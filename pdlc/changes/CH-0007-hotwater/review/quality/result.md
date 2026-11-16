Result: fail

Remit: quality

Problems:
- StoragePolicySim/HotWater.lean:82 and StoragePolicySim/HotWater.lean:107 · The rule "the tank counts as full before the hour only when `hour != 0 && state.fullToday`" is written twice. `thermostatOn` writes it as `fullBefore`. `tankStep` writes it again inside `fullToday := (hour != 0 && state.fullToday) || full`. A change to the day reset at hour 0 needs two edits, and one edit can leave the two out of step. Fix: one small private helper, for example `fullEarlierToday`, that both places call. · Remit rule: "There is no unnecessary repetition and no dead code."

Follow-ups:
- `drawKwh` reads `profile[hour]!`. An hour of 24 or more makes the compiled code print a panic message and return 0.0. A new intent could check the hour of `drawKwh` and `tankStep` and give a named error code in DES-errors (the project's error codes). The spec lists "errors: none", so this change builds nothing for it.

Notes:
- I checked the code against each line of R1 to R6 by hand. The Interface entries match: names, types, fields, and the default tank values. The only file is the one in "Files". I found no other break of an acceptance line.
- The profile adds up to 1000 parts. Hour 7 and hour 19 each hold 110 parts, so the peaks and the R4 comparisons hold.
- The spec requires `floorKwh` in `TankConfig`, and nothing in this module reads it. I did not count it as dead code, because the Interface asks for it.
- Nits that I did not count as problems. Line 107 of the file is 105 characters long, while the other lines stay within 100. Line 96 writes `if drawKwh < afterLoss then drawKwh else afterLoss`, where `min drawKwh afterLoss` matches the `min` calls a few lines below. The divisor `1000.0` in `drawKwh` repeats the "parts of 1000" in the doc comment of `profile`, so a named constant would tie the two together.
- The parameter `drawKwh` of `tankStep` has the same name as the function `drawKwh`. Both names come from the Interface, so I did not count this.
- DES-writing-style is in "Relies on" of the change but not in the packet. I judged the comments by short sentences in the active voice. They read well.
