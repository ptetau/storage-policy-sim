Result: pass

Remit: security

Problems: none

Follow-ups:
- Escape control characters in the detail of an error line. `Problem.line` (the error text) writes the word or the value as typed to stderr. JOB-simulate.R5 (bad command line) asks for the value as typed. Thus, a value with terminal escape codes, for example `sim fly$'\e[2J'`, reaches the terminal unchanged. A new intent can print each control character as an escape, for example `\x1b`, so that an error line cannot change the terminal.
- Cap the length of a number value before `readNumber` (the number reader) reads it. `digitsValue` (the digit sum) builds one `Nat` from all the digits. A very long value, for example 1,000,000 digits, costs time and memory before `OUT_OF_RANGE` (a number outside its range) stops it. The operating system limit on the command line bounds this cost. Thus, the risk is low. A new intent can give `BAD_NUMBER` (a number of the wrong form) for a value of more than, for example, 64 characters.

Notes:
- The input checks meet JOB-simulate.R5 (bad command line). `readNumber` accepts only an optional sign, ASCII digits and an optional point with more digits. `Char.isDigit` accepts only `0` to `9`. Each number option has a range check before the simulation runs, and `--flex` has a check against the `--load` value.
- A huge value can give infinity. Infinity is above each highest bound, so the range step gives `OUT_OF_RANGE`. No parse gives NaN.
- `CommandLine.whole` (the whole-number value) converts with `toUInt64` only after the range step. Thus, `--days` and `--seed` are whole, from 0 to 4294967295, and the conversion cannot wrap. The value `-0` for `--seed` passes the range and gives seed 0. This is safe.
- The work of a run is bounded. The most is `sim compare --days 3650`: four runs of 87,600 hours each.
- The code builds no shell command, query, path or HTML. It reads no file and uses no network.
- The code holds no secrets, and no error line holds a secret.
- The change adds no dependency. `lakefile.toml` adds only the `sim` executable.
- The README check command quotes `"$f"` in the loop. This is safe.
- The packet does not hold `pdlc/config.md`. Thus, I cannot say if the README command is the "all" command that Step 6 (README) names. This question is outside the security remit.
