Result: fail

Remit: specification

Problems:
- README.md:71 · The `UNKNOWN_COMMAND` row says that the error occurs when "The first word is not `run`, `compare` or `help`". The first word of `sim --help` is `--help`, which is not in that list. Thus, the row says that `sim --help` gives `UNKNOWN_COMMAND`, but `main` prints the usage and exits with 0. README.md:18 says the opposite, so the two README lines disagree. To correct the row, add `--help` to the list, for example "is not `run`, `compare`, `help` or `--help`". · Remit rule: a text that is wrong or unclear about what the code does is a problem. JOB-simulate.R5 (bad command line): "Given `--help`, when the person runs `sim --help`, then it prints the same usage and exits with 0."
- Main.lean:222 · The doc comment of `CommandLine.whole` says "The range step makes sure that the value is whole and not negative". The range step (`rangeProblem?`) does not make sure that the value is whole. The reading step makes sure of that: `readNumber` with `wholeOnly` gives `BAD_NUMBER` for a value with a point. The range step makes sure only that the value is not negative. · Remit rule: a text that is wrong or unclear about what the code does is a problem. Interface: the order of reading (step 2 gives a bad number, step 3 gives the range).

Follow-ups:
- `sim help extra` and `sim --help extra` print the usage and ignore the extra words, because `main` matches `"help" :: _`. No acceptance line covers extra words after `help`. A new intent can decide if extra words give `UNKNOWN_OPTION`.
- When two options are out of range, `rangeProblem?` reports the first option in the fixed list (`--days`, `--seed`, `--lat` and so on), not the first option that the person typed. The Interface does not give an order for step 3 (range of each option). A new intent can decide on left-to-right order, the same as in step 2 (each option and its value).

Notes:
- All acceptance lines of JOB-simulate.R1 (run one strategy) to R5 (bad command line) agree with the code as far as the packet shows. I traced each R5 error line through `readNumber`, `readOptions` and `rangeProblem?`, and each code, detail, range text (`boundText`), stdout and exit code agrees.
- The packet does not contain the library of CH-0003 (simulation) and the earlier changes. Thus, I could not confirm these items: the field names of `Site` and `Battery`, the fields of `Totals` (for example `selfUsedKwh` and `lossKwh`), that `Month.name` gives `Jan` to `Dec`, `Strategy.all`, `Strategy.name` and `Strategy.ofName?`. The change does not change these items. The checks prove them.
- The packet does not contain `pdlc/config.md`. Thus, I could not confirm that the command in README.md:65 ("Run the checks") is the "all" command, as Step 6 (README) asks. The glob `tests/*.lean` does not read `tests/acceptance/`, which agrees with DES-pdlc-check-tagging (the "all" command does not run an acceptance file).
- The diff changes only the three files in "Files". The `lakefile.toml` change adds `sim` to `defaultTargets` and adds the `[[lean_exe]]` entry. Both are part of "the sim executable", because the Interface says that `lake build` makes `.lake/build/bin/sim`.
- Writing check: README.md:19 has a sentence of 32 words ("The command prints 11 lines: ..."). DES-writing-style rule 6.3 gives a maximum of 25 words. In this project, this rule is a guideline only.
- The JOB-simulate code map lists `Main.lean` and `lakefile.toml: the sim executable`, but not `README.md`. The change lists `README.md` in "Files". This is possibly correct, because a README is not code.
