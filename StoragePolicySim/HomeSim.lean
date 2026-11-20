/-
The simulation of a home with a policy, the evaluation over seeds, and the tuner. Not built yet:
each function is a stub, and each default is a placeholder.
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

/-- A placeholder. Not built yet. -/
def defaultHome : Home := default

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

/-- One run of a home with a policy. Not built yet. -/
def runHome (home : Home) (policy : Policy) (seed days : Nat) : HomeResult :=
  let _ := (home, policy, days)
  todo "runHome" seed

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
