/-
The run of a home with a policy on the physics model. Not built yet.
-/
import StoragePolicySim.HomeSim
import StoragePolicySim.PhysWeather
import StoragePolicySim.PhysTank
import StoragePolicySim.PhysAppliances

namespace StoragePolicySim

/-- Not built yet. -/
def runPhysics (home : Home) (policy : Policy) (seed days : Nat) : HomeResult :=
  let _ := (home, policy); todo "runPhysics" (seed + days)

end StoragePolicySim
