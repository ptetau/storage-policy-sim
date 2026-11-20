import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim

open StoragePolicySim

/-! Slice S8: shift the flexible load and stop thrashing (R24, R25). -/

def tiny : Float := 0.000000001

def defaultPolicies (_ : Unit) : List (String × Policy) :=
  [("static", Policy.static defaultStatic),
   ("precomputed", Policy.precomputed defaultPlan),
   ("dynamic", Policy.dynamic defaultDynamic)]

def tank1 : Array TankConfig := #[defaultTank]

def staticParams (flexStart : Nat) : StaticParams :=
  { windows := #[({ heatStart := 10, heatHours := 4 } : TankWindow)], dischargeFrom := 17, flexStart := flexStart }

def dynP : DynamicParams :=
  { lowKwh := #[5.25], targetKwh := #[10.5], dischargeFrom := 17 }

def mkObs (hour : Nat) (tank surplus rest flexLeft : Float) (starts : Nat) (asked : Bool) : Observation :=
  { hour := hour, tankKwh := #[tank], socKwh := 0.0, surplusKwh := surplus,
    forecastRestKwh := rest, flexLeftKwh := flexLeft, startsToday := #[starts],
    askedLastHour := #[asked] }

def sumFlex (acts : Array Action) : Float :=
  acts.foldl (fun (s : Float) (a : Action) => s + a.flexKwh) 0.0

/-- Flexible load of day `d` of a run. -/
def dayFlex (r : HomeResult) (d : Nat) : Float := Id.run do
  let mut s := 0.0
  for h in [0:24] do
    s := s + (r.hours[24 * d + h]!).flexKwh
  return s

/-- First hour of day `d` with a flexible load, or 99 when none. -/
def firstFlexHour (r : HomeResult) (d : Nat) : Nat := Id.run do
  for h in [0:24] do
    if (r.hours[24 * d + h]!).flexKwh > tiny then return h
  return 99

/-- Number of policy starts of tank `i` in day `d` (a request after an hour with none). -/
def tankStarts (r : HomeResult) (d i : Nat) : Nat := Id.run do
  let mut n := 0
  for h in [0:24] do
    let idx := 24 * d + h
    let cur := ((r.hours[idx]!).tanks[i]!).askKwh > tiny
    let prev := if idx == 0 then false else ((r.hours[idx - 1]!).tanks[i]!).askKwh > tiny
    if cur && !prev then n := n + 1
  return n

/-- Changes of the battery gate inside day `d`. -/
def gateChanges (r : HomeResult) (d : Nat) : Nat := Id.run do
  let mut n := 0
  for h in [1:24] do
    let a := r.hours[24 * d + h]!
    let b := r.hours[24 * d + h - 1]!
    if a.allowCharge != b.allowCharge || a.allowDischarge != b.allowDischarge then n := n + 1
  return n

def homeList : List String := ["generic", "small", "family", "no-battery", "mine"]

/-- Both checks of R25 over each home, policy and seed, computed once. -/
initialize r25Cache : IO.Ref (Option (Option String × Option String)) ← IO.mkRef none

def r25Compute : IO (Option String × Option String) := do
  let mut starts : Option String := none
  let mut gate : Option String := none
  for hn in homeList do
    match homeNamed hn with
    | none =>
      if starts.isNone then starts := some s!"homeNamed {hn} gave none"
    | some home =>
      for (pn, p) in defaultPolicies () do
        for seed in [1:4] do
          let r := runHome home p seed 365
          if r.hours.size != 24 * 365 then
            if starts.isNone then starts := some s!"{hn}/{pn}/seed {seed}: {r.hours.size} hours"
          else
            for d in [0:365] do
              for i in [0:home.tanks.size] do
                let n := tankStarts r d i
                if n > 2 && starts.isNone then
                  starts := some s!"{hn}/{pn}/seed {seed}/day {d}/tank {i}: {n} starts"
              let g := gateChanges r d
              if g > 2 && gate.isNone then
                gate := some s!"{hn}/{pn}/seed {seed}/day {d}: {g} gate changes"
  return (starts, gate)

def r25Get : IO (Option String × Option String) := do
  match (← r25Cache.get) with
  | some v => return v
  | none =>
    let v ← r25Compute
    r25Cache.set (some v)
    return v

/-- Parses a non-negative decimal such as `1.5`. -/
def parseDec (s : String) : Option Float :=
  match s.splitOn "." with
  | [a] => a.toNat?.map Nat.toFloat
  | [a, b] =>
    match a.toNat?, b.toNat? with
    | some x, some y => some (x.toFloat + y.toFloat / Float.pow 10.0 b.length.toFloat)
    | _, _ => none
  | _ => none

/-- The value word of the line that starts with `label`, as typed. -/
def lineValue (out label : String) : Option String :=
  match (out.splitOn "\n").find? (fun (l : String) => l.startsWith label) with
  | none => none
  | some l =>
    let words := (l.splitOn " ").filter (fun (w : String) => w != "")
    words[1]?

def expectErr (args : List String) (want : String) : IO (Option String) := do
  let o ← Harness.sim args
  return Harness.firstFail
    [(o.code == 2, s!"{args}: exit code {o.code}, stderr {o.err}"),
     (o.out == "", s!"{args}: stdout not empty: {o.out}"),
     (o.err.trimAscii.toString == want, s!"{args}: stderr {o.err}, want {want}")]

-- R24 -----------------------------------------------------------------------

def t_flex_sum_each_day : IO (Option String) := do
  let days := 365
  for (name, p) in defaultPolicies () do
    let r := runHome defaultHome p 7 days
    if r.hours.size != 24 * days then return some s!"{name}: {r.hours.size} hours"
    for d in [0:days] do
      let s := dayFlex r d
      if !(Harness.near s 3.0 0.000001) then return some s!"{name} day {d}: flexible load {s}, want 3.0"
  return none

def t_static_profile_parts : IO (Option String) := do
  let acts := staticProfile tank1 (staticParams 11) 3.0
  let mut checks : List (Bool × String) := [(acts.size == 24, s!"size {acts.size}")]
  for h in [0:24] do
    let want := if h == 11 || h == 12 || h == 13 then 1.0 else 0.0
    let got := (acts[h]!).flexKwh
    checks := checks ++ [(Harness.near got want tiny, s!"hour {h}: flex {got}, want {want}")]
  return Harness.firstFail checks

def t_static_flex_start_run : IO (Option String) := do
  let p := Policy.static { defaultStatic with flexStart := 11 }
  let days := 30
  let r := runHome defaultHome p 7 days
  if r.hours.size != 24 * days then return some s!"{r.hours.size} hours"
  for d in [0:days] do
    let f := firstFlexHour r d
    if f != 11 then return some s!"day {d}: flexible load starts at hour {f}, want 11"
    let s := dayFlex r d
    if !(Harness.near s 3.0 0.000001) then return some s!"day {d}: flexible load {s}, want 3.0"
  return none

/-- The number after the label of a `policy run` line, parsed. -/
def runValue (out label : String) : Option Float :=
  match lineValue out label with
  | none => none
  | some w => parseDec w

def t_static_flex_start_cli : IO (Option String) := do
  let p := Policy.static { defaultStatic with flexStart := 11 }
  let r := runHome defaultHome p 7 30
  let base := ["policy", "run", "--policy", "static", "--seed", "7", "--days", "30"]
  let o11 ← Harness.sim (base ++ ["--flex-start", "11"])
  let od ← Harness.sim base
  if o11.code != 0 then return some s!"--flex-start 11: exit {o11.code}, stderr {o11.err}"
  if od.code != 0 then return some s!"default: exit {od.code}, stderr {od.err}"
  let labels : List (String × Float) :=
    [("import", r.totals.importKwh), ("self-consumption", r.totals.selfConsumption)]
  let mut differs := false
  for (label, want) in labels do
    match runValue o11.out label, runValue od.out label with
    | some a, some b =>
      if !(Harness.near a want 0.051) then
        return some s!"--flex-start 11: {label} {a}, want about {want} (runHome with flexStart 11)"
      if !(Harness.near a b 0.051) then differs := true
    | _, _ => return some s!"no {label} line in {o11.out} or {od.out}"
  if !differs then
    return some "--flex-start 11 gives the same import and self-consumption as the default run"
  return none

def t_static_flex_start_end_of_day : IO (Option String) := do
  let acts := staticProfile tank1 (staticParams 23) 3.0
  let early := (List.range 23).all (fun (h : Nat) => Harness.near (acts[h]!).flexKwh 0.0 tiny)
  let p := Policy.static { defaultStatic with flexStart := 23 }
  let days := 10
  let r := runHome defaultHome p 7 days
  if r.hours.size != 24 * days then return some s!"{r.hours.size} hours"
  for d in [0:days] do
    let s := dayFlex r d
    if !(Harness.near s 3.0 0.000001) then return some s!"day {d}: flexible load {s}, want 3.0"
    let last := (r.hours[24 * d + 23]!).flexKwh
    if !(Harness.near last 3.0 0.000001) then return some s!"day {d}: hour 23 has {last}, want 3.0"
  return Harness.firstFail
    [(acts.size == 24, s!"size {acts.size}"),
     (early, s!"flexible load before hour 23: {acts.map (fun (a : Action) => a.flexKwh)}"),
     (Harness.near (sumFlex acts) 3.0 tiny, s!"profile sum {sumFlex acts}, want 3.0"),
     (Harness.near (acts[23]!).flexKwh 3.0 tiny, s!"hour 23 flex {(acts[23]!).flexKwh}, want 3.0")]

def t_flex_start_out_of_range : IO (Option String) :=
  expectErr ["policy", "run", "--policy", "static", "--flex-start", "24"]
    "error: OUT_OF_RANGE: --flex-start 24 (0 to 23)"

def t_flex_start_negative : IO (Option String) :=
  expectErr ["policy", "run", "--flex-start", "-1"] "error: OUT_OF_RANGE: --flex-start -1 (0 to 23)"

def t_flex_start_bad_number : IO (Option String) :=
  expectErr ["policy", "run", "--flex-start", "abc"] "error: BAD_NUMBER: --flex-start abc"

def t_flex_start_missing : IO (Option String) :=
  expectErr ["policy", "run", "--flex-start"] "error: MISSING_VALUE: --flex-start"

def t_flex_start_bounds : IO (Option String) := do
  let a ← Harness.sim ["policy", "run", "--days", "5", "--flex-start", "0"]
  let b ← Harness.sim ["policy", "run", "--days", "5", "--flex-start", "23"]
  return Harness.firstFail
    [(a.code == 0, s!"--flex-start 0: exit {a.code}, stderr {a.err}"),
     (b.code == 0, s!"--flex-start 23: exit {b.code}, stderr {b.err}")]

def t_dynamic_no_surplus_from_20 : IO (Option String) := do
  let a19 := dynamicAction tank1 dynP (mkObs 19 10.5 0.0 0.0 3.0 0 false)
  let a20 := dynamicAction tank1 dynP (mkObs 20 10.5 0.0 0.0 3.0 0 false)
  let a23 := dynamicAction tank1 dynP (mkObs 23 10.5 0.0 0.0 3.0 0 false)
  return Harness.firstFail
    [(Harness.near a19.flexKwh 0.0 tiny, s!"hour 19, no surplus: flex {a19.flexKwh}, want 0"),
     (a20.flexKwh > tiny, s!"hour 20, no surplus: flex {a20.flexKwh}, want more than 0"),
     (a20.flexKwh ≤ 3.0 + tiny, s!"hour 20: flex {a20.flexKwh}, more than the 3.0 left"),
     (Harness.near a23.flexKwh 3.0 tiny, s!"hour 23 with 3.0 left: flex {a23.flexKwh}, want 3.0")]

def t_dynamic_surplus_runs_flex : IO (Option String) := do
  let a := dynamicAction tank1 dynP (mkObs 12 10.5 5.0 0.0 3.0 0 false)
  let z := dynamicAction tank1 dynP (mkObs 12 10.5 5.0 0.0 0.0 0 false)
  return Harness.firstFail
    [(a.flexKwh > tiny, s!"hour 12 with surplus 5.0: flex {a.flexKwh}, want more than 0"),
     (a.flexKwh ≤ 3.0 + tiny, s!"hour 12: flex {a.flexKwh}, more than the 3.0 left"),
     (Harness.near z.flexKwh 0.0 tiny, s!"nothing left: flex {z.flexKwh}, want 0")]

def t_dynamic_run_no_surplus_day : IO (Option String) := do
  let home := { defaultHome with arrays := #[({ kw := 0.0, direction := 0.0, tilt := 0.0 } : PanelArray)], site := { defaultHome.site with pvKw := 0.0 } }
  let days := 60
  let r := runHome home (Policy.dynamic defaultDynamic) 7 days
  if r.hours.size != 24 * days then return some s!"{r.hours.size} hours"
  for d in [0:days] do
    let f := firstFlexHour r d
    if f != 20 then return some s!"day {d}: flexible load starts at hour {f}, want 20"
    let s := dayFlex r d
    if !(Harness.near s 3.0 0.000001) then return some s!"day {d}: flexible load {s}, want 3.0"
  return none

def flexForecast : Array Float :=
  (List.range 24).toArray.map (fun (h : Nat) =>
    if h == 12 then 5.0 else if h == 13 then 4.0 else if h == 14 then 3.0 else 0.0)

def t_precomputed_flex_sunny_hours : IO (Option String) := do
  let params : PlanParams := { targetKwh := #[10.5], minSolarKwh := 0.5, dischargeFrom := 17 }
  let acts := planDay tank1 params flexForecast #[10.5] #[0.0] 3.0
  let outside := (List.range 24).all (fun (h : Nat) =>
    (h >= 12 && h <= 14) || Harness.near (acts[h]!).flexKwh 0.0 tiny)
  return Harness.firstFail
    [(acts.size == 24, s!"size {acts.size}"),
     (Harness.near (sumFlex acts) 3.0 tiny, s!"flex sum {sumFlex acts}, want 3.0"),
     ((acts[12]!).flexKwh > tiny, s!"hour 12 (sunniest) has flex {(acts[12]!).flexKwh}"),
     (outside, s!"flex outside hours 12 to 14: {acts.map (fun (a : Action) => a.flexKwh)}")]

-- R25 -----------------------------------------------------------------------

def t_tank_starts_at_most_2 : IO (Option String) := do
  let (s, _) ← r25Get
  return s

def t_gate_changes_at_most_2 : IO (Option String) := do
  let (_, g) ← r25Get
  return g

def t_starts_per_day_value : IO (Option String) := do
  let days := 30
  for (name, p) in defaultPolicies () do
    let o ← Harness.sim ["policy", "run", "--policy", name, "--days", "30", "--seed", "9"]
    if o.code != 0 then return some s!"{name}: exit {o.code}, stderr {o.err}"
    let r := runHome defaultHome p 9 days
    let want := r.totals.policyStarts.toFloat / days.toFloat
    match lineValue o.out "starts-per-day" with
    | none => return some s!"{name}: no starts-per-day line in {o.out}"
    | some w =>
      match parseDec w with
      | none => return some s!"{name}: starts-per-day value {w} is not a number"
      | some v =>
        if (w.splitOn ".").length != 2 || ((w.splitOn ".")[1]!).length != 1 then
          return some s!"{name}: starts-per-day {w} is not one decimal"
        if !(Harness.near v want 0.050000001) then
          return some s!"{name}: starts-per-day {w}, want about {want}"
  return none

def t_starts_per_day_default_run : IO (Option String) := do
  let o ← Harness.sim ["policy", "run"]
  if o.code != 0 then return some s!"exit {o.code}, stderr {o.err}"
  let r := runHome defaultHome (Policy.static defaultStatic) 1 365
  let want := r.totals.policyStarts.toFloat / (365.0 : Float)
  match lineValue o.out "starts-per-day" with
  | none => return some s!"no starts-per-day line in {o.out}"
  | some w =>
    match parseDec w with
    | none => return some s!"starts-per-day value {w} is not a number"
    | some v =>
      return Harness.firstFail
        [(Harness.near v want 0.050000001, s!"starts-per-day {w}, want about {want}"),
         (r.totals.policyStarts > 0, s!"the static policy has {r.totals.policyStarts} starts in 365 days")]

-- R25 machine ElementSchedule -----------------------------------------------

def t_T1_idle_to_requested : IO (Option String) := do
  let a0 := dynamicAction tank1 dynP (mkObs 12 5.0 5.0 0.0 0.0 0 false)
  let a1 := dynamicAction tank1 dynP (mkObs 12 5.0 5.0 0.0 0.0 1 false)
  return Harness.firstFail
    [((a0.heatKwh[0]!) > tiny, s!"0 starts: request {a0.heatKwh}, want more than 0"),
     ((a1.heatKwh[0]!) > tiny, s!"1 start: request {a1.heatKwh}, want more than 0")]

def t_T2_requested_to_idle : IO (Option String) := do
  let a := dynamicAction tank1 dynP (mkObs 12 10.5 5.0 0.0 0.0 1 true)
  return Harness.firstFail
    [(Harness.near (a.heatKwh[0]!) 0.0 tiny, s!"tank at the target after a request: request {a.heatKwh}, want 0")]

def t_X1_third_start_refused : IO (Option String) := do
  let a := dynamicAction tank1 dynP (mkObs 12 5.0 5.0 0.0 0.0 2 false)
  let b := dynamicAction tank1 dynP (mkObs 12 3.0 0.0 0.0 0.0 2 false)
  return Harness.firstFail
    [(Harness.near (a.heatKwh[0]!) 0.0 tiny, s!"2 starts, surplus 5.0, tank 5.0: request {a.heatKwh}, want 0"),
     (Harness.near (b.heatKwh[0]!) 0.0 tiny, s!"2 starts, low tank, no surplus: request {b.heatKwh}, want 0")]

def t_dynamic_keeps_heating_instead_of_third_start : IO (Option String) := do
  let a := dynamicAction tank1 dynP (mkObs 14 6.0 0.0 5.0 0.0 2 true)
  return Harness.firstFail
    [((a.heatKwh[0]!) > tiny, s!"2 starts, asked last hour, no surplus, tank 6.0: request {a.heatKwh}, want more than 0"),
     ((a.heatKwh[0]!) ≤ 3.0 + tiny, s!"request {a.heatKwh}, more than the element power 3.0")]

def t_dynamic_no_third_start_not_needed : IO (Option String) := do
  let a := dynamicAction tank1 dynP (mkObs 14 8.0 0.0 5.0 0.0 1 true)
  return Harness.firstFail
    [(Harness.near (a.heatKwh[0]!) 0.0 tiny,
      s!"1 start, asked last hour, no surplus, tank 8.0 (above low 5.25): request {a.heatKwh}, want 0")]

def afterTankForecast : Array Float :=
  (List.range 24).toArray.map (fun (h : Nat) =>
    if h == 12 then 4.0 else if h == 13 then 3.9 else if h == 14 then 3.8
    else if h == 15 then 3.0 else 0.0)

def t_precomputed_flex_after_tanks : IO (Option String) := do
  let params : PlanParams := { targetKwh := #[10.5], minSolarKwh := 0.5, dischargeFrom := 17 }
  let acts := planDay tank1 params afterTankForecast #[7.5] #[0.0] 3.0
  if acts.size != 24 then return some s!"size {acts.size}"
  let heat := acts.map (fun (a : Action) => a.heatKwh[0]!)
  let left := (List.range 24).toArray.map (fun (h : Nat) =>
    let x := afterTankForecast[h]! - heat[h]!
    if x < 0.0 then 0.0 else x)
  if !(heat.foldl (fun (s : Float) (x : Float) => s + x) 0.0 > tiny) then
    return some s!"the plan heats nothing: {heat}"
  if !(Harness.near (sumFlex acts) 3.0 tiny) then return some s!"flex sum {sumFlex acts}, want 3.0"
  for h in [0:24] do
    if (acts[h]!).flexKwh > tiny then
      for g in [0:24] do
        if (acts[g]!).flexKwh ≤ tiny && left[g]! > left[h]! + tiny then
          return some s!"flex in hour {h} (forecast left {left[h]!}) but not in hour {g} (forecast left {left[g]!}): flex {acts.map (fun (a : Action) => a.flexKwh)}, heat {heat}"
  return none

def planStarts (heat : Array Float) : Nat := Id.run do
  let mut n := 0
  for h in [0:heat.size] do
    let cur := heat[h]! > tiny
    let prev := if h == 0 then false else heat[h - 1]! > tiny
    if cur && !prev then n := n + 1
  return n

def scatterForecast : Array Float :=
  (List.range 24).toArray.map (fun (h : Nat) =>
    if h == 9 || h == 11 || h == 13 || h == 15 || h == 16 then 4.0
    else if h == 10 || h == 12 || h == 14 then 0.1 else 0.0)

def t_precomputed_plan_at_most_2_starts : IO (Option String) := do
  let params : PlanParams := { targetKwh := #[10.5], minSolarKwh := 0.5, dischargeFrom := 17 }
  let acts := planDay tank1 params scatterForecast #[4.0] #[6.0] 3.0
  let heat := acts.map (fun (a : Action) => a.heatKwh[0]!)
  return Harness.firstFail
    [(acts.size == 24, s!"size {acts.size}"),
     (planStarts heat ≤ 2, s!"{planStarts heat} starts in the plan {heat}"),
     (heat.foldl (fun (s : Float) (x : Float) => s + x) 0.0 > tiny, s!"the plan heats nothing: {heat}")]

def tests : List Harness.Test := [
  { name := "test_001_S8_R24_flex_load_adds_up_each_day", run := t_flex_sum_each_day },
  { name := "test_001_S8_R24_static_profile_flex_in_three_parts", run := t_static_profile_parts },
  { name := "test_001_S8_R24_static_flex_start_11_in_run", run := t_static_flex_start_run },
  { name := "test_001_S8_R24_static_flex_start_11_changes_command_output", run := t_static_flex_start_cli },
  { name := "test_001_S8_R24_static_flex_start_23_stays_in_day", run := t_static_flex_start_end_of_day },
  { name := "test_001_S8_R24_flex_start_24_out_of_range", run := t_flex_start_out_of_range },
  { name := "test_001_S8_R24_flex_start_negative_out_of_range", run := t_flex_start_negative },
  { name := "test_001_S8_R24_flex_start_not_a_number", run := t_flex_start_bad_number },
  { name := "test_001_S8_R24_flex_start_missing_value", run := t_flex_start_missing },
  { name := "test_001_S8_R24_flex_start_bounds_accepted", run := t_flex_start_bounds },
  { name := "test_001_S8_R24_dynamic_no_surplus_flex_from_20", run := t_dynamic_no_surplus_from_20 },
  { name := "test_001_S8_R24_dynamic_surplus_runs_flex", run := t_dynamic_surplus_runs_flex },
  { name := "test_001_S8_R24_dynamic_run_without_surplus_starts_at_20", run := t_dynamic_run_no_surplus_day },
  { name := "test_001_S8_R24_precomputed_flex_in_sunny_hours", run := t_precomputed_flex_sunny_hours },
  { name := "test_001_S8_R24_precomputed_flex_avoids_hours_the_tanks_took", run := t_precomputed_flex_after_tanks },
  { name := "test_001_S8_R25_dynamic_no_heat_when_third_start_not_needed", run := t_dynamic_no_third_start_not_needed },
  { name := "test_001_S8_R25_each_tank_at_most_2_starts_a_day", run := t_tank_starts_at_most_2 },
  { name := "test_001_S8_R25_battery_gate_at_most_2_changes_a_day", run := t_gate_changes_at_most_2 },
  { name := "test_001_S8_R25_starts_per_day_equals_run_totals", run := t_starts_per_day_value },
  { name := "test_001_S8_R25_starts_per_day_default_run", run := t_starts_per_day_default_run },
  { name := "test_001_S8_R25_T1_idle_to_requested_counts_start", run := t_T1_idle_to_requested },
  { name := "test_001_S8_R25_T2_requested_to_idle_at_target", run := t_T2_requested_to_idle },
  { name := "test_001_S8_R25_X1_third_start_refused", run := t_X1_third_start_refused },
  { name := "test_001_S8_R25_dynamic_keeps_heating_rather_than_third_start", run := t_dynamic_keeps_heating_instead_of_third_start },
  { name := "test_001_S8_R25_precomputed_plan_at_most_2_starts", run := t_precomputed_plan_at_most_2_starts }
]

def main (args : List String) : IO UInt32 := Harness.run tests args
