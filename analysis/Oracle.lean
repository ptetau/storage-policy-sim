import StoragePolicySim.PhysRun
open StoragePolicySim

def f1 (x : Float) : String :=
  let s := toString ((x * 10).round / 10)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 1).toString
  | _ => s

/-- The floor of the grid import of a run, from the daily totals: all the load of a day moves
freely inside the day, and one store without losses (the battery and the full tanks) carries
energy between days. Returns the import and the solar energy that is lost. -/
def ceiling (home : Home) (r : HomeResult) : Float × Float := Id.run do
  let store := home.battery.capacityKwh +
    home.tanks.foldl (fun sum t => sum + (physTankOf t).litres * kwhPerLitreK * 60.0) 0.0
  let days := r.hours.size / 96
  let mut held := 0.0
  let mut imp := 0.0
  let mut lost := 0.0
  for day in [0:days] do
    let mut pv := 0.0
    let mut load := 0.0
    for k in [0:96] do
      let h := r.hours[96 * day + k]!
      pv := pv + h.pvKwh
      load := load + h.houseLoadKwh + h.tanks.foldl (fun s t => s + t.heatKwh + t.backstopKwh) 0.0
    let net := held + pv - load
    if net < 0.0 then
      imp := imp - net
      held := 0.0
    else
      held := min store net
      lost := lost + (net - held)
  return (imp, lost)

def line (label : String) (rs : List HomeResult) : IO Unit := do
  let n := rs.length.toFloat
  let sum (f : HomeTotals → Float) := rs.foldl (fun s r => s + f r.totals) 0.0
  let worst := rs.foldl (fun w r => min w r.totals.selfConsumption) 100.0
  let pv := sum (·.pvKwh)
  let sc := 100.0 * (pv - sum (·.exportKwh) - sum (·.curtailedKwh)) / pv
  let ss := 100.0 * (sum (·.loadKwh) - sum (·.importKwh)) / sum (·.loadKwh)
  IO.println s!"{label}: SC {f1 sc} % (worst {f1 worst}), SS {f1 ss} %, import {f1 (sum (·.importKwh) / n)} kWh/yr, backstop {f1 (sum (·.backstopKwh) / n)}, unmet {f1 (sum (·.unmetKwh))}, cold hours {rs.foldl (fun s r => s + r.totals.coldHours) 0}, starts/day {f1 (sum (·.policyStarts.toFloat) / n / 365.0)}"

def main (args : List String) : IO Unit := do
  let some home := homeNamed "mine" | IO.println "no home"
  let seeds := match args with
    | [a, b] => (List.range b.toNat!).map (· + a.toNat!)
    | _ => [1, 2, 3, 4, 5]
  let base : StaticParams :=
    { windows := #[{ heatStart := 12, heatHours := 7 }, { heatStart := 10, heatHours := 7 }],
      dischargeFrom := 15, flexStart := 14 }
  let timer := seeds.map fun seed => runPhysics home (Policy.static base) seed 365
  line "tuned timer" timer
  let oracle := seeds.map fun seed => runOracle home base seed 365
  line "perfect day knowledge" oracle
  let mut imp := 0.0; let mut lost := 0.0; let mut pv := 0.0; let mut load := 0.0
  for r in oracle do
    let (i, l) := ceiling home r
    imp := imp + i; lost := lost + l; pv := pv + r.totals.pvKwh; load := load + r.totals.loadKwh
  let n := seeds.length.toFloat
  IO.println s!"physical ceiling: SC {f1 (100.0 * (pv - lost) / pv)} %, SS {f1 (100.0 * (load - imp) / load)} %, import {f1 (imp / n)} kWh/yr"
