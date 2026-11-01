Result: fail

Remit: visual

Problems:
- 07 · The frame shows `days 3650`, but no exit code. The shell prints `/bin/sh: 1: Bad substitution` in place of `exit 0`, because `${PIPESTATUS[0]}` needs bash and the recording runs `/bin/sh`. Use `.lake/build/bin/sim run --days 3650 > /tmp/o.txt; echo "exit $?"; grep '^days' /tmp/o.txt` or a similar form without a pipe · JOB-simulate.R1 "Given `--days 3650` ... then it exits with 0 and the `days` line shows 3650"; rule "Each part of a caption is visible on screen" and rule "An error on screen is a problem" · script
- 18 · The frame shows the usage line, but no exit code. The shell prints `/bin/sh: 1: Bad substitution` in place of `exit 0`, for the same `${PIPESTATUS[0]}` reason · JOB-simulate.R5 "Given no arguments, when the person runs `sim`, ... The exit code is 0"; rule "Each part of a caption is visible on screen" and rule "An error on screen is a problem" · script
- 19 · The frame shows the usage line for `sim help`, but no exit code. The shell prints `/bin/sh: 1: Bad substitution` in place of `exit 0` · JOB-simulate.R5 "Given `help`, ... then it prints the same usage and exits with 0"; rule "Each part of a caption is visible on screen" and rule "An error on screen is a problem" · script
- 20 · The frame shows the usage line for `sim --help`, but no exit code. The shell prints `/bin/sh: 1: Bad substitution` in place of `exit 0` · JOB-simulate.R5 "Given `--help`, ... then it prints the same usage and exits with 0"; rule "Each part of a caption is visible on screen" and rule "An error on screen is a problem" · script
- 05 · The `library:` lines match the `sim run` values, but the screen does not show the options that `library.lean` passes to the library. Thus the frame does not show that the library ran with `shift`, 30 days, latitude 45 and seed 1. Print those inputs in the `library:` output, or show the call · JOB-simulate.R1 "The values equal CAP-simulation (hourly energy flows) results for these options"; rule "A frame that shows less than its caption claims is a problem, also when the claim is probably true" · script
- 47 · The caption claims "each error above prints nothing on stdout", but the loop runs only 11 of the error cases. It leaves out `--days ""`, `--days 36.5`, `--pv 1e3`, `--pv .5`, `--pv 5.`, `--pv 5kW`, `--days 3651`, `--days 99999999999999999999`, `--seed 4294967296`, `--lat 90.1`, `--lat -90.1`, `--pv 100.1`, `--battery 200.1`, `--power 100.1`, `--load 0` and `--load 1000.1`. The error frames 25 to 41 merge stderr into stdout with `2>&1`, so no frame shows that these errors go to stderr with an empty stdout · JOB-simulate.R5 "Given each error above, when the person runs the command, then stdout is empty", and the "stderr is" part of each R5 error line; rule "A frame that shows less than its caption claims is a problem" · script

Follow-ups:
- none

Notes:
- Frames 01 to 04, 06, 08 to 17, 21 to 46 and 48 show what their captions claim.
- Frame 25: the line `error: BAD_NUMBER: --days ` ends in a space, and a frame cannot show a trailing space. A form such as `2>&1 | cat -A` would make the space visible. This is a suggestion, not a problem.
- Frame 08: with the default latitude -41.3, the Dec solar value (1273.3 kWh, about 41 kWh each day from 5 kW of panels) is about twice the Jan value (671.1 kWh). This looks high for a 5 kW array. The monthly totals agree with the 11 lines, so the command reports the library values faithfully. The source of the values is CAP-scenario and CAP-simulation, which this change does not change.
- Frame 48: the four test files give 34 + 54 + 35 + 67 = 190 checks and the acceptance file gives 154. These counts match the progress log of the change.
