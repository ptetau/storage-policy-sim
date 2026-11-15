Result: fail

Remit: visual

Problems:
- frames/24.png · The step prints "each pv_estimate has four decimals: false". This is an error on screen, and the frame shows the opposite of its caption. The sample line "[2.3112,, 2.3112,, 2.2016,, 2.2016,]" has doubled commas. Its four values each have four decimals, so the check disagrees with the values on screen. The script takes the text "up to the next comma" with the comma included, and the check probably counts that comma. The frame also shows only four values, not each `pv_estimate`. · CAP-forecast.R4 (Solcast JSON), line "Given an error scale of 0 and a fetch at hour 4116, when the JSON is made, then each `pv_estimate` has four decimals"; remit rule "an error on screen is a problem" · script
- frames/25.png · The caption says "each period has the five fields in order". The frame shows only the first period of the JSON, and that period is a night period with 0.0000 in all three values. One period of 96 does not show "each period". · CAP-forecast.R4 (Solcast JSON), line "Given a fetch at hour 0, when the JSON is made, then each period has the five fields in the order above, and `"period":"PT30M"`" · script
- frames/30.png · The sums print as "53.357 kWh" and "53.357 kWh", with three decimals. The line needs equality within 0.000001 kWh. A difference below 0.0005 kWh would look the same on screen. Frames 9 and 26 print the difference with six decimals and "(0.000001 or less)"; this frame does not. · CAP-forecast.R5 (hourly forecast energy), line "Given a fetch at hour 4116, when the hourly energy is made, then the sum of the 48 values is 0.5 times the sum of the estimates of the 96 periods. The tolerance is 0.000001 kWh" · script

Follow-ups: none

Notes:
- The 28 frames that I did not list above pass: frames 1 to 23, 26 to 29 and 31. Each shows what its caption claims. Frame 31 ends the recording with "0 failed" for all six test files, including the 57 acceptance checks of IN-0002.
- Frame 24 is a `script` problem, not an `app` problem, for two reasons. The shown values have four decimals, and frame 31 shows 0 failed on the R4 checks. If the fixed script still prints "false", the kind changes to `app`.
- Fix for frame 24: print a count, for example "96 of 96 pv_estimate values have four decimals", and keep a sample of the values without the extra commas. Fix for frame 25: print a count of periods that match the five fields in order, for example "96 of 96 periods", and keep the sample.
- Frames 6, 7, 12 and 13 say "92 daily fetches at 00:00". A run of 365 days has 365 daily fetches, so these look like every fourth day. The screen does not say so. A short note on screen would remove the doubt.
- Frame 9 prints "largest difference from the actual power". It does not say that the difference covers the estimate and both bands. The line says "each value". Naming the three values on screen would match the caption.
- Frame 25 wraps the JSON line in the middle of the time ("2024-12-" then "31T13:..."). This is a terminal wrap, not a line break in the JSON. A reader could still take it for a break, because the spec says the JSON has no line breaks.
- Frame 31 pipes each test file into `grep 'checks,'`. A file that crashes without a "checks," line prints nothing. Six lines show on screen, so no file is missing now.
