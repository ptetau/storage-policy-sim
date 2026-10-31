# Handoff · CH-0002 · build → verify

Time: 2026-10-31T23:57:49+00:00

## Done

- The builder wrote `StoragePolicySim/Strategy.lean` with the four strategies of the Interface.
- All checks pass: 35 in `tests/CAP-strategies.lean` and 34 in `tests/CAP-scenario.lean`. No check changed since the lock `91d1e6b`.
- CAP-strategies.R1 (strategy names) to R5 (load shift into sun) are now `built`.

## Decided on defaults

- none

## Open

- none

## Look here

- `StoragePolicySim/Strategy.lean`

## Don't redo

- The code and the checks.

## Next: do this first

Make the review packets with `make_packets.py CH-0002 --verify`.
