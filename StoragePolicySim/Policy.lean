/-
The policies of the hot-water tanks, the battery and the flexible load. Built: the structures,
the defaults, `Policy.name`, `staticProfile`, `planDay` and `dynamicAction`, with more tanks (the tank with the lowest share of its capacity goes
first). The flexible load is placed by each policy (D25): the static policy runs it from
`flexStart`, the precomputed policy in the sunniest hours that the tanks leave, and the dynamic
policy in the first hours with a surplus and from 20:00 at the latest. An hour holds one third of
the daily flexible energy (the dynamic policy: the surplus, or a share of the energy that is left),
and hour 23 takes all that is left. A tank starts at most 2 times in a day (D26).
-/
import StoragePolicySim.HotWater

namespace StoragePolicySim

/-- What a policy asks for in one hour. -/
structure Action where
  heatKwh : Array Float
  allowCharge : Bool
  allowDischarge : Bool
  flexKwh : Float
  deriving Repr, Inhabited

/-- The heating window of one tank. -/
structure TankWindow where
  heatStart : Nat
  heatHours : Nat
  deriving Repr, Inhabited

/-- The parameters of a static policy. -/
structure StaticParams where
  windows : Array TankWindow
  dischargeFrom : Nat
  flexStart : Nat
  deriving Repr, Inhabited

/-- The parameters of a precomputed policy. -/
structure PlanParams where
  targetKwh : Array Float
  minSolarKwh : Float
  dischargeFrom : Nat
  deriving Repr, Inhabited

/-- The parameters of a dynamic policy. -/
structure DynamicParams where
  lowKwh : Array Float
  targetKwh : Array Float
  dischargeFrom : Nat
  deriving Repr, Inhabited

/-- A policy. -/
inductive Policy where
  | static (p : StaticParams)
  | precomputed (p : PlanParams)
  | dynamic (p : DynamicParams)
  deriving Repr, Inhabited

/-- The name of a policy: `static`, `precomputed` or `dynamic`. -/
def Policy.name : Policy → String
  | .static _ => "static"
  | .precomputed _ => "precomputed"
  | .dynamic _ => "dynamic"

/-- The default static policy: heat from 10:00 for 4 hours, discharge from 17:00, and run the
flexible load from 18:00. -/
def defaultStatic : StaticParams :=
  { windows := #[{ heatStart := 10, heatHours := 4 }], dischargeFrom := 17, flexStart := 18 }

/-- The default precomputed policy: heat to a full tank, in hours with a forecast of at least
0.5 kWh, and discharge from 17:00. -/
def defaultPlan : PlanParams :=
  { targetKwh := #[defaultTank.capacityKwh], minSolarKwh := 0.5, dischargeFrom := 17 }

/-- The default dynamic policy: heat below 5.25 kWh, heat to a full tank, and discharge from
17:00. -/
def defaultDynamic : DynamicParams :=
  { lowKwh := #[defaultTank.cutInKwh], targetKwh := #[defaultTank.capacityKwh],
    dischargeFrom := 17 }

/-- The hours in a day. -/
def hoursInDay : Nat := 24

/-- The parts that the flexible load of a day runs in. -/
def flexParts : Nat := 3

/-- The flexible load of each hour of a day, in 3 equal parts from `flexStart`, in fewer and
larger parts when the day ends first. -/
def flexProfile (flexDayKwh : Float) (flexStart : Nat) : Array Float :=
  let parts := min flexParts (hoursInDay - flexStart)
  let partKwh := if parts == 0 then 0.0 else flexDayKwh / parts.toFloat
  (Array.range hoursInDay).map fun hour =>
    if flexStart ≤ hour && hour < flexStart + parts then partKwh else 0.0

/-- The window of a tank: window `i`, or the last window when there are fewer. -/
def StaticParams.windowOf (params : StaticParams) (tank : Nat) : Option TankWindow :=
  params.windows[tank]? <|> params.windows.back?

/-- The 24 actions of a static policy. Tank `i` asks for its element power in its window, and
the window stops at the end of the day. The battery may always charge, and may discharge from
`dischargeFrom`. The flexible load runs in 3 equal parts from `flexStart`, in fewer and larger
parts when the day ends first. -/
def staticProfile (tanks : Array TankConfig) (params : StaticParams) (flexDayKwh : Float) :
    Array Action :=
  let flex := flexProfile flexDayKwh params.flexStart
  (Array.range hoursInDay).map fun hour =>
    let heatKwh := tanks.mapIdx fun i tank =>
      match params.windowOf i with
      | some window =>
        if window.heatStart ≤ hour && hour < window.heatStart + window.heatHours
        then tank.elementKw else 0.0
      | none => 0.0
    { heatKwh, allowCharge := true, allowDischarge := params.dischargeFrom ≤ hour,
      flexKwh := flex[hour]! }

/-- The order in which tanks take the same energy (D22): the tank with the lowest share of its
capacity first, and a tie goes to the first tank. -/
def tankOrder (tanks : Array TankConfig) (energyKwh : Array Float) : Array Nat :=
  let share (i : Nat) : Float :=
    let capacity := tanks[i]!.capacityKwh
    if capacity > 0.0 then energyKwh[i]?.getD 0.0 / capacity else 1.0
  (Array.range tanks.size).qsort fun a b => share a < share b || (share a == share b && a < b)

/-- The heating of one tank in each hour of a day. The tank takes the hours with a forecast of at
least `minSolarKwh`, from the highest forecast to the lowest (a tie goes to the earlier hour),
at its element power each, until the need is met. The last hour gets only the rest of the
need. -/
private def planTank (elementKw minSolarKwh need : Float) (forecastKwh : Array Float) :
    Array Float :=
  let forecastAt (hour : Nat) := forecastKwh[hour]?.getD 0.0
  let sunny := (Array.range hoursInDay).filter fun hour => forecastAt hour ≥ minSolarKwh
  let ranked := sunny.qsort fun a b =>
    forecastAt a > forecastAt b || (forecastAt a == forecastAt b && a < b)
  let (heat, _) := ranked.foldl (init := (Array.replicate hoursInDay 0.0, need))
    fun (heat, left) hour =>
      if left > 0 then
        let ask := min elementKw left
        (heat.set! hour ask, left - ask)
      else (heat, left)
  heat

/-- The runs of a heating plan: the hours `(first, after the last)` of each stretch of hours with
a request. -/
private def runsOf (heat : Array Float) : Array (Nat × Nat) := Id.run do
  let mut runs : Array (Nat × Nat) := #[]
  let mut first : Option Nat := none
  for hour in [0:hoursInDay] do
    if heat[hour]! > 0 then
      if first.isNone then first := some hour
    else if let some start := first then
      runs := runs.push (start, hour)
      first := none
  if let some start := first then runs := runs.push (start, hoursInDay)
  return runs

/-- The most starts of an element in a day (D26). -/
def maxStartsPerDay : Nat := 2

/-- A heating plan with at most 2 runs of hours (D26): while it has more, it drops the run with
the least energy (a tie goes to the earlier run). -/
private def limitRuns (heat : Array Float) : Array Float := Id.run do
  let mut heat := heat
  for _ in [0:hoursInDay] do
    let runs := runsOf heat
    if runs.size ≤ maxStartsPerDay then break
    let energyOf (run : Nat × Nat) : Float :=
      (Array.range (run.2 - run.1)).foldl (fun sum k => sum + heat[run.1 + k]!) 0.0
    let smallest := runs.foldl (init := runs[0]!) fun best run =>
      if energyOf run < energyOf best then run else best
    for hour in [smallest.1:smallest.2] do
      heat := heat.set! hour 0.0
  return heat

/-- The flexible load of a precomputed plan: one third of the day in each of the 3 hours with the
most forecast energy left after the tanks. A tie goes to the hour that is nearest after 18:00. -/
private def planFlex (flexDayKwh : Float) (remaining : Array Float) : Array Float :=
  let key (hour : Nat) : Nat := (hour + hoursInDay - defaultStatic.flexStart) % hoursInDay
  let ranked := (Array.range hoursInDay).qsort fun a b =>
    remaining[a]! > remaining[b]! || (remaining[a]! == remaining[b]! && key a < key b)
  let chosen := ranked.extract 0 flexParts
  (Array.range hoursInDay).map fun hour =>
    if chosen.contains hour then flexDayKwh / flexParts.toFloat else 0.0

/-- The 24 actions of a precomputed policy for one day. The need of a tank is its target less its
energy plus its expected draw, and never less than 0. Each tank plans in turn, and the forecast
of an hour falls by what the tanks before it took. A tank has at most 2 runs of hours (D26). The
battery rules are those of a static policy. The flexible load runs in the 3 hours with the most
forecast that the tanks leave (D25). -/
def planDay (tanks : Array TankConfig) (params : PlanParams)
    (forecastKwh tankKwh expectedDrawKwh : Array Float) (flexDayKwh : Float) : Array Action :=
  let (heats, left) := (tankOrder tanks tankKwh).foldl
    (init := (Array.replicate tanks.size (Array.replicate hoursInDay 0.0), forecastKwh))
    fun (heats, remaining) i =>
      let tank := tanks[i]!
      let target := params.targetKwh[i]?.getD tank.capacityKwh
      let need := max 0.0 (target - tankKwh[i]?.getD 0.0 + expectedDrawKwh[i]?.getD 0.0)
      let heat := limitRuns (planTank tank.elementKw params.minSolarKwh need remaining)
      let left := (Array.range hoursInDay).map fun hour =>
        max 0.0 (remaining[hour]?.getD 0.0 - heat[hour]!)
      (heats.set! i heat, left)
  let flex := planFlex flexDayKwh left
  (Array.range hoursInDay).map fun hour =>
    { heatKwh := heats.map fun heat => heat[hour]!, allowCharge := true,
      allowDischarge := params.dischargeFrom ≤ hour, flexKwh := flex[hour]! }

/-- What a dynamic policy sees in one hour. -/
structure Observation where
  hour : Nat
  tankKwh : Array Float
  socKwh : Float
  surplusKwh : Float
  forecastRestKwh : Float
  flexLeftKwh : Float
  startsToday : Array Nat
  askedLastHour : Array Bool
  deriving Repr, Inhabited

/-- The hour from which a dynamic policy runs the flexible load whatever the surplus (D25). -/
def dynamicFlexDeadline : Nat := 20

/-- The action of a dynamic policy for one hour. With a solar surplus and a tank below its target,
a tank asks for the smallest of its element power, the surplus left and the room to the target.
If not, and the tank is below its low level and the forecast for the rest of the day is less than
the lack, it asks for the smaller of its element power and the lack. Otherwise it asks for 0. Each
tank takes its share of the surplus in turn. A tank with 2 starts today refuses a third start (its
request stays 0), and keeps heating, from the grid too, when it asked in the last hour and is below
its target (D26). The flexible load takes the surplus that the tanks leave, and from 20:00 runs in
equal shares of what is left (the whole of it at 23:00), so that it ends inside its day (D25). The
battery may discharge from `dischargeFrom`. -/
def dynamicAction (tanks : Array TankConfig) (params : DynamicParams) (obs : Observation) : Action :=
  let (asks, surplus) := (tankOrder tanks obs.tankKwh).foldl
    (init := (Array.replicate tanks.size 0.0, obs.surplusKwh)) fun (asks, surplus) i =>
      let tank := tanks[i]!
      let energy := obs.tankKwh[i]?.getD 0.0
      let target := params.targetKwh[i]?.getD tank.capacityKwh
      let low := params.lowKwh[i]?.getD (tank.capacityKwh / 2)
      let running := obs.askedLastHour[i]?.getD false
      let spent := obs.startsToday[i]?.getD 0 ≥ maxStartsPerDay
      if surplus > 0 && energy < target && (running || !spent) then
        let ask := min tank.elementKw (min surplus (target - energy))
        (asks.set! i ask, surplus - ask)
      else if running && spent && energy < target then
        (asks.set! i (min tank.elementKw (target - energy)), surplus)
      else if energy < low && obs.forecastRestKwh < low - energy && (running || !spent) then
        (asks.set! i (min tank.elementKw (low - energy)), surplus)
      else (asks, surplus)
  let left := max 0.0 obs.flexLeftKwh
  let flexKwh :=
    if obs.hour ≥ hoursInDay - 1 then left
    else if obs.hour ≥ dynamicFlexDeadline then left / (hoursInDay - 1 - obs.hour).toFloat
    else min left surplus
  { heatKwh := asks, allowCharge := true, allowDischarge := params.dischargeFrom ≤ obs.hour,
    flexKwh }

end StoragePolicySim
