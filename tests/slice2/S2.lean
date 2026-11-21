import tests.slice.Harness
import StoragePolicySim.HotWater
import StoragePolicySim.PhysTank
open StoragePolicySim

/-! Acceptance tests of slice S2 (a tank in litres and degrees) of spec 002. -/

/-- The tank config of the acceptance lines: 13.1 kWh, element 3.3 kW, loss 0.006, guard hour 20. -/
def cfgWith (cutInKwh : Float) : TankConfig :=
  { capacityKwh := 13.1
    elementKw := 3.3
    lossPerHour := 0.006
    cutInKwh := cutInKwh
    floorKwh := 0.0
    guardHour := 20 }

def tank0 : PhysTank := physTankOf (cfgWith 0.0)

/-- Cut-in share 0.5. -/
def tankHalf : PhysTank := physTankOf (cfgWith 6.55)

def stateOf (hot : Float) (heating full : Bool) : PhysTankState :=
  { hotLitres := hot, heating := heating, fullToday := full }

def fmt (x : Float) : String := s!"{x}"

/-- The first fail of the checks, as a test result. -/
def verdict (checks : List (Bool × String)) : IO (Option String) :=
  pure (Harness.firstFail checks)

-- R6: litres and energy

def t_litres : IO (Option String) :=
  verdict [(Harness.near tank0.litres 250.3 0.1, s!"litres {fmt tank0.litres}, wanted 250.3")]

def t_full_energy : IO (Option String) :=
  let e := tankEnergyKwh (physStart tank0) 15.0
  verdict [(Harness.near e 13.1 0.001, s!"full tank energy {fmt e}, wanted 13.1")]

def t_full_loss : IO (Option String) :=
  let r := physTankStep tank0 (physStart tank0) 10 0.0 0.0 15.0
  verdict [(Harness.near r.lossKwh 0.01965 0.00001, s!"loss {fmt r.lossKwh}, wanted 0.01965")]

def t_served_15 : IO (Option String) :=
  let r := physTankStep tank0 (physStart tank0) 10 0.0 50.0 15.0
  verdict [(Harness.near r.servedKwh 1.4538 0.0005, s!"served {fmt r.servedKwh}, wanted 1.4538"),
           (Harness.near r.unmetKwh 0.0 0.000001, s!"unmet {fmt r.unmetKwh}, wanted 0")]

def t_served_10 : IO (Option String) :=
  let r := physTankStep tank0 (physStart tank0) 10 0.0 50.0 10.0
  verdict [(Harness.near r.servedKwh 1.7445 0.0005, s!"served {fmt r.servedKwh}, wanted 1.7445")]

def t_colder_more : IO (Option String) :=
  let a := physTankStep tank0 (physStart tank0) 10 0.0 50.0 15.0
  let b := physTankStep tank0 (physStart tank0) 10 0.0 50.0 10.0
  verdict [(b.servedKwh > a.servedKwh, s!"served at 10 C {fmt b.servedKwh}, at 15 C {fmt a.servedKwh}")]

def t_unmet : IO (Option String) :=
  let r := physTankStep tank0 (stateOf 10.0 false true) 10 0.0 50.0 15.0
  let hotKwh := 10.0 * kwhPerLitreK * 45.0
  verdict [
    (Harness.near (r.servedKwh + r.lossKwh) hotKwh 0.000001,
      s!"served {fmt r.servedKwh} plus loss {fmt r.lossKwh}, wanted {fmt hotKwh}"),
    (Harness.near (r.servedKwh + r.unmetKwh) 1.45375 0.000001,
      s!"served {fmt r.servedKwh} plus unmet {fmt r.unmetKwh}, wanted 1.45375"),
    (r.unmetKwh > 0.9, s!"unmet {fmt r.unmetKwh}"),
    (Harness.near r.state.hotLitres 0.0 0.000001, s!"end hot litres {fmt r.state.hotLitres}")]

def t_heat_request_limited : IO (Option String) :=
  let r := physTankStep tank0 (stateOf (tank0.litres * 0.5) false true) 10 2.0 0.0 15.0
  verdict [(Harness.near r.heatKwh 0.825 0.000001, s!"heat {fmt r.heatKwh}, wanted 0.825"),
           (Harness.near r.backstopKwh 0.0 0.000001, s!"backstop {fmt r.backstopKwh}, wanted 0")]

def t_heat_request_small : IO (Option String) :=
  let r := physTankStep tank0 (stateOf (tank0.litres * 0.5) false true) 10 0.5 0.0 15.0
  verdict [(Harness.near r.heatKwh 0.5 0.000001, s!"heat {fmt r.heatKwh}, wanted 0.5")]

def t_full_tank_heats_loss : IO (Option String) :=
  let r := physTankStep tank0 (physStart tank0) 10 2.0 0.0 15.0
  verdict [(Harness.near r.heatKwh r.lossKwh 0.000001, s!"heat {fmt r.heatKwh}, loss {fmt r.lossKwh}"),
           (r.lossKwh > 0.0, s!"loss {fmt r.lossKwh}")]

/-- Cases of (tank, state, step, request, tap, inlet). -/
def balanceCases : List (PhysTank × PhysTankState × Nat × Float × Float × Float) :=
  [ (tank0, physStart tank0, 10, 0.0, 0.0, 15.0),
    (tank0, physStart tank0, 10, 0.0, 50.0, 15.0),
    (tank0, stateOf 10.0 false true, 10, 0.0, 50.0, 15.0),
    (tank0, stateOf (tank0.litres * 0.5) false true, 10, 2.0, 30.0, 12.0),
    (tank0, stateOf (tank0.litres * 0.5) false true, 10, 0.5, 0.0, 15.0),
    (tank0, stateOf (tank0.litres * 0.3) false false, 80, 0.0, 20.0, 10.0),
    (tankHalf, stateOf (tank0.litres * 0.45) false true, 10, 0.0, 0.0, 15.0),
    (tankHalf, stateOf (tank0.litres * 0.45) false true, 10, 1.0, 40.0, 15.0),
    (tankHalf, stateOf (tank0.litres * 0.7) true false, 10, 0.0, 0.0, 15.0),
    (tankHalf, stateOf (tank0.litres - 0.1) true false, 10, 0.0, 0.0, 15.0),
    (tankHalf, stateOf 0.0 false false, 90, 3.0, 10.0, 15.0) ]

def t_balance : IO (Option String) := do
  let mut bad : Option String := none
  let mut i : Nat := 0
  for c in balanceCases do
    let (t, st, step, req, tap, inlet) := c
    let r := physTankStep t st step req tap inlet
    let lhs := tankEnergyKwh st inlet + r.heatKwh + r.backstopKwh
    let rhs := r.servedKwh + r.lossKwh + tankEnergyKwh r.state inlet
    if !(Harness.near lhs rhs 0.000001) && bad.isNone then
      bad := some s!"case {i}: start plus heating {fmt lhs}, served plus loss plus end {fmt rhs}"
    i := i + 1
  return bad

-- R7: thermostat

/-- T1: cut-in share 0.5, hot share 0.45: the backstop heats and the thermostat is on. -/
def t_cut_in_below : IO (Option String) :=
  let r := physTankStep tankHalf (stateOf (tank0.litres * 0.45) false true) 10 0.0 0.0 15.0
  verdict [(Harness.near r.backstopKwh 0.825 0.000001, s!"backstop {fmt r.backstopKwh}, wanted 0.825"),
           (r.state.heating, "the thermostat is off after the cut-in")]

def t_no_cut_in_above : IO (Option String) :=
  let r := physTankStep tankHalf (stateOf (tank0.litres * 0.55) false true) 10 0.0 0.0 15.0
  verdict [(Harness.near r.backstopKwh 0.0 0.000001, s!"backstop {fmt r.backstopKwh}, wanted 0"),
           (!r.state.heating, "the thermostat is on above the cut-in share")]

/-- A thermostat that is on stays on until the tank is all hot (hot share 0.7, above the cut-in). -/
def t_stays_on : IO (Option String) :=
  let res := Id.run do
    let mut st : PhysTankState := stateOf (tank0.litres * 0.7) true false
    let mut bad : Option String := none
    let mut done := false
    let mut steps : Nat := 0
    for _ in [0:100] do
      if !done then
        let r := physTankStep tankHalf st 10 0.0 0.0 15.0
        steps := steps + 1
        if r.backstopKwh <= 0.0 && bad.isNone then
          bad := some s!"step {steps}: no backstop while on, state {fmt st.hotLitres} litres"
        st := r.state
        if st.hotLitres < tank0.litres - 0.000001 then
          if !st.heating && bad.isNone then
            bad := some s!"step {steps}: the thermostat stopped at {fmt st.hotLitres} litres"
        else
          done := true
    (bad, done, st, steps)
  let (bad, done, st, steps) := res
  match bad with
  | some m => pure (some m)
  | none => verdict [(done, s!"the tank was not all hot after {steps} steps"),
                     (steps >= 3, s!"the tank was hot after only {steps} steps")]

/-- T3: the tank becomes all hot, the thermostat stops and the full-today flag is set. -/
def t_stops_all_hot : IO (Option String) :=
  let r := physTankStep tankHalf (stateOf (tank0.litres - 0.1) true false) 10 0.0 0.0 15.0
  verdict [(Harness.near r.state.hotLitres tank0.litres 0.000001,
              s!"hot litres {fmt r.state.hotLitres}, wanted {fmt tank0.litres}"),
           (!r.state.heating, "the thermostat is on when the tank is all hot"),
           (r.state.fullToday, "the full-today flag is not set")]

/-- T2: the guard hour 20 is step 80. -/
def t_guard_80 : IO (Option String) :=
  let r := physTankStep tank0 (stateOf (tank0.litres * 0.5) false false) 80 0.0 0.0 15.0
  verdict [(Harness.near r.backstopKwh 0.825 0.000001, s!"backstop {fmt r.backstopKwh}, wanted 0.825"),
           (r.state.heating, "the thermostat is off after the guard heating")]

def t_guard_79 : IO (Option String) :=
  let r := physTankStep tank0 (stateOf (tank0.litres * 0.5) false false) 79 0.0 0.0 15.0
  verdict [(Harness.near r.backstopKwh 0.0 0.000001, s!"backstop {fmt r.backstopKwh}, wanted 0"),
           (!r.state.heating, "the thermostat is on at step 79")]

def t_guard_full_today : IO (Option String) :=
  let r := physTankStep tank0 (stateOf (tank0.litres * 0.5) false true) 80 0.0 0.0 15.0
  verdict [(Harness.near r.backstopKwh 0.0 0.000001, s!"backstop {fmt r.backstopKwh}, wanted 0")]

/-- Step 0 starts a new day: the full-today flag resets. Then the guard hour heats. -/
def t_new_day : IO (Option String) :=
  let r0 := physTankStep tank0 (stateOf (tank0.litres * 0.5) false true) 0 0.0 0.0 15.0
  let r80 := physTankStep tank0 r0.state 80 0.0 0.0 15.0
  verdict [(!r0.state.fullToday, "the full-today flag stays set at step 0 of a half-full tank"),
           (r80.backstopKwh > 0.8, s!"backstop at step 80 after a new day {fmt r80.backstopKwh}")]

def tests : List Harness.Test := [
  { name := "test_002_S2_R6_litres_from_capacity", run := t_litres },
  { name := "test_002_S2_R6_full_tank_energy", run := t_full_energy },
  { name := "test_002_S2_R6_full_tank_loss_one_step", run := t_full_loss },
  { name := "test_002_S2_R6_served_energy_inlet_15", run := t_served_15 },
  { name := "test_002_S2_R6_served_energy_inlet_10", run := t_served_10 },
  { name := "test_002_S2_R6_colder_inlet_needs_more_energy", run := t_colder_more },
  { name := "test_002_S2_R6_unmet_use_when_hot_layer_empty", run := t_unmet },
  { name := "test_002_S2_R6_heating_limited_by_element", run := t_heat_request_limited },
  { name := "test_002_S2_R6_heating_small_request", run := t_heat_request_small },
  { name := "test_002_S2_R6_full_tank_heats_only_loss", run := t_full_tank_heats_loss },
  { name := "test_002_S2_R6_energy_balance", run := t_balance },
  { name := "test_002_S2_R7_T1_cut_in_below_share", run := t_cut_in_below },
  { name := "test_002_S2_R7_no_cut_in_above_share", run := t_no_cut_in_above },
  { name := "test_002_S2_R7_thermostat_stays_on", run := t_stays_on },
  { name := "test_002_S2_R7_T3_stops_when_all_hot", run := t_stops_all_hot },
  { name := "test_002_S2_R7_T2_guard_heats_at_step_80", run := t_guard_80 },
  { name := "test_002_S2_R7_no_guard_heat_at_step_79", run := t_guard_79 },
  { name := "test_002_S2_R7_no_guard_heat_when_full_today", run := t_guard_full_today },
  { name := "test_002_S2_R7_step_0_starts_new_day", run := t_new_day } ]

def main (args : List String) : IO UInt32 := Harness.run tests args
