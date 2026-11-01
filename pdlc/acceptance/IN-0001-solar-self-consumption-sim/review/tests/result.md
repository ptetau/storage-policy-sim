Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354 · the declination ignores the day, so each day gives the same noon output · fails (a > 2.0 * b is false when a equals b)
- CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171 · the code takes the absolute latitude, so the south has the northern seasons · fails (day 354 gives less than day 171, so a > 2.0 * b is false)
- CAP-scenario.R2 60% or more of days 1 to 364 keep the previous sky · each day draws a new sky with no chance to keep the sky of the day before · fails (only about 40% of days keep by chance, which is less than 0.6 * 364.0, about 218 days)
- CAP-simulation.R2 a battery with 2 kW of power charges and discharges 2 kWh or less · the discharge has no power cap · fails (the stepHour call with 5 kWh stored and a 3 kWh shortfall gives a discharge over 2, and flowIs expects 2)
- CAP-simulation.R2 a 5 kWh battery holds 0 to 5 kWh each hour · the charge has no capacity cap · fails (socKwh goes over 5.0 + 1e-9 on a sunny summer day)
- CAP-simulation.R3 the self-consumption is 100 × (solar - export) / solar · the code divides by the load and not by the solar · fails (want differs from selfConsumption by more than 1e-6)
- CAP-simulation.R3 the self-sufficiency is 100 × (load - import) / load · the code returns a share from 0 to 1, not a percentage · fails (want is 100.0 times larger than selfSufficiency)
- CAP-simulation.R4 July has more than twice the solar of December · each month gets an equal share of the solar of the run, the total divided by 12 · fails (the July and December values are equal, so the July value is not more than 2.0 times the December value)
- JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul · the command ignores --lat and keeps the default -41.3 · fails (at -41.3 the Jul solar is less than the Dec solar, so j > 2.0 * d is false)

Follow-ups: none

Notes:
- Each change in the diff only writes a number literal as a Float literal, for example `2 * b` becomes `2.0 * b`, and `x < 0` becomes `x < 0.0`. In Lean 4, the literal takes the type Float in both forms. Thus each changed check keeps its meaning.
- The helper round1 (round to one decimal, half away from zero) also changed in the same way. Its result does not change, so the checks that use it through showsNum and checkShows do not change.
- The earlier review listed no problems, so no earlier problem needs a fix.
