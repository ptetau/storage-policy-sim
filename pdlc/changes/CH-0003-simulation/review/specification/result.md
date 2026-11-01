Result: pass

Remit: specification

Problems: none

Follow-ups: none

Notes:
- This review is a re-review. The earlier review at 707f29d2c925 found no problems. Thus, this review judges only the diff since that review.
- StoragePolicySim/Simulation.lean:53-54 · The diff renames `freeRoomKwh` to `chargeToFillKwh`. The behaviour does not change. CAP-simulation.R1 (energy flows of an hour) still holds: the charge stays within the request, the surplus, the power and the free room. The doc comment of `stepHour` still says "the free room". This wording is correct, because the limit is still the free room of the battery.
- StoragePolicySim/Simulation.lean:174-178 · The diff removes the `openMonth.days > 0` guard and the `month` update in the `with` expression. The month logic still meets CAP-simulation.R4 (monthly totals):
  - The first day of each run is day 0 of the year, and day 0 is January. `openMonth` starts as January. Thus, the first day never closes an empty month, and the removed guard was never necessary.
  - After a month change, `openMonth` is `{ month }`. Thus, `openMonth.month` already holds the month of the day, and the removed `month` field in the `with` expression was not necessary.
  - 365 days give 12 months with 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31 days.
  - 400 days give 14 months. Day 365 closes December and opens January. Days 396 to 399 give February with 4 days.
  - 10 days give one month, January with 10 days.
  - 0 days give no months, because the final `openMonth.days > 0` guard stays.
- pdlc/changes/CH-0003-simulation/change.md:179 · The new line of the progress log obeys DES-writing-style (how pdlc writes). "went back to build" is a literal movement to the build stage, not an idiomatic phrasal verb. Thus, the line does not break rule 9.3 (no phrasal verbs). The writing check found no findings on the changed lines.
- The diff changes only `StoragePolicySim/Simulation.lean` and the change spec. `StoragePolicySim/Simulation.lean` is the one entry under "Files".
