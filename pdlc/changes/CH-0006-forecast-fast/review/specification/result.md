Result: pass

Remit: specification

Problems: none

Follow-ups: none

Notes:
- Earlier problem 1 (the summary in "What it is for" of CAP-forecast) is fixed. The summary now says that the periods of one day share a part of their error (R7, shared error of a day). It also says that a caller that makes many fetches builds the hours once and gives them to `forecastOf` (R6, forecast from built hours).
- Earlier problem 2 (the sentence in CAP-forecast.R7 with two meanings) is fixed. The sentence now says "the day of the run that holds the hour of the period". The code agrees: `periodOf` takes `day := hourOfPeriod endMinute / 24`, and `hourOfPeriod` gives the hour in which the period lies. A period from 23:30 to 24:00 of day N now has day N in both the spec and the code.
- The new code comment "It has a variance of 1" on `normalDraw` is correct. The two parts have the variances 0.7 and 0.3, and they are independent.
- The `· proposed` mark is gone from the `forecastOf` entry of CAP-forecast. The seam text now names `forecast` and `forecastOf`. The `change.md` Delivers text says "the result of `forecast`". Each of these changes matches the code.
- Only `StoragePolicySim/Forecast.lean` changed in code, and it is the one file in "Files".
- Writing: the `check_writing.py` finding list is empty for the lines that changed. In the R7 text, "one cloud front" and, in the summary, "one weather front" name the same item with two terms (STE rule 1.11, one technical noun for one item). This is a note, not a problem. One line of the R7 paragraph is also longer than the other lines of the paragraph.
