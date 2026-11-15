Result: fail

Remit: tests

Problems:
- tests/acceptance/IN-0002.acceptance.lean:662 · The check "CAP-forecast.R4 the UTC time rounds to the nearest 30 minutes" has no tie case. A version that rounds a tie down passes every R4 check. So does a version that uses `Float.round`, which rounds a negative tie away from zero. Add two cases. Longitude 3.75 is an offset of 15 minutes, so the end at 00:30 solar lands on a tie and must print `2025-01-01T00:30:00.0000000Z`. Longitude 11.25 is an offset of 45 minutes, so the end lands on a tie at -15 minutes and must print `2025-01-01T00:00:00.0000000Z` (`Float.round` gives `2024-12-31T23:30:00.0000000Z`). · CAP-forecast.R4 (Solcast JSON), the rule "a tie rounds up"; remit rule "each check fails on a plausible wrong version"
- tests/acceptance/IN-0002.acceptance.lean:175 · `badStraddle` demands `p10 < estimate` for each sunny period, and its 90% side excuses an estimate of 5 kW, but the 10% side does not. R2 says each value is cut to 0 to 5 kW. A correct app that forms the bands from the uncut estimate and then cuts each value gives 10% = 5 = estimate, when the uncut estimate is above 5 / (1 - 1.28 × scale × spread). Summer noon periods 24 to 48 hours ahead (actual about 4.6 kW, spread about 0.2) can reach that. The check then fails a correct app. Excuse an estimate of 5 kW on the 10% side too. · remit rule "a correct app passes each check"; the line in CAP-forecast.R1 (forecast periods) says "no 10% band is above its estimate", which allows equality
- tests/acceptance/IN-0002.acceptance.lean:107 (and the header at line 17) · `isSunny` counts a period only when the sky is `sunny`. CAP-forecast.R2 (forecast error) defines a sunny period as a period with an actual power above 0 kW, and the handoff repeats that default. The three statistical checks (growth, error size, in the band) use the narrower term, so cloudy and overcast periods never reach them. A version that adds the random error only on sunny-sky days passes all three. Use `pvKwh > 0.0`. The window of 10:30 to 14:00 can stay. · CAP-forecast.R2, the sentence "A sunny period is a period with an actual power of more than 0 kW"; remit rule "each check tests what the acceptance line says"

Wrong versions:
- CAP-forecast.R1 a fetch at hour 0 has 96 periods · the first period ends at minute 0, not 30 · fails (`endMins` starts 0, 30; want 30, 60)
- CAP-forecast.R1 a fetch at hour 100 has 96 periods from 6030 to 8880 minutes · the ends count from the start of the run, not from the fetch hour · fails (first end 30, want 6030)
- CAP-forecast.R1 a fetch at hour 8750 has 20 periods · no cut at the end of the run · fails (96 periods, want 20; last end 525600)
- CAP-forecast.R1 a fetch at hour 8759 has 2 periods · the cut is one period late · fails (3 periods; want ends 525570 and 525600)
- CAP-forecast.R1 a fetch at hour 8760 has no period · the test is `fetch > 8760`, so hour 8760 gives periods · fails (size is not 0)
- CAP-forecast.R1 a fetch at hour 8761 has no period · the test is `fetch == 8760`, so later hours give periods · fails (size is not 0)
- CAP-forecast.R1 a run of 1 day has 48 periods at hour 0, 2 at hour 23 and none at hour 24 · `days` is ignored and the run is always 365 days · fails (hour 0 gives 96 periods, want 48)
- CAP-forecast.R1 each daily fetch has the periods of its next 48 hours or of the rest of the run · the periods wrap to the start of the run after its end · fails (`badShape` at fetch 8736: 96 periods, want 48)
- CAP-forecast.R1 no 10% band is above its estimate and no estimate is above its 90% band · the 10% and 90% bands are swapped · fails (`badOrder`: 10% band above the estimate)
- CAP-forecast.R1 each sunny period has its 10% band below and its 90% band above its estimate · the bands have no width · fails (`p10 < estimate` is false on the first sunny period); see Problems, it can also fail a correct app
- CAP-forecast.R1 each value of a daily fetch at 00:00 is from 0 to 5 kW · the estimate and the 90% band are not cut at 5 kW · fails (`badRange`: a summer noon estimate 24 to 48 hours ahead passes 5 kW; over 92 fetches this is near certain)
- CAP-forecast.R1 each value stays from 0 to 5 kW with an error scale of 6 · the cut at 0 is missing · fails (`badRange`: a negative 10% band at 24 hours of lead, since 1.28 × 6 × 0.15 is above 1)
- CAP-forecast.R1 each period with no actual power has 0 kW in all three values · the error is added in kW, not times the actual power · fails (`badNight`: a night value is not 0)
- CAP-forecast.R2 with an error scale of 0 each value of a fetch at hour 0 equals its actual power · the estimate ignores the error scale · fails (`badEqual`: estimate is not the actual power)
- CAP-forecast.R2 with an error scale of 0 each value of a fetch at hour 4116 equals its actual power · the bands keep a fixed width at scale 0, for example 0.9 and 1.1 times the estimate · fails (`badEqual`: 10% band is not the actual power)
- CAP-forecast.R2 seed 7 gives the same forecast two times · the numbers come from a clock or a global stream through unsafe code · passes (both calls are one closed term, and a pure `forecast` cannot differ; not a plausible version, see Notes)
- CAP-forecast.R2 seeds 7 and 8 give a different estimate for a fetch at hour 4000 · the scenario and the noise both ignore the seed (always seed 7) · fails (`differs` is false)
- CAP-forecast.R2 seeds 7 and 8 give different errors for a fetch at hour 4000 · the noise ignores the seed while the scenario uses it · fails (`differ.length` is 0)
- CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is more than 1.5 times the error 0 to 4 hours ahead · the spread is a constant 0.05 · fails (ratio about 1)
- CAP-forecast.R2 the error of sunny periods 0 to 4 hours ahead is 3% to 6.5% of the actual power · the spread is a constant 0.10 · fails (mean relative error about 0.08, above 0.065)
- CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is 8% to 20% of the actual power · the spread grows by 0.10 for each hour, not for each 24 hours · fails (mean relative error far above 0.20)
- CAP-forecast.R2 60% to 95% of sunny periods of a daily fetch at 00:00 have the actual power in the band · the bands are built on the actual power, not on the estimate · fails (every period is in the band, so over 95%)
- CAP-forecast.R2 the bands are 1.28 times the error scale times the spread on each side of the estimate · the bands ignore the error scale · fails (scales 2.0 and 0.5: half-width is off by 2 and 0.5 times)
- CAP-forecast.R3 10 fetches a day are at hours 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21 · the hours round to the nearest hour · fails (third fetch is 5, want 4)
- CAP-forecast.R3 3 fetches a day are at hours 0, 8 and 16 · `i` runs from 1 to `n` · fails (first hour 8, want 0)
- CAP-forecast.R3 1 fetch a day is at hour 0 · the list holds hours 0 and 24 · fails (got [0, 24])
- CAP-forecast.R3 the fetch hours of 1 to 10 fetches a day are i × 24 / n rounded down · the hours round up · fails (5 a day gives 0, 5, 10, 15, 20; want 0, 4, 9, 14, 19)
- CAP-forecast.R3 with 10 fetches a day the latest fetch for hour 27 is the fetch at hour 26 · the result is the next fetch at or after the hour · fails (got 28, want 26)
- CAP-forecast.R3 with 10 fetches a day the latest fetch for hour 26 is at hour 26 and for hour 25 it is at hour 24 · a fetch counts only when it is strictly before the hour · fails (hour 26 gives 24, want 26)
- CAP-forecast.R3 with 1 fetch a day the latest fetch for hour 47 is the fetch at hour 24 · the day is ignored, so the result is the hour of the day · fails (got 0, want 24)
- CAP-forecast.R3 the latest fetch for other hours of 10, 3 and 1 fetches a day · the result is the hour of the day, not of the run · fails (10 a day, hour 24 gives 0, want 24)
- CAP-forecast.R3 the latest fetch is the last fetch hour at or before the hour for 1 to 10 fetches a day and hours 0 to 239 · the search stops one fetch early, so the last fetch of each day is never found · fails (10 a day, hour 21 gives 19, want 21)
- CAP-forecast.R4 longitude 0 and a fetch at hour 0 give a first period that ends at 2025-01-01T00:30:00.0000000Z · the printed end is the start of the period · fails (00:00, want 00:30)
- CAP-forecast.R4 longitude 174.8 and a fetch at hour 0 give a first period that ends at 2024-12-31T13:00:00.0000000Z · the offset rounds down to 30 minutes · fails (12:30, want 13:00)
- CAP-forecast.R4 longitude -75 and a fetch at hour 0 give a first period that ends at 2025-01-01T05:30:00.0000000Z · the offset is added, not subtracted · fails (2024-12-31T19:30, want 2025-01-01T05:30)
- CAP-forecast.R4 longitude 0 and a fetch at hour 8759 give a last period that ends at 2026-01-01T00:00:00.0000000Z · midnight prints as 24:00 of the day before · fails (2025-12-31T24:00, want 2026-01-01T00:00)
- CAP-forecast.R4 with an error scale of 0 each value of a fetch at hour 4116 has four decimals · the values print with six decimals · fails (`fourDecimals` is false)
- CAP-forecast.R4 a value with more digits has four decimals in the text · the values print with five decimals · fails (`fourDecimals` is false)
- CAP-forecast.R4 a fetch at hour 0 has the five fields of each period in order and "period":"PT30M" · the 10% and 90% fields swap places · fails (`tokenOk`: field 1 does not start with `"pv_estimate10":`)
- CAP-forecast.R4 the period ends of a fetch at hour 0 run from 2025-01-01T00:30 to 2025-01-03T00:00 and have the Solcast form · the fraction has three digits (`.000Z`) · fails (`isIso`: length is 24, want 28)
- CAP-forecast.R4 the text of a fetch is one line with no spaces · the separator is a comma and a space · fails (`js` contains a space)
- CAP-forecast.R4 periods with values that need no rounding give the exact text · the values print with three decimals · fails (text differs from `handExactText`)
- CAP-forecast.R4 no period gives the text {"forecasts":[]} · the empty text keeps a space, `{"forecasts":[ ]}` · fails (text differs)
- CAP-forecast.R4 the UTC time rounds to the nearest 30 minutes · a tie rounds down, or rounds away from zero with `Float.round` · passes (no case is a tie; longitudes 12, -12, 100 and -100 give offsets of 48, -48, 400 and -400 minutes); a version that rounds down or up fails (-12 gives 01:00, want 01:30; 12 gives 00:00, want 23:30); see Problems
- CAP-forecast.R4 the period ends follow the days of each month of 2025 · February has 30 days in the month table · fails (hour 744 or 1416 gives a wrong day)
- CAP-forecast.R5 with an error scale of 0 value j of a fetch at hour 0 is the solar output of hour j · the two estimates are added without the factor 0.5 · fails (`energyFails`: value 0 is twice the solar output)
- CAP-forecast.R5 with an error scale of 0 value j of a fetch at hour 4116 is the solar output of hour 4116 + j · value j reads hour j of the run, not hour fetchHour + j · fails (value 0 is the output of hour 0, want hour 4116)
- CAP-forecast.R5 a fetch at hour 4116 gives 48 values from 0 to 5 kWh · the array holds 96 values, one for each period · fails (size is 96)
- CAP-forecast.R5 a fetch at hour 8750 gives 48 values and values 10 to 47 are 0 kWh · the array holds only the 10 hours that have periods · fails (size is 10)
- CAP-forecast.R5 with an error scale of 0 the values 0 to 9 of a fetch at hour 8750 are the solar output of hours 8750 to 8759 · values 0 to 9 are shifted by one hour · fails (`energyFails`: value 0 is the output of hour 8751)
- CAP-forecast.R5 a fetch at hour 8760 gives 48 values of 0 kWh · the code reads a period that does not exist and stops, or gives non-zero values · fails (`energyFails`: error or value not 0)
- CAP-forecast.R5 no period gives 48 values of 0 kWh · the array is empty for an empty fetch · fails (size is 0, want 48)
- CAP-forecast.R5 the sum of the 48 values of a fetch at hour 4116 is 0.5 times the sum of the 96 estimates · each value reads the 90% band, not the estimate · fails (sum is larger than half the estimates)
- CAP-forecast.R5 each value is half the two estimates of its hour and an hour with no period is 0 kWh · the values read the periods by position (period 2j and 2j + 1) · fails (value 2 is 3.0 and value 3 is 2.5, want 0 and 0; hours 102 and 103 have no period)
- CAP-forecast.R5 the values 0 and 47 are the hours fetchHour and fetchHour + 47 · the array starts at hour fetchHour + 1 · fails (value 0 is 0.0, want 2.0)

Follow-ups:
- `fetchHours` and `latestFetch` give no defined result for 0 fetches a day or for more than 10. The Interface lists no error, so no check can pin the result. A new intent could add an error that uses the existing code `OUT_OF_RANGE` (a number is outside its range) and a check for 0 and 11.

Notes:
- Line numbers are lines of the check file. The first line of the file is line 637 of the packet.
- Coverage is complete. Each of the 29 acceptance lines of R1 to R5 has a check, and the file holds 55 checks. Each name starts with its requirement ID. The test seam `seed` has checks. The Interface lists no error. No check uses the clock, reads stored data, or leaves out a check of an earlier intent.
- I judged by reading only. I did not run Lean, and I cannot see the scenario of seed 7. So I cannot say which days are sunny. The scale-0 checks at hours 0, 4116 and 8750 cover six days, so a forecast built on clear-sky output (ignoring the scenario sky) almost surely fails them.
- The check "seed 7 gives the same forecast two times" cannot fail on a pure function. `forecast` is pure in the Interface, so I do not count this as a problem.
- No check tells a normal curve from another curve with the same spread, for example a uniform one. The bounds of the lines (60% to 95%) are wide, so a uniform version passes. The spec's lines allow this.
- The spread is pinned only at lead 0.5 hours (0.05 to 0.0521) and at lead 24.5 hours (0.15 to 0.1521). The ranges allow a step and a slope on purpose. So a lead time that runs to the start of the period passes. The bounds of 8% to 20% also allow a growth of 0.05 for each 24 hours in the noise alone. A spread function that the bands share is caught by the bands check.
- The two scale-0 checks of R5 also pass a version that reads a band or the positions of the periods, because a band equals the estimate at scale 0 and the periods fill every hour. The sum check and the two hand checks catch these versions.
- The checks of "a daily fetch at 00:00" use every fourth day (92 fetches), and they include day 364. The file explains that each fetch costs one 365-day scenario. I did not count this as a problem. The window of 10:30 to 14:00 in the growth check is a sound fix, because a fetch at 00:00 has no sunny period within 4 hours.
- The header comment says "The intent lists only R1 and R5". The intent lists R1 to R5. The comment is stale and harmless.
- The file runs about 250 forecasts, each with a 365-day scenario, in one interpreted script. No check waits for a process, so none can hang. A slow run is the open item of the handoff.
