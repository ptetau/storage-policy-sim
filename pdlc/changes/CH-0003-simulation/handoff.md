# Handoff · CH-0003 · tests → build

Time: 2026-11-01T01:03:24+00:00

## Done

- The test writer wrote 54 checks in `tests/CAP-simulation.lean`, for R1 (energy flows of an hour) to R5 (strategy order).
- The checks compile against the Interface, and they fail because `StoragePolicySim/Simulation.lean` does not exist yet.
- The lock is `ba51e5b`, and the tests review passed.

## Decided on defaults

- none

## Open

- none

## Look here

- `tests/CAP-simulation.lean`
- The "Interface" of `pdlc/changes/CH-0003-simulation/change.md`

## Don't redo

- The checks and their lock.

## Next: do this first

Write `StoragePolicySim/Simulation.lean`. The power limit applies to the energy that goes into the battery, and to the energy that the battery gives after the loss.
