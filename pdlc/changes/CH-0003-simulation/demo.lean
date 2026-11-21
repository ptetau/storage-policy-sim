import StoragePolicySim.Simulation
open StoragePolicySim

-- The demo of CH-0003 (simulation) for the visual review. Each key shows one acceptance line.
-- Run it from the project root: lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-1

def f3 (x : Float) : String :=
  let s := toString ((x * 1000).round / 1000)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 3).toString
  | _ => s

def site (lat : Float := 45) (pv : Float := 5) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := 20, flexKwh := 3 }

def bat (cap power : Float) : Battery := { capacityKwh := cap, powerKw := power }

def showFlow (label : String) (f : Flow) : String :=
  s!"{label}\n→ direct {f3 f.directKwh}, charge {f3 f.chargeKwh}, discharge {f3 f.dischargeKwh}, " ++
    s!"export {f3 f.exportKwh}, import {f3 f.importKwh} kWh; the battery then holds {f3 f.socKwh} kWh"

def showTotals (t : Totals) : String :=
  s!"solar {f3 t.pvKwh}, load {f3 t.loadKwh}, self-used {f3 t.selfUsedKwh}, export {f3 t.exportKwh}, import {f3 t.importKwh}, " ++
    s!"losses {f3 t.lossKwh}, stored at end {f3 t.finalSocKwh} kWh\n" ++
    s!"self-consumption {f3 t.selfConsumption}%, self-sufficiency {f3 t.selfSufficiency}%"

def month (r : Result) (n : String) : Month := (r.months.find? (·.name == n)).getD default

def say (s : String) : IO Unit := IO.println s

def run : String → IO Unit
  | "r1-1" => say (showFlow "10 kWh / 5 kW battery, empty; greedy; 3 kWh solar, 1 kWh load"
      (stepHour (bat 10 5) 0 .greedy 12 3 1))
  | "r1-2" => say (showFlow "10 kWh / 5 kW battery, full; greedy; 3 kWh solar, 1 kWh load"
      (stepHour (bat 10 5) 10 .greedy 12 3 1))
  | "r1-3" => say (showFlow "10 kWh / 5 kW battery, 9.05 kWh stored; greedy; a surplus of 2 kWh"
      (stepHour (bat 10 5) 9.05 .greedy 12 3 1))
  | "r1-4" => say (showFlow "10 kWh / 2 kW battery, empty; greedy; a surplus of 3 kWh"
      (stepHour (bat 10 2) 0 .greedy 12 4 1))
  | "r1-5" => say (showFlow "10 kWh / 5 kW battery, 1.9 kWh stored; greedy; a shortfall of 2 kWh"
      (stepHour (bat 10 5) 1.9 .greedy 19 0 2))
  | "r1-6" => say (showFlow "10 kWh / 5 kW battery, 1.9 kWh stored; none; 3 kWh solar, 1 kWh load"
      (stepHour (bat 10 5) 1.9 .none 12 3 1))
  | "r1-7" => do
    let r := simulate (site) (bat 10 5) .greedy 7 365
    let h := r.hours[0]!
    say s!"greedy, seed 7, 365 days: the first hour\nload {f3 h.loadKwh} kWh, import {f3 h.flow.importKwh} kWh"
  | "r2-1" => do
    let r := simulate (site) (bat 5 2) .greedy 7 365
    let c := r.hours.foldl (fun m h => max m h.flow.chargeKwh) 0
    let d := r.hours.foldl (fun m h => max m h.flow.dischargeKwh) 0
    say s!"5 kWh / 2 kW battery, greedy, 365 days\nlargest charge of an hour: {f3 c} kWh\nlargest discharge of an hour: {f3 d} kWh"
  | "r2-2" => do
    let r := simulate (site) (bat 5 2) .greedy 7 365
    let lo := r.hours.foldl (fun m h => min m h.flow.socKwh) 1000
    let hi := r.hours.foldl (fun m h => max m h.flow.socKwh) (-1000)
    say s!"5 kWh / 2 kW battery, greedy, 365 days\nlowest stored energy: {f3 lo} kWh\nhighest stored energy: {f3 hi} kWh"
  | "r2-3" => do
    let t := (simulate (site) (bat 10 5) .greedy 7 365).totals
    let lhs := t.pvKwh + t.importKwh
    let rhs := t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh
    say s!"10 kWh battery, greedy, 365 days\nsolar + import = {f3 lhs} kWh\nload + export + losses + stored = {f3 rhs} kWh\ndifference: {f3 (lhs - rhs).abs} kWh"
  | "r2-4" => do
    let g := (simulate (site) (bat 0 5) .greedy 7 365).totals
    let n := (simulate (site) (bat 0 5) .none 7 365).totals
    say s!"0 kWh battery, 365 days\ngreedy: {showTotals g}\nnone:   {showTotals n}"
  | "r3-1" => do
    let r := simulate (site) (bat 10 5) .none 7 365
    let sum (f : HourResult → Float) := r.hours.foldl (fun a h => a + f h) 0
    let row (n : String) (tot s : Float) := s!"{n}: total {f3 tot}, sum of hours {f3 s}"
    say ("none, latitude 45, 365 days\n" ++ "\n".intercalate [
      row "solar" r.totals.pvKwh (sum (·.hour.pvKwh)),
      row "load" r.totals.loadKwh (sum (·.loadKwh)),
      row "import" r.totals.importKwh (sum (·.flow.importKwh)),
      row "export" r.totals.exportKwh (sum (·.flow.exportKwh)),
      row "losses" r.totals.lossKwh (sum (·.flow.lossKwh)),
      row "self-used" r.totals.selfUsedKwh (sum (·.hour.pvKwh) - sum (·.flow.exportKwh))])
  | "r3-2" => do
    let t := (simulate (site) (bat 10 5) .greedy 7 365).totals
    say s!"greedy, latitude 45, 365 days\nself-consumption: {f3 t.selfConsumption}%\n100 × (solar - export) / solar = {f3 (100 * (t.pvKwh - t.exportKwh) / t.pvKwh)}%"
  | "r3-3" => do
    let t := (simulate (site) (bat 10 5) .greedy 7 365).totals
    say s!"greedy, latitude 45, 365 days\nself-sufficiency: {f3 t.selfSufficiency}%\n100 × (load - import) / load = {f3 (100 * (t.loadKwh - t.importKwh) / t.loadKwh)}%"
  | "r3-4" => say s!"0 kW of panels, greedy, 365 days\n{showTotals (simulate (site 45 0) (bat 10 5) .greedy 7 365).totals}"
  | "r3-5" => do
    let r := simulate (site) (bat 10 5) .greedy 7 0
    say s!"greedy, 0 days\n{showTotals r.totals}\nmonths: {r.months.size}"
  | "r4-1" => do
    let r := simulate (site) (bat 10 5) .greedy 7 365
    say s!"greedy, 365 days: {r.months.size} months\n{r.months.toList.map (fun m => s!"{m.name} {m.days}")}"
  | "r4-2" => do
    let r := simulate (site) (bat 10 5) .greedy 7 365
    let s := r.months.foldl (fun a m => a + m.totals.pvKwh) 0
    say s!"greedy, 365 days\nsum of the monthly solar totals: {f3 s} kWh\nsolar total of the run: {f3 r.totals.pvKwh} kWh"
  | "r4-3" => do
    let r := simulate (site) (bat 10 5) .greedy 7 400
    say s!"greedy, 400 days: {r.months.size} months\n{r.months.toList.map (fun m => s!"{m.name} {m.days}")}"
  | "r4-4" => do
    let r := simulate (site) (bat 10 5) .greedy 7 10
    say s!"greedy, 10 days: {r.months.size} month\n{r.months.toList.map (fun m => s!"{m.name} {m.days}")}"
  | "r4-5" => do
    let r := simulate (site) (bat 10 5) .greedy 7 365
    let j := (month r "Jul").totals.pvKwh
    let d := (month r "Dec").totals.pvKwh
    say s!"latitude 45, seed 7, greedy, 365 days\nJuly solar: {f3 j} kWh\nDecember solar: {f3 d} kWh\nratio: {f3 (j / d)} (more than 2)"
  | "r4-6" => do
    let r := simulate (site) (bat 10 5) .greedy 7 365
    say s!"latitude 45, seed 7, greedy, 365 days\nJuly self-sufficiency: {f3 (month r "Jul").totals.selfSufficiency}%\nJanuary self-sufficiency: {f3 (month r "Jan").totals.selfSufficiency}%"
  | "r5-1" => do
    let g := (simulate (site) (bat 10 5) .greedy 7 365).totals.selfConsumption
    let n := (simulate (site) (bat 10 5) .none 7 365).totals.selfConsumption
    say s!"10 kWh / 5 kW battery, seed 7, 365 days\nself-consumption: none {f3 n}%, greedy {f3 g}%"
  | "r5-2" => do
    let g := (simulate (site) (bat 10 5) .greedy 7 365).totals.selfConsumption
    let e := (simulate (site) (bat 10 5) .evening 7 365).totals.selfConsumption
    say s!"10 kWh / 5 kW battery, seed 7, 365 days\nself-consumption: evening {f3 e}%, greedy {f3 g}%"
  | "r5-3" => do
    let s := (simulate (site) (bat 0 5) .shift 7 365).totals.selfConsumption
    let n := (simulate (site) (bat 0 5) .none 7 365).totals.selfConsumption
    say s!"0 kWh battery, seed 7, 365 days\nself-consumption: none {f3 n}%, shift {f3 s}%"
  | k => say s!"unknown key {k}"

def main (args : List String) : IO Unit := run (args.headD "")
