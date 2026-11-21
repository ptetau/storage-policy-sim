import StoragePolicySim.PhysRun
open StoragePolicySim

/-! The home `mine` with values measured from the owner's meter data (Tesla and Shelly exports,
April to November 2026), and its policies on the physics model. -/

def f1 (x : Float) : String :=
  let s := toString ((x * 10).round / 10)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 1).toString
  | _ => s

def monthOf (day : Nat) : Nat := Id.run do
  let ends := #[31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
  let d := day % 365
  for i in [0:12] do
    if d < ends[i]! then return i
  return 11

def monthDays : Array Float := #[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

/-- The measured home: `solar` scales the arrays, `load` is the daily load without hot water,
`draw` the hot water drawn a day, `share` the share of the first tank. -/
def measured (home : Home) (solar load draw share : Float) : Home :=
  { home with
    site := { home.site with dailyLoadKwh := load },
    arrays := home.arrays.map fun a => { a with kw := a.kw * solar },
    tanks := #[tankOf 13.1 3.3, tankOf 9.4 2.8],
    drawShares := #[share, 1.0 - share], drawKwhPerDay := draw }

def base : StaticParams :=
  { windows := #[{ heatStart := 12, heatHours := 7 }, { heatStart := 10, heatHours := 7 }],
    dischargeFrom := 15, flexStart := 14 }

/-- The daily means of each month: solar, house load, heat of tank 1, heat of tank 2. -/
def monthly (home : Home) (p : StaticParams) (seeds : List Nat) : IO Unit := do
  let mut sums := Array.replicate 12 #[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  for seed in seeds do
    for h in (runPhysics home (Policy.static p) seed 365).hours do
      let heat (i : Nat) := (h.tanks[i]?.map fun t => t.heatKwh + t.backstopKwh).getD 0.0
      let add := #[h.pvKwh, h.houseLoadKwh, heat 0, heat 1, h.flow.importKwh, h.flow.exportKwh + h.curtailedKwh]
      sums := sums.modify (monthOf h.day) fun row => (row.zip add).map fun (a, b) => a + b
  let n := seeds.length.toFloat
  IO.println "month: solar, house, tank1, tank2, import, export (kWh a day)"
  for m in [0:12] do
    IO.println s!"  {m + 1}: {(sums[m]!.map fun x => f1 (x / n / monthDays[m]!))}"

def line (label : String) (rs : List HomeTotals) : IO Unit := do
  let n := rs.length.toFloat
  let sum (f : HomeTotals → Float) := rs.foldl (fun s r => s + f r) 0.0
  let worst := rs.foldl (fun w r => min w r.selfConsumption) 100.0
  let pv := sum (·.pvKwh)
  let sc := 100.0 * (pv - sum (·.exportKwh) - sum (·.curtailedKwh)) / pv
  let ss := 100.0 * (sum (·.loadKwh) - sum (·.importKwh)) / sum (·.loadKwh)
  IO.println s!"{label}: SC {f1 sc} % (worst {f1 worst}), SS {f1 ss} %, import {f1 (sum (·.importKwh) / n)} kWh/yr, export {f1 ((sum (·.exportKwh) + sum (·.curtailedKwh)) / n)}, backstop {f1 (sum (·.backstopKwh) / n)}, unmet {f1 (sum (·.unmetKwh))}, cold hours {rs.foldl (fun s r => s + r.coldHours) 0}, starts/day {f1 (sum (·.policyStarts.toFloat) / n / 365.0)}"
  (← IO.getStdout).flush

def main (args : List String) : IO Unit := do
  let some mine := homeNamed "mine" | IO.println "no home"
  let num (i : Nat) (d : Float) : Float :=
    match args[i]? with
    | some s => (s.toNat!.toFloat) / 100.0
    | none => d
  let home := measured mine (num 1 1.0) (num 2 28.0) (num 3 15.0) (num 4 0.83)
  let seeds := [1, 2, 3, 4, 5]
  let mode := args[0]?.getD "monthly"
  if mode == "monthly" then
    monthly home base seeds
  else
    let run (p : Policy) := seeds.map fun s => (runPhysics home p s 365).totals
    let none : StaticParams := { windows := #[{ heatStart := 0, heatHours := 0 }], dischargeFrom := 0, flexStart := 18 }
    line "thermostat only" (run (.static none))
    let now : StaticParams :=
      { windows := #[{ heatStart := 10, heatHours := 5 }, { heatStart := 9, heatHours := 6 }], dischargeFrom := 0, flexStart := 18 }
    line "timer like today (10:00 and 09:00)" (run (.static now))
    line "old tuned timer" (run (.static base))
    let tuned := (tunePhysics home .gridImport 11 3 365).best
    IO.println s!"tuned: {repr tuned}"
    line "tuned timer" (run (.static tuned))
    let caps := home.tanks.map (·.capacityKwh)
    line "precomputed" (run (.precomputed { targetKwh := #[], minSolarKwh := 0.5, dischargeFrom := tuned.dischargeFrom }))
    line "dynamic" (run (.dynamic { lowKwh := caps.map (· / 2), targetKwh := #[], dischargeFrom := tuned.dischargeFrom }))
    line "perfect day knowledge" (seeds.map fun s => (runOracle home tuned s 365).totals)
