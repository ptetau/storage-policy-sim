Result: fail

Remit: specification

Problems:
- StoragePolicySim/Simulation.lean:48 · The new descriptive sentence in the doc comment of `stepHour` has 27 words: "The stored energy after the hour stays from 0 to the capacity, so that a rounding error of the floats cannot move it out of this range." · DES-writing-style rule 6.3 (a maximum of 25 words in each descriptive sentence). A possible fix is two sentences: "The stored energy after the hour stays from 0 to the capacity. Thus, a rounding error of the floats cannot move the stored energy out of this range."

Follow-ups: none

Notes:
- This review is a re-review. The earlier review found no problems. Thus, this review judges only the diff since 879c56afeef0 (the earlier review).
- The changed code line limits `socKwh` (the stored energy after the hour) to the range from 0 to `battery.capacityKwh`. This limit is not new behaviour. CAP-simulation.R2 (battery limits) says that the battery never goes past its capacity, and its second acceptance line asks for 0 to 5 kWh in each hour. The limit breaks no acceptance line.
- The limit removes or adds only a rounding error of the floats. The energy balance of CAP-simulation.R2 has a tolerance of 0.01 kWh, so the limit cannot break that balance line. The `lossKwh` field does not include the removed amount.
- With a battery of 0 kWh, the limit gives 0 kWh. Thus, the CAP-simulation.R2 line that compares `greedy` and `none` with a battery of 0 kWh still holds.
- The writing check in the packet covered only `change.md` and `CAP-simulation.md`, and it found nothing. The writing check did not cover the code comments. The problem above comes from my own reading of the changed comment.
- The changed comment obeys the local-references rule. In the comment, "it" refers to "the stored energy" in the same sentence.
