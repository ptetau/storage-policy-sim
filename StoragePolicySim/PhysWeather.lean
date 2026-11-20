/-
The physics model of the sun, the cloud, the panels and the temperatures. Not built yet.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Stub

namespace StoragePolicySim

/-- The steps of a day: a step is a quarter of an hour. -/
def stepsPerDay : Nat := 96

/-- Not built yet. -/
def haurwitzWm2 (cosZ : Float) : Float := todo "haurwitzWm2" cosZ.toUInt64.toNat
/-- Not built yet. -/
def clearSkyWm2 (latitude : Float) (dayOfYear step : Nat) : Float :=
  let _ := latitude; todo "clearSkyWm2" (dayOfYear + step)
/-- Not built yet. -/
def dayClearness (latitude : Float) (seed days : Nat) : Array Float :=
  let _ := latitude; todo "dayClearness" (seed + days)
/-- Not built yet. -/
def clearness (latitude : Float) (seed days : Nat) : Array Float :=
  let _ := latitude; todo "clearness" (seed + days)
/-- Not built yet. -/
def diffuseShare (clearness : Float) : Float := todo "diffuseShare" clearness.toUInt64.toNat
/-- Not built yet. -/
def panelWm2 (latitude : Float) (array : PanelArray) (dayOfYear step : Nat) (clearness : Float) : Float :=
  let _ := (latitude, array, clearness); todo "panelWm2" (dayOfYear + step)
/-- Not built yet. -/
def cellTempC (airC lightWm2 : Float) : Float := let _ := airC; todo "cellTempC" lightWm2.toUInt64.toNat
/-- Not built yet. -/
def arrayKw (array : PanelArray) (lightWm2 airC : Float) : Float :=
  let _ := (array, airC); todo "arrayKw" lightWm2.toUInt64.toNat
/-- Not built yet. -/
def airTempC (latitude : Float) (dayOfYear step : Nat) (clearnessOfDay : Float) : Float :=
  let _ := (latitude, clearnessOfDay); todo "airTempC" (dayOfYear + step)
/-- Not built yet. -/
def inletTempC (latitude : Float) (dayOfYear : Nat) : Float := let _ := latitude; todo "inletTempC" dayOfYear

end StoragePolicySim
