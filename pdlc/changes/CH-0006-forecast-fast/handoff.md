# Handoff · CH-0006 · tests → build

Time: 2026-11-15T12:08:52+00:00

### Done

- The test writer wrote 15 checks in `tests/CAP-forecast.lean`: 10 for CAP-forecast.R6 (forecast from built hours) and 5 for CAP-forecast.R7 (shared error of a day). The lock is `608aff7`, and the review passed in round 1.
- The acceptance file of IN-0008 holds the same lines, and it also fails until CH-0011 is built.

### Decided on defaults

- none

### Open

- none

### Look here

- `tests/CAP-forecast.lean`
- The Interface in `pdlc/changes/CH-0006-forecast-fast/change.md`

### Don't redo

- The checks and their lock.

### Next: do this first

Edit `StoragePolicySim/Forecast.lean`. Add `forecastOf`, which gives the same periods as `forecast` from hours that the caller built once. Make `forecast` call `forecastOf`, so that the two share one code path: the checks compare floats for exact equality. Then add the shared error of a day (CAP-forecast.R7): the random number of a period is `sqrt(0.7) × d + sqrt(0.3) × e`, where `d` depends only on the seed and on the day of the run in which the period ends. All checks of IN-0001 and IN-0002 must still pass.
