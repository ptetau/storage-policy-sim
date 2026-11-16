# Handoff · CH-0007 · build → verify

Time: 2026-11-16T05:02:21+00:00

### Done

- `StoragePolicySim/HotWater.lean` now has one helper, `fullEarlierToday`, for the day reset of the tank. `thermostatOn` and `tankStep` both call it.
- All 73 checks of `tests/CAP-hotwater.lean` pass again.

### Decided on defaults

- none

### Open

- none

### Look here

- `StoragePolicySim/HotWater.lean`

### Don't redo

- The checks and the other remits.

### Next: do this first

Verify CH-0007 again (round 2).
