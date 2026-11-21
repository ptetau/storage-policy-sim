Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-forecast.R1 each sunny period of a daily fetch at 00:00 has its 10% band below and its 90% band above its estimate unless the estimate is 5 kW · the 10% band equals the estimate for each period (no band below) · fails (the first period with an estimate from 0 to 5 kW has `p10Kw < estimateKw` false)
- CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is more than the error 0 to 4 hours ahead · the spread falls with the lead time, so the far periods have the smaller error · fails (`mb > ma` is false). A version with no growth passes this check by chance, and the next check fails it.
- CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is more than 1.5 times the error 0 to 4 hours ahead as a share of the actual power · the spread is a flat 0.05 at every lead time · fails (both shares are about 0.04, and the ratio of 1.5 is not reached)
- CAP-forecast.R2 the error of sunny periods 0 to 4 hours ahead is 3% to 6.5% of the actual power · the random error is added only on days with the sky `sunny` · fails (about 40% of the noon periods have a sunny sky, so the mean share is about 0.02, below 0.030)
- CAP-forecast.R2 the error of sunny periods 24 to 48 hours ahead is 8% to 20% of the actual power · the spread is a flat 0.05 at every lead time · fails (the mean share is about 0.04, below 0.08)
- CAP-forecast.R2 60% to 95% of sunny periods of a daily fetch at 00:00 have the actual power in the band · no band, so the 10% and the 90% values equal the estimate · fails (about 0% of the periods have the actual power in the band)
- CAP-forecast.R4 a tie of the UTC time rounds up · the UTC time rounds a tie down · fails (longitude 3.75 gives 00:00, and the check wants 00:30). Version two, `Float.round`, rounds a negative tie away from 0 · fails (longitude 11.25 gives 23:30, and the check wants 00:00 on 1 January). Version three, rounding the shift before the subtraction · fails (longitude 3.75 gives 00:00, and the check wants 00:30).

Follow-ups: none

Notes:
- The three earlier problems are fixed.
  - Tie case (CAP-forecast.R4, Solcast JSON): the new check has the ties 3.75, 11.25 and 18.75, with the negative ones, and the near-tie values 3.74, 3.76, -3.74 and -3.76. I worked each case by hand. The UTC minute is 30 less the shift of 4 minutes per degree. Each tie lands half way between two marks, and each wanted time is the later mark. Each near-tie lands 0.04 minutes from a tie, so it is not a tie. The shifts of the tie values are exact in binary, so a correct app does not lose a tie to a rounding error.
  - 5 kW straddle (CAP-forecast.R1, forecast periods): `badStraddle` now excuses an estimate of 5 kW on both sides. A band version that cuts each value after it forms the bands passes. A band that equals its estimate below 5 kW still fails.
  - Sunny definition (CAP-forecast.R2, forecast error): `isSunny` is now `actualKw e > 0.0`, as the spec says. The growth, error size and coverage checks now count periods of every sky. The window of 10:30 to 14:00 stays, as the earlier review allowed.
- The sunny periods of the changed checks now come from every sky. By the spec model, the share of periods in the band is about 80% for any spread and any sky, so a correct app stays inside the 60% to 95% bounds. The largest effect is the cut at 5 kW, and it is small.
- The first growth check (`mb > ma` on the mean absolute error) cannot fail a version with no growth, because the days of the two groups can have a different amount of sun. The test writer says so in the comment. The relative-share check carries this line: a correct app gives a ratio of about 3, a version with no growth gives about 1, and the bound is 1.5. Taken together, the two checks prove the acceptance line.
- The coverage check alone does not fail a version that adds the error only on sunny-sky days. That version scores about 92%. The two error-size checks fail it. Each line of CAP-forecast.R2 (forecast error) is still proved.
- I did not run the checks. I judged them from the packet only. The counts of sunny periods (at least 1000 in the daily fetch at 00:00, at least 100 in each noon group) are my estimate from the site geometry. They hold with a wide margin, about 3000 periods and about 700 periods.
- The comment "the model gives about 2.5 times" is a little low (about 3 times). This does not change a result.
