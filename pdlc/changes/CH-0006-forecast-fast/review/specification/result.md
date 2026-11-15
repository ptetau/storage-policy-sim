Result: fail

Remit: specification

Problems:
- pdlc/specs/capabilities/CAP-forecast.md:7-14 · The summary in "What it is for" does not show what the change adds. It does not say that the periods of one day share a part of their error (R7, shared error of a day). It does not say that a caller can build the hours once and give them to `forecastOf` (R6, forecast from built hours). The summary still says only "an error that grows with the lead time, from a seed". · Remit rule: the title and the summary of the spec show the behaviour as it is now, and include what the change adds.
- pdlc/specs/capabilities/CAP-forecast.md:175-176 · The sentence "The number `d` depends only on the seed and the day of the run in which the period ends" has two meanings for a period that ends at 00:00. The period from 23:30 to 24:00 of day N ends at 00:00 of day N+1. The same spec writes "a fetch at 00:00 of the day" for the start of a day, so a reader can take day N+1. The code takes day N: `day := hourOfPeriod endMinute / 24` (`StoragePolicySim/Forecast.lean`, `periodOf`). The acceptance lines of R7 test only the periods that end at 11:30 and 13:30, so no line settles this. · Remit rule: a text that is unclear about what the code does, here a sentence with two possible meanings, is a problem. CAP-forecast.R7 is a requirement that this change wrote. Fix: write "the day of the run in which the period lies". The sentence is only in CAP-forecast.md, so one fix is enough.

Follow-ups:
- none

Notes:
- Acceptance lines of R6 (forecast from built hours): met by the code. `forecast` is now `forecastOf (scenario site seed days) site seed errorScale fetchHour`, so the periods equal. With error scale 0, the spread is 0, and the estimate and both bands equal the actual power. At fetch hour 8760 and with no hours, `periodsLeft` is 0, so the array is empty. Seeds 7 and 8 give different hours and different draws.
- Acceptance lines of R7 (shared error of a day): met by the code, from my reading. I did not see the checks and I did not run the code. The random number is `sqrt(0.7) × d + sqrt(0.3) × e`, with `d` from the seed and the day, and `e` from the seed, the fetch hour and the period. The two shares add to 1, so the variance stays 1 and the bands keep their meaning. By theory, the correlation of two periods of one day in one fetch is 0.7 (limits 0.55 to 0.85). The chance of the same sign in the fetches at hour 0 and hour 10 is about 0.75 (limit 0.62). The coverage of the band is about 0.80 (limits 0.60 to 0.95). Different days use different `d`, so the correlation between days is about 0.
- I checked the keys. `dayDraw` mixes four times and `periodDraw` mixes three times, so the two kinds of key do not have the same shape. No fetch hour and period give the key of a day.
- Files: the code diff changes only `StoragePolicySim/Forecast.lean`, the one entry in "Files". The change adds no public name except `forecastOf`, which the spec asks for. The change does not touch the code of CAP-scenario. No README is in "Files".
- The writing check lists spec files of other capabilities: CAP-homesim.md, CAP-hotwater.md, CAP-policy.md, CAP-simulation.md, CAP-strategies.md, DES-errors.md and JOB-simulate.md. The packet does not show their diff. I could not tell whether this change edited them or whether they changed on the base. I did not judge them.
- R2 (forecast error) is not in the packet, so I could not read its text. By the code, a statement that the random number depends only on the seed, the fetch hour and the period is still true, because the day is a function of the fetch hour and the period.
- The interface of CAP-forecast.md still marks `forecastOf` as "proposed", but R6 has the status "built". Remove the marker when the change is verified.
- The seam entry "seed" names only the `seed` argument of `forecast`. `forecastOf` also takes a `seed` that drives the draws. Name both arguments in the seam entry (CAP-forecast.md and change.md).
- change.md, Delivers: "the result of the older call" does not name the call. Write `forecast` in place of "the older call". The older `forecast` of CH-0005 (forecast of the first change) gave other numbers, because R7 changes the draw.
- StoragePolicySim/Forecast.lean, the comment of `normalDraw`: "It has the variance of a normal curve" is unclear. Write "It has a variance of 1".
- Writing check, lines of change.md (rule: a descriptive sentence has 25 words or fewer; an ID has a short description in the same sentence):
  - Sentence length at lines 14, 15, 18, 21, 22, 23, 25, 39 and 46.
  - ID alone at line 21 ("R2") and at line 100 ("IN-0001", "IN-0002", "IN-0001" and "CH-0011").
- Writing check, lines of CAP-forecast.md (the same two rules):
  - Sentence length at lines 31, 161, 162, 165, 171, 172, 180, 188, 189, 190 and 192.
  - ID alone at lines 177, 181 and 188 ("R2").
- Writing check, other files: 132 more findings are in CAP-homesim.md, CAP-hotwater.md, CAP-policy.md, CAP-simulation.md and JOB-simulate.md. Nothing in the packet ties them to this change. They are notes, not problems.
- Per DES-writing-style, the writing rules are a guideline in this project, so no writing finding fails the review. The two problems above fail it because they are about what the text says of the code.
