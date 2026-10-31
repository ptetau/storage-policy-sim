Result: fail

Remit: tests

Problems:
- tests/CAP-scenario.lean:121-123 · The check "CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15" compares each `Float` factor with `==`. The value 0.15 has no exact binary form. A correct app that computes the factor in another way, for example `1.0 - 0.85`, gives 0.15000000000000002 and fails the check. Use `near` with a small tolerance, as the other checks do. · DES-lean-checks ("A `Float` comparison uses a tolerance"), and the remit rule "A correct app passes each check"

Wrong versions:
- CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354 · the declination has the wrong sign · fails (day 354 gives about 2.5 times day 171, so `a > 2 * b` is false)
- CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171 · the code uses the absolute value of the latitude · fails (day 354 then gives about 0.4 times day 171)
- CAP-scenario.R1 at latitude 0 days 171 and 354 differ by less than 1% · the code ignores the latitude and uses 45 · fails (the two outputs differ by more than 50%)
- CAP-scenario.R1 at latitude 45 00:00 of day 171 gives 0 kWh · the code does not set a negative sun height to 0 · fails (`v == 0` is false, because v is negative)
- CAP-scenario.R1 each sunny hour of days 0 to 364 at latitude 45 gives 0 to 5 kWh · no clamp at the horizon · fails (the night hours give less than 0)
- CAP-scenario.R1 the sunny noon of day 171 at latitude 45 uses the 5 kW of panels · the code omits the panel power · fails (`full > 4` is false, because full is less than 1)
- CAP-scenario.R1 a cloudy sky gives 0.5 times the sunny output · cloudy uses the factor 0.55 · fails (the difference is about 0.23 kWh, more than 0.001)
- CAP-scenario.R1 an overcast sky gives 0.15 times the sunny output · overcast uses the factor 0.2 · fails (the difference is about 0.23 kWh, more than 0.001)
- CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15 · cloudy and overcast swap their factors · fails (`Sky.factor Sky.cloudy == 0.5` is false)
- CAP-scenario.R1 0 kW of panels gives 0 kWh at 12:00 of day 171 · the code uses a fixed 5 kW and ignores `pvKw` · fails (v is about 4.6)
- CAP-scenario.R1 the output does not change with the load of the site · the output is scaled by `dailyLoadKwh / 20` · fails (`a == b` is false at load 99)
- CAP-scenario.R2 seed 7 at latitude 45 gives the same hours two times · the code gives 23 hours for each day · fails (`a.size == 8760` is false). In pure Lean, two calls with the same arguments cannot differ, so the size and NaN values are the only ways to fail. See Notes.
- CAP-scenario.R2 seeds 7 and 8 at latitude 45 give different skies on at least 50 days · the code ignores the seed · fails (n is 0)
- CAP-scenario.R2 seed 7 and 365 days give 8760 hours in order of day, then hour · the hours come in order of hour, then day · fails (item 1 is day 1 hour 0)
- CAP-scenario.R2 seed 7 and 0 days give no hours · the code makes `days + 1` days · fails (24 hours)
- CAP-scenario.R2 seed 7 and 1 day give the 24 hours of day 0 · the first day is day 1 · fails (`hs[i]!.day == 0` is false)
- CAP-scenario.R2 the 24 hours of each day have the same sky · the code draws a new sky each hour · fails (an hour of day 0 has a different sky)
- CAP-scenario.R2 each solar output of seed 7 equals the seasonal sun of its hour · `pvKwh` always uses the sunny factor · fails (the first cloudy or overcast day differs by more than 0.000001 kWh)
- CAP-scenario.R2 each solar output at latitude -41 equals the seasonal sun of its hour · `scenario` passes latitude 45 or the absolute latitude to `pvOutput` · fails (each daylight hour differs)
- CAP-scenario.R2 at latitude 45 December to February has over twice the overcast days · both halves of the year use the same chances · fails (w and s are about equal, because the periods have 90 and 92 days)
- CAP-scenario.R2 at latitude -41 June to August has over twice the overcast days · the summer half is days 90 to 272 at each latitude · fails (June to August then has about one third of the overcast days of December to February)
- CAP-scenario.R2 60% or more of days 1 to 364 of seed 7 keep the previous sky · the code has no chance to keep the sky, so each day draws a new sky · fails (about 40% keep, which is under 219 of 364)
- CAP-scenario.R2 with 730 days day 365 is day 0 and day 729 is day 364 of the year · `dayOfYear` is `day % 366` · fails (item 8760 is day 365 of the year)
- CAP-scenario.R2 with 730 days the solar output of the second year uses the day of the year · `pvKwh` is 0 for each day after day 364 · fails (item 8772 is not equal to `pvOutput`)
- CAP-scenario.R3 365 days at latitude 45 have 7300 kWh of load · the base load is the full daily load, and the flexible load is added on top · fails (the total is 8395 kWh)
- CAP-scenario.R3 365 days with 0 kWh of flexible load also have 7300 kWh of load · the base load is a fixed 17 kWh for each day · fails (the total is 6205 kWh)
- CAP-scenario.R3 at latitude 45 day 15 has 1.45 to 1.55 times the base load of day 197 · the peak is day 197 at each latitude · fails (the ratio is about 0.67)
- CAP-scenario.R3 at latitude -41 day 197 has 1.45 to 1.55 times the base load of day 15 · the peak is day 15 at each latitude · fails (the ratio is about 0.67)
- CAP-scenario.R3 on day 100 the base load at 19:00 is more than at 13:00 · a flat profile · fails (`a > b` is false, because the two values are equal)
- CAP-scenario.R3 on day 100 the base load at 07:00 is more than at 03:00 · a profile with only an evening peak · fails (07:00 equals 03:00)
- CAP-scenario.R3 3 kWh of flexible load is 1 kWh at 18:00, 19:00 and 20:00 · the flexible load goes at 17:00, 18:00 and 19:00 · fails (hour 17 of day 0 has 1 kWh)
- CAP-scenario.R3 6 kWh of flexible load is 2 kWh at 18:00, 19:00 and 20:00 · the code puts a fixed 1 kWh in each flexible hour · fails (hour 18 of day 0 has 1 kWh)
- CAP-scenario.R3 0 kWh of flexible load gives 0 kWh in each hour · the code ignores `flexKwh` and always puts 1 kWh in each flexible hour · fails (hour 18 of day 0 has 1 kWh)
- CAP-scenario.R3 seeds 7 and 8 at latitude 45 give the same base and flexible load · the base load goes up by 10% on overcast days · fails (the loads differ on the days where the two skies differ)

Follow-ups: none

Notes:
- Each acceptance line of R1 (seasonal sun), R2 (daily weather) and R3 (household load) has at least one check. Each check name starts with its requirement ID. The checks use only the Interface, and the `seed` argument is the only seam. No check waits on anything, so no check can hang. No error code exists, so no check expects one.
- The file has 34 checks: 11 for R1, 13 for R2, and 10 for R3. This agrees with the progress log.
- The exact `== 0` comparisons at lines 89 and 127 follow the example in DES-lean-checks, and the acceptance lines ask for exactly 0 kWh. The exact comparisons in `sameHour` (line 53), at line 132 and at line 292 test "the same" values from a pure function, so exact equality is the right meaning. I did not count these as problems.
- The check of R2 (daily weather) "same hours two times" is weak by nature. `scenario` is a pure Lean function, so two calls cannot differ. The check is still useful, because it fails on a wrong size or on NaN values.
- Two "(assumed)" rules have an edge at latitude 0 that no acceptance line names: the summer half in R2 (daily weather), and the load peak in R3 (household load). A version that uses `latitude > 0` instead of `latitude ≥ 0` passes each check. An acceptance line at latitude 0 would close this gap. Also, no line checks the weather of the second year of a 730-day run.
- The line "60% or more keep the previous sky" also fits a keep chance of 0.5. With that chance, about 70% of days keep the sky. The check proves the line as the line is written.
- `badFlex` reads the hour from the index (`i % 24`), not from `hs[i]!.hour`. The order check of R2 proves that the two agree, so this is correct.
