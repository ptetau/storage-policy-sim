Result: pass

Remit: visual

Problems: none

Follow-ups: none

Notes:
- The earlier problem on frame 05 (the `| tail -8` cut the `strategy`, `days` and `seed` lines) is fixed. Frame 05 now shows all 11 lines of `sim run --strategy shift --days 30 --lat 45`, with `strategy          shift` and `days              30`. Each value equals the matching `library:` line: solar 90.8, load 700.9, self-used 90.8, import 610.6, export 0.0, losses 0.5, self-consumption 100.0 %, self-sufficiency 12.9 %.
- The height change from 680 to 780 adds lines to each frame. No frame lost a claim because of the change. Each frame from 01 to 48 shows its step and its caption.
- Frame 48 shows the check totals 34, 54, 35 and 67 (190 checks) and 154 acceptance checks, each with 0 failed. These totals match the progress log of the change.
