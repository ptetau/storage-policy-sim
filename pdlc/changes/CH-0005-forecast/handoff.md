# Handoff · CH-0005 · tests → build

Time: 2026-11-15T10:31:37+00:00

### Done

- The acceptance checks of IN-0002 are also the checks of CH-0005 (forecast). The file has 57 checks, locked at `3456206`, and the review passed.

### Decided on defaults

- none

### Open

- none

### Look here

- `tests/acceptance/IN-0002.acceptance.lean`
- The Interface in `pdlc/changes/CH-0005-forecast/change.md`

### Don't redo

- The checks and their lock.

### Next: do this first

Write `StoragePolicySim/Forecast.lean`. A static policy does not need it, but the library must stay fast: a forecast call must not rebuild the whole scenario more than once.
