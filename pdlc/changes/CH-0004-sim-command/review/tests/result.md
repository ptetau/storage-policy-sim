Result: pass

Remit: tests

Problems: none

Wrong versions:
- JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used · the app prints the solar total as the export value, and does not subtract the self-used energy · fails (with 5 kW of panels and 20 kWh of daily load, self-used is far more than 0.1 kWh, so `near e (s - u) (0.1 + 1e-9)` is false)
- JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER · the app trims the spaces of a value before it parses the number, and accepts `--days " 2"` as 2 days · fails (the first case expects exit code 2 and `error: BAD_NUMBER: --days  2`, but the app exits with 0)

Follow-ups: none

Notes:
- Earlier problem 1 (the export check fails a correct app when the rounded values differ by exactly 0.1) is fixed. Line 277 now uses the tolerance `0.1 + 1e-9`, so a Float error in the subtraction of the printed values does not fail a correct app.
- Earlier problem 2 (the check expects `--days 2.0` to give BAD_NUMBER, which JOB-simulate.R5 does not decide) is fixed. The diff removes the `2.0` case. The other three cases of that check stay, and each has a value outside the number form of R5 or a value that is not whole.
- The diff changes no other check.
