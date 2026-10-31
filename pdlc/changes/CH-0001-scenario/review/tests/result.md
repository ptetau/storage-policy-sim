Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354 · the declination is always 0, so the season does not change the output · fails (both days give about 4.4 kWh, and `a > 2 * b` is false; the correct values are about 4.62 and 1.81)
- CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171 · the code uses the absolute value of the latitude, so the south has northern seasons · fails (day 354 gives less than day 171)
- CAP-scenario.R1 at latitude 0 days 171 and 354 differ by less than 1% · the code multiplies the output by an extra seasonal factor from the day of the year alone · fails (`(a - b).abs < 0.01 * big` is false)
- CAP-scenario.R1 at latitude 45 00:00 of day 171 gives 0 kWh · the code does not clamp a sun below the horizon to 0 · fails (`v == 0` is false, the value is about -1.8)
- CAP-scenario.R1 each sunny hour of days 0 to 364 at latitude 45 gives 0 to 5 kWh · no clamp at night · fails (`v ≥ 0` is false at night)
- CAP-scenario.R1 the sunny noon of day 171 at latitude 45 uses the 5 kW of panels · the code omits the panel power · fails (`full > 4` is false, the value is about 0.92)
- CAP-scenario.R1 a cloudy sky gives 0.5 times the sunny output · the cloudy factor is 0.6 · fails (`near c (0.5 * s) 0.001` is false)
- CAP-scenario.R1 an overcast sky gives 0.15 times the sunny output · the overcast factor is 0.2 · fails (`near o (0.15 * s) 0.001` is false)
- CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15 · `Sky.factor` swaps cloudy and overcast · fails (`Sky.factor Sky.cloudy == 0.5` is false)
- CAP-scenario.R1 0 kW of panels gives 0 kWh at 12:00 of day 171 · the code uses a default of 5 kW when `pvKw` is 0 · fails (`v == 0` is false)
- CAP-scenario.R1 the output does not change with the load of the site · the code scales the output by the daily load · fails (`a == b` is false)
- CAP-scenario.R2 seed 7 at latitude 45 gives the same hours two times · the sun height comes from an `asin` of a value just above 1, so an output is NaN · fails (NaN == NaN is false in `sameHour`)
- CAP-scenario.R2 seeds 7 and 8 at latitude 45 give different skies on at least 50 days · the code ignores the seed · fails (0 days differ, and `n ≥ 50` is false)
- CAP-scenario.R2 seed 7 and 365 days give 8760 hours in order of day, then hour · the code gives the hours in order of hour, then day · fails (item 1 is day 1 hour 0)
- CAP-scenario.R2 seed 7 and 0 days give no hours · the loop runs from day 0 to `days` inclusive · fails (24 hours)
- CAP-scenario.R2 seed 7 and 1 day give the 24 hours of day 0 · the same inclusive loop · fails (48 hours)
- CAP-scenario.R2 the 24 hours of each day have the same sky · the code draws a new sky for each hour · fails (an hour differs from hour 0 of its day)
- CAP-scenario.R2 each solar output of seed 7 equals the seasonal sun of its hour · `pvKwh` uses the sky of the day before, while `sky` holds the new sky · fails (`near ... 0.000001` is false on a day where the sky changes)
- CAP-scenario.R2 each solar output at latitude -41 equals the seasonal sun of its hour · `scenario` passes latitude 0 to the solar formula · fails (the outputs differ from `pvOutput` at -41)
- CAP-scenario.R2 at latitude 45 December to February has over twice the overcast days · the summer and winter chances are swapped · fails (`w > 2 * s` is false)
- CAP-scenario.R2 at latitude -41 June to August has over twice the overcast days · the code ignores the sign of the latitude for the half of the year · fails (June to August has fewer overcast days)
- CAP-scenario.R2 60% or more of days 1 to 364 of seed 7 keep the previous sky · the code has no chance to keep the sky · fails (about 40% of days keep, below 218.4)
- CAP-scenario.R2 with 730 days day 365 is day 0 and day 729 is day 364 of the year · `dayOfYear` is `day` with no wrap · fails (`hs[365 * 24]!.dayOfYear == 0` is false)
- CAP-scenario.R2 with 730 days the solar output of the second year uses the day of the year · the solar output uses `day` in place of `dayOfYear` · passes (the declination has a period of 365 days, so day 400 gives the same output as day 35; see Notes)
- CAP-scenario.R3 365 days at latitude 45 have 7300 kWh of load · the base load is the full daily load, and the flexible load comes on top · fails (the total is 8395 kWh)
- CAP-scenario.R3 365 days with 0 kWh of flexible load also have 7300 kWh of load · the hourly profile sums to 1.1 · fails (the total is about 8030 kWh)
- CAP-scenario.R3 at latitude 45 day 15 has 1.45 to 1.55 times the base load of day 197 · the peak is day 197 at each latitude · fails (the ratio is about 0.67)
- CAP-scenario.R3 at latitude -41 day 197 has 1.45 to 1.55 times the base load of day 15 · the peak is day 15 at each latitude · fails (the ratio is about 0.67)
- CAP-scenario.R3 on day 100 the base load at 19:00 is more than at 13:00 · the profile is flat · fails (`a > b` is false)
- CAP-scenario.R3 on day 100 the base load at 07:00 is more than at 03:00 · the profile has only an evening peak and is flat elsewhere · fails (`a > b` is false)
- CAP-scenario.R3 3 kWh of flexible load is 1 kWh at 18:00, 19:00 and 20:00 · the flexible load goes at 17:00, 18:00 and 19:00 · fails (hour 17 has 1 kWh)
- CAP-scenario.R3 6 kWh of flexible load is 2 kWh at 18:00, 19:00 and 20:00 · the code always puts 1 kWh in each of the three hours · fails (hour 18 has 1 kWh, not 2)
- CAP-scenario.R3 0 kWh of flexible load gives 0 kWh in each hour · the code uses a default of 3 kWh when `flexKwh` is 0 · fails (hour 18 has 1 kWh)
- CAP-scenario.R3 seeds 7 and 8 at latitude 45 give the same base and flexible load · the base load is lower on sunny days · fails (`a[i]!.baseLoadKwh == b[i]!.baseLoadKwh` is false on a day where the skies differ)

Follow-ups:
- No acceptance line says that the weather of the second year uses its day of the year for the half of the year. A version that uses `day` in place of `dayOfYear` makes each day after 364 a winter day at latitude 45, and each check passes. A new intent could add a line, for example "Given latitude 45, when seeds 1 to 20 run 730 days, then June to August of the second year has fewer than half the overcast days of December to February".

Notes:
- Each acceptance line of R1 (seasonal sun), R2 (daily weather) and R3 (household load) has at least one check. Each check name starts with its requirement ID and a space. The checks of each requirement are under their `--` comment, as DES-lean-checks (Lean check file form) asks.
- The Interface lists no error codes and no clock. The only seam is the `seed` argument, and the checks use only that seam. No check can hang, because each check is a finite pure computation.
- The check "CAP-scenario.R2 with 730 days the solar output of the second year uses the day of the year" does not catch what its name says. The declination formula repeats each 365 days, so a version that passes `day` to the solar formula gives the same output. The check still catches other wrong solar outputs. No acceptance line asks for this check, so it is not a problem.
- The check "CAP-scenario.R2 seed 7 at latitude 45 gives the same hours two times" proves little about the seed. `scenario` is a pure Lean function, so the same arguments always give the same array. The check fails only on a NaN or on a wrong size. No better check is possible through the Interface.
- The check "CAP-scenario.R2 60% or more of days 1 to 364 of seed 7 keep the previous sky" passes a keep chance of 0.5, which gives about 70% of days kept. The acceptance line permits that result, so the check matches its line.
- Out-of-range `hs[i]!` reads panic and give the default `Hour`. They do not throw, so `tryCatch` does not report them. Most checks first test the size, so a wrong size still gives a clear failure.
