Result: pass

Remit: specification

Problems: none

Follow-ups:
- A check on `fetchesPerDay` outside 1 to 10, for example with `OUT_OF_RANGE` (a number is outside its range). Today `fetchHours 0` gives no hours, and `latestFetch 0 h` acts like one fetch a day. The spec gives the range 1 to 10 only as an input note, and asks for no error. A new intent could add the guard.
- A check on a negative or not-a-number `errorScale`. A negative scale swaps the bands, so a 10% band can lie above its estimate. R1 (forecast periods) and R2 (forecast error) name only scales of 0 and 1. A new intent could add the guard.
- A leap-year calendar in `forecastJson` (`StoragePolicySim/Forecast.lean:134`). The code gives each year 365 days, as the scenario does. A run that crosses 29 February 2028 shows a date one day wrong from March 2028. The spec says only "the run starts on 1 January 2025". A new intent could add leap years to the scenario and to the JSON together.
- A variant of `forecast` that takes the scenario hours (`StoragePolicySim/Forecast.lean:91`). Each call to `forecast` rebuilds the scenario of the whole run. A policy that reads one fetch for each fetch hour of a year repeats that work. The spec asks for no speed. A new intent could add the variant.

Notes:
- I traced each acceptance line of CAP-forecast.R1 (forecast periods) to R5 (hourly forecast energy) through the code. I do not see the checks. Each line holds by hand.
- R1: `periodsLeft` gives 96 periods at hour 0, 20 at hour 8750 and none at hour 8760. The ends at hour 100 are 6030 to 8880 minutes. The bands and the estimate stay in the range 0 to `pvKw`, and a period with no actual power gives 0 in all three values.
- R2: an error scale of 0 gives the actual power, because the spread is 0. The random number depends only on the seed, the fetch hour and the period. By hand, the actual power lies in the band for about 80% of sunny periods at spreads 0.05 and 0.25. That is inside the range 60% to 95%.
- R3 (fetch limit): 10 fetches give 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21. The latest fetch for hours 27, 26 and 25 is 26, 26 and 24. One fetch a day gives 24 for hour 47.
- R4 (Solcast JSON): longitude 174.8 gives -660 minutes, that is `2024-12-31T13:00:00.0000000Z`. Longitude 0 at hour 8759 ends at `2026-01-01T00:00:00.0000000Z`. The fields keep the order of the spec, and each power has four decimals.
- R5 (hourly forecast energy): the array has 48 values at each fetch hour. Each period adds its estimate times 0.5 hours, so the sum equals 0.5 times the sum of the estimates. Hours with no period stay 0.
- The Interface of the change matches the code: the names, the arguments, the result types, and the `Repr` and `Inhabited` derivations of `Period`. The `seed` seam is the `seed` argument of `forecast`. The code diff changes only `StoragePolicySim/Forecast.lean`, which is the one entry in "Files".
- "Files" lists no README, so the README rule did not apply.
- The writing check lists `CAP-scenario.md`, `CAP-simulation.md` and `DES-pdlc-commit-trailers.md` as changed since the base. The packet has no diff for them. I could not confirm that CAP-scenario stayed "used, not changed". The code diff leaves `Scenario.lean` as it was. This is not a problem, but the user can check those three files.
- In `CAP-forecast.md`, the entries of the Interface still say "proposed", but R1 to R5 say "built". This is a bookkeeping mismatch, not old behaviour. Change the entries when the change ships.
- The doc comments of `p10Kw` and `p90Kw` (`StoragePolicySim/Forecast.lean:17` and `:19`) say the actual power is below the band "one time in ten" and "nine times in ten". The code centres each band on the estimate. By hand, the actual power is below the 10% band 3% to 9% of the time. It is below the 90% band 83% to 89% of the time. The spec asks only for the range 60% to 95%. Say "about" in the comments. This does not fail the review.
- Writing check, DES-writing-style (a guideline in this project, so each item is a note). The linter found 8 items:
  - `pdlc/changes/CH-0005-forecast/change.md:46` · a sentence of 37 words, from "Given an error scale of" · rule 6.3 (25 words in a descriptive sentence).
  - `pdlc/changes/CH-0005-forecast/change.md:50` · a sentence of 31 words, from "Given a fetch at hour" · rule 6.3.
  - `pdlc/changes/CH-0005-forecast/change.md:64` · a sentence of 37 words, from "out: a structure with `Repr`" · rule 6.3.
  - `pdlc/changes/CH-0005-forecast/change.md:156` · "IN-0002" has no name next to it, in the Build line of the progress log · the described-IDs rule.
  - `pdlc/specs/capabilities/CAP-forecast.md:24` · a sentence of 37 words, from "out: a structure with `Repr`" · rule 6.3.
  - `pdlc/specs/capabilities/CAP-forecast.md:123` · a sentence of 26 words, from "The UTC time is the" · rule 6.3.
  - `pdlc/specs/capabilities/CAP-forecast.md:143` · a sentence of 37 words, from "Given an error scale of" · rule 6.3.
  - `pdlc/specs/capabilities/CAP-forecast.md:147` · a sentence of 31 words, from "Given a fetch at hour" · rule 6.3.
