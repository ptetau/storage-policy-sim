import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
open StoragePolicySim

/-! Tests of slice S6: panel arrays (R19) and the limits of the inverter (R20). -/

-- Helpers

/-- Parses a plain number: an optional sign, digits, and an optional point with digits. -/
def parseNum (s : String) : Option Float := Id.run do
  let cs0 := s.toList
  let neg := match cs0 with
    | '-' :: _ => true
    | _ => false
  let cs := match cs0 with
    | '-' :: r => r
    | r => r
  let mut whole : Float := 0.0
  let mut frac : Float := 0.0
  let mut scale : Float := 0.1
  let mut seenPoint := false
  let mut digits : Nat := 0
  for c in cs do
    if c == '.' then
      seenPoint := true
    else if c.isDigit then
      let d : Float := (c.toNat - '0'.toNat).toFloat
      if seenPoint then
        frac := frac + d * scale
        scale := scale / 10.0
      else
        whole := whole * 10.0 + d
      digits := digits + 1
    else
      return none
  if digits == 0 then
    return none
  let v : Float := whole + frac
  return some (if neg then 0.0 - v else v)

/-- The number of the output line that starts with `label`, read before the unit. -/
def valueOf (out label : String) : Option Float :=
  let lines := out.splitOn "\n"
  match lines.find? (fun (l : String) => l.startsWith (label ++ " ")) with
  | none => none
  | some l =>
    let rest := (l.drop label.length).toString.trimAscii.toString
    let tok := (rest.splitOn " ").headD ""
    parseNum tok

def showOpt (o : Option Float) : String :=
  match o with
  | some v => toString v
  | none => "none"

def southSite : Site := { latitude := -41.3, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

def arrayOf (kw direction tilt : Float) : PanelArray :=
  { kw := kw, direction := direction, tilt := tilt }

/-- The energy of one array over the hours `lo` to `hi - 1` of one day, with a sunny sky. -/
def daySpan (arr : PanelArray) (day lo hi : Nat) : Float :=
  (List.range (hi - lo)).foldl
    (fun (a : Float) (i : Nat) => a + arrayOutput (-41.3) arr day (lo + i) Sky.sunny) 0.0

def flowNear (a b : Flow) (tol : Float) : Bool :=
  Harness.near a.directKwh b.directKwh tol && Harness.near a.chargeKwh b.chargeKwh tol
    && Harness.near a.dischargeKwh b.dischargeKwh tol && Harness.near a.exportKwh b.exportKwh tol
    && Harness.near a.importKwh b.importKwh tol && Harness.near a.lossKwh b.lossKwh tol
    && Harness.near a.socKwh b.socKwh tol

def battery10 : Battery := { capacityKwh := 10.0, powerKw := 5.0 }

def errTest (args : List String) (line : String) : IO (Option String) := do
  let r ← Harness.sim args
  return Harness.firstFail [
    (r.code == 2, s!"exit code {r.code}, stderr: {r.err}"),
    (r.err.trimAscii.toString == line, s!"stderr was: {r.err}, expected: {line}"),
    (r.out == "", s!"stdout not empty: {r.out}")]

/-- The home `generic` with an inverter limit of 3 kW and an export limit of 1 kW. -/
def limitedHome : Home := { defaultHome with limits := { inverterKw := 3.0, exportKw := 1.0 } }

/-- One run of 30 days with these limits, read by two tests. -/
def limitedRun : HomeResult := runHome limitedHome (Policy.static defaultStatic) 1 30

-- Tests

def tests : List Harness.Test := [
  { name := "test_001_S6_R19_flat_array_equals_old_scenario"
    run := do
      let hs := scenario southSite 7 365
      let arr := arrayOf 5.0 0.0 0.0
      let mut worst : Float := 0.0
      let mut total : Float := 0.0
      for h in hs do
        let d := (arrayOutput (-41.3) arr h.dayOfYear h.hour h.sky - h.pvKwh).abs
        if d > worst then worst := d
        total := total + h.pvKwh
      return Harness.firstFail [
        (hs.size == 8760, s!"scenario has {hs.size} hours"),
        (total > 100.0, s!"scenario solar total is only {total}"),
        (worst ≤ 0.000001, s!"largest difference to the old scenario: {worst}")] },
  { name := "test_001_S6_R19_east_array_gives_more_before_noon"
    run := do
      let arr := arrayOf 3.0 90.0 30.0
      let before := daySpan arr 0 0 12
      let after := daySpan arr 0 12 24
      return Harness.firstFail [
        (before > 0.0, s!"no energy before noon: {before}"),
        (before > after, s!"east array: before noon {before}, after noon {after}")] },
  { name := "test_001_S6_R19_west_array_gives_more_after_noon"
    run := do
      let arr := arrayOf 3.0 270.0 30.0
      let before := daySpan arr 0 0 12
      let after := daySpan arr 0 12 24
      return Harness.firstFail [
        (after > 0.0, s!"no energy after noon: {after}"),
        (after > before, s!"west array: before noon {before}, after noon {after}")] },
  { name := "test_001_S6_R19_north_beats_south_at_noon_in_southern_summer"
    run := do
      let north := arrayOutput (-41.3) (arrayOf 3.0 0.0 30.0) 171 12 Sky.sunny
      let south := arrayOutput (-41.3) (arrayOf 3.0 180.0 30.0) 171 12 Sky.sunny
      return Harness.firstFail [
        (north > 0.0, s!"north array gives {north}"),
        (north > south, s!"north {north}, south {south}")] },
  { name := "test_001_S6_R19_two_arrays_solar_is_sum_of_arrays"
    run := do
      let hs := scenario southSite 1 365
      let a := arrayOf 3.0 90.0 30.0
      let b := arrayOf 3.0 270.0 30.0
      let mut expected : Float := 0.0
      for h in hs do
        expected := expected + arrayOutput (-41.3) a h.dayOfYear h.hour h.sky
          + arrayOutput (-41.3) b h.dayOfYear h.hour h.sky
      let r ← Harness.sim ["policy", "run", "--array", "3:90:30", "--array", "3:270:30"]
      let v := valueOf r.out "solar"
      return Harness.firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr: {r.err}"),
        (v.isSome, s!"no solar line, stdout: {r.out}, stderr: {r.err}"),
        (Harness.near (v.getD 0.0) expected 0.06,
          s!"solar {showOpt v}, sum of the arrays {expected}, stderr: {r.err}")] },
  { name := "test_001_S6_R19_array_option_replaces_flat_array_of_home"
    run := do
      let hs := scenario southSite 1 365
      let mut flat : Float := 0.0
      for h in hs do
        flat := flat + h.pvKwh
      let r ← Harness.sim ["policy", "run", "--array", "3:90:30", "--array", "3:270:30"]
      let v := valueOf r.out "solar"
      return Harness.firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr: {r.err}"),
        (v.isSome, s!"no solar line, stdout: {r.out}, stderr: {r.err}"),
        (!(Harness.near (v.getD 0.0) flat 0.06),
          s!"solar {showOpt v} equals the flat 5 kW total {flat}, stderr: {r.err}")] },
  { name := "test_001_S6_R19_array_with_two_parts_is_bad_number"
    run := errTest ["policy", "run", "--array", "3:90"] "error: BAD_NUMBER: --array 3:90" },
  { name := "test_001_S6_R19_array_without_value_is_missing_value"
    run := errTest ["policy", "run", "--array"] "error: MISSING_VALUE: --array" },
  { name := "test_001_S6_R20_inverter_limit_sends_rest_to_battery_and_grid"
    run := do
      let lim : Limits := { inverterKw := 5.0, exportKw := 0.0 }
      let r := stepHourLimited lim battery10 0.0 true true 8.0 1.0
      return Harness.firstFail [
        (Harness.near r.flow.directKwh 1.0 0.000000001, s!"direct {r.flow.directKwh}, expected 1"),
        (Harness.near r.flow.chargeKwh 3.0 0.000000001, s!"charge {r.flow.chargeKwh}, expected 3"),
        (Harness.near r.flow.exportKwh 4.0 0.000000001, s!"export {r.flow.exportKwh}, expected 4"),
        (Harness.near r.curtailedKwh 0.0 0.000000001, s!"curtailed {r.curtailedKwh}, expected 0")] },
  { name := "test_001_S6_R20_export_limit_curtails_with_full_battery"
    run := do
      let lim : Limits := { inverterKw := 5.0, exportKw := 2.0 }
      let r := stepHourLimited lim battery10 10.0 true true 8.0 1.0
      return Harness.firstFail [
        (Harness.near r.flow.exportKwh 2.0 0.000000001, s!"export {r.flow.exportKwh}, expected 2"),
        (Harness.near r.curtailedKwh 5.0 0.000000001, s!"curtailed {r.curtailedKwh}, expected 5")] },
  { name := "test_001_S6_R20_zero_limits_equal_gated_step"
    run := do
      let lim : Limits := { inverterKw := 0.0, exportKw := 0.0 }
      let cases : List (Float × Bool × Bool × Float × Float) := [
        (0.0, true, true, 8.0, 1.0), (0.0, false, true, 3.0, 1.0),
        (1.9, false, false, 0.0, 2.0), (1.9, true, true, 0.0, 2.0),
        (1.9, false, true, 0.0, 2.0), (10.0, true, true, 8.0, 1.0),
        (5.0, true, false, 4.0, 0.5), (5.0, true, true, 0.0, 0.0)]
      let mut bad : List String := []
      for c in cases do
        let (soc, ac, ad, pv, load) := c
        let l := stepHourLimited lim battery10 soc ac ad pv load
        let g := stepHourGated battery10 soc ac ad pv load
        if !(flowNear l.flow g 0.000000001) || !(Harness.near l.curtailedKwh 0.0 0.000000001) then
          bad := s!"(soc {soc}, charge {ac}, discharge {ad}, pv {pv}, load {load}) limited {repr l.flow} curtailed {l.curtailedKwh}, gated {repr g}" :: bad
      return if bad.isEmpty then none else some (String.intercalate "; " bad) },
  { name := "test_001_S6_R20_inverter_limit_caps_house_and_grid_each_hour"
    run := do
      let mut worst : Float := 0.0
      for h in limitedRun.hours do
        let s := h.flow.directKwh + h.flow.dischargeKwh + h.flow.exportKwh
        if s > worst then worst := s
      return Harness.firstFail [
        (limitedRun.hours.size == 720, s!"run has {limitedRun.hours.size} hours"),
        (worst ≤ 3.0 + 0.000000001, s!"largest energy to house and grid in an hour: {worst}")] },
  { name := "test_001_S6_R20_export_limit_holds_in_each_hour"
    run := do
      let mut worst : Float := 0.0
      for h in limitedRun.hours do
        if h.flow.exportKwh > worst then worst := h.flow.exportKwh
      return Harness.firstFail [
        (limitedRun.hours.size == 720, s!"run has {limitedRun.hours.size} hours"),
        (worst ≤ 1.0 + 0.000000001, s!"largest export in an hour: {worst}")] },
  { name := "test_001_S6_R20_run_command_shows_curtailed_energy"
    run := do
      let r ← Harness.sim ["policy", "run", "--days", "30", "--inverter", "3", "--export-limit", "1"]
      let v := valueOf r.out "curtailed"
      return Harness.firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr: {r.err}"),
        (v.isSome, s!"no curtailed line, stdout: {r.out}, stderr: {r.err}"),
        ((v.getD 0.0) > 0.0, s!"curtailed {showOpt v}, stderr: {r.err}"),
        (Harness.near (v.getD 0.0) limitedRun.totals.curtailedKwh 0.06,
          s!"curtailed {showOpt v}, runHome total {limitedRun.totals.curtailedKwh}")] },
  { name := "test_001_S6_R20_inverter_above_range_is_out_of_range"
    run := errTest ["policy", "run", "--inverter", "100.1"]
      "error: OUT_OF_RANGE: --inverter 100.1 (0 to 100)" },
  { name := "test_001_S6_R20_export_limit_above_range_is_out_of_range"
    run := errTest ["policy", "run", "--export-limit", "100.1"]
      "error: OUT_OF_RANGE: --export-limit 100.1 (0 to 100)" },
  { name := "test_001_S6_R20_negative_inverter_is_out_of_range"
    run := errTest ["policy", "run", "--inverter", "-1"]
      "error: OUT_OF_RANGE: --inverter -1 (0 to 100)" }
]

def main (args : List String) : IO UInt32 := Harness.run tests args
