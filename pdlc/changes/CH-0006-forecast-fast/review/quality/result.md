Result: pass

Remit: quality

Problems: none

Follow-ups: none

Notes:
- The earlier review at bde71c519e80 listed no problems, so nothing is carried over.
- The diff since that review changes one doc comment in `StoragePolicySim/Forecast.lean`, on `normalDraw`. The comment said "It has the variance of a normal curve". It now says "It has a variance of 1". The new text is correct: the shared part has the weight 0.7 and the period part has the weight 0.3, so the variances add to 1. It also matches R7, where the sum is still a number from a normal curve. The change adds no code, so no behaviour changes.
