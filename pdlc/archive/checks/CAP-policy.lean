/-
Component checks of CAP-policy (daily-profile policies), for CH-0009 (daily-profile policies).

The checks call only `Action`, `StaticParams`, `PlanParams`, `DynamicParams`, `Observation`,
`Policy`, `Policy.name`, `defaultStatic`, `defaultPlan`, `defaultDynamic`, `staticProfile`,
`planDay` and `dynamicAction`. They also call `TankConfig` and `defaultTank` of CAP-hotwater
(hot-water tank). No entry of the Interface can fail, so no check expects an error code. The
Interface has no test seam, and no check uses the clock.

These checks are the checks of CAP-policy.R1 to R4 in
tests/acceptance/IN-0008.acceptance.lean, with the same names and the same numbers.

Terms of the checks:
- A plan uses the default tank. Its parameters are `defaultPlan` with a target of 9.0 kWh,
  unless the check says otherwise. The forecast `sunDay` is the forecast of the first line
  of CAP-policy.R2.
- A dynamic action uses the default tank. Its parameters are `defaultDynamic` with a low level
  of 4.0 kWh and a target of 9.0 kWh, unless the check says otherwise.
- The tolerance of each kWh value is 0.000000001.
-/
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

/-- Compares named values with a tolerance. Gives the first value that is wrong. -/
def valsIs (tol : Float) (pairs : List (String × Float × Float)) : Option String :=
  match pairs.find? (fun (_, got, want) => !near got want tol) with
  | some (n, got, want) => some s!"{n} is {got}, want {want}"
  | none => none

-- Helpers for CAP-policy

/-- A forecast of 24 hours: the listed hours have their value, the other hours have `other`. -/
def accFcOf (pairs : List (Nat × Float)) (other : Float := 0.0) : Array Float :=
  ((List.range 24).map (fun h =>
    ((pairs.find? (fun (k, _) => k == h)).map Prod.snd).getD other)).toArray

/-- The forecast of the lines of the day-ahead plan: hours 9 to 14. -/
def sunDay : Array Float :=
  accFcOf [(9, 1.0), (10, 2.0), (11, 3.5), (12, 3.0), (13, 4.0), (14, 1.5)]

/-- The parameters of the plan of the lines: a target of 9.0 kWh. -/
def plan9 : PlanParams := { defaultPlan with targetKwh := 9.0 }

/-- The plan must ask for the listed values in the listed hours, and for 0 kWh elsewhere. -/
def planAsks (acts : Array Action) (want : List (Nat × Float)) : Option String :=
  if acts.size != 24 then some s!"{acts.size} actions, want 24"
  else
    (List.range 24).findSome? (fun h =>
      let w := ((want.find? (fun (k, _) => k == h)).map Prod.snd).getD 0.0
      if near acts[h]!.heatKwh w 1e-9 then none
      else some s!"hour {h} asks for {acts[h]!.heatKwh} kWh, want {w}")

/-- What a dynamic policy sees. The battery energy does not matter for a line. -/
def accObs (hour : Nat) (tank surplus rest : Float) : Observation :=
  { hour := hour, tankKwh := tank, socKwh := 0.0, surplusKwh := surplus, forecastRestKwh := rest }

/-- The parameters of the lines of the dynamic action: a low level of 4.0 kWh and a target of
9.0 kWh. -/
def dyn49 : DynamicParams := { defaultDynamic with lowKwh := 4.0, targetKwh := 9.0 }

def asksDyn (o : Observation) (want : Float) : Option String :=
  let a := dynamicAction defaultTank dyn49 o
  if near a.heatKwh want 1e-9 then none
  else some s!"the tank asks for {a.heatKwh} kWh, want {want}"

def checks : List Check := [
  -- CAP-policy.R1
  { name := "CAP-policy.R1 the default parameters give 24 actions",
    run := do
      let a := staticProfile defaultStatic
      return if a.size == 24 then none else some s!"{a.size} actions" },
  { name := "CAP-policy.R1 the default parameters ask for 3.0 kWh in hours 10 to 13 and for 0 kWh in hours 9 and 14",
    run := do
      let a := staticProfile defaultStatic
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 9", a[9]!.heatKwh, 0.0), ("hour 10", a[10]!.heatKwh, 3.0),
        ("hour 11", a[11]!.heatKwh, 3.0), ("hour 12", a[12]!.heatKwh, 3.0),
        ("hour 13", a[13]!.heatKwh, 3.0), ("hour 14", a[14]!.heatKwh, 0.0)] },
  { name := "CAP-policy.R1 the default parameters let the battery discharge in hours 17 and 23, and not in hours 0 and 16",
    run := do
      let a := staticProfile defaultStatic
      if a.size != 24 then
        return some s!"{a.size} actions"
      return firstFail [
        (a[17]!.allowDischarge, "the battery may not discharge in hour 17"),
        (a[23]!.allowDischarge, "the battery may not discharge in hour 23"),
        (!a[0]!.allowDischarge, "the battery may discharge in hour 0"),
        (!a[16]!.allowDischarge, "the battery may discharge in hour 16")] },
  { name := "CAP-policy.R1 the default parameters let the battery charge in each hour",
    run := do
      let a := staticProfile defaultStatic
      return if a.size == 24 && (List.range 24).all (fun h => a[h]!.allowCharge) then none
        else some s!"{a.size} actions, and the battery may not charge in an hour" },
  { name := "CAP-policy.R1 0 heating hours ask for 0 kWh in each hour",
    run := do
      let a := staticProfile { defaultStatic with heatHours := 0 }
      return if a.size == 24 && (List.range 24).all (fun h => near a[h]!.heatKwh 0.0 1e-9) then none
        else some s!"{a.size} actions, and an hour asks for heating" },
  { name := "CAP-policy.R1 a start of 22 and 2 heating hours ask for 3.0 kWh in hours 22 and 23 and for 0 kWh in hour 21",
    run := do
      let a := staticProfile { defaultStatic with heatStart := 22, heatHours := 2 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 21", a[21]!.heatKwh, 0.0), ("hour 22", a[22]!.heatKwh, 3.0),
        ("hour 23", a[23]!.heatKwh, 3.0)] },
  -- The window of 5 hours from hour 23 does not wrap to hour 0.
  { name := "CAP-policy.R1 a start of 23 and 5 heating hours stop at the end of the day",
    run := do
      let a := staticProfile { defaultStatic with heatStart := 23, heatHours := 5 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 23", a[23]!.heatKwh, 3.0), ("hour 0", a[0]!.heatKwh, 0.0)] },
  { name := "CAP-policy.R1 an element of 1.5 kW asks for 1.5 kWh in each heating hour",
    run := do
      let a := staticProfile { defaultStatic with elementKw := 1.5 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 9", a[9]!.heatKwh, 0.0), ("hour 10", a[10]!.heatKwh, 1.5),
        ("hour 11", a[11]!.heatKwh, 1.5), ("hour 12", a[12]!.heatKwh, 1.5),
        ("hour 13", a[13]!.heatKwh, 1.5), ("hour 14", a[14]!.heatKwh, 0.0)] },
  { name := "CAP-policy.R1 discharge from 24 never lets the battery discharge",
    run := do
      let a := staticProfile { defaultStatic with dischargeFrom := 24 }
      return if a.size == 24 && (List.range 24).all (fun h => !a[h]!.allowDischarge) then none
        else some s!"{a.size} actions, and the battery may discharge in an hour" },

  -- CAP-policy.R2
  -- The need is 9.0 - 4.0 + 6.0 = 11.0 kWh. Hours 13, 11 and 12 take 3.0 kWh each, and hour 10
  -- takes the last 2.0 kWh. A version that fills the hours in order of the clock fails here.
  { name := "CAP-policy.R2 4.0 kWh in the tank and an expected draw of 6.0 kWh put 2.0, 3.0, 3.0 and 3.0 kWh in hours 10 to 13",
    run := do
      let a := planDay defaultTank plan9 sunDay 4.0 6.0
      return planAsks a [(10, 2.0), (11, 3.0), (12, 3.0), (13, 3.0)] },
  -- A version that leaves out the expected draw has a need of 0 kWh and fails here.
  { name := "CAP-policy.R2 9.0 kWh in the tank and an expected draw of 0.5 kWh ask for 0.5 kWh in hour 13",
    run := do
      let a := planDay defaultTank plan9 sunDay 9.0 0.5
      return planAsks a [(13, 0.5)] },
  -- The need is -1.0 kWh before the limit of 0 kWh.
  { name := "CAP-policy.R2 10.0 kWh in the tank and no expected draw ask for 0 kWh in each hour",
    run := do
      let a := planDay defaultTank plan9 sunDay 10.0 0.0
      return planAsks a [] },
  -- 0.4 kWh is one step below the minimum forecast of 0.5 kWh.
  { name := "CAP-policy.R2 a forecast of 0.4 kWh in each hour asks for 0 kWh in each hour",
    run := do
      let a := planDay defaultTank plan9 (accFcOf [] 0.4) 4.0 6.0
      return planAsks a [] },
  -- 0.5 kWh is exactly the minimum forecast. Only the rest of the need stays unplanned.
  { name := "CAP-policy.R2 a forecast of 0.5 kWh in hour 12 asks for 3.0 kWh in hour 12",
    run := do
      let a := planDay defaultTank plan9 (accFcOf [(12, 0.5)]) 4.0 6.0
      return planAsks a [(12, 3.0)] },
  { name := "CAP-policy.R2 a minimum forecast of 0.0 kWh and no sun put the heating in hour 0, because a tie goes to the earlier hour",
    run := do
      let p : PlanParams := { plan9 with minSolarKwh := 0.0 }
      let a := planDay defaultTank p (accFcOf []) 9.0 3.0
      return planAsks a [(0, 3.0)] },
  { name := "CAP-policy.R2 equal forecasts of 2.0 kWh in hours 10 to 14 put 3.0 kWh in hour 10 and 1.0 kWh in hour 11",
    run := do
      let fc := accFcOf [(10, 2.0), (11, 2.0), (12, 2.0), (13, 2.0), (14, 2.0)]
      let a := planDay defaultTank plan9 fc 9.0 4.0
      return planAsks a [(10, 3.0), (11, 1.0)] },
  { name := "CAP-policy.R2 the default parameters let the battery charge in each hour and discharge in hour 17 but not in hour 16",
    run := do
      let a := planDay defaultTank defaultPlan sunDay 5.0 6.0
      if a.size != 24 then
        return some s!"{a.size} actions"
      return firstFail [
        ((List.range 24).all (fun h => a[h]!.allowCharge), "the battery may not charge in an hour"),
        (a[17]!.allowDischarge, "the battery may not discharge in hour 17"),
        (!a[16]!.allowDischarge, "the battery may discharge in hour 16")] },

  -- CAP-policy.R3
  { name := "CAP-policy.R3 a surplus of 2.0 kWh and 5.0 kWh in the tank ask for 2.0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 2.0 0.0) 2.0 },
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 5.0 kWh in the tank ask for 3.0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 5.0 0.0) 3.0 },
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 8.0 kWh in the tank ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 8.0 5.0 0.0) 1.0 },
  -- 9.0 kWh is at the target, and 9.5 kWh is past the target.
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 9.0 or 9.5 kWh in the tank ask for 0 kWh",
    run := do
      return firstSome [asksDyn (accObs 12 9.0 5.0 0.0) 0.0, asksDyn (accObs 12 9.5 5.0 0.0) 0.0] },
  -- The lack is 4.0 - 3.0 = 1.0 kWh. A forecast of 0.5 kWh is under the lack.
  { name := "CAP-policy.R3 no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 0.0 0.5) 1.0 },
  -- A forecast of 1.0 kWh equals the lack, so it is not less than the lack.
  { name := "CAP-policy.R3 no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh ask for 0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 0.0 1.0) 0.0 },
  { name := "CAP-policy.R3 no surplus and 5.0 kWh in the tank ask for 0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 0.0 0.0) 0.0 },
  -- The lack is 4.0 kWh, and the element gives 3.0 kWh in one hour.
  { name := "CAP-policy.R3 no surplus, 0.0 kWh in the tank and no forecast ask for 3.0 kWh",
    run := do
      return asksDyn (accObs 12 0.0 0.0 0.0) 3.0 },
  { name := "CAP-policy.R3 a surplus of 1.0 kWh, 3.0 kWh in the tank and no forecast ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 1.0 0.0) 1.0 },
  { name := "CAP-policy.R3 in hour 16 the battery may charge and may not discharge, and in hour 17 it may do both",
    run := do
      let a := dynamicAction defaultTank dyn49 (accObs 16 5.0 0.0 0.0)
      let b := dynamicAction defaultTank dyn49 (accObs 17 5.0 0.0 0.0)
      return firstFail [
        (a.allowCharge, "hour 16: the battery may not charge"),
        (!a.allowDischarge, "hour 16: the battery may discharge"),
        (b.allowCharge, "hour 17: the battery may not charge"),
        (b.allowDischarge, "hour 17: the battery may not discharge")] },

  -- CAP-policy.R4
  { name := "CAP-policy.R4 defaultStatic heats from hour 10 for 4 hours, discharges from hour 17 and has an element of 3.0 kW",
    run := do
      let p := defaultStatic
      return firstFail [
        (p.heatStart == 10, s!"the heating starts at {p.heatStart}"),
        (p.heatHours == 4, s!"the heating lasts {p.heatHours} hours"),
        (p.dischargeFrom == 17, s!"discharge starts at {p.dischargeFrom}"),
        (near p.elementKw 3.0 1e-9, s!"the element is {p.elementKw} kW")] },
  { name := "CAP-policy.R4 defaultPlan has a target of 10.5 kWh, a minimum forecast of 0.5 kWh and discharge from hour 17",
    run := do
      let p := defaultPlan
      return firstFail [
        (near p.targetKwh 10.5 1e-9, s!"the target is {p.targetKwh} kWh"),
        (near p.minSolarKwh 0.5 1e-9, s!"the minimum forecast is {p.minSolarKwh} kWh"),
        (p.dischargeFrom == 17, s!"discharge starts at {p.dischargeFrom}")] },
  { name := "CAP-policy.R4 defaultDynamic has a low level of 5.25 kWh, a target of 10.5 kWh and discharge from hour 17",
    run := do
      let p := defaultDynamic
      return firstFail [
        (near p.lowKwh 5.25 1e-9, s!"the low level is {p.lowKwh} kWh"),
        (near p.targetKwh 10.5 1e-9, s!"the target is {p.targetKwh} kWh"),
        (p.dischargeFrom == 17, s!"discharge starts at {p.dischargeFrom}")] },
  { name := "CAP-policy.R4 the names of the policies are static, precomputed and dynamic",
    run := do
      let a := Policy.name (Policy.static defaultStatic)
      let b := Policy.name (Policy.precomputed defaultPlan)
      let c := Policy.name (Policy.dynamic defaultDynamic)
      return firstFail [
        (a == "static", s!"the static policy is called {repr a}"),
        (b == "precomputed", s!"the precomputed policy is called {repr b}"),
        (c == "dynamic", s!"the dynamic policy is called {repr c}")] }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
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
