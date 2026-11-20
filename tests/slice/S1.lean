import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
open StoragePolicySim

/-! Acceptance tests of slice S1 (run the static policy) of the spec 001-hot-water-policies. -/

def chkTol : Float := 0.000000001

def chkBat : Battery := { capacityKwh := 10.0, powerKw := 5.0 }

def chkMk (name : String) (act : IO (Option String)) : Harness.Test :=
  { name := name, run := act }

def chkSameFlow (a b : Flow) (e : Float) : Bool :=
  Harness.near a.directKwh b.directKwh e && Harness.near a.chargeKwh b.chargeKwh e &&
  Harness.near a.dischargeKwh b.dischargeKwh e && Harness.near a.exportKwh b.exportKwh e &&
  Harness.near a.importKwh b.importKwh e && Harness.near a.lossKwh b.lossKwh e &&
  Harness.near a.socKwh b.socKwh e

-- Library values

def chkSite45 : Site := { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

/-- The 24 hours of day 100 at latitude 45 with seed 7. -/
def chkDay100 : Array Hour :=
  (scenario chkSite45 7 101).filter (fun (h : Hour) => h.day == 100)

def chkPolicy : Policy := Policy.static defaultStatic

/-- The run of the acceptance lines: the home generic, the static policy, seed 7, 365 days. -/
def chkRun7 : HomeResult := runHome defaultHome chkPolicy 7 365

def chkScen7 : Array Hour := scenario defaultHome.site 7 365

def chkProfile : Array Action := staticProfile #[defaultTank] defaultStatic 3.0

def chkHeatAt (acts : Array Action) (h : Nat) : Float := (acts[h]!).heatKwh[0]!

def chkHome45 : Home := { defaultHome with site := { defaultHome.site with latitude := 45.0 } }

def chkRun9 : HomeResult := runHome chkHome45 chkPolicy 9 30

def chkHomePv0 : Home := { defaultHome with site := { defaultHome.site with pvKw := 0.0 }, arrays := #[({ kw := 0.0, direction := 0.0, tilt := 0.0 } : PanelArray)] }

def chkRunPv0 : HomeResult := runHome chkHomePv0 chkPolicy 7 30

def chkRun0 : HomeResult := runHome defaultHome chkPolicy 7 0

@[noinline] def chkRunAgain (seed days : Nat) : HomeResult := runHome defaultHome chkPolicy seed days

-- Helpers of the hours

def chkSumTanks (hh : HomeHour) (f : TankHour → Float) : Float :=
  hh.tanks.foldl (fun (a : Float) (x : TankHour) => a + f x) 0.0

def chkLoadOf (hh : HomeHour) : Float :=
  hh.houseLoadKwh + chkSumTanks hh (fun (x : TankHour) => x.heatKwh + x.backstopKwh)

def chkSumHours (r : HomeResult) (f : HomeHour → Float) : Float :=
  r.hours.foldl (fun (a : Float) (hh : HomeHour) => a + f hh) 0.0

def chkTankLossSum (r : HomeResult) : Float := Id.run do
  let cfg := defaultTank
  let mut st := startState cfg
  let mut acc : Float := 0.0
  for hh in r.hours do
    let x := hh.tanks[0]!
    let s := tankStep cfg st hh.hour x.askKwh x.drawKwh
    acc := acc + s.lossKwh
    st := s.state
  return acc

def chkColdCount (r : HomeResult) : Nat :=
  r.hours.foldl (fun (a : Nat) (hh : HomeHour) =>
    hh.tanks.foldl (fun (b : Nat) (x : TankHour) =>
      if x.energyKwh < defaultTank.floorKwh then b + 1 else b) a) 0

def chkMinTank (r : HomeResult) : Float :=
  r.hours.foldl (fun (a : Float) (hh : HomeHour) =>
    if hh.tanks[0]!.energyKwh < a then hh.tanks[0]!.energyKwh else a) defaultTank.capacityKwh

-- Helpers of the text

def chkSplitLines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def chkFirstLine (s : String) : String := (s.splitOn "\n").headD ""

def chkLabelOf (l : String) : String := ((l.take 18).toString).trimAscii.toString

def chkRestOf (l : String) : String := ((l.drop 18).toString).trimAscii.toString

def chkTokOf (l : String) : String :=
  (((chkRestOf l).splitOn " ").headD "").replace "%" ""

def chkPad (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

def chkParseF (s : String) : Option Float :=
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

def chkOneDecimal (tok : String) : Bool :=
  match tok.splitOn "." with
  | [_, f] => f.length == 1
  | _ => false

def chkLabels : List String :=
  ["policy", "days", "seed", "solar", "load", "import", "export", "curtailed", "heating",
   "backstop", "unmet-hot-water", "cold-hours", "starts-per-day", "self-consumption",
   "self-sufficiency"]

def chkEnergyLabels : List String :=
  ["solar", "load", "import", "export", "curtailed", "heating", "backstop", "unmet-hot-water"]

def chkRatioLabels : List String := ["self-consumption", "self-sufficiency"]

def chkLineOf (ls : List String) (label : String) : Option String :=
  ls.find? (fun (l : String) => chkLabelOf l == label)

def chkValueCheck (ls : List String) (p : String × Float) : Bool × String :=
  match (chkLineOf ls p.1).bind (fun (l : String) => chkParseF (chkTokOf l)) with
  | some g => (Harness.near g p.2 0.0501, s!"{p.1} prints {g}, want {p.2} (one decimal)")
  | none => (false, s!"{p.1}: no number found in the output")

def chkExpected (tot : HomeTotals) (days : Nat) : List (String × Float) :=
  [("solar", tot.pvKwh), ("load", tot.loadKwh), ("import", tot.importKwh),
   ("export", tot.exportKwh), ("curtailed", tot.curtailedKwh), ("heating", tot.heatKwh),
   ("backstop", tot.backstopKwh), ("unmet-hot-water", tot.unmetKwh),
   ("cold-hours", tot.coldHours.toFloat),
   ("starts-per-day", tot.policyStarts.toFloat / days.toFloat),
   ("self-consumption", tot.selfConsumption), ("self-sufficiency", tot.selfSufficiency)]

def chkUsage (r : Harness.Out) (want : String) : Option String :=
  Harness.firstFail [
    (r.code == 0, s!"exit code {r.code}, want 0; stderr: {r.err}"),
    (chkFirstLine r.out == want, s!"first line is '{chkFirstLine r.out}', want '{want}'; stderr: {r.err}")]

def chkErr (r : Harness.Out) (want : String) : Option String :=
  Harness.firstFail [
    (r.code == 2, s!"exit code {r.code}, want 2; stderr: {r.err}"),
    (r.out == "", s!"stdout is not empty: {r.out}"),
    (r.err.trimAscii.toString == want, s!"stderr is '{r.err}', want '{want}'"),
    ((r.err.trimAscii.toString.splitOn "\n").length == 1, s!"stderr is not one line: '{r.err}'")]

def chkUsageLine : String :=
  "usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]"

def chkPolicyUsageLine : String := "usage: sim policy run|compare|robust|tune|plan [options]"

-- R1: the gated battery step

def tR1NoCharge : IO (Option String) := do
  let f := stepHourGated chkBat 0.0 false true 3.0 1.0
  return Harness.firstFail [
    (Harness.near f.chargeKwh 0.0 chkTol, s!"charge is {f.chargeKwh}, want 0"),
    (Harness.near f.exportKwh 2.0 chkTol, s!"export is {f.exportKwh}, want 2.0"),
    (Harness.near f.socKwh 0.0 chkTol, s!"battery holds {f.socKwh}, want 0")]

def tR1NoDischarge : IO (Option String) := do
  let f := stepHourGated chkBat 1.9 true false 0.0 2.0
  return Harness.firstFail [
    (Harness.near f.dischargeKwh 0.0 chkTol, s!"discharge is {f.dischargeKwh}, want 0"),
    (Harness.near f.importKwh 2.0 chkTol, s!"import is {f.importKwh}, want 2.0"),
    (Harness.near f.socKwh 1.9 chkTol, s!"battery holds {f.socKwh}, want 1.9")]

def tR1Discharge : IO (Option String) := do
  let f := stepHourGated chkBat 1.9 true true 0.0 2.0
  return Harness.firstFail [
    (Harness.near f.dischargeKwh 1.805 chkTol, s!"discharge is {f.dischargeKwh}, want 1.805"),
    (Harness.near f.importKwh 0.195 chkTol, s!"import is {f.importKwh}, want 0.195")]

def chkGatedVsStep (strat : Strategy) (fromHour : Nat) : Option String := Id.run do
  if chkDay100.size != 24 then
    return some s!"the scenario of day 100 has {chkDay100.size} hours, want 24"
  for soc0 in [0.0, 5.0] do
    let mut soc : Float := soc0
    for h in chkDay100 do
      let load := h.baseLoadKwh + h.flexKwh
      let want := stepHour chkBat soc strat h.hour h.pvKwh load
      let got := stepHourGated chkBat soc true (decide (h.hour ≥ fromHour)) h.pvKwh load
      if !(chkSameFlow got want chkTol) then
        return some s!"start {soc0} hour {h.hour} soc {soc}: got {reprStr got}, want {reprStr want}"
      soc := want.socKwh
  return none

def tR1Greedy : IO (Option String) := pure (chkGatedVsStep Strategy.greedy 0)

def tR1Evening : IO (Option String) := pure (chkGatedVsStep Strategy.evening 17)

-- R2: the static profile

def tR2Window : IO (Option String) := do
  let a := chkProfile
  let inWin := [10, 11, 12, 13].map (fun (h : Nat) =>
    (Harness.near (chkHeatAt a h) 3.0 chkTol, s!"hour {h} asks {chkHeatAt a h}, want 3.0"))
  let outWin := ((List.range 24).filter (fun (h : Nat) => h < 10 || h > 13)).map (fun (h : Nat) =>
    (Harness.near (chkHeatAt a h) 0.0 chkTol, s!"hour {h} asks {chkHeatAt a h}, want 0"))
  return Harness.firstFail ([(a.size == 24, s!"the profile has {a.size} actions, want 24")] ++ inWin ++ outWin)

def chkP23 : StaticParams :=
  { defaultStatic with windows := #[({ heatStart := 23, heatHours := 5 } : TankWindow)] }

def tR2EndOfDay : IO (Option String) := do
  let a := staticProfile #[defaultTank] chkP23 3.0
  let others := ((List.range 23)).map (fun (h : Nat) =>
    (Harness.near (chkHeatAt a h) 0.0 chkTol, s!"hour {h} asks {chkHeatAt a h}, want 0"))
  return Harness.firstFail ([
    (a.size == 24, s!"the profile has {a.size} actions, want 24"),
    (Harness.near (chkHeatAt a 23) 3.0 chkTol, s!"hour 23 asks {chkHeatAt a 23}, want 3.0"),
    (Harness.near (chkHeatAt a 0) 0.0 chkTol, s!"hour 0 asks {chkHeatAt a 0}, want 0")] ++ others)

def tR2Gate : IO (Option String) := do
  let a := chkProfile
  let charge := (List.range 24).map (fun (h : Nat) =>
    ((a[h]!).allowCharge == true, s!"hour {h} may not charge"))
  let disch := (List.range 24).map (fun (h : Nat) =>
    ((a[h]!).allowDischarge == decide (h ≥ 17), s!"hour {h} may discharge is {(a[h]!).allowDischarge}"))
  return Harness.firstFail ([(a.size == 24, s!"the profile has {a.size} actions, want 24")] ++ charge ++ disch)

def tR2Never : IO (Option String) := do
  let a := staticProfile #[defaultTank] { defaultStatic with dischargeFrom := 24 } 3.0
  let disch := (List.range 24).map (fun (h : Nat) =>
    ((a[h]!).allowDischarge == false, s!"hour {h} may discharge with discharge from 24"))
  let charge := (List.range 24).map (fun (h : Nat) =>
    ((a[h]!).allowCharge == true, s!"hour {h} may not charge with discharge from 24"))
  return Harness.firstFail ([(a.size == 24, s!"the profile has {a.size} actions, want 24")] ++ disch ++ charge)

-- R6: hourly home flows

def chkOrder (r : HomeResult) (n : Nat) : Option String := Id.run do
  if r.hours.size != n * 24 then
    return some s!"the run has {r.hours.size} hours, want {n * 24}"
  for i in [0:r.hours.size] do
    let hh := r.hours[i]!
    if hh.day != i / 24 || hh.hour != i % 24 then
      return some s!"index {i} holds day {hh.day} hour {hh.hour}"
  return none

def tR6Order : IO (Option String) := pure (chkOrder chkRun7 365)

def chkScenario (r : HomeResult) : Option String := Id.run do
  if r.hours.size != chkScen7.size then
    return some s!"the run has {r.hours.size} hours, the scenario {chkScen7.size}"
  for i in [0:r.hours.size] do
    let hh := r.hours[i]!
    let s := chkScen7[i]!
    if !(Harness.near hh.pvKwh s.pvKwh 0.000001) then
      return some s!"hour {i}: solar {hh.pvKwh}, scenario {s.pvKwh}"
    if !(Harness.near hh.houseLoadKwh (s.baseLoadKwh + hh.flexKwh) 0.000001) then
      return some s!"hour {i}: house load {hh.houseLoadKwh}, scenario base load {s.baseLoadKwh} plus flexible {hh.flexKwh}"
  return none

def tR6Scenario : IO (Option String) := pure (chkScenario chkRun7)

def chkPolicyAsk (r : HomeResult) : Option String := Id.run do
  let a := chkProfile
  for hh in r.hours do
    let act := a[hh.hour]!
    let x := hh.tanks[0]!
    if !(Harness.near x.askKwh (chkHeatAt a hh.hour) chkTol) then
      return some s!"day {hh.day} hour {hh.hour}: request {x.askKwh}, profile {chkHeatAt a hh.hour}"
    if hh.allowCharge != act.allowCharge || hh.allowDischarge != act.allowDischarge then
      return some s!"day {hh.day} hour {hh.hour}: gate {hh.allowCharge}/{hh.allowDischarge}, profile {act.allowCharge}/{act.allowDischarge}"
  return none

def tR6Ask : IO (Option String) := pure (chkPolicyAsk chkRun7)

def chkTankChain (r : HomeResult) : Option String := Id.run do
  let cfg := defaultTank
  let mut st := startState cfg
  for hh in r.hours do
    let x := hh.tanks[0]!
    let s := tankStep cfg st hh.hour x.askKwh x.drawKwh
    if !(Harness.near s.heatKwh x.heatKwh 0.000001 && Harness.near s.backstopKwh x.backstopKwh 0.000001 &&
         Harness.near s.unmetKwh x.unmetKwh 0.000001 && Harness.near s.state.energyKwh x.energyKwh 0.000001) then
      return some s!"day {hh.day} hour {hh.hour}: tank {reprStr x}, tankStep heat {s.heatKwh} backstop {s.backstopKwh} unmet {s.unmetKwh} energy {s.state.energyKwh}"
    st := s.state
  return none

def tR6Tank : IO (Option String) := pure (chkTankChain chkRun7)

def chkFlowChain (r : HomeResult) : Option String := Id.run do
  let mut soc : Float := 0.0
  for hh in r.hours do
    let want := stepHourGated defaultHome.battery soc hh.allowCharge hh.allowDischarge hh.pvKwh (chkLoadOf hh)
    if !(chkSameFlow hh.flow want 0.000001) then
      return some s!"day {hh.day} hour {hh.hour}: flow {reprStr hh.flow}, stepHourGated {reprStr want}"
    soc := hh.flow.socKwh
  return none

def tR6Flow : IO (Option String) := pure (chkFlowChain chkRun7)

def chkDrawCheck (r : HomeResult) : Option String := Id.run do
  if r.hours.size != chkScen7.size then
    return some s!"the run has {r.hours.size} hours, the scenario {chkScen7.size}"
  for i in [0:r.hours.size] do
    let hh := r.hours[i]!
    let s := chkScen7[i]!
    let want := drawKwh 6.0 (-41.3) s.dayOfYear s.hour * drawFactor 7 s.day 0.25
    if !(Harness.near hh.tanks[0]!.drawKwh want chkTol) then
      return some s!"day {s.day} hour {s.hour}: draw {hh.tanks[0]!.drawKwh}, want {want}"
  return none

def tR6Draw : IO (Option String) := pure (chkDrawCheck chkRun7)

def tR6Same : IO (Option String) := do
  let a := reprStr (chkRunAgain 7 30)
  let b := reprStr (chkRunAgain 7 30)
  return Harness.firstFail [(a == b, "two runs with the same arguments differ"),
    (a != "", "the run prints nothing")]

def tR6ZeroDays : IO (Option String) :=
  pure (Harness.firstFail [(chkRun0.hours.size == 0, s!"a run of 0 days has {chkRun0.hours.size} hours")])

-- R8: totals and ratios

def tR8Sums : IO (Option String) := do
  let r := chkRun7
  let t := r.totals
  let e : Float := 0.000001
  let last := r.hours[r.hours.size - 1]!
  return Harness.firstFail [
    (r.hours.size == 8760, s!"the run has {r.hours.size} hours"),
    (Harness.near t.pvKwh (chkSumHours r (fun (hh : HomeHour) => hh.pvKwh)) e, s!"solar total {t.pvKwh}"),
    (Harness.near t.loadKwh (chkSumHours r chkLoadOf) e, s!"load total {t.loadKwh}"),
    (Harness.near t.importKwh (chkSumHours r (fun (hh : HomeHour) => hh.flow.importKwh)) e, s!"import total {t.importKwh}"),
    (Harness.near t.exportKwh (chkSumHours r (fun (hh : HomeHour) => hh.flow.exportKwh)) e, s!"export total {t.exportKwh}"),
    (Harness.near t.curtailedKwh (chkSumHours r (fun (hh : HomeHour) => hh.curtailedKwh)) e, s!"curtailed total {t.curtailedKwh}"),
    (Harness.near t.batteryLossKwh (chkSumHours r (fun (hh : HomeHour) => hh.flow.lossKwh)) e, s!"battery loss total {t.batteryLossKwh}"),
    (Harness.near t.tankLossKwh (chkTankLossSum r) e, s!"tank loss total {t.tankLossKwh}, want {chkTankLossSum r}"),
    (Harness.near t.heatKwh (chkSumHours r (fun (hh : HomeHour) => chkSumTanks hh (fun (x : TankHour) => x.heatKwh))) e, s!"heating total {t.heatKwh}"),
    (Harness.near t.backstopKwh (chkSumHours r (fun (hh : HomeHour) => chkSumTanks hh (fun (x : TankHour) => x.backstopKwh))) e, s!"backstop total {t.backstopKwh}"),
    (Harness.near t.drawKwh (chkSumHours r (fun (hh : HomeHour) => chkSumTanks hh (fun (x : TankHour) => x.drawKwh))) e, s!"draw total {t.drawKwh}"),
    (Harness.near t.unmetKwh (chkSumHours r (fun (hh : HomeHour) => chkSumTanks hh (fun (x : TankHour) => x.unmetKwh))) e, s!"unmet total {t.unmetKwh}"),
    (t.coldHours == chkColdCount r, s!"cold hours {t.coldHours}, want {chkColdCount r}"),
    (t.minTankKwh.size == 1 && Harness.near t.minTankKwh[0]! (chkMinTank r) e, s!"lowest tank energy {reprStr t.minTankKwh}, want {chkMinTank r}"),
    (t.finalTankKwh.size == 1 && Harness.near t.finalTankKwh[0]! last.tanks[0]!.energyKwh e, s!"final tank energy {reprStr t.finalTankKwh}, want {last.tanks[0]!.energyKwh}")]

def tR8Balance : IO (Option String) := do
  let r := chkRun7
  let t := r.totals
  let last := r.hours[r.hours.size - 1]!
  let lhs := t.pvKwh + t.importKwh
  let rhs := t.loadKwh + t.exportKwh + t.curtailedKwh + t.batteryLossKwh + last.flow.socKwh
  return Harness.firstFail [
    (r.hours.size == 8760, s!"the run has {r.hours.size} hours"),
    (Harness.near lhs rhs 0.01, s!"solar plus import is {lhs}, load plus export plus curtailed plus loss plus battery energy is {rhs}")]

def tR8Ratios : IO (Option String) := do
  let t := chkRun7.totals
  let sc := 100.0 * (t.pvKwh - t.exportKwh - t.curtailedKwh) / t.pvKwh
  let ss := 100.0 * (t.loadKwh - t.importKwh) / t.loadKwh
  return Harness.firstFail [
    (decide (t.pvKwh > 0.0), "the run has no solar energy"),
    (Harness.near t.selfConsumption sc chkTol, s!"self-consumption {t.selfConsumption}, want {sc}"),
    (Harness.near t.selfSufficiency ss chkTol, s!"self-sufficiency {t.selfSufficiency}, want {ss}")]

def tR8NoPanels : IO (Option String) := do
  let t := chkRunPv0.totals
  return Harness.firstFail [
    (chkRunPv0.hours.size == 720, s!"the run has {chkRunPv0.hours.size} hours, want 720"),
    (Harness.near t.pvKwh 0.0 chkTol, s!"solar total {t.pvKwh}, want 0"),
    (Harness.near t.selfConsumption 0.0 chkTol, s!"self-consumption {t.selfConsumption}, want 0")]

def tR8ZeroDays : IO (Option String) := do
  let t := chkRun0.totals
  return Harness.firstFail [
    (Harness.near t.pvKwh 0.0 chkTol, s!"solar {t.pvKwh}"),
    (Harness.near t.loadKwh 0.0 chkTol, s!"load {t.loadKwh}"),
    (Harness.near t.importKwh 0.0 chkTol, s!"import {t.importKwh}"),
    (Harness.near t.exportKwh 0.0 chkTol, s!"export {t.exportKwh}"),
    (Harness.near t.curtailedKwh 0.0 chkTol, s!"curtailed {t.curtailedKwh}"),
    (Harness.near t.batteryLossKwh 0.0 chkTol, s!"battery loss {t.batteryLossKwh}"),
    (Harness.near t.tankLossKwh 0.0 chkTol, s!"tank loss {t.tankLossKwh}"),
    (Harness.near t.heatKwh 0.0 chkTol, s!"heating {t.heatKwh}"),
    (Harness.near t.backstopKwh 0.0 chkTol, s!"backstop {t.backstopKwh}"),
    (Harness.near t.drawKwh 0.0 chkTol, s!"draw {t.drawKwh}"),
    (Harness.near t.unmetKwh 0.0 chkTol, s!"unmet {t.unmetKwh}"),
    (Harness.near t.selfConsumption 0.0 chkTol, s!"self-consumption {t.selfConsumption}"),
    (Harness.near t.selfSufficiency 0.0 chkTol, s!"self-sufficiency {t.selfSufficiency}"),
    (t.coldHours == 0, s!"cold hours {t.coldHours}"),
    (t.minTankKwh.size == 1 && Harness.near t.minTankKwh[0]! 10.5 chkTol, s!"lowest tank energy {reprStr t.minTankKwh}, want 10.5"),
    (t.finalTankKwh.size == 1 && Harness.near t.finalTankKwh[0]! 10.5 chkTol, s!"final tank energy {reprStr t.finalTankKwh}, want 10.5")]

-- R12: the usage line

def tR12None : IO (Option String) := do
  let r ← Harness.sim []
  return chkUsage r chkUsageLine

def tR12Help : IO (Option String) := do
  let r ← Harness.sim ["help"]
  return chkUsage r chkUsageLine

def tR12DashHelp : IO (Option String) := do
  let r ← Harness.sim ["--help"]
  return chkUsage r chkUsageLine

def tR12Policy : IO (Option String) := do
  let r ← Harness.sim ["policy"]
  return chkUsage r chkPolicyUsageLine

def tR12PolicyHelp : IO (Option String) := do
  let r ← Harness.sim ["policy", "help"]
  return chkUsage r chkPolicyUsageLine

def tR12Fly : IO (Option String) := do
  let r ← Harness.sim ["policy", "fly"]
  return chkErr r "error: UNKNOWN_COMMAND: policy fly"

-- R14: sim policy run

def tR14Lines : IO (Option String) := do
  let r ← Harness.sim ["policy", "run"]
  let ls := chkSplitLines r.out
  return Harness.firstFail [
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.length == 15, s!"{ls.length} lines, want 15; stderr: {r.err}"),
    (ls.map chkLabelOf == chkLabels, s!"labels are {ls.map chkLabelOf}")]

def tR14FirstThree : IO (Option String) := do
  let r ← Harness.sim ["policy", "run"]
  let ls := chkSplitLines r.out
  return Harness.firstFail [
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.headD "" == chkPad "policy" "static", s!"line 1 is '{ls.headD ""}'; stderr: {r.err}"),
    ((ls.drop 1).headD "" == chkPad "days" "365", s!"line 2 is '{(ls.drop 1).headD ""}'; stderr: {r.err}"),
    ((ls.drop 2).headD "" == chkPad "seed" "1", s!"line 3 is '{(ls.drop 2).headD ""}'; stderr: {r.err}")]

def tR14Column : IO (Option String) := do
  let r ← Harness.sim ["policy", "run"]
  let ls := chkSplitLines r.out
  let checks := ls.map (fun (l : String) =>
    (l.toList[17]? == some ' ' && l.toList[18]? != some ' ' && l.toList[18]?.isSome,
      s!"the value of '{l}' does not start in column 19"))
  return Harness.firstFail ([(ls.length == 15, s!"{ls.length} lines, want 15; stderr: {r.err}")] ++ checks)

def tR14Values : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--days", "30", "--lat", "45", "--seed", "9"]
  let ls := chkSplitLines r.out
  let want := chkExpected chkRun9.totals 30
  let vals := want.map (fun (p : String × Float) => chkValueCheck ls p)
  return Harness.firstFail ([
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (ls.length == 15, s!"{ls.length} lines, want 15; stderr: {r.err}"),
    (ls.headD "" == chkPad "policy" "static", s!"line 1 is '{ls.headD ""}'"),
    ((ls.drop 1).headD "" == chkPad "days" "30", s!"line 2 is '{(ls.drop 1).headD ""}'"),
    ((ls.drop 2).headD "" == chkPad "seed" "9", s!"line 3 is '{(ls.drop 2).headD ""}'")] ++ vals)

def tR14Format : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--days", "30", "--lat", "45", "--seed", "9"]
  let ls := chkSplitLines r.out
  let energy := chkEnergyLabels.map (fun (lab : String) =>
    match chkLineOf ls lab with
    | some l => ((chkRestOf l).endsWith " kWh" && chkOneDecimal (chkTokOf l), s!"'{l}' is not one decimal and kWh")
    | none => (false, s!"no line {lab}"))
  let ratio := chkRatioLabels.map (fun (lab : String) =>
    match chkLineOf ls lab with
    | some l => ((chkRestOf l).endsWith "%" && chkOneDecimal (chkTokOf l), s!"'{l}' is not one decimal and %")
    | none => (false, s!"no line {lab}"))
  return Harness.firstFail ([(r.code == 0, s!"exit code {r.code}; stderr: {r.err}")] ++ energy ++ ratio)

def tR14NoHeat : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--heat-hours", "0"]
  let ls := chkSplitLines r.out
  let back := (chkLineOf ls "backstop").bind (fun (l : String) => chkParseF (chkTokOf l))
  let backPos : Bool := match back with
    | some b => decide (b > 0.0)
    | none => false
  return Harness.firstFail [
    (r.code == 0, s!"exit code {r.code}; stderr: {r.err}"),
    (chkLineOf ls "heating" == some (chkPad "heating" "0.0 kWh"), s!"heating line is {chkLineOf ls "heating"}; stderr: {r.err}"),
    (backPos, s!"backstop value is {back}, want more than 0.0")]

def tR14UnknownPolicy : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--policy", "wild"]
  return chkErr r "error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)"

def tR14Hostile : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--policy", ";rm -rf /"]
  return chkErr r "error: UNKNOWN_POLICY: ;rm -rf / (static, precomputed, dynamic)"

def tR14HugeDays : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--days", "1000000000"]
  return Harness.firstFail [
    (r.code == 2, s!"exit code {r.code}, want 2; stderr: {r.err}"),
    (r.out == "", s!"stdout is not empty"),
    (r.err.startsWith "error: OUT_OF_RANGE: --days 1000000000 (", s!"stderr is '{r.err}'")]

def tR14UnknownOption : IO (Option String) := do
  let r ← Harness.sim ["policy", "run", "--bogus", "1"]
  return chkErr r "error: UNKNOWN_OPTION: --bogus"

def tests : List Harness.Test := [
  chkMk "test_001_S1_R1_no_charge_keeps_surplus_as_export" tR1NoCharge,
  chkMk "test_001_S1_R1_no_discharge_leaves_shortfall_as_import" tR1NoDischarge,
  chkMk "test_001_S1_R1_discharge_gives_1_805_and_import_0_195" tR1Discharge,
  chkMk "test_001_S1_R1_both_allowed_equals_step_hour_greedy" tR1Greedy,
  chkMk "test_001_S1_R1_discharge_from_17_equals_step_hour_evening" tR1Evening,
  chkMk "test_001_S1_R2_default_static_window_hours_10_to_13" tR2Window,
  chkMk "test_001_S1_R2_window_stops_at_end_of_day" tR2EndOfDay,
  chkMk "test_001_S1_R2_battery_gate_discharge_from_17" tR2Gate,
  chkMk "test_001_S1_R2_discharge_from_24_never_discharges" tR2Never,
  chkMk "test_001_S1_R6_run_has_8760_hours_in_order" tR6Order,
  chkMk "test_001_S1_R6_hours_hold_scenario_solar_and_house_load" tR6Scenario,
  chkMk "test_001_S1_R6_hours_hold_policy_request_and_gate" tR6Ask,
  chkMk "test_001_S1_R6_tank_result_equals_tank_step" tR6Tank,
  chkMk "test_001_S1_R6_flow_equals_step_hour_gated" tR6Flow,
  chkMk "test_001_S1_R6_draw_equals_draw_kwh_times_factor" tR6Draw,
  chkMk "test_001_S1_R6_same_arguments_same_run" tR6Same,
  chkMk "test_001_S1_R6_zero_days_no_hours" tR6ZeroDays,
  chkMk "test_001_S1_R8_totals_equal_sums_of_hours" tR8Sums,
  chkMk "test_001_S1_R8_energy_balance_within_0_01" tR8Balance,
  chkMk "test_001_S1_R8_ratios_from_totals" tR8Ratios,
  chkMk "test_001_S1_R8_zero_panels_self_consumption_zero" tR8NoPanels,
  chkMk "test_001_S1_R8_zero_days_totals_zero" tR8ZeroDays,
  chkMk "test_001_S1_R12_no_arguments_prints_usage" tR12None,
  chkMk "test_001_S1_R12_help_prints_usage" tR12Help,
  chkMk "test_001_S1_R12_dash_dash_help_prints_usage" tR12DashHelp,
  chkMk "test_001_S1_R12_policy_prints_policy_usage" tR12Policy,
  chkMk "test_001_S1_R12_policy_help_prints_policy_usage" tR12PolicyHelp,
  chkMk "test_001_S1_R12_policy_unknown_word_refused" tR12Fly,
  chkMk "test_001_S1_R14_prints_15_lines_in_order" tR14Lines,
  chkMk "test_001_S1_R14_first_three_lines" tR14FirstThree,
  chkMk "test_001_S1_R14_value_starts_in_column_19" tR14Column,
  chkMk "test_001_S1_R14_values_equal_run_home_totals" tR14Values,
  chkMk "test_001_S1_R14_values_one_decimal_with_units" tR14Format,
  chkMk "test_001_S1_R14_heat_hours_0_no_heating_backstop_positive" tR14NoHeat,
  chkMk "test_001_S1_R14_unknown_policy_refused" tR14UnknownPolicy,
  chkMk "test_001_S1_R14_hostile_policy_value_refused" tR14Hostile,
  chkMk "test_001_S1_R14_huge_days_refused" tR14HugeDays,
  chkMk "test_001_S1_R14_unknown_option_refused" tR14UnknownOption
]

def main (args : List String) : IO UInt32 := Harness.run tests args
