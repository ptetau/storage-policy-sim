import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim

open StoragePolicySim

/-! Tests of slice S9: `sim policy plan` (R23). -/

/-- One data line of the plan: the hour, the numbers (forecast, then the heating of each tank)
and the last word (the battery discharge). -/
structure Row where
  hour : Nat
  nums : Array Float
  gate : String
  deriving Inhabited

def isDigits (s : String) : Bool := s.length > 0 && s.toList.all Char.isDigit

/-- Parses an unsigned or signed decimal such as `3`, `0.5` or `-1.25`. -/
def parseF (s0 : String) : Option Float :=
  let neg := s0.startsWith "-"
  let body := if neg then (s0.drop 1).toString else s0
  let sg := fun (x : Float) => if neg then 0.0 - x else x
  match body.splitOn "." with
  | [a] => if isDigits a then some (sg a.toNat!.toFloat) else none
  | [a, b] =>
    if isDigits a && isDigits b then
      some (sg (a.toNat!.toFloat + b.toNat!.toFloat / Float.pow 10.0 b.length.toFloat))
    else none
  | _ => none

def cleanToken (t : String) : String :=
  if t.endsWith "kWh" then (t.take (t.length - 3)).toString else t

def tokens (line : String) : List String :=
  ((line.splitOn " ").map cleanToken).filter (fun (t : String) => t != "")

def nonEmptyLines (s : String) : List String :=
  (s.splitOn "\n").filter (fun (l : String) => l.trimAscii.toString != "")

/-- Parses a data line, or gives the reason. -/
def parseRow (line : String) : Except String Row :=
  let ts := (tokens line).toArray
  if ts.size < 4 then .error s!"too few columns in line: {line}"
  else
    let hourTok := ((ts[0]!).splitOn ":").head!
    if !isDigits hourTok then .error s!"hour column is not a number in line: {line}"
    else
      let mids := (ts.extract 1 (ts.size - 1)).map parseF
      if mids.any (fun (o : Option Float) => o.isNone) then
        .error s!"a number column does not parse in line: {line}"
      else
        .ok { hour := hourTok.toNat!, nums := mids.map (fun (o : Option Float) => o.getD 0.0),
              gate := ts[ts.size - 1]! }

/-- The header line, then 24 data rows. -/
def parsePlan (out : String) : Except String (Array Row) := do
  let ls := nonEmptyLines out
  if ls.length != 25 then
    throw s!"expected a header and 24 lines, got {ls.length} non-empty lines: {out}"
  let mut rows : Array Row := #[]
  for l in ls.drop 1 do
    let r ← parseRow l
    rows := rows.push r
  return rows

def planArgs (extra : List String) : List String := ["policy", "plan"] ++ extra

def mineHome : Home := (homeNamed "mine").getD defaultHome

def precomputedRun (home : Home) (seed days : Nat) : HomeResult :=
  runHome home (Policy.precomputed defaultPlan) seed days

/-- Runs `sim policy plan` and parses it. -/
def getPlan (extra : List String) : IO (Except String (Array Row)) := do
  let r ← Harness.sim (planArgs extra)
  if r.code != 0 then
    return .error s!"exit code {r.code}, stderr: {r.err}"
  return (match parsePlan r.out with
    | .ok rows => .ok rows
    | .error e => .error (e ++ s!" (stderr: {r.err})"))

def errCase (extra : List String) (expected : String) : IO (Option String) := do
  let r ← Harness.sim (planArgs extra)
  return Harness.firstFail [
    (r.code == 2, s!"exit code {r.code}, expected 2, stderr: {r.err}"),
    (r.err.trimAscii.toString == expected, s!"stderr is '{r.err}', expected '{expected}'"),
    (r.out == "", s!"stdout is not empty: {r.out}")]

/-- Index of the first hour of a day in the run. -/
def hourAt (res : HomeResult) (day hour : Nat) : Option HomeHour := res.hours[day * 24 + hour]?

/-- Checks that each row of the plan holds the request of the same hour of the run, with one decimal. -/
def heatingMatches (rows : Array Row) (res : HomeResult) (day tanks : Nat) : Option String := Id.run do
  for r in rows do
    match hourAt res day r.hour with
    | none => return some s!"runHome has no hour {r.hour} of day {day}"
    | some hh =>
      if r.nums.size != tanks + 1 then
        return some s!"hour {r.hour}: expected {tanks + 1} numbers, got {r.nums.size}"
      for i in [0:tanks] do
        let asked := (hh.tanks[i]!).askKwh
        let shown := r.nums[i + 1]!
        if !Harness.near shown asked 0.0501 then
          return some s!"day {day} hour {r.hour} tank {i}: plan shows {shown}, runHome asks {asked}"
  return none

def askedInDay (res : HomeResult) (day : Nat) : Float := Id.run do
  let mut s := 0.0
  for h in [0:24] do
    match hourAt res day h with
    | some hh => for t in hh.tanks do s := s + t.askKwh
    | none => pure ()
  return s

def tests : List Harness.Test := [
  { name := "test_001_S9_R23_plan_has_header_and_24_hour_rows_for_mine_day_10"
    run := do
      let r ← Harness.sim (planArgs ["--home", "mine", "--day", "10"])
      if r.code != 0 then return some s!"exit code {r.code}, stderr: {r.err}"
      let ls := nonEmptyLines r.out
      let firstIsHeader := match ls.head? with
        | some l => (parseRow l).toOption.isNone
        | none => false
      match parsePlan r.out with
      | .error e => return some (e ++ s!" (stderr: {r.err})")
      | .ok rows =>
        let hoursOk := (List.range 24).all (fun (h : Nat) => (rows[h]?.map (fun (x : Row) => x.hour)) == some h)
        let gatesOk := rows.all (fun (x : Row) => x.gate == "yes" || x.gate == "no")
        let colsOk := rows.all (fun (x : Row) => x.nums.size == 3)
        return Harness.firstFail [
          (r.err == "", s!"stderr is not empty: {r.err}"),
          (firstIsHeader, s!"the first line is not a header: {ls.head?}"),
          (hoursOk, s!"the hours are not 0 to 23 in order: {rows.map (fun (x : Row) => x.hour)}"),
          (colsOk, "each row needs the forecast and the heating of 2 tanks (3 numbers)"),
          (gatesOk, s!"the last word of each row must be yes or no: {rows.map (fun (x : Row) => x.gate)}")] },

  { name := "test_001_S9_R23_forecast_column_is_plausible_for_mine_day_10"
    run := do
      match ← getPlan ["--home", "mine", "--day", "10"] with
      | .error e => return some e
      | .ok rows =>
        let fc := rows.map (fun (x : Row) => x.nums[0]!)
        let nonNeg := fc.all (fun (v : Float) => v >= 0.0)
        let total := fc.foldl (fun (a : Float) (v : Float) => a + v) 0.0
        return Harness.firstFail [
          (nonNeg, s!"a forecast is negative: {fc}"),
          (fc[0]! < 0.05, s!"the forecast at hour 0 is {fc[0]!}, expected 0.0 (night)"),
          (total > 1.0, s!"the forecast of the day adds up to {total}, expected sun on a summer day"),
          (fc[12]! > fc[0]!, s!"the forecast at noon {fc[12]!} is not above midnight {fc[0]!}")] },

  { name := "test_001_S9_R23_heating_of_each_tank_equals_runHome_precomputed_day_10"
    run := do
      match ← getPlan ["--home", "mine", "--day", "10"] with
      | .error e => return some e
      | .ok rows =>
        let res := precomputedRun mineHome 1 365
        let asked := askedInDay res 10
        if asked <= 0.0 then return some s!"runHome asks for no heat on day 10 ({asked}), the test is empty"
        return heatingMatches rows res 10 2 },

  { name := "test_001_S9_R23_heating_follows_seed_and_days_options"
    run := do
      match ← getPlan ["--home", "mine", "--day", "5", "--seed", "9", "--days", "30"] with
      | .error e => return some e
      | .ok rows =>
        let res := precomputedRun mineHome 9 30
        let asked := askedInDay res 5
        if asked <= 0.0 then return some s!"runHome asks for no heat on day 5 ({asked}), the test is empty"
        return heatingMatches rows res 5 2 },

  { name := "test_001_S9_R23_heat_only_in_hours_with_forecast_at_least_minimum"
    run := do
      match ← getPlan ["--home", "mine", "--day", "10"] with
      | .error e => return some e
      | .ok rows =>
        let bad := rows.filter (fun (x : Row) =>
          (x.nums[1]! > 0.0 || x.nums[2]! > 0.0) && x.nums[0]! < 0.45)
        let total := rows.foldl (fun (a : Float) (x : Row) => a + x.nums[1]! + x.nums[2]!) 0.0
        return Harness.firstFail [
          (bad.size == 0, s!"hours with heat and a forecast under 0.5 kWh: {bad.map (fun (x : Row) => x.hour)}"),
          (total > 0.0, "the plan of day 10 heats no tank")] },

  { name := "test_001_S9_R23_battery_gate_equals_runHome_allowDischarge_day_10"
    run := do
      match ← getPlan ["--home", "mine", "--day", "10"] with
      | .error e => return some e
      | .ok rows =>
        let res := precomputedRun mineHome 1 365
        for r in rows do
          match hourAt res 10 r.hour with
          | none => return some s!"runHome has no hour {r.hour} of day 10"
          | some hh =>
            let want := if hh.allowDischarge then "yes" else "no"
            if r.gate != want then
              return some s!"hour {r.hour}: plan says {r.gate}, runHome allows discharge = {hh.allowDischarge}"
        let g16 := rows[16]!.gate
        let g17 := rows[17]!.gate
        return Harness.firstFail [
          (g16 == "no", s!"hour 16 gate is {g16}, expected no (discharge from 17)"),
          (g17 == "yes", s!"hour 17 gate is {g17}, expected yes (discharge from 17)")] },

  { name := "test_001_S9_R23_no_day_option_prints_day_0"
    run := do
      let a ← Harness.sim (planArgs [])
      let b ← Harness.sim (planArgs ["--day", "0"])
      if a.code != 0 then return some s!"exit code {a.code}, stderr: {a.err}"
      if b.code != 0 then return some s!"exit code {b.code} with --day 0, stderr: {b.err}"
      match parsePlan a.out with
      | .error e => return some e
      | .ok rows =>
        let res := precomputedRun defaultHome 1 365
        let asked := askedInDay res 0
        if asked <= 0.0 then return some s!"runHome asks for no heat on day 0 ({asked}), the test is empty"
        match heatingMatches rows res 0 1 with
        | some m => return some m
        | none =>
          return Harness.firstFail [
            (a.out == b.out, s!"no --day differs from --day 0: '{a.out}' versus '{b.out}'")] },

  { name := "test_001_S9_R23_same_arguments_give_same_plan"
    run := do
      let a ← Harness.sim (planArgs ["--home", "mine", "--day", "10"])
      let b ← Harness.sim (planArgs ["--home", "mine", "--day", "10"])
      return Harness.firstFail [
        (a.code == 0, s!"exit code {a.code}, stderr: {a.err}"),
        (a.out == b.out, "two runs with the same arguments print different plans"),
        (a.out != "", "stdout is empty")] },

  { name := "test_001_S9_R23_last_day_364_is_accepted"
    run := do
      match ← getPlan ["--day", "364"] with
      | .error e => return some e
      | .ok rows =>
        let res := precomputedRun defaultHome 1 365
        return heatingMatches rows res 364 1 },

  { name := "test_001_S9_R23_day_365_with_365_days_is_out_of_range"
    run := errCase ["--day", "365"] "error: OUT_OF_RANGE: --day 365 (0 to 364)" },

  { name := "test_001_S9_R23_day_range_follows_days_option"
    run := do
      let bad ← errCase ["--days", "30", "--day", "30"] "error: OUT_OF_RANGE: --day 30 (0 to 29)"
      match bad with
      | some m => return some m
      | none =>
        match ← getPlan ["--days", "30", "--day", "29"] with
        | .error e => return some s!"--day 29 with --days 30: {e}"
        | .ok _ => return none },

  { name := "test_001_S9_R23_negative_day_is_out_of_range"
    run := errCase ["--day", "-1"] "error: OUT_OF_RANGE: --day -1 (0 to 364)" },

  { name := "test_001_S9_R23_fractional_or_text_day_is_bad_number"
    run := do
      let a ← errCase ["--day", "2.5"] "error: BAD_NUMBER: --day 2.5"
      match a with
      | some m => return some m
      | none => errCase ["--day", "abc"] "error: BAD_NUMBER: --day abc" },

  { name := "test_001_S9_R23_day_without_value_is_missing_value"
    run := errCase ["--day"] "error: MISSING_VALUE: --day" },

  { name := "test_001_S9_R23_unknown_option_is_refused"
    run := errCase ["--bogus", "1"] "error: UNKNOWN_OPTION: --bogus" }
]

def main (args : List String) : IO UInt32 := Harness.run tests args
