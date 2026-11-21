import StoragePolicySim.Forecast
open StoragePolicySim

-- The demo of CH-0006 (forecast-fast) for the visual review. Each key shows one acceptance line.
-- Run it from the project root: lake env lean --run pdlc/changes/CH-0006-forecast-fast/demo.lean r6-1

def site : Site := { latitude := 45, pvKw := 5, dailyLoadKwh := 20, flexKwh := 3 }
def days : Nat := 365

def f3 (x : Float) : String :=
  let s := toString ((x * 1000).round / 1000)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 3).toString
  | _ => s

def say (s : String) : IO Unit := IO.println s

/-- The hours of seed 7, built once. -/
def hours7 : Array Hour := scenario site 7 days

/-- The hours of seed 8, built once. -/
def hours8 : Array Hour := scenario site 8 days

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def actualKw (p : Period) : Float :=
  hours7[(p.endMinute - 30) / 60]!.pvKwh

/-- A fetch from the built hours of seed 7. -/
def fo (scale : Float) (hour : Nat) : Array Period := forecastOf hours7 site 7 scale hour

def samePeriod (a b : Period) : Bool :=
  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
  a.p90Kw == b.p90Kw

def samePeriods (a b : Array Period) : Bool :=
  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)

/-- The largest difference of a value of a period from its actual power. -/
def worstDiff (ps : Array Period) : Float :=
  ps.foldl (fun m p =>
    max m (max (p.estimateKw - actualKw p).abs
      (max (p.p10Kw - actualKw p).abs (p.p90Kw - actualKw p).abs))) 0

/-- The first period with an actual power above 0, as text. -/
def firstSunny (ps : Array Period) : String :=
  match ps.toList.find? (fun p => actualKw p > 0) with
  | some p => s!"ends {p.endMinute}: {f3 p.estimateKw} kW"
  | none => "none"

-- Helpers of the statistical lines, as in tests/CAP-forecast.lean.

def sumF (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0

def meanF (xs : List Float) : Float :=
  if xs.isEmpty then 0.0 else sumF xs / xs.length.toFloat

/-- The correlation of two lists of the same length. It is 0 when a list has no spread. -/
def corrF (xs ys : List Float) : Float :=
  let mx := meanF xs
  let mv := meanF ys
  let cov := meanF ((xs.zip ys).map (fun (p : Float × Float) => (p.1 - mx) * (p.2 - mv)))
  let vx := meanF (xs.map (fun x => (x - mx) * (x - mx)))
  let vy := meanF (ys.map (fun y => (y - mv) * (y - mv)))
  if vx > 0.0 && vy > 0.0 then cov / Float.sqrt (vx * vy) else 0.0

def periodEnding (ps : Array Period) (e : Nat) : Option Period :=
  ps.toList.find? (fun p => p.endMinute == e)

/-- The relative error of a period: its estimate less its actual power, over the actual power.
The spread is left out, as in tests/CAP-forecast.lean. -/
def relErr (p : Period) : Float := (p.estimateKw - actualKw p) / actualKw p

/-- An estimate is cut at 0 kW or at the panel power of 5 kW. -/
def isCut (p : Period) : Bool := p.estimateKw ≤ 1e-9 || p.estimateKw ≥ 5.0 - 1e-9

/-- A sunny period with an estimate that is not cut. -/
def okSunny (p : Period) : Bool := actualKw p > 0.0 && !isCut p

def inBand (p : Period) : Bool :=
  p.p10Kw - 1e-9 ≤ actualKw p && actualKw p ≤ p.p90Kw + 1e-9

/-- The fetches at 00:00 of the days 0 to 364, each with the hour of its fetch. -/
def dayFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d, fo 1.0 (24 * d)))

/-- The fetches at hour 10 of the days 0 to 364. -/
def tenFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d + 10, fo 1.0 (24 * d + 10)))

/-- The relative errors of the periods that end at 11:30 and at 13:30 of the same day, for each
day that has both, sunny and not cut. The fetch is at 00:00 of the day. -/
def pairsSameDay : List (Float × Float) :=
  dayFetches.filterMap (fun (f, ps) =>
    match periodEnding ps (60 * f + 690), periodEnding ps (60 * f + 810) with
    | some a, some b => if okSunny a && okSunny b then some (relErr a, relErr b) else none
    | _, _ => none)

/-- The relative error of the sunny period that ends at 11:30 of the day of a fetch at 00:00. -/
def err1130 : List (Option Float) :=
  dayFetches.map (fun (f, ps) =>
    match periodEnding ps (60 * f + 690) with
    | some p => if actualKw p > 0.0 then some (relErr p) else none
    | none => none)

/-- The periods that end at 11:30 of a day and of the next day. Each one comes from the fetch
at 00:00 of its own day. -/
def pairsNextDay : List (Float × Float) :=
  (err1130.zip err1130.tail).filterMap (fun (x, y) =>
    match x, y with
    | some u, some v => some (u, v)
    | _, _ => none)

/-- The relative errors of the period that ends at 13:30 of a day, from the fetch at 00:00 and
from the fetch at hour 10. Only a sunny period counts. -/
def signPairs : List (Float × Float) :=
  (dayFetches.zip tenFetches).filterMap (fun (a, b) =>
    match periodEnding a.2 (60 * a.1 + 810), periodEnding b.2 (60 * a.1 + 810) with
    | some p, some q => if actualKw p > 0.0 then some (relErr p, relErr q) else none
    | _, _ => none)

/-- The sunny periods of the fetches at 00:00 of each day. -/
def sunnyAll : List Period :=
  dayFetches.foldl (fun acc (_, ps) => acc ++ ps.toList.filter (fun p => actualKw p > 0.0)) []

def pct (k n : Nat) : String := f3 (100 * k.toFloat / n.toFloat)

def run : String → IO Unit
  | "r6-1" => do
    say s!"seed 7, 365 days, latitude 45, 5 kW, error scale 1: {hours7.size} hours built once"
    for h in [0, 4116, 8750] do
      let a := fo 1.0 h
      let b := forecast site 7 days 1.0 h
      say s!"fetch {h}: forecastOf {a.size} periods, forecast {b.size} periods, same: {samePeriods a b}"
      say s!"  first period with sun: forecastOf {firstSunny a}, forecast {firstSunny b}"
  | "r6-2" => do
    let ps := fo 0.0 4000
    say s!"error scale 0, fetch at hour 4000, forecastOf: {ps.size} periods"
    say s!"largest difference from the actual power: {worstDiff ps} kW (0.000001 or less)"
    match ps.toList.find? (fun p => actualKw p > 0) with
    | some p => say s!"first period with sun ends {p.endMinute}: estimate {f3 p.estimateKw} kW, actual {f3 (actualKw p)} kW"
    | none => say "no period with sun"
  | "r6-3" => do
    say s!"hours of the run: {hours7.size}"
    say s!"forecastOf, fetch at hour 8760: {(fo 1.0 8760).size} periods"
  | "r6-4" => do
    let ps := forecastOf (#[] : Array Hour) site 7 1.0 0
    say s!"forecastOf with no hours, fetch at hour 0: {ps.size} periods"
  | "r6-5" => do
    let a := forecastOf hours7 site 7 1.0 4000
    let b := forecastOf hours8 site 8 1.0 4000
    let n := (List.range a.size).filter (fun i => a[i]!.estimateKw != b[i]!.estimateKw) |>.length
    say s!"forecastOf, fetch at hour 4000, the hours of seed 7 and of seed 8"
    say s!"periods: {a.size} and {b.size}"
    say s!"periods with a different estimate: {n} of {a.size} (at least 1)"
    match (List.range a.size).find? (fun i => a[i]!.estimateKw != b[i]!.estimateKw) with
    | some i => say s!"first difference, period ending {a[i]!.endMinute}: seed 7 {f3 a[i]!.estimateKw} kW, seed 8 {f3 b[i]!.estimateKw} kW"
    | none => say "no difference"
  | "r7-1" => do
    let n := pairsSameDay.length
    let c := corrF (pairsSameDay.map (·.1)) (pairsSameDay.map (·.2))
    say s!"365 fetches at 00:00, seed 7, error scale 1, forecastOf"
    say s!"sunny periods that end at 11:30 and at 13:30 of the same day"
    say s!"days with both (estimates not cut): {n} of 365"
    say s!"correlation of the relative errors: {f3 c} (0.55 to 0.85)"
  | "r7-2" => do
    let n := pairsNextDay.length
    let c := corrF (pairsNextDay.map (·.1)) (pairsNextDay.map (·.2))
    say s!"365 fetches at 00:00, seed 7, error scale 1, forecastOf"
    say s!"sunny period that ends at 11:30 of a day and of the next day, each from its own fetch"
    say s!"pairs of days with both: {n} of 364"
    say s!"correlation of the relative errors: {f3 c} (-0.25 to 0.25)"
  | "r7-3" => do
    let usable := signPairs.filter (fun (x, y) => x.abs > 1e-12 && y.abs > 1e-12)
    let same := usable.filter (fun (x, y) => x * y > 0.0)
    say s!"fetches at hour 0 and at hour 10 of days 0 to 364, seed 7, error scale 1"
    say s!"sunny period that ends at 13:30, days with an error other than 0 in both: {usable.length}"
    say s!"days with the same sign in both fetches: {same.length}"
    say s!"share: {pct same.length usable.length}% (at least 62%)"
  | "r7-4" => do
    let ps := fo 0.0 0
    say s!"error scale 0, fetch at hour 0, forecastOf: {ps.size} periods"
    say s!"largest difference from the actual power: {worstDiff ps} kW (0.000001 or less)"
    say s!"sum of the estimates: {f3 (sumF (ps.toList.map (·.estimateKw)))} kW"
  | "r7-5" => do
    let n := sunnyAll.length
    let k := (sunnyAll.filter inBand).length
    say s!"365 fetches at 00:00, seed 7, error scale 1, forecastOf"
    say s!"sunny periods: {n}"
    say s!"actual power inside the band: {k}"
    say s!"share: {pct k n}% (60% to 95%)"
  | k => say s!"unknown key {k}"

def main (args : List String) : IO Unit := run (args.headD "")
