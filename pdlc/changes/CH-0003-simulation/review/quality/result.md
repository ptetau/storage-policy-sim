Result: fail

Remit: quality

Problems:
- StoragePolicySim/Simulation.lean:175 · In `simulate`, the condition `&& openMonth.days > 0` never changes the result. On day 0, `month` is 0 and `openMonth.month` is 0, so the first part is already false. On each later day, `openMonth.days` is 1 or more. Remove the second part, so that the reader does not look for a case that cannot happen. · Remit rule: no dead code.
- StoragePolicySim/Simulation.lean:178 · In `simulate`, `{ openMonth with month, days := ... }` sets `month` each day, but `openMonth.month` already equals `month` at that point. The reset on line 177 sets it for a new month, and day 0 starts at month 0. The extra field makes the month change look like it happens in two places. Write `{ openMonth with days := openMonth.days + 1 }`. · Remit rule: no unnecessary repetition and no dead code; the code is as simple as the requirement lets it be.
- StoragePolicySim/Simulation.lean:54 · In `stepHour`, `freeRoomKwh` is not the free room of the battery. The free room is `capacityKwh - socKwh`. The value is that room divided by `efficiency`: the charge before the loss that fills the room. A reader who takes the name at its word gets the limit wrong by 5%. Use a name such as `chargeToFillKwh`, or keep the free room in its own value and divide on line 55. · Remit rule: names tell what things are.

Follow-ups: none

Notes:
- The change relies on DES-writing-style (conventions to follow), but the packet does not hold it. I did not judge the doc comments against it. The remit asks only for the design specs in this packet.
- `simulate` uses `daysInYear`. This name is not in the Interface list of CH-0001 (scenario), so I could not see it. The build passes, so I take it to come from `StoragePolicySim/Scenario.lean`.
- `limitTo` takes three values. On lines 55 and 57 to 58, the call nests a `min` to pass a fourth value. A `limitTo` with four values, or plain `min` calls, would read more simply. This is a small point, so I did not list it as a problem.
- `stepHour` matches each R1 (energy flows of an hour) line that I worked through by hand: 1 kWh charge at 9.05 kWh stored, and 1.805 kWh given with 0.195 kWh import at 1.9 kWh stored.
- The code names no error, and the Interface says that no entry can fail. Thus, DES-errors (error codes) asks nothing of this code.
