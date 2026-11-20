import StoragePolicySim.HomeSim
open StoragePolicySim

/-- Month (0 to 11) of a day of the year. -/
def monthOf (day : Nat) : Nat := Id.run do
  let ends := #[31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
  let d := day % 365
  for i in [0:12] do
    if d < ends[i]! then return i
  return 11

structure Score where
  imp : Array Float   -- per month
  lost : Array Float  -- export + curtailed, per month
  pv : Array Float
  unmet : Array Float
  backstop : Array Float
  starts : Nat

def scoreRun (home : Home) (p : StaticParams) (seed : Nat) : Score := Id.run do
  let r := runHome home (Policy.static p) seed 365
  let mut imp := Array.replicate 12 0.0
  let mut lost := Array.replicate 12 0.0
  let mut pv := Array.replicate 12 0.0
  let mut unmet := Array.replicate 12 0.0
  let mut bs := Array.replicate 12 0.0
  for h in r.hours do
    let m := monthOf h.day
    imp := imp.modify m (· + h.flow.importKwh)
    lost := lost.modify m (· + h.flow.exportKwh + h.curtailedKwh)
    pv := pv.modify m (· + h.pvKwh)
    for t in h.tanks do
      unmet := unmet.modify m (· + t.unmetKwh)
      bs := bs.modify m (· + t.backstopKwh)
  return { imp, lost, pv, unmet, backstop := bs, starts := r.totals.policyStarts }

def addScore (a b : Score) : Score :=
  { imp := (a.imp.zip b.imp).map (fun (x, y) => x + y), lost := (a.lost.zip b.lost).map (fun (x, y) => x + y),
    pv := (a.pv.zip b.pv).map (fun (x, y) => x + y), unmet := (a.unmet.zip b.unmet).map (fun (x, y) => x + y),
    backstop := (a.backstop.zip b.backstop).map (fun (x, y) => x + y), starts := a.starts + b.starts }

def scoreSeeds (home : Home) (p : StaticParams) (seeds : List Nat) : Score :=
  match seeds.map (scoreRun home p) with
  | [] => { imp := #[], lost := #[], pv := #[], unmet := #[], backstop := #[], starts := 0 }
  | s :: rest => rest.foldl addScore s

def sumA (a : Array Float) : Float := a.foldl (· + ·) 0.0

/-- Cost of a profile over the months in `ms`: import, with a large penalty for unmet draw. -/
def cost (s : Score) (ms : List Nat) : Float :=
  ms.foldl (fun acc m => acc + s.imp[m]! + 1000.0 * s.unmet[m]!) 0.0

/-- Coordinate search: window of tank 1, of tank 2, discharge hour, flexible-load start. Two passes. -/
def tune (home : Home) (seeds : List Nat) (ms : List Nat) : StaticParams := Id.run do
  let mut best : StaticParams :=
    { windows := #[{ heatStart := 10, heatHours := 4 }, { heatStart := 10, heatHours := 4 }], dischargeFrom := 17, flexStart := 18 }
  let mut bestC := cost (scoreSeeds home best seeds) ms
  for _ in [0:2] do
    for tank in [0:2] do
      for st in [6:17] do
        for hrs in [1:9] do
          let cand := { best with windows := best.windows.set! tank { heatStart := st, heatHours := hrs } }
          let c := cost (scoreSeeds home cand seeds) ms
          if c < bestC - 0.01 then
            best := cand; bestC := c
    for d in [14:23] do
      let cand := { best with dischargeFrom := d }
      let c := cost (scoreSeeds home cand seeds) ms
      if c < bestC - 0.01 then
        best := cand; bestC := c
    for f in [7:21] do
      let cand := { best with flexStart := f }
      let c := cost (scoreSeeds home cand seeds) ms
      if c < bestC - 0.01 then
        best := cand; bestC := c
  return best

def f1 (x : Float) : String :=
  let s := toString ((x * 10).round / 10)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 1).toString
  | _ => s

def descr (p : StaticParams) : String :=
  let w0 := p.windows[0]!; let w1 := p.windows[1]!
  s!"250L {w0.heatStart}:00 for {w0.heatHours}h | 180L {w1.heatStart}:00 for {w1.heatHours}h | discharge from {p.dischargeFrom}:00 | flex from {p.flexStart}:00"

def main : IO Unit := do
  let some home := homeNamed "mine" | IO.println "no home"
  let train := [1, 2, 3]
  let test := [4, 5, 6, 7, 8]
  let n := test.length.toFloat
  let all := List.range 12
  -- year-round
  let yr := tune home train all
  IO.println s!"YEAR-ROUND: {descr yr}"
  let sy := scoreSeeds home yr test
  IO.println s!"  test years: imp {f1 (sumA sy.imp / n)} kWh/yr, export+curtailed {f1 (sumA sy.lost / n)}, backstop {f1 (sumA sy.backstop / n)}, unmet {f1 (sumA sy.unmet)}, starts/day {f1 (sy.starts.toFloat / n / 365.0)}"
  IO.println s!"  self-consumption {f1 (100.0 * (sumA sy.pv - sumA sy.lost) / sumA sy.pv)} %"
  -- monthly
  let names := #["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  let mut impM := 0.0; let mut lostM := 0.0; let mut bsM := 0.0; let mut unM := 0.0
  IO.println "MONTHLY:"
  for m in all do
    let p := tune home train [m]
    let s := scoreSeeds home p test
    impM := impM + s.imp[m]!; lostM := lostM + s.lost[m]!; bsM := bsM + s.backstop[m]!; unM := unM + s.unmet[m]!
    IO.println s!"  {names[m]!}: {descr p}  (imp {f1 (s.imp[m]! / n)} vs year-round {f1 (sy.imp[m]! / n)})"
    (← IO.getStdout).flush
  IO.println s!"  test years: imp {f1 (impM / n)} kWh/yr, export+curtailed {f1 (lostM / n)}, backstop {f1 (bsM / n)}, unmet {f1 unM}"
  IO.println s!"  self-consumption {f1 (100.0 * (sumA sy.pv - lostM) / sumA sy.pv)} %"
