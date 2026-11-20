/-
The physics model of the battery, the flexible appliances and the base load. Not built yet.
-/
import StoragePolicySim.Simulation
import StoragePolicySim.Stub

namespace StoragePolicySim

/-- Not built yet. -/
def physBatteryStep (limits : Limits) (battery : Battery) (socKwh : Float)
    (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : LimitedFlow :=
  let _ := (limits, battery, socKwh, allowCharge, allowDischarge, loadKwh); todo "physBatteryStep" pvKwh.toUInt64.toNat

/-- One run of an appliance: its energy in each step. -/
structure Cycle where
  name : String
  stepKwh : Array Float
  deriving Repr, Inhabited

/-- A placeholder. Not built yet. -/
def dishwasher : Cycle := default
/-- A placeholder. Not built yet. -/
def washingMachine : Cycle := default
/-- A placeholder. Not built yet. -/
def dryer : Cycle := default

/-- Not built yet. -/
def applianceCycles (seed day : Nat) : Array Cycle := todo "applianceCycles" (seed + day)
/-- Not built yet. -/
def baseLoadKw (dailyKwh latitude : Float) (dayOfYear step : Nat) : Float :=
  let _ := (dailyKwh, latitude); todo "baseLoadKw" (dayOfYear + step)

end StoragePolicySim
