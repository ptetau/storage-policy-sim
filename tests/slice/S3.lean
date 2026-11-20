import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim

open StoragePolicySim

/-! Slice S3: compare the policies and prove no cold tank (R7, R15). -/

/-! ## Policies and homes -/

def staticP : Policy := Policy.static defaultStatic
def planP : Policy := Policy.precomputed defaultPlan
def dynP : Policy := Policy.dynamic defaultDynamic

/-- The static policy with 0 heating hours (the thermostat row). -/
def noHeatP : Policy :=
  Policy.static { defaultStatic with windows := #[({ heatStart := 10, heatHours := 0 } : TankWindow)] }

def defaultPolicies : List (String × Policy) :=
  [("static", staticP), ("precomputed", planP), ("dynamic", dynP)]

def homeLat45 : Home := { defaultHome with site := { defaultHome.site with latitude := 45.0 } }

def homeCv05 : Home := { defaultHome with drawCv := 0.5 }

def homeWeak : Home := { defaultHome with tanks := #[({ defaultTank with elementKw := 0.2 } : TankConfig)] }

def homeNoCutIn : Home :=
  { defaultHome with tanks := #[({ defaultTank with cutInKwh := 0.0, floorKwh := 0.0 } : TankConfig)] }

/-! ## Runs, computed once -/

def runsOf (home : Home) : Array (String × Nat × HomeResult) := Id.run do
  let mut acc : Array (String × Nat × HomeResult) := #[]
  for (n, p) in defaultPolicies do
    for s in [1, 2, 3, 4, 5] do
      acc := acc.push (n, s, runHome home p s 365)
  return acc

def baseRuns : Array (String × Nat × HomeResult) := runsOf defaultHome

def cv05Runs : Array (String × Nat × HomeResult) := runsOf homeCv05

def thermostatRun7 : HomeResult := runHome defaultHome noHeatP 7 365

def weakRun : HomeResult := runHome homeWeak noHeatP 1 365

def noCutInRun : HomeResult := runHome homeNoCutIn noHeatP 7 30

/-! ## Helpers -/

def full : Float := 10.5

def tol : Float := 0.000000001

def verdict (bad : List String) : Option String :=
  if bad.isEmpty then none else some (String.intercalate "; " bad)

def unmetHours (r : HomeResult) : Nat :=
  r.hours.foldl (fun (a : Nat) (h : HomeHour) =>
    if h.tanks.any (fun (t : TankHour) => t.unmetKwh > tol) then a + 1 else a) 0

def floorHours (r : HomeResult) : Nat :=
  r.hours.foldl (fun (a : Nat) (h : HomeHour) =>
    if h.tanks.any (fun (t : TankHour) => t.energyKwh < 2.1 - tol) then a + 1 else a) 0

def isFullAt (r : HomeResult) (i : Nat) : Bool :=
  match r.hours[i]? with
  | some h => h.tanks.any (fun (t : TankHour) => full - tol ≤ t.energyKwh)
  | none => false

def daysNotFull (r : HomeResult) (days : Nat) : Nat := Id.run do
  let mut n := 0
  for d in [0:days] do
    let mut ok := false
    for h in [0:24] do
      if isFullAt r (24 * d + h) then ok := true
    if !ok then n := n + 1
  return n

def energyAt (r : HomeResult) (i : Nat) : Float :=
  match r.hours[i]? with
  | some h => (h.tanks[0]!).energyKwh
  | none => 0.0

def backstopAt (r : HomeResult) (i : Nat) : Float :=
  match r.hours[i]? with
  | some h => (h.tanks[0]!).backstopKwh
  | none => 0.0

def perRunBad (rs : Array (String × Nat × HomeResult)) (what : String) (f : HomeResult → Nat) : List String :=
  rs.toList.filterMap (fun (x : String × Nat × HomeResult) =>
    let n := f x.2.2
    if n > 0 then some s!"{what}: policy {x.1} seed {x.2.1} has {n}" else none)

def sizeBad (rs : Array (String × Nat × HomeResult)) : List String :=
  rs.toList.filterMap (fun (x : String × Nat × HomeResult) =>
    if x.2.2.hours.size == 8760 then none
    else some s!"policy {x.1} seed {x.2.1} has {x.2.2.hours.size} hours")

def lines (s : String) : List String :=
  (s.splitOn "\n").filter (fun (l : String) => l.trimAscii.toString != "")

def tokens (l : String) : List String :=
  (l.splitOn " ").filter (fun (t : String) => t != "")

def parseNum (t : String) : Float := Id.run do
  let cs := t.toList.takeWhile (fun (c : Char) => c.isDigit || c == '.' || c == '-')
  let neg := cs.head? == some '-'
  let body := if neg then cs.drop 1 else cs
  let ip := body.takeWhile (fun (c : Char) => c.isDigit)
  let rest := (body.dropWhile (fun (c : Char) => c.isDigit)).drop 1
  let mut v : Float := 0.0
  for c in ip do
    v := v * 10.0 + (c.toNat - 48).toFloat
  let mut scale : Float := 0.1
  for c in rest do
    if c.isDigit then
      v := v + scale * (c.toNat - 48).toFloat
      scale := scale / 10.0
  return if neg then -v else v

def isNumTok (s : String) : Bool :=
  match s.toList.head? with
  | some c => c.isDigit || c == '-'
  | none => false

def rowValues (l : String) : List Float :=
  (((tokens l).drop 1).filter isNumTok).map parseNum

def sameVals (a b : List Float) (t : Float) : Bool :=
  a.length == b.length && (List.zip a b).all (fun (p : Float × Float) => Harness.near p.1 p.2 t)

def compareValues (home : Home) (p : Policy) (seed days : Nat) : List Float :=
  let t := (runHome home p seed days).totals
  [t.selfConsumption, t.selfSufficiency, t.importKwh, t.exportKwh, t.curtailedKwh, t.backstopKwh,
    t.policyStarts.toFloat / days.toFloat]

def errIs (o : Harness.Out) (msg : String) : Bool :=
  o.code == 2 && o.out == "" && o.err.trimAscii.toString == msg

def headerTokens : List String :=
  tokens "policy self-consumption-% self-sufficiency-% import-kWh export-kWh curtailed-kWh backstop-kWh starts-per-day"

def rowNames : List String := ["thermostat", "static", "precomputed", "dynamic", "perfect-forecast"]

def rowOf (ls : List String) (n : String) : Option String :=
  ls.find? (fun (l : String) => (tokens l).head? == some n)

def show' (o : Harness.Out) : String := s!"code {o.code}, stdout [{o.out}], stderr [{o.err}]"

/-! ## R7: no cold tank -/

def t_unmet_zero : IO (Option String) := do
  return verdict (sizeBad baseRuns ++ perRunBad baseRuns "hours with unmet draw" unmetHours)

def t_floor : IO (Option String) := do
  return verdict (sizeBad baseRuns ++ perRunBad baseRuns "hours below 2.1 kWh" floorHours)

def t_full_each_day : IO (Option String) := do
  return verdict (sizeBad baseRuns
    ++ perRunBad baseRuns "days without a full tank" (fun (r : HomeResult) => daysNotFull r 365))

def t_spread_totals : IO (Option String) := do
  let bad := cv05Runs.toList.filterMap (fun (x : String × Nat × HomeResult) =>
    let t := x.2.2.totals
    if t.unmetKwh > tol || t.coldHours > 0 then
      some s!"policy {x.1} seed {x.2.1}: unmet {t.unmetKwh} kWh, cold hours {t.coldHours}"
    else none)
  return verdict (sizeBad cv05Runs ++ bad)

def t_spread_hours : IO (Option String) := do
  return verdict (sizeBad cv05Runs
    ++ perRunBad cv05Runs "hours with unmet draw" unmetHours
    ++ perRunBad cv05Runs "hours below 2.1 kWh" floorHours
    ++ perRunBad cv05Runs "days without a full tank" (fun (r : HomeResult) => daysNotFull r 365))

def t_thermostat_backstop : IO (Option String) := do
  let t := thermostatRun7.totals
  return verdict ((if t.backstopKwh > 500.0 then [] else [s!"backstop {t.backstopKwh} kWh, want more than 500"])
    ++ (if t.heatKwh < tol then [] else [s!"heating {t.heatKwh} kWh, want 0"])
    ++ (if t.unmetKwh < tol then [] else [s!"unmet {t.unmetKwh} kWh, want 0"]))

def t_weak_element : IO (Option String) := do
  let t := weakRun.totals
  return verdict ((if t.unmetKwh > 0.0 then [] else [s!"unmet {t.unmetKwh} kWh, want more than 0"])
    ++ (if t.coldHours > 0 then [] else [s!"cold hours {t.coldHours}, want more than 0"]))

/-! Thermostat machine, seen through `runHome`. -/

/-- T1: a tank that starts an hour below the cut-in is heated by the backstop. -/
def t_thermostat_t1 : IO (Option String) := do
  let mut n := 0
  let mut bad : List String := []
  for i in [0:thermostatRun7.hours.size] do
    let before := if i == 0 then full else energyAt thermostatRun7 (i - 1)
    if before < 5.25 - tol then
      n := n + 1
      if !(backstopAt thermostatRun7 i > 0.0) then
        bad := bad ++ [s!"hour {i}: tank {before} kWh at the start, backstop {backstopAt thermostatRun7 i}"]
  let miss := if n == 0 then ["no hour started below the cut-in"] else []
  return verdict (miss ++ bad.take 3)

/-- A day d (1 to 29) of `noCutInRun` that starts after a full tank at hour 23 of the day before. -/
def guardDays : List Nat :=
  (List.range 30).filter (fun (d : Nat) => d ≥ 1 && isFullAt noCutInRun (24 * d - 1))

/-- T2: with no cut-in, the thermostat stays off until the guard hour, then heats a tank that was not full. -/
def t_thermostat_t2 : IO (Option String) := do
  let mut bad : List String := []
  for d in guardDays do
    let mut early := 0.0
    for h in [0:20] do
      early := early + backstopAt noCutInRun (24 * d + h)
    if early > tol then bad := bad ++ [s!"day {d}: backstop {early} kWh before hour 20"]
    if !(backstopAt noCutInRun (24 * d + 20) > 0.0) then
      bad := bad ++ [s!"day {d}: no backstop at hour 20 (tank {energyAt noCutInRun (24 * d + 19)} kWh)"]
  let miss := if guardDays.length < 10 then [s!"only {guardDays.length} days start from a full tank"] else []
  return verdict (miss ++ bad.take 3)

/-- T3: once the tank is full at or after the guard hour, the thermostat stops heating for the rest of the day. -/
def t_thermostat_t3 : IO (Option String) := do
  let mut bad : List String := []
  let mut seen := 0
  for d in guardDays do
    let mut found : Option Nat := none
    for h in [20:24] do
      if found.isNone && isFullAt noCutInRun (24 * d + h) then found := some h
    match found with
    | none => pure ()
    | some f =>
      seen := seen + 1
      for h in [f + 1:24] do
        if backstopAt noCutInRun (24 * d + h) > tol then
          bad := bad ++ [s!"day {d}: backstop {backstopAt noCutInRun (24 * d + h)} kWh at hour {h} after full at hour {f}"]
  let miss := if seen < 5 then [s!"only {seen} days reach a full tank in the evening"] else []
  return verdict (miss ++ bad.take 3)

/-! ## R15: sim policy compare -/

def t_compare_default : IO (Option String) := do
  let o ← Harness.sim ["policy", "compare"]
  let ls := lines o.out
  let head := match ls.head? with
    | some l => tokens l
    | none => []
  let names := (ls.drop 1).map (fun (l : String) => (tokens l).head?.getD "")
  let valuesOk := (ls.drop 1).all (fun (l : String) => (rowValues l).length == 7)
  return verdict ((if o.code == 0 then [] else [s!"exit code {o.code}"])
    ++ (if head == headerTokens then [] else [s!"header {head}"])
    ++ (if names == rowNames then [] else [s!"rows {names}"])
    ++ (if valuesOk then [] else ["a row has not 7 numeric values"])
    ++ (if o.err == "" then [] else [s!"stderr [{o.err}]"]))

def t_compare_values : IO (Option String) := do
  let o ← Harness.sim ["policy", "compare", "--seed", "9", "--lat", "45", "--days", "90"]
  let ls := lines o.out
  let spec : List (String × Home × Policy) :=
    [("thermostat", homeLat45, noHeatP), ("static", homeLat45, staticP),
     ("precomputed", homeLat45, planP), ("dynamic", homeLat45, dynP),
     ("perfect-forecast", { homeLat45 with errorScale := 0.0 }, planP)]
  let mut bad : List String := []
  for (n, h, p) in spec do
    match rowOf ls n with
    | none => bad := bad ++ [s!"row {n} missing"]
    | some l =>
      let want := compareValues h p 9 90
      if !(sameVals (rowValues l) want 0.0501) then
        bad := bad ++ [s!"row {n}: [{l}] want {want}"]
  return verdict ((if o.code == 0 then [] else [s!"exit code {o.code}, stderr [{o.err}]"]) ++ bad)

def t_compare_heat_hours_zero : IO (Option String) := do
  let o ← Harness.sim ["policy", "compare", "--heat-hours", "0", "--days", "60"]
  let ls := lines o.out
  let a := (rowOf ls "static").map (fun (l : String) => (tokens l).drop 1)
  let b := (rowOf ls "thermostat").map (fun (l : String) => (tokens l).drop 1)
  let ok := o.code == 0 && a.isSome && a == b
  return if ok then none else some s!"static row {a}, thermostat row {b}, {show' o}"

def t_compare_policy_unknown : IO (Option String) := do
  let o ← Harness.sim ["policy", "compare", "--policy", "static"]
  return if errIs o "error: UNKNOWN_OPTION: --policy" then none else some (show' o)

/-! Security floor: bad input is refused with one error line. -/

def t_compare_bad_input : IO (Option String) := do
  let cases : List (List String × String) :=
    [(["policy", "compare", "--tank", "51"], "error: OUT_OF_RANGE: --tank 51 (0 to 50)"),
     (["policy", "compare", "--tank", "abc"], "error: BAD_NUMBER: --tank abc"),
     (["policy", "compare", "--tank", "1;rm"], "error: BAD_NUMBER: --tank 1;rm"),
     (["policy", "compare", "--tank"], "error: MISSING_VALUE: --tank"),
     (["policy", "compare", "--bogus", "1"], "error: UNKNOWN_OPTION: --bogus"),
     (["policy", "compare", "--seeds", "3"], "error: UNKNOWN_OPTION: --seeds")]
  let mut bad : List String := []
  for (args, msg) in cases do
    let o ← Harness.sim args
    if !(errIs o msg) then bad := bad ++ [s!"{args}: {show' o}"]
  return verdict bad

/-! ## The tests -/

def tests : List Harness.Test := [
  { name := "test_001_S3_R7_generic_no_unmet_draw_in_any_hour", run := t_unmet_zero },
  { name := "test_001_S3_R7_generic_tank_never_below_floor", run := t_floor },
  { name := "test_001_S3_R7_generic_tank_full_each_day", run := t_full_each_day },
  { name := "test_001_S3_R7_spread_half_no_unmet_no_cold_hours", run := t_spread_totals },
  { name := "test_001_S3_R7_spread_half_no_unmet_floor_and_full_each_day", run := t_spread_hours },
  { name := "test_001_S3_R7_zero_heating_hours_all_heat_from_backstop", run := t_thermostat_backstop },
  { name := "test_001_S3_R7_weak_element_gives_unmet_and_cold_hours", run := t_weak_element },
  { name := "test_001_S3_R7_thermostat_T1_below_cut_in_backstop_heats", run := t_thermostat_t1 },
  { name := "test_001_S3_R7_thermostat_T2_guard_hour_heats_tank_not_full", run := t_thermostat_t2 },
  { name := "test_001_S3_R7_thermostat_T3_full_tank_stops_heating", run := t_thermostat_t3 },
  { name := "test_001_S3_R15_compare_prints_header_and_five_rows", run := t_compare_default },
  { name := "test_001_S3_R15_compare_rows_equal_runhome_values", run := t_compare_values },
  { name := "test_001_S3_R15_compare_heat_hours_zero_static_equals_thermostat", run := t_compare_heat_hours_zero },
  { name := "test_001_S3_R15_compare_refuses_policy_option", run := t_compare_policy_unknown },
  { name := "test_001_S3_R15_compare_refuses_bad_input", run := t_compare_bad_input }
]

def main (args : List String) : IO UInt32 := Harness.run tests args
