# Handoff · CH-0006 · build → verify

Time: 2026-11-15T12:11:27+00:00

### Done

- `StoragePolicySim/Forecast.lean` has `forecastOf`, and `forecast` calls it. The random number of a period has a shared part for the day of the period (CAP-forecast.R7).
- All 15 checks of `tests/CAP-forecast.lean` pass in 1.8 s. The older component checks and the acceptance files of IN-0001 and IN-0002 pass. Three checks of IN-0001 (the usage line) fail until CH-0011 builds the new usage.

### Decided on defaults

- none

### Open

- none

### Look here

- `StoragePolicySim/Forecast.lean`
- `tests/CAP-forecast.lean`

### Don't redo

- The checks and their lock.

### Next: do this first

Verify CH-0006. Check that `forecast` and `forecastOf` share one code path, and that the marginal error of a period is still normal.
