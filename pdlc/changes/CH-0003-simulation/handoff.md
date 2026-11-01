# Handoff · CH-0003 · build → verify

Time: 2026-11-01T01:11:19+00:00

## Done

- The builder keeps the stored energy from 0 to the capacity after each hour, in `stepHour`.
- The greedy run with a 5 kWh battery now has no hour below 0 kWh. All 123 checks pass, and no check changed since the lock.

## Decided on defaults

- none

## Open

- none

## Look here

- `StoragePolicySim/Simulation.lean`: `stepHour`

## Don't redo

- The checks and the demo script.

## Next: do this first

Make the re-review packets with `make_packets.py CH-0003 --verify`.
