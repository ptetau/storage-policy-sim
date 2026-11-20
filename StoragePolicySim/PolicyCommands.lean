/-
The `sim forecast` and `sim policy` commands. Not built yet.
-/
import StoragePolicySim.HomeSim

namespace StoragePolicySim

/-- Runs `sim forecast` with its words. Not built yet. -/
def forecastCommand (words : List String) : IO UInt32 := do
  let _ := words
  IO.eprintln "error: not implemented"
  return 3

/-- Runs `sim policy` with its words. Not built yet. -/
def policyCommand (words : List String) : IO UInt32 := do
  let _ := words
  IO.eprintln "error: not implemented"
  return 3

end StoragePolicySim
