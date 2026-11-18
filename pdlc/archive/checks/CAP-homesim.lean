/-
Component checks of CAP-homesim (home simulation, robust evaluation and tuning), for CH-0010
(home simulation, robust evaluation and tuning).

The checks call `HomeSetup`, `defaultHome`, `HomeHour`, `HomeTotals`, `HomeResult`, `runHome`,
`Evaluation`, `evaluate`, `TuneResult` and `tuneStatic` of CH-0010. They also call the items of
the earlier changes that the lines name: `Site`, `Hour` and `scenario` (CAP-scenario),
`forecastOf` and `hourlyEnergy` (CAP-forecast), `TankConfig`, `defaultTank`, `TankState`,
`startState`, `TankStep`, `tankStep`, `drawKwh` and `drawFactor` (CAP-hotwater), `Battery`,
`Flow` and `stepHourGated` (CAP-simulation), and `Action`, `StaticParams`, `PlanParams`,
`DynamicParams`, `Policy`, `defaultStatic`, `defaultPlan`, `defaultDynamic`, `staticProfile` and
`planDay` (CAP-policy).

No entry of the Interface can fail, so no check expects an error code. The only seam is
`homeSeed`, the `seed` argument of `runHome`, `evaluate` and `tuneStatic`. The checks of the
seam use other seeds than the lines do (8 and 3 for the runs, 7 and 8 for the evaluation), so
that an app that fixes the seed fails them. No check uses the clock.

The checks of R1 to R6 are the checks of tests/acceptance/IN-0008.acceptance.lean for these
requirements, with the same names and numbers. The checks with `homeSeed` in their names are
new.

In the lines, the home is `defaultHome` and a policy is the static policy with `defaultStatic`,
the precomputed policy with `defaultPlan` or the dynamic policy with `defaultDynamic`, unless
the line says otherwise.

Shared runs. A run can take long, so one run serves several checks. A run is a value at the top
level of this file. The first check that reads it makes the run. The next checks read the same
value. The lines of R6 evaluate each of the 704 candidates of the tuner, so this file needs
minutes to run, not seconds. The checks of the seam run 30 days (the tuner: 10 days).
-/
import StoragePolicySim.Scenario
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

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

def sumF (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0

def meanF (xs : List Float) : Float :=
  if xs.isEmpty then 0.0 else sumF xs / xs.length.toFloat

def minF (xs : List Float) : Float :=
  xs.foldl (fun acc x => if x < acc then x else acc) (xs.headD 0.0)

/-- Compares named values with a tolerance. Gives the first value that is wrong. -/
def valsIs (tol : Float) (pairs : List (String × Float × Float)) : Option String :=
  match pairs.find? (fun (_, got, want) => !near got want tol) with
  | some (n, got, want) => some s!"{n} is {got}, want {want}"
  | none => none

-- Helpers for the library

/-- The draw of one day, from the 24 hours. -/
def accDayDraw (daily lat : Float) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc h => acc + drawKwh daily lat d h) 0.0

def flowSame (a b : Flow) (tol : Float) : Bool :=
  near a.directKwh b.directKwh tol && near a.chargeKwh b.chargeKwh tol &&
  near a.dischargeKwh b.dischargeKwh tol && near a.exportKwh b.exportKwh tol &&
  near a.importKwh b.importKwh tol && near a.lossKwh b.lossKwh tol &&
  near a.socKwh b.socKwh tol

def pStatic : Policy := Policy.static defaultStatic
def pThermo : Policy := Policy.static { defaultStatic with heatHours := 0 }
def pPlan : Policy := Policy.precomputed defaultPlan
def pDyn : Policy := Policy.dynamic defaultDynamic

def homeCv (cv : Float) : HomeSetup := { defaultHome with drawCv := cv }
def homePv0 : HomeSetup :=
  { defaultHome with site := { defaultHome.site with pvKw := 0.0 } }
def homeElem02 : HomeSetup :=
  { defaultHome with tank := { defaultHome.tank with elementKw := 0.2 } }
def homeF1 : HomeSetup := { defaultHome with fetchesPerDay := 1 }
def homeE0F1 : HomeSetup := { defaultHome with errorScale := 0.0, fetchesPerDay := 1 }

/-- The hours of the scenario of the default home, seed 7 and 365 days. -/
def scenHome7 : Array Hour := scenario defaultHome.site 7 365

/-- The default run: the default home, the static policy, seed 7 and 365 days. -/
def runS7 : HomeResult := runHome defaultHome pStatic 7 365
def runS7cv0 : HomeResult := runHome (homeCv 0.0) pStatic 7 365
def runT7 : HomeResult := runHome defaultHome pThermo 7 365
def runD7 : HomeResult := runHome defaultHome pDyn 7 365
def runP7f1 : HomeResult := runHome homeF1 pPlan 7 365
def runP7e0 : HomeResult := runHome homeE0F1 pPlan 7 365
def runPv0 : HomeResult := runHome homePv0 pStatic 7 365

def seeds15 : List Nat := [1, 2, 3, 4, 5]

/-- The runs of the seeds 1 to 5 for a home and a policy. -/
def runsOf (setup : HomeSetup) (p : Policy) : List HomeResult :=
  seeds15.map (fun s => runHome setup p s 365)

def runsStatic : List HomeResult := runsOf defaultHome pStatic
def runsPlan : List HomeResult := runsOf defaultHome pPlan
def runsDyn : List HomeResult := runsOf defaultHome pDyn
def runsStaticCv5 : List HomeResult := runsOf (homeCv 0.5) pStatic
def runsPlanCv5 : List HomeResult := runsOf (homeCv 0.5) pPlan
def runsDynCv5 : List HomeResult := runsOf (homeCv 0.5) pDyn

def allRuns : List (String × List HomeResult) :=
  [("static", runsStatic), ("precomputed", runsPlan), ("dynamic", runsDyn)]

def allRunsCv5 : List (String × List HomeResult) :=
  [("static", runsStaticCv5), ("precomputed", runsPlanCv5), ("dynamic", runsDynCv5)]

def accSumHours (hs : Array HomeHour) (f : HomeHour → Float) : Float :=
  hs.foldl (fun acc h => acc + f h) 0.0

/-- The steps of the tank over the hours of a run, from the full tank. -/
def accReplayTank (cfg : TankConfig) (hs : Array HomeHour) : List TankStep :=
  let step := fun (acc : TankState × List TankStep) (h : HomeHour) =>
    let s := tankStep cfg acc.1 h.hour h.askKwh h.drawKwh
    (s.state, s :: acc.2)
  (hs.foldl step (startState cfg, ([] : List TankStep))).2.reverse

/-- The flows of the battery over the hours of a run, from an empty battery. -/
def accReplayFlows (b : Battery) (hs : Array HomeHour) : List Flow :=
  let step := fun (acc : Float × List Flow) (h : HomeHour) =>
    let f := stepHourGated b acc.1 h.allowCharge h.allowDischarge h.pvKwh
      (h.houseLoadKwh + h.heatKwh + h.backstopKwh)
    (f.socKwh, f :: acc.2)
  (hs.foldl step (0.0, ([] : List Flow))).2.reverse

def sameHomeHour (a b : HomeHour) : Bool :=
  a.day == b.day && a.hour == b.hour && a.pvKwh == b.pvKwh &&
  a.houseLoadKwh == b.houseLoadKwh && a.drawKwh == b.drawKwh && a.askKwh == b.askKwh &&
  a.heatKwh == b.heatKwh && a.backstopKwh == b.backstopKwh && a.unmetKwh == b.unmetKwh &&
  a.tankKwh == b.tankKwh && a.allowCharge == b.allowCharge &&
  a.allowDischarge == b.allowDischarge && flowSame a.flow b.flow 0.0

def sameRuns (a b : HomeResult) : Bool :=
  a.hours.size == b.hours.size &&
  (a.hours.toList.zip b.hours.toList).all (fun (x, y) => sameHomeHour x y)

/-- The first day of a run that has no hour with a full tank. -/
def dayWithoutFull (r : HomeResult) (cap : Float) : Option Nat :=
  (List.range (r.hours.size / 24)).find? (fun d =>
    !((List.range 24).any (fun h => r.hours[24 * d + h]!.tankKwh ≥ cap - 1e-9)))

def sameEval (a b : Evaluation) (tol : Float) : Bool :=
  near a.meanSelfConsumption b.meanSelfConsumption tol &&
  near a.worstSelfConsumption b.worstSelfConsumption tol &&
  near a.meanSelfSufficiency b.meanSelfSufficiency tol &&
  near a.meanImportKwh b.meanImportKwh tol && near a.meanExportKwh b.meanExportKwh tol &&
  near a.meanBackstopKwh b.meanBackstopKwh tol && near a.totalUnmetKwh b.totalUnmetKwh tol &&
  a.seeds == b.seeds && a.unmetSeeds == b.unmetSeeds && a.coldHours == b.coldHours

/-- Runs of the seeds 3 to 6 with the static policy, for the lines of the evaluation. -/
def runsS36 : List HomeResult :=
  (List.range 4).map (fun i => runHome defaultHome pStatic (3 + i) 365)

def evalS3x4 : Evaluation := evaluate defaultHome pStatic 3 4 365
def evalS3x4b : Evaluation := evaluate defaultHome pStatic 3 4 365
def evalS3x1 : Evaluation := evaluate defaultHome pStatic 3 1 365
def evalS3x0 : Evaluation := evaluate defaultHome pStatic 3 0 365

/-- Runs of a home with an unmet draw: an element of 0.2 kW, the static policy with 0 heating
hours, the seeds 3 to 6 and 30 days. The lines of CAP-homesim.R5 use them to prove that
`evaluate` counts and sums. -/
def runsE36 : List HomeResult :=
  (List.range 4).map (fun i => runHome homeElem02 pThermo (3 + i) 30)

def evalE3x4 : Evaluation := evaluate homeElem02 pThermo 3 4 30

/-- The grid of the tuner: a start from 6 to 16, from 1 to 8 heating hours, and discharge from
15 to 22, with the element of the home tank. -/
def accGrid : List StaticParams :=
  (List.range 704).map (fun n =>
    ({ heatStart := 6 + n / 64, heatHours := 1 + (n / 8) % 8, dischargeFrom := 15 + n % 8,
       elementKw := defaultHome.tank.elementKw } : StaticParams))

def accGridEvals : List (StaticParams × Evaluation) :=
  accGrid.map (fun p => (p, evaluate defaultHome (Policy.static p) 1 2 30))

def tune1 : TuneResult := tuneStatic defaultHome 1 2 30
def tune2 : TuneResult := tuneStatic defaultHome 1 2 30
def tunePv0 : TuneResult := tuneStatic homePv0 1 2 30

/-- The run of a home with an element of 0.2 kW and the thermostat policy: seed 7, 365 days. -/
def runE02 : HomeResult := runHome homeElem02 pThermo 7 365

/-- Each hour of a run must have the tank energy, the heating, the backstop heating and the
unmet draw of the `tankStep` result for the tank state of the hour before. -/
def tankMismatch (cfg : TankConfig) (hs : Array HomeHour) : Option String :=
  let steps := accReplayTank cfg hs
  match (hs.toList.zip steps).find? (fun (h, s) =>
      !(near h.tankKwh s.state.energyKwh 1e-9 && near h.heatKwh s.heatKwh 1e-9 &&
        near h.backstopKwh s.backstopKwh 1e-9 && near h.unmetKwh s.unmetKwh 1e-9)) with
  | some (h, s) =>
    some s!"day {h.day} hour {h.hour}: tank {h.tankKwh}, heating {h.heatKwh}, backstop {h.backstopKwh}, unmet {h.unmetKwh}; tankStep gives {s.state.energyKwh}, {s.heatKwh}, {s.backstopKwh}, {s.unmetKwh}"
  | none => if hs.size == steps.length then none else some "the replay has another length"

/-- Each hour of a run must have the flow of `stepHourGated` for the battery energy of the hour
before, its gate, its solar energy, and its house load plus its heating plus its backstop
heating. -/
def flowMismatch (b : Battery) (hs : Array HomeHour) : Option String :=
  let flows := accReplayFlows b hs
  match (hs.toList.zip flows).find? (fun (h, f) => !flowSame h.flow f 1e-9) with
  | some (h, f) =>
    some s!"day {h.day} hour {h.hour}: the flow is {repr h.flow}, stepHourGated gives {repr f}"
  | none => if hs.size == flows.length then none else some "the replay has another length"

/-- The first run of a policy (seeds 1 to 5) with an unmet draw in an hour. -/
def noUnmet (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    if r.hours.size != 8760 then some s!"{name}, seed {s}: {r.hours.size} hours"
    else
      match r.hours.toList.find? (fun h => h.unmetKwh > 1e-9) with
      | some h =>
        some s!"{name}, seed {s}: day {h.day} hour {h.hour} has an unmet draw of {h.unmetKwh} kWh"
      | none => none)

/-- The first run of a policy that ends an hour below the floor of 2.1 kWh, or that has a cold
hour. -/
def noCold (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    match r.hours.toList.find? (fun h => h.tankKwh < 2.1 - 1e-9) with
    | some h =>
      some s!"{name}, seed {s}: day {h.day} hour {h.hour} ends at {h.tankKwh} kWh, below the floor"
    | none =>
      if r.totals.coldHours == 0 && r.hours.size == 8760 then none
      else some s!"{name}, seed {s}: coldHours is {r.totals.coldHours}, {r.hours.size} hours")

/-- The first run of a policy with a cold hour. -/
def coldHoursZero (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    if r.totals.coldHours == 0 && r.hours.size == 8760 then none
    else some s!"{name}, seed {s}: coldHours is {r.totals.coldHours}, {r.hours.size} hours")

/-- The first run of a policy with a day that has no hour with a full tank. -/
def noEmptyDay (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    match dayWithoutFull r defaultHome.tank.capacityKwh with
    | some d => some s!"{name}, seed {s}: day {d} has no hour with a full tank"
    | none => if r.hours.size == 8760 then none else some s!"{name}, seed {s}: {r.hours.size} hours")

/-- A dynamic policy heats only in an hour with a surplus, or when the tank held less than
5.25 kWh before the hour. Gives the first hour that breaks this. -/
def badDynamic (hs : Array HomeHour) : Option String :=
  (List.range hs.size).findSome? (fun i =>
    let h := hs[i]!
    let before := if i == 0 then defaultHome.tank.capacityKwh else hs[i - 1]!.tankKwh
    if h.askKwh > 0.0 && !(h.pvKwh > h.houseLoadKwh || before < 5.25 + 1e-9) then
      some s!"day {h.day} hour {h.hour}: asks {h.askKwh}, solar {h.pvKwh}, load {h.houseLoadKwh}, tank before {before}"
    else none)

-- Helpers for the test seam `homeSeed`. The runs of the seam use the seeds 7 and 8 for 30 days,
-- and the seed 8 is not the seed of the lines of R1.

def seamS7 : HomeResult := runHome defaultHome pStatic 7 30
def seamS8 : HomeResult := runHome defaultHome pStatic 8 30
def seamP8 : HomeResult := runHome homeF1 pPlan 8 30
def seamP8b : HomeResult := runHome homeF1 pPlan 8 30
def evalSeam7x2 : Evaluation := evaluate defaultHome pStatic 7 2 30
def evalSeam8x1 : Evaluation := evaluate defaultHome pStatic 8 1 30

/-- The tuner with the first seed 3, 1 seed and 10 days, and the evaluation of its best profile
with the seeds 3 and 4. -/
def seamTune3 : TuneResult := tuneStatic defaultHome 3 1 10
def seamEval3 : Evaluation := evaluate defaultHome (Policy.static seamTune3.best) 3 1 10
def seamEval4 : Evaluation := evaluate defaultHome (Policy.static seamTune3.best) 4 1 10

-- The checks

def checks : List Check := [
  -- CAP-homesim.R1
  { name := "CAP-homesim.R1 the default run has 8760 hours in order of day, then hour",
    run := do
      let hs := runS7.hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i =>
            !(hs[i]!.day == i / 24 && hs[i]!.hour == i % 24)) with
          | some i => some s!"item {i} is day {hs[i]!.day} hour {hs[i]!.hour}"
          | none => none },
  { name := "CAP-homesim.R1 the solar energy and the house load of each hour are those of the scenario hour",
    run := do
      let hs := runS7.hours
      let bad := (List.range hs.size).find? (fun i =>
        !(near hs[i]!.pvKwh scenHome7[i]!.pvKwh 1e-9 &&
          near hs[i]!.houseLoadKwh (scenHome7[i]!.baseLoadKwh + scenHome7[i]!.flexKwh) 1e-9))
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i}: solar {hs[i]!.pvKwh}, load {hs[i]!.houseLoadKwh}; the scenario has {scenHome7[i]!.pvKwh} and {scenHome7[i]!.baseLoadKwh + scenHome7[i]!.flexKwh}"
          | none => none },
  { name := "CAP-homesim.R1 askKwh and the battery gate of each hour are those of the static profile",
    run := do
      let prof := staticProfile defaultStatic
      let hs := runS7.hours
      let bad := hs.toList.find? (fun h =>
        !(h.hour < 24 && near h.askKwh prof[h.hour]!.heatKwh 1e-9 &&
          h.allowCharge == prof[h.hour]!.allowCharge &&
          h.allowDischarge == prof[h.hour]!.allowDischarge))
      return if hs.size != 8760 || prof.size != 24 then
          some s!"{hs.size} hours and {prof.size} actions"
        else match bad with
          | some h => some s!"day {h.day} hour {h.hour}: ask {h.askKwh}, charge {h.allowCharge}, discharge {h.allowDischarge}"
          | none => none },
  { name := "CAP-homesim.R1 the tank energy of each hour is the tankStep result for the tank state of the hour before",
    run := do
      let hs := runS7.hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else tankMismatch defaultHome.tank hs },
  { name := "CAP-homesim.R1 the flow of each hour is the stepHourGated flow for the battery energy of the hour before",
    run := do
      let hs := runS7.hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else flowMismatch defaultHome.battery hs },
  -- The spread of the home is 0.25 in the line. Thus the check uses the number 0.25.
  { name := "CAP-homesim.R1 the draw of each hour is the drawKwh of the home times the drawFactor for seed 7, its day and the spread 0.25",
    run := do
      let hs := runS7.hours
      let want := fun (i : Nat) =>
        let s := scenHome7[i]!
        drawKwh defaultHome.drawKwhPerDay defaultHome.site.latitude s.dayOfYear s.hour *
          drawFactor 7 s.day 0.25
      let bad := (List.range hs.size).find? (fun i => !near hs[i]!.drawKwh (want i) 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i} draws {hs[i]!.drawKwh} kWh, want {want i}"
          | none => if hs.any (fun h => h.drawKwh > 0.0) then none else some "no hour has a draw" },
  { name := "CAP-homesim.R1 with a spread of 0 the draw of each hour is the drawKwh of the home",
    run := do
      let hs := runS7cv0.hours
      let want := fun (i : Nat) =>
        let s := scenHome7[i]!
        drawKwh defaultHome.drawKwhPerDay defaultHome.site.latitude s.dayOfYear s.hour
      let bad := (List.range hs.size).find? (fun i => !near hs[i]!.drawKwh (want i) 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i} draws {hs[i]!.drawKwh} kWh, want {want i}"
          | none => if hs.any (fun h => h.drawKwh > 0.0) then none else some "no hour has a draw" },
  { name := "CAP-homesim.R1 the precomputed policy with 1 fetch each day asks for the heating of planDay from the forecast of the fetch at hour 24 × d",
    run := do
      let hs := runP7f1.hours
      if hs.size != 8760 then
        return some s!"{hs.size} hours"
      let bad := (List.range 365).findSome? (fun d =>
        let ps := forecastOf scenHome7 homeF1.site 7 homeF1.errorScale (24 * d)
        let fc := ((hourlyEnergy ps (24 * d)).toList.take 24).toArray
        let tank0 := if d == 0 then defaultTank.capacityKwh else hs[24 * d - 1]!.tankKwh
        let draw := accDayDraw homeF1.drawKwhPerDay homeF1.site.latitude d
        let plan := planDay homeF1.tank defaultPlan fc tank0 draw
        (List.range 24).findSome? (fun h =>
          if near hs[24 * d + h]!.askKwh plan[h]!.heatKwh 1e-9 then none
          else some s!"day {d} hour {h}: asks {hs[24 * d + h]!.askKwh} kWh, planDay gives {plan[h]!.heatKwh} kWh"))
      return firstSome [bad,
        if hs.any (fun h => h.askKwh > 0.0) then none else some "no hour asks for heating"] },
  { name := "CAP-homesim.R1 0 days give a run with no hours",
    run := do
      let r := runHome defaultHome pStatic 7 0
      return if r.hours.size == 0 then none else some s!"{r.hours.size} hours" },
  -- The test seam `homeSeed`. The lines above use seed 7 only. An app that fixes the seed at 7
  -- passes them. The two checks below use seed 8.
  { name := "CAP-homesim.R1 homeSeed: each hour of a run with seed 8 has the solar energy and the house load of the scenario with seed 8, and the seeds 7 and 8 give a different weather",
    run := do
      let a := seamS7.hours
      let b := seamS8.hours
      let sc8 := scenario defaultHome.site 8 30
      let bad := (List.range b.size).find? (fun i =>
        !(near b[i]!.pvKwh sc8[i]!.pvKwh 1e-9 &&
          near b[i]!.houseLoadKwh (sc8[i]!.baseLoadKwh + sc8[i]!.flexKwh) 1e-9))
      let differs := (List.range (min a.size b.size)).any (fun i =>
        !near a[i]!.pvKwh b[i]!.pvKwh 1e-9)
      return firstFail [
        (a.size == 720 && b.size == 720 && sc8.size == 720,
          s!"{a.size}, {b.size} and {sc8.size} hours"),
        (bad.isNone, s!"item {bad.getD 0} has not the solar energy and the house load of the scenario with seed 8"),
        (differs, "the runs with the seeds 7 and 8 have the same solar energy in each hour")] },
  { name := "CAP-homesim.R1 homeSeed: the draw of each hour of a run with seed 8 is the drawKwh of the home times the drawFactor for seed 8",
    run := do
      let hs := seamS8.hours
      let sc8 := scenario defaultHome.site 8 30
      let want := fun (i : Nat) =>
        let s := sc8[i]!
        drawKwh defaultHome.drawKwhPerDay defaultHome.site.latitude s.dayOfYear s.hour *
          drawFactor 8 s.day 0.25
      let bad := (List.range hs.size).find? (fun i => !near hs[i]!.drawKwh (want i) 1e-9)
      return if hs.size != 720 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i} draws {hs[i]!.drawKwh} kWh, want {want i}"
          | none => none },
  { name := "CAP-homesim.R1 homeSeed: the precomputed policy with seed 8 asks for the heating of planDay from the forecast of seed 8, and the same seed twice gives the same hours",
    run := do
      let hs := seamP8.hours
      if hs.size != 720 then
        return some s!"{hs.size} hours"
      let sc := scenario homeF1.site 8 30
      let bad := (List.range 30).findSome? (fun d =>
        let ps := forecastOf sc homeF1.site 8 homeF1.errorScale (24 * d)
        let fc := ((hourlyEnergy ps (24 * d)).toList.take 24).toArray
        let tank0 := if d == 0 then defaultTank.capacityKwh else hs[24 * d - 1]!.tankKwh
        let draw := accDayDraw homeF1.drawKwhPerDay homeF1.site.latitude d
        let plan := planDay homeF1.tank defaultPlan fc tank0 draw
        (List.range 24).findSome? (fun h =>
          if near hs[24 * d + h]!.askKwh plan[h]!.heatKwh 1e-9 then none
          else some s!"day {d} hour {h}: asks {hs[24 * d + h]!.askKwh} kWh, planDay gives {plan[h]!.heatKwh} kWh"))
      return firstSome [bad,
        if hs.any (fun h => h.askKwh > 0.0) then none else some "no hour asks for heating",
        if sameRuns seamP8 seamP8b then none else some "two runs with seed 8 give other hours"] },

  -- CAP-homesim.R2
  { name := "CAP-homesim.R2 each policy and the seeds 1 to 5 have an unmet draw of 0 kWh in each hour",
    run := do
      return allRuns.findSome? (fun (n, rs) => noUnmet n rs) },
  { name := "CAP-homesim.R2 each policy and the seeds 1 to 5 keep the tank at or above 2.1 kWh and have no cold hours",
    run := do
      return allRuns.findSome? (fun (n, rs) => noCold n rs) },
  { name := "CAP-homesim.R2 each policy and the seeds 1 to 5 have an hour after which the tank is full on each day",
    run := do
      return allRuns.findSome? (fun (n, rs) => noEmptyDay n rs) },
  { name := "CAP-homesim.R2 each policy with a spread of 0.5 and the seeds 1 to 5 have no unmet draw and no cold hours",
    run := do
      return allRunsCv5.findSome? (fun (n, rs) => firstSome [noUnmet n rs, coldHoursZero n rs]) },
  { name := "CAP-homesim.R2 a static policy with 0 heating hours has more than 500 kWh of backstop heating and no unmet draw",
    run := do
      let t := runT7.totals
      return firstFail [
        (runT7.hours.size == 8760, s!"{runT7.hours.size} hours"),
        (t.backstopKwh > 500.0, s!"backstop heating {t.backstopKwh} kWh"),
        (near t.unmetKwh 0.0 1e-9, s!"unmet draw {t.unmetKwh} kWh")] },
  { name := "CAP-homesim.R2 a home with an element of 0.2 kW and no heating hours has an unmet draw and cold hours",
    run := do
      let t := runE02.totals
      return firstFail [
        (runE02.hours.size == 8760, s!"{runE02.hours.size} hours"),
        (t.unmetKwh > 0.0, s!"unmet draw {t.unmetKwh} kWh"),
        (t.coldHours > 0, s!"cold hours {t.coldHours}")] },

  -- CAP-homesim.R3
  { name := "CAP-homesim.R3 each total equals the sum of its hours",
    run := do
      let hs := runS7.hours
      let t := runS7.totals
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (t.pvKwh > 0.0 && t.heatKwh > 0.0 && t.batteryLossKwh > 0.0, "a total is 0, so the run proves little"),
        (near t.pvKwh (accSumHours hs (·.pvKwh)) 0.01, s!"solar {t.pvKwh}"),
        (near t.loadKwh (accSumHours hs (fun h => h.houseLoadKwh + h.heatKwh + h.backstopKwh)) 0.01,
          s!"load {t.loadKwh}"),
        (near t.importKwh (accSumHours hs (·.flow.importKwh)) 0.01, s!"import {t.importKwh}"),
        (near t.exportKwh (accSumHours hs (·.flow.exportKwh)) 0.01, s!"export {t.exportKwh}"),
        (near t.batteryLossKwh (accSumHours hs (·.flow.lossKwh)) 0.01,
          s!"battery loss {t.batteryLossKwh}"),
        (near t.heatKwh (accSumHours hs (·.heatKwh)) 0.01, s!"heating {t.heatKwh}"),
        (near t.backstopKwh (accSumHours hs (·.backstopKwh)) 0.01, s!"backstop heating {t.backstopKwh}"),
        (near t.drawKwh (accSumHours hs (·.drawKwh)) 0.01, s!"draw {t.drawKwh}"),
        (near t.unmetKwh (accSumHours hs (·.unmetKwh)) 0.01, s!"unmet draw {t.unmetKwh}")] },
  { name := "CAP-homesim.R3 solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end",
    run := do
      let hs := runS7.hours
      let t := runS7.totals
      let soc := hs[hs.size - 1]!.flow.socKwh
      let lhs := t.pvKwh + t.importKwh
      let rhs := t.loadKwh + t.exportKwh + t.batteryLossKwh + soc
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (t.pvKwh > 0.0 && t.batteryLossKwh > 0.0, "solar or battery loss is 0, so the run proves little"),
        (near lhs rhs 0.01, s!"solar and import {lhs}, the rest {rhs}")] },
  { name := "CAP-homesim.R3 the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy",
    run := do
      let hs := runS7.hours
      let t := runS7.totals
      let steps := accReplayTank defaultHome.tank hs
      let served := sumF (steps.map (·.servedKwh))
      let lhs := defaultHome.tank.capacityKwh + t.heatKwh + t.backstopKwh
      let rhs := served + t.tankLossKwh + t.finalTankKwh
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (t.tankLossKwh > 0.0 && served > 0.0, "the tank loss or the served draw is 0, so the run proves little"),
        (near lhs rhs 0.01, s!"start, heating and backstop {lhs}, the rest {rhs}")] },
  -- The second run has an unmet draw, so the check also proves that the unmet draw counts.
  { name := "CAP-homesim.R3 unmetKwh plus the served draw equals drawKwh, which is the sum of the hours",
    run := do
      let one := fun (r : HomeResult) (cfg : TankConfig) =>
        let served := sumF ((accReplayTank cfg r.hours).map (·.servedKwh))
        firstFail [
          (r.hours.size == 8760, s!"{r.hours.size} hours"),
          (near (r.totals.unmetKwh + served) r.totals.drawKwh 0.01,
            s!"unmet {r.totals.unmetKwh} and served {served}, draw {r.totals.drawKwh}"),
          (near r.totals.drawKwh (accSumHours r.hours (·.drawKwh)) 0.01,
            s!"draw {r.totals.drawKwh}, sum of the hours {accSumHours r.hours (·.drawKwh)}")]
      return firstSome [one runS7 defaultHome.tank, one runE02 homeElem02.tank,
        if runE02.totals.unmetKwh > 0.0 then none else some "the second run has no unmet draw"] },
  { name := "CAP-homesim.R3 the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load",
    run := do
      let t := runS7.totals
      let sc := 100.0 * (t.pvKwh - t.exportKwh) / t.pvKwh
      let ss := 100.0 * (t.loadKwh - t.importKwh) / t.loadKwh
      return firstFail [
        (t.pvKwh > 0.0 && t.loadKwh > 0.0, "solar or load is 0"),
        (near t.selfConsumption sc 1e-6, s!"self-consumption {t.selfConsumption}, want {sc}"),
        (near t.selfSufficiency ss 1e-6, s!"self-sufficiency {t.selfSufficiency}, want {ss}")] },
  { name := "CAP-homesim.R3 with a spread of 0 the draw total is 2190.0 kWh",
    run := do
      let t := runS7cv0.totals
      return if near t.drawKwh 2190.0 0.1 then none else some s!"draw {t.drawKwh}" },
  { name := "CAP-homesim.R3 with a spread of 0.25 and the seeds 1 to 5 the draw total is from 2060 to 2320 kWh",
    run := do
      let ds := runsStatic.map (·.totals.drawKwh)
      return match (seeds15.zip ds).find? (fun (_, d) => !(d ≥ 2060.0 && d ≤ 2320.0)) with
        | some (s, d) => some s!"seed {s} has a draw of {d} kWh"
        | none => if ds.length == 5 then none else some s!"{ds.length} runs" },
  { name := "CAP-homesim.R3 0 kW of panels give a self-consumption of 0%",
    run := do
      let t := runPv0.totals
      return firstFail [
        (runPv0.hours.size == 8760, s!"{runPv0.hours.size} hours"),
        (near t.pvKwh 0.0 1e-9, s!"solar {t.pvKwh}"),
        (near t.selfConsumption 0.0 1e-9, s!"self-consumption {t.selfConsumption}")] },
  -- A run of 0 days has no hours. Each total and each ratio is 0, except `minTankKwh` and
  -- `finalTankKwh`. These two are 10.5 kWh, the energy of the full tank at the start.
  { name := "CAP-homesim.R3 0 days give a total of 0 and a ratio of 0% in each field, and 10.5 kWh in the tank",
    run := do
      let t := (runHome defaultHome pStatic 7 0).totals
      let zero := [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh),
        ("export", t.exportKwh), ("battery loss", t.batteryLossKwh),
        ("tank loss", t.tankLossKwh), ("heating", t.heatKwh), ("backstop", t.backstopKwh),
        ("draw", t.drawKwh), ("unmet", t.unmetKwh), ("self-consumption", t.selfConsumption),
        ("self-sufficiency", t.selfSufficiency)]
      return firstSome [
        (match zero.find? (fun (_, v) => !(v == 0.0)) with
          | some (n, v) => some s!"{n} is {v}, want 0"
          | none => none),
        valsIs 1e-9 [("lowest tank", t.minTankKwh, 10.5), ("final tank", t.finalTankKwh, 10.5)],
        if t.coldHours == 0 then none else some s!"cold hours {t.coldHours}"] },

  -- CAP-homesim.R4
  { name := "CAP-homesim.R4 the static policy asks for heating only in hours 10, 11, 12 and 13",
    run := do
      let hs := runS7.hours
      let bad := hs.toList.find? (fun h => h.askKwh > 0.0 && !(10 ≤ h.hour && h.hour ≤ 13))
      return match bad with
        | some h => some s!"day {h.day} hour {h.hour} asks for {h.askKwh} kWh"
        | none => if hs.size == 8760 && hs.any (fun h => h.askKwh > 0.0) then none
          else some s!"{hs.size} hours, and no hour asks for heating" },
  { name := "CAP-homesim.R4 the precomputed policy with an error scale of 0 asks for heating only in hours with at least 0.5 kWh of solar energy",
    run := do
      let hs := runP7e0.hours
      let bad := hs.toList.find? (fun h => h.askKwh > 0.0 && !(h.pvKwh ≥ 0.5 - 0.000001))
      return match bad with
        | some h => some s!"day {h.day} hour {h.hour} asks for {h.askKwh} kWh with {h.pvKwh} kWh of solar energy"
        | none => if hs.size == 8760 && hs.any (fun h => h.askKwh > 0.0) then none
          else some s!"{hs.size} hours, and no hour asks for heating" },
  { name := "CAP-homesim.R4 the dynamic policy asks for heating only with a surplus or when the tank held less than 5.25 kWh",
    run := do
      let hs := runD7.hours
      return firstSome [badDynamic hs,
        if hs.size == 8760 && hs.any (fun h => h.askKwh > 0.0) then none
        else some s!"{hs.size} hours, and no hour asks for heating"] },
  { name := "CAP-homesim.R4 the static policy has a higher self-consumption than the static policy with 0 heating hours",
    run := do
      let a := runS7.totals.selfConsumption
      let b := runT7.totals.selfConsumption
      return if a > b then none else some s!"static {a}, 0 heating hours {b}" },
  { name := "CAP-homesim.R4 the dynamic policy has a higher self-consumption than the static policy with 0 heating hours",
    run := do
      let a := runD7.totals.selfConsumption
      let b := runT7.totals.selfConsumption
      return if a > b then none else some s!"dynamic {a}, 0 heating hours {b}" },
  { name := "CAP-homesim.R4 the same policy and seed twice give the same hours",
    run := do
      let cases := [("static", pStatic), ("precomputed", pPlan), ("dynamic", pDyn)]
      return cases.findSome? (fun (n, p) =>
        let a := runHome defaultHome p 7 30
        let b := runHome defaultHome p 7 30
        if a.hours.size == 720 && sameRuns a b then none
        else some s!"the {n} policy gives {a.hours.size} and {b.hours.size} hours, or the hours differ") },

  -- CAP-homesim.R5
  { name := "CAP-homesim.R5 1 seed from seed 3 gives the self-consumption of the run with seed 3 as mean and as worst",
    run := do
      let sc := runsS36[0]!.totals.selfConsumption
      return firstFail [
        (near evalS3x1.meanSelfConsumption sc 1e-9, s!"mean {evalS3x1.meanSelfConsumption}, want {sc}"),
        (near evalS3x1.worstSelfConsumption sc 1e-9,
          s!"worst {evalS3x1.worstSelfConsumption}, want {sc}")] },
  { name := "CAP-homesim.R5 4 seeds from seed 3 give the average of the runs as mean and the lowest as worst",
    run := do
      let scs := runsS36.map (·.totals.selfConsumption)
      return firstFail [
        (scs.length == 4, s!"{scs.length} runs"),
        (near evalS3x4.meanSelfConsumption (meanF scs) 1e-9,
          s!"mean {evalS3x4.meanSelfConsumption}, want {meanF scs}"),
        (near evalS3x4.worstSelfConsumption (minF scs) 1e-9,
          s!"worst {evalS3x4.worstSelfConsumption}, want {minF scs}")] },
  { name := "CAP-homesim.R5 the worst self-consumption is not more than the mean",
    run := do
      let e := evalS3x4
      return if e.worstSelfConsumption ≤ e.meanSelfConsumption + 1e-9 then none
        else some s!"worst {e.worstSelfConsumption}, mean {e.meanSelfConsumption}" },
  { name := "CAP-homesim.R5 the mean import, export and backstop heating are the averages of the runs and the total unmet draw is their sum",
    run := do
      let e := evalS3x4
      let ts := runsS36.map (·.totals)
      return firstFail [
        (ts.length == 4, s!"{ts.length} runs"),
        (near e.meanImportKwh (meanF (ts.map (·.importKwh))) 1e-9, s!"mean import {e.meanImportKwh}"),
        (near e.meanExportKwh (meanF (ts.map (·.exportKwh))) 1e-9, s!"mean export {e.meanExportKwh}"),
        (near e.meanBackstopKwh (meanF (ts.map (·.backstopKwh))) 1e-9,
          s!"mean backstop heating {e.meanBackstopKwh}"),
        (near e.meanSelfSufficiency (meanF (ts.map (·.selfSufficiency))) 1e-9,
          s!"mean self-sufficiency {e.meanSelfSufficiency}"),
        (near e.totalUnmetKwh (sumF (ts.map (·.unmetKwh))) 1e-9,
          s!"total unmet draw {e.totalUnmetKwh}")] },
  { name := "CAP-homesim.R5 4 seeds give seeds 4 and no seed with an unmet draw and no cold hours",
    run := do
      let e := evalS3x4
      return firstFail [
        (e.seeds == 4, s!"seeds {e.seeds}"),
        (e.unmetSeeds == 0, s!"unmetSeeds {e.unmetSeeds}"),
        (e.coldHours == 0, s!"coldHours {e.coldHours}")] },
  -- The runs of the default home have an unmet draw of 0 kWh. Thus the two checks below use a
  -- home with an element of 0.2 kW and no heating hours. A version of `evaluate` that never
  -- counts, or that takes a mean where the line says a sum, fails them.
  { name := "CAP-homesim.R5 for a home with an unmet draw the total unmet draw is the sum of the unmet draws of the runs",
    run := do
      let e := evalE3x4
      let us := runsE36.map (·.totals.unmetKwh)
      return firstFail [
        (us.length == 4, s!"{us.length} runs"),
        (sumF us > 0.0, "the runs have no unmet draw, so the check proves nothing"),
        (e.totalUnmetKwh > 0.0, s!"total unmet draw {e.totalUnmetKwh}"),
        (near e.totalUnmetKwh (sumF us) 1e-9,
          s!"total unmet draw {e.totalUnmetKwh}, the sum of the runs is {sumF us}")] },
  { name := "CAP-homesim.R5 for a home with an unmet draw unmetSeeds counts the runs with an unmet draw and coldHours is the sum of their cold hours",
    run := do
      let e := evalE3x4
      let ts := runsE36.map (·.totals)
      let n := (ts.filter (fun t => t.unmetKwh > 0.0)).length
      let cold := ts.foldl (fun acc t => acc + t.coldHours) (0 : Nat)
      return firstFail [
        (ts.length == 4, s!"{ts.length} runs"),
        (n > 0, "no run has an unmet draw, so the check proves nothing"),
        (cold > 0, "no run has a cold hour, so the check proves nothing"),
        (e.unmetSeeds > 0, s!"unmetSeeds {e.unmetSeeds}"),
        (e.unmetSeeds == n, s!"unmetSeeds {e.unmetSeeds}, the runs with an unmet draw are {n}"),
        (e.coldHours == cold, s!"coldHours {e.coldHours}, the sum of the runs is {cold}")] },
  { name := "CAP-homesim.R5 0 seeds give 0 in each field",
    run := do
      let e := evalS3x0
      let zero := [("mean self-consumption", e.meanSelfConsumption),
        ("worst self-consumption", e.worstSelfConsumption),
        ("mean self-sufficiency", e.meanSelfSufficiency), ("mean import", e.meanImportKwh),
        ("mean export", e.meanExportKwh), ("mean backstop heating", e.meanBackstopKwh),
        ("total unmet draw", e.totalUnmetKwh)]
      return match zero.find? (fun (_, v) => !(v == 0.0)) with
        | some (n, v) => some s!"{n} is {v}, want 0"
        | none =>
          if e.seeds == 0 && e.unmetSeeds == 0 && e.coldHours == 0 then none
          else some s!"seeds {e.seeds}, unmetSeeds {e.unmetSeeds}, coldHours {e.coldHours}" },
  { name := "CAP-homesim.R5 the same arguments twice give the same evaluation",
    run := do
      return if sameEval evalS3x4 evalS3x4b 0.0 then none
        else some s!"first {repr evalS3x4}, second {repr evalS3x4b}" },
  -- The test seam `homeSeed`. The lines above use the first seed 3. The check below uses the
  -- first seed 7 and 8, and it runs `runHome` with the same seeds.
  { name := "CAP-homesim.R5 homeSeed: the first seed 7 and 2 seeds evaluate the runs with the seeds 7 and 8, and the first seed 8 and 1 seed evaluates the run with seed 8",
    run := do
      let t7 := seamS7.totals
      let t8 := seamS8.totals
      let e2 := evalSeam7x2
      let e1 := evalSeam8x1
      return firstFail [
        (!(near t7.selfConsumption t8.selfConsumption 1e-9 && near t7.importKwh t8.importKwh 1e-9),
          "the runs with the seeds 7 and 8 have the same totals, so the check proves nothing"),
        (e2.seeds == 2 && e1.seeds == 1, s!"seeds {e2.seeds} and {e1.seeds}"),
        (near e2.meanSelfConsumption (meanF [t7.selfConsumption, t8.selfConsumption]) 1e-9,
          s!"mean self-consumption {e2.meanSelfConsumption}, want {meanF [t7.selfConsumption, t8.selfConsumption]}"),
        (near e2.worstSelfConsumption (minF [t7.selfConsumption, t8.selfConsumption]) 1e-9,
          s!"worst self-consumption {e2.worstSelfConsumption}, want {minF [t7.selfConsumption, t8.selfConsumption]}"),
        (near e2.meanImportKwh (meanF [t7.importKwh, t8.importKwh]) 1e-9,
          s!"mean import {e2.meanImportKwh}, want {meanF [t7.importKwh, t8.importKwh]}"),
        (near e1.meanSelfConsumption t8.selfConsumption 1e-9,
          s!"mean self-consumption of seed 8 {e1.meanSelfConsumption}, want {t8.selfConsumption}"),
        (near e1.worstSelfConsumption t8.selfConsumption 1e-9,
          s!"worst self-consumption of seed 8 {e1.worstSelfConsumption}, want {t8.selfConsumption}"),
        (near e1.meanImportKwh t8.importKwh 1e-9,
          s!"mean import of seed 8 {e1.meanImportKwh}, want {t8.importKwh}")] },

  -- CAP-homesim.R6
  { name := "CAP-homesim.R6 2 seeds from seed 1 and 30 days give 704 candidates and 704 safe candidates",
    run := do
      return firstFail [
        (tune1.candidates == 704, s!"candidates {tune1.candidates}"),
        (tune1.safe == 704, s!"safe {tune1.safe}")] },
  { name := "CAP-homesim.R6 the best start is from 6 to 16, its heating hours from 1 to 8 and its discharge hour from 15 to 22",
    run := do
      let b := tune1.best
      return firstFail [
        (6 ≤ b.heatStart && b.heatStart ≤ 16, s!"start {b.heatStart}"),
        (1 ≤ b.heatHours && b.heatHours ≤ 8, s!"heating hours {b.heatHours}"),
        (15 ≤ b.dischargeFrom && b.dischargeFrom ≤ 22, s!"discharge hour {b.dischargeFrom}")] },
  { name := "CAP-homesim.R6 the evaluation is the evaluation of the best static profile over the same seeds and days",
    run := do
      let e := evaluate defaultHome (Policy.static tune1.best) 1 2 30
      return if sameEval tune1.evaluation e 1e-9 then none
        else some s!"tuner {repr tune1.evaluation}, evaluate {repr e}" },
  { name := "CAP-homesim.R6 no safe candidate has a mean self-consumption more than 0.05 points above the best",
    run := do
      let best := tune1.evaluation.meanSelfConsumption
      let bad := accGridEvals.find? (fun (_, e) =>
        e.unmetSeeds == 0 && e.meanSelfConsumption > best + 0.05 + 1e-9)
      return if accGridEvals.length != 704 then some s!"{accGridEvals.length} candidates"
        else match bad with
          | some (p, e) => some s!"start {p.heatStart}, {p.heatHours} hours, discharge {p.dischargeFrom} has {e.meanSelfConsumption}, the best has {best}"
          | none => none },
  { name := "CAP-homesim.R6 no safe candidate within 0.05 points of the highest has a lower mean import than the best",
    run := do
      let safeEvals := accGridEvals.filter (fun (_, e) => e.unmetSeeds == 0)
      let top := safeEvals.foldl (fun acc (_, e) =>
        if e.meanSelfConsumption > acc then e.meanSelfConsumption else acc) (-1.0)
      let bestImport := tune1.evaluation.meanImportKwh
      let bad := safeEvals.find? (fun (_, e) =>
        e.meanSelfConsumption ≥ top - 0.05 && e.meanImportKwh < bestImport - 1e-9)
      return if accGridEvals.length != 704 then some s!"{accGridEvals.length} candidates"
        else match bad with
          | some (p, e) => some s!"start {p.heatStart}, {p.heatHours} hours, discharge {p.dischargeFrom} has an import of {e.meanImportKwh}, the best has {bestImport}"
          | none => none },
  { name := "CAP-homesim.R6 the same arguments twice give the same result",
    run := do
      let a := tune1
      let b := tune2
      return if a.best.heatStart == b.best.heatStart && a.best.heatHours == b.best.heatHours &&
          a.best.dischargeFrom == b.best.dischargeFrom && a.candidates == b.candidates &&
          a.safe == b.safe && sameEval a.evaluation b.evaluation 0.0 then none
        else some s!"first {repr a}, second {repr b}" },
  { name := "CAP-homesim.R6 a home with 0 kW of panels gives 704 safe candidates and a best mean self-consumption of 0%",
    run := do
      return firstFail [
        (tunePv0.safe == 704, s!"safe {tunePv0.safe}"),
        (near tunePv0.evaluation.meanSelfConsumption 0.0 1e-9,
          s!"best mean self-consumption {tunePv0.evaluation.meanSelfConsumption}")] },
  -- The test seam `homeSeed`. The lines above use the first seed 1. An app that fixes the first
  -- seed at 1 passes them. The check below uses the first seed 3 and 1 seed. The best profile
  -- must have the evaluation of seed 3, and seed 4 must give another evaluation of the same
  -- profile (the weather and the draw of the days depend on the seed).
  { name := "CAP-homesim.R6 homeSeed: the tuner with the first seed 3 and 1 seed gives the evaluation of its best static profile with seed 3",
    run := do
      let t := seamTune3
      return firstFail [
        (t.candidates == 704, s!"candidates {t.candidates}"),
        (t.evaluation.seeds == 1, s!"seeds {t.evaluation.seeds}"),
        (sameEval t.evaluation seamEval3 1e-9,
          s!"tuner {repr t.evaluation}, evaluate with seed 3 {repr seamEval3}"),
        (!sameEval seamEval3 seamEval4 1e-9,
          "the seeds 3 and 4 give the same evaluation of the best profile, so the check proves nothing")] }
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
