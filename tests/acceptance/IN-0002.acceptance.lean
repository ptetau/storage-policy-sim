/-
Acceptance checks of IN-0002 (simulated Solcast forecast for policies).

The intent has one change, CH-0005 (simulated Solcast forecast). Thus this file is also the
component check file of CH-0005. It holds the checks of CAP-forecast.R1 to R5. The intent
lists only R1 and R5, but the steps of CH-0005 name the checks of R2, R3 and R4 in this file.

Stored-data lines: none. No requirement of this intent reads or writes stored data.

The forecast has no command yet. The checks call the public functions of the library:
`forecast`, `fetchHours`, `latestFetch`, `hourlyEnergy` and `forecastJson` of CAP-forecast,
and `scenario` of CAP-scenario. No entry of the Interface can fail, so no check expects an
error code. The `seed` argument of `forecast` is the only test seam. No check uses the clock.

Terms of the checks:
- The actual power of a period is the solar output of its hour in the scenario with the same
  site, seed and days. The hour of a period that ends at minute `e` is `(e - 30) / 60`.
- A sunny period is a period with an actual power of more than 0 kW, as CAP-forecast.R2
  says. The sky does not matter. A night period is not sunny, so no statistical check counts
  it. A period at dawn or at dusk, and a period under an overcast sky, is sunny.

The statistical checks use seed 7, a run of 365 days and an error scale of 1. They use a fetch
on every fourth day, at 00:00 and at 10:00. Each fetch costs one scenario of 365 days.
- Coverage: under the model of the spec, about 80% of the sunny periods have the actual power
  in the band. This share does not depend on the sky or on the size of the actual power, except
  for a small effect of the cut at 5 kW. The checks keep the 60% to 95% of the spec. A version
  with no band scores about 0%.
- Growth: the groups of the growth check use only the sunny periods that end from 10:30 to
  14:00 of their day, so both groups have the same hours of the day. The mean absolute error
  is the line of the spec. It also depends on how much sun the days of each group have, so a
  version with no growth can pass it. Thus a second check compares the mean error as a share
  of the actual power, which does not depend on the sky. The model gives about 2.5 times, and
  the check requires 1.5 times.
- Error size: the mean error as a share of the actual power is the spread times 0.80, for any
  sky. The bounds keep a margin of more than four standard errors, and they hold for the
  spread as a step or as a slope.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Forecast
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- True for a value from 0 to 5, with a margin for rounding. False for NaN. -/
def okVal (v : Float) : Bool := v ≥ -1e-9 && v ≤ 5.0 + 1e-9

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

def sumList (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0

def meanOf (xs : List Float) : Float :=
  if xs.isEmpty then 0.0 else sumList xs / xs.length.toFloat

def digitsVal (cs : List Char) : Nat :=
  cs.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads a printed number: an optional minus, digits, and an optional point with digits. -/
def parseNum (s : String) : Option Float :=
  let p : Bool × List Char := match s.toList with
    | '-' :: r => (true, r)
    | r => (false, r)
  let cs := p.2
  let ip := cs.takeWhile Char.isDigit
  let rest := cs.dropWhile Char.isDigit
  let q : List Char × List Char := match rest with
    | '.' :: r => (r.takeWhile Char.isDigit, r.dropWhile Char.isDigit)
    | r => ([], r)
  if ip.isEmpty || !q.2.isEmpty then none
  else
    let v := Float.ofNat (digitsVal ip) + Float.ofScientific (digitsVal q.1) true q.1.length
    some (if p.1 then -v else v)

-- Helpers for the library

/-- The site of the lines: latitude 45 with 5 kW of panels. The load does not matter here. -/
def site45 : Site :=
  { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

/-- The scenario of the lines: seed 7 and 365 days. -/
def scen7 : Array Hour := scenario site45 7 365

/-- The scenario of seed 8, for the checks that compare two seeds. -/
def scen8 : Array Hour := scenario site45 8 365

/-- The forecast of the lines: seed 7, 365 days, and the given error scale and fetch hour. -/
def fc (scale : Float) (fetch : Nat) : Array Period :=
  forecast site45 7 365 scale fetch

def mkP (e : Nat) (est p10 p90 : Float) : Period :=
  { endMinute := e, estimateKw := est, p10Kw := p10, p90Kw := p90 }

def endMins (ps : Array Period) : List Nat := ps.toList.map (fun p => p.endMinute)

/-- The end minutes of period 1 to period `n` of a fetch at hour `f`. -/
def wantEnds (f n : Nat) : List Nat := (List.range n).map (fun i => 60 * f + 30 * (i + 1))

/-- The hour of the run of a period that ends at minute `e`. -/
def hourOf (e : Nat) : Nat := (e - 30) / 60

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def actualKw (e : Nat) : Float := scen7[hourOf e]!.pvKwh

/-- A sunny period has an actual power of more than 0 kW. The sky does not matter. -/
def isSunny (e : Nat) : Bool := actualKw e > 0.0

/-- The lead time of a period in minutes, from a fetch at hour `f`. -/
def leadMin (f : Nat) (p : Period) : Nat := p.endMinute - 60 * f

def absErr (p : Period) : Float := (p.estimateKw - actualKw p.endMinute).abs

def relErr (p : Period) : Float := absErr p / actualKw p.endMinute

def inBand (p : Period) : Bool :=
  let a := actualKw p.endMinute
  p.p10Kw - 1e-9 ≤ a && a ≤ p.p90Kw + 1e-9

def sumEst (ps : Array Period) : Float := sumList (ps.toList.map (fun p => p.estimateKw))

def sumArr (a : Array Float) : Float := sumList a.toList

def samePeriod (a b : Period) : Bool :=
  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
  a.p90Kw == b.p90Kw

def samePeriods (a b : Array Period) : Bool :=
  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)

-- The fetches of the statistical checks: every fourth day of the run, at 00:00 and at 10:00

def daysList : List Nat := (List.range 92).map (fun i => 4 * i)

def fetches0 : List (Nat × Array Period) :=
  daysList.map (fun d => (24 * d, fc 1.0 (24 * d)))

def fetches10 : List (Nat × Array Period) :=
  daysList.map (fun d => (24 * d + 10, fc 1.0 (24 * d + 10)))

/-- The sunny periods of the fetches, each with the hour of its fetch. -/
def sunnyPeriods (fs : List (Nat × Array Period)) : List (Nat × Period) :=
  fs.foldl (fun acc (f, ps) =>
    acc ++ (ps.toList.filter (fun p => isSunny p.endMinute)).map (fun p => (f, p))) []

/-- The value `f` of each sunny period that ends from 10:30 to 14:00 of its day, with a lead
time from `lo` to `hi` minutes. Both groups of the growth check use the same hours of the day,
so the actual power is about the same in both groups. -/
def noonValues (fs : List (Nat × Array Period)) (lo hi : Nat) (f : Period → Float) :
    List Float :=
  ((sunnyPeriods fs).filter (fun (fh, p) =>
      10 ≤ hourOf p.endMinute % 24 && hourOf p.endMinute % 24 ≤ 13 &&
      lo ≤ leadMin fh p && leadMin fh p ≤ hi)).map (fun (_, p) => f p)

def badShape (fs : List (Nat × Array Period)) : Option String :=
  fs.findSome? (fun (f, ps) =>
    let n := min 96 (2 * (8760 - f))
    if endMins ps == wantEnds f n then none
    else some s!"fetch {f}: {ps.size} periods, want {n}")

def badOrder (fs : List (Nat × Array Period)) : Option String :=
  fs.findSome? (fun (f, ps) =>
    (ps.toList.find? (fun p =>
        !(p.p10Kw ≤ p.estimateKw + 1e-9 && p.estimateKw ≤ p.p90Kw + 1e-9))).map
      (fun p => s!"fetch {f} end {p.endMinute}: 10% {p.p10Kw}, estimate {p.estimateKw}, 90% {p.p90Kw}"))

/-- A sunny period has its 10% band below its estimate and its 90% band above it, unless the
estimate is at the panel power. A version can form the bands from the estimate before the cut
at 5 kW and then cut each value, which gives 10% = estimate = 90% = 5 kW. -/
def badStraddle (fs : List (Nat × Array Period)) : Option String :=
  fs.findSome? (fun (f, ps) =>
    (ps.toList.find? (fun p =>
        isSunny p.endMinute && p.estimateKw > 1e-6 &&
        !(p.estimateKw ≥ 5.0 - 1e-9 || (p.p10Kw < p.estimateKw && p.p90Kw > p.estimateKw)))).map
      (fun p => s!"fetch {f} end {p.endMinute}: 10% {p.p10Kw}, estimate {p.estimateKw}, 90% {p.p90Kw}"))

def badRange (fs : List (Nat × Array Period)) : Option String :=
  fs.findSome? (fun (f, ps) =>
    (ps.toList.find? (fun p => !(okVal p.estimateKw && okVal p.p10Kw && okVal p.p90Kw))).map
      (fun p => s!"fetch {f} end {p.endMinute}: estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}"))

def maxEst (fs : List (Nat × Array Period)) : Float :=
  fs.foldl (fun acc (_, ps) =>
    ps.toList.foldl (fun a p => if p.estimateKw > a then p.estimateKw else a) acc) 0.0

/-- The fetches of the large error scale: 17 fetches at noon, from day 100 to day 260. -/
def bigFetch (i : Nat) : Nat × Array Period :=
  let f := 24 * (100 + 10 * i) + 12
  (f, fc 6.0 f)

/-- The fetches that the check of the night periods uses. -/
def nightFetches : List Nat := [0, 2000, 4104, 8000]

/-- A period with no actual power must have 0 kW in all three values. -/
def badNight (f : Nat) (ps : Array Period) : Option String :=
  ps.toList.findSome? (fun p =>
    if actualKw p.endMinute == 0.0 &&
        !(near p.estimateKw 0.0 1e-12 && near p.p10Kw 0.0 1e-12 && near p.p90Kw 0.0 1e-12) then
      some s!"fetch {f} end {p.endMinute}: no sun, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}"
    else none)

/-- Each value of each period must equal its actual power. -/
def badEqual (ps : Array Period) : Option String :=
  ps.toList.findSome? (fun p =>
    let a := actualKw p.endMinute
    if near p.estimateKw a 1e-6 && near p.p10Kw a 1e-6 && near p.p90Kw a 1e-6 then none
    else some s!"end {p.endMinute}: actual {a}, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}")

-- The bands: the half-width is 1.28 times the error scale times the spread

def bandFetches : List Nat := (List.range 6).map (fun i => 24 * (160 + 7 * i) + 16)

/-- Period `i` of a fetch, when its estimate and its bands are not cut at 0 or at 5 kW. -/
def openPeriod (ps : Array Period) (i : Nat) : Option Period :=
  match ps[i]? with
  | some p =>
    if p.estimateKw > 0.05 && p.p10Kw > 1e-9 && p.p90Kw < 5.0 - 1e-9 then some p else none
  | none => none

/-- The relative half-width of the bands of period `i` must lie in the range of the spread. -/
def bandsAt (s : Float) (fcs : List (Array Period)) (i : Nat) (spreadLo spreadHi : Float) :
    Option String :=
  let open_ := fcs.filterMap (fun ps => openPeriod ps i)
  let lo := 0.99 * 1.28 * s * spreadLo
  let hi := 1.01 * 1.28 * s * spreadHi
  if open_.length < 3 then
    some s!"scale {s}, period {i + 1}: only {open_.length} of {fcs.length} fetches have open bands"
  else
    (open_.find? (fun p =>
        !((p.p90Kw - p.p10Kw) / (2.0 * p.estimateKw) ≥ lo &&
          (p.p90Kw - p.p10Kw) / (2.0 * p.estimateKw) ≤ hi &&
          near (p.estimateKw - p.p10Kw) (p.p90Kw - p.estimateKw) 1e-9))).map
      (fun p => s!"scale {s}, period {i + 1}: estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}, want a half-width of {lo} to {hi} times the estimate")

/-- The spread is 0.05 at a lead time of 0 hours, and it grows by 0.10 for each 24 hours. A
step of the spread gives the lower value and a slope gives the upper value. The checks allow
both: 0.05 to 0.0521 at 0.5 hours ahead, and 0.15 to 0.1521 at 24.5 hours ahead. -/
def bandsFor (s : Float) : Option String :=
  let fcs := bandFetches.map (fun f => fc s f)
  firstSome [
    bandsAt s fcs 0 0.05 (0.05 + 0.10 * 0.5 / 24.0),
    bandsAt s fcs 48 0.15 (0.05 + 0.10 * 24.5 / 24.0)]

-- Helpers for the Solcast JSON

def jsonPrefix : String := "{\"forecasts\":["

/-- The comma-separated fields between the prefix and the suffix. None if the frame is wrong. -/
def jsonTokens (s : String) : Option (List String) :=
  match s.splitOn jsonPrefix with
  | ["", rest] => (match rest.splitOn "]}" with
      | [inner, ""] => some (if inner == "" then [] else inner.splitOn ",")
      | _ => none)
  | _ => none

/-- The period end of each period of the JSON text. -/
def jsonEnds (js : String) : List String :=
  ((js.splitOn "\"period_end\":\"").drop 1).map (fun p => (p.splitOn "\"").headD "")

/-- The text after `"key":` up to the next comma, for each period of the JSON text. -/
def valuesOfKey (js key : String) : List String :=
  ((js.splitOn ("\"" ++ key ++ "\":")).drop 1).map (fun p => (p.splitOn ",").headD "")

def firstEnd (lon : Float) (fetch : Nat) : Option String :=
  (jsonEnds (forecastJson (fc 1.0 fetch) lon)).head?

/-- The end of a period at minute 30 for a longitude, as the JSON gives it. -/
def endAt30 (lon : Float) : Option String :=
  (jsonEnds (forecastJson #[mkP 30 1.0 0.5 1.5] lon)).head?

def two (n : Nat) : String := if n < 10 then s!"0{n}" else s!"{n}"

/-- The time of minute `m` of the run on 1 to 3 January at longitude 0. -/
def isoJan (m : Nat) : String :=
  s!"2025-01-{two (1 + m / 1440)}T{two (m % 1440 / 60)}:{two (m % 60)}:00.0000000Z"

def fourDecimals (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && a.toList.all Char.isDigit && b.length == 4 && b.toList.all Char.isDigit
  | _ => false

/-- A period end has the form `2025-01-01T00:30:00.0000000Z`, at a full or a half hour. -/
def isIso (t : String) : Bool :=
  let cs := t.toList
  cs.length == 28 && cs[4]? == some '-' && cs[7]? == some '-' && cs[10]? == some 'T' &&
  cs[13]? == some ':' && cs[16]? == some ':' &&
  (t.endsWith "00:00.0000000Z" || t.endsWith "30:00.0000000Z") &&
  cs.all (fun c => c.isDigit || c == '-' || c == 'T' || c == ':' || c == '.' || c == 'Z')

def tokenOk (j : Nat) (t : String) : Bool :=
  match j % 5 with
  | 0 => t.startsWith "{\"pv_estimate\":"
  | 1 => t.startsWith "\"pv_estimate10\":"
  | 2 => t.startsWith "\"pv_estimate90\":"
  | 3 => t.startsWith "\"period_end\":\"" && t.endsWith "\""
  | _ => t == "\"period\":\"PT30M\"}"

/-- Each printed value must have four decimals, and it must be within 0.00011 of the value of
its period. A printed value that is rounded or cut at four decimals passes. -/
def badValues (js key : String) (ps : Array Period) (get : Period → Float) : Option String :=
  let vs := valuesOfKey js key
  if vs.length != ps.size then some s!"{key}: {vs.length} values for {ps.size} periods"
  else (List.zip vs ps.toList).findSome? (fun (v, p) =>
    match parseNum v with
    | none => some s!"{key}: {repr v} is not a number"
    | some x =>
      if fourDecimals v && near x (get p) 0.00011 then none
      else some s!"{key}: printed {v} for {get p}")

/-- Three periods with values that need no rounding, to check the text exactly. -/
def handExact : Array Period :=
  #[mkP 30 1.5 1.25 2.0, mkP 60 0.0625 0.0 0.125, mkP 1470 3.0 2.5 4.0]

def handExactText : String :=
  "{\"forecasts\":[" ++
  "{\"pv_estimate\":1.5000,\"pv_estimate10\":1.2500,\"pv_estimate90\":2.0000,\"period_end\":\"2025-01-01T00:30:00.0000000Z\",\"period\":\"PT30M\"}," ++
  "{\"pv_estimate\":0.0625,\"pv_estimate10\":0.0000,\"pv_estimate90\":0.1250,\"period_end\":\"2025-01-01T01:00:00.0000000Z\",\"period\":\"PT30M\"}," ++
  "{\"pv_estimate\":3.0000,\"pv_estimate10\":2.5000,\"pv_estimate90\":4.0000,\"period_end\":\"2025-01-02T00:30:00.0000000Z\",\"period\":\"PT30M\"}" ++
  "]}"

-- Helpers for the hourly energy

/-- Compares the 48 values of the hourly energy with the wanted values. -/
def energyFails (v : Array Float) (want : Nat → Float) (tol : Float) : Option String :=
  if v.size != 48 then some s!"{v.size} values, want 48"
  else match (List.range 48).find? (fun j => !near (v.getD j (-1.0)) (want j) tol) with
    | some j => some s!"value {j} is {v.getD j (-1.0)}, want {want j}"
    | none => none

/-- Periods in hours 100, 101 and 104, with none in hours 102 and 103. The 10% and 90% bands
differ from the estimate, so a version that reads a band gets a wrong value. -/
def handEnergyA : Array Period :=
  #[mkP 6030 2.0 0.1 9.0, mkP 6060 3.0 0.1 9.0, mkP 6090 1.0 0.1 9.0, mkP 6120 5.0 0.1 9.0,
    mkP 6270 2.5 0.1 9.0, mkP 6300 3.5 0.1 9.0]

/-- Periods in hour 4116 and hour 4163, the first and the last hour of the 48 hours. -/
def handEnergyB : Array Period :=
  #[mkP 246990 1.0 0.1 9.0, mkP 247020 3.0 0.1 9.0, mkP 249810 4.0 0.1 9.0,
    mkP 249840 6.0 0.1 9.0]

-- Helpers for the fetch limit

def fetchTable : List (Nat × List Nat) := [
  (1, [0]), (2, [0, 12]), (3, [0, 8, 16]), (4, [0, 6, 12, 18]), (5, [0, 4, 9, 14, 19]),
  (6, [0, 4, 8, 12, 16, 20]), (7, [0, 3, 6, 10, 13, 17, 20]),
  (8, [0, 3, 6, 9, 12, 15, 18, 21]), (9, [0, 2, 5, 8, 10, 13, 16, 18, 21]),
  (10, [0, 2, 4, 7, 9, 12, 14, 16, 19, 21])]

/-- Fetches a day, hour of the run, and the hour of the run of the latest fetch. -/
def latestTable : List (Nat × Nat × Nat) := [
  (10, 0, 0), (10, 1, 0), (10, 2, 2), (10, 3, 2), (10, 23, 21), (10, 24, 24),
  (10, 8757, 8757), (10, 8759, 8757),
  (3, 7, 0), (3, 8, 8), (3, 15, 8), (3, 16, 16), (3, 23, 16), (3, 31, 24), (3, 32, 32),
  (1, 0, 0), (1, 23, 0), (1, 24, 24)]

/-- The latest fetch at or before an hour, from the fetch hours of the day. -/
def wantLatest (n h : Nat) : Nat :=
  let day := h / 24
  let todays := (fetchHours n).toList.filter (fun x => 24 * day + x ≤ h)
  24 * day + todays.foldl max 0

def checks : List Check := [
  -- CAP-forecast.R1
  { name := "CAP-forecast.R1 a fetch at hour 0 has 96 periods that end at 30, 60 and up to 2880 minutes",
    run := do
      let ps := fc 1.0 0
      return firstFail [
        (ps.size == 96, s!"{ps.size} periods"),
        (endMins ps == wantEnds 0 96, s!"the ends are {endMins ps}")] },
  { name := "CAP-forecast.R1 a fetch at hour 100 has 96 periods from 6030 to 8880 minutes",
    run := do
      let ps := fc 1.0 100
      return firstFail [
        (ps.size == 96, s!"{ps.size} periods"),
        ((endMins ps).head? == some 6030, s!"the first period ends at {(endMins ps).head?}"),
        ((endMins ps).getLast? == some 8880, s!"the last period ends at {(endMins ps).getLast?}"),
        (endMins ps == wantEnds 100 96, s!"the ends are {endMins ps}")] },
  { name := "CAP-forecast.R1 a fetch at hour 8750 has 20 periods because the run ends after 10 hours",
    run := do
      let ps := fc 1.0 8750
      return firstFail [
        (ps.size == 20, s!"{ps.size} periods"),
        (endMins ps == wantEnds 8750 20, s!"the ends are {endMins ps}"),
        ((endMins ps).getLast? == some 525600, s!"the last period ends at {(endMins ps).getLast?}")] },
  { name := "CAP-forecast.R1 a fetch at hour 8759 has 2 periods that end at 525570 and 525600 minutes",
    run := do
      let ps := fc 1.0 8759
      return if endMins ps == [525570, 525600] then none else some s!"the ends are {endMins ps}" },
  { name := "CAP-forecast.R1 a fetch at hour 8760 has no period",
    run := do
      let ps := fc 1.0 8760
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R1 a fetch at hour 8761 has no period",
    run := do
      let ps := fc 1.0 8761
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R1 a run of 1 day has 48 periods at hour 0, 2 at hour 23 and none at hour 24",
    run := do
      let a := forecast site45 7 1 1.0 0
      let b := forecast site45 7 1 1.0 23
      let c := forecast site45 7 1 1.0 24
      let d := forecast site45 7 0 1.0 0
      return firstFail [
        (endMins a == wantEnds 0 48, s!"hour 0 gives the ends {endMins a}"),
        (endMins b == [1410, 1440], s!"hour 23 gives the ends {endMins b}"),
        (c.size == 0, s!"hour 24 gives {c.size} periods"),
        (d.size == 0, s!"a run of 0 days gives {d.size} periods")] },
  { name := "CAP-forecast.R1 each daily fetch has the periods of its next 48 hours or of the rest of the run",
    run := do
      return firstSome [
        badShape fetches0,
        badShape fetches10,
        if fetches0.length == 92 && fetches10.length == 92 then none else some "the fetches are missing"] },
  { name := "CAP-forecast.R1 no 10% band is above its estimate and no estimate is above its 90% band in a daily fetch at 00:00",
    run := do
      return firstSome [
        badOrder fetches0,
        if maxEst fetches0 > 1.0 then none else some s!"the largest estimate is {maxEst fetches0}"] },
  { name := "CAP-forecast.R1 each sunny period of a daily fetch at 00:00 has its 10% band below and its 90% band above its estimate unless the estimate is 5 kW",
    run := do
      let n := (sunnyPeriods fetches0).length
      return firstSome [
        badStraddle fetches0,
        if n ≥ 1000 then none else some s!"only {n} sunny periods"] },
  { name := "CAP-forecast.R1 each value of a daily fetch at 00:00 is from 0 to 5 kW",
    run := do
      return firstSome [
        badRange fetches0,
        if maxEst fetches0 > 1.0 then none else some s!"the largest estimate is {maxEst fetches0}"] },
  -- The error scale of 6 makes the estimate fall below 0 and rise above 5 kW. Thus a version
  -- that does not cut the values fails here.
  { name := "CAP-forecast.R1 each value stays from 0 to 5 kW with an error scale of 6",
    run := do
      let fs := (List.range 17).map bigFetch
      return firstSome [
        badRange fs,
        if maxEst fs ≥ 4.9 then none else some s!"the largest estimate is {maxEst fs}"] },
  { name := "CAP-forecast.R1 each period with no actual power has 0 kW in all three values",
    run := do
      let pss := nightFetches.map (fun f => (f, fc 1.0 f))
      let dark := pss.foldl (fun acc (_, ps) =>
        acc + (ps.toList.filter (fun p => actualKw p.endMinute == 0.0)).length) 0
      let lit := pss.foldl (fun acc (_, ps) =>
        acc + (ps.toList.filter (fun p => p.estimateKw > 0.0)).length) 0
      return firstSome [
        pss.findSome? (fun (f, ps) => badNight f ps),
        if dark ≥ 40 && lit ≥ 20 then none
        else some s!"{dark} periods with no sun, {lit} periods with a positive estimate"] },

  -- CAP-forecast.R2
  { name := "CAP-forecast.R2 with an error scale of 0 each value of a fetch at hour 0 equals its actual power",
    run := do
      let ps := fc 0.0 0
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R2 with an error scale of 0 each value of a fetch at hour 4116 equals its actual power",
    run := do
      let ps := fc 0.0 4116
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 1.0 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R2 seed 7 gives the same forecast two times",
    run := do
      let a := fc 1.0 4116
      let b := fc 1.0 4116
      let c := fc 1.0 0
      let d := fc 1.0 0
      return firstFail [
        (a.size == 96 && c.size == 96, s!"{a.size} and {c.size} periods"),
        (samePeriods a b, "the two forecasts at hour 4116 differ"),
        (samePeriods c d, "the two forecasts at hour 0 differ"),
        (sumEst a > 1.0, s!"the estimates add up to {sumEst a}")] },
  { name := "CAP-forecast.R2 seeds 7 and 8 give a different estimate for a fetch at hour 4000",
    run := do
      let a := fc 1.0 4000
      let b := forecast site45 8 365 1.0 4000
      let differs := (List.zip a.toList b.toList).any (fun (x, y) => !(x.estimateKw == y.estimateKw))
      return firstFail [
        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
        (differs, "each estimate is the same for the two seeds")] },
  -- The two seeds also have two scenarios. Thus this check compares the error of each period
  -- with its own actual power. A version with the same random numbers for each seed fails.
  { name := "CAP-forecast.R2 seeds 7 and 8 give different errors for a fetch at hour 4000",
    run := do
      let a := fc 1.0 4000
      let b := forecast site45 8 365 1.0 4000
      let usable := (List.zip a.toList b.toList).filter (fun (x, y) =>
        scen7[hourOf x.endMinute]!.pvKwh > 0.0 && scen8[hourOf y.endMinute]!.pvKwh > 0.0 &&
        x.estimateKw > 0.0 && x.estimateKw < 5.0 && y.estimateKw > 0.0 && y.estimateKw < 5.0)
      let differ := usable.filter (fun (x, y) =>
        !near ((x.estimateKw - scen7[hourOf x.endMinute]!.pvKwh) / scen7[hourOf x.endMinute]!.pvKwh)
          ((y.estimateKw - scen8[hourOf y.endMinute]!.pvKwh) / scen8[hourOf y.endMinute]!.pvKwh) 1e-9)
      return firstFail [
        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
        (usable.length ≥ 10, s!"only {usable.length} periods with sun and an uncut estimate in both"),
        (differ.length ≥ 10, s!"the error differs in {differ.length} of {usable.length} periods")] },
  -- The line of the spec. The two groups have the same hours of the day, but the days of each
  -- group can have a different amount of sun. Thus a version with no growth can also pass
  -- this check. The next check does not have this gap.
  { name := "CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is more than the error 0 to 4 hours ahead",
    run := do
      let both := fetches0 ++ fetches10
      let a := noonValues both 0 240 absErr
      let b := noonValues both 1440 2880 absErr
      if a.length < 100 || b.length < 100 then
        return some s!"too few sunny periods: {a.length} and {b.length}"
      let ma := meanOf a
      let mb := meanOf b
      return if mb > ma then none
        else some s!"error 0 to 4 hours ahead {ma} kW, 24 to 48 hours ahead {mb} kW" },
  -- The mean error as a share of the actual power is the spread times 0.80 for any sky. The
  -- model gives about 2.5 times. A version with no growth gives about 1 time, and the number
  -- of periods moves that by less than 0.1. The bound of 1.5 times leaves a large margin.
  { name := "CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is more than 1.5 times the error 0 to 4 hours ahead as a share of the actual power",
    run := do
      let both := fetches0 ++ fetches10
      let a := noonValues both 0 240 relErr
      let b := noonValues both 1440 2880 relErr
      if a.length < 100 || b.length < 100 then
        return some s!"too few sunny periods: {a.length} and {b.length}"
      let ma := meanOf a
      let mb := meanOf b
      return if mb > 1.5 * ma then none
        else some s!"share 0 to 4 hours ahead {ma}, 24 to 48 hours ahead {mb}" },
  -- The spread is 0.05 to 0.067 at 0 to 4 hours ahead. The mean of |z| for a normal curve is
  -- 0.80, so the mean relative error is 0.04 to 0.05.
  { name := "CAP-forecast.R2 the error of sunny periods 0 to 4 hours ahead is 3% to 6.5% of the actual power",
    run := do
      let a := noonValues (fetches0 ++ fetches10) 0 240 relErr
      if a.length < 100 then return some s!"too few sunny periods: {a.length}"
      let m := meanOf a
      return if m ≥ 0.030 && m ≤ 0.065 then none else some s!"mean relative error {m}" },
  -- The spread is 0.15 to 0.21 at 24 to 38 hours ahead. The mean relative error is 0.11 to
  -- 0.14. A fetch at noon cuts a few estimates at 5 kW, so the bounds are wide.
  { name := "CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is 8% to 20% of the actual power",
    run := do
      let b := noonValues (fetches0 ++ fetches10) 1440 2880 relErr
      if b.length < 100 then return some s!"too few sunny periods: {b.length}"
      let m := meanOf b
      return if m ≥ 0.08 && m ≤ 0.20 then none else some s!"mean relative error {m}" },
  -- A sunny period has an actual power of more than 0 kW, so the periods of dawn, dusk and
  -- overcast skies count. The share of the model is about 80% for each of them.
  { name := "CAP-forecast.R2 60% to 95% of sunny periods of a daily fetch at 00:00 have the actual power in the band",
    run := do
      let xs := sunnyPeriods fetches0
      let n := xs.length
      let k := (xs.filter (fun (_, p) => inBand p)).length
      if n < 1000 then return some s!"only {n} sunny periods"
      return if k.toFloat ≥ 0.6 * n.toFloat && k.toFloat ≤ 0.95 * n.toFloat then none
        else some s!"{k} of {n} sunny periods have the actual power in the band" },
  { name := "CAP-forecast.R2 the bands are 1.28 times the error scale times the spread on each side of the estimate",
    run := do
      return firstSome [bandsFor 1.0, bandsFor 2.0, bandsFor 0.5] },

  -- CAP-forecast.R3
  { name := "CAP-forecast.R3 10 fetches a day are at hours 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21",
    run := do
      let got := (fetchHours 10).toList
      return if got == [0, 2, 4, 7, 9, 12, 14, 16, 19, 21] then none else some s!"got {got}" },
  { name := "CAP-forecast.R3 3 fetches a day are at hours 0, 8 and 16",
    run := do
      let got := (fetchHours 3).toList
      return if got == [0, 8, 16] then none else some s!"got {got}" },
  { name := "CAP-forecast.R3 1 fetch a day is at hour 0",
    run := do
      let got := (fetchHours 1).toList
      return if got == [0] then none else some s!"got {got}" },
  -- Fetch i of n is at i × 24 / n rounded down. For 5, 7 and 9 fetches a day, the hours that
  -- round to the nearest hour or up differ from the hours that round down.
  { name := "CAP-forecast.R3 the fetch hours of 1 to 10 fetches a day are i × 24 / n rounded down",
    run := do
      return fetchTable.findSome? (fun (n, want) =>
        if (fetchHours n).toList == want then none
        else some s!"{n} fetches a day: got {(fetchHours n).toList}, want {want}") },
  { name := "CAP-forecast.R3 with 10 fetches a day the latest fetch for hour 27 is the fetch at hour 26",
    run := do
      let got := latestFetch 10 27
      return if got == 26 then none else some s!"got {got}" },
  { name := "CAP-forecast.R3 with 10 fetches a day the latest fetch for hour 26 is at hour 26 and for hour 25 it is at hour 24",
    run := do
      let a := latestFetch 10 26
      let b := latestFetch 10 25
      return firstFail [
        (a == 26, s!"hour 26 gives {a}"),
        (b == 24, s!"hour 25 gives {b}")] },
  { name := "CAP-forecast.R3 with 1 fetch a day the latest fetch for hour 47 is the fetch at hour 24",
    run := do
      let got := latestFetch 1 47
      return if got == 24 then none else some s!"got {got}" },
  { name := "CAP-forecast.R3 the latest fetch for other hours of 10, 3 and 1 fetches a day",
    run := do
      return latestTable.findSome? (fun (n, h, want) =>
        if latestFetch n h == want then none
        else some s!"{n} fetches a day, hour {h}: got {latestFetch n h}, want {want}") },
  { name := "CAP-forecast.R3 the latest fetch is the last fetch hour at or before the hour for 1 to 10 fetches a day and hours 0 to 239",
    run := do
      let cases := (List.range 10).foldl (fun acc i =>
        acc ++ (List.range 240).map (fun h => (i + 1, h))) []
      return cases.findSome? (fun (n, h) =>
        if latestFetch n h == wantLatest n h then none
        else some s!"{n} fetches a day, hour {h}: got {latestFetch n h}, want {wantLatest n h}") },

  -- CAP-forecast.R4
  { name := "CAP-forecast.R4 longitude 0 and a fetch at hour 0 give a first period that ends at 2025-01-01T00:30:00.0000000Z",
    run := do
      let got := firstEnd 0.0 0
      return if got == some "2025-01-01T00:30:00.0000000Z" then none else some s!"got {got}" },
  { name := "CAP-forecast.R4 longitude 174.8 and a fetch at hour 0 give a first period that ends at 2024-12-31T13:00:00.0000000Z",
    run := do
      let got := firstEnd 174.8 0
      return if got == some "2024-12-31T13:00:00.0000000Z" then none else some s!"got {got}" },
  { name := "CAP-forecast.R4 longitude -75 and a fetch at hour 0 give a first period that ends at 2025-01-01T05:30:00.0000000Z",
    run := do
      let got := firstEnd (-75.0) 0
      return if got == some "2025-01-01T05:30:00.0000000Z" then none else some s!"got {got}" },
  { name := "CAP-forecast.R4 longitude 0 and a fetch at hour 8759 give a last period that ends at 2026-01-01T00:00:00.0000000Z",
    run := do
      let es := jsonEnds (forecastJson (fc 1.0 8759) 0.0)
      return firstFail [
        (es.getLast? == some "2026-01-01T00:00:00.0000000Z", s!"the last period ends at {es.getLast?}"),
        (es.head? == some "2025-12-31T23:30:00.0000000Z", s!"the first period ends at {es.head?}"),
        (es.length == 2, s!"{es.length} periods")] },
  { name := "CAP-forecast.R4 with an error scale of 0 each value of a fetch at hour 4116 has four decimals",
    run := do
      let ps := fc 0.0 4116
      let js := forecastJson ps 0.0
      return firstSome [
        if ps.size == 96 && sumEst ps > 1.0 then none
        else some s!"{ps.size} periods, the estimates add up to {sumEst ps}",
        badValues js "pv_estimate" ps (fun p => p.estimateKw),
        badValues js "pv_estimate10" ps (fun p => p.p10Kw),
        badValues js "pv_estimate90" ps (fun p => p.p90Kw)] },
  { name := "CAP-forecast.R4 a value with more digits has four decimals in the text",
    run := do
      let ps := #[mkP 30 0.12346 0.00004 0.99996]
      let js := forecastJson ps 0.0
      return firstSome [
        badValues js "pv_estimate" ps (fun p => p.estimateKw),
        badValues js "pv_estimate10" ps (fun p => p.p10Kw),
        badValues js "pv_estimate90" ps (fun p => p.p90Kw)] },
  { name := "CAP-forecast.R4 a fetch at hour 0 has the five fields of each period in order and \"period\":\"PT30M\"",
    run := do
      let js := forecastJson (fc 1.0 0) 0.0
      return match jsonTokens js with
        | none => some "the text is not {\"forecasts\":[ then the periods then ]}"
        | some ts =>
          if ts.length != 480 then some s!"{ts.length} fields, want 480"
          else match (List.range 480).find? (fun j => !tokenOk j (ts.getD j "")) with
            | some j => some s!"field {j} is {repr (ts.getD j "")}"
            | none => none },
  { name := "CAP-forecast.R4 the period ends of a fetch at hour 0 run from 2025-01-01T00:30 to 2025-01-03T00:00 and have the Solcast form",
    run := do
      let es := jsonEnds (forecastJson (fc 1.0 0) 0.0)
      return firstFail [
        (es == (wantEnds 0 96).map isoJan, s!"the ends are {es}"),
        (es.all isIso, "a period end does not have the form 2025-01-01T00:30:00.0000000Z")] },
  { name := "CAP-forecast.R4 the text of a fetch is one line with no spaces",
    run := do
      let js := forecastJson (fc 1.0 4116) 0.0
      return firstFail [
        (js.startsWith jsonPrefix && js.endsWith "]}", "the text has the wrong frame"),
        (!(js.toList.contains ' '), "the text has a space"),
        (!(js.toList.contains '\n') && !(js.toList.contains '\r'), "the text has a line break")] },
  { name := "CAP-forecast.R4 periods with values that need no rounding give the exact text",
    run := do
      let got := forecastJson handExact 0.0
      return if got == handExactText then none else some s!"got {got}" },
  { name := "CAP-forecast.R4 no period gives the text {\"forecasts\":[]}",
    run := do
      let got := forecastJson #[] 0.0
      return if got == "{\"forecasts\":[]}" then none else some s!"got {got}" },
  -- The UTC time is the solar time less the longitude over 15 hours, to the nearest 30 minutes.
  -- A longitude of 12 gives 48 minutes, and 100 gives 400 minutes. Cutting down or up gives
  -- another time.
  { name := "CAP-forecast.R4 the UTC time rounds to the nearest 30 minutes",
    run := do
      let cases : List (Float × String) := [
        (12.0, "2024-12-31T23:30:00.0000000Z"), (-12.0, "2025-01-01T01:30:00.0000000Z"),
        (100.0, "2024-12-31T18:00:00.0000000Z"), (-100.0, "2025-01-01T07:00:00.0000000Z")]
      return cases.findSome? (fun (lon, want) =>
        if endAt30 lon == some want then none
        else some s!"longitude {lon}: got {endAt30 lon}, want {want}") },
  -- A tie rounds up, to the later time. The period ends at 00:30 solar time. A longitude of
  -- 3.75 gives a shift of exactly 15 minutes, 11.25 gives 45 and 18.75 gives 75. The UTC time
  -- is then 00:15, 23:45 and 23:15, each half way between two marks. A negative longitude
  -- gives the UTC times 00:45, 01:15 and 01:45. A version that rounds a tie down, that rounds
  -- the shift instead of the UTC time, or that rounds a tie away from 0, gets a time wrong.
  -- A longitude 0.01 degrees from a tie is not a tie, and it rounds to the near mark.
  { name := "CAP-forecast.R4 a tie of the UTC time rounds up",
    run := do
      let cases : List (Float × String) := [
        (3.75, "2025-01-01T00:30:00.0000000Z"), (11.25, "2025-01-01T00:00:00.0000000Z"),
        (18.75, "2024-12-31T23:30:00.0000000Z"), (-3.75, "2025-01-01T01:00:00.0000000Z"),
        (-11.25, "2025-01-01T01:30:00.0000000Z"), (-18.75, "2025-01-01T02:00:00.0000000Z"),
        (3.74, "2025-01-01T00:30:00.0000000Z"), (3.76, "2025-01-01T00:00:00.0000000Z"),
        (-3.74, "2025-01-01T00:30:00.0000000Z"), (-3.76, "2025-01-01T01:00:00.0000000Z")]
      return cases.findSome? (fun (lon, want) =>
        if endAt30 lon == some want then none
        else some s!"longitude {lon}: got {endAt30 lon}, want {want}") },
  { name := "CAP-forecast.R4 the period ends follow the days of each month of 2025",
    run := do
      let cases : List (Nat × String) := [
        (744, "2025-02-01T00:30:00.0000000Z"), (1416, "2025-03-01T00:30:00.0000000Z"),
        (2160, "2025-04-01T00:30:00.0000000Z"), (4116, "2025-06-21T12:30:00.0000000Z"),
        (5088, "2025-08-01T00:30:00.0000000Z"), (5832, "2025-09-01T00:30:00.0000000Z"),
        (8016, "2025-12-01T00:30:00.0000000Z")]
      return cases.findSome? (fun (f, want) =>
        let got := (jsonEnds (forecastJson #[mkP (60 * f + 30) 1.0 0.5 1.5] 0.0)).head?
        if got == some want then none else some s!"hour {f}: got {got}, want {want}") },

  -- CAP-forecast.R5
  { name := "CAP-forecast.R5 with an error scale of 0 value j of a fetch at hour 0 is the solar output of hour j",
    run := do
      let v := hourlyEnergy (fc 0.0 0) 0
      return firstSome [
        energyFails v (fun j => scen7[j]!.pvKwh) 1e-6,
        if sumArr v > 0.5 then none else some s!"the values add up to {sumArr v}"] },
  { name := "CAP-forecast.R5 with an error scale of 0 value j of a fetch at hour 4116 is the solar output of hour 4116 + j",
    run := do
      let v := hourlyEnergy (fc 0.0 4116) 4116
      return firstSome [
        energyFails v (fun j => scen7[4116 + j]!.pvKwh) 1e-6,
        if sumArr v > 2.0 then none else some s!"the values add up to {sumArr v}"] },
  { name := "CAP-forecast.R5 a fetch at hour 4116 gives 48 values from 0 to 5 kWh",
    run := do
      let v := hourlyEnergy (fc 1.0 4116) 4116
      let bad := (List.range 48).find? (fun j => !okVal (v.getD j (-1.0)))
      return firstFail [
        (v.size == 48, s!"{v.size} values"),
        (bad.isNone, s!"value {bad.getD 0} is {v.getD (bad.getD 0) (-1.0)}"),
        (sumArr v > 1.0, s!"the values add up to {sumArr v}")] },
  { name := "CAP-forecast.R5 a fetch at hour 8750 gives 48 values and values 10 to 47 are 0 kWh",
    run := do
      let v := hourlyEnergy (fc 1.0 8750) 8750
      let late := (List.range 38).find? (fun i => !near (v.getD (10 + i) 1.0) 0.0 1e-9)
      return firstFail [
        (v.size == 48, s!"{v.size} values"),
        (late.isNone, s!"value {10 + late.getD 0} is {v.getD (10 + late.getD 0) 1.0}"),
        (v.getD 0 0.0 > 0.01, s!"value 0 is {v.getD 0 0.0}")] },
  { name := "CAP-forecast.R5 with an error scale of 0 the values 0 to 9 of a fetch at hour 8750 are the solar output of hours 8750 to 8759",
    run := do
      let v := hourlyEnergy (fc 0.0 8750) 8750
      return energyFails v (fun j => if j < 10 then scen7[8750 + j]!.pvKwh else 0.0) 1e-6 },
  { name := "CAP-forecast.R5 a fetch at hour 8760 gives 48 values of 0 kWh",
    run := do
      let v := hourlyEnergy (fc 1.0 8760) 8760
      let w := hourlyEnergy (fc 1.0 8761) 8761
      return firstSome [
        energyFails v (fun _ => 0.0) 1e-12,
        energyFails w (fun _ => 0.0) 1e-12] },
  { name := "CAP-forecast.R5 no period gives 48 values of 0 kWh",
    run := do
      let v := hourlyEnergy #[] 100
      return energyFails v (fun _ => 0.0) 1e-12 },
  { name := "CAP-forecast.R5 the sum of the 48 values of a fetch at hour 4116 is 0.5 times the sum of the 96 estimates",
    run := do
      let ps := fc 1.0 4116
      let v := hourlyEnergy ps 4116
      return firstFail [
        (v.size == 48 && ps.size == 96, s!"{v.size} values, {ps.size} periods"),
        (sumEst ps > 1.0, s!"the estimates add up to {sumEst ps}"),
        (near (sumArr v) (0.5 * sumEst ps) 1e-6,
          s!"the values add up to {sumArr v}, half of the estimates is {0.5 * sumEst ps}")] },
  -- Hours 102 and 103 have no period, so a version that reads the periods by position fails.
  -- The bands differ from the estimate, so a version that reads a band fails.
  { name := "CAP-forecast.R5 each value is half the two estimates of its hour and an hour with no period is 0 kWh",
    run := do
      let want := fun (j : Nat) =>
        if j == 0 then 2.5 else if j == 1 then 3.0 else if j == 4 then 3.0 else 0.0
      return energyFails (hourlyEnergy handEnergyA 100) want 1e-9 },
  { name := "CAP-forecast.R5 the values 0 and 47 are the hours fetchHour and fetchHour + 47",
    run := do
      let want := fun (j : Nat) => if j == 0 then 2.0 else if j == 47 then 5.0 else 0.0
      return energyFails (hourlyEnergy handEnergyB 4116) want 1e-9 }
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
