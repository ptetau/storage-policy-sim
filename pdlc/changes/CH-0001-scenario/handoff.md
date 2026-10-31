# Handoff · CH-0001 · tests → build

Time: 2026-10-31T23:21:28+00:00

## Done

- The test writer wrote 36 checks in `tests/CAP-scenario.lean`, for R1 (seasonal sun), R2 (daily weather) and R3 (household load).
- The checks failed before any code, because the library and `lakefile.toml` do not exist yet.
- The lock is `0185f3e`. The tests review passed with no problem.

## Decided on defaults

- none

## Open

- The acceptance check of CAP-simulation.R2 (battery limits) needs an hour that discharges 2 kWh, from a 5 kWh battery with 2 kW. The evening load profile must give a shortfall above 2 kWh in some hours.

## Look here

- `tests/CAP-scenario.lean`
- The "Interface" of `pdlc/changes/CH-0001-scenario/change.md`

## Don't redo

- The checks and their lock.

## Next: do this first

Create `lakefile.toml` with the library `StoragePolicySim` and its modules, and `lean-toolchain` with `leanprover/lean4:v4.35.0`. Then write `StoragePolicySim/Scenario.lean`.
