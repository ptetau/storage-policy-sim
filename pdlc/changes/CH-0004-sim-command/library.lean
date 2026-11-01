import StoragePolicySim.Simulation
open StoragePolicySim

-- Prints the totals of CAP-simulation (hourly energy flows) for the options of the R1 frame:
-- shift, 30 days, latitude 45, and the defaults for the rest.
-- Run it from the project root: lake env lean --run pdlc/changes/CH-0004-sim-command/library.lean

def round1 (x : Float) : String :=
  let r := (x * 10).abs.round / 10
  let s := toString r
  let txt := match s.splitOn "." with
    | [w, f] => w ++ "." ++ (f.take 1).toString
    | _ => s
  if x < 0 && r != 0 then "-" ++ txt else txt

def main : IO Unit := do
  IO.println "library: simulate with shift, seed 1, 30 days, latitude 45, 5 kW of panels, 20 kWh with 3 kWh flexible, 10 kWh / 5 kW battery"
  let site : Site := { latitude := 45, pvKw := 5, dailyLoadKwh := 20, flexKwh := 3 }
  let t := (simulate site { capacityKwh := 10, powerKw := 5 } Strategy.shift 1 30).totals
  IO.println s!"library: solar {round1 t.pvKwh}, load {round1 t.loadKwh}, self-used {round1 t.selfUsedKwh}"
  IO.println s!"library: import {round1 t.importKwh}, export {round1 t.exportKwh}, losses {round1 t.lossKwh}"
  IO.println s!"library: self-consumption {round1 t.selfConsumption} %, self-sufficiency {round1 t.selfSufficiency} %"
