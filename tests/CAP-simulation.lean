/-
Component checks of CAP-simulation (hourly energy flows), for CH-0003 (hourly energy flows
and results).

The checks call only `Battery`, `efficiency`, `Flow`, `stepHour`, `HourResult`, `Totals`,
`Month`, `Result` and `simulate`. They also call `Site`, `Hour` and `scenario` of CH-0001
(scenario), and `Strategy`, `Strategy.decide` and `Strategy.placeFlex` of CH-0002
(strategies). No entry of the Interface can fail, so no check expects an error code. The
`seed` argument of `simulate` is the only seam. No check uses the clock.

In the lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of daily load,
3 kWh of it flexible. The battery holds 10 kWh with 5 kW of power, and the seed is 7, unless
the check says otherwise.
-/
import StoragePolicySim.Simulation
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

/-- A percentage. A ratio with nothing to divide by is 0%. -/
def pct (part whole : Float) : Float := if whole == 0 then 0 else 100 * part / whole

-- Helpers for the library

def site (lat : Float) (pv : Float := 5) (flex : Float := 3) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := 20, flexKwh := flex }

def bat (cap power : Float) : Battery := { capacityKwh := cap, powerKw := power }

/-- A run at latitude 45 with seed 7. -/
def run7 (s : Strategy) (b : Battery := bat 10 5) (days : Nat := 365) (pv : Float := 5) :
    Result :=
  simulate (site 45 pv) b s 7 days

def flowFields (f : Flow) : List (String × Float) :=
  [("direct", f.directKwh), ("charge", f.chargeKwh), ("discharge", f.dischargeKwh),
   ("export", f.exportKwh), ("import", f.importKwh), ("loss", f.lossKwh), ("soc", f.socKwh)]

/-- Compares a flow with the expected direct, charge, discharge, export, import, loss and
soc, in this order. -/
def badFlow (f : Flow) (want : List Float) : Option String :=
  if want.length != 7 then some "the check gives the wrong number of values"
  else match ((flowFields f).zip want).find? (fun p => !near p.1.2 p.2 1e-6) with
    | some p => some s!"{p.1.1} is {p.1.2}, want {p.2}, flow {repr f}"
    | none => none

def sameFlow (a b : Flow) : Bool :=
  ((flowFields a).zip (flowFields b)).all (fun p => near p.1.2 p.2.2 1e-9)

/-- The energy of one hour balances, with the stored energy before and after the hour. -/
def balanced (soc0 pv load : Float) (f : Flow) : Bool :=
  near (f.directKwh + f.chargeKwh + f.exportKwh) pv 1e-6 &&
  near (f.directKwh + f.dischargeKwh + f.importKwh) load 1e-6 &&
  near (soc0 + pv + f.importKwh) (load + f.exportKwh + f.lossKwh + f.socKwh) 1e-6

def socBefore (hs : Array HourResult) (i : Nat) : Float :=
  if i == 0 then 0 else hs[i - 1]!.flow.socKwh

/-- Finds the first hour whose flow is not `stepHour` with the energy of the hour before. -/
def badChain (b : Battery) (s : Strategy) (hs : Array HourResult) : Option Nat :=
  (List.range hs.size).find? (fun i =>
    let h := hs[i]!
    !sameFlow (stepHour b (socBefore hs i) s h.hour.hour h.hour.pvKwh h.loadKwh) h.flow)

/-- Finds the first hour whose load is not the base load and the flexible load that
`Strategy.placeFlex` places for its day. -/
def badLoad (s : Strategy) (hs : Array HourResult) : Option Nat :=
  let days := hs.size / 24
  let badDay := (List.range days).find? (fun d =>
    let pv := ((List.range 24).map (fun k => hs[d * 24 + k]!.hour.pvKwh)).toArray
    let fl := ((List.range 24).map (fun k => hs[d * 24 + k]!.hour.flexKwh)).toArray
    let placed := Strategy.placeFlex s pv fl
    (List.range 24).any (fun k =>
      let h := hs[d * 24 + k]!
      !near h.loadKwh (h.hour.baseLoadKwh + placed[k]!) 1e-9))
  badDay.map (fun d => d * 24)

def sameHour (a b : Hour) : Bool :=
  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh

def sumOf (hs : Array HourResult) (f : HourResult → Float) : Float :=
  hs.foldl (fun acc h => acc + f h) 0

def totalsFields (t : Totals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh),
   ("export", t.exportKwh), ("losses", t.lossKwh), ("self-used", t.selfUsedKwh),
   ("final soc", t.finalSocKwh), ("self-consumption", t.selfConsumption),
   ("self-sufficiency", t.selfSufficiency)]

def badTotals (a b : Totals) : Option String :=
  match ((totalsFields a).zip (totalsFields b)).find? (fun p => !near p.1.2 p.2.2 1e-6) with
  | some p => some s!"{p.1.1} is {p.1.2} and {p.2.2}"
  | none => none

/-- Compares each total with the sum of the hours of the run. -/
def badSums (res : Result) : Option String :=
  let hs := res.hours
  let t := res.totals
  firstFail [
    (hs.size == 8760, s!"{hs.size} hours"),
    (near t.pvKwh (sumOf hs (·.hour.pvKwh)) 0.01, s!"solar {t.pvKwh}, hours {sumOf hs (·.hour.pvKwh)}"),
    (near t.loadKwh (sumOf hs (·.loadKwh)) 0.01, s!"load {t.loadKwh}, hours {sumOf hs (·.loadKwh)}"),
    (near t.importKwh (sumOf hs (·.flow.importKwh)) 0.01,
      s!"import {t.importKwh}, hours {sumOf hs (·.flow.importKwh)}"),
    (near t.exportKwh (sumOf hs (·.flow.exportKwh)) 0.01,
      s!"export {t.exportKwh}, hours {sumOf hs (·.flow.exportKwh)}"),
    (near t.lossKwh (sumOf hs (·.flow.lossKwh)) 0.01,
      s!"losses {t.lossKwh}, hours {sumOf hs (·.flow.lossKwh)}"),
    (near t.selfUsedKwh (t.pvKwh - t.exportKwh) 0.01, s!"self-used {t.selfUsedKwh}"),
    (near t.finalSocKwh (socBefore hs hs.size) 1e-9, s!"final soc {t.finalSocKwh}")]

def monthNames : List String :=
  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

def monthDays : List Nat := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

/-- The months of a run of `days` days from 1 January, with the days of the run in each. -/
def wantMonths (days : Nat) : List (String × Nat) := Id.run do
  let mut out : List (String × Nat) := []
  let mut left := days
  for i in List.range (days / 28 + 2) do
    if left > 0 then
      let len := monthDays.getD (i % 12) 0
      let n := if left < len then left else len
      out := out ++ [(monthNames.getD (i % 12) "", n)]
      left := left - n
  return out

def gotMonths (res : Result) : List (String × Nat) :=
  res.months.toList.map (fun m => (m.name, m.days))

def sumDays (hs : Array HourResult) (startDay n : Nat) (f : HourResult → Float) : Float :=
  (List.range (n * 24)).foldl (fun acc k => acc + f hs[startDay * 24 + k]!) 0

/-- Compares the totals and the two ratios of each month with the hours of that month. -/
def badMonths (res : Result) : Option String := Id.run do
  let mut start := 0
  for i in List.range res.months.size do
    let m := res.months[i]!
    let t := m.totals
    let add := sumDays res.hours start m.days
    let pv := add (·.hour.pvKwh)
    let load := add (·.loadKwh)
    let imp := add (·.flow.importKwh)
    let exp := add (·.flow.exportKwh)
    let loss := add (·.flow.lossKwh)
    let r := firstFail [
      (near t.pvKwh pv 0.01, s!"solar {t.pvKwh}, hours {pv}"),
      (near t.loadKwh load 0.01, s!"load {t.loadKwh}, hours {load}"),
      (near t.importKwh imp 0.01, s!"import {t.importKwh}, hours {imp}"),
      (near t.exportKwh exp 0.01, s!"export {t.exportKwh}, hours {exp}"),
      (near t.lossKwh loss 0.01, s!"losses {t.lossKwh}, hours {loss}"),
      (near t.selfConsumption (pct (t.pvKwh - t.exportKwh) t.pvKwh) 1e-6,
        s!"self-consumption {t.selfConsumption}"),
      (near t.selfSufficiency (pct (t.loadKwh - t.importKwh) t.loadKwh) 1e-6,
        s!"self-sufficiency {t.selfSufficiency}")]
    match r with
    | some msg => return some s!"{m.name} (month {i + 1}): {msg}"
    | none => pure ()
    start := start + m.days
  return none

def checks : List Check := [
  -- CAP-simulation.R1
  { name := "CAP-simulation.R1 the efficiency is 0.95",
    run := do
      return if near efficiency 0.95 1e-9 then none else some s!"got {efficiency}" },
  -- A version with no loss gives 2 kWh stored.
  { name := "CAP-simulation.R1 an empty battery with 3 kWh of solar and 1 kWh of load takes 2 kWh and holds 1.9 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 0 Strategy.greedy 12 3 1) [1, 2, 0, 0, 0, 0.1, 1.9] },
  { name := "CAP-simulation.R1 a full battery takes 0 kWh and 2 kWh is export",
    run := do
      return badFlow (stepHour (bat 10 5) 10 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 10] },
  -- A version that limits the charge to the free room with no loss takes 0.95 kWh.
  { name := "CAP-simulation.R1 9.05 kWh stored takes 1 kWh of a 2 kWh surplus and then holds 10 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 9.05 Strategy.greedy 12 3 1) [1, 1, 0, 1, 0, 0.05, 10] },
  -- A version that ignores the loss in the free room takes 1 kWh and holds 9.95 kWh.
  { name := "CAP-simulation.R1 9 kWh stored takes 1/0.95 kWh of a 2 kWh surplus and then holds 10 kWh",
    run := do
      let c := 1 / 0.95
      return badFlow (stepHour (bat 10 5) 9 Strategy.greedy 12 3 1)
        [1, c, 0, 2 - c, 0, 0.05 * c, 10] },
  -- A version that limits the energy stored, not the energy in, takes 2/0.95 kWh.
  { name := "CAP-simulation.R1 a battery with 2 kW of power takes 2 kWh of a 3 kWh surplus and 1 kWh is export",
    run := do
      return badFlow (stepHour (bat 10 2) 0 Strategy.greedy 12 4 1) [1, 2, 0, 1, 0, 0.1, 1.9] },
  -- A version with no loss on the way out gives 1.9 kWh.
  { name := "CAP-simulation.R1 1.9 kWh stored gives 1.805 kWh for a shortfall of 2 kWh and 0.195 kWh is import",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.greedy 20 0 2)
        [0, 0, 1.805, 0, 0.195, 0.095, 0] },
  -- A version that takes the shortfall as the full load asks for 2.5 kWh.
  { name := "CAP-simulation.R1 0.5 kWh of solar and 2.5 kWh of load give 0.5 kWh direct and a shortfall of 2 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.greedy 20 0.5 2.5)
        [0.5, 0, 1.805, 0, 0.195, 0.095, 0] },
  -- A version that takes the given energy from the store with no loss holds 3 kWh.
  { name := "CAP-simulation.R1 5 kWh stored gives 2 kWh for a shortfall of 2 kWh and then holds 5 - 2/0.95 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 5 Strategy.greedy 20 0 2)
        [0, 0, 2, 0, 0, 2 / 0.95 - 2, 5 - 2 / 0.95] },
  { name := "CAP-simulation.R1 none with 1.9 kWh stored exports 2 kWh and still holds 1.9 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.none 12 3 1) [1, 0, 0, 2, 0, 0, 1.9] },
  { name := "CAP-simulation.R1 none with 1.9 kWh stored imports a shortfall of 2 kWh and still holds 1.9 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.none 20 0 2) [0, 0, 0, 0, 2, 0, 1.9] },
  -- The strategy gets the hour. A version that ignores the request of the strategy, or
  -- gives the wrong hour to the strategy, fails one of these two checks.
  { name := "CAP-simulation.R1 evening at 16:00 with 1.9 kWh stored gives 0 kWh and imports 2 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.evening 16 0 2) [0, 0, 0, 0, 2, 0, 1.9] },
  { name := "CAP-simulation.R1 evening at 17:00 with 1.9 kWh stored gives 1.805 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.evening 17 0 2)
        [0, 0, 1.805, 0, 0.195, 0.095, 0] },
  -- A version that starts with a full or a half battery discharges in the first hour.
  { name := "CAP-simulation.R1 the first hour of greedy with seed 7 and 365 days imports its full load",
    run := do
      let res := run7 Strategy.greedy
      if res.hours.size != 8760 then return some s!"{res.hours.size} hours"
      let h := res.hours[0]!
      return firstFail [
        (h.hour.day == 0 && h.hour.hour == 0, s!"the first hour is day {h.hour.day} hour {h.hour.hour}"),
        (h.loadKwh > 0, s!"load {h.loadKwh}"),
        (near h.flow.importKwh h.loadKwh 1e-9, s!"load {h.loadKwh}, import {h.flow.importKwh}"),
        (near h.flow.dischargeKwh 0 1e-9, s!"discharge {h.flow.dischargeKwh}")] },
  { name := "CAP-simulation.R1 the hours of a run are the hours of the scenario",
    run := do
      let res := run7 Strategy.greedy
      let hs := scenario (site 45) 7 365
      return if res.hours.size == 8760 && hs.size == 8760 &&
          (List.range 8760).all (fun i => sameHour res.hours[i]!.hour hs[i]!) then none
        else some s!"{res.hours.size} hours, the scenario has {hs.size}" },
  -- A version that keeps the energy of the battery between hours wrongly, or that gives
  -- the wrong hour, solar or load to the hour, fails here.
  { name := "CAP-simulation.R1 each hour of greedy is the flow of stepHour with the energy of the hour before",
    run := do
      let res := run7 Strategy.greedy
      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
        else match badChain (bat 10 5) Strategy.greedy res.hours with
          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr res.hours[i]!.flow}"
          | none => none },
  { name := "CAP-simulation.R1 each hour of evening is the flow of stepHour with the energy of the hour before",
    run := do
      let res := run7 Strategy.evening
      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
        else match badChain (bat 10 5) Strategy.evening res.hours with
          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr res.hours[i]!.flow}"
          | none => none },
  { name := "CAP-simulation.R1 evening discharges only from 17:00 to 23:00 in a run",
    run := do
      let hs := (run7 Strategy.evening).hours
      let bad := hs.toList.find? (fun h => h.hour.hour < 17 && h.flow.dischargeKwh > 1e-9)
      let used := hs.toList.any (fun h => h.flow.dischargeKwh > 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour} discharges {h.flow.dischargeKwh}"
          | none => if used then none else some "no hour discharges" },
  { name := "CAP-simulation.R1 each hour of greedy has the base load and the default flexible load",
    run := do
      let hs := (run7 Strategy.greedy).hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badLoad Strategy.greedy hs with
          | some i => some s!"day {i / 24} has the wrong load"
          | none => none },
  -- A version that ignores placeFlex keeps the flexible load at 18:00 to 20:00.
  { name := "CAP-simulation.R1 each hour of shift has the base load and the flexible load that placeFlex places",
    run := do
      let hs := (run7 Strategy.shift).hours
      let moved := hs.toList.any (fun h =>
        h.hour.hour == 12 && h.loadKwh > h.hour.baseLoadKwh + 0.5)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badLoad Strategy.shift hs with
          | some i => some s!"day {i / 24} has the wrong load"
          | none => if moved then none else some "no day moves the flexible load to 12:00" },

  -- CAP-simulation.R2
  -- 2 kWh is at the edge of the power, and 2.5 kWh is past the edge.
  { name := "CAP-simulation.R2 a battery with 2 kW of power takes all of a 2 kWh surplus",
    run := do
      return badFlow (stepHour (bat 5 2) 0 Strategy.greedy 12 3 1) [1, 2, 0, 0, 0, 0.1, 1.9] },
  { name := "CAP-simulation.R2 a battery with 2 kW of power takes 2 kWh of a 2.5 kWh surplus",
    run := do
      return badFlow (stepHour (bat 5 2) 0 Strategy.greedy 12 3.5 1) [1, 2, 0, 0.5, 0, 0.1, 1.9] },
  { name := "CAP-simulation.R2 a battery with 2 kW of power gives all of a 2 kWh shortfall",
    run := do
      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 20 0 2)
        [0, 0, 2, 0, 0, 2 / 0.95 - 2, 5 - 2 / 0.95] },
  { name := "CAP-simulation.R2 a battery with 2 kW of power gives 2 kWh of a 2.5 kWh shortfall",
    run := do
      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 20 0 2.5)
        [0, 0, 2, 0, 0.5, 2 / 0.95 - 2, 5 - 2 / 0.95] },
  { name := "CAP-simulation.R2 a full 5 kWh battery takes 0 kWh",
    run := do
      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 5] },
  { name := "CAP-simulation.R2 a 5 kWh battery with 4 kWh stored takes 1/0.95 kWh and holds 5 kWh",
    run := do
      let c := 1 / 0.95
      return badFlow (stepHour (bat 5 2) 4 Strategy.greedy 12 3 1)
        [1, c, 0, 2 - c, 0, 0.05 * c, 5] },
  { name := "CAP-simulation.R2 a 5 kWh battery with 2 kW of power charges and discharges 2 kWh or less each hour",
    run := do
      let hs := (run7 Strategy.greedy (bat 5 2)).hours
      let bad := hs.toList.find? (fun h =>
        h.flow.chargeKwh > 2 + 1e-9 || h.flow.dischargeKwh > 2 + 1e-9 ||
        h.flow.chargeKwh < -1e-9 || h.flow.dischargeKwh < -1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour}: charge {h.flow.chargeKwh}, discharge {h.flow.dischargeKwh}"
          | none => match badChain (bat 5 2) Strategy.greedy hs with
            | some i => some s!"day {i / 24} hour {i % 24} is not the flow of stepHour"
            | none => none },
  { name := "CAP-simulation.R2 a 5 kWh battery with 2 kW of power holds 0 to 5 kWh each hour",
    run := do
      let hs := (run7 Strategy.greedy (bat 5 2)).hours
      let bad := hs.toList.find? (fun h => h.flow.socKwh < -1e-9 || h.flow.socKwh > 5 + 1e-9)
      let full := hs.toList.any (fun h => h.flow.socKwh > 4.9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour} holds {h.flow.socKwh}"
          | none => if full then none else some "no hour holds more than 4.9 kWh" },
  { name := "CAP-simulation.R2 with a 10 kWh battery solar plus import equals load, export, losses and the stored energy",
    run := do
      let t := (run7 Strategy.greedy).totals
      let lhs := t.pvKwh + t.importKwh
      let rhs := t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh
      return firstFail [
        (t.pvKwh > 0 && t.lossKwh > 0, s!"solar {t.pvKwh}, losses {t.lossKwh}"),
        (near lhs rhs 0.01, s!"solar and import {lhs}, load, export, losses and stored {rhs}")] },
  { name := "CAP-simulation.R2 each hour of a greedy run balances with the energy of the hour before",
    run := do
      let hs := (run7 Strategy.greedy).hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range hs.size).find? (fun i =>
            !balanced (socBefore hs i) hs[i]!.hour.pvKwh hs[i]!.loadKwh hs[i]!.flow) with
          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr hs[i]!.flow}"
          | none => none },
  { name := "CAP-simulation.R2 the energy of an evening run and of a shift run balances",
    run := do
      let e := (run7 Strategy.evening).totals
      let s := (run7 Strategy.shift).totals
      let gap := fun (t : Totals) =>
        t.pvKwh + t.importKwh - (t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh)
      return firstFail [
        (near (gap e) 0 0.01, s!"evening is off by {gap e}"),
        (near (gap s) 0 0.01, s!"shift is off by {gap s}")] },
  { name := "CAP-simulation.R2 a battery of 0 kWh takes 0 kWh and gives 0 kWh",
    run := do
      return badFlow (stepHour (bat 0 5) 0 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 0] <|>
        badFlow (stepHour (bat 0 5) 0 Strategy.greedy 20 0 2) [0, 0, 0, 0, 2, 0, 0] },
  { name := "CAP-simulation.R2 with a battery of 0 kWh greedy and none have the same totals",
    run := do
      let a := run7 Strategy.greedy (bat 0 5)
      let b := run7 Strategy.none (bat 0 5)
      return firstFail [
        (a.hours.size == 8760 && b.hours.size == 8760, s!"{a.hours.size} and {b.hours.size} hours"),
        (a.totals.pvKwh > 0, s!"solar {a.totals.pvKwh}")] <|>
        badTotals a.totals b.totals },

  -- CAP-simulation.R3
  { name := "CAP-simulation.R3 at latitude 45 each total of none equals the sum of its hours",
    run := do
      return badSums (run7 Strategy.none) },
  { name := "CAP-simulation.R3 at latitude 45 each total of greedy equals the sum of its hours",
    run := do
      return badSums (run7 Strategy.greedy) },
  -- A version that leaves out the flexible load has 6205 kWh.
  { name := "CAP-simulation.R3 the load total of greedy over 365 days is 7300 kWh",
    run := do
      let t := (run7 Strategy.greedy).totals
      return if near t.loadKwh 7300 0.1 then none else some s!"load {t.loadKwh}" },
  -- The solar total and the load total differ. Thus, a version that divides by the wrong
  -- total fails here.
  { name := "CAP-simulation.R3 at latitude 45 the self-consumption of greedy is 100 × (solar - export) / solar",
    run := do
      let t := (run7 Strategy.greedy).totals
      let want := 100 * (t.pvKwh - t.exportKwh) / t.pvKwh
      return firstFail [
        (t.pvKwh > 0 && !near t.pvKwh t.loadKwh 1, s!"solar {t.pvKwh}, load {t.loadKwh}"),
        (want > 0 && want < 100, s!"the formula gives {want}"),
        (near t.selfConsumption want 1e-6, s!"got {t.selfConsumption}, want {want}")] },
  { name := "CAP-simulation.R3 at latitude 45 the self-sufficiency of greedy is 100 × (load - import) / load",
    run := do
      let t := (run7 Strategy.greedy).totals
      let want := 100 * (t.loadKwh - t.importKwh) / t.loadKwh
      return firstFail [
        (t.loadKwh > 0 && !near t.pvKwh t.loadKwh 1, s!"solar {t.pvKwh}, load {t.loadKwh}"),
        (want > 0 && want < 100, s!"the formula gives {want}"),
        (near t.selfSufficiency want 1e-6, s!"got {t.selfSufficiency}, want {want}")] },
  -- A version that divides by 0 gives NaN, and NaN is not near 0.
  { name := "CAP-simulation.R3 0 kW of panels gives 0% self-consumption and 0% self-sufficiency",
    run := do
      let t := (run7 Strategy.greedy (pv := 0)).totals
      return firstFail [
        (near t.pvKwh 0 1e-9, s!"solar {t.pvKwh}"),
        (near t.selfConsumption 0 1e-9, s!"self-consumption {t.selfConsumption}"),
        (near t.selfSufficiency 0 1e-9, s!"self-sufficiency {t.selfSufficiency}")] },
  { name := "CAP-simulation.R3 0 days give each total 0, each ratio 0% and no months",
    run := do
      let res := run7 Strategy.greedy (days := 0)
      return firstFail [
        (res.hours.size == 0, s!"{res.hours.size} hours"),
        (res.months.size == 0, s!"{res.months.size} months")] <|>
        (match (totalsFields res.totals).find? (fun p => !near p.2 0 1e-12) with
          | some p => some s!"{p.1} is {p.2}"
          | none => none) },

  -- CAP-simulation.R4
  { name := "CAP-simulation.R4 365 days give 12 months with 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31 days",
    run := do
      let ms := (run7 Strategy.greedy).months.toList
      return firstFail [
        (ms.map (·.days) == [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
          s!"days {ms.map (·.days)}"),
        (ms.map (·.name) == monthNames, s!"names {ms.map (·.name)}")] },
  { name := "CAP-simulation.R4 the solar totals of the 12 months add up to the solar total of the run",
    run := do
      let res := run7 Strategy.greedy
      let s := res.months.foldl (fun acc m => acc + m.totals.pvKwh) 0
      return if res.months.size == 12 && res.totals.pvKwh > 0 && near s res.totals.pvKwh 0.01
        then none else some s!"{res.months.size} months, months {s}, run {res.totals.pvKwh}" },
  -- A version that puts the hours in the wrong month keeps the sum and fails here.
  { name := "CAP-simulation.R4 the totals and the ratios of each month of 365 days come from the hours of that month",
    run := do
      let res := run7 Strategy.greedy
      return if res.months.size != 12 then some s!"{res.months.size} months" else badMonths res },
  { name := "CAP-simulation.R4 400 days give 14 months and the last is February with 4 days",
    run := do
      let res := run7 Strategy.greedy (days := 400)
      let got := gotMonths res
      return firstFail [
        (res.months.size == 14, s!"{res.months.size} months: {got}"),
        (got.getLast? == some ("Feb", 4), s!"months {got}"),
        (got == wantMonths 400, s!"months {got}")] <|> badMonths res },
  -- 365 days is at the edge of a year, and 366 days is one past the edge.
  { name := "CAP-simulation.R4 366 days give 13 months and the last is January with 1 day",
    run := do
      let got := gotMonths (run7 Strategy.greedy (days := 366))
      return if got.length == 13 && got.getLast? == some ("Jan", 1) then none
        else some s!"months {got}" },
  { name := "CAP-simulation.R4 10 days give one month, January with 10 days",
    run := do
      let got := gotMonths (run7 Strategy.greedy (days := 10))
      return if got == [("Jan", 10)] then none else some s!"months {got}" },
  -- 31 days is at the edge of January, and 32 days is one past the edge.
  { name := "CAP-simulation.R4 31 days give January with 31 days, and 32 days add February with 1 day",
    run := do
      let a := gotMonths (run7 Strategy.greedy (days := 31))
      let b := gotMonths (run7 Strategy.greedy (days := 32))
      return firstFail [
        (a == [("Jan", 31)], s!"31 days give {a}"),
        (b == [("Jan", 31), ("Feb", 1)], s!"32 days give {b}")] },
  -- With no leap day, 59 days end at February, and 60 days add 1 March.
  { name := "CAP-simulation.R4 59 days end with February and 60 days add March with 1 day",
    run := do
      let a := gotMonths (run7 Strategy.greedy (days := 59))
      let b := gotMonths (run7 Strategy.greedy (days := 60))
      return firstFail [
        (a == [("Jan", 31), ("Feb", 28)], s!"59 days give {a}"),
        (b == [("Jan", 31), ("Feb", 28), ("Mar", 1)], s!"60 days give {b}")] },
  { name := "CAP-simulation.R4 at latitude 45 with seed 7 July has more than twice the solar energy of December",
    run := do
      let ms := (run7 Strategy.greedy).months
      if ms.size != 12 then return some s!"{ms.size} months"
      let jul := ms[6]!.totals.pvKwh
      let dec := ms[11]!.totals.pvKwh
      return if ms[6]!.name == "Jul" && ms[11]!.name == "Dec" && dec > 0 && jul > 2 * dec then none
        else some s!"July {jul}, December {dec}" },
  { name := "CAP-simulation.R4 at latitude 45 with seed 7 the July self-sufficiency is more than the January self-sufficiency",
    run := do
      let ms := (run7 Strategy.greedy).months
      if ms.size != 12 then return some s!"{ms.size} months"
      let jul := ms[6]!.totals.selfSufficiency
      let jan := ms[0]!.totals.selfSufficiency
      return if ms[6]!.name == "Jul" && ms[0]!.name == "Jan" && jul > jan then none
        else some s!"July {jul}, January {jan}" },

  -- CAP-simulation.R5
  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW greedy has a higher self-consumption than none",
    run := do
      let g := (run7 Strategy.greedy).totals.selfConsumption
      let n := (run7 Strategy.none).totals.selfConsumption
      return if n > 0 && g > n then none else some s!"greedy {g}, none {n}" },
  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW evening has a self-consumption no higher than greedy",
    run := do
      let g := (run7 Strategy.greedy).totals.selfConsumption
      let e := (run7 Strategy.evening).totals.selfConsumption
      return if g > 0 && e ≤ g + 1e-9 then none else some s!"evening {e}, greedy {g}" },
  -- The text of R5 says that a battery must raise the self-consumption. A version in which
  -- evening never uses the battery fails here.
  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW evening has a higher self-consumption than none",
    run := do
      let e := (run7 Strategy.evening).totals.selfConsumption
      let n := (run7 Strategy.none).totals.selfConsumption
      return if e > n then none else some s!"evening {e}, none {n}" },
  { name := "CAP-simulation.R5 with a battery of 0 kWh shift has a higher self-consumption than none",
    run := do
      let s := (run7 Strategy.shift (bat 0 5)).totals
      let n := (run7 Strategy.none (bat 0 5)).totals
      return firstFail [
        (near s.loadKwh n.loadKwh 0.01, s!"shift load {s.loadKwh}, none load {n.loadKwh}"),
        (s.selfConsumption > n.selfConsumption,
          s!"shift {s.selfConsumption}, none {n.selfConsumption}")] }
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
