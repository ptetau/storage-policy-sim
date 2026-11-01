# Handoff · CH-0004 · verify → build

Time: 2026-11-01T01:44:54+00:00

## Done

- Verify round 1 of CH-0004 (sim command) failed on specification and quality. Security and privacy passed. Compliance does not apply.
- All 190 checks and the 154 acceptance checks pass.
- Verify filed IN-0006 (polish of the sim command) for approval, with the five follow-ups.

## Decided on defaults

- none

## Open

- README.md:71 · The `UNKNOWN_COMMAND` row says that the error occurs when "The first word is not `run`, `compare` or `help`". The first word of `sim --help` is `--help`, which is not in that list. Thus, the row says that `sim --help` gives `UNKNOWN_COMMAND`, but `main` prints the usage and exits with 0. README.md:18 says the opposite, so the two README lines disagree. To correct the row, add `--help` to the list, for example "is not `run`, `compare`, `help` or `--help`". · Remit rule: a text that is wrong or unclear about what the code does is a problem. JOB-simulate.R5 (bad command line): "Given `--help`, when the person runs `sim --help`, then it prints the same usage and exits with 0."
- Main.lean:222 · The doc comment of `CommandLine.whole` says "The range step makes sure that the value is whole and not negative". The range step (`rangeProblem?`) does not make sure that the value is whole. The reading step makes sure of that: `readNumber` with `wholeOnly` gives `BAD_NUMBER` for a value with a point. The range step makes sure only that the value is not negative. · Remit rule: a text that is wrong or unclear about what the code does is a problem. Interface: the order of reading (step 2 gives a bad number, step 3 gives the range).

- Main.lean:292 · `usageLine` pads the option with `labelWidth`. The doc of `labelWidth` (Main.lean:231) says that it is the width of a label in a line of `sim run`. Thus, the usage layout depends on a constant that names a different thing. The doc of `usageLine` (Main.lean:290) says "spaces to column 21". That is true only while `labelWidth` is 18. A change to the `sim run` layout would also move the usage text, and nothing tells the reader so. Fix: give the usage its own named width, for example `usageOptionWidth`, or rename `labelWidth` and its doc to say that both layouts share it. · Remit rule "Names tell what things are and what they do."

## Look here

- `pdlc/changes/CH-0004-sim-command/review/specification/result.md`
- `pdlc/changes/CH-0004-sim-command/review/quality/result.md`

## Don't redo

- The checks, and the code that the other reviews passed.

## Next: do this first

Fix the three problems above in `README.md` and `Main.lean`, and run all checks and the acceptance file.
