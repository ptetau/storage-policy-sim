Result: fail

Remit: visual

Problems:
- frames/13.png · The caption claims that each total of `none` equals the sum of its hours. The frame shows only three totals: solar, import and export. The load total and the loss total do not show on screen, so the frame shows less than its caption claims. · CAP-simulation.R3 (totals and ratios), line 1: "each total equals the sum of its hours"; remit rule "Each part of a caption is visible on screen" · script

Follow-ups: none

Notes:
- The packet lists 27 frames for the 27 steps of `visual.json`. Each acceptance line of CAP-simulation.R1 to R5 has a frame, and each caption starts with its requirement ID.
- Frames 02 to 12 and 14 to 26 show what their captions claim. No frame is blank, and no frame shows an error.
- Frame 27 (all checks pass) shows 34, 54 and 35 checks with 0 failed. The sum is 123 checks, the same as the progress log of the change.
- Frames 12 (R2, 0 kWh battery: same totals) and 17 (R3, 0 days: each total 0) do not print the `selfUsedKwh` total. The frames show solar and export, so a reader can work it out as solar less export. A fix for frame 13 can also print this total in all three frames.
- Frames 22 and 23 (R4, July against December and January) do not print "365 days". The acceptance lines name 365 days, but the captions do not claim it. The script can add "365 days" to the header line, as frames 18 and 19 do.
- The numbers agree across frames. For example, the solar total of 5923.536 kWh shows in frames 12, 13 and 19, and the greedy self-consumption of 70.124% shows in frames 14 and 24.
- `pdlc/specs/design/DES-writing-style.md` is not in the packet. This result follows the fallback rule: short sentences in the active voice.
