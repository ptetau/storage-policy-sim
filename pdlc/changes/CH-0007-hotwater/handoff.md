# Handoff · CH-0007 · tests → build

Time: 2026-11-15T12:32:16+00:00

### Done

- The test writer wrote 73 checks in `tests/CAP-hotwater.lean` for CAP-hotwater.R1 to R6: the lines of the spec, and extra checks for config fields, edges, chains of hours and the seam `drawSeed`. The lock is `ae785cd`, and the review passed in round 2 (round 1 found two problems).

### Decided on defaults

- none

### Open

- none

### Look here

- `tests/CAP-hotwater.lean`
- The Interface in `pdlc/changes/CH-0007-hotwater/change.md`

### Don't redo

- The checks and their lock.

### Next: do this first

Write `StoragePolicySim/HotWater.lean`. The hour runs in this order: the tank loses a share of its energy; the household draws (served is the smaller of the draw and the energy, the rest is unmet); the element heats by the request, never more than the element power for one hour and never more than the room; then the thermostat decides (it cuts in below the cut-in level, or from the guard hour when the tank was not full today, and stays on until the tank is full within 0.000000001 kWh); the backstop heating is the element power that the policy left, never more than the room. `fullToday` resets at hour 0 and becomes true in the hour in which the tank is full. `drawFactor` is `exp(cv × z - cv × cv / 2)` where z is a normal number from a hash of the seed and the day. Write the hash and the normal draw in this file, because the ones in Forecast.lean are private.
