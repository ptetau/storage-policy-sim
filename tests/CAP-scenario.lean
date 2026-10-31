/-
Component checks of CAP-scenario (sun, weather and load), for CH-0001 (seasonal sun, daily
weather and household load).

The checks call only `Sky`, `Sky.factor`, `Site`, `Hour`, `pvOutput` and `scenario`. No entry
of the Interface can fail, so no check expects an error code. The `seed` argument of
`scenario` is the only seam. No check uses the clock.
-/
import StoragePolicySim.Scenario
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

-- Helpers for the library

/-- The site of the lines: 5 kW of panels, and 20 kWh of daily load with 3 kWh flexible. -/
def site (lat : Float) (pv : Float := 5) (flex : Float := 3) (load : Float := 20) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }

def noon (s : Site) (day : Nat) (sky : Sky) : Float := pvOutput s day 12 sky

/-- The base load of one day of the run. -/
def dayBase (hs : Array Hour) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc i => acc + hs[d * 24 + i]!.baseLoadKwh) 0

def totalLoad (hs : Array Hour) : Float :=
  hs.foldl (fun acc h => acc + h.baseLoadKwh + h.flexKwh) 0

/-- The number of overcast days in the days that `inDays` selects, for seeds 1 to 20. -/
def overcastDays (lat : Float) (inDays : Nat → Bool) : Nat :=
  (List.range 20).foldl (fun acc i =>
    let hs := scenario (site lat) (i + 1) 365
    acc + ((List.range 365).filter (fun d =>
      inDays d && hs[d * 24]!.sky == Sky.overcast)).length) 0

-- Day of the year 0 is 1 January. A year has 365 days.
def inDecToFeb (d : Nat) : Bool := d ≤ 58 || d ≥ 334
def inJunToAug (d : Nat) : Bool := 151 ≤ d && d ≤ 242

def sameHour (a b : Hour) : Bool :=
  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh

/-- Finds the first item whose solar output is not the seasonal sun of its hour. -/
def badSolar (s : Site) (hs : Array Hour) : Option Nat :=
  (List.range hs.size).find? (fun i =>
    let h := hs[i]!
    !near h.pvKwh (pvOutput s h.dayOfYear h.hour h.sky) 0.000001)

/-- Finds the first hour whose flexible load is not `each` kWh at 18:00, 19:00 and 20:00. -/
def badFlex (hs : Array Hour) (each : Float) : Option Nat :=
  (List.range hs.size).find? (fun i =>
    let want : Float := if i % 24 == 18 || i % 24 == 19 || i % 24 == 20 then each else 0
    !near hs[i]!.flexKwh want 1e-9)

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354",
    run := do
      let a := noon (site 45) 171 Sky.sunny
      let b := noon (site 45) 354 Sky.sunny
      return if b > 0 && a > 2 * b then none else some s!"day 171 {a}, day 354 {b}" },
  { name := "CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171",
    run := do
      let a := noon (site (-41)) 354 Sky.sunny
      let b := noon (site (-41)) 171 Sky.sunny
      return if b > 0 && a > 2 * b then none else some s!"day 354 {a}, day 171 {b}" },
  { name := "CAP-scenario.R1 at latitude 0 days 171 and 354 differ by less than 1%",
    run := do
      let a := noon (site 0) 171 Sky.sunny
      let b := noon (site 0) 354 Sky.sunny
      let big := if a > b then a else b
      return if a > 0 && b > 0 && (a - b).abs < 0.01 * big then none
        else some s!"day 171 {a}, day 354 {b}" },
  { name := "CAP-scenario.R1 at latitude 45 00:00 of day 171 gives 0 kWh",
    run := do
      let v := pvOutput (site 45) 171 0 Sky.sunny
      return if v == 0 then none else some s!"got {v}" },
  { name := "CAP-scenario.R1 each sunny hour of days 0 to 364 at latitude 45 gives 0 to 5 kWh",
    run := do
      let bad := (List.range (365 * 24)).find? (fun i =>
        let v := pvOutput (site 45) (i / 24) (i % 24) Sky.sunny
        !(v ≥ 0 && v ≤ 5))
      return match bad with
        | some i =>
          some s!"day {i / 24} hour {i % 24} gives {pvOutput (site 45) (i / 24) (i % 24) Sky.sunny}"
        | none => none },
  -- A version that omits the panel power gives 1 kWh or less, and stays from 0 to 5 kWh.
  { name := "CAP-scenario.R1 the sunny noon of day 171 at latitude 45 uses the 5 kW of panels",
    run := do
      let full := noon (site 45) 171 Sky.sunny
      let half := noon (site 45 (pv := 2.5)) 171 Sky.sunny
      return firstFail [
        (full > 4 && full ≤ 5, s!"5 kW gives {full}"),
        (near half (0.5 * full) 0.001, s!"2.5 kW gives {half}, 5 kW gives {full}")] },
  { name := "CAP-scenario.R1 a cloudy sky gives 0.5 times the sunny output",
    run := do
      let s := noon (site 45) 171 Sky.sunny
      let c := noon (site 45) 171 Sky.cloudy
      return if s > 1 && near c (0.5 * s) 0.001 then none else some s!"sunny {s}, cloudy {c}" },
  { name := "CAP-scenario.R1 an overcast sky gives 0.15 times the sunny output",
    run := do
      let s := noon (site 45) 171 Sky.sunny
      let o := noon (site 45) 171 Sky.overcast
      return if s > 1 && near o (0.15 * s) 0.001 then none
        else some s!"sunny {s}, overcast {o}" },
  { name := "CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15",
    run := do
      return firstFail [
        (Sky.factor Sky.sunny == 1.0, s!"sunny {Sky.factor Sky.sunny}"),
        (Sky.factor Sky.cloudy == 0.5, s!"cloudy {Sky.factor Sky.cloudy}"),
        (Sky.factor Sky.overcast == 0.15, s!"overcast {Sky.factor Sky.overcast}")] },
  { name := "CAP-scenario.R1 0 kW of panels gives 0 kWh at 12:00 of day 171",
    run := do
      let v := noon (site 45 (pv := 0)) 171 Sky.sunny
      return if v == 0 then none else some s!"got {v}" },
  { name := "CAP-scenario.R1 the output does not change with the load of the site",
    run := do
      let a := noon (site 45) 171 Sky.sunny
      let b := noon (site 45 (flex := 0) (load := 99)) 171 Sky.sunny
      return if a > 0 && a == b then none else some s!"load 20 gives {a}, load 99 gives {b}" },

  -- CAP-scenario.R2
  { name := "CAP-scenario.R2 seed 7 at latitude 45 gives the same hours two times",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 7 365
      return if a.size == 8760 && b.size == 8760 &&
          (List.range 8760).all (fun i => sameHour a[i]! b[i]!) then none
        else some s!"the two runs differ, sizes {a.size} and {b.size}" },
  { name := "CAP-scenario.R2 seeds 7 and 8 at latitude 45 give different skies on at least 50 days",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 8 365
      if a.size != 8760 || b.size != 8760 then
        return some s!"sizes {a.size} and {b.size}"
      let n := ((List.range 365).filter (fun d => !(a[d * 24]!.sky == b[d * 24]!.sky))).length
      return if n ≥ 50 then none else some s!"{n} days differ" },
  { name := "CAP-scenario.R2 seed 7 and 365 days give 8760 hours in order of day, then hour",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i =>
            !(hs[i]!.day == i / 24 && hs[i]!.hour == i % 24)) with
          | some i => some s!"item {i} is day {hs[i]!.day} hour {hs[i]!.hour}"
          | none => none },
  { name := "CAP-scenario.R2 seed 7 and 0 days give no hours",
    run := do
      let hs := scenario (site 45) 7 0
      return if hs.size == 0 then none else some s!"{hs.size} hours" },
  { name := "CAP-scenario.R2 seed 7 and 1 day give the 24 hours of day 0",
    run := do
      let hs := scenario (site 45) 7 1
      return if hs.size == 24 && (List.range 24).all (fun i =>
          hs[i]!.day == 0 && hs[i]!.dayOfYear == 0 && hs[i]!.hour == i) then none
        else some s!"{hs.size} hours" },
  { name := "CAP-scenario.R2 the 24 hours of each day have the same sky",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i => !(hs[i]!.sky == hs[(i / 24) * 24]!.sky)) with
          | some i => some s!"day {i / 24} hour {i % 24} has a different sky"
          | none => none },
  { name := "CAP-scenario.R2 each solar output of seed 7 equals the seasonal sun of its hour",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badSolar (site 45) hs with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R2 each solar output at latitude -41 equals the seasonal sun of its hour",
    run := do
      let hs := scenario (site (-41)) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badSolar (site (-41)) hs with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R2 at latitude 45 December to February has over twice the overcast days",
    run := do
      let w := overcastDays 45 inDecToFeb
      let s := overcastDays 45 inJunToAug
      return if w > 2 * s then none else some s!"Dec to Feb {w}, Jun to Aug {s}" },
  { name := "CAP-scenario.R2 at latitude -41 June to August has over twice the overcast days",
    run := do
      let w := overcastDays (-41) inJunToAug
      let s := overcastDays (-41) inDecToFeb
      return if w > 2 * s then none else some s!"Jun to Aug {w}, Dec to Feb {s}" },
  -- With no chance to keep the sky, about 40% of the days keep the sky of the day before.
  { name := "CAP-scenario.R2 60% or more of days 1 to 364 of seed 7 keep the previous sky",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let n := ((List.range 364).filter (fun d =>
        hs[(d + 1) * 24]!.sky == hs[d * 24]!.sky)).length
      return if n.toFloat ≥ 0.6 * 364 then none else some s!"{n} of 364 days keep" },
  { name := "CAP-scenario.R2 with 730 days day 365 is day 0 and day 729 is day 364 of the year",
    run := do
      let hs := scenario (site 45) 7 730
      if hs.size != 730 * 24 then return some s!"{hs.size} hours"
      return firstFail [
        (hs[365 * 24]!.day == 365 && hs[365 * 24]!.dayOfYear == 0,
          s!"item {365 * 24} is day {hs[365 * 24]!.day}, day {hs[365 * 24]!.dayOfYear} of the year"),
        (hs[729 * 24 + 23]!.day == 729 && hs[729 * 24 + 23]!.dayOfYear == 364,
          s!"the last item is day {hs[729 * 24 + 23]!.day}, day {hs[729 * 24 + 23]!.dayOfYear} of the year"),
        ((List.range hs.size).all (fun i =>
            hs[i]!.day == i / 24 && hs[i]!.dayOfYear == (i / 24) % 365 && hs[i]!.hour == i % 24),
          "an hour has the wrong day, day of the year or hour")] },
  { name := "CAP-scenario.R2 with 730 days the solar output of the second year uses the day of the year",
    run := do
      let hs := scenario (site 45) 7 730
      return if hs.size != 730 * 24 then some s!"{hs.size} hours"
        else match badSolar (site 45) hs with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },

  -- CAP-scenario.R3
  { name := "CAP-scenario.R3 365 days at latitude 45 have 7300 kWh of load",
    run := do
      let hs := scenario (site 45) 7 365
      let t := totalLoad hs
      return if hs.size == 8760 && near t 7300 0.1 then none else some s!"total {t}" },
  -- The daily load includes the flexible load. Thus, 0 kWh of flexible load keeps 7300 kWh.
  { name := "CAP-scenario.R3 365 days with 0 kWh of flexible load also have 7300 kWh of load",
    run := do
      let hs := scenario (site 45 (flex := 0)) 7 365
      let t := totalLoad hs
      return if hs.size == 8760 && near t 7300 0.1 then none else some s!"total {t}" },
  { name := "CAP-scenario.R3 at latitude 45 day 15 has 1.45 to 1.55 times the base load of day 197",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let q := dayBase hs 15 / dayBase hs 197
      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
  { name := "CAP-scenario.R3 at latitude -41 day 197 has 1.45 to 1.55 times the base load of day 15",
    run := do
      let hs := scenario (site (-41)) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let q := dayBase hs 197 / dayBase hs 15
      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
  { name := "CAP-scenario.R3 on day 100 the base load at 19:00 is more than at 13:00",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let a := hs[100 * 24 + 19]!.baseLoadKwh
      let b := hs[100 * 24 + 13]!.baseLoadKwh
      return if a > b then none else some s!"19:00 {a}, 13:00 {b}" },
  { name := "CAP-scenario.R3 on day 100 the base load at 07:00 is more than at 03:00",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let a := hs[100 * 24 + 7]!.baseLoadKwh
      let b := hs[100 * 24 + 3]!.baseLoadKwh
      return if a > b then none else some s!"07:00 {a}, 03:00 {b}" },
  { name := "CAP-scenario.R3 3 kWh of flexible load is 1 kWh at 18:00, 19:00 and 20:00",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badFlex hs 1 with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  -- Equal parts: a version that always puts 1 kWh in each hour fails here.
  { name := "CAP-scenario.R3 6 kWh of flexible load is 2 kWh at 18:00, 19:00 and 20:00",
    run := do
      let hs := scenario (site 45 (flex := 6)) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badFlex hs 2 with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R3 0 kWh of flexible load gives 0 kWh in each hour",
    run := do
      let hs := scenario (site 45 (flex := 0)) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badFlex hs 0 with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R3 seeds 7 and 8 at latitude 45 give the same base and flexible load",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 8 365
      return if a.size == 8760 && b.size == 8760 && (List.range 8760).all (fun i =>
          a[i]!.baseLoadKwh == b[i]!.baseLoadKwh && a[i]!.flexKwh == b[i]!.flexKwh) then none
        else some "the loads differ" }
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
