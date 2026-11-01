Result: pass

Remit: specification

Problems: none

Follow-ups: none

Notes:
- The earlier problem at README.md:71 (the `UNKNOWN_COMMAND` row left out `--help`) is fixed. The row now says "The first word is not `run`, `compare`, `help` or `--help`". This agrees with `main`, which prints the usage for `--help` and exits with 0. It also agrees with README.md:18 and with JOB-simulate.R5 (bad command line).
- The earlier problem at Main.lean:222 (the doc comment of `CommandLine.whole` gave the wrong step) is fixed. The comment now says that the reading step makes sure that the value is whole, and that the range step makes sure that the value is not negative. `readNumber` with `wholeOnly` gives `BAD_NUMBER` for a value with a point. `rangeProblem?` gives `OUT_OF_RANGE` below 1 for `--days` and below 0 for `--seed`. Thus, the comment is correct.
- The new constant `usageOptionWidth` (18) replaces `labelWidth` (18) in `usageLine`. The output of the usage does not change. The new doc comment of `usageLine` is correct: two spaces, the option and its value, spaces to fill 18 characters, and then the meaning. The longest option text is `--strategy NAME` (15 characters), so the subtraction does not go below 0.
- The new line in the progress log of change.md is correct, and it changes no behaviour.
- The writing check found nothing on the lines that changed. I found no break of DES-writing-style (writing rules) on those lines.
