# Handoff · CH-0003 · verify → build

Time: 2026-11-01T01:06:41+00:00

## Done

- Verify round 1 of CH-0003 (simulation) failed on quality. Specification, security and privacy passed. Compliance does not apply.
- The security follow-up on `Battery` and `Site` values went into IN-0005 (guards on inputs). JOB-simulate.R5 (bad command line) already limits `--days`.

## Decided on defaults

- none

## Open

- StoragePolicySim/Simulation.lean:175 · In `simulate`, the condition `&& openMonth.days > 0` never changes the result. On day 0, `month` is 0 and `openMonth.month` is 0, so the first part is already false. On each later day, `openMonth.days` is 1 or more. Remove the second part, so that the reader does not look for a case that cannot happen. · Remit rule: no dead code.
- StoragePolicySim/Simulation.lean:178 · In `simulate`, `{ openMonth with month, days := ... }` sets `month` each day, but `openMonth.month` already equals `month` at that point. The reset on line 177 sets it for a new month, and day 0 starts at month 0. The extra field makes the month change look like it happens in two places. Write `{ openMonth with days := openMonth.days + 1 }`. · Remit rule: no unnecessary repetition and no dead code; the code is as simple as the requirement lets it be.
- StoragePolicySim/Simulation.lean:54 · In `stepHour`, `freeRoomKwh` is not the free room of the battery. The free room is `capacityKwh - socKwh`. The value is that room divided by `efficiency`: the charge before the loss that fills the room. A reader who takes the name at its word gets the limit wrong by 5%. Use a name such as `chargeToFillKwh`, or keep the free room in its own value and divide on line 55. · Remit rule: names tell what things are.

## Look here

- `pdlc/changes/CH-0003-simulation/review/quality/result.md`

## Don't redo

- The checks, and the code that the other reviews passed.

## Next: do this first

Fix the three quality problems in `StoragePolicySim/Simulation.lean`, and run all checks.
