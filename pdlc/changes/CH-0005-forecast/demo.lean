import StoragePolicySim.Forecast
open StoragePolicySim

-- The demo of CH-0005 (forecast) for the visual review. Each key shows one acceptance line.
-- Run it from the project root: lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-1

def site : Site := { latitude := 45, pvKw := 5, dailyLoadKwh := 20, flexKwh := 3 }
def days : Nat := 365

def f3 (x : Float) : String :=
  let s := toString ((x * 1000).round / 1000)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 3).toString
  | _ => s

def hoursOfScenario : Array Hour := scenario site 7 days

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def actualKw (p : Period) : Float :=
  hoursOfScenario[(p.endMinute - 30) / 60]!.pvKwh

def fetch (seed : Nat) (scale : Float) (hour : Nat) : Array Period := forecast site seed days scale hour

def say (s : String) : IO Unit := IO.println s

/-- Every fourth day, at 00:00: the daily fetches that the statistical lines use. -/
def dailyFetches : List (Array Period) :=
  (List.range 92).map fun i => fetch 7 1.0 (i * 4 * 24)

/-- The same days, at 10:00: the fetches whose first four hours are in the middle of the day. -/
def middayFetches : List (Array Period) :=
  (List.range 92).map fun i => fetch 7 1.0 (i * 4 * 24 + 10)

def firstLast (ps : Array Period) : String :=
  match ps[0]?, ps[ps.size - 1]? with
  | some a, some b => s!"first ends at {a.endMinute}, last ends at {b.endMinute}"
  | _, _ => "no period"

def jsonField (s : String) (key : String) (n : Nat := 0) : String :=
  let parts := s.splitOn key
  match parts[n + 1]? with
  | some rest => (rest.takeWhile (· != '"')).toString
  | none => "?"

def run : String → IO Unit
  | "r1-1" => do
    let ps := fetch 7 1.0 0
    say s!"fetch at hour 0: {ps.size} periods, {firstLast ps}"
    say s!"ends 30, 60, 90 ...: {(ps.toList.take 3).map (·.endMinute)}"
  | "r1-2" => do
    let ps := fetch 7 1.0 100
    say s!"fetch at hour 100: {ps.size} periods, {firstLast ps}"
  | "r1-3" => do
    let ps := fetch 7 1.0 8750
    say s!"fetch at hour 8750: {ps.size} periods ({firstLast ps})"
  | "r1-4" => say s!"fetch at hour 8760: {(fetch 7 1.0 8760).size} periods"
  | "r1-5" => do
    let bad := dailyFetches.foldl (fun n ps => n + (ps.filter fun p => p.p10Kw > p.estimateKw + 1e-9 || p.estimateKw > p.p90Kw + 1e-9).size) 0
    let total := dailyFetches.foldl (fun n ps => n + ps.size) 0
    say s!"92 daily fetches at 00:00, {total} periods\nperiods with a 10% band above the estimate, or an estimate above the 90% band: {bad}"
  | "r1-6" => do
    let lo := dailyFetches.foldl (fun m ps => ps.foldl (fun m p => min m (min p.p10Kw (min p.estimateKw p.p90Kw))) m) 1000.0
    let hi := dailyFetches.foldl (fun m ps => ps.foldl (fun m p => max m (max p.p10Kw (max p.estimateKw p.p90Kw))) m) (-1000.0)
    say s!"92 daily fetches at 00:00\nlowest value: {f3 lo} kW\nhighest value: {f3 hi} kW (5 kW or less)"
  | "r1-7" => do
    let ps := fetch 7 1.0 0
    let night := ps.filter fun p => actualKw p == 0
    let nonzero := night.filter fun p => p.estimateKw != 0 || p.p10Kw != 0 || p.p90Kw != 0
    say s!"fetch at hour 0: {night.size} periods with no actual power\nof these, periods with a value above 0 kW: {nonzero.size}"
  | "r2-1" => do
    let ps := fetch 7 0.0 0
    let worst := ps.foldl (fun m p => max m (max (p.estimateKw - actualKw p).abs (max (p.p10Kw - actualKw p).abs (p.p90Kw - actualKw p).abs))) 0
    say s!"error scale 0, fetch at hour 0: {ps.size} periods\nlargest difference from the actual power: {worst} kW (0.000001 or less)"
  | "r2-2" => do
    let a := fetch 7 1.0 4000
    let b := fetch 7 1.0 4000
    let same := a.size == b.size && (List.range a.size).all fun i => a[i]!.estimateKw == b[i]!.estimateKw && a[i]!.p10Kw == b[i]!.p10Kw && a[i]!.p90Kw == b[i]!.p90Kw
    say s!"seed 7, the same fetch two times\nperiods: {a.size} and {b.size}\nthe two forecasts are the same: {same}"
  | "r2-3" => do
    let a := fetch 7 1.0 4000
    let b := fetch 8 1.0 4000
    let n := (List.range a.size).filter (fun i => a[i]!.estimateKw != b[i]!.estimateKw) |>.length
    say s!"fetch at hour 4000 with seeds 7 and 8\nperiods with a different estimate: {n} of {a.size}"
  | "r2-4" => do
    -- Sunny periods ending 10:30 to 14:00, so that both groups cover the same hours of the day.
    let mut sumNear := 0.0; let mut nNear := 0; let mut sumFar := 0.0; let mut nFar := 0
    let mut actNear := 0.0; let mut actFar := 0.0
    for ps in middayFetches ++ dailyFetches do
      for p in ps.toList do
        let minuteOfDay := p.endMinute % 1440
        if actualKw p > 0 && minuteOfDay ≥ 630 && minuteOfDay ≤ 840 then
          let lead := p.endMinute - (ps[0]!.endMinute - 30)
          if lead ≤ 240 then
            sumNear := sumNear + (p.estimateKw - actualKw p).abs; actNear := actNear + actualKw p; nNear := nNear + 1
          else if lead > 1440 then
            sumFar := sumFar + (p.estimateKw - actualKw p).abs; actFar := actFar + actualKw p; nFar := nFar + 1
    say s!"sunny periods ending 10:30 to 14:00, seed 7, 92 fetches at 10:00 and 92 at 00:00\n0 to 4 hours ahead: {nNear} periods, error {f3 (100 * sumNear / actNear)}% of the actual power\n24 to 48 hours ahead: {nFar} periods, error {f3 (100 * sumFar / actFar)}% of the actual power"
  | "r2-5" => do
    let mut inBand := 0; let mut total := 0
    for ps in dailyFetches do
      for p in ps.toList do
        if actualKw p > 0 then
          total := total + 1
          if p.p10Kw - 1e-9 ≤ actualKw p && actualKw p ≤ p.p90Kw + 1e-9 then inBand := inBand + 1
    say s!"92 daily fetches at 00:00, {total} sunny periods\nactual power inside the band: {inBand} = {f3 (100 * inBand.toFloat / total.toFloat)}% (60% to 95%)"
  | "r3-1" => say s!"10 fetches a day: {(fetchHours 10).toList}"
  | "r3-2" => say s!"3 fetches a day: {(fetchHours 3).toList}"
  | "r3-3" => say s!"1 fetch a day: {(fetchHours 1).toList}"
  | "r3-4" => say s!"10 fetches a day, the latest fetch for hour 27: hour {latestFetch 10 27}"
  | "r3-5" => say s!"10 fetches a day, the latest fetch for hour 26: hour {latestFetch 10 26}\nthe latest fetch for hour 25: hour {latestFetch 10 25}"
  | "r3-6" => say s!"1 fetch a day, the latest fetch for hour 47: hour {latestFetch 1 47}"
  | "r4-1" => say s!"longitude 0, fetch at hour 0, first period_end: {jsonField (forecastJson (fetch 7 1.0 0) 0.0) "\"period_end\":\""}"
  | "r4-2" => say s!"longitude 174.8, fetch at hour 0, first period_end: {jsonField (forecastJson (fetch 7 1.0 0) 174.8) "\"period_end\":\""}"
  | "r4-3" => say s!"longitude -75, fetch at hour 0, first period_end: {jsonField (forecastJson (fetch 7 1.0 0) (-75.0)) "\"period_end\":\""}"
  | "r4-4" => do
    let j := forecastJson (fetch 7 1.0 8759) 0.0
    say s!"longitude 0, fetch at hour 8759: 2 periods\nlast period_end: {jsonField j "\"period_end\":\"" 1}"
  | "r4-5" => do
    let ps := fetch 7 0.0 4116
    let j := forecastJson ps 0.0
    let values := (List.range ps.size).map fun i => jsonField j "\"pv_estimate\":" i
    let ok := values.all fun v => match v.splitOn "." with | [_, f] => f.length == 4 | _ => false
    say s!"error scale 0, fetch at hour 4116: {ps.size} periods\nfirst pv_estimate values (the JSON text up to the next comma): {(values.take 4)}\neach pv_estimate has four decimals: {ok}"
  | "r4-6" => do
    let j := forecastJson (fetch 7 1.0 0) 174.8
    let first := (j.splitOn "},").head!
    say s!"fetch at hour 0, the first period of the JSON:\n{first}}"
  | "r5-1" => do
    let ps := fetch 7 0.0 0
    let hs := hourlyEnergy ps 0
    let worst := (List.range 48).foldl (fun m j => max m (hs[j]! - hoursOfScenario[j]!.pvKwh).abs) 0
    say s!"error scale 0, fetch at hour 0: {hs.size} values\nhours 10 to 13 of the forecast: {(List.range 4).map (fun k => f3 hs[10 + k]!)}\nhours 10 to 13 of the scenario: {(List.range 4).map (fun k => f3 hoursOfScenario[10 + k]!.pvKwh)}\nlargest difference over 48 hours: {worst} kWh (0.000001 or less)"
  | "r5-2" => do
    let hs := hourlyEnergy (fetch 7 1.0 4116) 4116
    let lo := hs.foldl min 1000.0
    let hi := hs.foldl max (-1000.0)
    say s!"fetch at hour 4116: {hs.size} values\nlowest: {f3 lo} kWh, highest: {f3 hi} kWh (0 to 5)"
  | "r5-3" => do
    let hs := hourlyEnergy (fetch 7 1.0 8750) 8750
    say s!"fetch at hour 8750: {hs.size} values\nvalues 10 to 47 are all 0: {(List.range 38).all fun k => hs[10 + k]! == 0}"
  | "r5-4" => do
    let hs := hourlyEnergy (fetch 7 1.0 8760) 8760
    say s!"fetch at hour 8760: {hs.size} values\nlargest value: {hs.foldl max 0.0} kWh"
  | "r5-5" => do
    let ps := fetch 7 1.0 4116
    let hs := hourlyEnergy ps 4116
    let sumH := hs.foldl (· + ·) 0.0
    let sumP := ps.foldl (fun a p => a + p.estimateKw) 0.0
    say s!"fetch at hour 4116\nsum of the 48 values: {f3 sumH} kWh\n0.5 times the sum of the {ps.size} estimates: {f3 (0.5 * sumP)} kWh"
  | k => say s!"unknown key {k}"

def main (args : List String) : IO Unit := run (args.headD "")
