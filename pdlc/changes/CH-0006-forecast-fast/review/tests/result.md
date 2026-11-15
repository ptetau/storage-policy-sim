Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-forecast.R6 forecastOf gives the same periods as forecast for the fetch hours 0, 4116 and 8750 · forecastOf ends each period 30 minutes late, or drops the last period of the run · fails (`samePeriods` against `forecast`, and the sizes 96 at hour 0 and 20 at hour 8750)
- CAP-forecast.R6 with an error scale of 0 each value of a fetch at hour 4000 equals its actual power · the day part of the error is not multiplied by the error scale · fails (`badEqual` finds a daylight period of days 166 to 168 whose estimate is far from the actual power)
- CAP-forecast.R6 a fetch at hour 8760 has no period · forecastOf wraps the fetch hour with a modulo and gives the periods of hour 0 · fails (the size must be 0)
- CAP-forecast.R6 no hours give no period for a fetch at hour 0 · forecastOf reads `hours[0]!` and gives 96 periods of a default hour · fails (the size must be 0)
- CAP-forecast.R6 seeds 7 and 8 give a different estimate for a fetch at hour 4000 · forecastOf returns the first result for each later call at the same fetch hour (a cache that ignores the seed) · fails (`differs` is false)
- CAP-forecast.R6 the same seed gives the same forecast from forecastOf and from forecast · the error comes from a source that changes on each call (an unseeded counter) · fails (`samePeriods c d` or `samePeriods a b`)
- CAP-forecast.R6 a fetch at hour 8759 has the 2 periods of the last hour, as forecast gives · the end of the run is off by one, so the last hour gives 0 or 1 periods · fails (the size must be 2 and the ends 525570 and 525600)
- CAP-forecast.R6 forecastOf gives the same periods as forecast with an error scale of 0.5 · forecastOf squares the error scale (0.25), and forecast does not · fails (`samePeriods` on the estimates and bands)
- CAP-forecast.R6 hours of 10 days make a run of 10 days: the fetch at hour 240 has no period · forecastOf takes the run length as 365 days, not as the count of hours divided by 24 · fails (hour 230 gives 96 periods, not 20, and hour 240 gives periods)
- CAP-forecast.R6 no hours give no period for each fetch hour and each error scale · forecastOf guards only the fetch hour 0 for empty hours · fails (the case (1, 1.0) has periods)
- CAP-forecast.R7 the errors of the periods that end at 11:30 and at 13:30 of a day have a correlation from 0.55 to 0.85 · the day part is drawn again for each period, so nothing is shared · fails (the correlation is near 0, below 0.55)
- CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25 · the day part is keyed by the day of the fetch, not by the day where the period ends · fails (reading `b`, both days from one fetch, gives a correlation near 0.7; reading `a` alone would pass)
- CAP-forecast.R7 at least 62% of the days have the same sign of the error at 13:30 in the fetches at hour 0 and at hour 10 · the fetch hour is part of the key of the day part, so the two fetches do not share it · fails (the same-sign share is near 50%, below 62%)
- CAP-forecast.R7 with an error scale of 0 each value of a fetch at hour 0 equals its actual power · the day part is not multiplied by the error scale · fails (`badEqual` finds a daylight period of day 0 or 1 that differs from the actual power)
- CAP-forecast.R7 60% to 95% of the sunny periods of a fetch at 00:00 of each day have the actual power in the band · the bands are 0.5 spreads wide, not 1.28 · fails (coverage is near 38%, below 60%)

Follow-ups: none

Notes:
- The packet does not hold CAP-forecast.R2 (forecast error). I could not check the reading of "sunny period" (actual power above 0 kW) and "cut" (0 kW or 5 kW) that the checks take from it. The checks cite R2 for both terms. I did not count this as a problem.
- The check of R6 for seeds 7 and 8 follows the line: it uses the hours of each seed. A difference can come from the skies as well as from the error. A version that ignores the seed in the error alone could pass when the skies of the two seeds differ in the 48 hours. The line asks for these hours, so I did not count this as a problem.
- A version that forgets the roots in `sqrt(0.7) × d + sqrt(0.3) × e` gives a correlation of about 0.845 and a band coverage of about 91%. Both values sit inside the ranges of the lines. No check that follows the lines can catch it.
- The statistical margins are wide for a correct app. The expected correlation is 0.7 for the same-day line (range 0.55 to 0.85, standard error about 0.03). It is 0 for the next-day line (range -0.25 to 0.25, standard error about 0.05). The expected same-sign share is about 75% (limit 62%). The expected band coverage is about 80% (range 60% to 95%). Each statistical check also has a floor on the count of days or periods, so an empty result cannot pass.
- The next-day check also reads both periods from the fetch of the first day. A correct app passes this reading, because the day part depends on the day where the period ends. It catches a day part keyed by the fetch day.
- The edge of the run has a check on both sides: the fetch at hour 8759 gives 2 periods, and the fetch at hour 8760 gives none.
- No check uses the clock, a process, or a vendor, so no check needs a time limit. No Interface entry can fail, so no check expects an error code.
