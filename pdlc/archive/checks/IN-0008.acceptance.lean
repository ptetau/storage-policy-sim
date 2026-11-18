/-
Acceptance checks of IN-0008 (hot-water policy simulation).

Stored-data lines: none. No requirement of this intent reads or writes stored data.

The capability lines (CAP-forecast, CAP-hotwater, CAP-simulation, CAP-policy, CAP-homesim) use
the public functions of the library. The JOB-simulate lines run the `sim` command as a process
(arguments, stdout, stderr and the exit code). The checks of the library fail until the last
change of the intent is built. That is correct.

JOB-simulate.R5: this intent changes only the usage line. Thus this file proves the three
lines about the usage (`sim`, `sim help` and `sim --help`). The other lines of R5 did not
change, and tests/acceptance/IN-0001.acceptance.lean still proves them.

Shared runs. A run of the library or of `sim` can take long, so one run serves several checks:
- A library run is a value at the top level of this file. The first check that reads it
  makes the run. The next checks read the same value.
- A `sim` run goes through a small cache in `main`. The first check that runs an argument
  list makes the run. The next checks read the same output.

Cost. The checks of CAP-homesim run the home simulation for 365 days over many seeds, and
the lines of CAP-homesim.R6 evaluate each of the 704 candidates of the tuner. The interpreter
runs these checks. Thus this file needs minutes to run, not seconds. A line that does not
need a full year adds `--days 3`, `--days 10`, `--days 30` or `--days 1` to its command.

Statistics of CAP-forecast.R7. The relative error of a sunny period is its estimate less its
actual power, over the actual power. R7 divides it also by the spread. The spread depends only
on the lead time of the period. Each series that a line compares has one lead time (for
example, the period that ends at 11:30 in the fetches at 00:00). Thus the spread is one
constant for the series. A correlation does not change when a series is scaled by a constant,
and the sign does not change either. So the helper `relErr` leaves out the spread. It then
needs no rule for the spread (a step or a slope).
A sunny period is a period with an actual power of more than 0 kW, as CAP-forecast.R2 says.
An estimate is cut when it is 0 kW or it is the panel power (5 kW).

Terms of the checks:
- The actual power of a period that ends at minute `e` is the solar energy of hour
  `(e - 30) / 60` in the scenario with the same site, seed and days.
- The home of the lines of CAP-homesim is `defaultHome`. A policy is the static policy
  with `defaultStatic`, the precomputed policy with `defaultPlan` or the dynamic policy with
  `defaultDynamic`, unless the line says otherwise.
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
  if x < 0.0 then -(Float.round (-x * 10.0)) / 10.0 else Float.round (x * 10.0) / 10.0

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

/-- The standard deviation of a list. The divisor is the count. -/
def stdF (xs : List Float) : Float :=
  let m := meanF xs
  Float.sqrt (meanF (xs.map (fun x => (x - m) * (x - m))))

/-- The correlation of two lists of the same length. It is 0 when a list has no spread. -/
def corrF (xs ys : List Float) : Float :=
  let mx := meanF xs
  let mv := meanF ys
  let cov := meanF ((xs.zip ys).map (fun (p : Float × Float) => (p.1 - mx) * (p.2 - mv)))
  let vx := meanF (xs.map (fun x => (x - mx) * (x - mx)))
  let vy := meanF (ys.map (fun y => (y - mv) * (y - mv)))
  if vx > 0.0 && vy > 0.0 then cov / Float.sqrt (vx * vy) else 0.0

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

/-- Compares named values with a tolerance. Gives the first value that is wrong. -/
def valsIs (tol : Float) (pairs : List (String × Float × Float)) : Option String :=
  match pairs.find? (fun (_, got, want) => !near got want tol) with
  | some (n, got, want) => some s!"{n} is {got}, want {want}"
  | none => none

-- Helpers for CAP-forecast

def site45 : Site :=
  { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

/-- The hours of seed 7 and 365 days, built once. -/
def scen7 : Array Hour := scenario site45 7 365

/-- The hours of seed 8 and 365 days, for the lines that compare two seeds. -/
def scen8 : Array Hour := scenario site45 8 365

/-- A forecast of the lines: site 45, seed 7, 365 days, from the built hours. -/
def fo (scale : Float) (fetch : Nat) : Array Period :=
  forecastOf scen7 site45 7 scale fetch

/-- The hour of the run of a period that ends at minute `e`. -/
def accHourOf (e : Nat) : Nat := (e - 30) / 60

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def accActualKw (e : Nat) : Float := scen7[accHourOf e]!.pvKwh

def samePeriod (a b : Period) : Bool :=
  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
  a.p90Kw == b.p90Kw

def samePeriods (a b : Array Period) : Bool :=
  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)

def sumEst (ps : Array Period) : Float := sumF (ps.toList.map (fun p => p.estimateKw))

/-- Each value of each period must equal its actual power. -/
def badEqual (ps : Array Period) : Option String :=
  ps.toList.findSome? (fun p =>
    let a := accActualKw p.endMinute
    if near p.estimateKw a 1e-6 && near p.p10Kw a 1e-6 && near p.p90Kw a 1e-6 then none
    else some s!"end {p.endMinute}: actual {a}, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}")

/-- `forecastOf` and `forecast` must give the same periods for a fetch hour. -/
def sameAsForecast (f : Nat) : Option String :=
  let a := forecastOf scen7 site45 7 1.0 f
  let b := forecast site45 7 365 1.0 f
  if a.size > 0 && samePeriods a b then none
  else some s!"fetch {f}: forecastOf gives {a.size} periods and forecast gives {b.size}, or a value differs"

/-- The period of a fetch that ends at minute `e` of the run. -/
def periodEnding (ps : Array Period) (e : Nat) : Option Period :=
  ps.toList.find? (fun p => p.endMinute == e)

/-- The relative error of a period: its estimate less its actual power, over the actual power.
The spread is left out. See the comment at the top of the file. -/
def relErr (p : Period) : Float :=
  (p.estimateKw - accActualKw p.endMinute) / accActualKw p.endMinute

/-- An estimate is cut at 0 kW or at the panel power of 5 kW. -/
def isCut (p : Period) : Bool := p.estimateKw ≤ 1e-9 || p.estimateKw ≥ 5.0 - 1e-9

/-- A sunny period with an estimate that is not cut. -/
def okSunny (p : Period) : Bool := accActualKw p.endMinute > 0.0 && !isCut p

def inBand (p : Period) : Bool :=
  let a := accActualKw p.endMinute
  p.p10Kw - 1e-9 ≤ a && a ≤ p.p90Kw + 1e-9

/-- The fetches at 00:00 of the days 0 to 364, each with the hour of its fetch. -/
def dayFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d, fo 1.0 (24 * d)))

/-- The fetches at hour 10 of the days 0 to 364. -/
def tenFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d + 10, fo 1.0 (24 * d + 10)))

/-- The relative errors of the periods that end at 11:30 and at 13:30 of the same day, for
each day that has both, sunny and not cut. The fetch is at 00:00 of the day. -/
def pairsSameDay : List (Float × Float) :=
  dayFetches.filterMap (fun (f, ps) =>
    match periodEnding ps (60 * f + 690), periodEnding ps (60 * f + 810) with
    | some a, some b => if okSunny a && okSunny b then some (relErr a, relErr b) else none
    | _, _ => none)

/-- The relative error of the sunny period that ends at 11:30 of the day of a fetch at 00:00,
shifted by `shift` minutes. A day has none when its period is not in the fetch or it is not
sunny. -/
def err1130 (shift : Nat) : List (Option Float) :=
  dayFetches.map (fun (f, ps) =>
    match periodEnding ps (60 * f + 690 + shift) with
    | some p => if accActualKw p.endMinute > 0.0 then some (relErr p) else none
    | none => none)

def bothSome (a b : List (Option Float)) : List (Float × Float) :=
  (a.zip b).filterMap (fun (x, y) =>
    match x, y with
    | some u, some v => some (u, v)
    | _, _ => none)

/-- The periods that end at 11:30 of a day and of the next day. Each one comes from the fetch
at 00:00 of its own day. -/
def pairsNextFetch : List (Float × Float) :=
  bothSome (err1130 0) ((err1130 0).tail)

/-- The periods that end at 11:30 of a day and of the next day. Both come from the fetch at
00:00 of the first day. -/
def pairsNextSameFetch : List (Float × Float) :=
  bothSome (err1130 0) (err1130 1440)

/-- The relative errors of the period that ends at 13:30 of a day, from the fetch at 00:00 and
from the fetch at hour 10. Only a sunny period counts. -/
def signPairs : List (Float × Float) :=
  (dayFetches.zip tenFetches).filterMap (fun (a, b) =>
    match periodEnding a.2 (60 * a.1 + 810), periodEnding b.2 (60 * a.1 + 810) with
    | some p, some q =>
      if accActualKw p.endMinute > 0.0 then some (relErr p, relErr q) else none
    | _, _ => none)

/-- The sunny periods of the fetches at 00:00 of each day. -/
def sunnyAll : List Period :=
  dayFetches.foldl (fun acc (_, ps) =>
    acc ++ ps.toList.filter (fun p => accActualKw p.endMinute > 0.0)) []

-- Helpers for CAP-hotwater

/-- The default tank with a cut-in of 0 kWh, so that the thermostat stays out of a line. -/
def flatTank : TankConfig := { defaultTank with cutInKwh := 0.0 }

/-- A state with the thermostat off and with the tank full today. -/
def stOff (e : Float) : TankState := { energyKwh := e, heating := false, fullToday := true }

/-- A state with the thermostat on and with the tank full today. -/
def stOn (e : Float) : TankState := { energyKwh := e, heating := true, fullToday := true }

/-- A state with the thermostat off and with the tank not full today. -/
def stOpen (e : Float) : TankState := { energyKwh := e, heating := false, fullToday := false }

/-- The draw of one day, from the 24 hours. -/
def accDayDraw (daily lat : Float) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc h => acc + drawKwh daily lat d h) 0.0

/-- The draw of the days 0 to 364. -/
def accYearDraw (daily lat : Float) : Float :=
  (List.range 365).foldl (fun acc d => acc + accDayDraw daily lat d) 0.0

/-- The factors of the days 0 to `n - 1`. -/
def accFactors (seed : Nat) (cv : Float) (n : Nat) : List Float :=
  (List.range n).map (fun d => drawFactor seed d cv)

/-- The thermostat of the state after the hour must be on or off. -/
def thermoIs (s : TankStep) (want : Bool) : Option String :=
  if s.state.heating == want then none
  else some s!"the thermostat is {s.state.heating}, want {want}"

/-- `fullToday` of the state after the hour must be true or false. -/
def fullIs (s : TankStep) (want : Bool) : Option String :=
  if s.state.fullToday == want then none
  else some s!"fullToday is {s.state.fullToday}, want {want}"

-- Helpers for CAP-simulation.R6

def b105 : Battery := { capacityKwh := 10.0, powerKw := 5.0 }

/-- The solar energy and the load of the 24 hours of day 100: latitude 45, seed 7. -/
def dayLoads : Array (Float × Float) :=
  ((List.range 24).map (fun h =>
    let s := scen7[100 * 24 + h]!
    (s.pvKwh, s.baseLoadKwh + s.flexKwh))).toArray

def flowSame (a b : Flow) (tol : Float) : Bool :=
  near a.directKwh b.directKwh tol && near a.chargeKwh b.chargeKwh tol &&
  near a.dischargeKwh b.dischargeKwh tol && near a.exportKwh b.exportKwh tol &&
  near a.importKwh b.importKwh tol && near a.lossKwh b.lossKwh tol &&
  near a.socKwh b.socKwh tol

/-- Runs the 24 hours of day 100 with the battery energy of the hour before. The battery may
charge in each hour, and it may discharge from hour `from`. Each flow must equal the flow of
`stepHour` with `strat`. Gives the first hour that differs. -/
def gatedVersus (strat : Strategy) (dischargeFrom : Nat) (soc0 : Float) : Option String :=
  let step := fun (acc : Float × Option String) (h : Nat) =>
    let p := dayLoads[h]!
    let g := stepHourGated b105 acc.1 true (decide (h ≥ dischargeFrom)) p.1 p.2
    let s := stepHour b105 acc.1 strat h p.1 p.2
    let bad := if acc.2.isNone && !flowSame g s 1e-9 then
        some s!"hour {h}: gated {repr g}, stepHour {repr s}"
      else acc.2
    (g.socKwh, bad)
  ((List.range 24).foldl step (soc0, (none : Option String))).2

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

-- Helpers for CAP-homesim

def pStatic : Policy := Policy.static defaultStatic
def pThermo : Policy := Policy.static { defaultStatic with heatHours := 0 }
def pPlan : Policy := Policy.precomputed defaultPlan
def pDyn : Policy := Policy.dynamic defaultDynamic

def homeCv (cv : Float) : HomeSetup := { defaultHome with drawCv := cv }
def homeLat45 : HomeSetup :=
  { defaultHome with site := { defaultHome.site with latitude := 45.0 } }
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

/-- The five policies of `sim policy compare` and `sim policy robust`, each with its home. -/
def rowSetups (home : HomeSetup) : List (String × HomeSetup × Policy) :=
  [("thermostat", home, pThermo), ("static", home, pStatic), ("precomputed", home, pPlan),
   ("dynamic", home, pDyn), ("perfect-forecast", { home with errorScale := 0.0 }, pPlan)]

/-- The totals of the five policies for latitude 45, seed 9 and 90 days. -/
def cmpLib90 : List (String × HomeTotals) :=
  (rowSetups homeLat45).map (fun (n, s, p) => (n, (runHome s p 9 90).totals))

/-- The evaluations of the five policies over the seeds 1 to 10 for 365 days. -/
def robustLib : List (String × Evaluation) :=
  (rowSetups defaultHome).map (fun (n, s, p) => (n, evaluate s p 1 10 365))

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

-- Helpers for the `sim` process

structure RunOut where
  code : UInt32
  out : String
  err : String

def sim (args : List String) : IO RunOut := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

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

def lines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")

/-- A line of `sim policy run`: the label, spaces to fill 18 characters, and the value. -/
def row (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
def labelled (l label : String) : Bool :=
  let cs := l.toList
  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '

def usageNew : String :=
  "usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]"

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

def firstWords (out : String) : List String :=
  (lines out).map (fun l => (words l).head?.getD "")

def valueOf (out label : String) : Option String :=
  match (lines out).find? (fun l => (words l).head? == some label) with
  | some l => (words l)[1]?
  | none => none

def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum

/-- The words of the line that starts with `name`. -/
def rowWords (out name : String) : Option (List String) :=
  ((lines out).find? (fun l => (words l).head? == some name)).map words

def showsNum (s : Option String) (x : Float) : Bool :=
  match s.bind parseNum with
  | some v => near v (round1 x) 0.001
  | none => false

def checkShows (out : String) (pairs : List (String × Float)) : Option String :=
  match pairs.find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

def oneDecimal (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
  | _ => false

/-- The lines of `sim policy run` must show the totals of a run of the library. -/
def policyPairs (t : HomeTotals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh), ("export", t.exportKwh),
   ("heating", t.heatKwh), ("backstop", t.backstopKwh), ("unmet-hot-water", t.unmetKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

/-- A row of `sim policy compare` must show five values of the totals, with one decimal. -/
def compareRowShows (w : List String) (t : HomeTotals) : Bool :=
  w.length == 6 && (w.drop 1).all oneDecimal &&
  showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
  showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh && showsNum w[5]? t.backstopKwh

/-- A row of `sim policy robust` must show an evaluation. The column `safe` is `yes` when no
seed has an unmet draw and `cold-hours` is 0. -/
def robustRowShows (w : List String) (e : Evaluation) : Bool :=
  w.length == 9 && showsNum w[1]? e.meanSelfConsumption &&
  showsNum w[2]? e.worstSelfConsumption && showsNum w[3]? e.meanSelfSufficiency &&
  showsNum w[4]? e.meanExportKwh && showsNum w[5]? e.meanBackstopKwh &&
  showsNum w[6]? e.totalUnmetKwh && w[7]? == some (toString e.coldHours) &&
  w[8]? == some (if e.unmetSeeds == 0 && e.coldHours == 0 then "yes" else "no")

/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
def expectError (args : List String) (line : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]

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

/-- The line that starts with `label`. -/
def lineOf (out label : String) : Option String :=
  (lines out).find? (fun l => (words l).head? == some label)

/-- The value of the line `label` must be a number near `want`. -/
def numNear (out label : String) (want tol : Float) : Bool :=
  match numOf out label with
  | some v => near v want tol
  | none => false

/-- The self-consumption of a row of `sim policy compare` or `sim policy robust`. The mean is
the first value of both tables. -/
def firstOfRow (out name : String) : Option Float :=
  (rowWords out name).bind (fun w => w[1]?.bind parseNum)

/-- The words of a row without its name. -/
def tailOfRow (out name : String) : Option (List String) :=
  (rowWords out name).map (fun w => w.drop 1)

/-- A `sim policy run` argument list for an option that is checked at its edge. The run is 3
days, so that the check stays cheap. -/
def cheap (extra : List String) : List String :=
  ["policy", "run", "--days", "3"] ++ extra

def pr (extra : List String) : List String := ["policy", "run"] ++ extra

-- The checks of each spec

def forecastChecks : List Check := [
  -- CAP-forecast.R6
  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast for the fetch hours 0, 4116 and 8750",
    run := do
      let a := forecastOf scen7 site45 7 1.0 0
      let b := forecastOf scen7 site45 7 1.0 8750
      return firstSome [
        sameAsForecast 0, sameAsForecast 4116, sameAsForecast 8750,
        if a.size == 96 && b.size == 20 then none
        else some s!"{a.size} periods at hour 0 and {b.size} periods at hour 8750"] },
  { name := "CAP-forecast.R6 with an error scale of 0 each value of a fetch at hour 4000 equals its actual power",
    run := do
      let ps := forecastOf scen7 site45 7 0.0 4000
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R6 a fetch at hour 8760 has no period",
    run := do
      let ps := forecastOf scen7 site45 7 1.0 8760
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 no hours give no period for a fetch at hour 0",
    run := do
      let ps := forecastOf (#[] : Array Hour) site45 7 1.0 0
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 seeds 7 and 8 give a different estimate for a fetch at hour 4000",
    run := do
      let a := forecastOf scen7 site45 7 1.0 4000
      let b := forecastOf scen8 site45 8 1.0 4000
      let differs := (List.zip a.toList b.toList).any (fun (x, y) => !(x.estimateKw == y.estimateKw))
      return firstFail [
        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
        (differs, "each estimate is the same for the two seeds")] },

  -- CAP-forecast.R7
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 and at 13:30 of a day have a correlation from 0.55 to 0.85",
    run := do
      let n := pairsSameDay.length
      let c := corrF (pairsSameDay.map (·.1)) (pairsSameDay.map (·.2))
      if n < 150 then
        return some s!"only {n} days have both periods"
      return if c ≥ 0.55 && c ≤ 0.85 then none
        else some s!"correlation {c} over {n} days" },
  -- The line says that each period comes from the fetch at 00:00 of its own day. The variable `a`
  -- reads the line so. The variable `b` also takes both periods from the fetch of the first
  -- day. Both readings must give a correlation from -0.25 to 0.25.
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25",
    run := do
      let a := pairsNextFetch
      let b := pairsNextSameFetch
      let ca := corrF (a.map (·.1)) (a.map (·.2))
      let cb := corrF (b.map (·.1)) (b.map (·.2))
      return firstFail [
        (a.length ≥ 150 && b.length ≥ 150, s!"only {a.length} and {b.length} pairs of days"),
        (ca ≥ -0.25 && ca ≤ 0.25,
          s!"fetch of each day: correlation {ca} over {a.length} pairs of days"),
        (cb ≥ -0.25 && cb ≤ 0.25,
          s!"one fetch for both days: correlation {cb} over {b.length} pairs of days")] },
  { name := "CAP-forecast.R7 at least 62% of the days have the same sign of the error at 13:30 in the fetches at hour 0 and at hour 10",
    run := do
      let usable := signPairs.filter (fun (x, y) => x.abs > 1e-12 && y.abs > 1e-12)
      let same := usable.filter (fun (x, y) => x * y > 0.0)
      let n := usable.length
      if n < 150 then
        return some s!"only {n} days count"
      return if same.length.toFloat ≥ 0.62 * n.toFloat then none
        else some s!"{same.length} of {n} days have the same sign" },
  { name := "CAP-forecast.R7 with an error scale of 0 each value of a fetch at hour 0 equals its actual power",
    run := do
      let ps := fo 0.0 0
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R7 60% to 95% of the sunny periods of a fetch at 00:00 of each day have the actual power in the band",
    run := do
      let n := sunnyAll.length
      let k := (sunnyAll.filter inBand).length
      if n < 1000 then
        return some s!"only {n} sunny periods"
      return if k.toFloat ≥ 0.6 * n.toFloat && k.toFloat ≤ 0.95 * n.toFloat then none
        else some s!"{k} of {n} sunny periods have the actual power in the band" }
]

def hotwaterChecks : List Check := [
  -- CAP-hotwater.R1
  { name := "CAP-hotwater.R1 8.0 kWh stored and no draw give a loss of 0.048 kWh and 7.952 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 8.0) 12 0.0 0.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.048), ("tank", s.state.energyKwh, 7.952)] },
  { name := "CAP-hotwater.R1 8.0 kWh stored and a draw of 1.5 kWh serve the draw and leave 6.452 kWh",
    run := do
      let s := tankStep flatTank (stOff 8.0) 12 0.0 1.5
      return valsIs 1e-9 [("loss", s.lossKwh, 0.048), ("served", s.servedKwh, 1.5),
        ("unmet", s.unmetKwh, 0.0), ("tank", s.state.energyKwh, 6.452)] },
  { name := "CAP-hotwater.R1 1.0 kWh stored and a draw of 2.0 kWh leave an unmet draw of 1.006 kWh",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.006), ("served", s.servedKwh, 0.994),
        ("unmet", s.unmetKwh, 1.006)] },
  { name := "CAP-hotwater.R1 0.0 kWh stored and a draw of 1.0 kWh give no loss and an unmet draw of 1.0 kWh",
    run := do
      let s := tankStep flatTank (stOff 0.0) 12 0.0 1.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.0), ("served", s.servedKwh, 0.0),
        ("unmet", s.unmetKwh, 1.0)] },
  { name := "CAP-hotwater.R1 10.5 kWh stored and no draw give a loss of 0.063 kWh",
    run := do
      let s := tankStep flatTank (stOff 10.5) 12 0.0 0.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.063)] },
  { name := "CAP-hotwater.R1 a tank with no loss keeps 5.0 kWh in an hour with no draw",
    run := do
      let s := tankStep { flatTank with lossPerHour := 0.0 } (stOff 5.0) 12 0.0 0.0
      return valsIs 1e-9 [("tank", s.state.energyKwh, 5.0)] },

  -- CAP-hotwater.R2
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 2.0 kWh give a heating of 2.0 kWh and 6.97 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 2.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 2.0), ("tank", s.state.energyKwh, 6.97)] },
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 5.0 kWh give a heating of 3.0 kWh, the element power",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 5.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 3.0), ("tank", s.state.energyKwh, 7.97)] },
  { name := "CAP-hotwater.R2 9.0 kWh stored and a request of 3.0 kWh give a heating of 1.554 kWh, the room that is left",
    run := do
      let s := tankStep flatTank (stOff 9.0) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 1.554), ("tank", s.state.energyKwh, 10.5)] },
  { name := "CAP-hotwater.R2 10.5 kWh stored and a request of 3.0 kWh give a heating of 0.063 kWh",
    run := do
      let s := tankStep flatTank (stOff 10.5) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 0.063), ("tank", s.state.energyKwh, 10.5)] },
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 0 kWh give no heating",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 0.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 0.0)] },
  { name := "CAP-hotwater.R2 the draw comes before the heating: 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh leave an unmet draw of 0.512 kWh",
    run := do
      let s := tankStep flatTank (stOff 2.0) 12 3.0 2.5
      return valsIs 1e-9 [("served", s.servedKwh, 1.988), ("unmet", s.unmetKwh, 0.512),
        ("heating", s.heatKwh, 3.0), ("tank", s.state.energyKwh, 3.0)] },
  { name := "CAP-hotwater.R2 a tank with a capacity of 0 kWh has an unmet draw of 1.0 kWh and takes no heating",
    run := do
      let s := tankStep { flatTank with capacityKwh := 0.0 } (stOff 0.0) 12 3.0 1.0
      return valsIs 1e-9 [("unmet", s.unmetKwh, 1.0), ("heating", s.heatKwh, 0.0),
        ("tank", s.state.energyKwh, 0.0)] },

  -- CAP-hotwater.R3
  { name := "CAP-hotwater.R3 a tank at 5.0 kWh cuts the thermostat in",
    run := do
      let s := tankStep defaultTank (stOff 5.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 7.97)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat off gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 6.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 5.964)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat on keeps heating",
    run := do
      let s := tankStep defaultTank (stOn 6.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 8.964)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a tank at 9.0 kWh with the thermostat on heats to full and then the thermostat goes off",
    run := do
      let s := tankStep defaultTank (stOn 9.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 1.554), ("tank", s.state.energyKwh, 10.5)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a request of 2.0 kWh at 5.0 kWh keeps the thermostat off and gives no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 5.0) 12 2.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 2.0), ("backstop", s.backstopKwh, 0.0),
          ("tank", s.state.energyKwh, 6.97)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a request of 1.0 kWh at 4.0 kWh leaves 2.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 4.0) 12 1.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("backstop", s.backstopKwh, 2.0),
          ("tank", s.state.energyKwh, 6.976)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a request of 1.0 kWh at 9.0 kWh with the thermostat on leaves 0.554 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOn 9.0) 12 1.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("backstop", s.backstopKwh, 0.554),
          ("tank", s.state.energyKwh, 10.5)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a draw that empties the tank gives an unmet draw of 1.006 kWh and 3.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("unmet", s.unmetKwh, 1.006), ("backstop", s.backstopKwh, 3.0),
        ("tank", s.state.energyKwh, 3.0)] },
  { name := "CAP-hotwater.R3 a cut-in of 0 kWh gives no backstop heating at 1.0 kWh",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },

  -- CAP-hotwater.R4
  { name := "CAP-hotwater.R4 at latitude 45 the draw of the days 0 to 364 adds up to 2190.0 kWh",
    run := do
      let t := accYearDraw 6.0 45.0
      return if near t 2190.0 0.1 then none else some s!"got {t}" },
  { name := "CAP-hotwater.R4 at latitude 45 the 24 hours of day 100 add up to the seasonal draw",
    run := do
      let t := accDayDraw 6.0 45.0 100
      let want := 6.0 * (1.0 + 0.15 * Float.cos (2.0 * 3.141592653589793 * 85.0 / 365.0))
      return if near t want 0.000001 then none else some s!"got {t}, want {want}" },
  { name := "CAP-hotwater.R4 at latitude 45 the draw of day 15 is 1.34 to 1.37 times the draw of day 197",
    run := do
      let q := accDayDraw 6.0 45.0 15 / accDayDraw 6.0 45.0 197
      return if q ≥ 1.34 && q ≤ 1.37 then none else some s!"ratio {q}" },
  { name := "CAP-hotwater.R4 at latitude -41 the draw of day 197 is 1.34 to 1.37 times the draw of day 15",
    run := do
      let q := accDayDraw 6.0 (-41.0) 197 / accDayDraw 6.0 (-41.0) 15
      return if q ≥ 1.34 && q ≤ 1.37 then none else some s!"ratio {q}" },
  { name := "CAP-hotwater.R4 on day 100 hour 7 draws more than hour 3, and hour 19 draws more than hour 13",
    run := do
      let h7 := drawKwh 6.0 45.0 100 7
      let h3 := drawKwh 6.0 45.0 100 3
      let h19 := drawKwh 6.0 45.0 100 19
      let h13 := drawKwh 6.0 45.0 100 13
      return firstFail [
        (h7 > h3, s!"hour 7 draws {h7}, hour 3 draws {h3}"),
        (h19 > h13, s!"hour 19 draws {h19}, hour 13 draws {h13}")] },
  { name := "CAP-hotwater.R4 a daily energy of 0.0 kWh gives a draw of 0 kWh in each hour of day 100",
    run := do
      let bad := (List.range 24).find? (fun h => !near (drawKwh 0.0 45.0 100 h) 0.0 1e-12)
      return match bad with
        | some h => some s!"hour {h} draws {drawKwh 0.0 45.0 100 h}"
        | none => none },

  -- CAP-hotwater.R5
  { name := "CAP-hotwater.R5 at hour 20 a tank at 9.0 kWh that was not full today heats to full",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 20 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 1.554), ("tank", s.state.energyKwh, 10.5)],
        fullIs s true] },
  { name := "CAP-hotwater.R5 at hour 19 a tank at 9.0 kWh that was not full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 19 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 8.946)],
        fullIs s false] },
  { name := "CAP-hotwater.R5 at hour 20 a tank at 9.0 kWh that was full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 9.0) 20 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 8.946)] },
  { name := "CAP-hotwater.R5 at hour 22 a tank at 4.0 kWh that was not full today gets 3.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 4.0) 22 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 6.976)],
        thermoIs s true] },
  { name := "CAP-hotwater.R5 at hour 0 a full tank loses energy and fullToday starts again as false",
    run := do
      let s := tankStep defaultTank (stOff 10.5) 0 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("tank", s.state.energyKwh, 10.437)],
        fullIs s false] },
  { name := "CAP-hotwater.R5 at hour 0 a request of 3.0 kWh at 10.5 kWh fills the tank and fullToday is true",
    run := do
      let s := tankStep defaultTank (stOpen 10.5) 0 3.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 0.063), ("tank", s.state.energyKwh, 10.5)],
        fullIs s true] },
  { name := "CAP-hotwater.R5 at hour 12 a tank at 9.0 kWh that was not full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 12 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  { name := "CAP-hotwater.R5 a guard hour of 24 gives no backstop heating at hour 23",
    run := do
      let s := tankStep { defaultTank with guardHour := 24 } (stOpen 9.0) 23 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  { name := "CAP-hotwater.R5 the start state of the default tank is full with the thermostat off and fullToday true",
    run := do
      let st := startState defaultTank
      return firstFail [
        (near st.energyKwh 10.5 1e-9, s!"the tank holds {st.energyKwh} kWh"),
        (st.heating == false, "the thermostat is on"),
        (st.fullToday == true, "fullToday is false")] },

  -- CAP-hotwater.R6
  { name := "CAP-hotwater.R6 a spread of 0 gives the factor 1.0 on each of the days 0 to 364",
    run := do
      let fs := accFactors 7 0.0 365
      let bad := fs.find? (fun f => !near f 1.0 0.000000000001)
      return if fs.length == 365 && bad.isNone then none
        else some s!"{fs.length} factors, a wrong one is {bad}" },
  { name := "CAP-hotwater.R6 seed 7 and a spread of 0.25 give factors above 0 with a mean from 0.98 to 1.02 and a standard deviation from 0.23 to 0.27",
    run := do
      let fs := accFactors 7 0.25 5000
      let m := meanF fs
      let sd := stdF fs
      return firstFail [
        (fs.length == 5000, s!"{fs.length} factors"),
        (fs.all (fun f => f > 0.0), "a factor is not above 0"),
        (m ≥ 0.98 && m ≤ 1.02, s!"mean {m}"),
        (sd ≥ 0.23 && sd ≤ 0.27, s!"standard deviation {sd}")] },
  { name := "CAP-hotwater.R6 seed 7 and a spread of 0.5 give a mean from 0.97 to 1.03 and a standard deviation from 0.48 to 0.58",
    run := do
      let fs := accFactors 7 0.5 5000
      let m := meanF fs
      let sd := stdF fs
      return firstFail [
        (fs.length == 5000, s!"{fs.length} factors"),
        (m ≥ 0.97 && m ≤ 1.03, s!"mean {m}"),
        (sd ≥ 0.48 && sd ≤ 0.58, s!"standard deviation {sd}")] },
  { name := "CAP-hotwater.R6 the factor of the same day is the same two times",
    run := do
      let a := accFactors 7 0.25 365
      let b := accFactors 7 0.25 365
      return if a == b && a.length == 365 && !(a.all (fun f => f == 1.0)) then none
        else some "the two reads differ, or the factors do not vary" },
  { name := "CAP-hotwater.R6 seeds 7 and 8 give a different factor on at least 300 of the days 0 to 364",
    run := do
      let a := accFactors 7 0.25 365
      let b := accFactors 8 0.25 365
      let n := ((a.zip b).filter (fun (x, y) => !(x == y))).length
      return if n ≥ 300 then none else some s!"{n} days differ" }
]

def simulationChecks : List Check := [
  -- CAP-simulation.R6
  { name := "CAP-simulation.R6 an empty battery that may charge takes 2 kWh and then holds 1.9 kWh",
    run := do
      let f := stepHourGated b105 0.0 true true 3.0 1.0
      return valsIs 1e-9 [("direct", f.directKwh, 1.0), ("charge", f.chargeKwh, 2.0),
        ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R6 an empty battery that may not charge exports 2 kWh and still holds 0 kWh",
    run := do
      let f := stepHourGated b105 0.0 false true 3.0 1.0
      return valsIs 1e-9 [("charge", f.chargeKwh, 0.0), ("export", f.exportKwh, 2.0),
        ("soc", f.socKwh, 0.0)] },
  { name := "CAP-simulation.R6 1.9 kWh stored and a battery that may discharge give 1.805 kWh and an import of 0.195 kWh",
    run := do
      let f := stepHourGated b105 1.9 true true 0.0 2.0
      return valsIs 1e-9 [("discharge", f.dischargeKwh, 1.805), ("import", f.importKwh, 0.195)] },
  { name := "CAP-simulation.R6 1.9 kWh stored and a battery that may not discharge give 0 kWh and an import of 2.0 kWh",
    run := do
      let f := stepHourGated b105 1.9 true false 0.0 2.0
      return valsIs 1e-9 [("discharge", f.dischargeKwh, 0.0), ("import", f.importKwh, 2.0),
        ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R6 9.05 kWh stored and a battery that may charge take 1 kWh of a surplus of 2 kWh and then hold 10 kWh",
    run := do
      let f := stepHourGated b105 9.05 true true 3.0 1.0
      return valsIs 1e-9 [("charge", f.chargeKwh, 1.0), ("export", f.exportKwh, 1.0),
        ("soc", f.socKwh, 10.0)] },
  { name := "CAP-simulation.R6 a battery that may not charge and may not discharge exports a surplus of 2 kWh and imports a shortfall of 2 kWh",
    run := do
      let a := stepHourGated b105 5.0 false false 3.0 1.0
      let b := stepHourGated b105 5.0 false false 0.0 2.0
      return valsIs 1e-9 [("export of the surplus", a.exportKwh, 2.0),
        ("import of the shortfall", b.importKwh, 2.0)] },
  { name := "CAP-simulation.R6 a battery that may charge and discharge gives the flows of greedy in the 24 hours of day 100",
    run := do
      return gatedVersus Strategy.greedy 0 6.0 },
  { name := "CAP-simulation.R6 a battery that may charge and may discharge only from 17:00 gives the flows of evening in the 24 hours of day 100",
    run := do
      return gatedVersus Strategy.evening 17 6.0 }
]

def policyChecks : List Check := [
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
      return if a.size == 24 && (List.range 24).all (fun h => a[h]!.heatKwh == 0.0) then none
        else some s!"{a.size} actions, and an hour asks for heating" },
  { name := "CAP-policy.R1 a start of 22 and 2 heating hours ask for 3.0 kWh in hours 22 and 23 and for 0 kWh in hour 21",
    run := do
      let a := staticProfile { defaultStatic with heatStart := 22, heatHours := 2 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 21", a[21]!.heatKwh, 0.0), ("hour 22", a[22]!.heatKwh, 3.0),
        ("hour 23", a[23]!.heatKwh, 3.0)] },
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
  { name := "CAP-policy.R2 4.0 kWh in the tank and an expected draw of 6.0 kWh put 2.0, 3.0, 3.0 and 3.0 kWh in hours 10 to 13",
    run := do
      let a := planDay defaultTank plan9 sunDay 4.0 6.0
      return planAsks a [(10, 2.0), (11, 3.0), (12, 3.0), (13, 3.0)] },
  { name := "CAP-policy.R2 9.0 kWh in the tank and an expected draw of 0.5 kWh ask for 0.5 kWh in hour 13",
    run := do
      let a := planDay defaultTank plan9 sunDay 9.0 0.5
      return planAsks a [(13, 0.5)] },
  { name := "CAP-policy.R2 10.0 kWh in the tank and no expected draw ask for 0 kWh in each hour",
    run := do
      let a := planDay defaultTank plan9 sunDay 10.0 0.0
      return planAsks a [] },
  { name := "CAP-policy.R2 a forecast of 0.4 kWh in each hour asks for 0 kWh in each hour",
    run := do
      let a := planDay defaultTank plan9 (accFcOf [] 0.4) 4.0 6.0
      return planAsks a [] },
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
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 9.0 or 9.5 kWh in the tank ask for 0 kWh",
    run := do
      return firstSome [asksDyn (accObs 12 9.0 5.0 0.0) 0.0, asksDyn (accObs 12 9.5 5.0 0.0) 0.0] },
  { name := "CAP-policy.R3 no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 0.0 0.5) 1.0 },
  { name := "CAP-policy.R3 no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh ask for 0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 0.0 1.0) 0.0 },
  { name := "CAP-policy.R3 no surplus and 5.0 kWh in the tank ask for 0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 0.0 0.0) 0.0 },
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

def homesimChecks : List Check := [
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
          s!"best mean self-consumption {tunePv0.evaluation.meanSelfConsumption}")] }
]

def jobChecks (cache : Cache) : List Check := [
  -- JOB-simulate.R5
  { name := "JOB-simulate.R5 sim with no arguments prints the usage with the new commands and exits with 0",
    run := do
      let r ← sim []
      return if r.code == 0 && (lines r.out).head? == some usageNew then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim help prints the same usage and exits with 0",
    run := do
      let a ← sim []
      let r ← sim ["help"]
      return if r.code == 0 && (lines r.out).head? == some usageNew && r.out == a.out then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim --help prints the same usage and exits with 0",
    run := do
      let a ← sim []
      let r ← sim ["--help"]
      return if r.code == 0 && (lines r.out).head? == some usageNew && r.out == a.out then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },

  -- JOB-simulate.R6
  { name := "JOB-simulate.R6 sim forecast prints the Solcast JSON with 96 periods and a line break",
    run := do
      let r ← sim ["forecast"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (r.out.startsWith (jsonStart ++ "{\"pv_estimate\":"),
          s!"stdout starts with {repr (r.out.take 60).toString}"),
        ((jsonEnds r.out).length == 96, s!"{(jsonEnds r.out).length} periods"),
        (r.out.endsWith "]}\n" && (lines r.out).length == 1, "stdout is not one line")] },
  { name := "JOB-simulate.R6 sim forecast has a first period that ends at 2024-12-31T13:00:00.0000000Z",
    run := do
      let r ← sim ["forecast"]
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
      let t := (runHome homeLat45 pDyn 9 30).totals
      let want := [row "policy" "dynamic", row "days" "30", row "seed" "9"]
      return firstSome [
        (if r.code == 0 then none else some s!"exit code {r.code}, stderr {repr r.err}"),
        (if (lines r.out).take 3 == want then none else some s!"stdout is {repr r.out}"),
        checkShows r.out (policyPairs t),
        (if valueOf r.out "cold-hours" == some (toString t.coldHours) then none
          else some s!"cold-hours shows {valueOf r.out "cold-hours"}, want {t.coldHours}")] },
  -- The line has no --days. The check adds --days 30, so that the run stays short.
  { name := "JOB-simulate.R7 --policy precomputed --target 8 --min-solar 1 shows the totals of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "precomputed", "--target", "8",
        "--min-solar", "1", "--days", "30"]
      let p := Policy.precomputed { defaultPlan with targetKwh := 8.0, minSolarKwh := 1.0 }
      let t := (runHome defaultHome p 1 30).totals
      let want := [row "policy" "precomputed", row "days" "30", row "seed" "1"]
      return firstSome [
        (if r.code == 0 then none else some s!"exit code {r.code}, stderr {repr r.err}"),
        (if (lines r.out).take 3 == want then none else some s!"stdout is {repr r.out}"),
        checkShows r.out (policyPairs t),
        (if valueOf r.out "cold-hours" == some (toString t.coldHours) then none
          else some s!"cold-hours shows {valueOf r.out "cold-hours"}, want {t.coldHours}")] },
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
        match rowWords r.out n with
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
      return match rowWords c.out "static" with
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
          rowWords r.out "perfect-forecast" with
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
        match rowWords r.out n with
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
        match rowWords a.out n, rowWords c.out n with
        | some x, some y => !(y[1]?.isSome && x[1]? == y[1]? && x[2]? == y[1]?)
        | _, _ => true)
      return if a.code != 0 || c.code != 0 then some s!"exit codes {a.code} and {c.code}"
        else match bad with
          | some n => some s!"the {n} row differs: robust {rowWords a.out n}, compare {rowWords c.out n}"
          | none => none },
  { name := "JOB-simulate.R9 the worst self-consumption of each row is not more than its mean",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := rowNames.find? (fun n =>
        match rowWords r.out n with
        | some w => worstAboveMean w
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some n => some s!"the {n} row has a worst self-consumption above its mean: {rowWords r.out n}"
          | none => none },
  { name := "JOB-simulate.R9 each row has an unmet draw of 0.0, 0 cold hours and safe yes",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := rowNames.find? (fun n =>
        match rowWords r.out n with
        | some w => !(w[6]? == some "0.0" && w[7]? == some "0" && w[8]? == some "yes")
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some n => some s!"the {n} row is {rowWords r.out n}"
          | none => none },
  { name := "JOB-simulate.R9 --element 0.2 --days 90 gives the thermostat row safe no and an unmet draw above 0.0",
    run := do
      let r ← sim ["policy", "robust", "--element", "0.2", "--days", "90"]
      let w := (rowWords r.out "thermostat").getD []
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
      let a := rowWords t.out "static"
      let b := rowWords r.out "static"
      return if t.code == 0 && r.code == 0 && a.isSome && a == b then none
        else some s!"tune {a}, robust {b}" },
  { name := "JOB-simulate.R10 the thermostat, precomputed, dynamic and perfect-forecast rows equal the rows of sim policy robust",
    run := do
      let t ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let r ← cachedSim cache ["policy", "robust", "--seeds", "2", "--days", "30"]
      let bad := ["thermostat", "precomputed", "dynamic", "perfect-forecast"].find? (fun n =>
        let a := rowWords t.out n
        !(a.isSome && a == rowWords r.out n))
      return if t.code != 0 || r.code != 0 then some s!"exit codes {t.code} and {r.code}"
        else match bad with
          | some n => some s!"the {n} row differs: tune {rowWords t.out n}, robust {rowWords r.out n}"
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
      pr ["--tank", "abc"], pr ["--tank"], pr ["--tank", "-1"]] }
]

def checks (cache : Cache) : List Check :=
  forecastChecks ++ hotwaterChecks ++ simulationChecks ++ policyChecks ++ homesimChecks ++
    jobChecks cache

def main (args : List String) : IO UInt32 := do
  let cache ← mkCache
  let all := checks cache
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
