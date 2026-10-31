Result: fail

Remit: quality

Problems:
- StoragePolicySim/Scenario.lean:149 · In `scenario`, the name `sky` holds the array of the skies of all days, but the name tells of one sky. Two lines later, `s` holds the one sky of the day. Rename the array to `skyOfDay` or `daySkies`, and rename `s` to `sky`. · Remit rule "Names tell what things are and what they do."

Follow-ups:
- none

Notes:
- StoragePolicySim/Scenario.lean:69 · In `pvOutput`, `h` holds the sine of the sun height. In `scenario`, `h` is the hour. A name such as `sinHeight` would make `pvOutput` clearer. This is minor, and I do not count it as a problem.
- StoragePolicySim/Scenario.lean:106 · On day 0, `skies` draws `u` and does not use it. The result is correct and repeatable, but a reader can think that the draw is a mistake. A short comment, or a draw only when a previous day exists, would make the intent clear. If the draw order changes, the checks of CAP-scenario.R2 (daily weather) that depend on seed 7 can change, so the builder must run the checks again.
- StoragePolicySim/Scenario.lean:50 · `daysInYear` is public, but the Interface does not list it. The other helpers are private. Make it private, or add it to the Interface.
- StoragePolicySim/Scenario.lean:91 · In `inSummerHalf`, the name `north` means "in the summer half at a north latitude". A name such as `northSummer` would tell this.
- The hourly profile sums to 1000, and the seasonal factor averages 1 over 365 days. Thus, the base and flexible loads sum to the daily load, as CAP-scenario.R3 (household load) asks.
- No requirement names an error, and the Interface says that no entry can fail. `profile[hour]!` gets only hours 0 to 23 from `scenario`.
- The code follows DES-errors (error codes) and adds no error. DES-lean-checks (Lean check form) and DES-pdlc-check-tagging (check names) apply to the check file. The packet does not hold the check file, and the quality remit judges the code.
