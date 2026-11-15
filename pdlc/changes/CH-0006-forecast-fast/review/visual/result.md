Result: fail

Remit: visual

Problems:
- frames/04.png · The frame shows "forecastOf, fetch at hour 8760: 0 periods" and nothing about the hours. The same line would show for no hours, so the frame does not prove that a full run of 8760 hours ends at hour 8760. Frame 2 prints "8760 hours built once" for r6-1, but frame 4 comes from a separate command (r6-3) that prints no hour count. · CAP-forecast.R6, third line ("Given the same hours, when `forecastOf` runs for the fetch hour 8760, then it has no period") and the remit rule that each part of a caption is visible on screen · script

Follow-ups: none

Notes:
- Frames 1 to 3 and 5 to 12 pass. Each of them shows new output after its step, shows no error, and shows what its caption claims.
- R6 line 1 (frame 2): "same: true" shows that the periods are the same for the fetch hours 0, 4116 and 8750, with 96, 96 and 20 periods. The 20 periods at hour 8750 match the 10 hours left in the run.
- R6 line 2 (frame 3): the largest difference is 0.000000 kW, with a tolerance of 0.000001 kW, over 96 periods. The first sunny period (0.396 kW) shows that the input is not trivial.
- R6 line 5 (frame 6): 64 of 96 periods differ between seed 7 and seed 8. The 32 equal periods are probably the night periods.
- R7 (frames 7 to 11): correlation 0.736 (range 0.55 to 0.85), correlation -0.037 (range -0.25 to 0.25), same sign 269 of 365 days = 73.699% (at least 62%), error scale 0 gives a difference of 0.000000 kW with a sum of 24.258 kW, and 14180 of 17504 sunny periods are in the band = 81.010% (range 60% to 95%). All are in range, so there is no `app` problem.
- The R7 frames print the seed, the error scale and "365 fetches", but not the latitude (45) and the panels (5 kW) of the site. Only frame 2 prints them. This is not a problem, because no caption claims the site. A demo that prints the site in each R7 frame would be easier to check.
- Frame 12 ends the recording with "15 checks, 0 failed" for `tests/CAP-forecast.lean` and "57 checks, 0 failed" for the acceptance file of IN-0002. It does not run the acceptance file of IN-0001, which has three usage checks that fail until CH-0011, as the progress log says. The frame prints no file names, but the order of the two lines matches the order of the files in the loop.
