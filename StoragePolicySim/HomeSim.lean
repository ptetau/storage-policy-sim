/-
The simulation of a home with a policy, the evaluation over seeds, and the tuner. Built: the
structures, `defaultHome`, `runHome` for the three policies with any panel arrays and the limits of
the inverter and the export, `evaluate` and `tuneStatic` (with one tank). Not built yet:
`homeNames` (a placeholder), `homeNamed` (a stub), and the search over more tanks.
-/
import StoragePolicySim.Policy
import StoragePolicySim.Simulation
import StoragePolicySim.Forecast

namespace StoragePolicySim

/-- A home. `site.pvKw` holds the sum of the array powers. -/
structure Home where
  site : Site
  arrays : Array PanelArray
  battery : Battery
  limits : Limits
  tanks : Array TankConfig
  drawShares : Array Float
  drawKwhPerDay : Float
  drawCv : Float
  fetchesPerDay : Nat
  errorScale : Float
  deriving Repr, Inhabited

/-- A placeholder. Not built yet. -/
def homeNames : List String := []

/-- The home of a name. Not built yet. -/
def homeNamed (name : String) : Option Home :=
  todo "homeNamed" name.length

/-- The home `generic`: latitude -41.3, one flat array of 5 kW, 20 kWh of load a day with 3 kWh
flexible, a battery of 10 kWh with 5 kW, no limits, the default tank, 6.0 kWh of hot water a day
with a spread of 0.25, 10 forecast fetches a day, and a forecast error scale of 1.0. -/
def defaultHome : Home where
  site := { latitude := -41.3, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }
  arrays := #[{ kw := 5.0, direction := 0.0, tilt := 0.0 }]
  battery := { capacityKwh := 10.0, powerKw := 5.0 }
  limits := noLimits
  tanks := #[defaultTank]
  drawShares := #[1.0]
  drawKwhPerDay := 6.0
  drawCv := 0.25
  fetchesPerDay := 10
  errorScale := 1.0

/-- One tank in one hour of a run. -/
structure TankHour where
  drawKwh : Float
  askKwh : Float
  heatKwh : Float
  backstopKwh : Float
  unmetKwh : Float
  energyKwh : Float
  deriving Repr, Inhabited

/-- One hour of a run. -/
structure HomeHour where
  day : Nat
  hour : Nat
  pvKwh : Float
  houseLoadKwh : Float
  flexKwh : Float
  tanks : Array TankHour
  allowCharge : Bool
  allowDischarge : Bool
  flow : Flow
  curtailedKwh : Float
  deriving Repr, Inhabited

/-- The totals of a run. -/
structure HomeTotals where
  pvKwh : Float
  loadKwh : Float
  importKwh : Float
  exportKwh : Float
  curtailedKwh : Float
  batteryLossKwh : Float
  tankLossKwh : Float
  heatKwh : Float
  backstopKwh : Float
  drawKwh : Float
  unmetKwh : Float
  selfConsumption : Float
  selfSufficiency : Float
  minTankKwh : Array Float
  finalTankKwh : Array Float
  coldHours : Nat
  policyStarts : Nat
  deriving Repr, Inhabited

/-- A run: its hours and its totals. -/
structure HomeResult where
  hours : Array HomeHour
  totals : HomeTotals
  deriving Repr, Inhabited

/-- The scenario of a home: the hours of its site, with the solar energy of each hour set to the
sum of the arrays of the home (D18). A home with one flat array gives the solar energy of the
site. The forecast reads these hours, so it follows the arrays too. -/
private def homeScenario (home : Home) (seed days : Nat) : Array Hour :=
  (scenario home.site seed days).map fun hour =>
    { hour with
      pvKwh := home.arrays.foldl (init := 0.0) fun sum array =>
        sum + arrayOutput home.site.latitude array hour.dayOfYear hour.hour hour.sky }

/-- The expected draw of each tank in a day: the draw profile with the season, and without the
random factor of the day. -/
private def expectedDraw (home : Home) (dayOfYear : Nat) : Array Float :=
  (Array.range home.tanks.size).map fun i =>
    (Array.range hoursInDay).foldl (init := 0.0) fun sum hour =>
      sum + drawKwh (home.drawKwhPerDay * home.drawShares[i]!) home.site.latitude dayOfYear hour

/-- The sum of a value over the hours of a run. -/
private def sumHours (hours : Array HomeHour) (value : HomeHour → Float) : Float :=
  hours.foldl (fun sum hour => sum + value hour) 0.0

/-- The sum of a value of each tank over the hours of a run. -/
private def sumTankHours (hours : Array HomeHour) (value : TankHour → Float) : Float :=
  sumHours hours fun hour => hour.tanks.foldl (fun sum tank => sum + value tank) 0.0

/-- One run of a home with a policy, from a full tank and an empty battery on 1 January. In each
hour, the policy gives its action, each tank runs its hour, the heating and the backstop heating
join the house load, and the battery runs its hour. A precomputed policy plans at hour 0 of each
day, from the forecast of the fetch at hour 0. A dynamic policy reads the latest fetch. The
flexible load of each policy runs as the static default does. -/
private def runHomeOn (home : Home) (policy : Policy) (seed days : Nat)
    (scenarioHours : Array Hour) : HomeResult := Id.run do
  -- A static policy gives the same actions each day: build them once.
  let staticPlan : Array Action := match policy with
    | .static params => staticProfile home.tanks params home.site.flexKwh
    | _ => #[]
  let flexHours := flexProfile home.site.flexKwh defaultStatic.flexStart
  let mut states := home.tanks.map startState
  let mut minTankKwh := home.tanks.map (·.capacityKwh)
  let mut asked := Array.replicate home.tanks.size false
  let mut socKwh := 0.0
  let mut tankLossKwh := 0.0
  let mut coldHours := 0
  let mut policyStarts := 0
  let mut startsToday := Array.replicate home.tanks.size 0
  let mut flexToday := 0.0
  let mut fetchedAt : Option Nat := none
  let mut fetchedKwh : Array Float := #[]
  let mut hours : Array HomeHour := Array.mkEmpty scenarioHours.size
  for day in [0:days] do
    startsToday := Array.replicate home.tanks.size 0
    flexToday := 0.0
    let mut dayPlan : Array Action := #[]
    match policy with
    | .static _ => dayPlan := staticPlan
    | .precomputed params =>
      let fetch := hoursInDay * day
      let forecastKwh := (hourlyEnergy (forecastOf scenarioHours home.site seed home.errorScale
        fetch) fetch).extract 0 hoursInDay
      dayPlan := planDay home.tanks params forecastKwh (states.map (·.energyKwh))
        (expectedDraw home scenarioHours[fetch]!.dayOfYear) home.site.flexKwh
    | .dynamic _ => pure ()
    let factor := drawFactor seed day home.drawCv
    for scenarioHour in scenarioHours.extract (hoursInDay * day) (hoursInDay * (day + 1)) do
      let pvKwh := scenarioHour.pvKwh
      let hourOfRun := hoursInDay * day + scenarioHour.hour
      let mut action := dayPlan[scenarioHour.hour]?.getD default
      if let .dynamic params := policy then
        let fetch := latestFetch home.fetchesPerDay hourOfRun
        if fetchedAt != some fetch then
          fetchedKwh := hourlyEnergy (forecastOf scenarioHours home.site seed home.errorScale
            fetch) fetch
          fetchedAt := some fetch
        let mut forecastRestKwh := 0.0
        for k in [hourOfRun + 1 - fetch : hoursInDay * (day + 1) - fetch] do
          forecastRestKwh := forecastRestKwh + fetchedKwh[k]?.getD 0.0
        let flexKwh := flexHours[scenarioHour.hour]!
        let observation : Observation :=
          { hour := scenarioHour.hour, tankKwh := states.map (·.energyKwh),
            socKwh := socKwh,
            surplusKwh := max 0.0 (pvKwh - (scenarioHour.baseLoadKwh + flexKwh)),
            forecastRestKwh, flexLeftKwh := home.site.flexKwh - flexToday, startsToday,
            askedLastHour := asked }
        action := { dynamicAction home.tanks params observation with flexKwh }
      let mut tankHours : Array TankHour := Array.mkEmpty home.tanks.size
      let mut tankLoadKwh := 0.0
      for i in [0:home.tanks.size] do
        let tank := home.tanks[i]!
        let askKwh := action.heatKwh[i]!
        let drawKwh := drawKwh (home.drawKwhPerDay * home.drawShares[i]!) home.site.latitude
          scenarioHour.dayOfYear scenarioHour.hour * factor
        let step := tankStep tank states[i]! scenarioHour.hour askKwh drawKwh
        states := states.set! i step.state
        tankLossKwh := tankLossKwh + step.lossKwh
        tankLoadKwh := tankLoadKwh + step.heatKwh + step.backstopKwh
        minTankKwh := minTankKwh.set! i (min minTankKwh[i]! step.state.energyKwh)
        if step.state.energyKwh < tank.floorKwh then coldHours := coldHours + 1
        if askKwh > 0 && !asked[i]! then
          policyStarts := policyStarts + 1
          startsToday := startsToday.modify i (· + 1)
        asked := asked.set! i (askKwh > 0)
        let tankHour : TankHour :=
          { drawKwh := drawKwh, askKwh := askKwh, heatKwh := step.heatKwh,
            backstopKwh := step.backstopKwh, unmetKwh := step.unmetKwh,
            energyKwh := step.state.energyKwh }
        tankHours := tankHours.push tankHour
      flexToday := flexToday + action.flexKwh
      let houseLoadKwh := scenarioHour.baseLoadKwh + action.flexKwh
      let limited := stepHourLimited home.limits home.battery socKwh action.allowCharge
        action.allowDischarge pvKwh (houseLoadKwh + tankLoadKwh)
      let flow := limited.flow
      socKwh := flow.socKwh
      let homeHour : HomeHour :=
        { day := day, hour := scenarioHour.hour, pvKwh := pvKwh, houseLoadKwh := houseLoadKwh,
          flexKwh := action.flexKwh, tanks := tankHours, allowCharge := action.allowCharge,
          allowDischarge := action.allowDischarge, flow := flow, curtailedKwh := limited.curtailedKwh }
      hours := hours.push homeHour
  let pvKwh := sumHours hours (·.pvKwh)
  let exportKwh := sumHours hours (·.flow.exportKwh)
  let curtailedKwh := sumHours hours (·.curtailedKwh)
  let importKwh := sumHours hours (·.flow.importKwh)
  let heatKwh := sumTankHours hours (·.heatKwh)
  let backstopKwh := sumTankHours hours (·.backstopKwh)
  let loadKwh := sumHours hours (·.houseLoadKwh) + heatKwh + backstopKwh
  let totals : HomeTotals :=
    { pvKwh, loadKwh, importKwh, exportKwh, curtailedKwh,
      batteryLossKwh := sumHours hours (·.flow.lossKwh), tankLossKwh, heatKwh, backstopKwh,
      drawKwh := sumTankHours hours (·.drawKwh), unmetKwh := sumTankHours hours (·.unmetKwh),
      selfConsumption := percent (pvKwh - exportKwh - curtailedKwh) pvKwh,
      selfSufficiency := percent (loadKwh - importKwh) loadKwh,
      minTankKwh, finalTankKwh := states.map (·.energyKwh), coldHours, policyStarts }
  return { hours, totals }

/-- One run of a home with a policy, from a full tank and an empty battery on 1 January. See
`runHomeOn`: this is the run on the scenario of the seed. -/
def runHome (home : Home) (policy : Policy) (seed days : Nat) : HomeResult :=
  runHomeOn home policy seed days (homeScenario home seed days)

/-- The summary of a policy over several seeds. -/
structure Evaluation where
  meanSelfConsumption : Float
  worstSelfConsumption : Float
  meanSelfSufficiency : Float
  meanImportKwh : Float
  meanExportKwh : Float
  meanCurtailedKwh : Float
  meanBackstopKwh : Float
  totalUnmetKwh : Float
  meanStartsPerDay : Float
  seeds : Nat
  unmetSeeds : Nat
  coldHours : Nat
  deriving Repr, Inhabited

/-- The mean of a value over the runs: 0 for no run. -/
private def meanOf (runs : Array HomeTotals) (value : HomeTotals → Float) : Float :=
  if runs.isEmpty then 0.0 else runs.foldl (fun sum run => sum + value run) 0.0 / runs.size.toFloat

/-- The evaluation of runs that are already made, one for each seed. `days` is the length of each
run. -/
private def summarise (runs : Array HomeTotals) (days : Nat) : Evaluation :=
  let startsPerDay (run : HomeTotals) : Float :=
    if days == 0 then 0.0 else run.policyStarts.toFloat / days.toFloat
  { meanSelfConsumption := meanOf runs (·.selfConsumption),
    worstSelfConsumption := runs.foldl (fun worst run => min worst run.selfConsumption)
      ((runs[0]?.map (·.selfConsumption)).getD 0.0),
    meanSelfSufficiency := meanOf runs (·.selfSufficiency),
    meanImportKwh := meanOf runs (·.importKwh), meanExportKwh := meanOf runs (·.exportKwh),
    meanCurtailedKwh := meanOf runs (·.curtailedKwh),
    meanBackstopKwh := meanOf runs (·.backstopKwh),
    totalUnmetKwh := runs.foldl (fun sum run => sum + run.unmetKwh) 0.0,
    meanStartsPerDay := meanOf runs startsPerDay,
    seeds := runs.size,
    unmetSeeds := (runs.filter (·.unmetKwh > 0.0)).size,
    coldHours := runs.foldl (fun sum run => sum + run.coldHours) 0 }

/-- The scenario of each seed from `seed`. -/
private def scenariosOf (home : Home) (seed seeds days : Nat) : Array (Array Hour) :=
  (Array.range seeds).map fun k => homeScenario home (seed + k) days

/-- The evaluation of a policy on scenarios that are already built. -/
private def evaluateOn (home : Home) (policy : Policy) (seed days : Nat)
    (scenarios : Array (Array Hour)) : Evaluation :=
  let runs := (Array.range scenarios.size).map fun k =>
    (runHomeOn home policy (seed + k) days scenarios[k]!).totals
  summarise runs days

/-- The evaluation of a policy over the seeds from `seed`: the run of each seed from `seed` to
`seed + seeds - 1`, with the mean, the worst and the total of R10. 0 seeds give 0 in each field. -/
def evaluate (home : Home) (policy : Policy) (seed seeds days : Nat) : Evaluation :=
  evaluateOn home policy seed days (scenariosOf home seed seeds days)

/-- What the tuner ranks by. -/
inductive Goal where
  | selfConsumption
  | gridImport
  deriving Repr, Inhabited, BEq

/-- The result of the tuner. -/
structure TuneResult where
  best : StaticParams
  evaluation : Evaluation
  candidates : Nat
  safe : Nat
  deriving Repr, Inhabited

/-- The candidates of D12, in the order of the start, the heating hours and the discharge hour.
Each candidate keeps the flexible-load start of the default static policy. -/
private def candidateGrid : Array StaticParams := Id.run do
  let mut grid := #[]
  for start in [6:17] do
    for hours in [1:9] do
      for discharge in [15:23] do
        grid := grid.push { windows := #[{ heatStart := start, heatHours := hours }],
                            dischargeFrom := discharge, flexStart := defaultStatic.flexStart }
  return grid

/-- The first measure of a goal, where higher is better: the import is negated. -/
private def firstMeasure (goal : Goal) (e : Evaluation) : Float :=
  match goal with
  | .selfConsumption => e.meanSelfConsumption
  | .gridImport => -e.meanImportKwh

/-- The width of a near tie in the first measure: 0.05 points, or 0.5 kWh. -/
private def nearTie (goal : Goal) : Float :=
  match goal with
  | .selfConsumption => 0.05
  | .gridImport => 0.5

/-- The second measure of a goal, which breaks a near tie: higher is better. -/
private def secondMeasure (goal : Goal) (e : Evaluation) : Float :=
  match goal with
  | .selfConsumption => -e.meanImportKwh
  | .gridImport => e.meanSelfConsumption

/-- The best static profile of the grid of D12 with the element of the home tank. A candidate is
safe when no seed has an unmet draw. The best safe candidate ranks first by the goal; the
candidates within the near tie of the first rank by the second measure, and a tie goes to the first
candidate. With no safe candidate, the best has the lowest total unmet draw. -/
def tuneStatic (home : Home) (goal : Goal) (seed seeds days : Nat) : TuneResult :=
  let scenarios := scenariosOf home seed seeds days
  let candidates := candidateGrid.map fun params =>
    (params, evaluateOn home (.static params) seed days scenarios)
  let safe := candidates.filter fun candidate => candidate.2.unmetSeeds == 0
  let empty : StaticParams × Evaluation := default
  let best : StaticParams × Evaluation :=
    if safe.isEmpty then
      candidates.foldl (init := candidates[0]?.getD empty) fun best candidate =>
        if candidate.2.totalUnmetKwh < best.2.totalUnmetKwh then candidate else best
    else
      let top := safe.foldl (init := (safe[0]?.getD empty).2) fun top candidate =>
        if firstMeasure goal candidate.2 > firstMeasure goal top then candidate.2 else top
      let floor := firstMeasure goal top - nearTie goal
      let tied := safe.filter fun candidate => firstMeasure goal candidate.2 ≥ floor
      tied.foldl (init := tied[0]?.getD empty) fun best candidate =>
        if secondMeasure goal candidate.2 > secondMeasure goal best.2 then candidate else best
  { best := best.1, evaluation := best.2, candidates := candidates.size, safe := safe.size }

end StoragePolicySim
