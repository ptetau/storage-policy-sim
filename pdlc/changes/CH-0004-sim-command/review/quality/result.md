Result: pass

Remit: quality

Problems: none

Follow-ups: none

Notes:
- The earlier problem is fixed. The earlier problem was that Main.lean:292 `usageLine` used `labelWidth`, the width of a `sim run` label. Now `usageLine` (Main.lean:295) pads with its own constant `usageOptionWidth` (Main.lean:291). The doc of `usageOptionWidth` says what the width covers. The doc of `usageLine` names the constant and no longer names a fixed column. Thus, a change to the `sim run` layout no longer moves the usage text.
- The new width of 18 fits each option in the usage. The longest option is `--strategy NAME`, with 15 characters. Thus, the subtraction in `usageLine` never drops to 0.
- The new doc of `CommandLine.whole` (Main.lean:222) is true. `readNumber` rejects a point when `wholeOnly` is true, so the reading step makes the value whole. The ranges of `--days` (1 to 3650) and `--seed` (0 to 4294967295) keep the value from being negative. `output` calls `whole` only after `rangeProblem?` finds no problem.
- The new README row for `UNKNOWN_COMMAND` matches `main`. `main` takes `run`, `compare`, `help` and `--help`, and gives `UNKNOWN_COMMAND` for each other first word.
