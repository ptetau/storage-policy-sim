Result: pass

Remit: security

Problems:
none

Follow-ups:
none

Notes:
- This is a re-review. The earlier review at bde71c519e80 had no problems, so no earlier problem needs a check.
- The diff since the earlier review changes one doc comment in `StoragePolicySim/Forecast.lean`, on `normalDraw`. The old text said "It has the variance of a normal curve." The new text says "It has a variance of 1."
- The change touches no code. It reads no input, builds no command, query, path or page, holds no secret, makes no access check, and adds no dependency. Thus, it opens no security problem.
- The new comment is correct: the shares 0.7 and 0.3 add to 1, so the sum of the two parts has a variance of 1.
