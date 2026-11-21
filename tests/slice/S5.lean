import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Simulation
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim

open StoragePolicySim

/-- The first failure message of the checks, run in order. -/
def firstOf (rs : List (IO (Option String))) : IO (Option String) := do
  for r in rs do
    match (← r) with
    | some m => return some m
    | none => pure ()
  return none

/-- The stderr text without the final line break. -/
def errLine (o : Harness.Out) : String := o.err.trimAscii.toString

/-- The command must refuse with the error line, exit 2 and an empty stdout. -/
def expectErr (args : List String) (line : String) : IO (Option String) := do
  let o ← Harness.sim args
  return Harness.firstFail [
    (o.code == 2, s!"args {args}: exit code {o.code}, stderr '{o.err}'"),
    (errLine o == line, s!"args {args}: stderr was '{errLine o}', want '{line}'"),
    (o.out == "", s!"args {args}: stdout was not empty: '{o.out}'")]

/-- The command must exit with 0. -/
def expectOk (args : List String) : IO (Option String) := do
  let o ← Harness.sim args
  return Harness.firstFail [
    (o.code == 0, s!"args {args}: exit code {o.code}, stderr '{o.err}'")]

/-- One option of D15 with its lowest value, its highest value, a value just above, a value just
below, and the range text of the error. -/
structure Rng where
  opt : String
  lo : String
  hi : String
  above : String
  below : String
  text : String

/-- The options of D15 that `sim policy run` takes. -/
def runRanges : List Rng := [
  { opt := "--tank", lo := "0", hi := "50", above := "50.1", below := "-1", text := "0 to 50" },
  { opt := "--element", lo := "0", hi := "20", above := "20.1", below := "-1", text := "0 to 20" },
  { opt := "--cut-in", lo := "0", hi := "50", above := "50.1", below := "-1", text := "0 to 50" },
  { opt := "--floor", lo := "0", hi := "50", above := "50.1", below := "-1", text := "0 to 50" },
  { opt := "--draw", lo := "0", hi := "100", above := "100.1", below := "-1", text := "0 to 100" },
  { opt := "--draw-cv", lo := "0", hi := "1", above := "1.1", below := "-1", text := "0 to 1" },
  { opt := "--fetches", lo := "1", hi := "10", above := "11", below := "0", text := "1 to 10" },
  { opt := "--forecast-error", lo := "0", hi := "5", above := "5.1", below := "-1", text := "0 to 5" },
  { opt := "--heat-start", lo := "0", hi := "23", above := "24", below := "-1", text := "0 to 23" },
  { opt := "--heat-hours", lo := "0", hi := "24", above := "25", below := "-1", text := "0 to 24" },
  { opt := "--discharge-from", lo := "0", hi := "24", above := "25", below := "-1", text := "0 to 24" },
  { opt := "--target", lo := "0", hi := "50", above := "50.1", below := "-1", text := "0 to 50" },
  { opt := "--min-solar", lo := "0", hi := "10", above := "10.1", below := "-1", text := "0 to 10" },
  { opt := "--low", lo := "0", hi := "50", above := "50.1", below := "-1", text := "0 to 50" }]

/-- The options of D15 that must be whole. -/
def wholeOpts : List String :=
  ["--fetches", "--heat-start", "--heat-hours", "--discharge-from"]

/-- A short `sim policy run` with one option. -/
def runWith (opt val : String) : List String :=
  ["policy", "run", "--days", "3", opt, val]

def outOfRange (r : Rng) (val : String) : String :=
  s!"error: OUT_OF_RANGE: {r.opt} {val} ({r.text})"

def tests : List Harness.Test := [
  { name := "test_001_S5_R18_tank_0_and_50_exit_0"
    run := firstOf [expectOk ["policy", "run", "--tank", "0"],
                    expectOk ["policy", "run", "--tank", "50"]] },
  { name := "test_001_S5_R18_tank_50_1_out_of_range"
    run := expectErr ["policy", "run", "--tank", "50.1"]
      "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)" },
  { name := "test_001_S5_R18_tank_minus_1_out_of_range"
    run := expectErr ["policy", "run", "--tank", "-1"]
      "error: OUT_OF_RANGE: --tank -1 (0 to 50)" },
  { name := "test_001_S5_R18_each_option_lowest_value_exits_0"
    run := firstOf (runRanges.map (fun (r : Rng) => expectOk (runWith r.opt r.lo))) },
  { name := "test_001_S5_R18_each_option_highest_value_exits_0"
    run := firstOf (runRanges.map (fun (r : Rng) => expectOk (runWith r.opt r.hi))) },
  { name := "test_001_S5_R18_each_option_above_highest_out_of_range"
    run := firstOf (runRanges.map (fun (r : Rng) =>
      expectErr (runWith r.opt r.above) (outOfRange r r.above))) },
  { name := "test_001_S5_R18_each_option_below_lowest_out_of_range"
    run := firstOf (runRanges.map (fun (r : Rng) =>
      expectErr (runWith r.opt r.below) (outOfRange r r.below))) },
  { name := "test_001_S5_R18_seeds_option_range_of_robust"
    run := firstOf [
      expectOk ["policy", "robust", "--days", "1", "--seeds", "1"],
      expectOk ["policy", "robust", "--days", "1", "--seeds", "100"],
      expectErr ["policy", "robust", "--days", "1", "--seeds", "101"]
        "error: OUT_OF_RANGE: --seeds 101 (1 to 100)",
      expectErr ["policy", "robust", "--days", "1", "--seeds", "0"]
        "error: OUT_OF_RANGE: --seeds 0 (1 to 100)"] },
  { name := "test_001_S5_R18_seeds_option_range_of_tune"
    run := expectErr ["policy", "tune", "--days", "1", "--seeds", "101"]
      "error: OUT_OF_RANGE: --seeds 101 (1 to 100)" },
  { name := "test_001_S5_R18_hour_option_range_of_forecast"
    run := firstOf [
      expectOk ["forecast", "--days", "2", "--hour", "0"],
      expectOk ["forecast", "--days", "2", "--hour", "47"],
      expectErr ["forecast", "--days", "2", "--hour", "48"]
        "error: OUT_OF_RANGE: --hour 48 (0 to 47)",
      expectErr ["forecast", "--hour", "-1"]
        "error: OUT_OF_RANGE: --hour -1 (0 to 8759)"] },
  { name := "test_001_S5_R18_lon_option_range_of_forecast"
    run := firstOf [
      expectOk ["forecast", "--lon", "-180"],
      expectOk ["forecast", "--lon", "180"],
      expectErr ["forecast", "--lon", "180.1"]
        "error: OUT_OF_RANGE: --lon 180.1 (-180 to 180)",
      expectErr ["forecast", "--lon", "-180.1"]
        "error: OUT_OF_RANGE: --lon -180.1 (-180 to 180)"] },
  { name := "test_001_S5_R18_forecast_error_option_range_of_forecast"
    run := firstOf [
      expectOk ["forecast", "--forecast-error", "5"],
      expectErr ["forecast", "--forecast-error", "5.1"]
        "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"] },
  { name := "test_001_S5_R18_range_errors_on_compare_robust_tune"
    run := firstOf [
      expectErr ["policy", "compare", "--tank", "50.1"]
        "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)",
      expectErr ["policy", "robust", "--tank", "50.1"]
        "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)",
      expectErr ["policy", "tune", "--tank", "50.1"]
        "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)"] },
  { name := "test_001_S5_R18_heat_hours_2_5_bad_number"
    run := expectErr ["policy", "run", "--heat-hours", "2.5"]
      "error: BAD_NUMBER: --heat-hours 2.5" },
  { name := "test_001_S5_R18_tank_abc_bad_number"
    run := expectErr ["policy", "run", "--tank", "abc"]
      "error: BAD_NUMBER: --tank abc" },
  { name := "test_001_S5_R18_element_1e3_bad_number"
    run := expectErr ["policy", "run", "--element", "1e3"]
      "error: BAD_NUMBER: --element 1e3" },
  { name := "test_001_S5_R18_floor_dot_5_bad_number"
    run := expectErr ["policy", "run", "--floor", ".5"]
      "error: BAD_NUMBER: --floor .5" },
  { name := "test_001_S5_R18_trailing_point_and_double_sign_bad_number"
    run := firstOf [
      expectErr ["policy", "run", "--tank", "5."] "error: BAD_NUMBER: --tank 5.",
      expectErr ["policy", "run", "--tank", "1.2.3"] "error: BAD_NUMBER: --tank 1.2.3"] },
  { name := "test_001_S5_R18_each_whole_option_refuses_a_fraction"
    run := firstOf (wholeOpts.map (fun (o : String) =>
      expectErr (runWith o "2.5") s!"error: BAD_NUMBER: {o} 2.5")) },
  { name := "test_001_S5_R18_seeds_and_hour_refuse_a_fraction"
    run := firstOf [
      expectErr ["policy", "robust", "--seeds", "2.5"] "error: BAD_NUMBER: --seeds 2.5",
      expectErr ["forecast", "--hour", "2.5"] "error: BAD_NUMBER: --hour 2.5"] },
  { name := "test_001_S5_R18_bad_number_on_compare_robust_tune_forecast"
    run := firstOf [
      expectErr ["policy", "compare", "--tank", "abc"] "error: BAD_NUMBER: --tank abc",
      expectErr ["policy", "robust", "--tank", "abc"] "error: BAD_NUMBER: --tank abc",
      expectErr ["policy", "tune", "--tank", "abc"] "error: BAD_NUMBER: --tank abc",
      expectErr ["forecast", "--lon", "abc"] "error: BAD_NUMBER: --lon abc"] },
  { name := "test_001_S5_R18_tank_without_value_missing_value"
    run := expectErr ["policy", "run", "--tank"] "error: MISSING_VALUE: --tank" },
  { name := "test_001_S5_R18_missing_value_on_compare_robust_tune_forecast"
    run := firstOf [
      expectErr ["policy", "compare", "--days"] "error: MISSING_VALUE: --days",
      expectErr ["policy", "robust", "--seeds"] "error: MISSING_VALUE: --seeds",
      expectErr ["policy", "tune", "--goal"] "error: MISSING_VALUE: --goal",
      expectErr ["forecast", "--hour"] "error: MISSING_VALUE: --hour"] },
  { name := "test_001_S5_R18_seeds_on_run_unknown_option"
    run := expectErr ["policy", "run", "--seeds", "3"] "error: UNKNOWN_OPTION: --seeds" },
  { name := "test_001_S5_R18_unknown_option_on_each_command"
    run := firstOf [
      expectErr ["policy", "run", "--bogus", "1"] "error: UNKNOWN_OPTION: --bogus",
      expectErr ["policy", "compare", "--bogus", "1"] "error: UNKNOWN_OPTION: --bogus",
      expectErr ["policy", "compare", "--policy", "static"] "error: UNKNOWN_OPTION: --policy",
      expectErr ["policy", "robust", "--bogus", "1"] "error: UNKNOWN_OPTION: --bogus",
      expectErr ["policy", "tune", "--bogus", "1"] "error: UNKNOWN_OPTION: --bogus",
      expectErr ["forecast", "--battery", "5"] "error: UNKNOWN_OPTION: --battery",
      expectErr ["policy", "run", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy"] },
  { name := "test_001_S5_R18_last_value_of_an_option_counts"
    run := do
      let a ← Harness.sim ["policy", "run", "--days", "5", "--tank", "5", "--tank", "12"]
      let b ← Harness.sim ["policy", "run", "--days", "5", "--tank", "12"]
      return Harness.firstFail [
        (a.code == 0, s!"first run: exit {a.code}, stderr '{a.err}'"),
        (b.code == 0, s!"second run: exit {b.code}, stderr '{b.err}'"),
        (a.out == b.out, s!"outputs differ: '{Harness.oneLine a.out}' vs '{Harness.oneLine b.out}'")] },
  { name := "test_001_S5_R18_last_value_decides_validity"
    run := firstOf [
      expectOk ["policy", "run", "--days", "3", "--tank", "50.1", "--tank", "12"],
      expectErr ["policy", "run", "--days", "3", "--tank", "12", "--tank", "50.1"]
        "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)"] },
  { name := "test_001_S5_R18_each_error_has_empty_stdout_and_exit_2"
    run := do
      let cases : List (List String) := [
        ["policy", "run", "--tank", "50.1"],
        ["policy", "run", "--tank", "abc"],
        ["policy", "run", "--tank"],
        ["policy", "run", "--seeds", "3"],
        ["policy", "compare", "--tank", "-1"],
        ["policy", "robust", "--element", "20.1"],
        ["policy", "tune", "--floor", ".5"],
        ["forecast", "--lon", "181"]]
      firstOf (cases.map (fun (c : List String) => do
        let o ← Harness.sim c
        return Harness.firstFail [
          (o.code == 2, s!"args {c}: exit code {o.code}"),
          (o.out == "", s!"args {c}: stdout '{o.out}'"),
          (o.err != "", s!"args {c}: stderr empty"),
          ((o.err.trimAscii.toString.splitOn "\n").length == 1, s!"args {c}: stderr has many lines '{o.err}'"),
          ((o.err.splitOn "error: ").length == 2, s!"args {c}: stderr is not one error line '{o.err}'")])) },
  { name := "test_001_S5_R18_error_repeats_value_as_typed_without_running_it"
    run := firstOf [
      expectErr ["policy", "run", "--tank", "$(id)"] "error: BAD_NUMBER: --tank $(id)",
      expectErr ["policy", "run", "--tank", "5;ls"] "error: BAD_NUMBER: --tank 5;ls",
      expectErr ["policy", "run", "--tank", "../../etc/passwd"]
        "error: BAD_NUMBER: --tank ../../etc/passwd",
      expectErr ["policy", "run", "--tank-x", "1"] "error: UNKNOWN_OPTION: --tank-x"] },
  { name := "test_001_S5_R18_huge_days_is_refused_by_its_range"
    run := do
      let o ← Harness.sim ["policy", "run", "--days", "99999999"]
      return Harness.firstFail [
        (o.code == 2, s!"exit code {o.code}, stderr '{o.err}'"),
        ((errLine o).startsWith "error: OUT_OF_RANGE: --days 99999999 (", s!"stderr was '{errLine o}'"),
        (o.out == "", s!"stdout was not empty: '{o.out}'")] }
]

def main (args : List String) : IO UInt32 := Harness.run tests args
