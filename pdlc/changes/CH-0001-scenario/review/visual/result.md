Result: fail

Remit: visual

Problems:
- 26.png · The caption claims "0 kWh in each hour", but the frame shows only "largest flexible load of an hour: 0.000000 kWh". A largest value of 0 does not show that no hour is below 0, so the frame shows less than its caption claims. Print the lowest and the highest value, or the largest absolute value, as frame 06 does for R1 (seasonal sun). · CAP-scenario.R3 (household load): "Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load." · script

Follow-ups: none

Notes:
- 10.png: the acceptance line of R2 (daily weather) names latitude 45, but the frame shows only "seed 7, two runs of 365 days". The caption does not claim the latitude, so this is not a problem. A later recording can print the latitude, as frame 11 does.
- Each of the 26 acceptance lines has its own frame (frames 02 to 27). Each caption starts with its requirement ID. Frame 01 is a setup frame and shows a good build.
- The numbers on screen agree with the captions. Examples: 4.622 / 1.810 = 2.554 (frame 02), 846 / 246 = 3.439 (frame 16), 287 / 364 = 78.846% (frame 18), and 20.4 / 13.6 = 1.500 (frame 21).
- In frame 25, the list of 24 hours has 1.000 at positions 18, 19 and 20, and 0.000 at each other position.
- No frame shows an error. Frame 28 ends the recording with "34 checks, 0 failed".
