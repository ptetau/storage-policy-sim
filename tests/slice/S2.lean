import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Forecast
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
open StoragePolicySim

/-! Acceptance tests of slice S2 (the precomputed and the dynamic policy) of spec 001. -/

-- Helpers for numbers and text

def allNear (xs ys : List Float) (tol : Float) : Bool :=
  xs.length == ys.length
    && (List.zip xs ys).all (fun (p : Float × Float) => Harness.near p.1 p.2 tol)

def parseNum (s : String) : Option Float :=
  let neg : Bool := s.startsWith "-"
  let body : String := if neg then (s.drop 1).toString else s
  let sign : Float := if neg then -1.0 else 1.0
  match body.splitOn "." with
  | [a] => (a.toNat?).map (fun (n : Nat) => sign * n.toFloat)
  | [a, b] =>
    match a.toNat?, b.toNat? with
    | some x, some y => some (sign * (x.toFloat + y.toFloat / Float.pow 10.0 b.length.toFloat))
    | _, _ => none
  | _ => none

/-- A label padded with spaces to column 19 (18 characters). -/
def padLabel (s : String) : String :=
  s.pushn ' ' (18 - s.length)

def findLine (lines : List String) (label : String) : Option String :=
  lines.find? (fun (l : String) => (l.take 18).toString.trimAscii.toString == label)

def valueOf (l : String) : Option Float :=
  let rest : String := (l.drop 18).toString.trimAscii.toString
  let tok : String := (rest.splitOn " ").headD ""
  parseNum (tok.replace "%" "")

def numCheck (lines : List String) (label : String) (want : Float) : Bool × String :=
  let got : Option Float := (findLine lines label).bind valueOf
  match got with
  | some g => (Harness.near g want 0.0501, s!"{label}: got {g}, want {want}")
  | none => (false, s!"{label}: no value in the lines {lines}")

-- The home of the defaults (D6), built here from the interface

def myHome : Home :=
  { site := { latitude := -41.3, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }
    arrays := #[{ kw := 5.0, direction := 0.0, tilt := 0.0 }]
    battery := { capacityKwh := 10.0, powerKw := 5.0 }
    limits := { inverterKw := 0.0, exportKw := 0.0 }
    tanks := #[defaultTank]
    drawShares := #[1.0]
    drawKwhPerDay := 6.0
    drawCv := 0.25
    fetchesPerDay := 10
    errorScale := 1.0 }

def staticDefault : StaticParams :=
  { windows := #[{ heatStart := 10, heatHours := 4 }], dischargeFrom := 17, flexStart := 18 }

def staticNoHeat : StaticParams :=
  { windows := #[{ heatStart := 10, heatHours := 0 }], dischargeFrom := 17, flexStart := 18 }

def planDefault : PlanParams :=
  { targetKwh := #[10.5], minSolarKwh := 0.5, dischargeFrom := 17 }

def dynDefault : DynamicParams :=
  { lowKwh := #[5.25], targetKwh := #[10.5], dischargeFrom := 17 }

-- Helpers for the day-ahead plan (R3)

def forecastOfHours (pairs : List (Nat × Float)) : Array Float := Id.run do
  let mut a : Array Float := Array.replicate 24 0.0
  for p in pairs do
    a := a.set! p.1 p.2
  return a

def plan (target : Float) (fc : Array Float) (tank draw : Float) : Array Action :=
  planDay #[defaultTank] { targetKwh := #[target], minSolarKwh := 0.5, dischargeFrom := 17 }
    fc #[tank] #[draw] 0.0

def heatList (acts : Array Action) : List Float :=
  (List.range 24).map (fun (h : Nat) =>
    ((acts[h]?).map (fun (a : Action) => (a.heatKwh[0]?).getD (-1.0))).getD (-1.0))

def expectList (pairs : List (Nat × Float)) : List Float :=
  (List.range 24).map (fun (h : Nat) =>
    ((pairs.find? (fun (p : Nat × Float) => p.1 == h)).map (fun (p : Nat × Float) => p.2)).getD 0.0)

def checkPlan (acts : Array Action) (pairs : List (Nat × Float)) : Option String :=
  Harness.firstFail
    [ (acts.size == 24, s!"the plan has {acts.size} actions")
    , (allNear (heatList acts) (expectList pairs) 0.000000001,
        s!"got {heatList acts}, want {expectList pairs}") ]

def sunnyForecast : Array Float :=
  forecastOfHours [(9, 1.0), (10, 2.0), (11, 3.5), (12, 3.0), (13, 4.0), (14, 1.5)]

-- Helpers for the dynamic action (R4)

def dynParams : DynamicParams :=
  { lowKwh := #[4.0], targetKwh := #[9.0], dischargeFrom := 17 }

def mkObs (hour : Nat) (tank surplus rest : Float) : Observation :=
  { hour := hour, tankKwh := #[tank], socKwh := 5.0, surplusKwh := surplus
    forecastRestKwh := rest, flexLeftKwh := 0.0, startsToday := #[0], askedLastHour := #[false] }

def dynAsk (tank surplus rest : Float) : Float :=
  ((dynamicAction #[defaultTank] dynParams (mkObs 12 tank surplus rest)).heatKwh[0]?).getD (-1.0)

def askCheck (label : String) (got want : Float) : Bool × String :=
  (Harness.near got want 0.000000001, s!"{label}: got {got}, want {want}")

-- R3 tests

def t_plan_main : IO (Option String) :=
  pure (checkPlan (plan 9.0 sunnyForecast 4.0 6.0) [(10, 2.0), (11, 3.0), (12, 3.0), (13, 3.0)])

def t_plan_small_need : IO (Option String) :=
  pure (checkPlan (plan 9.0 sunnyForecast 9.0 0.5) [(13, 0.5)])

def t_plan_dark : IO (Option String) :=
  pure (checkPlan (plan 10.5 (forecastOfHours ((List.range 24).map (fun (h : Nat) => (h, 0.4)))) 0.0 0.5) [])

def t_plan_tie_earlier : IO (Option String) :=
  let fc := forecastOfHours [(10, 2.0), (11, 2.0), (12, 2.0), (13, 2.0), (14, 2.0)]
  pure (checkPlan (plan 9.0 fc 9.0 4.0) [(10, 3.0), (11, 1.0)])

def t_plan_min_solar_edge : IO (Option String) :=
  let fc := forecastOfHours [(12, 0.5), (13, 0.49)]
  pure (checkPlan (plan 10.5 fc 0.0 6.0) [(12, 3.0)])

def t_plan_need_not_negative : IO (Option String) :=
  pure (checkPlan (plan 9.0 sunnyForecast 10.5 0.5) [])

def t_plan_battery_gate : IO (Option String) :=
  let acts := plan 9.0 sunnyForecast 4.0 6.0
  let ok := (List.range 24).all (fun (h : Nat) =>
    (acts[h]?).any (fun (a : Action) => a.allowCharge && (a.allowDischarge == decide (h ≥ 17))))
  pure (Harness.firstFail [(acts.size == 24 && ok, "the battery gate of the plan is not charge always, discharge from 17")])

-- R4 tests

def t_dyn_surplus : IO (Option String) :=
  pure (Harness.firstFail
    [ askCheck "tank 8.0, surplus 5.0" (dynAsk 8.0 5.0 0.0) 1.0
    , askCheck "tank 5.0, surplus 5.0" (dynAsk 5.0 5.0 0.0) 3.0
    , askCheck "tank 9.0, surplus 5.0" (dynAsk 9.0 5.0 0.0) 0.0 ])

def t_dyn_surplus_smallest : IO (Option String) :=
  pure (Harness.firstFail [askCheck "tank 5.0, surplus 1.5" (dynAsk 5.0 1.5 0.0) 1.5])

def t_dyn_lack : IO (Option String) :=
  pure (Harness.firstFail
    [ askCheck "tank 3.0, forecast 0.5" (dynAsk 3.0 0.0 0.5) 1.0
    , askCheck "tank 3.0, forecast 1.0" (dynAsk 3.0 0.0 1.0) 0.0 ])

def t_dyn_lack_capped_by_element : IO (Option String) :=
  pure (Harness.firstFail [askCheck "tank 0.5, forecast 0.5" (dynAsk 0.5 0.0 0.5) 3.0])

def t_dyn_other_cases : IO (Option String) :=
  pure (Harness.firstFail
    [ askCheck "tank 5.0, no surplus, no forecast" (dynAsk 5.0 0.0 0.0) 0.0
    , askCheck "tank 3.0, no surplus, plenty of forecast" (dynAsk 3.0 0.0 6.0) 0.0 ])

def t_dyn_battery_gate : IO (Option String) :=
  let a16 := dynamicAction #[defaultTank] dynParams (mkObs 16 8.0 5.0 0.0)
  let a17 := dynamicAction #[defaultTank] dynParams (mkObs 17 8.0 5.0 0.0)
  pure (Harness.firstFail
    [ (a16.allowCharge && a17.allowCharge, "the battery may not charge")
    , (!a16.allowDischarge, "the battery may discharge at hour 16")
    , (a17.allowDischarge, "the battery may not discharge at hour 17") ])

-- R5 tests

def t_defaults_plan : IO (Option String) :=
  pure (Harness.firstFail
    [ (defaultPlan.targetKwh.size == 1, s!"targets {defaultPlan.targetKwh}")
    , (Harness.near ((defaultPlan.targetKwh[0]?).getD (-1.0)) 10.5 0.000000001, s!"targets {defaultPlan.targetKwh}")
    , (Harness.near defaultPlan.minSolarKwh 0.5 0.000000001, s!"minimum forecast {defaultPlan.minSolarKwh}")
    , (defaultPlan.dischargeFrom == 17, s!"discharge from {defaultPlan.dischargeFrom}") ])

def t_defaults_dynamic : IO (Option String) :=
  pure (Harness.firstFail
    [ (defaultDynamic.lowKwh.size == 1, s!"low levels {defaultDynamic.lowKwh}")
    , (Harness.near ((defaultDynamic.lowKwh[0]?).getD (-1.0)) 5.25 0.000000001, s!"low levels {defaultDynamic.lowKwh}")
    , (defaultDynamic.targetKwh.size == 1, s!"targets {defaultDynamic.targetKwh}")
    , (Harness.near ((defaultDynamic.targetKwh[0]?).getD (-1.0)) 10.5 0.000000001, s!"targets {defaultDynamic.targetKwh}")
    , (defaultDynamic.dischargeFrom == 17, s!"discharge from {defaultDynamic.dischargeFrom}") ])

def t_policy_names : IO (Option String) :=
  pure (Harness.firstFail
    [ ((Policy.static staticDefault).name == "static", s!"name {(Policy.static staticDefault).name}")
    , ((Policy.precomputed planDefault).name == "precomputed", s!"name {(Policy.precomputed planDefault).name}")
    , ((Policy.dynamic dynDefault).name == "dynamic", s!"name {(Policy.dynamic dynDefault).name}") ])

-- R9 tests

initialize dynRef : IO.Ref (Option HomeResult) ← IO.mkRef none

def getDynRun : IO HomeResult := do
  match (← dynRef.get) with
  | some r => pure r
  | none =>
    let r := runHome myHome (Policy.dynamic defaultDynamic) 7 365
    dynRef.set (some r)
    pure r

def t_precomputed_hours : IO (Option String) := do
  let home : Home := { myHome with fetchesPerDay := 1, errorScale := 0.0 }
  let res := runHome home (Policy.precomputed defaultPlan) 7 365
  let mut asks := 0
  let mut bad := 0
  let mut firstBad := ""
  for h in res.hours do
    let ask : Float := ((h.tanks[0]?).map (fun (t : TankHour) => t.askKwh)).getD 0.0
    if ask > 0.000000000001 then
      asks := asks + 1
      if h.pvKwh < 0.5 - 0.000001 then
        bad := bad + 1
        if firstBad == "" then firstBad := s!"day {h.day} hour {h.hour} solar {h.pvKwh} ask {ask}"
  return Harness.firstFail
    [ (res.hours.size == 8760, s!"{res.hours.size} hours")
    , (asks > 0, "the tank never asks for heat")
    , (bad == 0, s!"{bad} hours ask for heat with less than 0.5 kWh of solar, the first: {firstBad}") ]

def t_dynamic_hours : IO (Option String) := do
  let res ← getDynRun
  let mut asks := 0
  let mut bad := 0
  let mut firstBad := ""
  let mut prev : Float := 10.5
  for h in res.hours do
    let t : TankHour := (h.tanks[0]?).getD default
    if t.askKwh > 0.000000000001 then
      asks := asks + 1
      if !(h.pvKwh > h.houseLoadKwh - 0.000000001 || prev < 5.25) then
        bad := bad + 1
        if firstBad == "" then
          firstBad := s!"day {h.day} hour {h.hour} solar {h.pvKwh} load {h.houseLoadKwh} tank before {prev} ask {t.askKwh}"
    prev := t.energyKwh
  return Harness.firstFail
    [ (res.hours.size == 8760, s!"{res.hours.size} hours")
    , (asks > 0, "the tank never asks for heat")
    , (bad == 0, s!"{bad} hours ask for heat with no surplus and a tank at the low level or more, the first: {firstBad}") ]

def t_static_beats_thermostat : IO (Option String) := do
  let s := (runHome myHome (Policy.static staticDefault) 7 365).totals.selfConsumption
  let t := (runHome myHome (Policy.static staticNoHeat) 7 365).totals.selfConsumption
  return Harness.firstFail [(s > t, s!"static {s} is not above the thermostat {t}")]

def t_dynamic_beats_thermostat : IO (Option String) := do
  let d := (← getDynRun).totals.selfConsumption
  let t := (runHome myHome (Policy.static staticNoHeat) 7 365).totals.selfConsumption
  return Harness.firstFail [(d > t, s!"dynamic {d} is not above the thermostat {t}")]

def runLabels : List String :=
  [ "solar", "load", "import", "export", "curtailed", "heating", "backstop", "unmet-hot-water"
  , "cold-hours", "starts-per-day", "self-consumption", "self-sufficiency" ]

def simRunCheck (policyArg : String) (pol : Policy) (seed days : Nat) : IO (Option String) := do
  let o ← Harness.sim
    ["policy", "run", "--policy", policyArg, "--days", toString days, "--seed", toString seed]
  let lines : List String := (o.out.splitOn "\n").filter (fun (l : String) => l != "")
  let t := (runHome myHome pol seed days).totals
  let starts : Float := t.policyStarts.toFloat / days.toFloat
  let wants : List (String × Float) :=
    [ ("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh), ("export", t.exportKwh)
    , ("curtailed", t.curtailedKwh), ("heating", t.heatKwh), ("backstop", t.backstopKwh)
    , ("unmet-hot-water", t.unmetKwh), ("cold-hours", t.coldHours.toFloat)
    , ("starts-per-day", starts), ("self-consumption", t.selfConsumption)
    , ("self-sufficiency", t.selfSufficiency) ]
  let nums := wants.map (fun (p : String × Float) => numCheck lines p.1 p.2)
  return Harness.firstFail
    ([ (o.code == 0, s!"exit code {o.code}, stderr: {o.err}")
     , (lines.length == 15, s!"{lines.length} lines: {lines}")
     , (lines.head? == some (padLabel "policy" ++ policyArg), s!"first line {lines.head?}") ] ++ nums)

def t_cmd_dynamic : IO (Option String) :=
  simRunCheck "dynamic" (Policy.dynamic defaultDynamic) 9 30

def t_cmd_precomputed : IO (Option String) :=
  simRunCheck "precomputed" (Policy.precomputed defaultPlan) 9 30

-- R13 tests

def t_forecast_shape : IO (Option String) := do
  let o ← Harness.sim ["forecast"]
  let periods := (o.out.splitOn "\"period_end\"").length - 1
  let afterFirst : String := ((o.out.splitOn "\"period_end\":\"")[1]?).getD ""
  return Harness.firstFail
    [ (o.code == 0, s!"exit code {o.code}, stderr: {o.err}")
    , (o.out.startsWith "{\"forecasts\":[{\"pv_estimate\":", s!"stdout starts with {(o.out.take 60).toString}")
    , (periods == 96, s!"{periods} periods")
    , (afterFirst.startsWith "2024-12-31T13:00:00.0000000Z", s!"first period_end after: {(afterFirst.take 40).toString}")
    , (o.out.endsWith "\n", "stdout does not end with a line break") ]

def t_forecast_options : IO (Option String) := do
  let o ← Harness.sim
    ["forecast", "--hour", "24", "--lon", "170", "--forecast-error", "0.5", "--lat", "45",
     "--pv", "6", "--days", "30", "--seed", "3"]
  let afterFirst : String := ((o.out.splitOn "\"period_end\":\"")[1]?).getD ""
  return Harness.firstFail
    [ (o.code == 0, s!"exit code {o.code}, stderr: {o.err}")
    , (o.out.startsWith "{\"forecasts\":[{\"pv_estimate\":", s!"stdout starts with {(o.out.take 60).toString}")
    , (afterFirst.startsWith "2025-01-01T13:00:00.0000000Z",
        s!"first period_end after --hour 24: {(afterFirst.take 40).toString}") ]

def errCheck (o : Harness.Out) (line : String) : Option String :=
  Harness.firstFail
    [ (o.code == 2, s!"exit code {o.code}")
    , (o.out == "", s!"stdout {o.out}")
    , (o.err.trimAscii.toString == line, s!"stderr {o.err}, want {line}") ]

def t_forecast_hour_range : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--hour", "8760"]
  return errCheck o "error: OUT_OF_RANGE: --hour 8760 (0 to 8759)"

def t_forecast_hour_range_days : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--days", "30", "--hour", "720"]
  return errCheck o "error: OUT_OF_RANGE: --hour 720 (0 to 719)"

def t_forecast_unknown_option : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--battery", "5"]
  return errCheck o "error: UNKNOWN_OPTION: --battery"

def t_forecast_bad_number : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--hour", "abc"]
  return errCheck o "error: BAD_NUMBER: --hour abc"

def t_forecast_missing_value : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--hour"]
  return errCheck o "error: MISSING_VALUE: --hour"

def t_forecast_lon_range : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--lon", "180.5"]
  return errCheck o "error: OUT_OF_RANGE: --lon 180.5 (-180 to 180)"

def t_forecast_error_range : IO (Option String) := do
  let o ← Harness.sim ["forecast", "--forecast-error", "5.1"]
  return errCheck o "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"

def t_policy_name_refused : IO (Option String) := do
  let o ← Harness.sim ["policy", "run", "--policy", "dynamic;ls"]
  return errCheck o "error: UNKNOWN_POLICY: dynamic;ls (static, precomputed, dynamic)"

def tests : List Harness.Test :=
  [ ⟨"test_001_S2_R3_plan_hours_10_to_13_fill_the_need", t_plan_main⟩
  , ⟨"test_001_S2_R3_plan_small_need_goes_to_best_hour", t_plan_small_need⟩
  , ⟨"test_001_S2_R3_plan_dark_forecast_asks_nothing", t_plan_dark⟩
  , ⟨"test_001_S2_R3_plan_tie_goes_to_earlier_hour", t_plan_tie_earlier⟩
  , ⟨"test_001_S2_R3_plan_minimum_forecast_is_inclusive", t_plan_min_solar_edge⟩
  , ⟨"test_001_S2_R3_plan_need_never_below_zero", t_plan_need_not_negative⟩
  , ⟨"test_001_S2_R3_plan_battery_gate_like_static", t_plan_battery_gate⟩
  , ⟨"test_001_S2_R4_dynamic_surplus_takes_smallest_of_three", t_dyn_surplus⟩
  , ⟨"test_001_S2_R4_dynamic_surplus_limits_the_ask", t_dyn_surplus_smallest⟩
  , ⟨"test_001_S2_R4_dynamic_lack_when_forecast_is_short", t_dyn_lack⟩
  , ⟨"test_001_S2_R4_dynamic_lack_capped_by_element", t_dyn_lack_capped_by_element⟩
  , ⟨"test_001_S2_R4_dynamic_other_cases_ask_nothing", t_dyn_other_cases⟩
  , ⟨"test_001_S2_R4_dynamic_battery_gate_from_17", t_dyn_battery_gate⟩
  , ⟨"test_001_S2_R5_default_plan_values", t_defaults_plan⟩
  , ⟨"test_001_S2_R5_default_dynamic_values", t_defaults_dynamic⟩
  , ⟨"test_001_S2_R5_policy_names", t_policy_names⟩
  , ⟨"test_001_S2_R9_precomputed_heats_only_in_sunny_hours", t_precomputed_hours⟩
  , ⟨"test_001_S2_R9_dynamic_heats_only_with_surplus_or_low_tank", t_dynamic_hours⟩
  , ⟨"test_001_S2_R9_static_beats_thermostat_self_consumption", t_static_beats_thermostat⟩
  , ⟨"test_001_S2_R9_dynamic_beats_thermostat_self_consumption", t_dynamic_beats_thermostat⟩
  , ⟨"test_001_S2_R9_command_dynamic_matches_run_home", t_cmd_dynamic⟩
  , ⟨"test_001_S2_R9_command_precomputed_matches_run_home", t_cmd_precomputed⟩
  , ⟨"test_001_S2_R13_forecast_prints_96_periods_json", t_forecast_shape⟩
  , ⟨"test_001_S2_R13_forecast_accepts_its_options", t_forecast_options⟩
  , ⟨"test_001_S2_R13_forecast_hour_8760_out_of_range", t_forecast_hour_range⟩
  , ⟨"test_001_S2_R13_forecast_hour_range_follows_days", t_forecast_hour_range_days⟩
  , ⟨"test_001_S2_R13_forecast_battery_is_unknown_option", t_forecast_unknown_option⟩
  , ⟨"test_001_S2_R13_forecast_hour_not_a_number", t_forecast_bad_number⟩
  , ⟨"test_001_S2_R13_forecast_hour_missing_value", t_forecast_missing_value⟩
  , ⟨"test_001_S2_R13_forecast_lon_out_of_range", t_forecast_lon_range⟩
  , ⟨"test_001_S2_R13_forecast_error_scale_out_of_range", t_forecast_error_range⟩
  , ⟨"test_001_S2_R9_policy_name_is_refused_as_typed", t_policy_name_refused⟩ ]

def main (args : List String) : IO UInt32 := Harness.run tests args
