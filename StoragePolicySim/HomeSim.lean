/-
The simulation of a home with a policy, the evaluation over seeds, and the tuner. Built: the
structures, `defaultHome`, and `runHome` for the static policy and one flat array. Not built yet:
`homeNames` (a placeholder), `homeNamed`, `evaluate` and `tuneStatic` (stubs), `runHome` for the
precomputed and the dynamic policy, and the panel arrays other than one flat array.
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

/-- The solar energy of a scenario hour. A home with one flat array gives the solar energy of
the scenario. Not built yet for other arrays (the slice of the panel arrays owns them). -/
private def solarOf (_home : Home) (hour : Hour) : Float := hour.pvKwh

/-- The 24 actions of a day. The static policy repeats one profile each day. Not built yet for
the precomputed and the dynamic policy. -/
private def dayActions (home : Home) (policy : Policy) : Array Action :=
  match policy with
  | .static params => staticProfile home.tanks params home.site.flexKwh
  | .precomputed _ => todo "runHome precomputed policy" 0
  | .dynamic _ => todo "runHome dynamic policy" 0

/-- The sum of a value over the hours of a run. -/
private def sumHours (hours : Array HomeHour) (value : HomeHour → Float) : Float :=
  hours.foldl (fun sum hour => sum + value hour) 0.0

/-- The sum of a value of each tank over the hours of a run. -/
private def sumTankHours (hours : Array HomeHour) (value : TankHour → Float) : Float :=
  sumHours hours fun hour => hour.tanks.foldl (fun sum tank => sum + value tank) 0.0

/-- One run of a home with a policy, from a full tank and an empty battery on 1 January. In each
hour, the policy gives its action, each tank runs its hour, the heating and the backstop heating
join the house load, and the battery runs its hour. -/
def runHome (home : Home) (policy : Policy) (seed days : Nat) : HomeResult := Id.run do
  let scenarioHours := scenario home.site seed days
  let mut states := home.tanks.map startState
  let mut minTankKwh := home.tanks.map (·.capacityKwh)
  let mut asked := Array.replicate home.tanks.size false
  let mut socKwh := 0.0
  let mut tankLossKwh := 0.0
  let mut coldHours := 0
  let mut policyStarts := 0
  let mut hours : Array HomeHour := Array.mkEmpty scenarioHours.size
  for day in [0:days] do
    let actions := dayActions home policy
    let factor := drawFactor seed day home.drawCv
    for scenarioHour in scenarioHours.extract (hoursInDay * day) (hoursInDay * (day + 1)) do
      let action := actions[scenarioHour.hour]!
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
        if askKwh > 0 && !asked[i]! then policyStarts := policyStarts + 1
        asked := asked.set! i (askKwh > 0)
        let tankHour : TankHour :=
          { drawKwh := drawKwh, askKwh := askKwh, heatKwh := step.heatKwh,
            backstopKwh := step.backstopKwh, unmetKwh := step.unmetKwh,
            energyKwh := step.state.energyKwh }
        tankHours := tankHours.push tankHour
      let pvKwh := solarOf home scenarioHour
      let houseLoadKwh := scenarioHour.baseLoadKwh + action.flexKwh
      let flow := stepHourGated home.battery socKwh action.allowCharge action.allowDischarge
        pvKwh (houseLoadKwh + tankLoadKwh)
      socKwh := flow.socKwh
      let homeHour : HomeHour :=
        { day := day, hour := scenarioHour.hour, pvKwh := pvKwh, houseLoadKwh := houseLoadKwh,
          flexKwh := action.flexKwh, tanks := tankHours, allowCharge := action.allowCharge,
          allowDischarge := action.allowDischarge, flow := flow, curtailedKwh := 0.0 }
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

/-- The evaluation of a policy over the seeds from `seed`. Not built yet. -/
def evaluate (home : Home) (policy : Policy) (seed seeds days : Nat) : Evaluation :=
  let _ := (home, policy, seeds, days)
  todo "evaluate" seed

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

/-- The best static profile of the search. Not built yet. -/
def tuneStatic (home : Home) (goal : Goal) (seed seeds days : Nat) : TuneResult :=
  let _ := (home, goal, seeds, days)
  todo "tuneStatic" seed

end StoragePolicySim
