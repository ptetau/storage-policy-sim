Result: fail

Remit: visual

Problems:
- 05 · The new `| tail -8` cuts the `strategy`, `days` and `seed` lines from the `sim run` output. Thus the sim output on screen no longer shows `shift` or 30 days. Only the typed command and the `library:` line name them, and the `library:` line shows the inputs of the library, not the output of `sim`. Use `| grep -E '^(strategy|days) ' ` with the values, or drop the `tail -8` and keep all 11 lines · JOB-simulate.R1 "Given `--strategy shift --days 30 --lat 45`, when the person runs `sim run`, then the lines show `shift` and 30 days"; rule "Each part of a caption is visible on screen" · script

Follow-ups:
- none

Notes:
- Earlier problem 07 (`--days 3650` with no exit code) is fixed. The frame shows `days 3650` and `exit 0`.
- Earlier problems 18, 19 and 20 (`sim`, `sim help` and `sim --help` with no exit code) are fixed. Each frame shows the usage line and `exit 0`.
- Earlier problem 05 (the library inputs not on screen) is fixed. The `library:` line shows shift, seed 1, 30 days, latitude 45 and the other inputs, and the library values equal the `sim run` values.
- Earlier problem 47 (only 11 error cases, and stderr merged into stdout) is fixed. Frame 47 lists all 27 bad command lines, each with exit 2, 0 bytes on stdout and 1 line on stderr. Frames 15 and 21 to 45 now use `2>&1 >/dev/null`, so the error line on screen comes from stderr alone.
- Frame 47 does not show its own command line `bash pdlc/changes/CH-0004-sim-command/errors.sh`, because the 27 rows push it off the top. The screen also does not show how `errors.sh` counts the bytes. The claim is visible, so this is not a problem, but a shorter header or a smaller font would let a viewer see the command.
- Frames 08 to 14, 16, 17, 46 and 48 have unchanged steps. Each frame shows its caption.
