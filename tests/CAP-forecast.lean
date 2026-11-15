/-
Component checks of CAP-forecast, for CH-0006 (forecast from built hours). The change covers
CAP-forecast.R6 (forecast from built hours) and CAP-forecast.R7 (shared error of a day).

The checks call only `Period`, `forecast`, `forecastOf`, `Site`, `Hour` and `scenario`. No
entry of the Interface can fail, so no check expects an error code. The `seed` argument of
`forecast` and `forecastOf` is the only seam. No check uses the clock. No check waits for a
process, so no check needs a time limit.

In the lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is 365
days, and the error scale is 1, unless the line says otherwise.

Terms of the checks:
- The actual power of a period that ends at minute `e` is the solar energy of hour
  `(e - 30) / 60` in the scenario with the same site, seed and days.
- A sunny period is a period with an actual power of more than 0 kW, as CAP-forecast.R2 says.
- An estimate is cut when it is 0 kW or it is the panel power (5 kW).

Statistics of CAP-forecast.R7. The relative error of a sunny period is its estimate less its
actual power, over the actual power. R7 divides it also by the spread. The spread depends only
on the lead time of the period. Each series that a line compares has one lead time (for
example, the period that ends at 11:30 in the fetches at 00:00). Thus the spread is one
constant for the series. A correlation does not change when a series is scaled by a constant,
and the sign does not change either. So the helper `relErr` leaves out the spread. It then
needs no rule for the spread (a step or a slope).

Shared runs. A forecast from the built hours is cheap, and a call of `forecast` builds the
scenario again. Thus the checks of R7 call `forecastOf` with the hours of seed 7, built once
at the top level of this file.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Forecast
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

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

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

-- Helpers for CAP-forecast

def site45 : Site :=
  { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

/-- The hours of seed 7 and 365 days, built once. -/
def scen7 : Array Hour := scenario site45 7 365

/-- The hours of seed 8 and 365 days, for the lines that compare two seeds. -/
def scen8 : Array Hour := scenario site45 8 365

/-- A forecast of the lines: site 45, seed 7, 365 days, from the built hours. -/
def fo (scale : Float) (fetch : Nat) : Array Period :=
  forecastOf scen7 site45 7 scale fetch

/-- The hour of the run of a period that ends at minute `e`. -/
def accHourOf (e : Nat) : Nat := (e - 30) / 60

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def accActualKw (e : Nat) : Float := scen7[accHourOf e]!.pvKwh

def samePeriod (a b : Period) : Bool :=
  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
  a.p90Kw == b.p90Kw

def samePeriods (a b : Array Period) : Bool :=
  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)

def sumEst (ps : Array Period) : Float := sumF (ps.toList.map (fun p => p.estimateKw))

/-- Each value of each period must equal its actual power. -/
def badEqual (ps : Array Period) : Option String :=
  ps.toList.findSome? (fun p =>
    let a := accActualKw p.endMinute
    if near p.estimateKw a 1e-6 && near p.p10Kw a 1e-6 && near p.p90Kw a 1e-6 then none
    else some s!"end {p.endMinute}: actual {a}, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}")

/-- `forecastOf` and `forecast` must give the same periods for a fetch hour. -/
def sameAsForecast (f : Nat) : Option String :=
  let a := forecastOf scen7 site45 7 1.0 f
  let b := forecast site45 7 365 1.0 f
  if a.size > 0 && samePeriods a b then none
  else some s!"fetch {f}: forecastOf gives {a.size} periods and forecast gives {b.size}, or a value differs"

/-- The period of a fetch that ends at minute `e` of the run. -/
def periodEnding (ps : Array Period) (e : Nat) : Option Period :=
  ps.toList.find? (fun p => p.endMinute == e)

/-- The relative error of a period: its estimate less its actual power, over the actual power.
The spread is left out. See the comment at the top of the file. -/
def relErr (p : Period) : Float :=
  (p.estimateKw - accActualKw p.endMinute) / accActualKw p.endMinute

/-- An estimate is cut at 0 kW or at the panel power of 5 kW. -/
def isCut (p : Period) : Bool := p.estimateKw ≤ 1e-9 || p.estimateKw ≥ 5.0 - 1e-9

/-- A sunny period with an estimate that is not cut. -/
def okSunny (p : Period) : Bool := accActualKw p.endMinute > 0.0 && !isCut p

def inBand (p : Period) : Bool :=
  let a := accActualKw p.endMinute
  p.p10Kw - 1e-9 ≤ a && a ≤ p.p90Kw + 1e-9

/-- The fetches at 00:00 of the days 0 to 364, each with the hour of its fetch. -/
def dayFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d, fo 1.0 (24 * d)))

/-- The fetches at hour 10 of the days 0 to 364. -/
def tenFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d + 10, fo 1.0 (24 * d + 10)))

/-- The relative errors of the periods that end at 11:30 and at 13:30 of the same day, for
each day that has both, sunny and not cut. The fetch is at 00:00 of the day. -/
def pairsSameDay : List (Float × Float) :=
  dayFetches.filterMap (fun (f, ps) =>
    match periodEnding ps (60 * f + 690), periodEnding ps (60 * f + 810) with
    | some a, some b => if okSunny a && okSunny b then some (relErr a, relErr b) else none
    | _, _ => none)

/-- The relative error of the sunny period that ends at 11:30 of the day of a fetch at 00:00,
shifted by `shift` minutes. A day has none when its period is not in the fetch or it is not
sunny. -/
def err1130 (shift : Nat) : List (Option Float) :=
  dayFetches.map (fun (f, ps) =>
    match periodEnding ps (60 * f + 690 + shift) with
    | some p => if accActualKw p.endMinute > 0.0 then some (relErr p) else none
    | none => none)

def bothSome (a b : List (Option Float)) : List (Float × Float) :=
  (a.zip b).filterMap (fun (x, y) =>
    match x, y with
    | some u, some v => some (u, v)
    | _, _ => none)

/-- The periods that end at 11:30 of a day and of the next day. Each one comes from the fetch
at 00:00 of its own day. -/
def pairsNextFetch : List (Float × Float) :=
  bothSome (err1130 0) ((err1130 0).tail)

/-- The periods that end at 11:30 of a day and of the next day. Both come from the fetch at
00:00 of the first day. -/
def pairsNextSameFetch : List (Float × Float) :=
  bothSome (err1130 0) (err1130 1440)

/-- The relative errors of the period that ends at 13:30 of a day, from the fetch at 00:00 and
from the fetch at hour 10. Only a sunny period counts. -/
def signPairs : List (Float × Float) :=
  (dayFetches.zip tenFetches).filterMap (fun (a, b) =>
    match periodEnding a.2 (60 * a.1 + 810), periodEnding b.2 (60 * a.1 + 810) with
    | some p, some q =>
      if accActualKw p.endMinute > 0.0 then some (relErr p, relErr q) else none
    | _, _ => none)

/-- The sunny periods of the fetches at 00:00 of each day. -/
def sunnyAll : List Period :=
  dayFetches.foldl (fun acc (_, ps) =>
    acc ++ ps.toList.filter (fun p => accActualKw p.endMinute > 0.0)) []

def checks : List Check := [
  -- CAP-forecast.R6
  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast for the fetch hours 0, 4116 and 8750",
    run := do
      let a := forecastOf scen7 site45 7 1.0 0
      let b := forecastOf scen7 site45 7 1.0 8750
      return firstSome [
        sameAsForecast 0, sameAsForecast 4116, sameAsForecast 8750,
        if a.size == 96 && b.size == 20 then none
        else some s!"{a.size} periods at hour 0 and {b.size} periods at hour 8750"] },
  { name := "CAP-forecast.R6 with an error scale of 0 each value of a fetch at hour 4000 equals its actual power",
    run := do
      let ps := forecastOf scen7 site45 7 0.0 4000
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R6 a fetch at hour 8760 has no period",
    run := do
      let ps := forecastOf scen7 site45 7 1.0 8760
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 no hours give no period for a fetch at hour 0",
    run := do
      let ps := forecastOf (#[] : Array Hour) site45 7 1.0 0
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 seeds 7 and 8 give a different estimate for a fetch at hour 4000",
    run := do
      let a := forecastOf scen7 site45 7 1.0 4000
      let b := forecastOf scen8 site45 8 1.0 4000
      let differs := (List.zip a.toList b.toList).any (fun (x, y) => !(x.estimateKw == y.estimateKw))
      return firstFail [
        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
        (differs, "each estimate is the same for the two seeds")] },
  -- Checks that the acceptance file lacks: the seam `seed`, and the edges of the Interface.
  { name := "CAP-forecast.R6 the same seed gives the same forecast from forecastOf and from forecast",
    run := do
      let again := scenario site45 7 365
      let a := forecastOf scen7 site45 7 1.0 4116
      let b := forecastOf again site45 7 1.0 4116
      let c := forecast site45 7 365 1.0 4116
      let d := forecast site45 7 365 1.0 4116
      return firstFail [
        (a.size == 96, s!"{a.size} periods"),
        (samePeriods a b, "two calls of forecastOf with seed 7 give other periods"),
        (samePeriods c d, "two calls of forecast with seed 7 give other periods")] },
  { name := "CAP-forecast.R6 a fetch at hour 8759 has the 2 periods of the last hour, as forecast gives",
    run := do
      let a := fo 1.0 8759
      let b := forecast site45 7 365 1.0 8759
      let ends := a.toList.map (fun p => p.endMinute)
      return firstFail [
        (a.size == 2, s!"{a.size} periods, want 2"),
        (ends == [525570, 525600], s!"the ends are {ends}, want [525570, 525600]"),
        (samePeriods a b, "forecastOf and forecast give other periods")] },
  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast with an error scale of 0.5",
    run := do
      let a := fo 0.5 4116
      let b := forecast site45 7 365 0.5 4116
      return firstFail [
        (a.size == 96, s!"{a.size} periods"),
        (samePeriods a b, "forecastOf and forecast give other periods with an error scale of 0.5")] },
  { name := "CAP-forecast.R6 hours of 10 days make a run of 10 days: the fetch at hour 240 has no period",
    run := do
      let hs := scenario site45 7 10
      let at230 := forecastOf hs site45 7 1.0 230
      let at239 := forecastOf hs site45 7 1.0 239
      let at240 := forecastOf hs site45 7 1.0 240
      let ends := at230.toList.map (fun p => p.endMinute)
      return firstFail [
        (hs.size == 240, s!"{hs.size} hours, want 240"),
        (at230.size == 20, s!"{at230.size} periods at hour 230, want 20"),
        (ends.head? == some 13830 && ends.getLast? == some 14400,
          s!"the first and the last end at hour 230 are {ends.head?} and {ends.getLast?}, want 13830 and 14400"),
        (samePeriods at230 (forecast site45 7 10 1.0 230),
          "forecastOf and forecast give other periods at hour 230"),
        (at239.size == 2 && samePeriods at239 (forecast site45 7 10 1.0 239),
          s!"hour 239 gives {at239.size} periods, want 2 as forecast gives"),
        (at240.size == 0, s!"{at240.size} periods at hour 240, want 0")] },
  { name := "CAP-forecast.R6 no hours give no period for each fetch hour and each error scale",
    run := do
      let cases : List (Nat × Float) :=
        [(0, 1.0), (1, 1.0), (100, 1.0), (4116, 0.0), (8760, 1.0)]
      let bad := cases.find? (fun (f, s) =>
        (forecastOf (#[] : Array Hour) site45 7 s f).size != 0)
      return match bad with
        | some (f, s) => some s!"fetch hour {f} with error scale {s} has periods"
        | none => none },

  -- CAP-forecast.R7
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 and at 13:30 of a day have a correlation from 0.55 to 0.85",
    run := do
      let n := pairsSameDay.length
      let c := corrF (pairsSameDay.map (·.1)) (pairsSameDay.map (·.2))
      if n < 150 then
        return some s!"only {n} days have both periods"
      return if c ≥ 0.55 && c ≤ 0.85 then none
        else some s!"correlation {c} over {n} days" },
  -- The line says that each period comes from the fetch at 00:00 of its own day. The variable `a`
  -- reads the line so. The variable `b` also takes both periods from the fetch of the first
  -- day. Both readings must give a correlation from -0.25 to 0.25.
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25",
    run := do
      let a := pairsNextFetch
      let b := pairsNextSameFetch
      let ca := corrF (a.map (·.1)) (a.map (·.2))
      let cb := corrF (b.map (·.1)) (b.map (·.2))
      return firstFail [
        (a.length ≥ 150 && b.length ≥ 150, s!"only {a.length} and {b.length} pairs of days"),
        (ca ≥ -0.25 && ca ≤ 0.25,
          s!"fetch of each day: correlation {ca} over {a.length} pairs of days"),
        (cb ≥ -0.25 && cb ≤ 0.25,
          s!"one fetch for both days: correlation {cb} over {b.length} pairs of days")] },
  { name := "CAP-forecast.R7 at least 62% of the days have the same sign of the error at 13:30 in the fetches at hour 0 and at hour 10",
    run := do
      let usable := signPairs.filter (fun (x, y) => x.abs > 1e-12 && y.abs > 1e-12)
      let same := usable.filter (fun (x, y) => x * y > 0.0)
      let n := usable.length
      if n < 150 then
        return some s!"only {n} days count"
      return if same.length.toFloat ≥ 0.62 * n.toFloat then none
        else some s!"{same.length} of {n} days have the same sign" },
  { name := "CAP-forecast.R7 with an error scale of 0 each value of a fetch at hour 0 equals its actual power",
    run := do
      let ps := fo 0.0 0
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R7 60% to 95% of the sunny periods of a fetch at 00:00 of each day have the actual power in the band",
    run := do
      let n := sunnyAll.length
      let k := (sunnyAll.filter inBand).length
      if n < 1000 then
        return some s!"only {n} sunny periods"
      return if k.toFloat ≥ 0.6 * n.toFloat && k.toFloat ≤ 0.95 * n.toFloat then none
        else some s!"{k} of {n} sunny periods have the actual power in the band" }
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
