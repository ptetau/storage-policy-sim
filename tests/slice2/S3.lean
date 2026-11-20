import tests.slice.Harness
import StoragePolicySim.Simulation
import StoragePolicySim.PhysAppliances

open StoragePolicySim

def bat135 : Battery := { capacityKwh := 13.5, powerKw := 11.0 }

def fsum (a : Array Float) : Float := a.foldl (fun (x : Float) (y : Float) => x + y) 0.0

def maxOf (a : Array Float) : Float := a.foldl (fun (x : Float) (y : Float) => if y > x then y else x) 0.0

def minOf (a : Array Float) : Float := a.foldl (fun (x : Float) (y : Float) => if y < x then y else x) 1000000.0

/-- Absolute gap of the balance of one step. -/
def gap (pv load soc : Float) (r : LimitedFlow) : Float :=
  ((pv + r.flow.importKwh + (soc - r.flow.socKwh))
    - (load + r.flow.exportKwh + r.curtailedKwh + r.flow.lossKwh)).abs

def fmt (r : LimitedFlow) : String :=
  s!"charge={r.flow.chargeKwh} discharge={r.flow.dischargeKwh} export={r.flow.exportKwh} import={r.flow.importKwh} loss={r.flow.lossKwh} soc={r.flow.socKwh} curtailed={r.curtailedKwh} direct={r.flow.directKwh}"

/-- Number of days in 0 to 699 (seed 7) on which the named cycle runs. -/
def daysWith (name : String) : Nat := Id.run do
  let mut n := 0
  for d in [0:700] do
    if (applianceCycles 7 d).any (fun (c : Cycle) => c.name == name) then
      n := n + 1
  return n

/-- The energy of one day of the base load. -/
def dayKwh (dailyKwh latitude : Float) (day : Nat) : Float := Id.run do
  let mut s := 0.0
  for st in [0:96] do
    s := s + baseLoadKw dailyKwh latitude day st * 0.25
  return s

def idleLoss : IO (Option String) := do
  let r := physBatteryStep noLimits bat135 5.0 true true 0.0 0.0
  let mut soc := 5.0
  let mut loss := 0.0
  for _ in [0:96] do
    let q := physBatteryStep noLimits bat135 soc true true 0.0 0.0
    soc := q.flow.socKwh
    loss := loss + q.flow.lossKwh
  return Harness.firstFail [
    (Harness.near r.flow.socKwh 4.9975 0.000000001, s!"soc after one idle step: {fmt r}"),
    (Harness.near r.flow.chargeKwh 0.0 0.000000001 && Harness.near r.flow.dischargeKwh 0.0 0.000000001
      && Harness.near r.flow.exportKwh 0.0 0.000000001 && Harness.near r.flow.importKwh 0.0 0.000000001,
      s!"energy moved in an idle step: {fmt r}"),
    (Harness.near (5.0 - soc) 0.24 0.000001, s!"store after 96 idle steps {soc}, expected 4.76"),
    (Harness.near loss 0.24 0.000001, s!"loss over 96 idle steps {loss}, expected 0.24")]

def solarCharge : IO (Option String) := do
  let r := physBatteryStep noLimits bat135 0.0 true true 2.0 0.5
  let soc := 0.97 * 1.4875 - 0.0025
  return Harness.firstFail [
    (Harness.near r.flow.chargeKwh 1.4875 0.000001, s!"charge expected 1.4875: {fmt r}"),
    (Harness.near r.flow.socKwh soc 0.000001, s!"soc expected {soc}: {fmt r}"),
    (Harness.near r.flow.exportKwh 0.0 0.000001, s!"export expected 0: {fmt r}"),
    (Harness.near r.flow.lossKwh (0.0125 + 0.03 * 1.4875 + 0.0025) 0.000001,
      s!"loss expected inverter 0.0125 + charge 0.044625 + standby 0.0025: {fmt r}")]

def dischargeLoad : IO (Option String) := do
  let r := physBatteryStep noLimits bat135 5.0 true true 0.0 1.0
  let soc := 5.0 - ((1.0 + 0.02) / 0.97 + 0.0025)
  return Harness.firstFail [
    (Harness.near r.flow.socKwh soc 0.000001, s!"soc expected {soc}: {fmt r}"),
    (Harness.near r.flow.dischargeKwh 1.02 0.000001, s!"discharge expected 1.02: {fmt r}"),
    (Harness.near r.flow.importKwh 0.0 0.000001, s!"import expected 0: {fmt r}")]

def balanceCases : IO (Option String) := do
  let lim1 : Limits := { inverterKw := 2.0, exportKw := 1.0 }
  let cases : List (String × Limits × Float × Float × Float) := [
    ("surplus", noLimits, 3.0, 0.4, 2.0),
    ("deficit", noLimits, 0.0, 1.5, 6.0),
    ("empty with deficit", noLimits, 0.0, 1.5, 0.0),
    ("full with surplus", noLimits, 4.0, 0.5, 13.5),
    ("limits surplus", lim1, 4.0, 0.5, 13.0),
    ("limits deficit", lim1, 0.0, 3.0, 8.0),
    ("night idle", noLimits, 0.0, 0.0, 3.0)]
  let mut bad : List String := []
  for (name, lim, pv, load, soc) in cases do
    let r := physBatteryStep lim bat135 soc true true pv load
    if gap pv load soc r > 0.000001 then
      bad := bad ++ [s!"{name}: gap {gap pv load soc r}: {fmt r}"]
  return if bad.isEmpty then none else some (String.intercalate "; " bad)

def limitsHold : IO (Option String) := do
  let lim : Limits := { inverterKw := 0.0, exportKw := 1.0 }
  let r := physBatteryStep lim bat135 13.5 true true 3.0 0.2
  let r2 := physBatteryStep noLimits bat135 0.0 true true 20.0 0.0
  let r3 := physBatteryStep noLimits bat135 13.5 true true 0.0 20.0
  return Harness.firstFail [
    (r.flow.exportKwh ≤ 0.25 + 0.000001, s!"export above 0.25 kWh with exportKw 1.0: {fmt r}"),
    (r.curtailedKwh > 1.0, s!"surplus above the export limit should be curtailed: {fmt r}"),
    (gap 3.0 0.2 13.5 r ≤ 0.000001, s!"balance with export limit: {fmt r}"),
    (r2.flow.chargeKwh ≤ 2.75 + 0.000001, s!"charge above a quarter of 11 kW: {fmt r2}"),
    (r2.flow.chargeKwh > 0.0, s!"no charge from 20 kWh of solar: {fmt r2}"),
    (gap 20.0 0.0 0.0 r2 ≤ 0.000001, s!"balance with charge limit: {fmt r2}"),
    (r3.flow.dischargeKwh ≤ 2.75 + 0.000001, s!"discharge above a quarter of 11 kW: {fmt r3}"),
    (r3.flow.dischargeKwh > 0.0, s!"no discharge for a load of 20 kWh: {fmt r3}"),
    (gap 0.0 20.0 13.5 r3 ≤ 0.000001, s!"balance with discharge limit: {fmt r3}")]

def countTest (name : String) (lo hi : Nat) : IO (Option String) := do
  let n := daysWith name
  return if n ≥ lo && n ≤ hi then none
    else some s!"{name} runs on {n} of 700 days, expected {lo} to {hi}"

def sameCycles : IO (Option String) := do
  let mut bad : List String := []
  for d in [0:60] do
    let a := applianceCycles 7 d
    let b := applianceCycles 7 d
    let same := a.size == b.size
      && (List.range a.size).all (fun (i : Nat) =>
        a[i]!.name == b[i]!.name && a[i]!.stepKwh == b[i]!.stepKwh)
    if !same then bad := bad ++ [s!"day {d}"]
  let mut seen := 0
  for d in [0:60] do
    seen := seen + (applianceCycles 7 d).size
  return Harness.firstFail [
    (bad.isEmpty, s!"different cycles for the same seed and day: {bad}"),
    (seen > 0, "no cycle in 60 days")]

def cycleShape (c : Cycle) (name : String) (kwh : Float) (n : Nat) : Option String :=
  Harness.firstFail [
    (c.stepKwh.size == n, s!"{name} has {c.stepKwh.size} steps, expected {n}"),
    (Harness.near (fsum c.stepKwh) kwh 0.000001, s!"{name} uses {fsum c.stepKwh} kWh, expected {kwh}"),
    (c.stepKwh.all (fun (x : Float) => x > 0.0), s!"{name} has a step without energy (a gap): {c.stepKwh}")]

def cyclesInRun : IO (Option String) := do
  let mut bad : List String := []
  for d in [0:100] do
    for c in applianceCycles 7 d do
      let exp : Option (Float × Nat) :=
        if c.name == "dishwasher" then some (1.2, 8)
        else if c.name == "washing-machine" then some (0.8, 6)
        else if c.name == "dryer" then some (2.5, 6)
        else none
      match exp with
      | none => bad := bad ++ [s!"day {d}: unknown name {c.name}"]
      | some (kwh, n) =>
        match cycleShape c c.name kwh n with
        | some m => bad := bad ++ [s!"day {d}: {m}"]
        | none => pure ()
  return if bad.isEmpty then none else some (String.intercalate "; " (bad.take 3))

def yearBase : IO (Option String) := do
  let mut s := 0.0
  for d in [0:365] do
    s := s + dayKwh 17.0 (-41.3) d
  return if Harness.near s 6205.0 62.05 then none
    else some s!"year of base load {s} kWh, expected 6205 within 1%"

def eveningBase : IO (Option String) := do
  let a := baseLoadKw 17.0 (-41.3) 100 76
  let b := baseLoadKw 17.0 (-41.3) 100 12
  return if a > b then none else some s!"19:00 gives {a} kW, 03:00 gives {b} kW"

def winterBase : IO (Option String) := do
  let w := dayKwh 17.0 (-41.3) 197
  let s := dayKwh 17.0 (-41.3) 15
  return if w > s then none else some s!"winter day {w} kWh, summer day {s} kWh"

def tests : List Harness.Test := [
  { name := "test_002_S3_R8_idle_battery_loses_standby", run := idleLoss },
  { name := "test_002_S3_R8_solar_charges_with_inverter_loss", run := solarCharge },
  { name := "test_002_S3_R8_discharge_gives_load_and_inverter_loss", run := dischargeLoad },
  { name := "test_002_S3_R8_energy_balances_in_each_step", run := balanceCases },
  { name := "test_002_S3_R8_limits_hold_with_quarter_energy", run := limitsHold },
  { name := "test_002_S3_R9_dishwasher_days", run := countTest "dishwasher" 450 550 },
  { name := "test_002_S3_R9_washing_machine_days", run := countTest "washing-machine" 350 450 },
  { name := "test_002_S3_R9_dryer_days", run := countTest "dryer" 150 250 },
  { name := "test_002_S3_R9_same_seed_and_day_same_cycles", run := sameCycles },
  { name := "test_002_S3_R9_cycles_of_a_day_use_their_energy_without_gap", run := cyclesInRun },
  { name := "test_002_S3_R9_dishwasher_shape", run := pure (cycleShape dishwasher "dishwasher" 1.2 8) },
  { name := "test_002_S3_R9_dishwasher_heats_more_in_some_steps", run :=
      pure (if maxOf dishwasher.stepKwh > minOf dishwasher.stepKwh then none
        else some s!"dishwasher steps are flat: {dishwasher.stepKwh}") },
  { name := "test_002_S3_R9_washing_machine_shape", run := pure (cycleShape washingMachine "washing machine" 0.8 6) },
  { name := "test_002_S3_R9_dryer_shape", run := pure (cycleShape dryer "dryer" 2.5 6) },
  { name := "test_002_S3_R10_year_of_base_load", run := yearBase },
  { name := "test_002_S3_R10_evening_above_night", run := eveningBase },
  { name := "test_002_S3_R10_winter_day_above_summer_day", run := winterBase }
]

def main (args : List String) : IO UInt32 := Harness.run tests args
