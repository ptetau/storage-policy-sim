/-
The run of a home with a policy on the physics model (spec 002, D2, D13 to D15): 96 steps a day.
A policy decides once an hour as in `runHome`, and its heating request spreads over the 4 steps of
the hour. Built: `runPhysics`, the runners of the physics model for the evaluation and the tuner
(`evaluatePhysics`, `tunePhysics`), and `physDayForecast`.
-/
import StoragePolicySim.HomeSim
import StoragePolicySim.PhysWeather
import StoragePolicySim.PhysTank
import StoragePolicySim.PhysAppliances

namespace StoragePolicySim

/-- The temperature rise of the draw at the tap in the litres rule of D15: 26 degrees. -/
private def tapRiseK : Float := 26.0

/-- What a run reads that does not depend on the policy. -/
private structure PhysPre where
  /-- The hourly sums of the steps, for the forecast and for the dynamic policy. -/
  hours : Array Hour
  /-- The solar energy of each step of the run, in kWh. -/
  solarKwh : FloatArray
  /-- The base load of each step of the run, in kWh. -/
  baseKwh : FloatArray
  /-- The temperature of the inlet water of each day. -/
  inletC : FloatArray
  /-- For each tank, the litres at the tap in each hour of the run, with the day factor. -/
  tapLitres : Array FloatArray
  /-- The appliance cycles of each day. -/
  cycles : Array (Array Cycle)
  deriving Inhabited

/-- Everything that does not depend on the policy: the weather, the solar energy, the base load,
the cycles and the litres at the tap. -/
private def physPre (home : Home) (seed days : Nat) : PhysPre := Id.run do
  let latitude := home.site.latitude
  let dailyClearness := dayClearness latitude seed days
  let stepClearness := clearness latitude seed days
  let baseDailyKwh := max 0.0 (home.site.dailyLoadKwh - home.site.flexKwh)
  let mut solar := FloatArray.emptyWithCapacity (stepsPerDay * days)
  let mut base := FloatArray.emptyWithCapacity (stepsPerDay * days)
  let mut inlet := FloatArray.emptyWithCapacity days
  let mut hours : Array Hour := Array.mkEmpty (hoursInDay * days)
  let mut cycles : Array (Array Cycle) := Array.mkEmpty days
  let mut taps : Array FloatArray :=
    home.tanks.map fun _ => FloatArray.emptyWithCapacity (hoursInDay * days)
  for day in [0:days] do
    let dayOfYear := day % daysInYear
    inlet := inlet.push (inletTempC latitude dayOfYear)
    cycles := cycles.push (if home.site.flexKwh > 0 then applianceCycles seed day else #[])
    let factor := drawFactor seed day home.drawCv
    for hour in [0:hoursInDay] do
      let mut pvKwh := 0.0
      let mut baseKwh := 0.0
      for quarter in [0:stepsPerHour] do
        let step := stepsPerHour * hour + quarter
        let airC := airTempC latitude dayOfYear step dailyClearness[day]!
        let clear := stepClearness[stepsPerDay * day + step]!
        let kw := home.arrays.foldl (init := 0.0) fun sum array =>
          sum + arrayKw array (panelWm2 latitude array dayOfYear step clear) airC
        let solarStep := kw * stepHours
        let baseStep := baseLoadKw baseDailyKwh latitude dayOfYear step * stepHours
        solar := solar.push solarStep
        base := base.push baseStep
        pvKwh := pvKwh + solarStep
        baseKwh := baseKwh + baseStep
      hours := hours.push
        { day, dayOfYear, hour, sky := .sunny, pvKwh, baseLoadKwh := baseKwh, flexKwh := 0.0 }
      taps := taps.mapIdx fun i tap =>
        tap.push (drawKwh (home.drawKwhPerDay * (home.drawShares[i]?.getD 0.0)) latitude dayOfYear
          hour * factor / (kwhPerLitreK * tapRiseK))
  return { hours, solarKwh := solar, baseKwh := base, inletC := inlet, tapLitres := taps, cycles }

/-- The energy of each step of a day from its cycles. The first cycle starts at step `first`, and
each next one when the one before ends. A cycle starts early enough to end inside its day. -/
private def placeCycles (cycles : Array Cycle) (first : Nat) : Array Float := Id.run do
  let mut out := Array.replicate stepsPerDay 0.0
  let mut next := first
  for cycle in cycles do
    let length := cycle.stepKwh.size
    let start := min next (stepsPerDay - length)
    for k in [0:length] do
      out := out.modify (start + k) (· + cycle.stepKwh[k]!)
    next := start + length
  return out

/-! The running sums of a run are slots of one `FloatArray`, which keeps the numbers unboxed: the
loop of 96 steps a day runs many times in the tuner. -/

/-- The slots of the running sums, and the number of them. -/
private def slotSoc : Nat := 0
private def slotPv : Nat := 1
private def slotHouse : Nat := 2
private def slotImport : Nat := 3
private def slotExport : Nat := 4
private def slotCurtailed : Nat := 5
private def slotBatteryLoss : Nat := 6
private def slotHeat : Nat := 7
private def slotBackstop : Nat := 8
private def slotDrawn : Nat := 9
private def slotUnmet : Nat := 10
private def slotTankLoss : Nat := 11
/-- The load of the tanks in the step that runs (not a total). -/
private def slotTankLoad : Nat := 12
private def sumSlots : Nat := 13

/-- Adds an energy to a slot. -/
private def bump (sums : FloatArray) (slot : Nat) (kwh : Float) : FloatArray :=
  sums.set! slot (sums.get! slot + kwh)

/-- What a run carries from one day to the next: the tanks, the battery and the last requests. -/
private structure PhysCarry where
  states : Array PhysTankState
  socKwh : Float
  asked : Array Bool
  deriving Inhabited

/-- The run of a home with a policy on the physics model, from a full tank and an empty battery on
1 January. In each hour, the policy gives its action from what it sees: the tanks as their energy
above the inlet temperature, and the capacity of a full tank at that temperature. Then each of the 4
steps of the hour runs: each tank takes a quarter of the request, and the battery runs on the solar
energy and the load of the step. The cycles of the day start when the policy first gives flexible
energy (D25 and D11). With `record` false the run keeps the totals only. The run covers the days
from `first` to before `days`, and starts from `carry` when it is given. `plans` gives the plan of
a day in place of the plan of the policy. The run also returns what it carries on. -/
private def runPhysicsOn (home : Home) (policy : Policy) (seed days : Nat) (pre : PhysPre)
    (record : Bool) (first : Nat := 0) (carry : Option PhysCarry := none)
    (plans : Nat → Option (Array Action) := fun _ => none) : HomeResult × PhysCarry := Id.run do
  let latitude := home.site.latitude
  let tanks := home.tanks.map physTankOf
  let tankCount := home.tanks.size
  let staticPlan : Array Action := match policy with
    | .static params => staticProfile home.tanks params home.site.flexKwh
    | _ => #[]
  let mut states := match carry with
    | some c => c.states
    | none => tanks.map physStart
  let firstInlet := inletTempC latitude 0
  let mut minTank := FloatArray.mk (states.map fun state => tankEnergyKwh state firstInlet)
  let mut asked := match carry with
    | some c => c.asked
    | none => Array.replicate tankCount false
  let mut sums := FloatArray.mk (Array.replicate sumSlots 0.0)
  if let some c := carry then sums := sums.set! slotSoc c.socKwh
  let mut coldHours := 0
  let mut policyStarts := 0
  let mut startsToday := Array.replicate tankCount 0
  let mut fetchedAt : Option Nat := none
  let mut fetchedKwh : Array Float := #[]
  let mut hours : Array HomeHour := Array.mkEmpty (if record then stepsPerDay * days else 0)
  for day in [first:days] do
    let dayOfYear := day % daysInYear
    let inletC := pre.inletC.get! day
    -- The guard hour of the day (D13): early enough for the element to fill a full tank by midnight.
    let dayTanks := tanks.map fun tank =>
      if tank.elementKw > 0.0 then
        let hoursNeeded := (tankEnergyKwh (physStart tank) inletC / tank.elementKw).ceil.toUInt64.toNat
        { tank with guardHour := min tank.guardHour (hoursInDay - hoursNeeded) }
      else tank
    startsToday := Array.replicate tankCount 0
    -- A full tank at the inlet temperature is the capacity that a policy compares with.
    let seen : Array TankConfig := home.tanks.mapIdx fun i tank =>
      { tank with capacityKwh := tankEnergyKwh (physStart tanks[i]!) inletC }
    let mut dayPlan : Array Action := #[]
    match plans day, policy with
    | some plan, _ => dayPlan := plan
    | none, .static _ => dayPlan := staticPlan
    | none, .precomputed params =>
      -- The draw of the day takes `(40 - inlet) / 26` of the energy that the profile gives.
      let drawScale := (40.0 - inletC) / tapRiseK
      dayPlan := planDay seen params (forecastOfDay home seed pre.hours day)
        (states.map fun state => tankEnergyKwh state inletC)
        ((expectedDraw home dayOfYear).map (· * drawScale)) home.site.flexKwh
    | none, .dynamic _ => pure ()
    -- The cycles of the day: they start in the first hour with flexible energy.
    let mut flexSteps : Array Float := #[]
    let mut placed := false
    if let some hour := (Array.range hoursInDay).find? fun hour =>
        (dayPlan[hour]?.map (·.flexKwh)).getD 0.0 > 0.0 then
      flexSteps := placeCycles pre.cycles[day]! (stepsPerHour * hour)
      placed := true
    for hour in [0:hoursInDay] do
      let hourOfRun := hoursInDay * day + hour
      let mut action := dayPlan[hour]?.getD default
      if let (.dynamic params, none) := (policy, plans day) then
        let fetch := latestFetch home.fetchesPerDay hourOfRun
        if fetchedAt != some fetch then
          fetchedKwh := fetchedEnergy home seed pre.hours fetch
          fetchedAt := some fetch
        let hourSums := pre.hours[hourOfRun]!
        let observation : Observation :=
          { hour, tankKwh := states.map fun state => tankEnergyKwh state inletC,
            socKwh := sums.get! slotSoc,
            surplusKwh := max 0.0 (hourSums.pvKwh - hourSums.baseLoadKwh),
            forecastRestKwh := restOfDayForecast fetchedKwh fetch hourOfRun day,
            flexLeftKwh := if placed then 0.0 else home.site.flexKwh, startsToday,
            askedLastHour := asked }
        action := dynamicAction seen params observation
        if !placed && action.flexKwh > 0.0 then
          flexSteps := placeCycles pre.cycles[day]! (stepsPerHour * hour)
          placed := true
      for tankIndex in [0:tankCount] do
        let askKwh := action.heatKwh[tankIndex]!
        if askKwh > 0 && !asked[tankIndex]! then
          policyStarts := policyStarts + 1
          startsToday := startsToday.modify tankIndex (· + 1)
        asked := asked.set! tankIndex (askKwh > 0)
      for quarter in [0:stepsPerHour] do
        let step := stepsPerHour * hour + quarter
        let stepOfRun := stepsPerDay * day + step
        let mut tankHours : Array TankHour := Array.mkEmpty (if record then tankCount else 0)
        sums := sums.set! slotTankLoad 0.0
        for i in [0:tankCount] do
          let tank := dayTanks[i]!
          let askKwh := action.heatKwh[i]! / stepsPerHour.toFloat
          let tapLitres := pre.tapLitres[i]!.get! hourOfRun / stepsPerHour.toFloat
          let result := physTankStep tank states[i]! step askKwh tapLitres inletC
          states := states.set! i result.state
          let energyKwh := tankEnergyKwh result.state inletC
          sums := bump sums slotTankLoss result.lossKwh
          sums := bump sums slotTankLoad (result.heatKwh + result.backstopKwh)
          sums := bump sums slotHeat result.heatKwh
          sums := bump sums slotBackstop result.backstopKwh
          sums := bump sums slotDrawn (result.servedKwh + result.unmetKwh)
          sums := bump sums slotUnmet result.unmetKwh
          minTank := minTank.set! i (min (minTank.get! i) energyKwh)
          if quarter == stepsPerHour - 1 && result.state.hotLitres / tank.litres < tank.floorShare then
            coldHours := coldHours + 1
          if record then
            tankHours := tankHours.push
              { drawKwh := result.servedKwh + result.unmetKwh, askKwh, heatKwh := result.heatKwh,
                backstopKwh := result.backstopKwh, unmetKwh := result.unmetKwh, energyKwh }
        let flexKwh := flexSteps[step]?.getD 0.0
        let houseLoadKwh := pre.baseKwh.get! stepOfRun + flexKwh
        let solarKwh := pre.solarKwh.get! stepOfRun
        let limited := physBatteryStep home.limits home.battery (sums.get! slotSoc)
          action.allowCharge action.allowDischarge solarKwh
          (houseLoadKwh + sums.get! slotTankLoad)
        sums := sums.set! slotSoc limited.flow.socKwh
        sums := bump sums slotPv solarKwh
        sums := bump sums slotHouse houseLoadKwh
        sums := bump sums slotImport limited.flow.importKwh
        sums := bump sums slotExport limited.flow.exportKwh
        sums := bump sums slotCurtailed limited.curtailedKwh
        sums := bump sums slotBatteryLoss limited.flow.lossKwh
        if record then
          hours := hours.push
            { day, hour := step, pvKwh := solarKwh, houseLoadKwh, flexKwh, tanks := tankHours,
              allowCharge := action.allowCharge, allowDischarge := action.allowDischarge,
              flow := limited.flow, curtailedKwh := limited.curtailedKwh }
  let lastInlet := if days == 0 then firstInlet else pre.inletC.get! (days - 1)
  let pvKwh := sums.get! slotPv
  let exportKwh := sums.get! slotExport
  let curtailedKwh := sums.get! slotCurtailed
  let importKwh := sums.get! slotImport
  let loadKwh := sums.get! slotHouse + sums.get! slotHeat + sums.get! slotBackstop
  let totals : HomeTotals :=
    { pvKwh, loadKwh, importKwh, exportKwh, curtailedKwh,
      batteryLossKwh := sums.get! slotBatteryLoss, tankLossKwh := sums.get! slotTankLoss,
      heatKwh := sums.get! slotHeat, backstopKwh := sums.get! slotBackstop,
      drawKwh := sums.get! slotDrawn, unmetKwh := sums.get! slotUnmet,
      selfConsumption := percent (pvKwh - exportKwh - curtailedKwh) pvKwh,
      selfSufficiency := percent (loadKwh - importKwh) loadKwh,
      minTankKwh := minTank.data, finalTankKwh := states.map fun state => tankEnergyKwh state lastInlet,
      coldHours, policyStarts }
  return ({ hours, totals }, { states, socKwh := sums.get! slotSoc, asked })

/-- One run of a home with a policy on the physics model: 96 records for each day (in a record,
`hour` holds the step from 0 to 95, `flexKwh` the appliance energy of the step, and `energyKwh` of
a tank its energy above the inlet temperature). The totals have the meaning of spec 001. The same
arguments give the same run. -/
def runPhysics (home : Home) (policy : Policy) (seed days : Nat) : HomeResult :=
  (runPhysicsOn home policy seed days (physPre home seed days) true).1

/-- The runner of each seed from `seed` on the physics model. Each runner holds the weather, the
loads and the draws of its seed, which do not depend on the policy, and keeps the totals only. -/
private def physRunners (home : Home) (seed seeds days : Nat) : Array Runner :=
  let pres := (Array.range seeds).map fun k => physPre home (seed + k) days
  (Array.range seeds).map fun k policy =>
    (runPhysicsOn home policy (seed + k) days pres[k]! false).1.totals

/-- `evaluate` on the physics model. -/
def evaluatePhysics (home : Home) (policy : Policy) (seed seeds days : Nat) : Evaluation :=
  evaluateRunners (physRunners home seed seeds days) policy days

/-- `tuneStatic` on the physics model. The run of each seed builds its weather once, for all the
candidates. -/
def tunePhysics (home : Home) (goal : Goal) (seed seeds days : Nat) : TuneResult :=
  tuneWith home goal (physRunners home seed seeds days) days

/-- The forecast solar energy of each hour of a day of a physics run, as the precomputed policy
reads it at hour 0 of the day: the forecast of spec 001 over the hourly solar energy of the run. -/
def physDayForecast (home : Home) (seed days day : Nat) : Array Float :=
  forecastOfDay home seed (physPre home seed days).hours day

/-- A run with perfect knowledge of each day (an analysis aid, not a policy of the spec). For each
day, the run searches the timer plans of that day (the window of each tank, the discharge hour and
the start of the flexible load) on the true weather, loads and draws of the day. A plan costs the
grid import of the day and of the next day on the plan `base`, which values what the day leaves
in the tanks and the battery. Unmet draw and cold hours cost much more. -/
def runOracle (home : Home) (base : StaticParams) (seed days : Nat) : HomeResult := Id.run do
  let pre := physPre home seed days
  let policy := Policy.static base
  let planOf (params : StaticParams) := staticProfile home.tanks params home.site.flexKwh
  let mut carry : Option PhysCarry := none
  let mut chosen : Array (Array Action) := Array.mkEmpty days
  for day in [0:days] do
    let start := carry
    let cost (params : StaticParams) : Float :=
      let plan := planOf params
      let totals := (runPhysicsOn home policy seed (min days (day + 2)) pre false day start
        fun d => if d == day then some plan else none).1.totals
      totals.importKwh + 1000.0 * totals.unmetKwh + 10.0 * totals.coldHours.toFloat
    let mut best := base
    let mut bestCost := cost best
    for _ in [0:2] do
      for tank in [0:home.tanks.size] do
        for heatStart in [5:19] do
          for heatHours in [0:10] do
            let windows := (Array.range home.tanks.size).map fun i =>
              if i == tank then { heatStart, heatHours } else (best.windowOf i).getD default
            let candidate := { best with windows }
            let c := cost candidate
            if c < bestCost - 0.001 then
              best := candidate
              bestCost := c
      for dischargeFrom in [0:hoursInDay] do
        let candidate := { best with dischargeFrom }
        let c := cost candidate
        if c < bestCost - 0.001 then
          best := candidate
          bestCost := c
      for flexStart in [0:22] do
        let candidate := { best with flexStart }
        let c := cost candidate
        if c < bestCost - 0.001 then
          best := candidate
          bestCost := c
    let plan := planOf best
    carry := some (runPhysicsOn home policy seed (day + 1) pre false day start fun _ => some plan).2
    chosen := chosen.push plan
  return (runPhysicsOn home policy seed days pre true 0 none fun d => chosen[d]?).1

end StoragePolicySim
