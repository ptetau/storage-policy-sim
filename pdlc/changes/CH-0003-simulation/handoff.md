# Handoff · CH-0003 · build → verify

Time: 2026-11-01T01:05:23+00:00

## Done

- The builder wrote `StoragePolicySim/Simulation.lean` with the items of the Interface.
- All 123 checks pass: 34 in `tests/CAP-scenario.lean`, 35 in `tests/CAP-strategies.lean` and 54 in `tests/CAP-simulation.lean`.
- No check changed since the lock `ba51e5b`. CAP-simulation.R1 (energy flows of an hour) to R5 (strategy order) are now `built`.

## Decided on defaults

- none

## Open

- none

## Look here

- `StoragePolicySim/Simulation.lean`

## Don't redo

- The code and the checks.

## Next: do this first

Make the review packets with `make_packets.py CH-0003 --verify`.
