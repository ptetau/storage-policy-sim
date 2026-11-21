Result: pass

Remit: visual

Problems: none

Follow-ups: none

Notes:
- The earlier problem is fixed. Frame 4 (new caption "hours of a run of 8760 hours: a fetch at hour 8760 has no period") now shows two lines from the same command r6-3: "hours of the run: 8760" and "forecastOf, fetch at hour 8760: 0 periods". The hour count and the empty result are on screen together, so the frame proves the third line of CAP-forecast.R6.
- Frames 5 to 12 changed only because the output of r6-3 grew by one line and the screen scrolls. Each frame still shows what its caption claims:
  - Frame 5 (R6, no hours): "forecastOf with no hours, fetch at hour 0: 0 periods".
  - Frame 6 (R6, seeds 7 and 8): "64 of 96 (at least 1)" periods with a different estimate.
  - Frame 7 (R7, same day): correlation 0.736, range 0.55 to 0.85.
  - Frame 8 (R7, next day): correlation -0.037, range -0.25 to 0.25.
  - Frame 9 (R7, same sign): 73.699%, at least 62%.
  - Frame 10 (R7, error scale 0): largest difference 0.000000 kW, limit 0.000001 kW.
  - Frame 11 (R7, band): 81.010%, range 60% to 95%.
  - Frame 12 (end): "15 checks, 0 failed" and "57 checks, 0 failed".
- No error shows on screen. The last frame shows that all checks pass.
- In frames 7 to 12 the top line of the screen is cut off by the scroll. The claim of each frame is in the last lines, so this is not a problem.
