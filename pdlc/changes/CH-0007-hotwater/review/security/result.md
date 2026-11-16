Result: pass

Remit: security

Problems: none

Follow-ups:
- Check the hour range in `drawKwh` (and `tankStep`). The spec says the hour is 0 to 23 and the errors are "none". An hour of 24 or more makes `profile[hour]!` panic. Lean prints a panic message and returns 0.0, so the caller gets a silent wrong draw. A new intent could add an `OUT_OF_RANGE` check (an error code in DES-errors) at the edge where the hour comes in.
- Reject or clamp a negative or non-finite `drawKwh`, `requestKwh`, `dailyKwh` or `cv`. No acceptance line asks for this. A negative draw adds energy to the tank and can lift it above its capacity. A NaN input gives a NaN state. A new intent could add this guard at the edge where the numbers come in.
- Cap `cv` in `drawFactor`. The interface says the factor is more than 0. For a very large `cv`, `Float.exp` underflows to 0 or overflows to infinity. The acceptance lines use only 0, 0.25 and 0.5, and all of them hold. A new intent could add a range for `cv`.

Notes:
- The change touches only `StoragePolicySim/HotWater.lean`. That file is the one entry under "Files".
- The module has no imports, so it adds no dependency.
- The code has no IO, no strings built from input, no paths, no commands, no queries, and no HTML. Thus no injection is possible here.
- The code has no secrets, no logs, and no error text. It has no access check, so there is nothing to fail open.
- The random numbers use SplitMix64 and Box-Muller. They are for simulation only, and the spec does not ask for cryptographic strength. `unitFloat` gives a value above 0, so `Float.log` never sees 0.
- The interface in the packet matches the code: the types, the field names, `defaultTank`, `startState`, `tankStep`, `drawKwh`, and `drawFactor`. The seam `drawSeed` is the `seed` argument of `drawFactor`.
- I traced a sample of lines from R1 (standby loss and draw), R2 (heating limits), R3 (thermostat), R5 (daily full heating) and R4 (draw profile) against the code by hand. I found no break. This is a spot check, not the tests remit.
