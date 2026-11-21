import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
import StoragePolicySim.PhysWeather
import StoragePolicySim.PhysTank
import StoragePolicySim.PhysRun
open StoragePolicySim

/-! Acceptance tests of slice S4 (run the policies on the physics model) of the spec 002-physics-models. -/

def mk (name : String) (act : IO (Option String)) : Harness.Test :=
  { name := name, run := act }

-- The default policies (a missing target or low level uses the tank capacity).

def polStatic : Policy := Policy.static defaultStatic

def polPlan : Policy := Policy.precomputed { defaultPlan with targetKwh := #[] }

def polDyn : Policy := Policy.dynamic { defaultDynamic with lowKwh := #[], targetKwh := #[] }

-- Helpers for the output of the commands

def splitLines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def labelOf (l : String) : String := ((l.take 18).toString).trimAscii.toString

def restOf (l : String) : String := ((l.drop 18).toString).trimAscii.toString

def tokOf (l : String) : String :=
  (((restOf l).splitOn " ").headD "").replace "%" ""

def padLine (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

def words (l : String) : List String :=
  (l.splitOn " ").filter (fun (w : String) => w != "")

def parseF (s : String) : Option Float :=
  let neg := s.startsWith "-"
  let body : String := if neg then (s.drop 1).toString else s
  let sign : Float := if neg then -1.0 else 1.0
  match body.splitOn "." with
  | [i] => (i.toNat?).map (fun (n : Nat) => sign * n.toFloat)
  | [i, f] =>
    match i.toNat?, f.toNat? with
    | some a, some b => some (sign * (a.toFloat + b.toFloat / Float.pow 10.0 f.length.toFloat))
    | _, _ => none
  | _ => none

def lineOf (ls : List String) (label : String) : Option String :=
  ls.find? (fun (l : String) => labelOf l == label)

def valueCheck (ls : List String) (p : String × Float) : Bool × String :=
  match (lineOf ls p.1).bind (fun (l : String) => parseF (tokOf l)) with
  | some g => (Harness.near g p.2 0.0501, s!"{p.1} prints {g}, want {p.2} (one decimal)")
  | none => (false, s!"{p.1}: no number found in the output")

def expected (tot : HomeTotals) (days : Nat) : List (String × Float) :=
  [("solar", tot.pvKwh), ("load", tot.loadKwh), ("import", tot.importKwh),
   ("export", tot.exportKwh), ("curtailed", tot.curtailedKwh), ("heating", tot.heatKwh),
   ("backstop", tot.backstopKwh), ("unmet-hot-water", tot.unmetKwh),
   ("cold-hours", tot.coldHours.toFloat),
   ("starts-per-day", tot.policyStarts.toFloat / days.toFloat),
   ("self-consumption", tot.selfConsumption), ("self-sufficiency", tot.selfSufficiency)]

def runLabels : List String :=
  ["policy", "days", "seed", "solar", "load", "import", "export", "curtailed", "heating",
   "backstop", "unmet-hot-water", "cold-hours", "starts-per-day", "self-consumption",
   "self-sufficiency"]

def errCheck (r : Harness.Out) (want : String) : Option String :=
  Harness.firstFail [
    (r.code == 2, s!"exit code {r.code}, want 2; stderr: {r.err}"),
    (r.out == "", s!"stdout is not empty: {r.out}"),
    (r.err.trimAscii.toString == want, s!"stderr is '{r.err}', want '{want}'"),
    ((r.err.trimAscii.toString.splitOn "\n").length == 1, s!"stderr is not one line: '{r.err}'")]

-- Helpers for runs

def sumTanks (hh : HomeHour) (f : TankHour → Float) : Float :=
  hh.tanks.foldl (fun (a : Float) (x : TankHour) => a + f x) 0.0

def sumHours (r : HomeResult) (f : HomeHour → Float) : Float :=
  r.hours.foldl (fun (a : Float) (hh : HomeHour) => a + f hh) 0.0

def loadOf (hh : HomeHour) : Float :=
  hh.houseLoadKwh + sumTanks hh (fun (x : TankHour) => x.heatKwh + x.backstopKwh)

def balanceMsg (r : HomeResult) : Option String :=
  let t := r.totals
  match r.hours.back? with
  | none => some "the run has no records"
  | some last =>
    let lhs := t.pvKwh + t.importKwh
    let rhs := t.loadKwh + t.exportKwh + t.curtailedKwh + t.batteryLossKwh + last.flow.socKwh
    Harness.firstFail [
      (Harness.near lhs rhs 0.01,
        s!"solar plus import is {lhs}, load plus export plus curtailed plus battery loss plus final battery energy is {rhs}")]

-- The runs of the acceptance lines

def run30 : HomeResult := runPhysics defaultHome polStatic 7 30

def run30Again : HomeResult := runPhysics defaultHome polStatic 7 30

/-- The run that `sim policy run --model physics --days 30` prints (seed 1). -/
def run30Seed1 : HomeResult := runPhysics defaultHome polStatic 1 30

def simple30Seed1 : HomeResult := runHome defaultHome polStatic 1 30

def mineHome : Home := (homeNamed "mine").getD defaultHome

def mine30 (p : Policy) : HomeResult := runPhysics mineHome p 7 30

structure RunSum where
  homeName : String
  polName : String
  seed : Nat
  steps : Nat
  unmetTotal : Float
  unmetStep : Float
  missedHot : Nat
  worstStarts : Nat
  pv : Float
  dailyPv : Array Float
  deriving Inhabited

/-- The small facts of a long run, so that the run itself can be freed. -/
def summarise (home : Home) (hn pn : String) (seed days : Nat) (r : HomeResult) : RunSum := Id.run do
  let nt := home.tanks.size
  let lat := home.site.latitude
  let fulls : Array Float := home.tanks.map (fun (c : TankConfig) => (physTankOf c).litres * kwhPerLitreK)
  let mut hot : Array Bool := (List.replicate (days * nt) false).toArray
  let mut starts : Array Nat := (List.replicate (days * nt) 0).toArray
  let mut prev : Array Bool := (List.replicate nt false).toArray
  let mut daily : Array Float := (List.replicate days 0.0).toArray
  let mut unmetStep : Float := 0.0
  for h in r.hours do
    if h.day < days then
      daily := daily.set! h.day (daily[h.day]! + h.pvKwh)
      let inlet := inletTempC lat h.day
      for t in [0:nt] do
        let x := h.tanks[t]!
        if x.unmetKwh > unmetStep then
          unmetStep := x.unmetKwh
        let full := fulls[t]! * (60.0 - inlet)
        if x.energyKwh >= full - 0.0001 then
          hot := hot.set! (h.day * nt + t) true
        if h.hour % 4 == 0 then
          let req := x.askKwh > 0.000000001
          if h.hour == 0 then
            prev := prev.set! t false
          if req && !(prev[t]!) then
            starts := starts.set! (h.day * nt + t) (starts[h.day * nt + t]! + 1)
          prev := prev.set! t req
  let missed := hot.foldl (fun (a : Nat) (b : Bool) => if b then a else a + 1) 0
  let worst := starts.foldl (fun (a : Nat) (b : Nat) => max a b) 0
  return { homeName := hn, polName := pn, seed := seed, steps := r.hours.size,
           unmetTotal := r.totals.unmetKwh, unmetStep := unmetStep, missedHot := missed,
           worstStarts := worst, pv := r.totals.pvKwh, dailyPv := daily }

/-- Each home, each default policy, the seeds 1 to 3, 365 days: computed once. -/
def bigSummaries : Array RunSum := Id.run do
  let pols : List (String × Policy) :=
    [("static", polStatic), ("precomputed", polPlan), ("dynamic", polDyn)]
  let mut acc : Array RunSum := #[]
  for hn in homeNames do
    match homeNamed hn with
    | none => pure ()
    | some home =>
      for p in pols do
        for seed in [1:4] do
          acc := acc.push (summarise home hn p.1 seed 365 (runPhysics home p.2 seed 365))
  return acc

/-- The home `mine` with the static policy, seed 7, 365 days. -/
def mineSum7 : RunSum :=
  summarise mineHome "mine" "static" 7 365 (runPhysics mineHome polStatic 7 365)

def mineSimplePv : Float := (runHome mineHome polStatic 7 365).totals.pvKwh

-- R11: the run

def tOrder : IO (Option String) := do
  let r := run30
  if r.hours.size != 2880 then
    return some s!"the run has {r.hours.size} records, want 2880"
  for i in [0:r.hours.size] do
    let h := r.hours[i]!
    if h.day != i / 96 || h.hour != i % 96 then
      return some s!"record {i} has day {h.day} step {h.hour}, want day {i / 96} step {i % 96}"
  if r.hours[0]!.tanks.size != defaultHome.tanks.size then
    return some s!"a record has {r.hours[0]!.tanks.size} tanks, want {defaultHome.tanks.size}"
  return none

def tSame : IO (Option String) := do
  let a := reprStr run30
  let b := reprStr run30Again
  return Harness.firstFail [(run30.hours.size == 2880, s!"the run has {run30.hours.size} records, want 2880"),
    (a == b, "two runs with the same arguments differ")]

def tTotals : IO (Option String) := do
  let r := run30
  let t := r.totals
  let e : Float := 0.0001
  let last := r.hours.back?.getD default
  return Harness.firstFail [
    (r.hours.size == 2880, s!"the run has {r.hours.size} records, want 2880"),
    (Harness.near t.pvKwh (sumHours r (fun (hh : HomeHour) => hh.pvKwh)) e, s!"solar total {t.pvKwh}"),
    (Harness.near t.loadKwh (sumHours r loadOf) e, s!"load total {t.loadKwh}, want {sumHours r loadOf}"),
    (Harness.near t.importKwh (sumHours r (fun (hh : HomeHour) => hh.flow.importKwh)) e, s!"import total {t.importKwh}"),
    (Harness.near t.exportKwh (sumHours r (fun (hh : HomeHour) => hh.flow.exportKwh)) e, s!"export total {t.exportKwh}"),
    (Harness.near t.curtailedKwh (sumHours r (fun (hh : HomeHour) => hh.curtailedKwh)) e, s!"curtailed total {t.curtailedKwh}"),
    (Harness.near t.batteryLossKwh (sumHours r (fun (hh : HomeHour) => hh.flow.lossKwh)) e, s!"battery loss total {t.batteryLossKwh}"),
    (Harness.near t.heatKwh (sumHours r (fun (hh : HomeHour) => sumTanks hh (fun (x : TankHour) => x.heatKwh))) e, s!"heating total {t.heatKwh}"),
    (Harness.near t.backstopKwh (sumHours r (fun (hh : HomeHour) => sumTanks hh (fun (x : TankHour) => x.backstopKwh))) e, s!"backstop total {t.backstopKwh}"),
    (Harness.near t.drawKwh (sumHours r (fun (hh : HomeHour) => sumTanks hh (fun (x : TankHour) => x.drawKwh))) e, s!"draw total {t.drawKwh}"),
    (Harness.near t.unmetKwh (sumHours r (fun (hh : HomeHour) => sumTanks hh (fun (x : TankHour) => x.unmetKwh))) e, s!"unmet total {t.unmetKwh}"),
    (t.finalTankKwh.size == 1 && Harness.near t.finalTankKwh[0]! (last.tanks[0]!).energyKwh e,
      s!"final tank energy {reprStr t.finalTankKwh}, want {(last.tanks[0]!).energyKwh}")]

def tBalance : IO (Option String) := do
  let r := run30
  if r.hours.size != 2880 then
    return some s!"the run has {r.hours.size} records, want 2880"
  return balanceMsg r

def tRatios : IO (Option String) := do
  let t := run30.totals
  let sc := 100.0 * (t.pvKwh - t.exportKwh - t.curtailedKwh) / t.pvKwh
  let ss := 100.0 * (t.loadKwh - t.importKwh) / t.loadKwh
  return Harness.firstFail [
    (decide (t.pvKwh > 0.0), "the run has no solar energy"),
    (Harness.near t.selfConsumption sc 0.0001, s!"self-consumption {t.selfConsumption}, want {sc}"),
    (Harness.near t.selfSufficiency ss 0.0001, s!"self-sufficiency {t.selfSufficiency}, want {ss}")]

def tBalanceEachPolicy : IO (Option String) := do
  let pols : List (String × Policy) :=
    [("static", polStatic), ("precomputed", polPlan), ("dynamic", polDyn)]
  for p in pols do
    let r := mine30 p.2
    if r.hours.size != 2880 then
      return some s!"{p.1}: the run has {r.hours.size} records, want 2880"
    match balanceMsg r with
    | some m => return some s!"{p.1}: {m}"
    | none => pure ()
  return none

def tNoUnmet : IO (Option String) := do
  if bigSummaries.size != 45 then
    return some s!"{bigSummaries.size} runs, want 45 (5 homes, 3 policies, 3 seeds)"
  for s in bigSummaries do
    if s.steps != 365 * 96 then
      return some s!"{s.homeName} {s.polName} seed {s.seed}: {s.steps} records, want 35040"
    if s.unmetTotal > 0.000001 || s.unmetStep > 0.000001 then
      return some s!"{s.homeName} {s.polName} seed {s.seed}: unmet use total {s.unmetTotal}, largest step {s.unmetStep}"
  return none

def tAllHot : IO (Option String) := do
  if bigSummaries.size != 45 then
    return some s!"{bigSummaries.size} runs, want 45 (5 homes, 3 policies, 3 seeds)"
  for s in bigSummaries do
    if s.steps != 365 * 96 then
      return some s!"{s.homeName} {s.polName} seed {s.seed}: {s.steps} records, want 35040"
    if s.missedHot != 0 then
      return some s!"{s.homeName} {s.polName} seed {s.seed}: {s.missedHot} tank days with no all-hot step"
  return none

def tMineSolar : IO (Option String) := do
  let p := mineSum7.pv
  let s := mineSimplePv
  return Harness.firstFail [
    (mineSum7.steps == 365 * 96, s!"the physics run has {mineSum7.steps} records, want 35040"),
    (decide (s > 0.0), "the simple run has no solar energy"),
    (decide (Float.abs (p - s) / s < 0.35), s!"physics solar {p} and simple solar {s} differ by more than 35%")]

def maxOver (a : Array Float) (from_ to_ : Nat) : Float := Id.run do
  let mut m : Float := 0.0
  for d in [from_:to_] do
    let v := a[d]!
    if v > m then
      m := v
  return m

def tMineSeason : IO (Option String) := do
  let dec := maxOver mineSum7.dailyPv 334 365
  let jun := maxOver mineSum7.dailyPv 151 181
  return Harness.firstFail [
    (mineSum7.dailyPv.size == 365, s!"{mineSum7.dailyPv.size} days, want 365"),
    (decide (dec > jun), s!"best December day {dec} kWh, best June day {jun} kWh, want December more")]

def tMineStarts : IO (Option String) := do
  let sums := bigSummaries.filter (fun (s : RunSum) => s.homeName == "mine" && s.seed == 1)
  if sums.size != 3 then
    return some s!"{sums.size} runs of the home mine with seed 1, want 3"
  for s in sums do
    if s.steps != 365 * 96 then
      return some s!"mine {s.polName}: {s.steps} records, want 35040"
    if s.worstStarts > 2 then
      return some s!"mine {s.polName}: a tank has {s.worstStarts} policy starts in a day, want at most 2"
  return none

-- R12: the commands

def tPhysRunValues : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--model", "physics", "--days", "30"]
  let ls := splitLines r.out
  let want := expected run30Seed1.totals 30
  let vals := want.map (fun (p : String × Float) => valueCheck ls p)
  return Harness.firstFail ([
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.length == 15, s!"{ls.length} lines, want 15; stderr: {r.err}"),
    (ls.map labelOf == runLabels, s!"labels are {ls.map labelOf}"),
    (ls.headD "" == padLine "policy" "static", s!"line 1 is '{ls.headD ""}'"),
    ((ls.drop 1).headD "" == padLine "days" "30", s!"line 2 is '{(ls.drop 1).headD ""}'"),
    (run30Seed1.hours.size == 2880, s!"runPhysics gives {run30Seed1.hours.size} records, want 2880")] ++ vals)

def tNoModelValues : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--days", "30"]
  let ls := splitLines r.out
  let want := expected simple30Seed1.totals 30
  let vals := want.map (fun (p : String × Float) => valueCheck ls p)
  return Harness.firstFail ([
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.length == 15, s!"{ls.length} lines, want 15; stderr: {r.err}")] ++ vals)

def tSimpleEqualsNone : IO (Option String) := do
  let a ← Harness.sim ["policy", "run", "--days", "30"]
  let b ← Harness.sim ["policy", "run", "--model", "simple", "--days", "30"]
  return Harness.firstFail [
    (a.code == 0, s!"no model: exit code {a.code}; stderr: {a.err}"),
    (b.code == 0, s!"--model simple: exit code {b.code}; stderr: {b.err}"),
    (a.out != "", "the output is empty"),
    (a.out == b.out, s!"outputs differ: '{a.out}' and '{b.out}'")]

def tLastModelCounts : IO (Option String) := do
  let a ← Harness.sim ["policy", "run", "--days", "30"]
  let b ← Harness.sim ["policy", "run", "--model", "physics", "--model", "simple", "--days", "30"]
  return Harness.firstFail [
    (b.code == 0, s!"exit code {b.code}; stderr: {b.err}"),
    (a.out == b.out, s!"outputs differ: '{a.out}' and '{b.out}'")]

def tSimpleCompareEqualsNone : IO (Option String) := do
  let a ← Harness.sim ["policy", "compare", "--days", "30"]
  let b ← Harness.sim ["policy", "compare", "--model", "simple", "--days", "30"]
  return Harness.firstFail [
    (a.code == 0, s!"no model: exit code {a.code}; stderr: {a.err}"),
    (b.code == 0, s!"--model simple: exit code {b.code}; stderr: {b.err}"),
    (a.out != "", "the output is empty"),
    (a.out == b.out, s!"outputs differ: '{a.out}' and '{b.out}'")]

def compareHeader : List String :=
  ["policy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh",
   "curtailed-kWh", "backstop-kWh", "starts-per-day"]

def robustHeader : List String :=
  ["policy", "mean-self-consumption-%", "worst-self-consumption-%", "mean-self-sufficiency-%",
   "mean-export-kWh", "mean-backstop-kWh", "unmet-kWh", "cold-hours", "starts-per-day", "safe"]

def rowNames : List String := ["thermostat", "static", "precomputed", "dynamic", "perfect-forecast"]

def tableCheck (r : Harness.Out) (header : List String) (ls : List String) : List (Bool × String) :=
  [(r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
   (ls.length == 6, s!"{ls.length} lines in the table, want 6 (header and 5 rows); stderr: {r.err}"),
   (words (ls.headD "") == header, s!"header is '{ls.headD ""}'"),
   ((ls.drop 1).map (fun (l : String) => (words l).headD "") == rowNames,
     s!"rows are {(ls.drop 1).map (fun (l : String) => (words l).headD "")}")]

def tPhysCompare : IO (Option String) := do
  let r ← Harness.sim ["policy", "compare", "--model", "physics", "--days", "30"]
  let ls := splitLines r.out
  return Harness.firstFail (tableCheck r compareHeader ls)

def tPhysCompareValue : IO (Option String) := do
  let r ← Harness.sim ["policy", "compare", "--model", "physics", "--days", "30"]
  let ls := splitLines r.out
  let row := (ls.find? (fun (l : String) => (words l).headD "" == "static")).map words
  let got := row.bind (fun (w : List String) => parseF (((w.drop 1).headD "").replace "%" ""))
  match got with
  | none => return some s!"no self-consumption of the row static; stdout: {r.out}; stderr: {r.err}"
  | some g =>
    return Harness.firstFail [
      (Harness.near g run30Seed1.totals.selfConsumption 0.0501,
        s!"static self-consumption {g}, runPhysics gives {run30Seed1.totals.selfConsumption}")]

def tPhysRobust : IO (Option String) := do
  let r ← Harness.sim ["policy", "robust", "--model", "physics", "--days", "30", "--seeds", "2"]
  let ls := splitLines r.out
  return Harness.firstFail (tableCheck r robustHeader ls)

def tPhysTune : IO (Option String) := do
  let r ← Harness.sim ["policy", "tune", "--model", "physics", "--days", "30", "--seeds", "2"]
  let ls := splitLines r.out
  let names := (ls.take 6).map (fun (l : String) => (words l).headD "")
  return Harness.firstFail ([
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.length == 13, s!"{ls.length} lines, want 13 (6 lines, a blank line, a header and 5 rows); stderr: {r.err}"),
    (names == ["goal", "candidates", "safe", "heat-start", "heat-hours", "discharge-from"], s!"first lines are {names}"),
    ((ls.drop 6).headD "x" == "", s!"line 7 is '{(ls.drop 6).headD "x"}', want a blank line")] ++
    tableCheck r robustHeader (ls.drop 7))

def oneDecimal (s : String) : Bool :=
  match s.splitOn "." with
  | [i, f] => i.toNat?.isSome && f.length == 1 && f.all Char.isDigit
  | _ => false

def tPhysPlan : IO (Option String) := do
  let r ← Harness.sim ["policy", "plan", "--model", "physics", "--days", "30"]
  let ls := splitLines r.out
  let nt := defaultHome.tanks.size
  let header : List String :=
    ["hour", "forecast-kWh"] ++ (List.range nt).map (fun (i : Nat) => s!"tank{i + 1}-kWh") ++ ["discharge"]
  let rows := ls.drop 1
  let rowChecks : List (Bool × String) := (List.range rows.length).flatMap (fun (k : Nat) =>
    let l := rows.getD k ""
    let w := words l
    [((w.headD "") == toString k, s!"row {k} is '{l}', want the hour {k} first"),
     (w.length == 3 + nt, s!"row {k} has {w.length} words, want {3 + nt}: '{l}'"),
     ((w.drop 1).dropLast.all oneDecimal, s!"row {k} has a number without one decimal or with a unit: '{l}'"),
     (w.getLast? == some "yes" || w.getLast? == some "no", s!"row {k} does not end with yes or no: '{l}'")])
  return Harness.firstFail ([
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.length == 25, s!"{ls.length} lines, want 25 (a header and 24 rows); stderr: {r.err}"),
    (words (ls.headD "") == header, s!"header is '{ls.headD ""}', want {header}")] ++ rowChecks)

def weakHome : Home :=
  { defaultHome with tanks := defaultHome.tanks.map (fun (t : TankConfig) => { t with elementKw := 0.2 }) }

def polNoHeat : Policy :=
  Policy.static { defaultStatic with windows := #[({ heatStart := 10, heatHours := 0 } : TankWindow)] }

def tColdHoursCount : IO (Option String) := do
  let home := weakHome
  let r := runPhysics home polNoHeat 7 30
  let lat := home.site.latitude
  let nt := home.tanks.size
  let mut count : Nat := 0
  for d in [0:30] do
    let inlet := inletTempC lat d
    for hr in [0:24] do
      for t in [0:nt] do
        let cfg := home.tanks[t]!
        let litres := (physTankOf cfg).litres
        let full := litres * kwhPerLitreK * (60.0 - inlet)
        let floorShare := cfg.floorKwh / cfg.capacityKwh
        let x := (r.hours[d * 96 + 4 * hr + 3]!).tanks[t]!
        if x.energyKwh / full < floorShare then
          count := count + 1
  return Harness.firstFail [
    (r.hours.size == 2880, s!"the run has {r.hours.size} records, want 2880"),
    (count > 0, "no tank-hour is cold in the run: the test needs a weak element"),
    (r.totals.coldHours == count,
      s!"coldHours is {r.totals.coldHours}, want {count} (tank-hours below the floor at the last step of the hour)")]

def usesPhysics (cmd : String) (extra : List String) : IO (Option String) := do
  let a ← Harness.sim (["policy", cmd, "--model", "physics", "--days", "30"] ++ extra)
  let b ← Harness.sim (["policy", cmd, "--days", "30"] ++ extra)
  return Harness.firstFail [
    (a.code == 0, s!"physics: exit code {a.code}; stderr: {a.err}"),
    (b.code == 0, s!"simple: exit code {b.code}; stderr: {b.err}"),
    (a.out != b.out, s!"the output with --model physics equals the simple output")]

def tUnknownModel : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--model", "magic"]
  return errCheck r "error: UNKNOWN_MODEL: magic (simple, physics)"

def tUnknownModelEachCommand : IO (Option String) := do
  for cmd in ["run", "compare", "robust", "tune", "plan"] do
    let r ← Harness.sim ["policy", cmd, "--model", "magic", "--days", "3"]
    match errCheck r "error: UNKNOWN_MODEL: magic (simple, physics)" with
    | some m => return some s!"{cmd}: {m}"
    | none => pure ()
  return none

def tUnknownModelCase : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--model", "Physics"]
  return errCheck r "error: UNKNOWN_MODEL: Physics (simple, physics)"

def tHostileModel : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--model", ";rm -rf /"]
  return errCheck r "error: UNKNOWN_MODEL: ;rm -rf / (simple, physics)"

def tMissingModel : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--model"]
  return errCheck r "error: MISSING_VALUE: --model"

def tHugeDays : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--model", "physics", "--days", "1000000000"]
  return Harness.firstFail [
    (r.code == 2, s!"exit code {r.code}, want 2; stderr: {r.err}"),
    (r.out == "", "stdout is not empty"),
    (r.err.startsWith "error: OUT_OF_RANGE: --days 1000000000 (", s!"stderr is '{r.err}'")]

def tests : List Harness.Test := [
  mk "test_002_S4_R11_static_run_has_2880_records_in_order" tOrder,
  mk "test_002_S4_R11_same_arguments_give_the_same_run" tSame,
  mk "test_002_S4_R11_each_total_equals_the_sum_of_its_steps" tTotals,
  mk "test_002_S4_R11_energy_of_the_home_balances" tBalance,
  mk "test_002_S4_R11_self_consumption_and_sufficiency_follow_spec_001" tRatios,
  mk "test_002_S4_R11_energy_balances_for_each_policy_of_mine" tBalanceEachPolicy,
  mk "test_002_S4_R11_no_tank_has_unmet_use_in_any_home_policy_seed" tNoUnmet,
  mk "test_002_S4_R11_each_tank_is_all_hot_each_day_in_any_home_policy_seed" tAllHot,
  mk "test_002_S4_R11_mine_solar_of_year_within_35_percent_of_simple" tMineSolar,
  mk "test_002_S4_R11_mine_best_december_day_beats_best_june_day" tMineSeason,
  mk "test_002_S4_R11_mine_has_at_most_2_policy_starts_per_tank_per_day" tMineStarts,
  mk "test_002_S4_R12_physics_run_prints_15_lines_with_runphysics_totals" tPhysRunValues,
  mk "test_002_S4_R12_no_model_prints_spec_001_totals" tNoModelValues,
  mk "test_002_S4_R12_model_simple_equals_no_model_for_run" tSimpleEqualsNone,
  mk "test_002_S4_R12_last_model_option_counts" tLastModelCounts,
  mk "test_002_S4_R12_model_simple_equals_no_model_for_compare" tSimpleCompareEqualsNone,
  mk "test_002_S4_R12_physics_compare_prints_its_table" tPhysCompare,
  mk "test_002_S4_R12_physics_compare_static_row_follows_runphysics" tPhysCompareValue,
  mk "test_002_S4_R12_physics_compare_differs_from_simple" (usesPhysics "compare" []),
  mk "test_002_S4_R12_physics_robust_prints_its_table" tPhysRobust,
  mk "test_002_S4_R12_physics_robust_differs_from_simple" (usesPhysics "robust" ["--seeds", "2"]),
  mk "test_002_S4_R12_physics_tune_prints_its_lines_and_table" tPhysTune,
  mk "test_002_S4_R11_cold_hours_count_hours_not_steps" tColdHoursCount,
  mk "test_002_S4_R12_physics_tune_differs_from_simple" (usesPhysics "tune" ["--seeds", "2"]),
  mk "test_002_S4_R12_physics_plan_prints_header_and_24_rows" tPhysPlan,
  mk "test_002_S4_R12_physics_plan_differs_from_simple" (usesPhysics "plan" []),
  mk "test_002_S4_R12_unknown_model_gives_error_and_exit_2" tUnknownModel,
  mk "test_002_S4_R12_unknown_model_is_refused_by_each_command" tUnknownModelEachCommand,
  mk "test_002_S4_R12_model_name_is_case_sensitive" tUnknownModelCase,
  mk "test_002_S4_R12_hostile_model_name_is_echoed_as_typed_and_refused" tHostileModel,
  mk "test_002_S4_R12_model_without_value_is_missing_value" tMissingModel,
  mk "test_002_S4_R12_physics_run_with_huge_days_is_out_of_range" tHugeDays]

def main (args : List String) : IO UInt32 := Harness.run tests args
