/-
The physics model of a hot-water tank in litres and degrees. Not built yet.
-/
import StoragePolicySim.HotWater
import StoragePolicySim.Stub

namespace StoragePolicySim

/-- The energy that one litre of water takes for one degree, in kWh. -/
def kwhPerLitreK : Float := 0.001163

/-- A tank in litres. -/
structure PhysTank where
  litres : Float
  elementKw : Float
  uaKwPerK : Float
  cutInShare : Float
  floorShare : Float
  guardHour : Nat
  deriving Repr, Inhabited

/-- Not built yet. -/
def physTankOf (cfg : TankConfig) : PhysTank := let _ := cfg; todo "physTankOf" cfg.guardHour

/-- The state of a tank. -/
structure PhysTankState where
  hotLitres : Float
  heating : Bool
  fullToday : Bool
  deriving Repr, Inhabited

/-- Not built yet. -/
def physStart (t : PhysTank) : PhysTankState := let _ := t; todo "physStart" t.guardHour
/-- Not built yet. -/
def tankEnergyKwh (state : PhysTankState) (inletC : Float) : Float :=
  let _ := state; todo "tankEnergyKwh" inletC.toUInt64.toNat

/-- The result of one step of a tank. -/
structure PhysTankStep where
  lossKwh : Float
  servedKwh : Float
  unmetKwh : Float
  heatKwh : Float
  backstopKwh : Float
  state : PhysTankState
  deriving Repr, Inhabited

/-- Not built yet. -/
def physTankStep (t : PhysTank) (state : PhysTankState) (step : Nat) (requestKwh tapLitres inletC : Float) :
    PhysTankStep :=
  let _ := (t, state, requestKwh, tapLitres, inletC); todo "physTankStep" step

end StoragePolicySim
