# Review packet · CH-0004-sim-command · tests

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: aed11b17794b9d671a6f389c8267a70bbf59d5ea

# Remit: tests

Default: yes

You judge the checks, not the code. You do not see the code. The list below is for the
component checks of a change. For the acceptance checks of an intent, the section
"Acceptance checks of an intent" gives the differences.

- Each acceptance line in the change spec has at least one check. The exception is a
  requirement marked `(retire)`: its acceptance lines get no check, and each check that
  only proved them is gone.
- The name of each check contains its requirement ID.
- Each check tests what the acceptance line says, through the "Interface" in the change
  spec. The check does not depend on the internal structure of the code.
- A component check is permitted to prepare state directly, for example with a fixture
  file. But the check reads each result through the interface, unless the requirement is
  about the stored form.
- A check proves each line at the surface that the line names. A line where the person
  clicks needs a check that clicks and reads what shows. A check of a helper below that
  surface is not sufficient alone.
- If a line depends on the current date or time, its check sets the clock through a seam
  at that same surface. A check that runs a command sets the clock with the environment
  variable or flag of the command. Each of these is a problem:
  - Using the real clock, or setting the time only on a helper below the surface.
  - Leaving a line to manual checks when a stand-in seam could reach the surface.
- Each check can fail. It fails on a plausible wrong version of the code (see "Wrong
  versions"). A check that passes, whatever the code does, does not count.
- A correct app passes each check. A fake that stands in for something real must use the
  names and the behaviour of the real thing. Then the check does not prove only the fake.
- No check can hang. Anything that waits for the app has a time limit.
- Each error code that the Interface lists has a check that expects that exact code.
- The checks control time, randomness, and vendors only through the "Test seams" of the
  Interface.
- The checks are sufficiently clear that a failure tells you what broke.

## Wrong versions

For each check, name one plausible wrong version of the code. Decide whether the check
fails on that version. Write one line for each check under "Wrong versions" in your
result: the check, the wrong version, and `fails` or `passes`. A check that passes a
plausible wrong version is a problem. Name the value or line that catches the wrong
version. On a re-review, write a line only for each check that changed since the earlier
review.

Look for these traps:

- Examples that also fit a wrong rule. These are common cases:
  - A rule about order, tested with items that are already in that order or in
    alphabetical order.
  - Values that come out the same if the code rounds up, rounds down, or rounds to the
    nearest value.
  - Text that is already in the case that the rule asks for.
- A limit that the check does not test exactly at the edge and one past the edge. For "at
  most 20", the value 20 passes and the value 21 fails. Values near the edge prove nothing
  about the edge.
- A rule about every member of a class that the check tests without a non-member.
  "Any other value is an error" needs a value close to an allowed value, not only a few
  far-off values. A close value differs by its case, a space, or a prefix. "Only the
  owner may" needs a person who is not the owner.

## Acceptance checks of an intent

The packet holds the intent, the full text of its requirements, and the "Interface" of
each of its changes. Judge the acceptance checks by the list at the top, with these
differences:

- Each acceptance line of each requirement that the intent lists has at least one check. A
  `retiring` requirement has no check. A stored-data line also has no check here.
- Each check uses only what a user uses: commands, HTTP requests, pages, or the public
  functions of a library. A check can use each feature of the intent, and each feature
  that exists already.
- No check reads or writes stored data directly. A check that opens a saved file or
  queries a store is a problem.
- A stored-data line needs direct access to the stored data. The line is about the stored
  form, or it needs a state that the interface cannot make. An example of such a state is
  an old or a broken data file. The comment at the top of the file lists each such line, with a change of the
  intent that lists its requirement. Such a line with no check is not a problem.
- A line in that list that the interface can prove is a problem. So is a listed line whose
  change does not list its requirement. The packet gives the requirements of each change.
- A check can leave the acceptance file of an earlier intent only when the check proved a
  requirement that this intent changes or retires. Then a check in this file proves the
  new line. Any other removal is a problem.
- Each check fails until the last change of the intent is built. That is not a problem.
- When the intent lists one change, these checks are also the checks of that change. Then
  each error code and each test seam in its "Interface" has a check.

Write "Wrong versions" for the acceptance checks in the same way as for other checks.

## The change spec

````
# CH-0004 · The sim command

Intent: IN-0001 · Scope: JOB-simulate · Status: testing · Ticket: none · Branch: pdlc/CH-0004-sim-command · Base: pdlc/CH-0003-simulation

Tests-Locked: 79a6f27

## Delivers

A person runs `sim run`, `sim run --monthly` and `sim compare` in a terminal. A bad
command line gives one coded error and exit code 2.

## Requirements

### JOB-simulate.R1 · Run one strategy

- Given no options, when the person runs `sim run`, then it prints the 11 lines in order and exits with 0.
- Given no options, when the person runs `sim run`, then the first three lines are `strategy          greedy`, `days              365` and `seed              1`.
- Given `--pv 0`, when the person runs `sim run`, then the solar line is `solar             0.0 kWh`. The self-consumption line is `self-consumption  0.0 %`.
- Given `--strategy shift --days 30 --lat 45`, when the person runs `sim run`, then the lines show `shift` and 30 days. The values equal CAP-simulation (hourly energy flows) results for these options.
- Given `--strategy none --battery 0`, when the person runs `sim run`, then the `export` value equals `solar` less `self-used`, within 0.1 kWh.
- Given `--days 3650`, when the person runs `sim run`, then it exits with 0 and the `days` line shows 3650.

### JOB-simulate.R2 · Monthly table

- Given `--monthly`, when the person runs `sim run`, then the table has the header and 12 rows, from `Jan` to `Dec`.
- Given `--monthly --days 400`, when the person runs `sim run`, then the table has 14 rows. The last two rows are `Jan` and `Feb`.
- Given `--monthly --lat 45`, when the person runs `sim run`, then the `Jul` solar value is more than twice the `Dec` solar value.
- Given no `--monthly`, when the person runs `sim run`, then it prints only the 11 lines.

### JOB-simulate.R3 · Compare strategies

- Given no options, when the person runs `sim compare`, then it prints the header and the rows `none`, `greedy`, `evening` and `shift`, in this order.
- Given `--seed 9 --lat 45`, when the person runs `sim compare`, then the `greedy` row shows the same four values as `sim run --seed 9 --lat 45`.
- Given `--lat 45`, when the person runs `sim compare`, then the `greedy` self-consumption is more than the `none` self-consumption.
- Given `--strategy greedy`, when the person runs `sim compare`, then it prints `error: UNKNOWN_OPTION: --strategy` on stderr and exits with 2.

### JOB-simulate.R4 · Repeatable weather

- Given `--seed 5`, when the person runs `sim run` two times, then the two outputs are the same.
- Given `--seed 1` and `--seed 2`, when the person runs `sim run` with each, then the two `solar` values differ.

### JOB-simulate.R5 · Bad command line

- Given no arguments, when the person runs `sim`, then the first line on stdout is `usage: sim run [options] | sim compare [options]`. The exit code is 0.
- Given `help`, when the person runs `sim help`, then it prints the same usage and exits with 0.
- Given `--help`, when the person runs `sim --help`, then it prints the same usage and exits with 0.
- Given the command `fly`, when the person runs `sim fly`, then stderr is `error: UNKNOWN_COMMAND: fly`. The exit code is 2.
- Given `--colour red`, when the person runs `sim run`, then stderr is `error: UNKNOWN_OPTION: --colour`. The exit code is 2.
- Given `--days` with no value, when the person runs `sim run`, then stderr is `error: MISSING_VALUE: --days`. The exit code is 2.
- Given `--days abc`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days abc`. The exit code is 2.
- Given `--days ""`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days `. The exit code is 2.
- Given `--days 36.5`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days 36.5`. The exit code is 2.
- Given `--pv 1e3`, `--pv .5`, `--pv 5.` or `--pv 5kW`, when the person runs `sim run`, then each gives `BAD_NUMBER` and exit code 2.
- Given `--pv +3`, when the person runs `sim run`, then it exits with 0, and the result equals the result of `--pv 3`.
- Given `--days 0`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 0 (1 to 3650)`. The exit code is 2.
- Given `--days 3651`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 3651 (1 to 3650)`. The exit code is 2.
- Given `--days 99999999999999999999`, when the person runs `sim run`, then it gives `OUT_OF_RANGE` and exit code 2.
- Given `--seed -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)`. The exit code is 2.
- Given `--seed 4294967295`, when the person runs `sim run`, then it exits with 0. `--seed 4294967296` gives `OUT_OF_RANGE`.
- Given `--lat 90` and `--lat -90`, when the person runs `sim run`, then each exits with 0.
- Given `--lat 90.1` and `--lat -90.1`, when the person runs `sim run`, then each gives `OUT_OF_RANGE` and exit code 2.
- Given `--pv 100` and `--pv 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--pv -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --pv -1 (0 to 100)`. The exit code is 2.
- Given `--battery 200` and `--battery 200.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--power 100` and `--power 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 0.1` and `--load 0`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 1000` and `--load 1000.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 10 --flex 10`, when the person runs `sim run`, then it exits with 0.
- Given `--load 10 --flex 10.5`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --flex 10.5 (0 to 10)`. The exit code is 2.
- Given `--strategy wild`, when the person runs `sim run`, then stderr is `error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)`. The exit code is 2.
- Given the extra word `now`, when the person runs `sim run now`, then stderr is `error: UNKNOWN_OPTION: now`. The exit code is 2.
- Given `--days 10 --days 20`, when the person runs `sim run`, then the `days` line shows 20.
- Given each error above, when the person runs the command, then stdout is empty.

## Relies on

- CAP-scenario (used, not changed)
- CAP-strategies (used, not changed)
- CAP-simulation (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

The command is `.lake/build/bin/sim`, after `lake build`. Its source is `Main.lean`. A check
runs it as a process, as `DES-lean-checks` says. A check can also call the library of
CH-0003 (simulation) to compare values.

- `sim`, `sim help` and `sim --help`: the usage on stdout, exit code 0. The first line is
  `usage: sim run [options] | sim compare [options]`.
- `sim run [options]`: 11 lines on stdout, exit code 0.
  - Each line is a label, spaces to column 19, and a value. Thus, the label and its
    spaces fill 18 characters.
  - The first three lines are `strategy` (the name), `days` and `seed` (whole numbers).
  - Then come `solar`, `load`, `self-used`, `import`, `export` and `losses`. Each value
    has one decimal and ` kWh`.
  - The last two lines are `self-consumption` and `self-sufficiency`. Each value has one
    decimal and ` %`.
  - `solar` is `Totals.pvKwh`, `load` is `Totals.loadKwh`, `self-used` is
    `Totals.selfUsedKwh`, and `losses` is `Totals.lossKwh`. The ratios are
    `Totals.selfConsumption` and `Totals.selfSufficiency`.
  - The values come from `simulate` with `Site.mk lat pv load flex`,
    `Battery.mk battery power`, the strategy, the seed and the days. Each value is rounded
    to one decimal, half away from zero.
- `sim run --monthly [options]`: the 11 lines, a blank line, the header
  `month solar-kWh load-kWh import-kWh export-kWh self-consumption-% self-sufficiency-%`,
  and one row for each item of `Result.months`. Each row has seven fields split by spaces.
  The first field is the month name. The next six are one decimal each of `pvKwh`,
  `loadKwh`, `importKwh`, `exportKwh`, `selfConsumption` and `selfSufficiency`.
- `sim compare [options]`: the header
  `strategy self-consumption-% self-sufficiency-% import-kWh export-kWh` and one row for each
  strategy of `Strategy.all`. Each row has five fields split by spaces: the name, then one
  decimal each of `selfConsumption`, `selfSufficiency`, `importKwh` and `exportKwh`.
- The `--flex` default is 3, or the `--load` value when that is less.
- The options are `--strategy`, `--days`, `--seed`, `--lat`, `--pv`, `--battery`, `--power`,
  `--load` and `--flex`, each with one value, and `--monthly` with no value. The defaults
  and the ranges are in JOB-simulate.R1 (run one strategy) and R5 (bad command line).
- Errors: one line `error: <code>: <detail>` on stderr, nothing on stdout, exit code 2. The
  codes are `UNKNOWN_COMMAND`, `UNKNOWN_OPTION`, `MISSING_VALUE`, `BAD_NUMBER`,
  `OUT_OF_RANGE` and `UNKNOWN_STRATEGY`. The detail of each code is this:
  - `UNKNOWN_COMMAND`: the command word, for example `error: UNKNOWN_COMMAND: fly`.
  - `UNKNOWN_OPTION`: the word, for example `error: UNKNOWN_OPTION: --colour`.
  - `MISSING_VALUE`: the option, for example `error: MISSING_VALUE: --days`.
  - `BAD_NUMBER`: the option, a space, and the value as typed, for example
    `error: BAD_NUMBER: --days abc`.
  - `OUT_OF_RANGE`: the option, the value as typed, and the range in brackets, for example
    `error: OUT_OF_RANGE: --days 0 (1 to 3650)`. Each range is written as in the table of
    JOB-simulate.R5 (bad command line): `(1 to 3650)`, `(0 to 4294967295)`, `(-90 to 90)`,
    `(0 to 100)`, `(0 to 200)`, `(0 to 100)`, `(0.1 to 1000)`. The `--flex` range is `(0 to <the --load
    value as typed>)`.
  - `UNKNOWN_STRATEGY`: the name and the list, for example
    `error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)`.
- The command reads the command line in this order, and the first problem gives the error:
  1. The command word.
  2. Each option and its value, from left to right. A bad number or strategy name stops here.
  3. The range of each option.
  4. The `--flex` value against the `--load` value.

### Test seams

- randomness: the `--seed` option. The same seed gives the same weather. The README names
  this option.
- clock: none, because no line depends on the real date or time.

## Files

- `Main.lean`
- `lakefile.toml: the sim executable`
- `README.md`

## Check files

- `tests/JOB-simulate.lean`

## Steps

### Step 1 · Run one strategy · [ ]

- Requirement: JOB-simulate.R1
- Check: the checks named `JOB-simulate.R1 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 2 · Monthly table · [ ]

- Requirement: JOB-simulate.R2
- Check: the checks named `JOB-simulate.R2 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 3 · Compare strategies · [ ]

- Requirement: JOB-simulate.R3
- Check: the checks named `JOB-simulate.R3 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 4 · Repeatable weather · [ ]

- Requirement: JOB-simulate.R4
- Check: the checks named `JOB-simulate.R4 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 5 · Bad command line · [ ]

- Requirement: JOB-simulate.R5
- Check: the checks named `JOB-simulate.R5 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 6 · README · [ ]

- Requirement: JOB-simulate.R1, JOB-simulate.R2, JOB-simulate.R3, JOB-simulate.R4, JOB-simulate.R5
- Check: none
- Done when: the README tells what `sim run`, `sim run --monthly` and `sim compare` do, with each option, default and range. It names the `--seed` seam. It tells how to build with `lake build`, and how to run the checks with the "all" command of `pdlc/config.md`.

## Manual checks

none

## Progress log

- Planned last, because the command uses CH-0001 (scenario), CH-0002 (strategies) and CH-0003 (simulation).
````

## The spec it covers: title and summary

````
# JOB-simulate · Simulate a year of solar and compare strategies

Status: active

## Who and why

A person who plans a home solar system runs `sim` in a terminal. They run one strategy over
seasons and weather with `sim run`, and see the self-consumption and self-sufficiency.
They add `--monthly` to see each month. They compare all strategies on the same weather
with `sim compare`. The same `--seed` gives the same weather, so that each change of an
option is a fair test.

## Relies on

- Capabilities: CAP-scenario (sun, weather and load), CAP-strategies (battery and load strategies), CAP-simulation (hourly energy flows)
- Design: DES-errors (error codes), DES-writing-style (writing rules)

## Code map

- `Main.lean`
- `lakefile.toml: the sim executable`
````

## The requirements, in full

### JOB-simulate.R1 · Run one strategy

Status: ready · Intents: IN-0001

`sim run` simulates one strategy, prints the result on stdout, and exits with 0. Each line
is a label, spaces to column 19, and a value (assumed). An energy has one decimal and `kWh`,
and a ratio has one decimal and `%` (assumed).

The lines are `strategy`, `days`, `seed`, `solar`, `load`, `self-used`, `import`, `export`,
`losses`, `self-consumption` and `self-sufficiency`, in this order (assumed).

The options and their defaults are these (assumed):

- `--strategy`: `greedy`.
- `--days`: 365. `--seed`: 1.
- `--lat`: -41.3 (degrees). `--pv`: 5 (kW of panels).
- `--battery`: 10 (kWh). `--power`: 5 (kW of the battery).
- `--load`: 20 (kWh each day). `--flex`: 3 (kWh of the daily load that can move), or the `--load` value when that is less.

- Given no options, when the person runs `sim run`, then it prints the 11 lines in order and exits with 0.
- Given no options, when the person runs `sim run`, then the first three lines are `strategy          greedy`, `days              365` and `seed              1`.
- Given `--pv 0`, when the person runs `sim run`, then the solar line is `solar             0.0 kWh`. The self-consumption line is `self-consumption  0.0 %`.
- Given `--strategy shift --days 30 --lat 45`, when the person runs `sim run`, then the lines show `shift` and 30 days. The values equal CAP-simulation (hourly energy flows) results for these options.
- Given `--strategy none --battery 0`, when the person runs `sim run`, then the `export` value equals `solar` less `self-used`, within 0.1 kWh.
- Given `--days 3650`, when the person runs `sim run`, then it exits with 0 and the `days` line shows 3650.

### JOB-simulate.R2 · Monthly table

Status: ready · Intents: IN-0001

`sim run --monthly` prints the 11 lines, a blank line, and a table with one row for each
month (assumed). The header is `month solar-kWh load-kWh import-kWh export-kWh
self-consumption-% self-sufficiency-%` with the columns aligned by spaces (assumed). Each
row starts with the short month name, for example `Jan`, and has seven fields.

- Given `--monthly`, when the person runs `sim run`, then the table has the header and 12 rows, from `Jan` to `Dec`.
- Given `--monthly --days 400`, when the person runs `sim run`, then the table has 14 rows. The last two rows are `Jan` and `Feb`.
- Given `--monthly --lat 45`, when the person runs `sim run`, then the `Jul` solar value is more than twice the `Dec` solar value.
- Given no `--monthly`, when the person runs `sim run`, then it prints only the 11 lines.

### JOB-simulate.R3 · Compare strategies

Status: ready · Intents: IN-0001

`sim compare` runs each strategy on the same weather, and prints one row for each strategy.
The header is `strategy self-consumption-% self-sufficiency-% import-kWh export-kWh`
(assumed). The rows come in the order of the strategy list, and the columns align by
spaces. `sim compare` takes each option of `sim run` except `--strategy` and `--monthly`
(assumed).

- Given no options, when the person runs `sim compare`, then it prints the header and the rows `none`, `greedy`, `evening` and `shift`, in this order.
- Given `--seed 9 --lat 45`, when the person runs `sim compare`, then the `greedy` row shows the same four values as `sim run --seed 9 --lat 45`.
- Given `--lat 45`, when the person runs `sim compare`, then the `greedy` self-consumption is more than the `none` self-consumption.
- Given `--strategy greedy`, when the person runs `sim compare`, then it prints `error: UNKNOWN_OPTION: --strategy` on stderr and exits with 2.

### JOB-simulate.R4 · Repeatable weather

Status: ready · Intents: IN-0001

The seed sets the weather. The same options and seed give the same output each time.

- Given `--seed 5`, when the person runs `sim run` two times, then the two outputs are the same.
- Given `--seed 1` and `--seed 2`, when the person runs `sim run` with each, then the two `solar` values differ.

### JOB-simulate.R5 · Bad command line

Status: ready · Intents: IN-0001

A bad command line prints one error line on stderr, prints nothing on stdout, and exits
with 2 (assumed). The line is `error: <code>: <detail>` (assumed). `sim`, `sim help` and
`sim --help` print the usage on stdout and exit with 0.

A number option takes an optional sign, digits, and an optional point with more digits
(assumed). `--days` and `--seed` take only whole numbers (assumed). When an option comes
twice, the last value counts (assumed). The `--flex` range shows the `--load` value as
the person typed it (assumed). Any other word is an unknown option (assumed). The ranges are these (assumed):

| Option | Lowest | Highest |
|---|---|---|
| `--days` | 1 | 3650 |
| `--seed` | 0 | 4294967295 |
| `--lat` | -90 | 90 |
| `--pv` | 0 | 100 |
| `--battery` | 0 | 200 |
| `--power` | 0 | 100 |
| `--load` | 0.1 | 1000 |
| `--flex` | 0 | the `--load` value |

The range in an `OUT_OF_RANGE` line is `(<lowest> to <highest>)`, written as in this table,
for example `(-90 to 90)` and `(0.1 to 1000)` (assumed).

- Given no arguments, when the person runs `sim`, then the first line on stdout is `usage: sim run [options] | sim compare [options]`. The exit code is 0.
- Given `help`, when the person runs `sim help`, then it prints the same usage and exits with 0.
- Given `--help`, when the person runs `sim --help`, then it prints the same usage and exits with 0.
- Given the command `fly`, when the person runs `sim fly`, then stderr is `error: UNKNOWN_COMMAND: fly`. The exit code is 2.
- Given `--colour red`, when the person runs `sim run`, then stderr is `error: UNKNOWN_OPTION: --colour`. The exit code is 2.
- Given `--days` with no value, when the person runs `sim run`, then stderr is `error: MISSING_VALUE: --days`. The exit code is 2.
- Given `--days abc`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days abc`. The exit code is 2.
- Given `--days ""`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days `. The exit code is 2.
- Given `--days 36.5`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days 36.5`. The exit code is 2.
- Given `--pv 1e3`, `--pv .5`, `--pv 5.` or `--pv 5kW`, when the person runs `sim run`, then each gives `BAD_NUMBER` and exit code 2.
- Given `--pv +3`, when the person runs `sim run`, then it exits with 0, and the result equals the result of `--pv 3`.
- Given `--days 0`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 0 (1 to 3650)`. The exit code is 2.
- Given `--days 3651`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 3651 (1 to 3650)`. The exit code is 2.
- Given `--days 99999999999999999999`, when the person runs `sim run`, then it gives `OUT_OF_RANGE` and exit code 2.
- Given `--seed -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)`. The exit code is 2.
- Given `--seed 4294967295`, when the person runs `sim run`, then it exits with 0. `--seed 4294967296` gives `OUT_OF_RANGE`.
- Given `--lat 90` and `--lat -90`, when the person runs `sim run`, then each exits with 0.
- Given `--lat 90.1` and `--lat -90.1`, when the person runs `sim run`, then each gives `OUT_OF_RANGE` and exit code 2.
- Given `--pv 100` and `--pv 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--pv -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --pv -1 (0 to 100)`. The exit code is 2.
- Given `--battery 200` and `--battery 200.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--power 100` and `--power 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 0.1` and `--load 0`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 1000` and `--load 1000.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 10 --flex 10`, when the person runs `sim run`, then it exits with 0.
- Given `--load 10 --flex 10.5`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --flex 10.5 (0 to 10)`. The exit code is 2.
- Given `--strategy wild`, when the person runs `sim run`, then stderr is `error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)`. The exit code is 2.
- Given the extra word `now`, when the person runs `sim run now`, then stderr is `error: UNKNOWN_OPTION: now`. The exit code is 2.
- Given `--days 10 --days 20`, when the person runs `sim run`, then the `days` line shows 20.
- Given each error above, when the person runs the command, then stdout is empty.

## Specs it relies on

### CAP-scenario

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the conditions that a strategy must handle, one hour at a time. It gives
the solar output of each hour from the season and the sun height, and a daily sky from a
seeded weather model. It also gives the household load of each hour, with a seasonal base
load and a flexible load that a strategy can move.

## Code map

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`

## Requirements

### CAP-scenario.R1 · Seasonal sun

Status: verified · Intents: IN-0001

The output of an hour is the panel power, times the sine of the sun height, times the sky
factor (assumed). The sun height uses the latitude, the day of the year, and the middle of
the hour in solar time (assumed).

The declination is 23.44 degrees times sin(2π × (285 + day) / 365), where day 0 is 1 January
(assumed). The sky factor is 1.0 for sunny, 0.5 for cloudy, and 0.15 for overcast (assumed).
When the sun is below the horizon, the output is 0. In these lines, the site has 5 kW of panels,
unless the line says otherwise.

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

Status: verified · Intents: IN-0001

A seed and a number of days give one sky for each day, and the same hours each time. The
scenario starts on 1 January and gives the hours in order of day, then hour.

Each day keeps the sky of the day before with a chance of 0.6 (assumed). Else, the day takes
a new sky from the chances of its half of the year (assumed):

- Summer half: sunny 0.55, cloudy 0.30, overcast 0.15 (assumed).
- Winter half: sunny 0.20, cloudy 0.35, overcast 0.45 (assumed).

The summer half is days 90 to 272 of each year at latitude 0 or more, and the other days at
a negative latitude (assumed). After day 364, the day of the year starts again at 0.

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

Status: verified · Intents: IN-0001

The daily load includes the flexible load. The base load is the daily load less the flexible
load, spread over the hours by a fixed profile (assumed).

The profile has a morning peak and an evening peak (assumed). A seasonal factor of
1 + 0.2 × cos(2π × (day - peak) / 365) scales the base load (assumed). The peak is day 15 at
latitude 0 or more, and day 197 at a negative latitude (assumed).

By default, the flexible load uses equal parts at 18:00, 19:00 and 20:00 (assumed). The load
does not depend on the seed. In these lines, the daily load is 20 kWh with 3 kWh flexible,
unless the line says otherwise.

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.
````

### CAP-strategies

````
# CAP-strategies · Battery and load strategies to compare

Status: active

## What it is for

CAP-strategies (battery and load strategies) holds the rules that the simulation compares.
Each strategy has a name. For each hour, a strategy asks the battery to charge or to
discharge. For each day, a strategy also places the flexible load.

The four strategies are these:

- `none`: no battery use.
- `greedy`: battery use at any hour.
- `evening`: discharge only in the evening.
- `shift`: greedy battery use, and the flexible load in the sunniest hours.

## Code map

- `StoragePolicySim/Strategy.lean`

## Requirements

### CAP-strategies.R1 · Strategy names

Status: verified · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: verified · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: verified · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: verified · Intents: IN-0001

The `evening` strategy charges as `greedy` does. It discharges only from 17:00 to 23:59
(assumed), to keep the stored energy for the evening peak. It keeps the flexible load at its
default hours.

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

Status: verified · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.
````

### CAP-simulation

````
# CAP-simulation · Hourly energy flows and self-consumption results

Status: active

## What it is for

CAP-simulation (hourly energy flows) runs one strategy over a scenario, hour by hour, with
a battery. It gives the energy flows of each hour, the totals, and the totals of each
month. The totals include the self-consumption and the self-sufficiency, so that a caller
can compare strategies on the same weather.

## Code map

- `StoragePolicySim/Simulation.lean`

## Requirements

### CAP-simulation.R1 · Energy flows of an hour

Status: verified · Intents: IN-0001

The house first uses solar energy directly. Then the battery takes what the strategy asks,
up to the surplus, the battery power for one hour, and the free room. The rest goes to
the grid as export.

For a shortfall, the battery gives what the strategy asks, up to the shortfall, the battery
power for one hour, and the stored energy. The rest comes from the grid as import.

The battery keeps 95% of the energy that goes in, and gives 95% of the energy that comes
out (assumed). The battery is empty at the start (assumed). In these lines, the battery
holds 10 kWh with 5 kW of power, unless the line says otherwise.

- Given an empty battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given a full battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export.
- Given 9.05 kWh stored, when `greedy` meets a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery with 2 kW of power, when `greedy` meets a surplus of 3 kWh, then 2 kWh charges and 1 kWh is export.
- Given 1.9 kWh stored, when `greedy` meets a shortfall of 2 kWh, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored, when `none` meets 3 kWh of solar and 1 kWh of load, then 2 kWh is export. The battery still holds 1.9 kWh.
- Given `greedy` and seed 7, when the simulation runs 365 days, then the first hour imports its full load.

### CAP-simulation.R2 · Battery limits

Status: verified · Intents: IN-0001

Over a run, the battery never goes past its power or its capacity. The energy of each run
balances, with the battery losses included. In these lines, the site is at latitude 45
with 5 kW of panels and 20 kWh of daily load, 3 kWh of it flexible. The seed is 7, unless
the line says otherwise.

- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then no hour charges or discharges over 2 kWh.
- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then the battery holds 0 to 5 kWh each hour.
- Given a 10 kWh battery, when `greedy` runs 365 days, then solar plus import equals load, export, losses and the stored energy. The tolerance is 0.01 kWh.
- Given a battery of 0 kWh, when `greedy` and `none` each run 365 days, then the two runs have the same totals.

### CAP-simulation.R3 · Totals and ratios

Status: verified · Intents: IN-0001

The totals add up the hours of the run. The self-consumption is the solar energy less the
export, as a percentage of the solar energy. The self-sufficiency is the load less the
import, as a percentage of the load. A ratio with nothing to divide by is 0% (assumed).

- Given latitude 45 and `none`, when the simulation runs 365 days, then each total equals the sum of its hours. The tolerance is 0.01 kWh.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-consumption is 100 × (solar - export) / solar.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-sufficiency is 100 × (load - import) / load.
- Given 0 kW of panels, when `greedy` runs 365 days, then the self-consumption is 0% and the self-sufficiency is 0%.
- Given 0 days, when `greedy` runs, then each total is 0, each ratio is 0%, and there are no months.

### CAP-simulation.R4 · Monthly totals

Status: verified · Intents: IN-0001

The result has the totals of each calendar month in the run, in order. A year has 365
days, with no leap day (assumed). Each month also has its own two ratios.

- Given 365 days, when `greedy` runs, then the result has 12 months. Their days are 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31.
- Given 365 days, when `greedy` runs, then the solar totals of the 12 months add up to the solar total of the run. The tolerance is 0.01 kWh.
- Given 400 days, when `greedy` runs, then the result has 14 months. The last month is February with 4 days.
- Given 10 days, when `greedy` runs, then the result has one month, January with 10 days.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then July has more than twice the solar energy of December.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then the July self-sufficiency is more than the January self-sufficiency.

### CAP-simulation.R5 · Strategy order

Status: verified · Intents: IN-0001

On the same weather, a battery must raise the self-consumption, and a later discharge must
not raise it. In these lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of
daily load, 3 kWh of it flexible. The seed is 7, and each run is 365 days.

- Given a battery of 10 kWh with 5 kW of power, when `none` and `greedy` run, then `greedy` has the higher self-consumption.
- Given a battery of 10 kWh with 5 kW of power, when `evening` and `greedy` run, then `evening` has a self-consumption no higher than `greedy`.
- Given a battery of 0 kWh, when `none` and `shift` run, then `shift` has the higher self-consumption.
````

### DES-errors

````
# DES-errors · The project's error codes

Status: agreed · Default: yes · Ask at init: no

## Rule

Each error that the system can give has a code here, in `UPPER_SNAKE_CASE`. Acceptance
lines, Interface entries, and checks all use these codes. Thus, a check can expect the
exact error.

| Code | Meaning | Whose fault | Retry helps? |
|---|---|---|---|
| `UNKNOWN_COMMAND` | The first word of the command line is not a command | caller | no |
| `UNKNOWN_OPTION` | An option or a word that the command does not take | caller | no |
| `MISSING_VALUE` | An option that needs a value comes last, with no value | caller | no |
| `BAD_NUMBER` | The value of a number option is not a number of the right form | caller | no |
| `OUT_OF_RANGE` | A number is outside the range of its option | caller | no |
| `UNKNOWN_STRATEGY` | The name of the strategy is not in the list of strategies | caller | no |

When a requirement needs a new error, add a row. When the meaning is the same, use the
existing code again.

Add rows at intake and ready. Do not add a row while a change is in tests, build, or
verify. When you add a row, leave `Default:` as it is. Write each row the same way:

- The code in backticks.
- "Whose fault": `caller`, `system`, or `outside service`.
- "Retry helps?": `yes` or `no`.

Checks and the code of the app match on the error code. Each requirement decides what a
person sees, for example a message or a status. The message or the status can omit the
error code. If the caller cannot see the error code, a check expects the exact message and
status instead.

## Why

A check that expects "an error" passes for any error, also for a typo. A named code makes
the check exact. A named code also gives callers a stable value to handle.
````

### DES-pdlc-check-tagging

````
# DES-pdlc-check-tagging · How checks name their requirement

Status: agreed · Default: yes · Ask at init: yes

## Rule

The requirement ID starts the name of the check, for example `CAP-email.R3 sends from a
template`. A check that proves two requirements names the two requirements.

If the check runner does not accept `.` or `-` in names (Python's `unittest`, for
example), write the ID with underscores instead: `test_CAP_email_R3_sends_from_a_template`.
The two forms count as the same ID. Use only one form in each project.

Lay checks out the same way everywhere:

- Put new check files in the check folder (`tests/` in a project that had none). Name
  each file after the spec it proves, in a form the runner finds: `test_CAP_email.py`,
  `CAP-email.test.js`.
- Inside a file, make one group per requirement (a test class or a `describe` block).
  Name the group with the requirement ID: `class CAP_email_R3(unittest.TestCase)`,
  `describe("CAP-email.R3", ...)`.
- Each check's name still starts with the ID, then says what it proves.

The acceptance checks of an intent go in one file for each intent, at the path of
"acceptance file" in `pdlc/config.md`. The name of the file holds the word "acceptance"
and the intent ID, for example `tests/acceptance_IN_0012.py` or
`acceptance/IN-0012.acceptance.js`. The "all" command does not run such a file. Inside the
file, make one group for each requirement, and start each check name with the requirement
ID.

## Why

The trace from a requirement to its checks is only as good as this naming. Thus, the
naming must be simple and the same everywhere.
````

### DES-lean-checks

````
# DES-lean-checks · How a Lean check file runs and reports

Status: agreed · Default: no

## Rule

Each check file is a Lean script that `lake env lean --run <file> [filter]` runs. The file
has these parts:

- One file for each spec, named after the spec: `tests/CAP-scenario.lean`. The acceptance
  file of an intent is `tests/acceptance/IN-0001.acceptance.lean`.
- The imports of the library modules that the file calls, for example
  `import StoragePolicySim.Scenario`. A check file does not import another check file.
  Thus, each file holds its own small helpers.
- `def main (args : List String) : IO UInt32`.
- Each check has a name that starts with its requirement ID and a space, for example
  `"CAP-scenario.R1 day 171 gives more than twice day 354"`.
- The checks of one requirement are together, under the comment `-- CAP-scenario.R1`.

When `main` gets a first argument, it runs only the checks whose names start with that
argument and a space. Thus, the filter `CAP-scenario.R1` does not run `CAP-scenario.R10`.

The file prints `FAIL <name>: <what went wrong>` for each failed check. Its last line is
`<n> checks, <k> failed`. It exits with 1 when `k` is more than 0, and else with 0. A
filter that matches no check gives `0 checks, 0 failed`. The checks port reads that line
as "no checks found".

A check that runs the `sim` command uses `IO.Process.output` with the command `timeout`
and the arguments `60`, `.lake/build/bin/sim`, and then the arguments of `sim`. The check
reads the exit code, stdout and stderr. A `Float` comparison uses a tolerance.

## Example

```lean
import StoragePolicySim.Scenario
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 night gives no output",
    run := do
      let v := pvOutput site45 171 0 .sunny
      return if v == 0 then none else some s!"got {v}" }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    match ← c.run with
    | none => pure ()
    | some msg => failed := failed + 1; IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
```

The toolchain is Lean 4.35.0. In this version, `String.trim` does not exist. Use
`String.trimAscii` and then `.toString`, or split with `String.splitOn`.

## Why

Lean has no standard check runner. One small form for every file gives each check a name
with its requirement ID. It also gives a filter for one requirement, and one count line for the checks
port.
````

## The checks

### Diff against pdlc/CH-0003-simulation

````
diff --git a/tests/JOB-simulate.lean b/tests/JOB-simulate.lean
new file mode 100644
index 0000000..e8f8c41
--- /dev/null
+++ b/tests/JOB-simulate.lean
@@ -0,0 +1,608 @@
+/-
+Component checks of JOB-simulate (simulate a year of solar and compare strategies), for
+CH-0004 (the sim command).
+
+Each check runs `.lake/build/bin/sim` as a process through `timeout 60`, and reads the exit
+code, stdout and stderr. Some checks also call `simulate` of CH-0003 (simulation), with
+`Site`, `Battery` and `Strategy`, to compare the printed values. The `--seed` option is the
+only seam. No check uses the clock.
+
+Each error code of the Interface has at least one check that expects the exact line:
+UNKNOWN_COMMAND, UNKNOWN_OPTION, MISSING_VALUE, BAD_NUMBER, OUT_OF_RANGE and
+UNKNOWN_STRATEGY.
+
+The defaults of `sim run` are latitude -41.3, 5 kW of panels, 20 kWh of daily load with
+3 kWh flexible, a 10 kWh battery with 5 kW of power, `greedy`, seed 1 and 365 days.
+-/
+import StoragePolicySim.Scenario
+import StoragePolicySim.Strategy
+import StoragePolicySim.Simulation
+open StoragePolicySim
+
+structure Check where
+  name : String
+  run : IO (Option String)   -- none: pass, some msg: fail
+
+-- Helpers for numbers
+
+def near (a b tol : Float) : Bool := (a - b).abs ≤ tol
+
+/-- Rounds to one decimal, half away from zero. -/
+def round1 (x : Float) : Float :=
+  if x < 0 then -(Float.round (-x * 10)) / 10 else Float.round (x * 10) / 10
+
+def firstFail : List (Bool × String) → Option String
+  | [] => none
+  | (true, _) :: rest => firstFail rest
+  | (false, m) :: _ => some m
+
+def digitsVal (cs : List Char) : Nat :=
+  cs.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0
+
+/-- Reads a printed number: an optional minus, digits, and an optional point with digits. -/
+def parseNum (s : String) : Option Float :=
+  let p : Bool × List Char := match s.toList with
+    | '-' :: r => (true, r)
+    | r => (false, r)
+  let cs := p.2
+  let ip := cs.takeWhile Char.isDigit
+  let rest := cs.dropWhile Char.isDigit
+  let q : List Char × List Char := match rest with
+    | '.' :: r => (r.takeWhile Char.isDigit, r.dropWhile Char.isDigit)
+    | r => ([], r)
+  if ip.isEmpty || !q.2.isEmpty then none
+  else
+    let v := Float.ofNat (digitsVal ip) + Float.ofScientific (digitsVal q.1) true q.1.length
+    some (if p.1 then -v else v)
+
+-- Helpers for the library
+
+def site (lat : Float := -41.3) (pv : Float := 5) (load : Float := 20) (flex : Float := 3) :
+    Site :=
+  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }
+
+def bat (cap : Float := 10) (power : Float := 5) : Battery :=
+  { capacityKwh := cap, powerKw := power }
+
+def monthNames : List String :=
+  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
+
+-- Helpers for the `sim` process
+
+structure RunOut where
+  code : UInt32
+  out : String
+  err : String
+
+def sim (args : List String) : IO RunOut := do
+  let r ← IO.Process.output
+    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
+  return { code := r.exitCode, out := r.stdout, err := r.stderr }
+
+def lines (s : String) : List String :=
+  let ls := s.splitOn "\n"
+  if ls.getLast? == some "" then ls.dropLast else ls
+
+def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")
+
+/-- A line of `sim run`: the label, spaces to fill 18 characters, and the value. -/
+def row (label value : String) : String :=
+  label ++ "".pushn ' ' (18 - label.length) ++ value
+
+def runLabels : List String :=
+  ["strategy", "days", "seed", "solar", "load", "self-used", "import", "export", "losses",
+   "self-consumption", "self-sufficiency"]
+
+def monthHeader : String :=
+  "month solar-kWh load-kWh import-kWh export-kWh self-consumption-% self-sufficiency-%"
+
+def compareHeader : String :=
+  "strategy self-consumption-% self-sufficiency-% import-kWh export-kWh"
+
+def usage : String := "usage: sim run [options] | sim compare [options]"
+
+def firstWords (out : String) : List String :=
+  (lines out).map (fun l => (words l).head?.getD "")
+
+def valueOf (out label : String) : Option String :=
+  match (lines out).find? (fun l => (words l).head? == some label) with
+  | some l => (words l)[1]?
+  | none => none
+
+def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum
+
+def showsNum (s : Option String) (x : Float) : Bool :=
+  match s.bind parseNum with
+  | some v => near v (round1 x) 0.001
+  | none => false
+
+def totalsPairs (t : Totals) : List (String × Float) :=
+  [("solar", t.pvKwh), ("load", t.loadKwh), ("self-used", t.selfUsedKwh),
+   ("import", t.importKwh), ("export", t.exportKwh), ("losses", t.lossKwh),
+   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]
+
+/-- Compares each value line of `sim run` with the totals of the simulation. -/
+def checkShows (out : String) (t : Totals) : Option String :=
+  match (totalsPairs t).find? (fun (l, x) => !showsNum (valueOf out l) x) with
+  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
+  | none => none
+
+def rowShows (r : String) (m : Month) : Bool :=
+  let w := words r
+  w.length == 7 && w[0]? == some m.name &&
+  showsNum w[1]? m.totals.pvKwh && showsNum w[2]? m.totals.loadKwh &&
+  showsNum w[3]? m.totals.importKwh && showsNum w[4]? m.totals.exportKwh &&
+  showsNum w[5]? m.totals.selfConsumption && showsNum w[6]? m.totals.selfSufficiency
+
+/-- The row of `sim compare` for a strategy, split into words. -/
+def compareRow (out name : String) : Option (List String) :=
+  ((lines out).find? (fun l => (words l).head? == some name)).map words
+
+def compareShows (out : String) (s : Strategy) (t : Totals) : Bool :=
+  match compareRow out s.name with
+  | some w =>
+    w.length == 5 && showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
+    showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh
+  | none => false
+
+def oneDecimal (v : String) : Bool :=
+  match v.splitOn "." with
+  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
+  | _ => false
+
+/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
+def labelled (l label : String) : Bool :=
+  let cs := l.toList
+  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '
+
+/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
+def expectError (args : List String) (line : String) : IO (Option String) := do
+  let r ← sim args
+  return firstFail [
+    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
+    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
+    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]
+
+/-- Expects exit code 2, empty stdout, and stderr that starts with `pre`. -/
+def expectStart (args : List String) (pre : String) : IO (Option String) := do
+  let r ← sim args
+  return firstFail [
+    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
+    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
+    (r.err.startsWith pre, s!"sim {args}: stderr is {repr r.err}, want a start of {repr pre}")]
+
+/-- Expects exit code 0, empty stderr, and the 11 lines of `sim run`. -/
+def expectRun (args : List String) : IO (Option String) := do
+  let r ← sim args
+  return firstFail [
+    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
+    (r.err == "", s!"sim {args}: stderr is {repr r.err}"),
+    (firstWords r.out == runLabels, s!"sim {args}: stdout is {repr r.out}")]
+
+/-- Runs the expectations in order and gives the first failure. -/
+def allOf : List (IO (Option String)) → IO (Option String)
+  | [] => pure none
+  | c :: rest => do
+    match ← c with
+    | some m => return some m
+    | none => allOf rest
+
+/-- Each value of `ok` is accepted. Each pair of `bad` gives its exact error line. -/
+def rangeOf (opt : String) (ok : List String) (bad : List (String × String)) :
+    IO (Option String) :=
+  allOf (ok.map (fun v => expectRun ["run", opt, v]) ++
+    bad.map (fun p => expectError ["run", opt, p.1] p.2))
+
+def checks : List Check := [
+  -- JOB-simulate.R1
+  { name := "JOB-simulate.R1 sim run prints the 11 lines in order and exits with 0",
+    run := do
+      let r ← sim ["run"]
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        (r.err == "", s!"stderr is {repr r.err}"),
+        ((lines r.out).length == 11, s!"{(lines r.out).length} lines"),
+        (firstWords r.out == runLabels, s!"stdout is {repr r.out}")] },
+  { name := "JOB-simulate.R1 each line has its label to column 19 and a value of the right form",
+    run := do
+      let r ← sim ["run"]
+      let ls := lines r.out
+      let bad := (List.range 11).find? (fun i =>
+        let l := ls.getD i ""
+        let w := words l
+        !(labelled l (runLabels.getD i "") &&
+          (if i < 3 then w.length == 2
+           else if i < 9 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
+           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
+      return if r.code != 0 || ls.length != 11 then some s!"stdout is {repr r.out}"
+        else match bad with
+          | some i => some s!"the line {repr (ls.getD i "")} has the wrong form"
+          | none => none },
+  { name := "JOB-simulate.R1 the first three lines show greedy, 365 days and seed 1",
+    run := do
+      let r ← sim ["run"]
+      let want := [row "strategy" "greedy", row "days" "365", row "seed" "1"]
+      return if r.code == 0 && (lines r.out).take 3 == want then none
+        else some s!"stdout is {repr r.out}" },
+  { name := "JOB-simulate.R1 --pv 0 shows 0.0 kWh of solar and 0.0 % self-consumption",
+    run := do
+      let r ← sim ["run", "--pv", "0"]
+      let ls := lines r.out
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        (ls[3]? == some (row "solar" "0.0 kWh"), s!"the solar line is {ls[3]?}"),
+        (ls[9]? == some (row "self-consumption" "0.0 %"), s!"the line is {ls[9]?}")] },
+  { name := "JOB-simulate.R1 --strategy shift --days 30 --lat 45 shows the values of the simulation",
+    run := do
+      let r ← sim ["run", "--strategy", "shift", "--days", "30", "--lat", "45"]
+      let t := (simulate (site (lat := 45)) (bat) Strategy.shift 1 30).totals
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        ((lines r.out).take 3 == [row "strategy" "shift", row "days" "30", row "seed" "1"],
+          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
+  { name := "JOB-simulate.R1 the defaults give the values of the simulation",
+    run := do
+      let r ← sim ["run"]
+      let t := (simulate (site) (bat) Strategy.greedy 1 365).totals
+      return (if r.code == 0 then none else some s!"exit code {r.code}") <|> checkShows r.out t },
+  -- Each option has a value that differs from its default. Thus, a version that swaps two
+  -- options, for example --battery and --power, fails here.
+  { name := "JOB-simulate.R1 each option goes to its own part of the simulation",
+    run := do
+      let r ← sim ["run", "--strategy", "evening", "--days", "40", "--seed", "3", "--lat", "30",
+        "--pv", "7.5", "--battery", "4", "--power", "2", "--load", "15", "--flex", "1.5"]
+      let t := (simulate (site 30 7.5 15 1.5) (bat 4 2) Strategy.evening 3 40).totals
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        ((lines r.out).take 3 == [row "strategy" "evening", row "days" "40", row "seed" "3"],
+          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
+  -- A version that keeps --flex at 3 with --load 2 fails the first run. A version that sets
+  -- --flex to the --load value with --load 4 fails the second run.
+  { name := "JOB-simulate.R1 the --flex default is 3, or the --load value when that is less",
+    run := do
+      let a ← sim ["run", "--load", "2", "--lat", "45"]
+      let b ← sim ["run", "--load", "4", "--lat", "45"]
+      let ta := (simulate (site 45 5 2 2) (bat) Strategy.greedy 1 365).totals
+      let tb := (simulate (site 45 5 4 3) (bat) Strategy.greedy 1 365).totals
+      return firstFail [
+        (a.code == 0, s!"--load 2: exit code {a.code}, stderr {repr a.err}"),
+        (b.code == 0, s!"--load 4: exit code {b.code}, stderr {repr b.err}")] <|>
+        (checkShows a.out ta).map (s!"--load 2: " ++ ·) <|>
+        (checkShows b.out tb).map (s!"--load 4: " ++ ·) },
+  { name := "JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used",
+    run := do
+      let r ← sim ["run", "--strategy", "none", "--battery", "0"]
+      return match numOf r.out "solar", numOf r.out "self-used", numOf r.out "export" with
+        | some s, some u, some e =>
+          if r.code == 0 && s > 0 && e > 0 && near e (s - u) 0.1 then none
+          else some s!"solar {s}, self-used {u}, export {e}"
+        | _, _, _ => some s!"stdout is {repr r.out}" },
+  { name := "JOB-simulate.R1 --days 3650 exits with 0 and shows 3650 days",
+    run := do
+      let r ← sim ["run", "--days", "3650"]
+      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "3650") then none
+        else some s!"exit code {r.code}, stdout {repr r.out}" },
+
+  -- JOB-simulate.R2
+  { name := "JOB-simulate.R2 --monthly prints the 11 lines, a blank line, the header and 12 rows from Jan to Dec",
+    run := do
+      let r ← sim ["run", "--monthly"]
+      let ls := lines r.out
+      let rows := ls.drop 13
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        (ls.length == 25, s!"{ls.length} lines, want 25"),
+        ((ls.take 11).map (fun l => (words l).head?.getD "") == runLabels, "the 11 lines are wrong"),
+        (ls[11]? == some "", s!"line 12 is {ls[11]?}, want blank"),
+        (Option.map words ls[12]? == some (words monthHeader), s!"the header is {ls[12]?}"),
+        (rows.map (fun l => (words l).head?.getD "") == monthNames, s!"rows {rows}"),
+        (rows.all (fun l => (words l).length == 7), "a row does not have seven fields")] },
+  { name := "JOB-simulate.R2 each row shows the totals of its month",
+    run := do
+      let r ← sim ["run", "--monthly", "--lat", "45", "--seed", "4"]
+      let ms := (simulate (site (lat := 45)) (bat) Strategy.greedy 4 365).months
+      let rows := (lines r.out).drop 13
+      return if r.code == 0 && rows.length == ms.size && ms.size == 12 &&
+          (rows.zip ms.toList).all (fun (l, m) => rowShows l m) then none
+        else some s!"rows {rows}" },
+  { name := "JOB-simulate.R2 --monthly --days 400 prints 14 rows that end with Jan and Feb",
+    run := do
+      let r ← sim ["run", "--monthly", "--days", "400"]
+      let ms := (simulate (site) (bat) Strategy.greedy 1 400).months
+      let rows := (lines r.out).drop 13
+      let names := rows.map (fun l => (words l).head?.getD "")
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        (rows.length == 14 && names.drop 12 == ["Jan", "Feb"], s!"rows {names}"),
+        (ms.size == 14 && (rows.zip ms.toList).all (fun (l, m) => rowShows l m),
+          s!"the rows do not show the months of the simulation: {rows}")] },
+  { name := "JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul",
+    run := do
+      let r ← sim ["run", "--monthly", "--lat", "45"]
+      let rows := (lines r.out).drop 13
+      let solar := fun (n : String) =>
+        (rows.find? (fun l => (words l).head? == some n)).bind (fun l => (words l)[1]?.bind parseNum)
+      return match solar "Jul", solar "Dec" with
+        | some j, some d => if r.code == 0 && d > 0 && j > 2 * d then none else some s!"Jul {j}, Dec {d}"
+        | _, _ => some s!"stdout is {repr r.out}" },
+  { name := "JOB-simulate.R2 without --monthly sim run prints only the 11 lines",
+    run := do
+      let r ← sim ["run", "--lat", "45"]
+      return if r.code == 0 && (lines r.out).length == 11 && firstWords r.out == runLabels
+        then none else some s!"stdout is {repr r.out}" },
+  { name := "JOB-simulate.R2 the 11 lines of --monthly are the lines of sim run",
+    run := do
+      let a ← sim ["run", "--lat", "45", "--monthly"]
+      let b ← sim ["run", "--lat", "45"]
+      return if a.code == 0 && b.code == 0 && (lines a.out).take 11 == lines b.out then none
+        else some s!"--monthly {repr a.out}, without {repr b.out}" },
+
+  -- JOB-simulate.R3
+  { name := "JOB-simulate.R3 sim compare prints the header and none, greedy, evening and shift",
+    run := do
+      let r ← sim ["compare"]
+      let ls := lines r.out
+      return firstFail [
+        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
+        (ls.length == 5, s!"{ls.length} lines, want 5"),
+        (Option.map words ls[0]? == some (words compareHeader), s!"the header is {ls[0]?}"),
+        (firstWords r.out == ["strategy", "none", "greedy", "evening", "shift"],
+          s!"stdout is {repr r.out}"),
+        ((ls.drop 1).all (fun l => (words l).length == 5), "a row does not have five fields")] },
+  { name := "JOB-simulate.R3 the greedy row of --seed 9 --lat 45 shows the four values of sim run",
+    run := do
+      let c ← sim ["compare", "--seed", "9", "--lat", "45"]
+      let r ← sim ["run", "--seed", "9", "--lat", "45"]
+      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
+        valueOf r.out "import", valueOf r.out "export"]
+      return match compareRow c.out "greedy" with
+        | some w =>
+          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
+              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?] then none
+          else some s!"compare {w}, run {fromRun}"
+        | none => some s!"no greedy row in {repr c.out}" },
+  -- The options differ from the defaults. Thus, a version that ignores an option in
+  -- sim compare fails here.
+  { name := "JOB-simulate.R3 each row of sim compare shows the values of the simulation",
+    run := do
+      let c ← sim ["compare", "--seed", "9", "--lat", "45", "--battery", "4", "--load", "15",
+        "--days", "100"]
+      let bad := Strategy.all.find? (fun s =>
+        !compareShows c.out s (simulate (site 45 5 15 3) (bat 4 5) s 9 100).totals)
+      return if c.code != 0 then some s!"exit code {c.code}, stderr {repr c.err}"
+        else match bad with
+          | some s => some s!"the {s.name} row is wrong in {repr c.out}"
+          | none => none },
+  { name := "JOB-simulate.R3 --lat 45 gives greedy a higher self-consumption than none",
+    run := do
+      let c ← sim ["compare", "--lat", "45"]
+      let sc := fun (n : String) => (compareRow c.out n).bind (fun w => w[1]?.bind parseNum)
+      return match sc "greedy", sc "none" with
+        | some g, some n => if c.code == 0 && g > n then none else some s!"greedy {g}, none {n}"
+        | _, _ => some s!"stdout is {repr c.out}" },
+  { name := "JOB-simulate.R3 sim compare --strategy greedy gives UNKNOWN_OPTION",
+    run := expectError ["compare", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
+  { name := "JOB-simulate.R3 sim compare --monthly gives UNKNOWN_OPTION",
+    run := expectError ["compare", "--monthly"] "error: UNKNOWN_OPTION: --monthly" },
+
+  -- JOB-simulate.R4
+  { name := "JOB-simulate.R4 --seed 5 gives the same output two times",
+    run := do
+      let a ← sim ["run", "--seed", "5"]
+      let b ← sim ["run", "--seed", "5"]
+      let c ← sim ["compare", "--seed", "5"]
+      let d ← sim ["compare", "--seed", "5"]
+      return firstFail [
+        (a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11,
+          s!"sim run: first {repr a.out}, second {repr b.out}"),
+        (c.code == 0 && d.code == 0 && c.out == d.out && (lines c.out).length == 5,
+          s!"sim compare: first {repr c.out}, second {repr d.out}")] },
+  { name := "JOB-simulate.R4 --seed 1 and --seed 2 give different solar values",
+    run := do
+      let a ← sim ["run", "--seed", "1"]
+      let b ← sim ["run", "--seed", "2"]
+      let sa := valueOf a.out "solar"
+      let sb := valueOf b.out "solar"
+      return if a.code == 0 && b.code == 0 && sa.isSome && sb.isSome && sa != sb then none
+        else some s!"seed 1 {sa}, seed 2 {sb}" },
+  { name := "JOB-simulate.R4 --seed 2 gives the solar of the simulation with seed 2",
+    run := do
+      let r ← sim ["run", "--seed", "2"]
+      let t := (simulate (site) (bat) Strategy.greedy 2 365).totals
+      return if r.code == 0 && showsNum (valueOf r.out "solar") t.pvKwh then none
+        else some s!"solar {valueOf r.out "solar"}, want {round1 t.pvKwh}" },
+
+  -- JOB-simulate.R5
+  { name := "JOB-simulate.R5 sim with no arguments prints the usage and exits with 0",
+    run := do
+      let r ← sim []
+      return if r.code == 0 && (lines r.out).head? == some usage && r.err == "" then none
+        else some s!"exit code {r.code}, stdout {repr r.out}" },
+  { name := "JOB-simulate.R5 sim help and sim --help print the same usage and exit with 0",
+    run := do
+      let a ← sim []
+      let h ← sim ["help"]
+      let d ← sim ["--help"]
+      return firstFail [
+        (h.code == 0 && (lines h.out).head? == some usage && h.out == a.out,
+          s!"sim help: exit code {h.code}, stdout {repr h.out}"),
+        (d.code == 0 && (lines d.out).head? == some usage && d.out == a.out,
+          s!"sim --help: exit code {d.code}, stdout {repr d.out}")] },
+  { name := "JOB-simulate.R5 sim fly gives UNKNOWN_COMMAND",
+    run := expectError ["fly"] "error: UNKNOWN_COMMAND: fly" },
+  { name := "JOB-simulate.R5 a command word that differs by its case or a space gives UNKNOWN_COMMAND",
+    run := allOf [
+      expectError ["Run"] "error: UNKNOWN_COMMAND: Run",
+      expectError ["run "] "error: UNKNOWN_COMMAND: run ",
+      expectError ["Compare"] "error: UNKNOWN_COMMAND: Compare"] },
+  { name := "JOB-simulate.R5 --colour red gives UNKNOWN_OPTION",
+    run := expectError ["run", "--colour", "red"] "error: UNKNOWN_OPTION: --colour" },
+  { name := "JOB-simulate.R5 an option that differs by its case, a dash or an equals sign gives UNKNOWN_OPTION",
+    run := allOf [
+      expectError ["run", "--Days", "5"] "error: UNKNOWN_OPTION: --Days",
+      expectError ["run", "-days", "5"] "error: UNKNOWN_OPTION: -days",
+      expectError ["run", "--days=5"] "error: UNKNOWN_OPTION: --days=5"] },
+  { name := "JOB-simulate.R5 sim run now gives UNKNOWN_OPTION",
+    run := expectError ["run", "now"] "error: UNKNOWN_OPTION: now" },
+  { name := "JOB-simulate.R5 --days with no value gives MISSING_VALUE",
+    run := expectError ["run", "--days"] "error: MISSING_VALUE: --days" },
+  { name := "JOB-simulate.R5 --strategy and --flex with no value give MISSING_VALUE",
+    run := allOf [
+      expectError ["run", "--strategy"] "error: MISSING_VALUE: --strategy",
+      expectError ["run", "--days", "5", "--flex"] "error: MISSING_VALUE: --flex"] },
+  { name := "JOB-simulate.R5 --days abc gives BAD_NUMBER",
+    run := expectError ["run", "--days", "abc"] "error: BAD_NUMBER: --days abc" },
+  { name := "JOB-simulate.R5 an empty --days gives BAD_NUMBER",
+    run := expectError ["run", "--days", ""] "error: BAD_NUMBER: --days " },
+  { name := "JOB-simulate.R5 --days 36.5 gives BAD_NUMBER",
+    run := expectError ["run", "--days", "36.5"] "error: BAD_NUMBER: --days 36.5" },
+  { name := "JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER",
+    run := allOf [
+      expectError ["run", "--days", "2.0"] "error: BAD_NUMBER: --days 2.0",
+      expectError ["run", "--days", " 2"] "error: BAD_NUMBER: --days  2",
+      expectStart ["run", "--days", "2\n"] "error: BAD_NUMBER: --days 2\n",
+      expectError ["run", "--seed", "1.5"] "error: BAD_NUMBER: --seed 1.5"] },
+  { name := "JOB-simulate.R5 --days +2 is a whole number with a sign",
+    run := do
+      let r ← sim ["run", "--days", "+2"]
+      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "2") then none
+        else some s!"exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}" },
+  { name := "JOB-simulate.R5 --pv 1e3, .5, 5. and 5kW give BAD_NUMBER",
+    run := allOf [
+      expectError ["run", "--pv", "1e3"] "error: BAD_NUMBER: --pv 1e3",
+      expectError ["run", "--pv", ".5"] "error: BAD_NUMBER: --pv .5",
+      expectError ["run", "--pv", "5."] "error: BAD_NUMBER: --pv 5.",
+      expectError ["run", "--pv", "5kW"] "error: BAD_NUMBER: --pv 5kW"] },
+  { name := "JOB-simulate.R5 a number with a trailing space, a lone sign or a misplaced sign gives BAD_NUMBER",
+    run := allOf [
+      expectError ["run", "--pv", "3 "] "error: BAD_NUMBER: --pv 3 ",
+      expectError ["run", "--lat", "-"] "error: BAD_NUMBER: --lat -",
+      expectError ["run", "--lat", "5-"] "error: BAD_NUMBER: --lat 5-",
+      expectError ["run", "--load", "+-5"] "error: BAD_NUMBER: --load +-5"] },
+  { name := "JOB-simulate.R5 --pv +3 gives the result of --pv 3",
+    run := do
+      let a ← sim ["run", "--pv", "+3"]
+      let b ← sim ["run", "--pv", "3"]
+      let d ← sim ["run"]
+      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11 &&
+          valueOf a.out "solar" != valueOf d.out "solar" then none
+        else some s!"+3 {repr a.out}, 3 {repr b.out}" },
+  { name := "JOB-simulate.R5 --days 0 gives OUT_OF_RANGE",
+    run := expectError ["run", "--days", "0"] "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
+  { name := "JOB-simulate.R5 --days 3651 gives OUT_OF_RANGE",
+    run := expectError ["run", "--days", "3651"] "error: OUT_OF_RANGE: --days 3651 (1 to 3650)" },
+  { name := "JOB-simulate.R5 --days 1 and --days 3650 are accepted",
+    run := rangeOf "--days" ["1", "3650"] [] },
+  { name := "JOB-simulate.R5 --days 99999999999999999999 gives OUT_OF_RANGE",
+    run := expectError ["run", "--days", "99999999999999999999"]
+      "error: OUT_OF_RANGE: --days 99999999999999999999 (1 to 3650)" },
+  { name := "JOB-simulate.R5 --seed -1 gives OUT_OF_RANGE",
+    run := expectError ["run", "--seed", "-1"] "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)" },
+  { name := "JOB-simulate.R5 --seed 0 and 4294967295 are accepted, and 4294967296 gives OUT_OF_RANGE",
+    run := rangeOf "--seed" ["0", "4294967295"]
+      [("4294967296", "error: OUT_OF_RANGE: --seed 4294967296 (0 to 4294967295)"),
+       ("99999999999999999999", "error: OUT_OF_RANGE: --seed 99999999999999999999 (0 to 4294967295)")] },
+  { name := "JOB-simulate.R5 --lat 90 and -90 are accepted, and 90.1 and -90.1 give OUT_OF_RANGE",
+    run := rangeOf "--lat" ["90", "-90"]
+      [("90.1", "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)"),
+       ("-90.1", "error: OUT_OF_RANGE: --lat -90.1 (-90 to 90)")] },
+  { name := "JOB-simulate.R5 --pv 0 and 100 are accepted, and 100.1 and -1 give OUT_OF_RANGE",
+    run := rangeOf "--pv" ["0", "100"]
+      [("100.1", "error: OUT_OF_RANGE: --pv 100.1 (0 to 100)"),
+       ("-1", "error: OUT_OF_RANGE: --pv -1 (0 to 100)")] },
+  { name := "JOB-simulate.R5 --battery 0 and 200 are accepted, and 200.1 and -0.1 give OUT_OF_RANGE",
+    run := rangeOf "--battery" ["0", "200"]
+      [("200.1", "error: OUT_OF_RANGE: --battery 200.1 (0 to 200)"),
+       ("-0.1", "error: OUT_OF_RANGE: --battery -0.1 (0 to 200)")] },
+  { name := "JOB-simulate.R5 --power 0 and 100 are accepted, and 100.1 gives OUT_OF_RANGE",
+    run := rangeOf "--power" ["0", "100"]
+      [("100.1", "error: OUT_OF_RANGE: --power 100.1 (0 to 100)")] },
+  -- With --load 0.1 and no --flex, the --flex default is 0.1, the --load value.
+  { name := "JOB-simulate.R5 --load 0.1 and 1000 are accepted, and 0 and 1000.1 give OUT_OF_RANGE",
+    run := rangeOf "--load" ["0.1", "1000"]
+      [("0", "error: OUT_OF_RANGE: --load 0 (0.1 to 1000)"),
+       ("1000.1", "error: OUT_OF_RANGE: --load 1000.1 (0.1 to 1000)")] },
+  { name := "JOB-simulate.R5 --load 10 --flex 10 is accepted",
+    run := allOf [
+      expectRun ["run", "--load", "10", "--flex", "10"],
+      expectRun ["run", "--load", "10", "--flex", "0"]] },
+  { name := "JOB-simulate.R5 --load 10 --flex 10.5 gives OUT_OF_RANGE",
+    run := expectError ["run", "--load", "10", "--flex", "10.5"]
+      "error: OUT_OF_RANGE: --flex 10.5 (0 to 10)" },
+  { name := "JOB-simulate.R5 --flex -1 gives OUT_OF_RANGE",
+    run := expectError ["run", "--load", "20", "--flex", "-1"]
+      "error: OUT_OF_RANGE: --flex -1 (0 to 20)" },
+  { name := "JOB-simulate.R5 the --flex range shows the last --load value as typed",
+    run := allOf [
+      expectError ["run", "--load", "10.0", "--flex", "10.5"]
+        "error: OUT_OF_RANGE: --flex 10.5 (0 to 10.0)",
+      expectError ["run", "--load", "10", "--load", "+2", "--flex", "3"]
+        "error: OUT_OF_RANGE: --flex 3 (0 to +2)"] },
+  { name := "JOB-simulate.R5 --strategy wild gives UNKNOWN_STRATEGY",
+    run := expectError ["run", "--strategy", "wild"]
+      "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)" },
+  { name := "JOB-simulate.R5 a strategy name that differs by its case or a space gives UNKNOWN_STRATEGY",
+    run := allOf [
+      expectError ["run", "--strategy", "Greedy"]
+        "error: UNKNOWN_STRATEGY: Greedy (none, greedy, evening, shift)",
+      expectError ["run", "--strategy", "shift "]
+        "error: UNKNOWN_STRATEGY: shift  (none, greedy, evening, shift)",
+      expectError ["run", "--strategy", ""]
+        "error: UNKNOWN_STRATEGY:  (none, greedy, evening, shift)"] },
+  { name := "JOB-simulate.R5 each strategy name is accepted",
+    run := allOf (Strategy.all.map (fun s => do
+      let r ← sim ["run", "--strategy", s.name]
+      return if r.code == 0 && (lines r.out).head? == some (row "strategy" s.name) then none
+        else some s!"--strategy {s.name}: exit code {r.code}, stdout {repr r.out}")) },
+  { name := "JOB-simulate.R5 --days 10 --days 20 shows 20 days",
+    run := do
+      let r ← sim ["run", "--days", "10", "--days", "20"]
+      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
+        else some s!"exit code {r.code}, stdout {repr r.out}" },
+  { name := "JOB-simulate.R5 the last value counts before the range is read",
+    run := do
+      let r ← sim ["run", "--days", "0", "--days", "20"]
+      let e ← expectError ["run", "--days", "20", "--days", "0"]
+        "error: OUT_OF_RANGE: --days 0 (1 to 3650)"
+      return (if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
+        else some s!"--days 0 --days 20: exit code {r.code}, stderr {repr r.err}") <|> e },
+  { name := "JOB-simulate.R5 the command word comes before each option",
+    run := expectError ["fly", "--colour", "red"] "error: UNKNOWN_COMMAND: fly" },
+  { name := "JOB-simulate.R5 the options are read from left to right and the first problem gives the error",
+    run := allOf [
+      expectError ["run", "--colour", "red", "--days", "abc"] "error: UNKNOWN_OPTION: --colour",
+      expectError ["run", "--days", "abc", "--colour", "red"] "error: BAD_NUMBER: --days abc",
+      expectError ["run", "--strategy", "wild", "--pv", "x"]
+        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
+      expectError ["run", "--pv", "x", "--days"] "error: BAD_NUMBER: --pv x"] },
+  { name := "JOB-simulate.R5 a bad number or strategy comes before a range problem",
+    run := allOf [
+      expectError ["run", "--days", "0", "--pv", "x"] "error: BAD_NUMBER: --pv x",
+      expectError ["run", "--days", "0", "--strategy", "wild"]
+        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
+      expectError ["run", "--days", "0", "--colour"] "error: UNKNOWN_OPTION: --colour"] },
+  { name := "JOB-simulate.R5 a range problem comes before the --flex check",
+    run := expectError ["run", "--load", "2", "--flex", "5", "--days", "0"]
+      "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
+  { name := "JOB-simulate.R5 an error of sim compare gives the same line as an error of sim run",
+    run := allOf [
+      expectError ["compare", "--days", "abc"] "error: BAD_NUMBER: --days abc",
+      expectError ["compare", "--lat", "91"] "error: OUT_OF_RANGE: --lat 91 (-90 to 90)",
+      expectError ["compare", "--seed"] "error: MISSING_VALUE: --seed",
+      expectError ["compare", "now"] "error: UNKNOWN_OPTION: now"] }
+]
+
+def main (args : List String) : IO UInt32 := do
+  let sel := match args with
+    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
+    | [] => checks
+  let mut failed := 0
+  for c in sel do
+    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
+    match res with
+    | none => pure ()
+    | some msg =>
+      failed := failed + 1
+      IO.println s!"FAIL {c.name}: {msg}"
+  IO.println s!"{sel.length} checks, {failed} failed"
+  return if failed > 0 then 1 else 0
````

### tests/JOB-simulate.lean

````
/-
Component checks of JOB-simulate (simulate a year of solar and compare strategies), for
CH-0004 (the sim command).

Each check runs `.lake/build/bin/sim` as a process through `timeout 60`, and reads the exit
code, stdout and stderr. Some checks also call `simulate` of CH-0003 (simulation), with
`Site`, `Battery` and `Strategy`, to compare the printed values. The `--seed` option is the
only seam. No check uses the clock.

Each error code of the Interface has at least one check that expects the exact line:
UNKNOWN_COMMAND, UNKNOWN_OPTION, MISSING_VALUE, BAD_NUMBER, OUT_OF_RANGE and
UNKNOWN_STRATEGY.

The defaults of `sim run` are latitude -41.3, 5 kW of panels, 20 kWh of daily load with
3 kWh flexible, a 10 kWh battery with 5 kW of power, `greedy`, seed 1 and 365 days.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- Rounds to one decimal, half away from zero. -/
def round1 (x : Float) : Float :=
  if x < 0 then -(Float.round (-x * 10)) / 10 else Float.round (x * 10) / 10

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def digitsVal (cs : List Char) : Nat :=
  cs.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads a printed number: an optional minus, digits, and an optional point with digits. -/
def parseNum (s : String) : Option Float :=
  let p : Bool × List Char := match s.toList with
    | '-' :: r => (true, r)
    | r => (false, r)
  let cs := p.2
  let ip := cs.takeWhile Char.isDigit
  let rest := cs.dropWhile Char.isDigit
  let q : List Char × List Char := match rest with
    | '.' :: r => (r.takeWhile Char.isDigit, r.dropWhile Char.isDigit)
    | r => ([], r)
  if ip.isEmpty || !q.2.isEmpty then none
  else
    let v := Float.ofNat (digitsVal ip) + Float.ofScientific (digitsVal q.1) true q.1.length
    some (if p.1 then -v else v)

-- Helpers for the library

def site (lat : Float := -41.3) (pv : Float := 5) (load : Float := 20) (flex : Float := 3) :
    Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }

def bat (cap : Float := 10) (power : Float := 5) : Battery :=
  { capacityKwh := cap, powerKw := power }

def monthNames : List String :=
  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

-- Helpers for the `sim` process

structure RunOut where
  code : UInt32
  out : String
  err : String

def sim (args : List String) : IO RunOut := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

def lines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")

/-- A line of `sim run`: the label, spaces to fill 18 characters, and the value. -/
def row (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

def runLabels : List String :=
  ["strategy", "days", "seed", "solar", "load", "self-used", "import", "export", "losses",
   "self-consumption", "self-sufficiency"]

def monthHeader : String :=
  "month solar-kWh load-kWh import-kWh export-kWh self-consumption-% self-sufficiency-%"

def compareHeader : String :=
  "strategy self-consumption-% self-sufficiency-% import-kWh export-kWh"

def usage : String := "usage: sim run [options] | sim compare [options]"

def firstWords (out : String) : List String :=
  (lines out).map (fun l => (words l).head?.getD "")

def valueOf (out label : String) : Option String :=
  match (lines out).find? (fun l => (words l).head? == some label) with
  | some l => (words l)[1]?
  | none => none

def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum

def showsNum (s : Option String) (x : Float) : Bool :=
  match s.bind parseNum with
  | some v => near v (round1 x) 0.001
  | none => false

def totalsPairs (t : Totals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("self-used", t.selfUsedKwh),
   ("import", t.importKwh), ("export", t.exportKwh), ("losses", t.lossKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

/-- Compares each value line of `sim run` with the totals of the simulation. -/
def checkShows (out : String) (t : Totals) : Option String :=
  match (totalsPairs t).find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

def rowShows (r : String) (m : Month) : Bool :=
  let w := words r
  w.length == 7 && w[0]? == some m.name &&
  showsNum w[1]? m.totals.pvKwh && showsNum w[2]? m.totals.loadKwh &&
  showsNum w[3]? m.totals.importKwh && showsNum w[4]? m.totals.exportKwh &&
  showsNum w[5]? m.totals.selfConsumption && showsNum w[6]? m.totals.selfSufficiency

/-- The row of `sim compare` for a strategy, split into words. -/
def compareRow (out name : String) : Option (List String) :=
  ((lines out).find? (fun l => (words l).head? == some name)).map words

def compareShows (out : String) (s : Strategy) (t : Totals) : Bool :=
  match compareRow out s.name with
  | some w =>
    w.length == 5 && showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
    showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh
  | none => false

def oneDecimal (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
  | _ => false

/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
def labelled (l label : String) : Bool :=
  let cs := l.toList
  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '

/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
def expectError (args : List String) (line : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]

/-- Expects exit code 2, empty stdout, and stderr that starts with `pre`. -/
def expectStart (args : List String) (pre : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (r.err.startsWith pre, s!"sim {args}: stderr is {repr r.err}, want a start of {repr pre}")]

/-- Expects exit code 0, empty stderr, and the 11 lines of `sim run`. -/
def expectRun (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (r.err == "", s!"sim {args}: stderr is {repr r.err}"),
    (firstWords r.out == runLabels, s!"sim {args}: stdout is {repr r.out}")]

/-- Runs the expectations in order and gives the first failure. -/
def allOf : List (IO (Option String)) → IO (Option String)
  | [] => pure none
  | c :: rest => do
    match ← c with
    | some m => return some m
    | none => allOf rest

/-- Each value of `ok` is accepted. Each pair of `bad` gives its exact error line. -/
def rangeOf (opt : String) (ok : List String) (bad : List (String × String)) :
    IO (Option String) :=
  allOf (ok.map (fun v => expectRun ["run", opt, v]) ++
    bad.map (fun p => expectError ["run", opt, p.1] p.2))

def checks : List Check := [
  -- JOB-simulate.R1
  { name := "JOB-simulate.R1 sim run prints the 11 lines in order and exits with 0",
    run := do
      let r ← sim ["run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (r.err == "", s!"stderr is {repr r.err}"),
        ((lines r.out).length == 11, s!"{(lines r.out).length} lines"),
        (firstWords r.out == runLabels, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R1 each line has its label to column 19 and a value of the right form",
    run := do
      let r ← sim ["run"]
      let ls := lines r.out
      let bad := (List.range 11).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (runLabels.getD i "") &&
          (if i < 3 then w.length == 2
           else if i < 9 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
      return if r.code != 0 || ls.length != 11 then some s!"stdout is {repr r.out}"
        else match bad with
          | some i => some s!"the line {repr (ls.getD i "")} has the wrong form"
          | none => none },
  { name := "JOB-simulate.R1 the first three lines show greedy, 365 days and seed 1",
    run := do
      let r ← sim ["run"]
      let want := [row "strategy" "greedy", row "days" "365", row "seed" "1"]
      return if r.code == 0 && (lines r.out).take 3 == want then none
        else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --pv 0 shows 0.0 kWh of solar and 0.0 % self-consumption",
    run := do
      let r ← sim ["run", "--pv", "0"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls[3]? == some (row "solar" "0.0 kWh"), s!"the solar line is {ls[3]?}"),
        (ls[9]? == some (row "self-consumption" "0.0 %"), s!"the line is {ls[9]?}")] },
  { name := "JOB-simulate.R1 --strategy shift --days 30 --lat 45 shows the values of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "shift", "--days", "30", "--lat", "45"]
      let t := (simulate (site (lat := 45)) (bat) Strategy.shift 1 30).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "shift", row "days" "30", row "seed" "1"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
  { name := "JOB-simulate.R1 the defaults give the values of the simulation",
    run := do
      let r ← sim ["run"]
      let t := (simulate (site) (bat) Strategy.greedy 1 365).totals
      return (if r.code == 0 then none else some s!"exit code {r.code}") <|> checkShows r.out t },
  -- Each option has a value that differs from its default. Thus, a version that swaps two
  -- options, for example --battery and --power, fails here.
  { name := "JOB-simulate.R1 each option goes to its own part of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "evening", "--days", "40", "--seed", "3", "--lat", "30",
        "--pv", "7.5", "--battery", "4", "--power", "2", "--load", "15", "--flex", "1.5"]
      let t := (simulate (site 30 7.5 15 1.5) (bat 4 2) Strategy.evening 3 40).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "evening", row "days" "40", row "seed" "3"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
  -- A version that keeps --flex at 3 with --load 2 fails the first run. A version that sets
  -- --flex to the --load value with --load 4 fails the second run.
  { name := "JOB-simulate.R1 the --flex default is 3, or the --load value when that is less",
    run := do
      let a ← sim ["run", "--load", "2", "--lat", "45"]
      let b ← sim ["run", "--load", "4", "--lat", "45"]
      let ta := (simulate (site 45 5 2 2) (bat) Strategy.greedy 1 365).totals
      let tb := (simulate (site 45 5 4 3) (bat) Strategy.greedy 1 365).totals
      return firstFail [
        (a.code == 0, s!"--load 2: exit code {a.code}, stderr {repr a.err}"),
        (b.code == 0, s!"--load 4: exit code {b.code}, stderr {repr b.err}")] <|>
        (checkShows a.out ta).map (s!"--load 2: " ++ ·) <|>
        (checkShows b.out tb).map (s!"--load 4: " ++ ·) },
  { name := "JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used",
    run := do
      let r ← sim ["run", "--strategy", "none", "--battery", "0"]
      return match numOf r.out "solar", numOf r.out "self-used", numOf r.out "export" with
        | some s, some u, some e =>
          if r.code == 0 && s > 0 && e > 0 && near e (s - u) 0.1 then none
          else some s!"solar {s}, self-used {u}, export {e}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --days 3650 exits with 0 and shows 3650 days",
    run := do
      let r ← sim ["run", "--days", "3650"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "3650") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },

  -- JOB-simulate.R2
  { name := "JOB-simulate.R2 --monthly prints the 11 lines, a blank line, the header and 12 rows from Jan to Dec",
    run := do
      let r ← sim ["run", "--monthly"]
      let ls := lines r.out
      let rows := ls.drop 13
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 25, s!"{ls.length} lines, want 25"),
        ((ls.take 11).map (fun l => (words l).head?.getD "") == runLabels, "the 11 lines are wrong"),
        (ls[11]? == some "", s!"line 12 is {ls[11]?}, want blank"),
        (Option.map words ls[12]? == some (words monthHeader), s!"the header is {ls[12]?}"),
        (rows.map (fun l => (words l).head?.getD "") == monthNames, s!"rows {rows}"),
        (rows.all (fun l => (words l).length == 7), "a row does not have seven fields")] },
  { name := "JOB-simulate.R2 each row shows the totals of its month",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45", "--seed", "4"]
      let ms := (simulate (site (lat := 45)) (bat) Strategy.greedy 4 365).months
      let rows := (lines r.out).drop 13
      return if r.code == 0 && rows.length == ms.size && ms.size == 12 &&
          (rows.zip ms.toList).all (fun (l, m) => rowShows l m) then none
        else some s!"rows {rows}" },
  { name := "JOB-simulate.R2 --monthly --days 400 prints 14 rows that end with Jan and Feb",
    run := do
      let r ← sim ["run", "--monthly", "--days", "400"]
      let ms := (simulate (site) (bat) Strategy.greedy 1 400).months
      let rows := (lines r.out).drop 13
      let names := rows.map (fun l => (words l).head?.getD "")
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (rows.length == 14 && names.drop 12 == ["Jan", "Feb"], s!"rows {names}"),
        (ms.size == 14 && (rows.zip ms.toList).all (fun (l, m) => rowShows l m),
          s!"the rows do not show the months of the simulation: {rows}")] },
  { name := "JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45"]
      let rows := (lines r.out).drop 13
      let solar := fun (n : String) =>
        (rows.find? (fun l => (words l).head? == some n)).bind (fun l => (words l)[1]?.bind parseNum)
      return match solar "Jul", solar "Dec" with
        | some j, some d => if r.code == 0 && d > 0 && j > 2 * d then none else some s!"Jul {j}, Dec {d}"
        | _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 without --monthly sim run prints only the 11 lines",
    run := do
      let r ← sim ["run", "--lat", "45"]
      return if r.code == 0 && (lines r.out).length == 11 && firstWords r.out == runLabels
        then none else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 the 11 lines of --monthly are the lines of sim run",
    run := do
      let a ← sim ["run", "--lat", "45", "--monthly"]
      let b ← sim ["run", "--lat", "45"]
      return if a.code == 0 && b.code == 0 && (lines a.out).take 11 == lines b.out then none
        else some s!"--monthly {repr a.out}, without {repr b.out}" },

  -- JOB-simulate.R3
  { name := "JOB-simulate.R3 sim compare prints the header and none, greedy, evening and shift",
    run := do
      let r ← sim ["compare"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 5, s!"{ls.length} lines, want 5"),
        (Option.map words ls[0]? == some (words compareHeader), s!"the header is {ls[0]?}"),
        (firstWords r.out == ["strategy", "none", "greedy", "evening", "shift"],
          s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 5), "a row does not have five fields")] },
  { name := "JOB-simulate.R3 the greedy row of --seed 9 --lat 45 shows the four values of sim run",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45"]
      let r ← sim ["run", "--seed", "9", "--lat", "45"]
      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
        valueOf r.out "import", valueOf r.out "export"]
      return match compareRow c.out "greedy" with
        | some w =>
          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?] then none
          else some s!"compare {w}, run {fromRun}"
        | none => some s!"no greedy row in {repr c.out}" },
  -- The options differ from the defaults. Thus, a version that ignores an option in
  -- sim compare fails here.
  { name := "JOB-simulate.R3 each row of sim compare shows the values of the simulation",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45", "--battery", "4", "--load", "15",
        "--days", "100"]
      let bad := Strategy.all.find? (fun s =>
        !compareShows c.out s (simulate (site 45 5 15 3) (bat 4 5) s 9 100).totals)
      return if c.code != 0 then some s!"exit code {c.code}, stderr {repr c.err}"
        else match bad with
          | some s => some s!"the {s.name} row is wrong in {repr c.out}"
          | none => none },
  { name := "JOB-simulate.R3 --lat 45 gives greedy a higher self-consumption than none",
    run := do
      let c ← sim ["compare", "--lat", "45"]
      let sc := fun (n : String) => (compareRow c.out n).bind (fun w => w[1]?.bind parseNum)
      return match sc "greedy", sc "none" with
        | some g, some n => if c.code == 0 && g > n then none else some s!"greedy {g}, none {n}"
        | _, _ => some s!"stdout is {repr c.out}" },
  { name := "JOB-simulate.R3 sim compare --strategy greedy gives UNKNOWN_OPTION",
    run := expectError ["compare", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
  { name := "JOB-simulate.R3 sim compare --monthly gives UNKNOWN_OPTION",
    run := expectError ["compare", "--monthly"] "error: UNKNOWN_OPTION: --monthly" },

  -- JOB-simulate.R4
  { name := "JOB-simulate.R4 --seed 5 gives the same output two times",
    run := do
      let a ← sim ["run", "--seed", "5"]
      let b ← sim ["run", "--seed", "5"]
      let c ← sim ["compare", "--seed", "5"]
      let d ← sim ["compare", "--seed", "5"]
      return firstFail [
        (a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11,
          s!"sim run: first {repr a.out}, second {repr b.out}"),
        (c.code == 0 && d.code == 0 && c.out == d.out && (lines c.out).length == 5,
          s!"sim compare: first {repr c.out}, second {repr d.out}")] },
  { name := "JOB-simulate.R4 --seed 1 and --seed 2 give different solar values",
    run := do
      let a ← sim ["run", "--seed", "1"]
      let b ← sim ["run", "--seed", "2"]
      let sa := valueOf a.out "solar"
      let sb := valueOf b.out "solar"
      return if a.code == 0 && b.code == 0 && sa.isSome && sb.isSome && sa != sb then none
        else some s!"seed 1 {sa}, seed 2 {sb}" },
  { name := "JOB-simulate.R4 --seed 2 gives the solar of the simulation with seed 2",
    run := do
      let r ← sim ["run", "--seed", "2"]
      let t := (simulate (site) (bat) Strategy.greedy 2 365).totals
      return if r.code == 0 && showsNum (valueOf r.out "solar") t.pvKwh then none
        else some s!"solar {valueOf r.out "solar"}, want {round1 t.pvKwh}" },

  -- JOB-simulate.R5
  { name := "JOB-simulate.R5 sim with no arguments prints the usage and exits with 0",
    run := do
      let r ← sim []
      return if r.code == 0 && (lines r.out).head? == some usage && r.err == "" then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim help and sim --help print the same usage and exit with 0",
    run := do
      let a ← sim []
      let h ← sim ["help"]
      let d ← sim ["--help"]
      return firstFail [
        (h.code == 0 && (lines h.out).head? == some usage && h.out == a.out,
          s!"sim help: exit code {h.code}, stdout {repr h.out}"),
        (d.code == 0 && (lines d.out).head? == some usage && d.out == a.out,
          s!"sim --help: exit code {d.code}, stdout {repr d.out}")] },
  { name := "JOB-simulate.R5 sim fly gives UNKNOWN_COMMAND",
    run := expectError ["fly"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 a command word that differs by its case or a space gives UNKNOWN_COMMAND",
    run := allOf [
      expectError ["Run"] "error: UNKNOWN_COMMAND: Run",
      expectError ["run "] "error: UNKNOWN_COMMAND: run ",
      expectError ["Compare"] "error: UNKNOWN_COMMAND: Compare"] },
  { name := "JOB-simulate.R5 --colour red gives UNKNOWN_OPTION",
    run := expectError ["run", "--colour", "red"] "error: UNKNOWN_OPTION: --colour" },
  { name := "JOB-simulate.R5 an option that differs by its case, a dash or an equals sign gives UNKNOWN_OPTION",
    run := allOf [
      expectError ["run", "--Days", "5"] "error: UNKNOWN_OPTION: --Days",
      expectError ["run", "-days", "5"] "error: UNKNOWN_OPTION: -days",
      expectError ["run", "--days=5"] "error: UNKNOWN_OPTION: --days=5"] },
  { name := "JOB-simulate.R5 sim run now gives UNKNOWN_OPTION",
    run := expectError ["run", "now"] "error: UNKNOWN_OPTION: now" },
  { name := "JOB-simulate.R5 --days with no value gives MISSING_VALUE",
    run := expectError ["run", "--days"] "error: MISSING_VALUE: --days" },
  { name := "JOB-simulate.R5 --strategy and --flex with no value give MISSING_VALUE",
    run := allOf [
      expectError ["run", "--strategy"] "error: MISSING_VALUE: --strategy",
      expectError ["run", "--days", "5", "--flex"] "error: MISSING_VALUE: --flex"] },
  { name := "JOB-simulate.R5 --days abc gives BAD_NUMBER",
    run := expectError ["run", "--days", "abc"] "error: BAD_NUMBER: --days abc" },
  { name := "JOB-simulate.R5 an empty --days gives BAD_NUMBER",
    run := expectError ["run", "--days", ""] "error: BAD_NUMBER: --days " },
  { name := "JOB-simulate.R5 --days 36.5 gives BAD_NUMBER",
    run := expectError ["run", "--days", "36.5"] "error: BAD_NUMBER: --days 36.5" },
  { name := "JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER",
    run := allOf [
      expectError ["run", "--days", "2.0"] "error: BAD_NUMBER: --days 2.0",
      expectError ["run", "--days", " 2"] "error: BAD_NUMBER: --days  2",
      expectStart ["run", "--days", "2\n"] "error: BAD_NUMBER: --days 2\n",
      expectError ["run", "--seed", "1.5"] "error: BAD_NUMBER: --seed 1.5"] },
  { name := "JOB-simulate.R5 --days +2 is a whole number with a sign",
    run := do
      let r ← sim ["run", "--days", "+2"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "2") then none
        else some s!"exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}" },
  { name := "JOB-simulate.R5 --pv 1e3, .5, 5. and 5kW give BAD_NUMBER",
    run := allOf [
      expectError ["run", "--pv", "1e3"] "error: BAD_NUMBER: --pv 1e3",
      expectError ["run", "--pv", ".5"] "error: BAD_NUMBER: --pv .5",
      expectError ["run", "--pv", "5."] "error: BAD_NUMBER: --pv 5.",
      expectError ["run", "--pv", "5kW"] "error: BAD_NUMBER: --pv 5kW"] },
  { name := "JOB-simulate.R5 a number with a trailing space, a lone sign or a misplaced sign gives BAD_NUMBER",
    run := allOf [
      expectError ["run", "--pv", "3 "] "error: BAD_NUMBER: --pv 3 ",
      expectError ["run", "--lat", "-"] "error: BAD_NUMBER: --lat -",
      expectError ["run", "--lat", "5-"] "error: BAD_NUMBER: --lat 5-",
      expectError ["run", "--load", "+-5"] "error: BAD_NUMBER: --load +-5"] },
  { name := "JOB-simulate.R5 --pv +3 gives the result of --pv 3",
    run := do
      let a ← sim ["run", "--pv", "+3"]
      let b ← sim ["run", "--pv", "3"]
      let d ← sim ["run"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11 &&
          valueOf a.out "solar" != valueOf d.out "solar" then none
        else some s!"+3 {repr a.out}, 3 {repr b.out}" },
  { name := "JOB-simulate.R5 --days 0 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "0"] "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 3651 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "3651"] "error: OUT_OF_RANGE: --days 3651 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 1 and --days 3650 are accepted",
    run := rangeOf "--days" ["1", "3650"] [] },
  { name := "JOB-simulate.R5 --days 99999999999999999999 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "99999999999999999999"]
      "error: OUT_OF_RANGE: --days 99999999999999999999 (1 to 3650)" },
  { name := "JOB-simulate.R5 --seed -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--seed", "-1"] "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)" },
  { name := "JOB-simulate.R5 --seed 0 and 4294967295 are accepted, and 4294967296 gives OUT_OF_RANGE",
    run := rangeOf "--seed" ["0", "4294967295"]
      [("4294967296", "error: OUT_OF_RANGE: --seed 4294967296 (0 to 4294967295)"),
       ("99999999999999999999", "error: OUT_OF_RANGE: --seed 99999999999999999999 (0 to 4294967295)")] },
  { name := "JOB-simulate.R5 --lat 90 and -90 are accepted, and 90.1 and -90.1 give OUT_OF_RANGE",
    run := rangeOf "--lat" ["90", "-90"]
      [("90.1", "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)"),
       ("-90.1", "error: OUT_OF_RANGE: --lat -90.1 (-90 to 90)")] },
  { name := "JOB-simulate.R5 --pv 0 and 100 are accepted, and 100.1 and -1 give OUT_OF_RANGE",
    run := rangeOf "--pv" ["0", "100"]
      [("100.1", "error: OUT_OF_RANGE: --pv 100.1 (0 to 100)"),
       ("-1", "error: OUT_OF_RANGE: --pv -1 (0 to 100)")] },
  { name := "JOB-simulate.R5 --battery 0 and 200 are accepted, and 200.1 and -0.1 give OUT_OF_RANGE",
    run := rangeOf "--battery" ["0", "200"]
      [("200.1", "error: OUT_OF_RANGE: --battery 200.1 (0 to 200)"),
       ("-0.1", "error: OUT_OF_RANGE: --battery -0.1 (0 to 200)")] },
  { name := "JOB-simulate.R5 --power 0 and 100 are accepted, and 100.1 gives OUT_OF_RANGE",
    run := rangeOf "--power" ["0", "100"]
      [("100.1", "error: OUT_OF_RANGE: --power 100.1 (0 to 100)")] },
  -- With --load 0.1 and no --flex, the --flex default is 0.1, the --load value.
  { name := "JOB-simulate.R5 --load 0.1 and 1000 are accepted, and 0 and 1000.1 give OUT_OF_RANGE",
    run := rangeOf "--load" ["0.1", "1000"]
      [("0", "error: OUT_OF_RANGE: --load 0 (0.1 to 1000)"),
       ("1000.1", "error: OUT_OF_RANGE: --load 1000.1 (0.1 to 1000)")] },
  { name := "JOB-simulate.R5 --load 10 --flex 10 is accepted",
    run := allOf [
      expectRun ["run", "--load", "10", "--flex", "10"],
      expectRun ["run", "--load", "10", "--flex", "0"]] },
  { name := "JOB-simulate.R5 --load 10 --flex 10.5 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "10", "--flex", "10.5"]
      "error: OUT_OF_RANGE: --flex 10.5 (0 to 10)" },
  { name := "JOB-simulate.R5 --flex -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "20", "--flex", "-1"]
      "error: OUT_OF_RANGE: --flex -1 (0 to 20)" },
  { name := "JOB-simulate.R5 the --flex range shows the last --load value as typed",
    run := allOf [
      expectError ["run", "--load", "10.0", "--flex", "10.5"]
        "error: OUT_OF_RANGE: --flex 10.5 (0 to 10.0)",
      expectError ["run", "--load", "10", "--load", "+2", "--flex", "3"]
        "error: OUT_OF_RANGE: --flex 3 (0 to +2)"] },
  { name := "JOB-simulate.R5 --strategy wild gives UNKNOWN_STRATEGY",
    run := expectError ["run", "--strategy", "wild"]
      "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)" },
  { name := "JOB-simulate.R5 a strategy name that differs by its case or a space gives UNKNOWN_STRATEGY",
    run := allOf [
      expectError ["run", "--strategy", "Greedy"]
        "error: UNKNOWN_STRATEGY: Greedy (none, greedy, evening, shift)",
      expectError ["run", "--strategy", "shift "]
        "error: UNKNOWN_STRATEGY: shift  (none, greedy, evening, shift)",
      expectError ["run", "--strategy", ""]
        "error: UNKNOWN_STRATEGY:  (none, greedy, evening, shift)"] },
  { name := "JOB-simulate.R5 each strategy name is accepted",
    run := allOf (Strategy.all.map (fun s => do
      let r ← sim ["run", "--strategy", s.name]
      return if r.code == 0 && (lines r.out).head? == some (row "strategy" s.name) then none
        else some s!"--strategy {s.name}: exit code {r.code}, stdout {repr r.out}")) },
  { name := "JOB-simulate.R5 --days 10 --days 20 shows 20 days",
    run := do
      let r ← sim ["run", "--days", "10", "--days", "20"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 the last value counts before the range is read",
    run := do
      let r ← sim ["run", "--days", "0", "--days", "20"]
      let e ← expectError ["run", "--days", "20", "--days", "0"]
        "error: OUT_OF_RANGE: --days 0 (1 to 3650)"
      return (if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"--days 0 --days 20: exit code {r.code}, stderr {repr r.err}") <|> e },
  { name := "JOB-simulate.R5 the command word comes before each option",
    run := expectError ["fly", "--colour", "red"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 the options are read from left to right and the first problem gives the error",
    run := allOf [
      expectError ["run", "--colour", "red", "--days", "abc"] "error: UNKNOWN_OPTION: --colour",
      expectError ["run", "--days", "abc", "--colour", "red"] "error: BAD_NUMBER: --days abc",
      expectError ["run", "--strategy", "wild", "--pv", "x"]
        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
      expectError ["run", "--pv", "x", "--days"] "error: BAD_NUMBER: --pv x"] },
  { name := "JOB-simulate.R5 a bad number or strategy comes before a range problem",
    run := allOf [
      expectError ["run", "--days", "0", "--pv", "x"] "error: BAD_NUMBER: --pv x",
      expectError ["run", "--days", "0", "--strategy", "wild"]
        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
      expectError ["run", "--days", "0", "--colour"] "error: UNKNOWN_OPTION: --colour"] },
  { name := "JOB-simulate.R5 a range problem comes before the --flex check",
    run := expectError ["run", "--load", "2", "--flex", "5", "--days", "0"]
      "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 an error of sim compare gives the same line as an error of sim run",
    run := allOf [
      expectError ["compare", "--days", "abc"] "error: BAD_NUMBER: --days abc",
      expectError ["compare", "--lat", "91"] "error: OUT_OF_RANGE: --lat 91 (-90 to 90)",
      expectError ["compare", "--seed"] "error: MISSING_VALUE: --seed",
      expectError ["compare", "now"] "error: UNKNOWN_OPTION: now"] }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
    match res with
    | none => pure ()
    | some msg =>
      failed := failed + 1
      IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
````

