# Handoff · CH-0007 · build → verify

Time: 2026-11-16T04:59:54+00:00

### Done

- `StoragePolicySim/HotWater.lean` has the tank, its state, the hour step with the thermostat and the daily full heating, the draw profile, and the daily draw factor.
- All 73 checks of `tests/CAP-hotwater.lean` pass. The older component checks and the acceptance file of IN-0002 pass. Three checks of IN-0001 (the usage line) fail until CH-0011 builds the new usage.
- The builder agent stopped on a usage limit after it wrote the file. The skill ran the checks itself, and no check changed.

### Decided on defaults

- none

### Open

- none

### Look here

- `StoragePolicySim/HotWater.lean`
- `tests/CAP-hotwater.lean`

### Don't redo

- The checks and their lock.

### Next: do this first

Verify CH-0007. Check the order of the hour (loss, draw, heating, thermostat) and the use of the guard hour.
