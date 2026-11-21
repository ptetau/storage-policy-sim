Result: pass

Remit: visual

Problems: none

Follow-ups: none

Notes:
- This is a re-review. I judged frames 24 to 31, the frames without the mark "unchanged since the earlier review". The three earlier problems are fixed.
- Earlier problem on frame 24 (R4, each `pv_estimate` has four decimals) is fixed. The frame now prints "each pv_estimate has four decimals: true" for the fetch at hour 4116 with error scale 0, after the line "96 periods". The sample line is "[2.3112, 2.3112, 2.2016, 2.2016]". It has no doubled commas, and each value has four decimals, so the check and the values agree. No error shows on screen.
- Earlier problem on frame 25 (R4, each period has the five fields in order) is fixed. The frame now prints "fetch at hour 0: 96 periods in the JSON" and "each period has the five fields in order, and "period":"PT30M": true". It also prints the first period with sun. That period has the five fields in order, non-zero values, and `"period":"PT30M"`.
- Earlier problem on frame 30 (R5, the sum of the 48 values is 0.5 times the sum of the estimates) is fixed. The frame now prints "difference: 0.000000 kWh (0.000001 or less)". The tolerance of 0.000001 kWh is visible, and the difference has six decimals.
- Frames 26 to 29 (R5 lines 1 to 4) and frame 31 (all checks pass) show what their captions claim. Frame 31 ends the recording with six lines that each read "0 failed", and the last line reads "57 checks, 0 failed".
- The "Changes since the earlier review" section of the packet says "Nothing changed". The frames show that the demo output changed, so that section is incomplete. The diff of the script and `demo.lean` is not in the packet. I judged the frames as they are.
