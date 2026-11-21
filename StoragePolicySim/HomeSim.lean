/-
The simulation of a home with a policy, the evaluation over seeds, and the tuner. Built: the
structures, `defaultHome`, `runHome` for the three policies with any panel arrays and the limits of
the inverter and the export (with any number of tanks), `dayForecast`, `evaluate`, `tuneStatic` (the search over
more tanks too), and the five homes of D20 and D21 (`homeNames`, `homeNamed`). A `Runner` gives the
totals of a policy for one seed: `evaluateRunners` and `tuneWith` serve the simple model and the
physics model (`PhysRun`).
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
  /-- The space heating of each day of the year in kWh, read by the physics run only. Empty means
  none. -/
  heatDayKwh : Array Float := #[]
  /-- The share of the space heating of a day that falls in each hour. -/
  heatShape : Array Float := #[]
  /-- The set point of the tanks on each day of the year, read by the physics run only. Empty
  means 60 degrees. -/
  setPointByDay : Array Float := #[]
  deriving Repr, Inhabited

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

/-- The names of the homes of D20, in the order that an error lists them. -/
def homeNames : List String := ["generic", "small", "family", "no-battery", "mine"]

/-- A tank of a capacity and an element power, with the cut-in at half of its capacity, the floor
at 20% of it, and the loss and the guard hour of the default tank (D20). -/
def tankOf (capacityKwh elementKw : Float) : TankConfig :=
  { defaultTank with capacityKwh, elementKw, cutInKwh := capacityKwh / 2,
                     floorKwh := capacityKwh * 0.2 }

/-- A home with one north array, one tank, and the values of `generic` for the rest (D20). -/
private def northHome (pvKw batteryKwh powerKw : Float) (tank : TankConfig)
    (loadKwh drawKwh : Float) : Home :=
  { defaultHome with
    site := { defaultHome.site with pvKw, dailyLoadKwh := loadKwh, flexKwh := min 3.0 loadKwh },
    arrays := #[{ kw := pvKw, direction := 0.0, tilt := 30.0 }],
    battery := { capacityKwh := batteryKwh, powerKw },
    tanks := #[tank], drawKwhPerDay := drawKwh }

/-- The home `mine` of D21: five arrays, a battery of 13.5 kWh with an inverter and an export
limit, and two tanks that share the draw by their capacity. -/
private def mineHome : Home :=
  let arrays : Array PanelArray :=
    #[{ kw := 4.32, direction := 0.0, tilt := 15.0 },
      { kw := 2.88, direction := 270.0, tilt := 30.0 },
      { kw := 2.88, direction := 90.0, tilt := 30.0 },
      { kw := 2.40, direction := 0.0, tilt := 30.0 },
      { kw := 2.40, direction := 180.0, tilt := 30.0 }]
  { defaultHome with
    site := { defaultHome.site with pvKw := arrays.foldl (fun sum array => sum + array.kw) 0.0 },
    arrays,
    battery := { capacityKwh := 13.5, powerKw := 11.0 },
    limits := { inverterKw := 11.0, exportKw := 10.0 },
    tanks := #[tankOf 13.1 3.3, tankOf 9.4 2.5], drawShares := #[0.58, 0.42],
    drawKwhPerDay := 11.0 }

/-- The home of a name (D20, D21), or `none` for another name. -/
def homeNamed (name : String) : Option Home :=
  match name with
  | "generic" => some defaultHome
  | "small" => some (northHome 3.0 5.0 3.0 (tankOf 7.1 2.0) 12.0 4.0)
  | "family" => some (northHome 8.0 13.5 5.0 (tankOf 15.7 3.0) 30.0 10.0)
  | "no-battery" =>
    some { defaultHome with battery := { defaultHome.battery with capacityKwh := 0.0 } }
  | "mine" => some mineHome
  | _ => none

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
def expectedDraw (home : Home) (dayOfYear : Nat) : Array Float :=
  (Array.range home.tanks.size).map fun i =>
    (Array.range hoursInDay).foldl (init := 0.0) fun sum hour =>
      sum + drawKwh (home.drawKwhPerDay * home.drawShares[i]!) home.site.latitude dayOfYear hour

/-- The sum of a value over the hours of a run. -/
private def sumHours (hours : Array HomeHour) (value : HomeHour → Float) : Float :=
  hours.foldl (fun sum hour => sum + value hour) 0.0

/-- The sum of a value of each tank over the hours of a run. -/
private def sumTankHours (hours : Array HomeHour) (value : TankHour → Float) : Float :=
  sumHours hours fun hour => hour.tanks.foldl (fun sum tank => sum + value tank) 0.0

/-- The forecast solar energy of each hour of a day, from the fetch at hour 0 of that day, as the
precomputed policy reads it. `runHomeOn`, `dayForecast` and the physics run share this. -/
def forecastOfDay (home : Home) (seed : Nat) (scenarioHours : Array Hour) (day : Nat) :
    Array Float :=
  let fetch := hoursInDay * day
  (hourlyEnergy (forecastOf scenarioHours home.site seed home.errorScale fetch) fetch).extract
    0 hoursInDay

/-- The forecast solar energy of the 48 hours from hour `fetch` of a run, as the dynamic policy
reads it from the fetch at that hour. -/
def fetchedEnergy (home : Home) (seed : Nat) (scenarioHours : Array Hour) (fetch : Nat) :
    Array Float :=
  hourlyEnergy (forecastOf scenarioHours home.site seed home.errorScale fetch) fetch

/-- The forecast solar energy of the hours after hour `hourOfRun` to the end of `day`, from the
hourly energy of the fetch at hour `fetch` (see `fetchedEnergy`). -/
def restOfDayForecast (fetchedKwh : Array Float) (fetch hourOfRun day : Nat) : Float := Id.run do
  let mut rest := 0.0
  for k in [hourOfRun + 1 - fetch : hoursInDay * (day + 1) - fetch] do
    rest := rest + fetchedKwh[k]?.getD 0.0
  return rest

/-- The forecast solar energy of each hour of a day of a run, as the precomputed policy of
`runHome` reads it at hour 0 of the day. -/
def dayForecast (home : Home) (seed days day : Nat) : Array Float :=
  forecastOfDay home seed (homeScenario home seed days) day

/-- One run of a home with a policy, from a full tank and an empty battery on 1 January. In each
hour, the policy gives its action, each tank runs its hour, the heating and the backstop heating
join the house load, and the battery runs its hour. A precomputed policy plans at hour 0 of each
day, from the forecast of the fetch at hour 0. A dynamic policy reads the latest fetch. The
flexible load runs as each policy places it (D25). The run counts the starts of each tank, and a
dynamic policy sees the starts of the day and the last request of each tank (D26). -/
private def runHomeOn (home : Home) (policy : Policy) (seed days : Nat)
    (scenarioHours : Array Hour) : HomeResult := Id.run do
  -- A static policy gives the same actions each day: build them once.
  let staticPlan : Array Action := match policy with
    | .static params => staticProfile home.tanks params home.site.flexKwh
    | _ => #[]
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
      let forecastKwh := forecastOfDay home seed scenarioHours day
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
          fetchedKwh := fetchedEnergy home seed scenarioHours fetch
          fetchedAt := some fetch
        let forecastRestKwh := restOfDayForecast fetchedKwh fetch hourOfRun day
        let observation : Observation :=
          { hour := scenarioHour.hour, tankKwh := states.map (·.energyKwh),
            socKwh := socKwh,
            surplusKwh := max 0.0 (pvKwh - scenarioHour.baseLoadKwh),
            forecastRestKwh, flexLeftKwh := home.site.flexKwh - flexToday, startsToday,
            askedLastHour := asked }
        action := dynamicAction home.tanks params observation
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

/-- The run of one seed: the totals of a policy. A runner holds what does not depend on the policy
(the scenario of the seed), so that the tuner builds it once. -/
abbrev Runner := Policy → HomeTotals

/-- The runner of each seed from `seed` on the simple model: the scenarios are built once. -/
private def simpleRunners (home : Home) (seed seeds days : Nat) : Array Runner :=
  let scenarios := scenariosOf home seed seeds days
  (Array.range seeds).map fun k policy =>
    (runHomeOn home policy (seed + k) days scenarios[k]!).totals

/-- The evaluation of a policy over runners that are already built, one for each seed. -/
def evaluateRunners (runners : Array Runner) (policy : Policy) (days : Nat) : Evaluation :=
  summarise (runners.map fun run => run policy) days

/-- The evaluation of a policy over the seeds from `seed`: the run of each seed from `seed` to
`seed + seeds - 1`, with the mean, the worst and the total of R10. 0 seeds give 0 in each field. -/
def evaluate (home : Home) (policy : Policy) (seed seeds days : Nat) : Evaluation :=
  evaluateRunners (simpleRunners home seed seeds days) policy days

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

/-- The windows of D12, in the order of the start and the heating hours. -/
private def windowGrid : Array TankWindow := Id.run do
  let mut grid := #[]
  for start in [6:17] do
    for hours in [1:9] do
      grid := grid.push { heatStart := start, heatHours := hours }
  return grid

/-- The discharge hours of D12. -/
private def dischargeGrid : Array Nat := (Array.range 8).map (· + 15)

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

/-- The best candidate of a list, and the count of its safe candidates. A candidate is safe when no
seed has an unmet draw. The best safe candidate ranks first by the goal; the candidates within the
near tie of the first rank by the second measure, and a tie goes to the first candidate. With no
safe candidate, the best has the lowest total unmet draw. -/
private def pickBest (goal : Goal) (candidates : Array (StaticParams × Evaluation)) :
    (StaticParams × Evaluation) × Nat :=
  let safe := candidates.filter fun candidate => candidate.2.unmetSeeds == 0
  let empty : StaticParams × Evaluation := default
  if safe.isEmpty then
    (candidates.foldl (init := candidates[0]?.getD empty) fun best candidate =>
      if candidate.2.totalUnmetKwh < best.2.totalUnmetKwh then candidate else best, 0)
  else
    let top := safe.foldl (init := (safe[0]?.getD empty).2) fun top candidate =>
      if firstMeasure goal candidate.2 > firstMeasure goal top then candidate.2 else top
    let floor := firstMeasure goal top - nearTie goal
    let tied := safe.filter fun candidate => firstMeasure goal candidate.2 ≥ floor
    (tied.foldl (init := tied[0]?.getD empty) fun best candidate =>
      if secondMeasure goal candidate.2 > secondMeasure goal best.2 then candidate else best,
     safe.size)

/-- The best static profile with the element of each tank of the home. With one tank, the
candidates are the 704 of D12, in the order of the start, the heating hours and the discharge hour.
With more tanks (D23), the search takes the window of one tank at a time, in tank order, from the
default window of each tank and the default discharge hour, with the other tanks at their best
window so far (88 candidates for each tank), and then the discharge hour (8 candidates). Each
candidate keeps the flexible-load start of the default static policy. The runners (one for each
seed) give the model. -/
def tuneWith (home : Home) (goal : Goal) (runners : Array Runner) (days : Nat) : TuneResult :=
  let evaluateParams (params : StaticParams) : StaticParams × Evaluation :=
    (params, evaluateRunners runners (.static params) days)
  if home.tanks.size ≤ 1 then
    let candidates := windowGrid.flatMap fun window =>
      dischargeGrid.map fun discharge =>
        evaluateParams { windows := #[window], dischargeFrom := discharge,
                         flexStart := defaultStatic.flexStart }
    let (best, safe) := pickBest goal candidates
    { best := best.1, evaluation := best.2, candidates := candidates.size, safe }
  else
    let start : StaticParams :=
      { defaultStatic with windows := home.tanks.map fun _ => defaultStatic.windows[0]! }
    let (params, count, safe) := (Array.range home.tanks.size).foldl
      (init := (start, 0, 0)) fun (params, count, safe) i =>
        let tried := windowGrid.map fun window =>
          evaluateParams { params with windows := params.windows.set! i window }
        let (best, safeHere) := pickBest goal tried
        (best.1, count + tried.size, safe + safeHere)
    let tried := dischargeGrid.map fun discharge =>
      evaluateParams { params with dischargeFrom := discharge }
    let (best, safeHere) := pickBest goal tried
    { best := best.1, evaluation := best.2, candidates := count + tried.size,
      safe := safe + safeHere }

/-- `tuneWith` on the simple model, over the seeds from `seed`. -/
def tuneStatic (home : Home) (goal : Goal) (seed seeds days : Nat) : TuneResult :=
  tuneWith home goal (simpleRunners home seed seeds days) days

end StoragePolicySim
