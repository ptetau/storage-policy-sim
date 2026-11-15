# Handoff · CH-0005 · build → verify

Time: 2026-11-15T10:37:40+00:00

### Done

- The builder wrote `StoragePolicySim/Forecast.lean`. The 57 acceptance checks of IN-0002 pass, and so do the earlier check files.
- CAP-forecast.R1 (forecast periods) to R5 (hourly forecast energy) are now `built`.

### Decided on defaults

- none

### Open

- Each `forecast` call builds the scenario again, about 30 ms in the interpreter. A policy that fetches many times needs a call that takes the built hours. IN-0008 (hot-water policy simulation) adds one.

### Look here

- `StoragePolicySim/Forecast.lean`

### Don't redo

- The code and the checks.

### Next: do this first

Make the review packets with `make_packets.py CH-0005 --verify`.
