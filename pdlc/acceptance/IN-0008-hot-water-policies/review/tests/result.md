Result: pass

Remit: tests

Problems:
none

Wrong versions:
- CAP-homesim.R3 0 days give a total of 0 and a ratio of 0% in each field, and 10.5 kWh in the tank · a 0-day run returns 0 for `minTankKwh` and `finalTankKwh` (a fold that starts at 0) · fails (`valsIs` wants 10.5 for both fields, and `zero` no longer lists them)
- CAP-homesim.R5 for a home with an unmet draw the total unmet draw is the sum of the unmet draws of the runs · `evaluate` takes the mean of the unmet draws, or the largest run, in place of the sum · fails (the guard `sumF us > 0.0` makes the sum positive, and `near e.totalUnmetKwh (sumF us) 1e-9` rejects a quarter of it or the largest run)
- CAP-homesim.R5 for a home with an unmet draw unmetSeeds counts the runs with an unmet draw and coldHours is the sum of their cold hours · `evaluate` leaves `unmetSeeds` at 0, or counts the hours with an unmet draw, or takes the cold hours of one run in place of the sum · fails (`e.unmetSeeds > 0`, `e.unmetSeeds == n` and `e.coldHours == cold` each reject one of these)

Follow-ups:
none

Notes:
- Earlier problem 1 (the check of 0 days wanted 0 for `minTankKwh` and `finalTankKwh`) is fixed. The two fields leave the list of zeros. `valsIs` now wants 10.5 kWh for both, as the last line of CAP-homesim.R3 says. The name and the comment of the check match the line.
- Earlier problem 2 (no check of `totalUnmetKwh`, `unmetSeeds` and `coldHours` on a run with an unmet draw) is fixed. The two new checks use the home with an element of 0.2 kW and the policy with 0 heating hours. They compare `evaluate` with the four runs of the seeds 3 to 6 from `runHome`. The seeds and the days of `runsE36` and `evalE3x4` match.
- Each new check guards its own premise (`sumF us > 0.0`, `n > 0`, `cold > 0`). The guards need only one run with an unmet draw. By the draw profile of CAP-hotwater.R4, a January day at latitude -41.3 draws about 5.1 kWh, and the element heats at most 4.8 kWh in a day. The tank loses energy as well. Thus the tank empties within about 10 days, and each run has an unmet draw and cold hours.
- The check of `unmetSeeds` alone passes a version that counts every run, because all four runs have an unmet draw. The unchanged check with the default home (`unmetSeeds == 0` for the seeds 3 to 6) fails that version. Together the two checks pin the count at 0 and at 4.
- The check reads `coldHours` of the evaluation as the sum over the runs. CAP-homesim.R5 says that an evaluation "sums up the runs", and it does not name `coldHours` apart. This reading is fair, and it is not a problem.
- The change to the check of CAP-forecast.R7 (the periods that end at 11:30 of a day and of the next day) is a comment only. The code did not change, so it gets no line under "Wrong versions".
