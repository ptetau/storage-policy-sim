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

/-- The measured space heating of a day of the year (a heat pump): fitted to the daily load from
April to October, with the peak on day 215 and none from November to April. -/
def heatDay (day : Nat) : Float :=
  12.6 * max 0.0 (Float.cos (2.0 * 3.14159265 * (day.toFloat - 215.0) / 365.0) - 0.1)

/-- The measured share of the heating in each hour: winter less autumn and spring. -/
def heatShape : Array Float :=
  let raw := #[0.32, 0.03, 0.0, 0.10, 0.11, 0.11, 0.34, 0.66, 0.74, 0.19, 0.0, 0.0, 0.02, 0.07,
    0.07, 0.43, 0.59, 0.55, 0.63, 0.42, 0.65, 0.49, 0.44, 0.61]
  let sum := raw.foldl (· + ·) 0.0
  raw.map (· / sum)

/-- The measured home: `solar` scales the arrays, `load` is the daily load without hot water and
heating, `draw` the hot water drawn a day, `share` the share of the first tank. With `sensor`
false, a tank has no thermostat cut-in: its element runs only in its window and in the evening
top-up, as with a Shelly switch. -/
def measured (home : Home) (solar load draw share : Float) (sensor : Bool) : Home :=
  let tank (capacity element : Float) : TankConfig :=
    let t := tankOf capacity element
    if sensor then t else { t with cutInKwh := 0.0 }
  { home with
    site := { home.site with dailyLoadKwh := load },
    arrays := home.arrays.map fun a => { a with kw := a.kw * solar },
    tanks := #[tank 13.1 3.3, tank 9.4 2.8],
    drawShares := #[share, 1.0 - share], drawKwhPerDay := draw,
    heatDayKwh := (Array.range 365).map heatDay, heatShape }

/-- A coordinate search for the timer with the least grid import on the runs `runs`. Unmet hot
water and cold hours cost much more. -/
def tune (runs : List (Policy → HomeTotals)) (start : StaticParams) : StaticParams := Id.run do
  let cost (p : StaticParams) : Float :=
    runs.foldl (fun sum run =>
      let t := run (.static p)
      sum + t.importKwh + 1000.0 * t.unmetKwh + 10.0 * t.coldHours.toFloat) 0.0
  let mut best := start
  let mut bestCost := cost best
  for _ in [0:2] do
    for tank in [0:2] do
      for heatStart in [6:18] do
        for heatHours in [1:10] do
          let c := { best with windows := best.windows.set! tank { heatStart, heatHours } }
          let k := cost c
          if k < bestCost - 0.01 then best := c; bestCost := k
    for dischargeFrom in [0:hoursInDay] do
      let c := { best with dischargeFrom }
      let k := cost c
      if k < bestCost - 0.01 then best := c; bestCost := k
    for flexStart in [6:21] do
      let c := { best with flexStart }
      let k := cost c
      if k < bestCost - 0.01 then best := c; bestCost := k
  return best

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

def descr (p : StaticParams) : String :=
  let w0 := p.windows[0]!; let w1 := p.windows[1]!
  s!"main {w0.heatStart}:00 for {w0.heatHours} h | studio {w1.heatStart}:00 for {w1.heatHours} h | discharge from {p.dischargeFrom}:00 | flexible from {p.flexStart}:00"

def main (args : List String) : IO Unit := do
  let some mine := homeNamed "mine" | IO.println "no home"
  let sensor := args[1]? == some "sensor"
  let home := measured mine 1.1 23.9 13.5 0.81 sensor
  let seeds := [1, 2, 3, 4, 5]
  let mode := args[0]?.getD "monthly"
  if mode == "monthly" then
    monthly home base seeds
  else
    let runners := (physTotalsOf home seeds.toArray 365).toList
    let run (p : Policy) := runners.map fun r => r p
    let off : StaticParams := { windows := #[{ heatStart := 0, heatHours := 0 }], dischargeFrom := 0, flexStart := 18 }
    line "evening top-up only" (run (.static off))
    let now : StaticParams :=
      { windows := #[{ heatStart := 10, heatHours := 5 }, { heatStart := 9, heatHours := 6 }], dischargeFrom := 0, flexStart := 18 }
    line "timer like today" (run (.static now))
    let tuned := tune (physTotalsOf home #[11, 12, 13] 365).toList base
    IO.println s!"tuned: {descr tuned}"
    line "tuned timer" (run (.static tuned))
    line "precomputed" (run (.precomputed { targetKwh := #[], minSolarKwh := 0.5, dischargeFrom := tuned.dischargeFrom }))
    line "dynamic" (run (.dynamic { lowKwh := home.tanks.map (·.capacityKwh / 2), targetKwh := #[], dischargeFrom := tuned.dischargeFrom }))
    line "perfect day knowledge" (seeds.map fun s => (runOracle home tuned s 365).totals)
    monthly home tuned seeds
