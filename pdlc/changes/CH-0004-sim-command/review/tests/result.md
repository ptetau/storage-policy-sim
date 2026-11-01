Result: fail

Remit: tests

Problems:
- tests/JOB-simulate.lean:277 · The check "JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used" compares the printed values with `near e (s - u) 0.1`. Each printed value is rounded to one decimal. Thus a correct app can print values whose difference is exactly 0.1, for example solar 100.1, self-used 50.0 and export 50.0 from the true values 100.06, 50.03 and 50.03. The acceptance line accepts that output. But the Float subtraction of the printed values can give 0.1000000000001, and then the check fails a correct app. The fix is a small extra tolerance, for example `0.1 + 1e-9`. · JOB-simulate.R1 "the `export` value equals `solar` less `self-used`, within 0.1 kWh"; remit rule "A correct app passes each check"
- tests/JOB-simulate.lean:461 · The check "JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER" expects `--days 2.0` to give `BAD_NUMBER`. The spec does not decide this case. R5 says that a number option takes "an optional sign, digits, and an optional point with more digits", and that `--days` and `--seed` "take only whole numbers". The value 2.0 has the number form and is a whole number. Thus a correct app can accept `--days 2.0` as 2 days, and the check fails that app. The fix is to remove the `2.0` case, or to make the spec say first that a whole number has no point. · JOB-simulate.R5 (the number form and the whole-number rule); remit rule "A correct app passes each check"

Wrong versions:
- JOB-simulate.R1 sim run prints the 11 lines in order and exits with 0 · prints `export` before `import` · fails (`firstWords r.out == runLabels`)
- JOB-simulate.R1 each line has its label to column 19 and a value of the right form · pads each label to 17 characters, so the value starts at column 18 · fails (`labelled`, `cs.take 18`)
- JOB-simulate.R1 the first three lines show greedy, 365 days and seed 1 · the default seed is 0 · fails (`row "seed" "1"`)
- JOB-simulate.R1 --pv 0 shows 0.0 kWh of solar and 0.0 % self-consumption · prints `NaN %` for 0 divided by 0 · fails (`ls[9]? == some (row "self-consumption" "0.0 %")`)
- JOB-simulate.R1 --strategy shift --days 30 --lat 45 shows the values of the simulation · ignores `--lat` and keeps -41.3 · fails (`checkShows`, the solar value)
- JOB-simulate.R1 the defaults give the values of the simulation · the default latitude is 41.3, without the minus · fails (`checkShows`, the solar value)
- JOB-simulate.R1 each option goes to its own part of the simulation · swaps `--battery` and `--power` · fails (`bat 4 2` against the import and losses values)
- JOB-simulate.R1 the --flex default is 3, or the --load value when that is less · keeps `--flex` at 3 for `--load 2` · fails (`checkShows a.out ta`, the import and self-used values)
- JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used · prints export as solar less load · fails (`near e (s - u) 0.1`)
- JOB-simulate.R1 --days 3650 exits with 0 and shows 3650 days · the upper limit of `--days` is 365 · fails (`r.code == 0`)
- JOB-simulate.R2 --monthly prints the 11 lines, a blank line, the header and 12 rows from Jan to Dec · omits the blank line · fails (`ls[11]? == some ""` and `ls.length == 25`)
- JOB-simulate.R2 each row shows the totals of its month · swaps the import and export columns · fails (`rowShows`, `w[3]?`)
- JOB-simulate.R2 --monthly --days 400 prints 14 rows that end with Jan and Feb · merges the months of the second year into the rows of the first year, 12 rows · fails (`rows.length == 14`)
- JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul · `--monthly` ignores `--lat`, so December is sunnier than July · fails (`j > 2 * d`)
- JOB-simulate.R2 without --monthly sim run prints only the 11 lines · always prints the table · fails (`(lines r.out).length == 11`)
- JOB-simulate.R2 the 11 lines of --monthly are the lines of sim run · `--monthly` resets the latitude to the default · fails (`(lines a.out).take 11 == lines b.out`)
- JOB-simulate.R3 sim compare prints the header and none, greedy, evening and shift · sorts the rows by name · fails (`firstWords r.out == ["strategy", "none", "greedy", "evening", "shift"]`)
- JOB-simulate.R3 the greedy row of --seed 9 --lat 45 shows the four values of sim run · `sim compare` ignores `--seed` · fails (`fromRun == [w[1]?, w[2]?, w[3]?, w[4]?]`)
- JOB-simulate.R3 each row of sim compare shows the values of the simulation · `sim compare` ignores `--battery` · fails (`compareShows` with `bat 4 5`)
- JOB-simulate.R3 --lat 45 gives greedy a higher self-consumption than none · runs `none` for each row · fails (`g > n`)
- JOB-simulate.R3 sim compare --strategy greedy gives UNKNOWN_OPTION · `sim compare` accepts `--strategy` and ignores it · fails (`r.code == 2`)
- JOB-simulate.R3 sim compare --monthly gives UNKNOWN_OPTION · `sim compare` accepts `--monthly` · fails (`r.code == 2`)
- JOB-simulate.R4 --seed 5 gives the same output two times · mixes the clock into the seed · fails (`a.out == b.out`)
- JOB-simulate.R4 --seed 1 and --seed 2 give different solar values · ignores `--seed` · fails (`sa != sb`)
- JOB-simulate.R4 --seed 2 gives the solar of the simulation with seed 2 · passes the seed plus 1 to `simulate` · fails (`showsNum (valueOf r.out "solar") t.pvKwh`)
- JOB-simulate.R5 sim with no arguments prints the usage and exits with 0 · prints the usage on stderr · fails (`(lines r.out).head? == some usage`)
- JOB-simulate.R5 sim help and sim --help print the same usage and exit with 0 · treats `--help` as an unknown command · fails (`d.code == 0`)
- JOB-simulate.R5 sim fly gives UNKNOWN_COMMAND · exits with 1 · fails (`r.code == 2`)
- JOB-simulate.R5 a command word that differs by its case or a space gives UNKNOWN_COMMAND · lower-cases the command word · fails (`Run`)
- JOB-simulate.R5 --colour red gives UNKNOWN_OPTION · the detail is `--colour red` · fails (`lines r.err == [line]`)
- JOB-simulate.R5 an option that differs by its case, a dash or an equals sign gives UNKNOWN_OPTION · splits `--days=5` at the equals sign · fails (`--days=5`)
- JOB-simulate.R5 sim run now gives UNKNOWN_OPTION · ignores a word that is not an option · fails (`r.code == 2`)
- JOB-simulate.R5 --days with no value gives MISSING_VALUE · reads a missing value as "" and gives `BAD_NUMBER` · fails (the exact line)
- JOB-simulate.R5 --strategy and --flex with no value give MISSING_VALUE · gives `MISSING_VALUE` only for the number options · fails (`--strategy`)
- JOB-simulate.R5 --days abc gives BAD_NUMBER · the detail omits the option · fails (the exact line)
- JOB-simulate.R5 an empty --days gives BAD_NUMBER · treats "" as a missing value · fails (the exact line)
- JOB-simulate.R5 --days 36.5 gives BAD_NUMBER · truncates the value to 36 · fails (`r.code == 2`)
- JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER · trims the spaces before it reads the number · fails (` 2`)
- JOB-simulate.R5 --days +2 is a whole number with a sign · the whole-number reader rejects a sign · fails (`r.code == 0`)
- JOB-simulate.R5 --pv 1e3, .5, 5. and 5kW give BAD_NUMBER · uses a Float reader that accepts `1e3` · fails (`1e3`)
- JOB-simulate.R5 a number with a trailing space, a lone sign or a misplaced sign gives BAD_NUMBER · reads a lone `-` as 0 · fails (`--lat -`)
- JOB-simulate.R5 --pv +3 gives the result of --pv 3 · reads `+3` as 0 · fails (`a.out == b.out`)
- JOB-simulate.R5 --days 0 gives OUT_OF_RANGE · the lower limit is 0 · fails (`r.code == 2`)
- JOB-simulate.R5 --days 3651 gives OUT_OF_RANGE · the test is "at most 3651" · fails (`r.code == 2`)
- JOB-simulate.R5 --days 1 and --days 3650 are accepted · the test is "more than 1" · fails (`1`)
- JOB-simulate.R5 --days 99999999999999999999 gives OUT_OF_RANGE · reads the value into a 64-bit number that wraps, or gives `BAD_NUMBER` on overflow · fails (the exact line)
- JOB-simulate.R5 --seed -1 gives OUT_OF_RANGE · the seed reader rejects a sign with `BAD_NUMBER` · fails (the exact line)
- JOB-simulate.R5 --seed 0 and 4294967295 are accepted, and 4294967296 gives OUT_OF_RANGE · stores the seed as `UInt32`, so 4294967296 wraps to 0 · fails (`4294967296`)
- JOB-simulate.R5 --lat 90 and -90 are accepted, and 90.1 and -90.1 give OUT_OF_RANGE · the test is "less than 90" · fails (`90`)
- JOB-simulate.R5 --pv 0 and 100 are accepted, and 100.1 and -1 give OUT_OF_RANGE · the upper limit is 1000 · fails (`100.1`)
- JOB-simulate.R5 --battery 0 and 200 are accepted, and 200.1 and -0.1 give OUT_OF_RANGE · copies the `--pv` range, 0 to 100 · fails (`200`)
- JOB-simulate.R5 --power 0 and 100 are accepted, and 100.1 gives OUT_OF_RANGE · copies the `--battery` range, 0 to 200 · fails (`100.1`)
- JOB-simulate.R5 --load 0.1 and 1000 are accepted, and 0 and 1000.1 give OUT_OF_RANGE · the lower limit is 0 · fails (`0`)
- JOB-simulate.R5 --load 10 --flex 10 is accepted · the test is "`--flex` less than `--load`" · fails (`--flex 10`)
- JOB-simulate.R5 --load 10 --flex 10.5 gives OUT_OF_RANGE · compares `--flex` with the default load of 20 · fails (`r.code == 2`)
- JOB-simulate.R5 --flex -1 gives OUT_OF_RANGE · `--flex` has no lower limit · fails (`r.code == 2`)
- JOB-simulate.R5 the --flex range shows the last --load value as typed · prints the read value, `10` · fails (`(0 to 10.0)`)
- JOB-simulate.R5 --strategy wild gives UNKNOWN_STRATEGY · lists the names in alphabetical order · fails (the exact line)
- JOB-simulate.R5 a strategy name that differs by its case or a space gives UNKNOWN_STRATEGY · finds the name without regard to case · fails (`Greedy`)
- JOB-simulate.R5 each strategy name is accepted · omits `evening` from the lookup · fails (`--strategy evening`)
- JOB-simulate.R5 --days 10 --days 20 shows 20 days · the first value counts · fails (`row "days" "20"`)
- JOB-simulate.R5 the last value counts before the range is read · checks the range of each value as it reads it · fails (`--days 0 --days 20`)
- JOB-simulate.R5 the command word comes before each option · reads the options before the command word · fails (`UNKNOWN_COMMAND: fly`)
- JOB-simulate.R5 the options are read from left to right and the first problem gives the error · finds the unknown options before the bad numbers · fails (`--days abc --colour red`)
- JOB-simulate.R5 a bad number or strategy comes before a range problem · checks the range of each option as it reads it · fails (`--days 0 --pv x`)
- JOB-simulate.R5 a range problem comes before the --flex check · checks `--flex` against `--load` before the other ranges · fails (`--days 0`)
- JOB-simulate.R5 an error of sim compare gives the same line as an error of sim run · `sim compare` gives no range check · fails (`--lat 91`)

Follow-ups:
- none

Notes:
- The packet does not hold the Interface of CH-0003 (simulation). Thus this review cannot confirm these names: the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh` of `Site`, the fields `capacityKwh` and `powerKw` of `Battery`, `Month.name`, `Month.totals`, `Strategy.all` and `Strategy.name`, and that `Result.months` is an `Array`. If a name is wrong, the file does not compile and each check fails. The check does not pass by mistake.
- `expectRun` and the check "JOB-simulate.R5 sim with no arguments prints the usage and exits with 0" also expect an empty stderr. No acceptance line or Interface entry asks for an empty stderr on success. A correct app that writes a note to stderr fails these checks. This is a small risk, and the expectation is sensible.
- The range table of R5 gives `--power` a lower limit of 0. No check gives `--power` a negative value, for example `--power -0.1`. No acceptance line asks for that case, so it is not a problem. A version with no lower limit on `--power` passes each check.
- The diff and the full file in the packet have the same length. The line numbers above are the lines of `tests/JOB-simulate.lean`.
- Each error code of the Interface has a check that expects the exact line. Each check runs `sim` through `timeout 60`. The checks use only the `--seed` seam and no clock.
