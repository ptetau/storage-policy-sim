/-
Component checks of JOB-simulate (simulate a year of solar and compare strategies), for
CH-0004 (the sim command) and CH-0011 (the forecast and policy commands).

Each check runs `.lake/build/bin/sim` as a process through `timeout 60`, and reads the exit
code, stdout and stderr. Some checks also call `simulate` of CH-0003 (simulation), with
`Site`, `Battery` and `Strategy`, to compare the printed values. The checks of CH-0011 also
call `runHome`, `evaluate`, `tuneStatic`, `forecast` and `forecastJson` of the library for
the same purpose. The `--seed` option is the only seam. No check uses the clock.

Each error code of the Interface has at least one check that expects the exact line:
UNKNOWN_COMMAND, UNKNOWN_OPTION, MISSING_VALUE, BAD_NUMBER, OUT_OF_RANGE, UNKNOWN_STRATEGY
and UNKNOWN_POLICY. Since CH-0011, this holds for each command: `sim`, `sim forecast`,
`sim policy`, `sim policy run`, `sim policy compare`, `sim policy robust` and
`sim policy tune`.

Shared runs. A run of `sim policy robust` or `sim policy tune` is slow. Thus the checks of
JOB-simulate.R6 to R11 read a run through a small cache in `main`. The first check that
runs an argument list makes the run, and the next checks read the same output. A check
that needs a long run takes `--days` and `--seeds` as small as its line allows. A check that
compares a run of `sim` with a run of the library gives both the same options and the same
number of days.

The defaults of `sim run` are latitude -41.3, 5 kW of panels, 20 kWh of daily load with
3 kWh flexible, a 10 kWh battery with 5 kW of power, `greedy`, seed 1 and 365 days.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
import StoragePolicySim.Forecast
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- Rounds to one decimal, half away from zero. -/
def round1 (x : Float) : Float :=
  if x < 0 then -(Float.round (-x * 10)) / 10 else Float.round (x * 10) / 10

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def digitsVal (cs : List Char) : Nat :=
  cs.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads a printed number: an optional minus, digits, and an optional point with digits. -/
def parseNum (s : String) : Option Float :=
  let p : Bool × List Char := match s.toList with
    | '-' :: r => (true, r)
    | r => (false, r)
  let cs := p.2
  let ip := cs.takeWhile Char.isDigit
  let rest := cs.dropWhile Char.isDigit
  let q : List Char × List Char := match rest with
    | '.' :: r => (r.takeWhile Char.isDigit, r.dropWhile Char.isDigit)
    | r => ([], r)
  if ip.isEmpty || !q.2.isEmpty then none
  else
    let v := Float.ofNat (digitsVal ip) + Float.ofScientific (digitsVal q.1) true q.1.length
    some (if p.1 then -v else v)

-- Helpers for the library

def site (lat : Float := -41.3) (pv : Float := 5) (load : Float := 20) (flex : Float := 3) :
    Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }

def bat (cap : Float := 10) (power : Float := 5) : Battery :=
  { capacityKwh := cap, powerKw := power }

def monthNames : List String :=
  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

-- Helpers for the `sim` process

structure RunOut where
  code : UInt32
  out : String
  err : String

def sim (args : List String) : IO RunOut := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

def lines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")

/-- A line of `sim run`: the label, spaces to fill 18 characters, and the value. -/
def row (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

def runLabels : List String :=
  ["strategy", "days", "seed", "solar", "load", "self-used", "import", "export", "losses",
   "self-consumption", "self-sufficiency"]

def monthHeader : String :=
  "month solar-kWh load-kWh import-kWh export-kWh self-consumption-% self-sufficiency-%"

def compareHeader : String :=
  "strategy self-consumption-% self-sufficiency-% import-kWh export-kWh"

def usage : String :=
  "usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]"

def firstWords (out : String) : List String :=
  (lines out).map (fun l => (words l).head?.getD "")

def valueOf (out label : String) : Option String :=
  match (lines out).find? (fun l => (words l).head? == some label) with
  | some l => (words l)[1]?
  | none => none

def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum

def showsNum (s : Option String) (x : Float) : Bool :=
  match s.bind parseNum with
  | some v => near v (round1 x) 0.001
  | none => false

def totalsPairs (t : Totals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("self-used", t.selfUsedKwh),
   ("import", t.importKwh), ("export", t.exportKwh), ("losses", t.lossKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

/-- Compares each value line of `sim run` with the totals of the simulation. -/
def checkShows (out : String) (t : Totals) : Option String :=
  match (totalsPairs t).find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

def rowShows (r : String) (m : Month) : Bool :=
  let w := words r
  w.length == 7 && w[0]? == some m.name &&
  showsNum w[1]? m.totals.pvKwh && showsNum w[2]? m.totals.loadKwh &&
  showsNum w[3]? m.totals.importKwh && showsNum w[4]? m.totals.exportKwh &&
  showsNum w[5]? m.totals.selfConsumption && showsNum w[6]? m.totals.selfSufficiency

/-- The row of `sim compare` for a strategy, split into words. -/
def compareRow (out name : String) : Option (List String) :=
  ((lines out).find? (fun l => (words l).head? == some name)).map words

def compareShows (out : String) (s : Strategy) (t : Totals) : Bool :=
  match compareRow out s.name with
  | some w =>
    w.length == 5 && showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
    showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh
  | none => false

def oneDecimal (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
  | _ => false

/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
def labelled (l label : String) : Bool :=
  let cs := l.toList
  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '

/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
def expectError (args : List String) (line : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]

/-- Expects exit code 2, empty stdout, and stderr that starts with `pre`. -/
def expectStart (args : List String) (pre : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (r.err.startsWith pre, s!"sim {args}: stderr is {repr r.err}, want a start of {repr pre}")]

/-- Expects exit code 0, empty stderr, and the 11 lines of `sim run`. -/
def expectRun (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (r.err == "", s!"sim {args}: stderr is {repr r.err}"),
    (firstWords r.out == runLabels, s!"sim {args}: stdout is {repr r.out}")]

/-- Runs the expectations in order and gives the first failure. -/
def allOf : List (IO (Option String)) → IO (Option String)
  | [] => pure none
  | c :: rest => do
    match ← c with
    | some m => return some m
    | none => allOf rest

/-- Each value of `ok` is accepted. Each pair of `bad` gives its exact error line. -/
def rangeOf (opt : String) (ok : List String) (bad : List (String × String)) :
    IO (Option String) :=
  allOf (ok.map (fun v => expectRun ["run", opt, v]) ++
    bad.map (fun p => expectError ["run", opt, p.1] p.2))

def checks : List Check := [
  -- JOB-simulate.R1
  { name := "JOB-simulate.R1 sim run prints the 11 lines in order and exits with 0",
    run := do
      let r ← sim ["run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (r.err == "", s!"stderr is {repr r.err}"),
        ((lines r.out).length == 11, s!"{(lines r.out).length} lines"),
        (firstWords r.out == runLabels, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R1 each line has its label to column 19 and a value of the right form",
    run := do
      let r ← sim ["run"]
      let ls := lines r.out
      let bad := (List.range 11).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (runLabels.getD i "") &&
          (if i < 3 then w.length == 2
           else if i < 9 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
      return if r.code != 0 || ls.length != 11 then some s!"stdout is {repr r.out}"
        else match bad with
          | some i => some s!"the line {repr (ls.getD i "")} has the wrong form"
          | none => none },
  { name := "JOB-simulate.R1 the first three lines show greedy, 365 days and seed 1",
    run := do
      let r ← sim ["run"]
      let want := [row "strategy" "greedy", row "days" "365", row "seed" "1"]
      return if r.code == 0 && (lines r.out).take 3 == want then none
        else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --pv 0 shows 0.0 kWh of solar and 0.0 % self-consumption",
    run := do
      let r ← sim ["run", "--pv", "0"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls[3]? == some (row "solar" "0.0 kWh"), s!"the solar line is {ls[3]?}"),
        (ls[9]? == some (row "self-consumption" "0.0 %"), s!"the line is {ls[9]?}")] },
  { name := "JOB-simulate.R1 --strategy shift --days 30 --lat 45 shows the values of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "shift", "--days", "30", "--lat", "45"]
      let t := (simulate (site (lat := 45)) (bat) Strategy.shift 1 30).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "shift", row "days" "30", row "seed" "1"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
  { name := "JOB-simulate.R1 the defaults give the values of the simulation",
    run := do
      let r ← sim ["run"]
      let t := (simulate (site) (bat) Strategy.greedy 1 365).totals
      return (if r.code == 0 then none else some s!"exit code {r.code}") <|> checkShows r.out t },
  -- Each option has a value that differs from its default. Thus, a version that swaps two
  -- options, for example --battery and --power, fails here.
  { name := "JOB-simulate.R1 each option goes to its own part of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "evening", "--days", "40", "--seed", "3", "--lat", "30",
        "--pv", "7.5", "--battery", "4", "--power", "2", "--load", "15", "--flex", "1.5"]
      let t := (simulate (site 30 7.5 15 1.5) (bat 4 2) Strategy.evening 3 40).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "evening", row "days" "40", row "seed" "3"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
  -- A version that keeps --flex at 3 with --load 2 fails the first run. A version that sets
  -- --flex to the --load value with --load 4 fails the second run.
  { name := "JOB-simulate.R1 the --flex default is 3, or the --load value when that is less",
    run := do
      let a ← sim ["run", "--load", "2", "--lat", "45"]
      let b ← sim ["run", "--load", "4", "--lat", "45"]
      let ta := (simulate (site 45 5 2 2) (bat) Strategy.greedy 1 365).totals
      let tb := (simulate (site 45 5 4 3) (bat) Strategy.greedy 1 365).totals
      return firstFail [
        (a.code == 0, s!"--load 2: exit code {a.code}, stderr {repr a.err}"),
        (b.code == 0, s!"--load 4: exit code {b.code}, stderr {repr b.err}")] <|>
        (checkShows a.out ta).map (s!"--load 2: " ++ ·) <|>
        (checkShows b.out tb).map (s!"--load 4: " ++ ·) },
  { name := "JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used",
    run := do
      let r ← sim ["run", "--strategy", "none", "--battery", "0"]
      return match numOf r.out "solar", numOf r.out "self-used", numOf r.out "export" with
        | some s, some u, some e =>
          if r.code == 0 && s > 0 && e > 0 && near e (s - u) (0.1 + 1e-9) then none
          else some s!"solar {s}, self-used {u}, export {e}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --days 3650 exits with 0 and shows 3650 days",
    run := do
      let r ← sim ["run", "--days", "3650"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "3650") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },

  -- JOB-simulate.R2
  { name := "JOB-simulate.R2 --monthly prints the 11 lines, a blank line, the header and 12 rows from Jan to Dec",
    run := do
      let r ← sim ["run", "--monthly"]
      let ls := lines r.out
      let rows := ls.drop 13
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 25, s!"{ls.length} lines, want 25"),
        ((ls.take 11).map (fun l => (words l).head?.getD "") == runLabels, "the 11 lines are wrong"),
        (ls[11]? == some "", s!"line 12 is {ls[11]?}, want blank"),
        (Option.map words ls[12]? == some (words monthHeader), s!"the header is {ls[12]?}"),
        (rows.map (fun l => (words l).head?.getD "") == monthNames, s!"rows {rows}"),
        (rows.all (fun l => (words l).length == 7), "a row does not have seven fields")] },
  { name := "JOB-simulate.R2 each row shows the totals of its month",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45", "--seed", "4"]
      let ms := (simulate (site (lat := 45)) (bat) Strategy.greedy 4 365).months
      let rows := (lines r.out).drop 13
      return if r.code == 0 && rows.length == ms.size && ms.size == 12 &&
          (rows.zip ms.toList).all (fun (l, m) => rowShows l m) then none
        else some s!"rows {rows}" },
  { name := "JOB-simulate.R2 --monthly --days 400 prints 14 rows that end with Jan and Feb",
    run := do
      let r ← sim ["run", "--monthly", "--days", "400"]
      let ms := (simulate (site) (bat) Strategy.greedy 1 400).months
      let rows := (lines r.out).drop 13
      let names := rows.map (fun l => (words l).head?.getD "")
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (rows.length == 14 && names.drop 12 == ["Jan", "Feb"], s!"rows {names}"),
        (ms.size == 14 && (rows.zip ms.toList).all (fun (l, m) => rowShows l m),
          s!"the rows do not show the months of the simulation: {rows}")] },
  { name := "JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45"]
      let rows := (lines r.out).drop 13
      let solar := fun (n : String) =>
        (rows.find? (fun l => (words l).head? == some n)).bind (fun l => (words l)[1]?.bind parseNum)
      return match solar "Jul", solar "Dec" with
        | some j, some d => if r.code == 0 && d > 0 && j > 2 * d then none else some s!"Jul {j}, Dec {d}"
        | _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 without --monthly sim run prints only the 11 lines",
    run := do
      let r ← sim ["run", "--lat", "45"]
      return if r.code == 0 && (lines r.out).length == 11 && firstWords r.out == runLabels
        then none else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 the 11 lines of --monthly are the lines of sim run",
    run := do
      let a ← sim ["run", "--lat", "45", "--monthly"]
      let b ← sim ["run", "--lat", "45"]
      return if a.code == 0 && b.code == 0 && (lines a.out).take 11 == lines b.out then none
        else some s!"--monthly {repr a.out}, without {repr b.out}" },

  -- JOB-simulate.R3
  { name := "JOB-simulate.R3 sim compare prints the header and none, greedy, evening and shift",
    run := do
      let r ← sim ["compare"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 5, s!"{ls.length} lines, want 5"),
        (Option.map words ls[0]? == some (words compareHeader), s!"the header is {ls[0]?}"),
        (firstWords r.out == ["strategy", "none", "greedy", "evening", "shift"],
          s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 5), "a row does not have five fields")] },
  { name := "JOB-simulate.R3 the greedy row of --seed 9 --lat 45 shows the four values of sim run",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45"]
      let r ← sim ["run", "--seed", "9", "--lat", "45"]
      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
        valueOf r.out "import", valueOf r.out "export"]
      return match compareRow c.out "greedy" with
        | some w =>
          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?] then none
          else some s!"compare {w}, run {fromRun}"
        | none => some s!"no greedy row in {repr c.out}" },
  -- The options differ from the defaults. Thus, a version that ignores an option in
  -- sim compare fails here.
  { name := "JOB-simulate.R3 each row of sim compare shows the values of the simulation",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45", "--battery", "4", "--load", "15",
        "--days", "100"]
      let bad := Strategy.all.find? (fun s =>
        !compareShows c.out s (simulate (site 45 5 15 3) (bat 4 5) s 9 100).totals)
      return if c.code != 0 then some s!"exit code {c.code}, stderr {repr c.err}"
        else match bad with
          | some s => some s!"the {s.name} row is wrong in {repr c.out}"
          | none => none },
  { name := "JOB-simulate.R3 --lat 45 gives greedy a higher self-consumption than none",
    run := do
      let c ← sim ["compare", "--lat", "45"]
      let sc := fun (n : String) => (compareRow c.out n).bind (fun w => w[1]?.bind parseNum)
      return match sc "greedy", sc "none" with
        | some g, some n => if c.code == 0 && g > n then none else some s!"greedy {g}, none {n}"
        | _, _ => some s!"stdout is {repr c.out}" },
  { name := "JOB-simulate.R3 sim compare --strategy greedy gives UNKNOWN_OPTION",
    run := expectError ["compare", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
  { name := "JOB-simulate.R3 sim compare --monthly gives UNKNOWN_OPTION",
    run := expectError ["compare", "--monthly"] "error: UNKNOWN_OPTION: --monthly" },

  -- JOB-simulate.R4
  { name := "JOB-simulate.R4 --seed 5 gives the same output two times",
    run := do
      let a ← sim ["run", "--seed", "5"]
      let b ← sim ["run", "--seed", "5"]
      let c ← sim ["compare", "--seed", "5"]
      let d ← sim ["compare", "--seed", "5"]
      return firstFail [
        (a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11,
          s!"sim run: first {repr a.out}, second {repr b.out}"),
        (c.code == 0 && d.code == 0 && c.out == d.out && (lines c.out).length == 5,
          s!"sim compare: first {repr c.out}, second {repr d.out}")] },
  { name := "JOB-simulate.R4 --seed 1 and --seed 2 give different solar values",
    run := do
      let a ← sim ["run", "--seed", "1"]
      let b ← sim ["run", "--seed", "2"]
      let sa := valueOf a.out "solar"
      let sb := valueOf b.out "solar"
      return if a.code == 0 && b.code == 0 && sa.isSome && sb.isSome && sa != sb then none
        else some s!"seed 1 {sa}, seed 2 {sb}" },
  { name := "JOB-simulate.R4 --seed 2 gives the solar of the simulation with seed 2",
    run := do
      let r ← sim ["run", "--seed", "2"]
      let t := (simulate (site) (bat) Strategy.greedy 2 365).totals
      return if r.code == 0 && showsNum (valueOf r.out "solar") t.pvKwh then none
        else some s!"solar {valueOf r.out "solar"}, want {round1 t.pvKwh}" },

  -- JOB-simulate.R5
  { name := "JOB-simulate.R5 sim with no arguments prints the usage and exits with 0",
    run := do
      let r ← sim []
      return if r.code == 0 && (lines r.out).head? == some usage && r.err == "" then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim help and sim --help print the same usage and exit with 0",
    run := do
      let a ← sim []
      let h ← sim ["help"]
      let d ← sim ["--help"]
      return firstFail [
        (h.code == 0 && (lines h.out).head? == some usage && h.out == a.out,
          s!"sim help: exit code {h.code}, stdout {repr h.out}"),
        (d.code == 0 && (lines d.out).head? == some usage && d.out == a.out,
          s!"sim --help: exit code {d.code}, stdout {repr d.out}")] },
  { name := "JOB-simulate.R5 sim fly gives UNKNOWN_COMMAND",
    run := expectError ["fly"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 a command word that differs by its case or a space gives UNKNOWN_COMMAND",
    run := allOf [
      expectError ["Run"] "error: UNKNOWN_COMMAND: Run",
      expectError ["run "] "error: UNKNOWN_COMMAND: run ",
      expectError ["Compare"] "error: UNKNOWN_COMMAND: Compare"] },
  { name := "JOB-simulate.R5 --colour red gives UNKNOWN_OPTION",
    run := expectError ["run", "--colour", "red"] "error: UNKNOWN_OPTION: --colour" },
  { name := "JOB-simulate.R5 an option that differs by its case, a dash or an equals sign gives UNKNOWN_OPTION",
    run := allOf [
      expectError ["run", "--Days", "5"] "error: UNKNOWN_OPTION: --Days",
      expectError ["run", "-days", "5"] "error: UNKNOWN_OPTION: -days",
      expectError ["run", "--days=5"] "error: UNKNOWN_OPTION: --days=5"] },
  { name := "JOB-simulate.R5 sim run now gives UNKNOWN_OPTION",
    run := expectError ["run", "now"] "error: UNKNOWN_OPTION: now" },
  { name := "JOB-simulate.R5 --days with no value gives MISSING_VALUE",
    run := expectError ["run", "--days"] "error: MISSING_VALUE: --days" },
  { name := "JOB-simulate.R5 --strategy and --flex with no value give MISSING_VALUE",
    run := allOf [
      expectError ["run", "--strategy"] "error: MISSING_VALUE: --strategy",
      expectError ["run", "--days", "5", "--flex"] "error: MISSING_VALUE: --flex"] },
  { name := "JOB-simulate.R5 --days abc gives BAD_NUMBER",
    run := expectError ["run", "--days", "abc"] "error: BAD_NUMBER: --days abc" },
  { name := "JOB-simulate.R5 an empty --days gives BAD_NUMBER",
    run := expectError ["run", "--days", ""] "error: BAD_NUMBER: --days " },
  { name := "JOB-simulate.R5 --days 36.5 gives BAD_NUMBER",
    run := expectError ["run", "--days", "36.5"] "error: BAD_NUMBER: --days 36.5" },
  { name := "JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER",
    run := allOf [
      expectError ["run", "--days", " 2"] "error: BAD_NUMBER: --days  2",
      expectStart ["run", "--days", "2\n"] "error: BAD_NUMBER: --days 2\n",
      expectError ["run", "--seed", "1.5"] "error: BAD_NUMBER: --seed 1.5"] },
  { name := "JOB-simulate.R5 --days +2 is a whole number with a sign",
    run := do
      let r ← sim ["run", "--days", "+2"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "2") then none
        else some s!"exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}" },
  { name := "JOB-simulate.R5 --pv 1e3, .5, 5. and 5kW give BAD_NUMBER",
    run := allOf [
      expectError ["run", "--pv", "1e3"] "error: BAD_NUMBER: --pv 1e3",
      expectError ["run", "--pv", ".5"] "error: BAD_NUMBER: --pv .5",
      expectError ["run", "--pv", "5."] "error: BAD_NUMBER: --pv 5.",
      expectError ["run", "--pv", "5kW"] "error: BAD_NUMBER: --pv 5kW"] },
  { name := "JOB-simulate.R5 a number with a trailing space, a lone sign or a misplaced sign gives BAD_NUMBER",
    run := allOf [
      expectError ["run", "--pv", "3 "] "error: BAD_NUMBER: --pv 3 ",
      expectError ["run", "--lat", "-"] "error: BAD_NUMBER: --lat -",
      expectError ["run", "--lat", "5-"] "error: BAD_NUMBER: --lat 5-",
      expectError ["run", "--load", "+-5"] "error: BAD_NUMBER: --load +-5"] },
  { name := "JOB-simulate.R5 --pv +3 gives the result of --pv 3",
    run := do
      let a ← sim ["run", "--pv", "+3"]
      let b ← sim ["run", "--pv", "3"]
      let d ← sim ["run"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11 &&
          valueOf a.out "solar" != valueOf d.out "solar" then none
        else some s!"+3 {repr a.out}, 3 {repr b.out}" },
  { name := "JOB-simulate.R5 --days 0 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "0"] "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 3651 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "3651"] "error: OUT_OF_RANGE: --days 3651 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 1 and --days 3650 are accepted",
    run := rangeOf "--days" ["1", "3650"] [] },
  { name := "JOB-simulate.R5 --days 99999999999999999999 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "99999999999999999999"]
      "error: OUT_OF_RANGE: --days 99999999999999999999 (1 to 3650)" },
  { name := "JOB-simulate.R5 --seed -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--seed", "-1"] "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)" },
  { name := "JOB-simulate.R5 --seed 0 and 4294967295 are accepted, and 4294967296 gives OUT_OF_RANGE",
    run := rangeOf "--seed" ["0", "4294967295"]
      [("4294967296", "error: OUT_OF_RANGE: --seed 4294967296 (0 to 4294967295)"),
       ("99999999999999999999", "error: OUT_OF_RANGE: --seed 99999999999999999999 (0 to 4294967295)")] },
  { name := "JOB-simulate.R5 --lat 90 and -90 are accepted, and 90.1 and -90.1 give OUT_OF_RANGE",
    run := rangeOf "--lat" ["90", "-90"]
      [("90.1", "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)"),
       ("-90.1", "error: OUT_OF_RANGE: --lat -90.1 (-90 to 90)")] },
  { name := "JOB-simulate.R5 --pv 0 and 100 are accepted, and 100.1 and -1 give OUT_OF_RANGE",
    run := rangeOf "--pv" ["0", "100"]
      [("100.1", "error: OUT_OF_RANGE: --pv 100.1 (0 to 100)"),
       ("-1", "error: OUT_OF_RANGE: --pv -1 (0 to 100)")] },
  { name := "JOB-simulate.R5 --battery 0 and 200 are accepted, and 200.1 and -0.1 give OUT_OF_RANGE",
    run := rangeOf "--battery" ["0", "200"]
      [("200.1", "error: OUT_OF_RANGE: --battery 200.1 (0 to 200)"),
       ("-0.1", "error: OUT_OF_RANGE: --battery -0.1 (0 to 200)")] },
  { name := "JOB-simulate.R5 --power 0 and 100 are accepted, and 100.1 gives OUT_OF_RANGE",
    run := rangeOf "--power" ["0", "100"]
      [("100.1", "error: OUT_OF_RANGE: --power 100.1 (0 to 100)")] },
  -- With --load 0.1 and no --flex, the --flex default is 0.1, the --load value.
  { name := "JOB-simulate.R5 --load 0.1 and 1000 are accepted, and 0 and 1000.1 give OUT_OF_RANGE",
    run := rangeOf "--load" ["0.1", "1000"]
      [("0", "error: OUT_OF_RANGE: --load 0 (0.1 to 1000)"),
       ("1000.1", "error: OUT_OF_RANGE: --load 1000.1 (0.1 to 1000)")] },
  { name := "JOB-simulate.R5 --load 10 --flex 10 is accepted",
    run := allOf [
      expectRun ["run", "--load", "10", "--flex", "10"],
      expectRun ["run", "--load", "10", "--flex", "0"]] },
  { name := "JOB-simulate.R5 --load 10 --flex 10.5 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "10", "--flex", "10.5"]
      "error: OUT_OF_RANGE: --flex 10.5 (0 to 10)" },
  { name := "JOB-simulate.R5 --flex -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "20", "--flex", "-1"]
      "error: OUT_OF_RANGE: --flex -1 (0 to 20)" },
  { name := "JOB-simulate.R5 the --flex range shows the last --load value as typed",
    run := allOf [
      expectError ["run", "--load", "10.0", "--flex", "10.5"]
        "error: OUT_OF_RANGE: --flex 10.5 (0 to 10.0)",
      expectError ["run", "--load", "10", "--load", "+2", "--flex", "3"]
        "error: OUT_OF_RANGE: --flex 3 (0 to +2)"] },
  { name := "JOB-simulate.R5 --strategy wild gives UNKNOWN_STRATEGY",
    run := expectError ["run", "--strategy", "wild"]
      "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)" },
  { name := "JOB-simulate.R5 a strategy name that differs by its case or a space gives UNKNOWN_STRATEGY",
    run := allOf [
      expectError ["run", "--strategy", "Greedy"]
        "error: UNKNOWN_STRATEGY: Greedy (none, greedy, evening, shift)",
      expectError ["run", "--strategy", "shift "]
        "error: UNKNOWN_STRATEGY: shift  (none, greedy, evening, shift)",
      expectError ["run", "--strategy", ""]
        "error: UNKNOWN_STRATEGY:  (none, greedy, evening, shift)"] },
  { name := "JOB-simulate.R5 each strategy name is accepted",
    run := allOf (Strategy.all.map (fun s => do
      let r ← sim ["run", "--strategy", s.name]
      return if r.code == 0 && (lines r.out).head? == some (row "strategy" s.name) then none
        else some s!"--strategy {s.name}: exit code {r.code}, stdout {repr r.out}")) },
  { name := "JOB-simulate.R5 --days 10 --days 20 shows 20 days",
    run := do
      let r ← sim ["run", "--days", "10", "--days", "20"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 the last value counts before the range is read",
    run := do
      let r ← sim ["run", "--days", "0", "--days", "20"]
      let e ← expectError ["run", "--days", "20", "--days", "0"]
        "error: OUT_OF_RANGE: --days 0 (1 to 3650)"
      return (if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"--days 0 --days 20: exit code {r.code}, stderr {repr r.err}") <|> e },
  { name := "JOB-simulate.R5 the command word comes before each option",
    run := expectError ["fly", "--colour", "red"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 the options are read from left to right and the first problem gives the error",
    run := allOf [
      expectError ["run", "--colour", "red", "--days", "abc"] "error: UNKNOWN_OPTION: --colour",
      expectError ["run", "--days", "abc", "--colour", "red"] "error: BAD_NUMBER: --days abc",
      expectError ["run", "--strategy", "wild", "--pv", "x"]
        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
      expectError ["run", "--pv", "x", "--days"] "error: BAD_NUMBER: --pv x"] },
  { name := "JOB-simulate.R5 a bad number or strategy comes before a range problem",
    run := allOf [
      expectError ["run", "--days", "0", "--pv", "x"] "error: BAD_NUMBER: --pv x",
      expectError ["run", "--days", "0", "--strategy", "wild"]
        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
      expectError ["run", "--days", "0", "--colour"] "error: UNKNOWN_OPTION: --colour"] },
  { name := "JOB-simulate.R5 a range problem comes before the --flex check",
    run := expectError ["run", "--load", "2", "--flex", "5", "--days", "0"]
      "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 an error of sim compare gives the same line as an error of sim run",
    run := allOf [
      expectError ["compare", "--days", "abc"] "error: BAD_NUMBER: --days abc",
      expectError ["compare", "--lat", "91"] "error: OUT_OF_RANGE: --lat 91 (-90 to 90)",
      expectError ["compare", "--seed"] "error: MISSING_VALUE: --seed",
      expectError ["compare", "now"] "error: UNKNOWN_OPTION: now"] }
]

-- Helpers for the commands of CH-0011 (the forecast and the policy commands)

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

/-- The runs of `sim` by argument list. A run is made once, and then it is read again. -/
structure Cache where
  runs : IO.Ref (List (List String × RunOut))

def mkCache : IO Cache := do
  let r ← IO.mkRef ([] : List (List String × RunOut))
  return { runs := r }

def cachedSim (c : Cache) (args : List String) : IO RunOut := do
  let known ← c.runs.get
  match known.find? (fun (k, _) => k == args) with
  | some (_, v) => return v
  | none =>
    let v ← sim args
    c.runs.set ((args, v) :: known)
    return v

def usagePolicy : String := "usage: sim policy run|compare|robust|tune [options]"

def policyLabels : List String :=
  ["policy", "days", "seed", "solar", "load", "import", "export", "heating", "backstop",
   "unmet-hot-water", "cold-hours", "self-consumption", "self-sufficiency"]

def policyHeader : List String :=
  ["policy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh",
   "backstop-kWh"]

def robustHeader : List String :=
  ["policy", "mean-self-consumption-%", "worst-self-consumption-%", "mean-self-sufficiency-%",
   "mean-export-kWh", "mean-backstop-kWh", "unmet-kWh", "cold-hours", "safe"]

def rowNames : List String :=
  ["thermostat", "static", "precomputed", "dynamic", "perfect-forecast"]

/-- The line that starts with `label`. -/
def lineOf (out label : String) : Option String :=
  (lines out).find? (fun l => (words l).head? == some label)

/-- The value of the line `label` must be a number near `want`. -/
def numNear (out label : String) (want tol : Float) : Bool :=
  match numOf out label with
  | some v => near v want tol
  | none => false

/-- The first value of a row of `sim policy compare` or `sim policy robust`, which is the
self-consumption (the mean one in the table of `sim policy robust`). -/
def firstOfRow (out name : String) : Option Float :=
  (compareRow out name).bind (fun w => w[1]?.bind parseNum)

/-- The words of a row without its name. -/
def tailOfRow (out name : String) : Option (List String) :=
  (compareRow out name).map (fun w => w.drop 1)

/-- The lines of `sim policy run` must show the totals of a run of the library. -/
def policyPairs (t : HomeTotals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh), ("export", t.exportKwh),
   ("heating", t.heatKwh), ("backstop", t.backstopKwh), ("unmet-hot-water", t.unmetKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

/-- Compares the value lines of an output with named values. Gives the first line that is wrong. -/
def checkPairs (out : String) (pairs : List (String × Float)) : Option String :=
  match pairs.find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

/-- The output of `sim policy run` must show the policy, the days, the seed, the totals of a
run of the library, and its cold hours. -/
def runShows (r : RunOut) (name : String) (days seed : Nat) (t : HomeTotals) : Option String :=
  let want := [row "policy" name, row "days" (toString days), row "seed" (toString seed)]
  firstSome [
    (if r.code == 0 then none else some s!"exit code {r.code}, stderr {repr r.err}"),
    (if (lines r.out).take 3 == want then none else some s!"stdout is {repr r.out}"),
    checkPairs r.out (policyPairs t),
    (if valueOf r.out "cold-hours" == some (toString t.coldHours) then none
      else some s!"cold-hours shows {valueOf r.out "cold-hours"}, want {t.coldHours}")]

/-- A row of `sim policy compare` must show five values of the totals, with one decimal. -/
def compareRowShows (w : List String) (t : HomeTotals) : Bool :=
  w.length == 6 && (w.drop 1).all oneDecimal &&
  showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
  showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh && showsNum w[5]? t.backstopKwh

/-- A row of `sim policy robust` must show an evaluation. The first six values have one
decimal. The column `safe` is `yes` when no seed has an unmet draw and `cold-hours` is 0. -/
def robustRowShows (w : List String) (e : Evaluation) : Bool :=
  w.length == 9 && ((w.drop 1).take 6).all oneDecimal && showsNum w[1]? e.meanSelfConsumption &&
  showsNum w[2]? e.worstSelfConsumption && showsNum w[3]? e.meanSelfSufficiency &&
  showsNum w[4]? e.meanExportKwh && showsNum w[5]? e.meanBackstopKwh &&
  showsNum w[6]? e.totalUnmetKwh && w[7]? == some (toString e.coldHours) &&
  w[8]? == some (if e.unmetSeeds == 0 && e.coldHours == 0 then "yes" else "no")

/-- The output of `sim policy tune` must show the counts, the profile and the `static` row of a
tuning of the library. -/
def tuneShows (r : RunOut) (t : TuneResult) : Option String :=
  let b := t.best
  firstFail [
    (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
    (valueOf r.out "candidates" == some (toString t.candidates),
      s!"candidates shows {valueOf r.out "candidates"}, want {t.candidates}"),
    (valueOf r.out "safe" == some (toString t.safe),
      s!"safe shows {valueOf r.out "safe"}, want {t.safe}"),
    (valueOf r.out "heat-start" == some (toString b.heatStart),
      s!"heat-start shows {valueOf r.out "heat-start"}, want {b.heatStart}"),
    (valueOf r.out "heat-hours" == some (toString b.heatHours),
      s!"heat-hours shows {valueOf r.out "heat-hours"}, want {b.heatHours}"),
    (valueOf r.out "discharge-from" == some (toString b.dischargeFrom),
      s!"discharge-from shows {valueOf r.out "discharge-from"}, want {b.dischargeFrom}"),
    ((compareRow r.out "static").map (fun w => robustRowShows w t.evaluation) == some true,
      s!"the static row is {compareRow r.out "static"}, the evaluation is {repr t.evaluation}")]

/-- Expects each error line for its argument list. Gives the first failure. -/
def allErrors (cases : List (List String × String)) : IO (Option String) := do
  for (a, line) in cases do
    let r ← expectError a line
    if r.isSome then return r
  return none

/-- Expects exit code 0 and the 13 lines of `sim policy run`. -/
def okRun (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (firstWords r.out == policyLabels, s!"sim {args}: stdout is {repr r.out}")]

/-- Expects each argument list to run with exit code 0. Gives the first failure. -/
def allOk (cases : List (List String)) : IO (Option String) := do
  for a in cases do
    let r ← okRun a
    if r.isSome then return r
  return none

/-- Expects exit code 2 and empty stdout for each argument list. -/
def allEmptyOut (cases : List (List String)) : IO (Option String) := do
  for a in cases do
    let r ← sim a
    if r.out != "" || r.code != 2 || r.err == "" then
      return some s!"sim {a}: exit code {r.code}, stdout {repr r.out}"
  return none

/-- True when a row of `sim policy robust` has a worst self-consumption above its mean, or when
a value does not read as a number. -/
def worstAboveMean (w : List String) : Bool :=
  match w[1]?.bind parseNum, w[2]?.bind parseNum with
  | some m, some x => x > m
  | _, _ => true

/-- The start of the Solcast JSON. -/
def jsonStart : String := "{\"forecasts\":["

/-- The period end of each period of the JSON text. -/
def jsonEnds (js : String) : List String :=
  ((js.splitOn "\"period_end\":\"").drop 1).map (fun p => (p.splitOn "\"").headD "")

/-- The text after `"key":` up to the next comma, for each period of the JSON text. -/
def valuesOfKey (js key : String) : List String :=
  ((js.splitOn ("\"" ++ key ++ "\":")).drop 1).map (fun p => (p.splitOn ",").headD "")

/-- Expects exit code 0 and the Solcast JSON on stdout. -/
def expectJson (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (r.out.startsWith jsonStart, s!"sim {args}: stdout is {repr r.out}")]

/-- A `sim policy run` argument list for an option that is checked at its edge. The run is 3
days, so that the check stays cheap. -/
def cheap (extra : List String) : List String :=
  ["policy", "run", "--days", "3"] ++ extra

def pr (extra : List String) : List String := ["policy", "run"] ++ extra

/-- Each option of `sim policy run` with the options of its policy that must come before it.
The options of the precomputed and the dynamic policy come with their policy, as R11 says. -/
def policyOpts : List (String × List String) :=
  [("--tank", []), ("--element", []), ("--cut-in", []), ("--floor", []), ("--draw", []),
   ("--draw-cv", []), ("--forecast-error", []), ("--heat-start", []), ("--heat-hours", []),
   ("--discharge-from", []), ("--fetches", ["--policy", "precomputed"]),
   ("--min-solar", ["--policy", "precomputed"]), ("--target", ["--policy", "dynamic"]),
   ("--low", ["--policy", "dynamic"])]

-- Helpers for the library: the home simulation, the forecast and the tuner

def pStatic : Policy := Policy.static defaultStatic
def pDyn : Policy := Policy.dynamic defaultDynamic

def homeLat45 : HomeSetup :=
  { defaultHome with site := { defaultHome.site with latitude := 45.0 } }
def homeElem02 : HomeSetup :=
  { defaultHome with tank := { defaultHome.tank with elementKw := 0.2 } }

/-- Values that differ from each default, so that a version that swaps two options, or that
ignores one, fails a check. The tank holds 8 kWh, so that the target of 7 kWh is a possible
level. -/
def siteOpts : Site := site 30 7.5 15 1.5
def tankOpts : TankConfig :=
  { defaultTank with capacityKwh := 8.0, cutInKwh := 4.0, floorKwh := 1.5 }

/-- `--lat 30 --pv 7.5 --load 15 --flex 1.5 --battery 4 --power 2`. -/
def homeSiteOpts : HomeSetup := { defaultHome with site := siteOpts, battery := bat 4 2 }

/-- `--tank 8 --cut-in 4 --floor 1.5 --draw 5 --draw-cv 0.4`. -/
def homeTankOpts : HomeSetup :=
  { defaultHome with tank := tankOpts, drawKwhPerDay := 5.0, drawCv := 0.4 }

/-- `--fetches 4 --forecast-error 2`. -/
def homeFcOpts : HomeSetup := { defaultHome with fetchesPerDay := 4, errorScale := 2.0 }

/-- All options of the home together. -/
def homeAll : HomeSetup :=
  { defaultHome with
    site := siteOpts, battery := bat 4 2, tank := tankOpts, drawKwhPerDay := 5.0, drawCv := 0.4,
    fetchesPerDay := 4, errorScale := 2.0 }

/-- `--heat-start 9 --heat-hours 3 --discharge-from 16`. -/
def pStaticRun : Policy :=
  Policy.static { defaultStatic with heatStart := 9, heatHours := 3, dischargeFrom := 16 }

/-- `--target 9 --min-solar 1.5 --discharge-from 19`. -/
def pPlanRun : Policy :=
  Policy.precomputed { defaultPlan with targetKwh := 9.0, minSolarKwh := 1.5, dischargeFrom := 19 }

/-- `--low 4 --target 9 --discharge-from 19`. -/
def pDynRun : Policy :=
  Policy.dynamic { defaultDynamic with lowKwh := 4.0, targetKwh := 9.0, dischargeFrom := 19 }

/-- The parameters of the five rows of a table, for `optsAll`. -/
def statOpts : StaticParams := { defaultStatic with heatStart := 9, heatHours := 3 }
def planOpts : PlanParams := { defaultPlan with targetKwh := 7.0, minSolarKwh := 1.5 }
def dynOpts : DynamicParams := { defaultDynamic with lowKwh := 4.0, targetKwh := 7.0 }

/-- The options that make `homeAll`, `statOpts`, `planOpts` and `dynOpts`. The static profile
comes from `--heat-start` and `--heat-hours`, and `--discharge-from` stays at its default. -/
def optsAll : List String :=
  ["--lat", "30", "--pv", "7.5", "--load", "15", "--flex", "1.5", "--battery", "4",
   "--power", "2", "--tank", "8", "--cut-in", "4", "--floor", "1.5", "--draw", "5",
   "--draw-cv", "0.4", "--fetches", "4", "--forecast-error", "2", "--heat-start", "9",
   "--heat-hours", "3", "--target", "7", "--min-solar", "1.5", "--low", "4"]

/-- The five policies of `sim policy compare` and `sim policy robust`, each with its home. The
`thermostat` policy is the static policy with 0 heating hours. The `perfect-forecast` policy is
the precomputed policy with an error scale of 0. -/
def rowSetupsP (home : HomeSetup) (st : StaticParams) (pl : PlanParams) (dy : DynamicParams) :
    List (String × HomeSetup × Policy) :=
  [("thermostat", home, Policy.static { st with heatHours := 0 }),
   ("static", home, Policy.static st), ("precomputed", home, Policy.precomputed pl),
   ("dynamic", home, Policy.dynamic dy),
   ("perfect-forecast", { home with errorScale := 0.0 }, Policy.precomputed pl)]

def rowSetups (home : HomeSetup) : List (String × HomeSetup × Policy) :=
  rowSetupsP home defaultStatic defaultPlan defaultDynamic

/-- The totals of the five policies for latitude 45, seed 9 and 90 days. -/
def cmpLib90 : List (String × HomeTotals) :=
  (rowSetups homeLat45).map (fun (n, s, p) => (n, (runHome s p 9 90).totals))

/-- The evaluations of the five policies over the seeds 1 to 10 for 365 days. -/
def robustLib : List (String × Evaluation) :=
  (rowSetups defaultHome).map (fun (n, s, p) => (n, evaluate s p 1 10 365))

/-- The tuning with 2 seeds from seed 1 and 30 days. -/
def tune1 : TuneResult := tuneStatic defaultHome 1 2 30

/-- The home of the tuning check that gives each option of the home its own value. -/
def homeTune : HomeSetup :=
  { defaultHome with
    site := site 45 5 15 1.5, tank := tankOpts, drawKwhPerDay := 5.0, drawCv := 0.4 }

/-- The text of `sim forecast`: the Solcast JSON of one fetch, and a line break. -/
def forecastText (s : Site) (seed days : Nat) (scale : Float) (hour : Nat) (lon : Float) :
    String :=
  forecastJson (forecast s seed days scale hour) lon ++ "\n"

-- JOB-simulate.R6

def r6Checks (cache : Cache) : List Check := [
  -- JOB-simulate.R6
  { name := "JOB-simulate.R6 sim forecast prints the Solcast JSON with 96 periods and a line break",
    run := do
      let r ← cachedSim cache ["forecast"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (r.out.startsWith (jsonStart ++ "{\"pv_estimate\":"), s!"stdout is {repr r.out}"),
        ((jsonEnds r.out).length == 96, s!"{(jsonEnds r.out).length} periods"),
        (r.out.endsWith "]}\n" && (lines r.out).length == 1, "stdout is not one line")] },
  { name := "JOB-simulate.R6 sim forecast has a first period that ends at 2024-12-31T13:00:00.0000000Z",
    run := do
      let r ← cachedSim cache ["forecast"]
      let got := (jsonEnds r.out).head?
      return if r.code == 0 && got == some "2024-12-31T13:00:00.0000000Z" then none
        else some s!"exit code {r.code}, the first period ends at {got}" },
  { name := "JOB-simulate.R6 --lon 0 gives a first period that ends at 2025-01-01T00:30:00.0000000Z",
    run := do
      let r ← sim ["forecast", "--lon", "0"]
      let got := (jsonEnds r.out).head?
      return if r.code == 0 && got == some "2025-01-01T00:30:00.0000000Z" then none
        else some s!"exit code {r.code}, the first period ends at {got}" },
  { name := "JOB-simulate.R6 --hour 8759 gives 2 periods",
    run := do
      let r ← sim ["forecast", "--hour", "8759"]
      return if r.code == 0 && (jsonEnds r.out).length == 2 then none
        else some s!"exit code {r.code}, {(jsonEnds r.out).length} periods, stderr {repr r.err}" },
  { name := "JOB-simulate.R6 --forecast-error 0 --lat 45 --hour 4116 gives pv_estimate10 and pv_estimate90 equal to pv_estimate",
    run := do
      let r ← sim ["forecast", "--forecast-error", "0", "--lat", "45", "--hour", "4116"]
      let est := valuesOfKey r.out "pv_estimate"
      let lo := valuesOfKey r.out "pv_estimate10"
      let hi := valuesOfKey r.out "pv_estimate90"
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (est.length == 96, s!"{est.length} periods"),
        (lo == est, "a pv_estimate10 differs from its pv_estimate"),
        (hi == est, "a pv_estimate90 differs from its pv_estimate"),
        (est.any (fun v => (parseNum v).getD 0.0 > 0.0), "no estimate is above 0")] },
  { name := "JOB-simulate.R6 --seed 3 --hour 4116 gives the same output two times",
    run := do
      let a ← sim ["forecast", "--seed", "3", "--hour", "4116"]
      let b ← sim ["forecast", "--seed", "3", "--hour", "4116"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (jsonEnds a.out).length == 96
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R6 --hour 8760 gives OUT_OF_RANGE",
    run := expectError ["forecast", "--hour", "8760"] "error: OUT_OF_RANGE: --hour 8760 (0 to 8759)" },
  { name := "JOB-simulate.R6 --days 2 --hour 48 gives OUT_OF_RANGE",
    run := expectError ["forecast", "--days", "2", "--hour", "48"]
      "error: OUT_OF_RANGE: --hour 48 (0 to 47)" },
  { name := "JOB-simulate.R6 --hour abc gives BAD_NUMBER",
    run := expectError ["forecast", "--hour", "abc"] "error: BAD_NUMBER: --hour abc" },
  { name := "JOB-simulate.R6 --hour 2.5 gives BAD_NUMBER",
    run := expectError ["forecast", "--hour", "2.5"] "error: BAD_NUMBER: --hour 2.5" },
  { name := "JOB-simulate.R6 --hour with no value gives MISSING_VALUE",
    run := expectError ["forecast", "--hour"] "error: MISSING_VALUE: --hour" },
  { name := "JOB-simulate.R6 --lon 180.1 gives OUT_OF_RANGE, and --lon 180 and --lon -180 are accepted",
    run := do
      let a ← expectError ["forecast", "--lon", "180.1"] "error: OUT_OF_RANGE: --lon 180.1 (-180 to 180)"
      let b ← sim ["forecast", "--lon", "180"]
      let c ← sim ["forecast", "--lon", "-180"]
      return firstSome [a,
        if b.code == 0 && b.out.startsWith jsonStart then none
        else some s!"--lon 180: exit code {b.code}, stderr {repr b.err}",
        if c.code == 0 && c.out.startsWith jsonStart then none
        else some s!"--lon -180: exit code {c.code}, stderr {repr c.err}"] },
  { name := "JOB-simulate.R6 --forecast-error 5.1 gives OUT_OF_RANGE, and --forecast-error 5 and 0 are accepted",
    run := do
      let a ← expectError ["forecast", "--forecast-error", "5.1"]
        "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"
      let b ← sim ["forecast", "--forecast-error", "5"]
      let c ← sim ["forecast", "--forecast-error", "0"]
      return firstSome [a,
        if b.code == 0 && b.out.startsWith jsonStart then none
        else some s!"--forecast-error 5: exit code {b.code}, stderr {repr b.err}",
        if c.code == 0 && c.out.startsWith jsonStart then none
        else some s!"--forecast-error 0: exit code {c.code}, stderr {repr c.err}"] },
  { name := "JOB-simulate.R6 --strategy greedy gives UNKNOWN_OPTION",
    run := expectError ["forecast", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
  { name := "JOB-simulate.R6 --battery 5 gives UNKNOWN_OPTION",
    run := expectError ["forecast", "--battery", "5"] "error: UNKNOWN_OPTION: --battery" },
  { name := "JOB-simulate.R6 each error gives empty stdout and exit code 2",
    run := allEmptyOut [
      ["forecast", "--hour", "8760"], ["forecast", "--days", "2", "--hour", "48"],
      ["forecast", "--hour", "abc"], ["forecast", "--hour", "2.5"], ["forecast", "--hour"],
      ["forecast", "--lon", "180.1"], ["forecast", "--forecast-error", "5.1"],
      ["forecast", "--strategy", "greedy"], ["forecast", "--battery", "5"]] },
  -- The checks below also prove the defaults, the routing of each option, and each error code
  -- of `sim forecast`.
  { name := "JOB-simulate.R6 the defaults give the forecast of the library for the default site, 365 days, seed 1, hour 0 and longitude 174.8",
    run := do
      let r ← cachedSim cache ["forecast"]
      return if r.code == 0 && r.out == forecastText (site) 1 365 1.0 0 174.8 then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  -- Each option has a value that differs from its default. Thus, a version that swaps --lat and
  -- --lon, or that ignores --forecast-error, fails here.
  { name := "JOB-simulate.R6 each option goes to its own part of the forecast",
    run := do
      let r ← sim ["forecast", "--lat", "30", "--pv", "7.5", "--days", "200", "--seed", "3",
        "--hour", "4116", "--lon", "10", "--forecast-error", "2"]
      let want := forecastText (site 30 7.5) 3 200 2.0 4116 10.0
      return if r.code == 0 && r.out == want then none
        else some s!"exit code {r.code}, stdout {repr r.out}, want {repr want}" },
  { name := "JOB-simulate.R6 --days 2 --hour 47 is accepted and gives 2 periods, and --hour -1 gives OUT_OF_RANGE",
    run := do
      let a ← sim ["forecast", "--days", "2", "--hour", "47"]
      let e ← expectError ["forecast", "--hour", "-1"] "error: OUT_OF_RANGE: --hour -1 (0 to 8759)"
      return firstSome [
        if a.code == 0 && (jsonEnds a.out).length == 2 then none
        else some s!"--days 2 --hour 47: exit code {a.code}, stdout {repr a.out}, stderr {repr a.err}",
        e] },
  { name := "JOB-simulate.R6 --lon -180.1 and --forecast-error -0.1 give OUT_OF_RANGE",
    run := allErrors [
      (["forecast", "--lon", "-180.1"], "error: OUT_OF_RANGE: --lon -180.1 (-180 to 180)"),
      (["forecast", "--forecast-error", "-0.1"],
        "error: OUT_OF_RANGE: --forecast-error -0.1 (0 to 5)")] },
  { name := "JOB-simulate.R6 --lon and --forecast-error give BAD_NUMBER for a value that is not a number, and MISSING_VALUE with no value",
    run := allErrors [
      (["forecast", "--lon", "east"], "error: BAD_NUMBER: --lon east"),
      (["forecast", "--lon", "1e1"], "error: BAD_NUMBER: --lon 1e1"),
      (["forecast", "--forecast-error", "abc"], "error: BAD_NUMBER: --forecast-error abc"),
      (["forecast", "--forecast-error", ".5"], "error: BAD_NUMBER: --forecast-error .5"),
      (["forecast", "--lon"], "error: MISSING_VALUE: --lon"),
      (["forecast", "--forecast-error"], "error: MISSING_VALUE: --forecast-error"),
      (["forecast", "--days", "5", "--seed"], "error: MISSING_VALUE: --seed")] },
  { name := "JOB-simulate.R6 --lat, --pv, --days and --seed have the ranges and the errors of sim run",
    run := do
      let a ← allErrors [
        (["forecast", "--days", "0"], "error: OUT_OF_RANGE: --days 0 (1 to 3650)"),
        (["forecast", "--days", "3651"], "error: OUT_OF_RANGE: --days 3651 (1 to 3650)"),
        (["forecast", "--lat", "90.1"], "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)"),
        (["forecast", "--lat", "-90.1"], "error: OUT_OF_RANGE: --lat -90.1 (-90 to 90)"),
        (["forecast", "--pv", "100.1"], "error: OUT_OF_RANGE: --pv 100.1 (0 to 100)"),
        (["forecast", "--pv", "-1"], "error: OUT_OF_RANGE: --pv -1 (0 to 100)"),
        (["forecast", "--seed", "-1"], "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)"),
        (["forecast", "--seed", "4294967296"],
          "error: OUT_OF_RANGE: --seed 4294967296 (0 to 4294967295)"),
        (["forecast", "--days", "36.5"], "error: BAD_NUMBER: --days 36.5"),
        (["forecast", "--pv", "5kW"], "error: BAD_NUMBER: --pv 5kW"),
        (["forecast", "--lat"], "error: MISSING_VALUE: --lat")]
      let b ← allOf [
        expectJson ["forecast", "--lat", "90"], expectJson ["forecast", "--lat", "-90"],
        expectJson ["forecast", "--pv", "100"], expectJson ["forecast", "--pv", "0"],
        expectJson ["forecast", "--seed", "0"], expectJson ["forecast", "--seed", "4294967295"]]
      return firstSome [a, b] },
  { name := "JOB-simulate.R6 an --hour value that is close to a whole number gives BAD_NUMBER, and +5 is accepted",
    run := do
      let a ← allOf [
        expectError ["forecast", "--hour", " 2"] "error: BAD_NUMBER: --hour  2",
        expectStart ["forecast", "--hour", "2\n"] "error: BAD_NUMBER: --hour 2\n",
        expectError ["forecast", "--hour", "5."] "error: BAD_NUMBER: --hour 5.",
        expectError ["forecast", "--hour", ""] "error: BAD_NUMBER: --hour "]
      let r ← sim ["forecast", "--hour", "+5"]
      return firstSome [a,
        if r.code == 0 && (jsonEnds r.out).length == 96 then none
        else some s!"--hour +5: exit code {r.code}, stderr {repr r.err}"] },
  { name := "JOB-simulate.R6 an extra word and an option of another command give UNKNOWN_OPTION",
    run := allErrors [
      (["forecast", "now"], "error: UNKNOWN_OPTION: now"),
      (["forecast", "--colour", "red"], "error: UNKNOWN_OPTION: --colour"),
      (["forecast", "--monthly"], "error: UNKNOWN_OPTION: --monthly"),
      (["forecast", "--load", "10"], "error: UNKNOWN_OPTION: --load"),
      (["forecast", "--policy", "static"], "error: UNKNOWN_OPTION: --policy")] }
]

def r7Checks (cache : Cache) : List Check := [
  -- JOB-simulate.R7
  { name := "JOB-simulate.R7 sim policy run prints the 13 lines in order and exits with 0",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (firstWords r.out == policyLabels, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R7 each line of sim policy run has its label to column 19 and a value with its unit",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      let ls := lines r.out
      let bad := (List.range 13).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (policyLabels.getD i "") &&
          (if i < 3 then w.length == 2
           else if i == 10 then
             w.length == 2 && w.getD 1 "" != "" && (w.getD 1 "").toList.all Char.isDigit
           else if i < 10 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
      return if r.code != 0 || ls.length != 13 then some s!"stdout is {repr r.out}"
        else match bad with
          | some i => some s!"the line {ls[i]?} has the wrong form"
          | none => none },
  { name := "JOB-simulate.R7 the first three lines show static, 365 days and seed 1",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      let want := [row "policy" "static", row "days" "365", row "seed" "1"]
      return if r.code == 0 && (lines r.out).take 3 == want then none
        else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R7 --policy dynamic --days 30 --lat 45 --seed 9 shows the totals of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "dynamic", "--days", "30", "--lat", "45",
        "--seed", "9"]
      return runShows r "dynamic" 30 9 (runHome homeLat45 pDyn 9 30).totals },
  -- The line has no --days. The check adds --days 30, so that the run stays short.
  { name := "JOB-simulate.R7 --policy precomputed --target 8 --min-solar 1 shows the totals of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "precomputed", "--target", "8",
        "--min-solar", "1", "--days", "30"]
      let p := Policy.precomputed { defaultPlan with targetKwh := 8.0, minSolarKwh := 1.0 }
      return runShows r "precomputed" 30 1 (runHome defaultHome p 1 30).totals },
  { name := "JOB-simulate.R7 --heat-hours 0 shows a heating of 0.0 kWh and a backstop above 0.0 kWh",
    run := do
      let r ← cachedSim cache ["policy", "run", "--heat-hours", "0"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (lineOf r.out "heating" == some (row "heating" "0.0 kWh"),
          s!"the heating line is {lineOf r.out "heating"}"),
        ((numOf r.out "backstop").getD 0.0 > 0.0, s!"the backstop value is {valueOf r.out "backstop"}")] },
  { name := "JOB-simulate.R7 --tank 0 --draw-cv 0 shows an unmet hot water of 2190.0 kWh and no heating",
    run := do
      let r ← sim ["policy", "run", "--tank", "0", "--draw-cv", "0"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (numNear r.out "unmet-hot-water" 2190.0 0.1,
          s!"the unmet-hot-water value is {valueOf r.out "unmet-hot-water"}"),
        (numNear r.out "heating" 0.0 1e-9, s!"the heating value is {valueOf r.out "heating"}"),
        (numNear r.out "backstop" 0.0 1e-9, s!"the backstop value is {valueOf r.out "backstop"}")] },
  { name := "JOB-simulate.R7 --element 0.2 --heat-hours 0 --days 90 shows an unmet hot water and cold hours",
    run := do
      let r ← sim ["policy", "run", "--element", "0.2", "--heat-hours", "0", "--days", "90"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((numOf r.out "unmet-hot-water").getD 0.0 > 0.0,
          s!"the unmet-hot-water value is {valueOf r.out "unmet-hot-water"}"),
        ((numOf r.out "cold-hours").getD 0.0 > 0.0,
          s!"the cold-hours value is {valueOf r.out "cold-hours"}")] },
  { name := "JOB-simulate.R7 the default run shows an unmet hot water of 0.0 kWh and 0 cold hours",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (lineOf r.out "unmet-hot-water" == some (row "unmet-hot-water" "0.0 kWh"),
          s!"the unmet-hot-water line is {lineOf r.out "unmet-hot-water"}"),
        (lineOf r.out "cold-hours" == some (row "cold-hours" "0"),
          s!"the cold-hours line is {lineOf r.out "cold-hours"}")] },
  { name := "JOB-simulate.R7 --seed 5 gives the same output two times",
    run := do
      let a ← sim ["policy", "run", "--seed", "5"]
      let b ← sim ["policy", "run", "--seed", "5"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 13
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R7 --policy wild gives UNKNOWN_POLICY, and so does a name that differs by its case",
    run := do
      let a ← expectError (pr ["--policy", "wild"])
        "error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)"
      let b ← expectError (pr ["--policy", "Static"])
        "error: UNKNOWN_POLICY: Static (static, precomputed, dynamic)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R7 --seeds, --strategy and --monthly give UNKNOWN_OPTION",
    run := allErrors [
      (pr ["--seeds", "3"], "error: UNKNOWN_OPTION: --seeds"),
      (pr ["--strategy", "greedy"], "error: UNKNOWN_OPTION: --strategy"),
      (pr ["--monthly"], "error: UNKNOWN_OPTION: --monthly")] },
  { name := "JOB-simulate.R7 each error gives empty stdout and exit code 2",
    run := allEmptyOut [
      pr ["--policy", "wild"], pr ["--policy", "Static"], pr ["--seeds", "3"],
      pr ["--strategy", "greedy"], pr ["--monthly"]] },
  -- The checks below also prove the names of the policies, the routing of each option, and each
  -- error code of `sim policy run`.
  { name := "JOB-simulate.R7 each policy name is accepted and shown on the first line",
    run := allOf (["static", "precomputed", "dynamic"].map (fun n => do
      let r ← sim (cheap ["--policy", n])
      return if r.code == 0 && (lines r.out).head? == some (row "policy" n) &&
          firstWords r.out == policyLabels then none
        else some s!"--policy {n}: exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}")) },
  { name := "JOB-simulate.R7 --lat, --pv, --load, --flex, --battery and --power go to their own part of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--days", "30", "--seed", "3", "--lat", "30",
        "--pv", "7.5", "--load", "15", "--flex", "1.5", "--battery", "4", "--power", "2"]
      return runShows r "static" 30 3 (runHome homeSiteOpts pStatic 3 30).totals },
  { name := "JOB-simulate.R7 the --flex default is 3, or the --load value when that is less",
    run := do
      let a ← sim (cheap ["--load", "2", "--lat", "45"])
      let b ← sim (cheap ["--load", "4", "--lat", "45"])
      let ha : HomeSetup := { defaultHome with site := site 45 5 2 2 }
      let hb : HomeSetup := { defaultHome with site := site 45 5 4 3 }
      return firstSome [
        (runShows a "static" 3 1 (runHome ha pStatic 1 3).totals).map (s!"--load 2: " ++ ·),
        (runShows b "static" 3 1 (runHome hb pStatic 1 3).totals).map (s!"--load 4: " ++ ·)] },
  { name := "JOB-simulate.R7 --tank, --cut-in, --floor, --draw, --draw-cv, --heat-start, --heat-hours and --discharge-from go to their own part of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--days", "30", "--seed", "3", "--tank", "8",
        "--cut-in", "4", "--floor", "1.5", "--draw", "5", "--draw-cv", "0.4", "--heat-start", "9",
        "--heat-hours", "3", "--discharge-from", "16"]
      return runShows r "static" 30 3 (runHome homeTankOpts pStaticRun 3 30).totals },
  { name := "JOB-simulate.R7 --fetches, --forecast-error, --target, --min-solar and --discharge-from go to the precomputed policy",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "precomputed", "--days", "20", "--seed", "3",
        "--fetches", "4", "--forecast-error", "2", "--target", "9", "--min-solar", "1.5",
        "--discharge-from", "19"]
      return runShows r "precomputed" 20 3 (runHome homeFcOpts pPlanRun 3 20).totals },
  { name := "JOB-simulate.R7 --fetches, --forecast-error, --low, --target and --discharge-from go to the dynamic policy",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "dynamic", "--days", "20", "--seed", "3",
        "--fetches", "4", "--forecast-error", "2", "--low", "4", "--target", "9",
        "--discharge-from", "19"]
      return runShows r "dynamic" 20 3 (runHome homeFcOpts pDynRun 3 20).totals },
  { name := "JOB-simulate.R7 --policy with no value gives MISSING_VALUE, and a name with a space, or no name, gives UNKNOWN_POLICY",
    run := allErrors [
      (pr ["--policy"], "error: MISSING_VALUE: --policy"),
      (pr ["--policy", "static "], "error: UNKNOWN_POLICY: static  (static, precomputed, dynamic)"),
      (pr ["--policy", ""], "error: UNKNOWN_POLICY:  (static, precomputed, dynamic)"),
      (pr ["--policy", "dynamic", "--policy", "wild"],
        "error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)")] },
  { name := "JOB-simulate.R7 an extra word and an option of another command give UNKNOWN_OPTION",
    run := allErrors [
      (pr ["now"], "error: UNKNOWN_OPTION: now"),
      (pr ["--colour", "red"], "error: UNKNOWN_OPTION: --colour"),
      (pr ["--hour", "5"], "error: UNKNOWN_OPTION: --hour"),
      (pr ["--lon", "0"], "error: UNKNOWN_OPTION: --lon")] },
  { name := "JOB-simulate.R7 the options of sim run have their errors and their ranges in sim policy run",
    run := allErrors [
      (pr ["--days", "abc"], "error: BAD_NUMBER: --days abc"),
      (pr ["--days"], "error: MISSING_VALUE: --days"),
      (pr ["--days", "0"], "error: OUT_OF_RANGE: --days 0 (1 to 3650)"),
      (pr ["--days", "3651"], "error: OUT_OF_RANGE: --days 3651 (1 to 3650)"),
      (pr ["--seed", "-1"], "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)"),
      (pr ["--lat", "90.1"], "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)"),
      (pr ["--pv", "-1"], "error: OUT_OF_RANGE: --pv -1 (0 to 100)"),
      (pr ["--battery", "200.1"], "error: OUT_OF_RANGE: --battery 200.1 (0 to 200)"),
      (pr ["--power", "100.1"], "error: OUT_OF_RANGE: --power 100.1 (0 to 100)"),
      (pr ["--load", "0"], "error: OUT_OF_RANGE: --load 0 (0.1 to 1000)"),
      (pr ["--load", "10", "--flex", "10.5"], "error: OUT_OF_RANGE: --flex 10.5 (0 to 10)")] }
]

def r8Checks (cache : Cache) : List Check := [
  -- JOB-simulate.R8
  { name := "JOB-simulate.R8 sim policy compare prints the header and the rows thermostat, static, precomputed, dynamic and perfect-forecast",
    run := do
      let r ← cachedSim cache ["policy", "compare"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 6, s!"{ls.length} lines, want 6"),
        (Option.map words ls[0]? == some policyHeader, s!"the header is {ls[0]?}"),
        (firstWords r.out == "policy" :: rowNames, s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 6), "a row does not have six fields")] },
  { name := "JOB-simulate.R8 --seed 9 --lat 45 --days 90 shows the values of the home simulation in each row with one decimal",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--seed", "9", "--lat", "45", "--days", "90"]
      let bad := cmpLib90.find? (fun (n, t) =>
        match compareRow r.out n with
        | some w => !compareRowShows w t
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some (n, _) => some s!"the {n} row is wrong in {repr r.out}"
          | none => none },
  { name := "JOB-simulate.R8 the static row shows the same five values as sim policy run --seed 9 --lat 45",
    run := do
      let c ← cachedSim cache ["policy", "compare", "--seed", "9", "--lat", "45"]
      let r ← cachedSim cache ["policy", "run", "--seed", "9", "--lat", "45"]
      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
        valueOf r.out "import", valueOf r.out "export", valueOf r.out "backstop"]
      return match compareRow c.out "static" with
        | some w =>
          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?, w[5]?] then none
          else some s!"compare {w}, run {fromRun}"
        | none => some s!"no static row in {repr c.out}" },
  { name := "JOB-simulate.R8 --heat-hours 0 gives the static row the same five values as the thermostat row",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--heat-hours", "0"]
      let a := tailOfRow r.out "static"
      let b := tailOfRow r.out "thermostat"
      return if r.code == 0 && a.isSome && a == b then none
        else some s!"static {a}, thermostat {b}" },
  { name := "JOB-simulate.R8 --forecast-error 0 gives the perfect-forecast row the same five values as the precomputed row",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--forecast-error", "0"]
      let a := tailOfRow r.out "perfect-forecast"
      let b := tailOfRow r.out "precomputed"
      return if r.code == 0 && a.isSome && a == b then none
        else some s!"perfect-forecast {a}, precomputed {b}" },
  { name := "JOB-simulate.R8 --seed 9 --lat 45 --days 90 shows the perfect-forecast row of the precomputed policy with an error scale of 0",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--seed", "9", "--lat", "45", "--days", "90"]
      return match cmpLib90.find? (fun (n, _) => n == "perfect-forecast"),
          compareRow r.out "perfect-forecast" with
        | some (_, t), some w =>
          if r.code == 0 && compareRowShows w t then none
          else some s!"the perfect-forecast row is {w}, the totals are {repr t}"
        | _, _ => some s!"no perfect-forecast row in {repr r.out}" },
  { name := "JOB-simulate.R8 the static and the dynamic self-consumption are more than the thermostat self-consumption",
    run := do
      let r ← cachedSim cache ["policy", "compare"]
      return match firstOfRow r.out "thermostat", firstOfRow r.out "static",
          firstOfRow r.out "dynamic" with
        | some t, some s, some d =>
          if r.code == 0 && s > t && d > t then none
          else some s!"thermostat {t}, static {s}, dynamic {d}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R8 --policy and --seeds give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "compare", "--policy", "static"], "error: UNKNOWN_OPTION: --policy"),
      (["policy", "compare", "--seeds", "3"], "error: UNKNOWN_OPTION: --seeds")] },
  -- The checks below also prove the routing of each option, and each error code of
  -- `sim policy compare`. The options of the first check differ from each default.
  { name := "JOB-simulate.R8 each option goes to its own part of the home simulation in each row",
    run := do
      let r ← cachedSim cache (["policy", "compare", "--seed", "3", "--days", "20"] ++ optsAll)
      let bad := (rowSetupsP homeAll statOpts planOpts dynOpts).find? (fun (n, s, p) =>
        match compareRow r.out n with
        | some w => !compareRowShows w (runHome s p 3 20).totals
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some (n, _, _) => some s!"the {n} row is wrong in {repr r.out}"
          | none => none },
  { name := "JOB-simulate.R8 --strategy, --monthly and an extra word give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "compare", "--strategy", "greedy"], "error: UNKNOWN_OPTION: --strategy"),
      (["policy", "compare", "--monthly"], "error: UNKNOWN_OPTION: --monthly"),
      (["policy", "compare", "now"], "error: UNKNOWN_OPTION: now")] },
  { name := "JOB-simulate.R8 an option with no value gives MISSING_VALUE",
    run := allErrors [
      (["policy", "compare", "--days"], "error: MISSING_VALUE: --days"),
      (["policy", "compare", "--tank"], "error: MISSING_VALUE: --tank"),
      (["policy", "compare", "--days", "5", "--forecast-error"],
        "error: MISSING_VALUE: --forecast-error")] },
  { name := "JOB-simulate.R8 a value that is not a number gives BAD_NUMBER",
    run := allErrors [
      (["policy", "compare", "--days", "abc"], "error: BAD_NUMBER: --days abc"),
      (["policy", "compare", "--days", "36.5"], "error: BAD_NUMBER: --days 36.5"),
      (["policy", "compare", "--tank", "1e3"], "error: BAD_NUMBER: --tank 1e3"),
      (["policy", "compare", "--heat-hours", "2.5"], "error: BAD_NUMBER: --heat-hours 2.5")] },
  { name := "JOB-simulate.R8 a value out of its range gives OUT_OF_RANGE",
    run := allErrors [
      (["policy", "compare", "--days", "0"], "error: OUT_OF_RANGE: --days 0 (1 to 3650)"),
      (["policy", "compare", "--tank", "50.1"], "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)"),
      (["policy", "compare", "--forecast-error", "5.1"],
        "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"),
      (["policy", "compare", "--heat-start", "24"],
        "error: OUT_OF_RANGE: --heat-start 24 (0 to 23)"),
      (["policy", "compare", "--fetches", "11"], "error: OUT_OF_RANGE: --fetches 11 (1 to 10)"),
      (["policy", "compare", "--min-solar", "10.1"],
        "error: OUT_OF_RANGE: --min-solar 10.1 (0 to 10)"),
      (["policy", "compare", "--target", "50.1"], "error: OUT_OF_RANGE: --target 50.1 (0 to 50)"),
      (["policy", "compare", "--low", "50.1"], "error: OUT_OF_RANGE: --low 50.1 (0 to 50)")] }
]

def r9Checks (cache : Cache) : List Check := [
  -- JOB-simulate.R9
  { name := "JOB-simulate.R9 sim policy robust prints the header and the rows thermostat, static, precomputed, dynamic and perfect-forecast",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 6, s!"{ls.length} lines, want 6"),
        (Option.map words ls[0]? == some robustHeader, s!"the header is {ls[0]?}"),
        (firstWords r.out == "policy" :: rowNames, s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 9), "a row does not have nine fields")] },
  { name := "JOB-simulate.R9 each row shows the values of the home simulation for the evaluation over the seeds 1 to 10",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := robustLib.find? (fun (n, e) =>
        match compareRow r.out n with
        | some w => !robustRowShows w e
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some (n, e) => some s!"the {n} row is wrong in {repr r.out}; the evaluation is {repr e}"
          | none => none },
  { name := "JOB-simulate.R9 --seeds 1 --seed 4 gives the mean and the worst self-consumption of each row of sim policy compare --seed 4",
    run := do
      let a ← cachedSim cache ["policy", "robust", "--seeds", "1", "--seed", "4"]
      let c ← cachedSim cache ["policy", "compare", "--seed", "4"]
      let bad := rowNames.find? (fun n =>
        match compareRow a.out n, compareRow c.out n with
        | some x, some y => !(y[1]?.isSome && x[1]? == y[1]? && x[2]? == y[1]?)
        | _, _ => true)
      return if a.code != 0 || c.code != 0 then some s!"exit codes {a.code} and {c.code}"
        else match bad with
          | some n => some s!"the {n} row differs: robust {compareRow a.out n}, compare {compareRow c.out n}"
          | none => none },
  { name := "JOB-simulate.R9 the worst self-consumption of each row is not more than its mean",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := rowNames.find? (fun n =>
        match compareRow r.out n with
        | some w => worstAboveMean w
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some n => some s!"the {n} row has a worst self-consumption above its mean: {compareRow r.out n}"
          | none => none },
  { name := "JOB-simulate.R9 each row has an unmet draw of 0.0, 0 cold hours and safe yes",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := rowNames.find? (fun n =>
        match compareRow r.out n with
        | some w => !(w[6]? == some "0.0" && w[7]? == some "0" && w[8]? == some "yes")
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some n => some s!"the {n} row is {compareRow r.out n}"
          | none => none },
  { name := "JOB-simulate.R9 --element 0.2 --days 90 gives the thermostat row safe no and an unmet draw above 0.0",
    run := do
      let r ← sim ["policy", "robust", "--element", "0.2", "--days", "90"]
      let w := (compareRow r.out "thermostat").getD []
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (w.length == 9, s!"the thermostat row is {w}"),
        (w[8]? == some "no", s!"safe is {w[8]?}"),
        ((w[6]?.bind parseNum).getD 0.0 > 0.0, s!"unmet-kWh is {w[6]?}")] },
  -- The line has no --days. The check adds --days 30, so that the two runs stay short.
  { name := "JOB-simulate.R9 --seed 7 --seeds 3 gives the same output two times",
    run := do
      let a ← sim ["policy", "robust", "--seed", "7", "--seeds", "3", "--days", "30"]
      let b ← sim ["policy", "robust", "--seed", "7", "--seeds", "3", "--days", "30"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 6
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  -- The accepted run uses --days 1, so that 100 seeds stay cheap.
  { name := "JOB-simulate.R9 --seeds 0 and --seeds 101 give OUT_OF_RANGE, and --seeds 100 is accepted",
    run := do
      let a ← allErrors [
        (["policy", "robust", "--seeds", "0"], "error: OUT_OF_RANGE: --seeds 0 (1 to 100)"),
        (["policy", "robust", "--seeds", "101"], "error: OUT_OF_RANGE: --seeds 101 (1 to 100)")]
      let r ← sim ["policy", "robust", "--seeds", "100", "--days", "1"]
      return firstSome [a,
        if r.code == 0 && firstWords r.out == "policy" :: rowNames then none
        else some s!"--seeds 100: exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}"] },
  { name := "JOB-simulate.R9 --seeds 2.5 gives BAD_NUMBER",
    run := expectError ["policy", "robust", "--seeds", "2.5"] "error: BAD_NUMBER: --seeds 2.5" },
  -- The checks below also prove the routing of --seed, --seeds and the other options, and each
  -- error code of `sim policy robust`. The options of the first check differ from each default.
  { name := "JOB-simulate.R9 --seed 4 --seeds 3 and the options of the home give the evaluation over the seeds 4 to 6 in each row",
    run := do
      let r ← cachedSim cache (["policy", "robust", "--seed", "4", "--seeds", "3", "--days", "20"] ++
        optsAll)
      let bad := (rowSetupsP homeAll statOpts planOpts dynOpts).find? (fun (n, s, p) =>
        match compareRow r.out n with
        | some w => !robustRowShows w (evaluate s p 4 3 20)
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some (n, _, _) => some s!"the {n} row is wrong in {repr r.out}"
          | none => none },
  { name := "JOB-simulate.R9 --policy, --strategy, --monthly and an extra word give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "robust", "--policy", "static"], "error: UNKNOWN_OPTION: --policy"),
      (["policy", "robust", "--strategy", "greedy"], "error: UNKNOWN_OPTION: --strategy"),
      (["policy", "robust", "--monthly"], "error: UNKNOWN_OPTION: --monthly"),
      (["policy", "robust", "now"], "error: UNKNOWN_OPTION: now")] },
  { name := "JOB-simulate.R9 an option with no value gives MISSING_VALUE",
    run := allErrors [
      (["policy", "robust", "--seeds"], "error: MISSING_VALUE: --seeds"),
      (["policy", "robust", "--days"], "error: MISSING_VALUE: --days"),
      (["policy", "robust", "--seeds", "3", "--tank"], "error: MISSING_VALUE: --tank")] },
  { name := "JOB-simulate.R9 a value that is not a number gives BAD_NUMBER",
    run := allErrors [
      (["policy", "robust", "--seeds", "abc"], "error: BAD_NUMBER: --seeds abc"),
      (["policy", "robust", "--seeds", ""], "error: BAD_NUMBER: --seeds "),
      (["policy", "robust", "--seeds", "1e1"], "error: BAD_NUMBER: --seeds 1e1"),
      (["policy", "robust", "--seed", "1.5"], "error: BAD_NUMBER: --seed 1.5"),
      (["policy", "robust", "--tank", "5kW"], "error: BAD_NUMBER: --tank 5kW")] },
  { name := "JOB-simulate.R9 a value out of its range gives OUT_OF_RANGE",
    run := allErrors [
      (["policy", "robust", "--seeds", "-1"], "error: OUT_OF_RANGE: --seeds -1 (1 to 100)"),
      (["policy", "robust", "--seed", "-1"], "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)"),
      (["policy", "robust", "--days", "0"], "error: OUT_OF_RANGE: --days 0 (1 to 3650)"),
      (["policy", "robust", "--tank", "50.1"], "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)")] }
]

def r10Checks (cache : Cache) : List Check := [
  -- JOB-simulate.R10
  { name := "JOB-simulate.R10 sim policy tune --seeds 2 --days 30 starts with 704 candidates and 704 safe candidates",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls[0]? == some (row "candidates" "704"), s!"the first line is {ls[0]?}"),
        (ls[1]? == some (row "safe" "704"), s!"the second line is {ls[1]?}"),
        (firstWords r.out == ["candidates", "safe", "heat-start", "heat-hours", "discharge-from",
            "", "policy"] ++ rowNames, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R10 the best profile has a heat-start from 6 to 16, heat-hours from 1 to 8 and discharge-from from 15 to 22",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let hs := (valueOf r.out "heat-start").bind String.toNat?
      let hh := (valueOf r.out "heat-hours").bind String.toNat?
      let df := (valueOf r.out "discharge-from").bind String.toNat?
      return match hs, hh, df with
        | some a, some b, some c =>
          if r.code == 0 && 6 ≤ a && a ≤ 16 && 1 ≤ b && b ≤ 8 && 15 ≤ c && c ≤ 22 then none
          else some s!"heat-start {a}, heat-hours {b}, discharge-from {c}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R10 the profile is the best profile of the home simulation for these options",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let b := tune1.best
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (valueOf r.out "heat-start" == some (toString b.heatStart),
          s!"heat-start shows {valueOf r.out "heat-start"}, want {b.heatStart}"),
        (valueOf r.out "heat-hours" == some (toString b.heatHours),
          s!"heat-hours shows {valueOf r.out "heat-hours"}, want {b.heatHours}"),
        (valueOf r.out "discharge-from" == some (toString b.dischargeFrom),
          s!"discharge-from shows {valueOf r.out "discharge-from"}, want {b.dischargeFrom}")] },
  { name := "JOB-simulate.R10 the static row equals the static row of sim policy robust with the profile as options",
    run := do
      let t ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let hs := (valueOf t.out "heat-start").getD ""
      let hh := (valueOf t.out "heat-hours").getD ""
      let df := (valueOf t.out "discharge-from").getD ""
      let r ← cachedSim cache ["policy", "robust", "--seeds", "2", "--days", "30",
        "--heat-start", hs, "--heat-hours", hh, "--discharge-from", df]
      let a := compareRow t.out "static"
      let b := compareRow r.out "static"
      return if t.code == 0 && r.code == 0 && a.isSome && a == b then none
        else some s!"tune {a}, robust {b}" },
  { name := "JOB-simulate.R10 the thermostat, precomputed, dynamic and perfect-forecast rows equal the rows of sim policy robust",
    run := do
      let t ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let r ← cachedSim cache ["policy", "robust", "--seeds", "2", "--days", "30"]
      let bad := ["thermostat", "precomputed", "dynamic", "perfect-forecast"].find? (fun n =>
        let a := compareRow t.out n
        !(a.isSome && a == compareRow r.out n))
      return if t.code != 0 || r.code != 0 then some s!"exit codes {t.code} and {r.code}"
        else match bad with
          | some n => some s!"the {n} row differs: tune {compareRow t.out n}, robust {compareRow r.out n}"
          | none => none },
  { name := "JOB-simulate.R10 --seeds 2 --days 30 gives the same output two times",
    run := do
      let a ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let b ← sim ["policy", "tune", "--seeds", "2", "--days", "30"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 12
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R10 --heat-start, --heat-hours and --discharge-from give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "tune", "--heat-start", "10"], "error: UNKNOWN_OPTION: --heat-start"),
      (["policy", "tune", "--heat-hours", "4"], "error: UNKNOWN_OPTION: --heat-hours"),
      (["policy", "tune", "--discharge-from", "17"], "error: UNKNOWN_OPTION: --discharge-from")] },
  { name := "JOB-simulate.R10 --seeds 0 gives OUT_OF_RANGE",
    run := expectError ["policy", "tune", "--seeds", "0"] "error: OUT_OF_RANGE: --seeds 0 (1 to 100)" },
  -- The checks below also prove the form of the output, the default of --seeds, the routing of
  -- the options, the count of safe candidates, and each error code of `sim policy tune`.
  { name := "JOB-simulate.R10 the first five lines have a label to column 19 and a whole number, and the table has the header of sim policy robust",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let ls := lines r.out
      let labels := ["candidates", "safe", "heat-start", "heat-hours", "discharge-from"]
      let bad := (List.range 5).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (labels.getD i "") && w.length == 2 && w.getD 1 "" != "" &&
          (w.getD 1 "").toList.all Char.isDigit))
      return firstFail [
        (r.code == 0 && ls.length == 12, s!"exit code {r.code}, {ls.length} lines"),
        (bad.isNone, s!"the line {bad.bind (fun i => ls[i]?)} has the wrong form"),
        (ls[5]? == some "", s!"line 6 is {ls[5]?}, want blank"),
        (Option.map words ls[6]? == some robustHeader, s!"the header is {ls[6]?}")] },
  -- The run is 3 days, so that the tuning stays cheap. The default of --seeds is 5.
  { name := "JOB-simulate.R10 the default of --seeds is 5",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--days", "3"]
      return tuneShows r (tuneStatic defaultHome 1 5 3) },
  { name := "JOB-simulate.R10 --seed, --lat, --load, --flex, --tank, --cut-in, --floor, --draw and --draw-cv go to the search",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seed", "3", "--seeds", "1", "--days", "20",
        "--lat", "45", "--load", "15", "--flex", "1.5", "--tank", "8", "--cut-in", "4",
        "--floor", "1.5", "--draw", "5", "--draw-cv", "0.4"]
      return tuneShows r (tuneStatic homeTune 3 1 20) },
  -- A home with an element of 0.2 kW has candidates with an unmet draw. Thus the count of safe
  -- candidates must be the count of the library, not the count of candidates.
  { name := "JOB-simulate.R10 --element 0.2 --seeds 1 --days 20 shows the counts, the profile and the static row of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--element", "0.2", "--seeds", "1", "--days", "20"]
      return tuneShows r (tuneStatic homeElem02 1 1 20) },
  { name := "JOB-simulate.R10 --policy, --strategy and an extra word give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "tune", "--policy", "static"], "error: UNKNOWN_OPTION: --policy"),
      (["policy", "tune", "--strategy", "greedy"], "error: UNKNOWN_OPTION: --strategy"),
      (["policy", "tune", "now"], "error: UNKNOWN_OPTION: now")] },
  { name := "JOB-simulate.R10 an option with no value gives MISSING_VALUE",
    run := allErrors [
      (["policy", "tune", "--seeds"], "error: MISSING_VALUE: --seeds"),
      (["policy", "tune", "--days"], "error: MISSING_VALUE: --days"),
      (["policy", "tune", "--seeds", "2", "--tank"], "error: MISSING_VALUE: --tank")] },
  { name := "JOB-simulate.R10 a value that is not a number gives BAD_NUMBER",
    run := allErrors [
      (["policy", "tune", "--seeds", "2.5"], "error: BAD_NUMBER: --seeds 2.5"),
      (["policy", "tune", "--seeds", "abc"], "error: BAD_NUMBER: --seeds abc"),
      (["policy", "tune", "--days", "36.5"], "error: BAD_NUMBER: --days 36.5"),
      (["policy", "tune", "--tank", "1e3"], "error: BAD_NUMBER: --tank 1e3")] },
  { name := "JOB-simulate.R10 a value out of its range gives OUT_OF_RANGE",
    run := allErrors [
      (["policy", "tune", "--seeds", "101"], "error: OUT_OF_RANGE: --seeds 101 (1 to 100)"),
      (["policy", "tune", "--seeds", "-1"], "error: OUT_OF_RANGE: --seeds -1 (1 to 100)"),
      (["policy", "tune", "--days", "0"], "error: OUT_OF_RANGE: --days 0 (1 to 3650)"),
      (["policy", "tune", "--tank", "50.1"], "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)")] }
]

def r11Checks : List Check := [
  -- JOB-simulate.R11
  { name := "JOB-simulate.R11 --tank 0 and --tank 50 are accepted, and --tank 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--tank", "0"], cheap ["--tank", "50"]]
      let b ← expectError (pr ["--tank", "50.1"]) "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --element 0 and --element 20 are accepted, and --element 20.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--element", "0"], cheap ["--element", "20"]]
      let b ← expectError (pr ["--element", "20.1"]) "error: OUT_OF_RANGE: --element 20.1 (0 to 20)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --cut-in 0 and --cut-in 50 are accepted, and --cut-in 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--cut-in", "0"], cheap ["--cut-in", "50"]]
      let b ← expectError (pr ["--cut-in", "50.1"]) "error: OUT_OF_RANGE: --cut-in 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --floor 0 and --floor 50 are accepted, and --floor 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--floor", "0"], cheap ["--floor", "50"]]
      let b ← expectError (pr ["--floor", "50.1"]) "error: OUT_OF_RANGE: --floor 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --draw 0 and --draw 100 are accepted, and --draw 100.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--draw", "0"], cheap ["--draw", "100"]]
      let b ← expectError (pr ["--draw", "100.1"]) "error: OUT_OF_RANGE: --draw 100.1 (0 to 100)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --fetches 1 and --fetches 10 are accepted, and --fetches 0 and --fetches 11 give OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "precomputed", "--fetches", "1"],
        cheap ["--policy", "precomputed", "--fetches", "10"]]
      let b ← allErrors [
        (pr ["--policy", "precomputed", "--fetches", "0"], "error: OUT_OF_RANGE: --fetches 0 (1 to 10)"),
        (pr ["--policy", "precomputed", "--fetches", "11"],
          "error: OUT_OF_RANGE: --fetches 11 (1 to 10)")]
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --draw-cv 0 and --draw-cv 1 are accepted, and --draw-cv 1.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--draw-cv", "0"], cheap ["--draw-cv", "1"]]
      let b ← expectError (pr ["--draw-cv", "1.1"]) "error: OUT_OF_RANGE: --draw-cv 1.1 (0 to 1)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --forecast-error 0 and --forecast-error 5 are accepted, and --forecast-error 5.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--forecast-error", "0"], cheap ["--forecast-error", "5"]]
      let b ← expectError (pr ["--forecast-error", "5.1"])
        "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --heat-start 0 and --heat-start 23 are accepted, and --heat-start 24 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--heat-start", "0"], cheap ["--heat-start", "23"]]
      let b ← expectError (pr ["--heat-start", "24"]) "error: OUT_OF_RANGE: --heat-start 24 (0 to 23)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --heat-hours 0 and --heat-hours 24 are accepted, and --heat-hours 25 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--heat-hours", "0"], cheap ["--heat-hours", "24"]]
      let b ← expectError (pr ["--heat-hours", "25"]) "error: OUT_OF_RANGE: --heat-hours 25 (0 to 24)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --discharge-from 0 and --discharge-from 24 are accepted, and --discharge-from 25 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--discharge-from", "0"], cheap ["--discharge-from", "24"]]
      let b ← expectError (pr ["--discharge-from", "25"])
        "error: OUT_OF_RANGE: --discharge-from 25 (0 to 24)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --target 0 and --target 50 are accepted for the dynamic policy, and --target 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "dynamic", "--target", "0"],
        cheap ["--policy", "dynamic", "--target", "50"]]
      let b ← expectError (pr ["--policy", "dynamic", "--target", "50.1"])
        "error: OUT_OF_RANGE: --target 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --min-solar 0 and --min-solar 10 are accepted for the precomputed policy, and --min-solar 10.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "precomputed", "--min-solar", "0"],
        cheap ["--policy", "precomputed", "--min-solar", "10"]]
      let b ← expectError (pr ["--policy", "precomputed", "--min-solar", "10.1"])
        "error: OUT_OF_RANGE: --min-solar 10.1 (0 to 10)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --low 0 and --low 50 are accepted for the dynamic policy, and --low 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "dynamic", "--low", "0"],
        cheap ["--policy", "dynamic", "--low", "50"]]
      let b ← expectError (pr ["--policy", "dynamic", "--low", "50.1"])
        "error: OUT_OF_RANGE: --low 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 a whole-number option with a decimal point gives BAD_NUMBER",
    run := allErrors [
      (pr ["--heat-hours", "2.5"], "error: BAD_NUMBER: --heat-hours 2.5"),
      (pr ["--fetches", "2.5"], "error: BAD_NUMBER: --fetches 2.5"),
      (pr ["--heat-start", "1.5"], "error: BAD_NUMBER: --heat-start 1.5"),
      (pr ["--discharge-from", "17.5"], "error: BAD_NUMBER: --discharge-from 17.5")] },
  { name := "JOB-simulate.R11 a value that is not a number gives BAD_NUMBER with its option and value",
    run := allErrors [
      (pr ["--tank", "abc"], "error: BAD_NUMBER: --tank abc"),
      (pr ["--element", "1e3"], "error: BAD_NUMBER: --element 1e3"),
      (pr ["--floor", ".5"], "error: BAD_NUMBER: --floor .5"),
      (pr ["--cut-in", "3,5"], "error: BAD_NUMBER: --cut-in 3,5"),
      (pr ["--draw-cv", "x"], "error: BAD_NUMBER: --draw-cv x"),
      (pr ["--draw", "5kW"], "error: BAD_NUMBER: --draw 5kW")] },
  { name := "JOB-simulate.R11 --tank with no value gives MISSING_VALUE",
    run := expectError (pr ["--tank"]) "error: MISSING_VALUE: --tank" },
  { name := "JOB-simulate.R11 --tank -1 gives OUT_OF_RANGE",
    run := expectError (pr ["--tank", "-1"]) "error: OUT_OF_RANGE: --tank -1 (0 to 50)" },
  -- The three runs are 10 days. The run with --tank 5 must differ, or an app that ignores
  -- --tank would also pass.
  { name := "JOB-simulate.R11 --tank 5 --tank 12 gives the result of --tank 12",
    run := do
      let days := ["policy", "run", "--days", "10"]
      let a ← sim (days ++ ["--tank", "5", "--tank", "12"])
      let b ← sim (days ++ ["--tank", "12"])
      let c ← sim (days ++ ["--tank", "5"])
      return firstFail [
        (a.code == 0 && b.code == 0 && c.code == 0, s!"exit codes {a.code}, {b.code} and {c.code}"),
        (firstWords a.out == policyLabels, s!"stdout is {repr a.out}"),
        (a.out == b.out, s!"the last value is not used: {repr a.out} and {repr b.out}"),
        (a.out != c.out, "--tank 5 and --tank 12 give the same result")] },
  -- A window that stops at the end of the day heats in the hours 20 to 23 only. Thus a window of
  -- 10 hours from hour 20 gives the result of a window of 4 hours from hour 20.
  { name := "JOB-simulate.R11 --heat-start 20 --heat-hours 10 exits with 0, because the window stops at the end of the day",
    run := do
      let base := ["policy", "run", "--days", "30", "--heat-start", "20"]
      let a ← sim (base ++ ["--heat-hours", "10"])
      let b ← sim (base ++ ["--heat-hours", "4"])
      return firstFail [
        (a.code == 0 && b.code == 0, s!"exit codes {a.code} and {b.code}, stderr {repr a.err}"),
        (firstWords a.out == policyLabels, s!"stdout is {repr a.out}"),
        (a.out == b.out, s!"10 hours: {repr a.out}, 4 hours: {repr b.out}")] },
  { name := "JOB-simulate.R11 sim policy fly gives UNKNOWN_COMMAND, and sim policy and sim policy help print the usage of the policy commands",
    run := do
      let a ← expectError ["policy", "fly"] "error: UNKNOWN_COMMAND: policy fly"
      let b ← sim ["policy"]
      let c ← sim ["policy", "help"]
      return firstSome [a,
        if b.code == 0 && (lines b.out).head? == some usagePolicy then none
        else some s!"sim policy: exit code {b.code}, stdout {repr b.out}",
        if c.code == 0 && (lines c.out).head? == some usagePolicy && c.out == b.out then none
        else some s!"sim policy help: exit code {c.code}, stdout {repr c.out}"] },
  { name := "JOB-simulate.R11 each error gives empty stdout and exit code 2",
    run := allEmptyOut [
      ["policy", "fly"], pr ["--tank", "50.1"], pr ["--element", "20.1"], pr ["--cut-in", "50.1"],
      pr ["--floor", "50.1"], pr ["--draw", "100.1"], pr ["--draw-cv", "1.1"],
      pr ["--policy", "precomputed", "--fetches", "0"],
      pr ["--policy", "precomputed", "--fetches", "11"], pr ["--forecast-error", "5.1"],
      pr ["--heat-start", "24"], pr ["--heat-hours", "25"], pr ["--discharge-from", "25"],
      pr ["--policy", "dynamic", "--target", "50.1"],
      pr ["--policy", "precomputed", "--min-solar", "10.1"],
      pr ["--policy", "dynamic", "--low", "50.1"], pr ["--heat-hours", "2.5"],
      pr ["--tank", "abc"], pr ["--tank"], pr ["--tank", "-1"]] },
  -- The checks below also prove the lowest value of each option, the other forms of a bad
  -- number, a missing value for each option, a sign, the last value, and the words of
  -- `sim policy`.
  { name := "JOB-simulate.R11 a value below the lowest of its option gives OUT_OF_RANGE",
    run := allErrors [
      (pr ["--element", "-0.1"], "error: OUT_OF_RANGE: --element -0.1 (0 to 20)"),
      (pr ["--cut-in", "-1"], "error: OUT_OF_RANGE: --cut-in -1 (0 to 50)"),
      (pr ["--floor", "-1"], "error: OUT_OF_RANGE: --floor -1 (0 to 50)"),
      (pr ["--draw", "-1"], "error: OUT_OF_RANGE: --draw -1 (0 to 100)"),
      (pr ["--draw-cv", "-0.1"], "error: OUT_OF_RANGE: --draw-cv -0.1 (0 to 1)"),
      (pr ["--forecast-error", "-0.1"], "error: OUT_OF_RANGE: --forecast-error -0.1 (0 to 5)"),
      (pr ["--heat-start", "-1"], "error: OUT_OF_RANGE: --heat-start -1 (0 to 23)"),
      (pr ["--heat-hours", "-1"], "error: OUT_OF_RANGE: --heat-hours -1 (0 to 24)"),
      (pr ["--discharge-from", "-1"], "error: OUT_OF_RANGE: --discharge-from -1 (0 to 24)"),
      (pr ["--policy", "precomputed", "--fetches", "-1"],
        "error: OUT_OF_RANGE: --fetches -1 (1 to 10)"),
      (pr ["--policy", "precomputed", "--min-solar", "-0.1"],
        "error: OUT_OF_RANGE: --min-solar -0.1 (0 to 10)"),
      (pr ["--policy", "dynamic", "--target", "-0.1"],
        "error: OUT_OF_RANGE: --target -0.1 (0 to 50)"),
      (pr ["--policy", "dynamic", "--low", "-0.1"], "error: OUT_OF_RANGE: --low -0.1 (0 to 50)")] },
  { name := "JOB-simulate.R11 a bad number gives BAD_NUMBER for the other options and for a close value",
    run := allErrors [
      (pr ["--heat-start", "x"], "error: BAD_NUMBER: --heat-start x"),
      (pr ["--discharge-from", "5kW"], "error: BAD_NUMBER: --discharge-from 5kW"),
      (pr ["--forecast-error", "abc"], "error: BAD_NUMBER: --forecast-error abc"),
      (pr ["--policy", "precomputed", "--fetches", "x"], "error: BAD_NUMBER: --fetches x"),
      (pr ["--policy", "precomputed", "--min-solar", "1e1"], "error: BAD_NUMBER: --min-solar 1e1"),
      (pr ["--policy", "dynamic", "--target", ".5"], "error: BAD_NUMBER: --target .5"),
      (pr ["--policy", "dynamic", "--low", "5."], "error: BAD_NUMBER: --low 5."),
      (pr ["--tank", "5 "], "error: BAD_NUMBER: --tank 5 "),
      (pr ["--tank", ""], "error: BAD_NUMBER: --tank "),
      (pr ["--tank", "-"], "error: BAD_NUMBER: --tank -"),
      (pr ["--tank", "+-5"], "error: BAD_NUMBER: --tank +-5")] },
  { name := "JOB-simulate.R11 each option with no value gives MISSING_VALUE",
    run := allErrors (policyOpts.map (fun (o, pre) =>
      (pr (pre ++ [o]), s!"error: MISSING_VALUE: {o}"))) },
  -- The runs are 10 days. The run with --tank 5 must differ from the default, or an app that
  -- ignores --tank would also pass.
  { name := "JOB-simulate.R11 --tank +5 gives the result of --tank 5",
    run := do
      let days := ["policy", "run", "--days", "10"]
      let a ← sim (days ++ ["--tank", "+5"])
      let b ← sim (days ++ ["--tank", "5"])
      let d ← sim days
      return firstFail [
        (a.code == 0 && b.code == 0 && d.code == 0, s!"exit codes {a.code}, {b.code} and {d.code}"),
        (firstWords a.out == policyLabels, s!"stdout is {repr a.out}"),
        (a.out == b.out, s!"+5 gives {repr a.out}, 5 gives {repr b.out}"),
        (a.out != d.out, "--tank 5 gives the result of the default tank")] },
  { name := "JOB-simulate.R11 the last value of an option counts before the range is read",
    run := do
      let days := ["policy", "run", "--days", "10"]
      let a ← sim (days ++ ["--tank", "99", "--tank", "12"])
      let b ← sim (days ++ ["--tank", "12"])
      let e ← expectError (pr ["--tank", "12", "--tank", "99"])
        "error: OUT_OF_RANGE: --tank 99 (0 to 50)"
      return firstSome [
        (firstFail [
          (a.code == 0 && b.code == 0, s!"exit codes {a.code} and {b.code}, stderr {repr a.err}"),
          (a.out == b.out && firstWords a.out == policyLabels,
            s!"--tank 99 --tank 12 gives {repr a.out}, --tank 12 gives {repr b.out}")]),
        e] },
  { name := "JOB-simulate.R11 a word of sim policy that differs by its case or a space gives UNKNOWN_COMMAND",
    run := allErrors [
      (["policy", "Run"], "error: UNKNOWN_COMMAND: policy Run"),
      (["policy", "run "], "error: UNKNOWN_COMMAND: policy run "),
      (["policy", "Help"], "error: UNKNOWN_COMMAND: policy Help")] }
]

def allChecks (cache : Cache) : List Check :=
  checks ++ r6Checks cache ++ r7Checks cache ++ r8Checks cache ++ r9Checks cache ++
    r10Checks cache ++ r11Checks

def main (args : List String) : IO UInt32 := do
  let cache ← mkCache
  let all := allChecks cache
  let sel := match args with
    | f :: _ => all.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => all
  let mut failed := 0
  for c in sel do
    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
    match res with
    | none => pure ()
    | some msg =>
      failed := failed + 1
      IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
