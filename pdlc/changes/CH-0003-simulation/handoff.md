# Handoff · CH-0003 · show → build

Time: 2026-11-01T01:10:21+00:00

## Done

- Show wrote the script of the recording. Frame 12 and the frame of R2 (battery limits) show "lowest stored energy: -0.000 kWh".
- A greedy run with a 5 kWh battery and 2 kW of power has 633 such hours. Each ends at about -2e-16 kWh.
- This round is round 2 of 2 of CH-0003 (simulation).

## Decided on defaults

- none

## Open

- StoragePolicySim/Simulation.lean: `stepHour` · After a full discharge, `socKwh - dischargeKwh / efficiency` can give a value a little below 0. The stored energy must stay from 0 to the capacity after each hour. Keep `socKwh` from 0 to `capacityKwh` after the hour, with the plainest fix. · CAP-simulation.R2 (battery limits): "the battery holds 0 to 5 kWh each hour".

## Look here

- `StoragePolicySim/Simulation.lean`: `stepHour`

## Don't redo

- The checks, the reviews, and the demo script.

## Next: do this first

Fix the stored energy in `stepHour`, run all checks, and send the change to verify again.
