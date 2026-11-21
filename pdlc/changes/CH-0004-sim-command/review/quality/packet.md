# Review packet · CH-0004-sim-command · quality

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 144199141d891c6f17d32089e56b55f2914cfc0a

## Re-review

Earlier review: 9655884e4aae2f5c2163328c86f096299ead7f2f

An earlier review of this remit judged this change at 9655884e4aae. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.

### Earlier problems

- Main.lean:292 · `usageLine` pads the option with `labelWidth`. The doc of `labelWidth` (Main.lean:231) says that it is the width of a label in a line of `sim run`. Thus, the usage layout depends on a constant that names a different thing. The doc of `usageLine` (Main.lean:290) says "spaces to column 21". That is true only while `labelWidth` is 18. A change to the `sim run` layout would also move the usage text, and nothing tells the reader so. Fix: give the usage its own named width, for example `usageOptionWidth`, or rename `labelWidth` and its doc to say that both layouts share it. · Remit rule "Names tell what things are and what they do."

### Changes since the earlier review

````
diff --git a/Main.lean b/Main.lean
index 52c28b9..edf25e6 100644
--- a/Main.lean
+++ b/Main.lean
@@ -219,8 +219,8 @@ def CommandLine.site (commandLine : CommandLine) : Site :=
 def CommandLine.battery (commandLine : CommandLine) : Battery :=
   { capacityKwh := commandLine.number batteryOption, powerKw := commandLine.number powerOption }
 
-/-- The value of a whole-number option. The range step makes sure that the value is whole and
-not negative. -/
+/-- The value of a whole-number option. The reading step makes sure that the value is whole,
+and the range step makes sure that it is not negative. -/
 def CommandLine.whole (commandLine : CommandLine) (option : NumberOption) : Nat :=
   (commandLine.number option).toUInt64.toNat
 
@@ -287,9 +287,13 @@ def output (command : Command) (commandLine : CommandLine) : List String :=
 
 /-! ## The command -/
 
-/-- A line of the usage: the option and its value, spaces to column 21, and the meaning. -/
+/-- The width of the option, its value and its spaces in a line of the usage. -/
+def usageOptionWidth : Nat := 18
+
+/-- A line of the usage: two spaces, the option and its value, spaces to fill
+`usageOptionWidth`, and the meaning. -/
 def usageLine (option meaning : String) : String :=
-  "  " ++ option ++ "".pushn ' ' (labelWidth - option.length) ++ meaning
+  "  " ++ option ++ "".pushn ' ' (usageOptionWidth - option.length) ++ meaning
 
 def usage : List String :=
   let numberLine (option : NumberOption) :=
diff --git a/README.md b/README.md
index 0dec1a8..4411123 100644
--- a/README.md
+++ b/README.md
@@ -68,7 +68,7 @@ The line is `error: <code>: <detail>`, for example `error: OUT_OF_RANGE: --days
 
 | Code | Cause |
 |---|---|
-| `UNKNOWN_COMMAND` | The first word is not `run`, `compare` or `help` |
+| `UNKNOWN_COMMAND` | The first word is not `run`, `compare`, `help` or `--help` |
 | `UNKNOWN_OPTION` | The command does not take the word |
 | `MISSING_VALUE` | An option that needs a value comes last |
 | `BAD_NUMBER` | A value is not a number of the right form |
````

# Remit: quality

Default: yes

You judge if the code is easy to read and change.

- Names tell what things are and what they do.
- There is no unnecessary repetition and no dead code.
- The code handles the errors that the requirements name, and the error messages help the
  person who sees them.
- The code follows the design specs in this packet.
- The code is as simple as the requirement lets it be.

## The change spec

````
# CH-0004 · The sim command

Intent: IN-0001 · Scope: JOB-simulate · Status: building · Ticket: none · Branch: pdlc/CH-0004-sim-command · Base: pdlc/CH-0003-simulation

Tests-Locked: a7fe93a

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

### Step 1 · Run one strategy · [x]

- Requirement: JOB-simulate.R1
- Check: the checks named `JOB-simulate.R1 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 2 · Monthly table · [x]

- Requirement: JOB-simulate.R2
- Check: the checks named `JOB-simulate.R2 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 3 · Compare strategies · [x]

- Requirement: JOB-simulate.R3
- Check: the checks named `JOB-simulate.R3 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 4 · Repeatable weather · [x]

- Requirement: JOB-simulate.R4
- Check: the checks named `JOB-simulate.R4 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 5 · Bad command line · [x]

- Requirement: JOB-simulate.R5
- Check: the checks named `JOB-simulate.R5 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 6 · README · [x]

- Requirement: JOB-simulate.R1, JOB-simulate.R2, JOB-simulate.R3, JOB-simulate.R4, JOB-simulate.R5
- Check: none
- Done when: the README tells what `sim run`, `sim run --monthly` and `sim compare` do, with each option, default and range. It names the `--seed` seam. It tells how to build with `lake build`, and how to run the checks with the "all" command of `pdlc/config.md`.

## Manual checks

none

## Progress log

- Planned last, because the command uses CH-0001 (scenario), CH-0002 (strategies) and CH-0003 (simulation).
- Build: all 190 checks and the 154 acceptance checks pass. No check changed since the lock `a7fe93a`.
- The first verify failed on specification and quality. The change went back to build.
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

Status: built · Intents: IN-0001

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

Status: built · Intents: IN-0001

`sim run --monthly` prints the 11 lines, a blank line, and a table with one row for each
month (assumed). The header is `month solar-kWh load-kWh import-kWh export-kWh
self-consumption-% self-sufficiency-%` with the columns aligned by spaces (assumed). Each
row starts with the short month name, for example `Jan`, and has seven fields.

- Given `--monthly`, when the person runs `sim run`, then the table has the header and 12 rows, from `Jan` to `Dec`.
- Given `--monthly --days 400`, when the person runs `sim run`, then the table has 14 rows. The last two rows are `Jan` and `Feb`.
- Given `--monthly --lat 45`, when the person runs `sim run`, then the `Jul` solar value is more than twice the `Dec` solar value.
- Given no `--monthly`, when the person runs `sim run`, then it prints only the 11 lines.

### JOB-simulate.R3 · Compare strategies

Status: built · Intents: IN-0001

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

Status: built · Intents: IN-0001

The seed sets the weather. The same options and seed give the same output each time.

- Given `--seed 5`, when the person runs `sim run` two times, then the two outputs are the same.
- Given `--seed 1` and `--seed 2`, when the person runs `sim run` with each, then the two `solar` values differ.

### JOB-simulate.R5 · Bad command line

Status: built · Intents: IN-0001

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

## The code

### Diff against pdlc/CH-0003-simulation

````
diff --git a/Main.lean b/Main.lean
new file mode 100644
index 0000000..edf25e6
--- /dev/null
+++ b/Main.lean
@@ -0,0 +1,335 @@
+/-
+The `sim` command. `sim run` simulates one strategy, and `sim compare` simulates each
+strategy on the same weather. JOB-simulate (simulate a year of solar) gives the rules.
+-/
+import StoragePolicySim.Simulation
+
+open StoragePolicySim
+
+/-! ## Options -/
+
+/-- A command that simulates. -/
+inductive Command
+  | run
+  | compare
+  deriving BEq
+
+/-- An option that takes a number with a fixed range. -/
+structure NumberOption where
+  flag : String
+  /-- What the number gives, for the usage. -/
+  meaning : String
+  /-- True when the option takes only whole numbers. -/
+  wholeOnly : Bool := false
+  default : Float
+  lowest : Float
+  highest : Float
+
+def daysOption : NumberOption :=
+  { flag := "--days", meaning := "days to simulate", wholeOnly := true,
+    default := 365, lowest := 1, highest := 3650 }
+
+def seedOption : NumberOption :=
+  { flag := "--seed", meaning := "seed of the weather", wholeOnly := true,
+    default := 1, lowest := 0, highest := 4294967295 }
+
+def latitudeOption : NumberOption :=
+  { flag := "--lat", meaning := "latitude in degrees, south is negative",
+    default := -41.3, lowest := -90, highest := 90 }
+
+def pvOption : NumberOption :=
+  { flag := "--pv", meaning := "kW of the solar panels", default := 5, lowest := 0, highest := 100 }
+
+def batteryOption : NumberOption :=
+  { flag := "--battery", meaning := "kWh that the battery holds",
+    default := 10, lowest := 0, highest := 200 }
+
+def powerOption : NumberOption :=
+  { flag := "--power", meaning := "kW in or out of the battery",
+    default := 5, lowest := 0, highest := 100 }
+
+def loadOption : NumberOption :=
+  { flag := "--load", meaning := "kWh of household load each day",
+    default := 20, lowest := 0.1, highest := 1000 }
+
+/-- The number options with a fixed range, in the order that the range step reads them. -/
+def rangedOptions : List NumberOption :=
+  [daysOption, seedOption, latitudeOption, pvOption, batteryOption, powerOption, loadOption]
+
+/-- The `--flex` range is from 0 to the `--load` value. Thus, `--flex` is not a ranged option. -/
+def flexFlag : String := "--flex"
+
+/-- The `--flex` value when the person gives none, unless the `--load` value is less. -/
+def defaultFlexKwh : Float := 3
+
+def strategyFlag : String := "--strategy"
+
+def monthlyFlag : String := "--monthly"
+
+def defaultStrategy : Strategy := .greedy
+
+/-- A number option value, as the person typed it and as a number. -/
+structure TypedNumber where
+  text : String
+  value : Float
+
+/-- The options of a command line after the reading step. -/
+structure CommandLine where
+  strategy : Strategy := defaultStrategy
+  monthly : Bool := false
+  /-- The number options, the last typed first. -/
+  numbers : List (String × TypedNumber) := []
+
+/-- The last value that the person typed for the option. -/
+def CommandLine.typed (commandLine : CommandLine) (flag : String) : Option TypedNumber :=
+  (commandLine.numbers.find? (·.1 == flag)).map (·.2)
+
+/-- The last typed value of the option, or its default. -/
+def CommandLine.number (commandLine : CommandLine) (option : NumberOption) : Float :=
+  ((commandLine.typed option.flag).map (·.value)).getD option.default
+
+/-! ## Errors -/
+
+/-- A problem of the command line. DES-errors (error codes) gives the codes. -/
+inductive Problem
+  | unknownCommand (word : String)
+  | unknownOption (word : String)
+  | missingValue (flag : String)
+  | badNumber (flag text : String)
+  | outOfRange (flag text lowest highest : String)
+  | unknownStrategy (name : String)
+
+/-- The strategy names, as the usage and the errors list them. -/
+def strategyNames : String := ", ".intercalate (Strategy.all.map (·.name))
+
+def Problem.line : Problem → String
+  | .unknownCommand word => s!"error: UNKNOWN_COMMAND: {word}"
+  | .unknownOption word => s!"error: UNKNOWN_OPTION: {word}"
+  | .missingValue flag => s!"error: MISSING_VALUE: {flag}"
+  | .badNumber flag text => s!"error: BAD_NUMBER: {flag} {text}"
+  | .outOfRange flag text lowest highest =>
+    s!"error: OUT_OF_RANGE: {flag} {text} ({lowest} to {highest})"
+  | .unknownStrategy name =>
+    s!"error: UNKNOWN_STRATEGY: {name} ({strategyNames})"
+
+/-! ## Numbers -/
+
+/-- The value of decimal digits. -/
+def digitsValue (digits : List Char) : Nat :=
+  digits.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0
+
+/-- Reads an optional sign, digits, and an optional point with more digits. A whole number
+has no point. -/
+def readNumber (wholeOnly : Bool) (text : String) : Option Float :=
+  let (negative, unsigned) := match text.toList with
+    | '-' :: rest => (true, rest)
+    | '+' :: rest => (false, rest)
+    | rest => (false, rest)
+  let wholeDigits := unsigned.takeWhile Char.isDigit
+  let fraction : Option (List Char) := match unsigned.dropWhile Char.isDigit with
+    | [] => some []
+    | '.' :: digits => if wholeOnly || digits.isEmpty || !digits.all Char.isDigit then none
+      else some digits
+    | _ => none
+  match fraction with
+  | some fractionDigits =>
+    if wholeDigits.isEmpty then none
+    else
+      let magnitude := Float.ofScientific (digitsValue (wholeDigits ++ fractionDigits)) true
+        fractionDigits.length
+      some (if negative then -magnitude else magnitude)
+  | none => none
+
+/-- The value with one decimal, rounded half away from zero. -/
+def oneDecimal (x : Float) : String :=
+  let tenths := (x.abs * 10).round.toUInt64.toNat
+  let sign := if x < 0 && tenths > 0 then "-" else ""
+  s!"{sign}{tenths / 10}.{tenths % 10}"
+
+/-- A bound of a range, as the usage and the errors write it: `-90`, `0.1` or `3650`. -/
+def boundText (x : Float) : String :=
+  if x.floor == x then
+    let magnitude := x.abs.toUInt64.toNat
+    if x < 0 then s!"-{magnitude}" else s!"{magnitude}"
+  else oneDecimal x
+
+/-! ## Reading the command line -/
+
+def numberOption? (flag : String) : Option NumberOption :=
+  rangedOptions.find? (·.flag == flag)
+
+/-- Adds the value of an option that takes a value. A bad number or strategy name is a
+problem. -/
+def CommandLine.add (commandLine : CommandLine) (flag value : String) :
+    Except Problem CommandLine :=
+  if flag == strategyFlag then
+    match Strategy.ofName? value with
+    | some strategy => .ok { commandLine with strategy }
+    | none => .error (.unknownStrategy value)
+  else
+    let wholeOnly := ((numberOption? flag).map (·.wholeOnly)).getD false
+    match readNumber wholeOnly value with
+    | some number =>
+      .ok { commandLine with numbers := (flag, ⟨value, number⟩) :: commandLine.numbers }
+    | none => .error (.badNumber flag value)
+
+/-- True when the command takes the option and the option takes a value. -/
+def takesValue (command : Command) (flag : String) : Bool :=
+  (numberOption? flag).isSome || flag == flexFlag || (command == .run && flag == strategyFlag)
+
+/-- Reads each option and its value, from left to right. The first problem stops the reading. -/
+def readOptions (command : Command) (commandLine : CommandLine) :
+    List String → Except Problem CommandLine
+  | [] => .ok commandLine
+  | flag :: rest =>
+    if command == .run && flag == monthlyFlag then
+      readOptions command { commandLine with monthly := true } rest
+    else if !takesValue command flag then .error (.unknownOption flag)
+    else match rest with
+      | [] => .error (.missingValue flag)
+      | value :: afterValue => do
+        readOptions command (← commandLine.add flag value) afterValue
+
+/-- Finds the first option outside its range. Then finds a `--flex` value outside 0 to the
+`--load` value. -/
+def CommandLine.rangeProblem? (commandLine : CommandLine) : Option Problem :=
+  let outside (typed : TypedNumber) (lowest highest : Float) :=
+    typed.value < lowest || typed.value > highest
+  let ranged := rangedOptions.findSome? fun option =>
+    (commandLine.typed option.flag).bind fun typed =>
+      if outside typed option.lowest option.highest then
+        some (.outOfRange option.flag typed.text (boundText option.lowest)
+          (boundText option.highest))
+      else none
+  let loadText := ((commandLine.typed loadOption.flag).map (·.text)).getD
+    (boundText loadOption.default)
+  ranged <|> (commandLine.typed flexFlag).bind fun typed =>
+    if outside typed 0 (commandLine.number loadOption) then
+      some (.outOfRange flexFlag typed.text "0" loadText)
+    else none
+
+/-! ## Simulation and output -/
+
+def CommandLine.site (commandLine : CommandLine) : Site :=
+  let loadKwh := commandLine.number loadOption
+  let flexKwh := ((commandLine.typed flexFlag).map (·.value)).getD (min defaultFlexKwh loadKwh)
+  { latitude := commandLine.number latitudeOption, pvKw := commandLine.number pvOption,
+    dailyLoadKwh := loadKwh, flexKwh }
+
+def CommandLine.battery (commandLine : CommandLine) : Battery :=
+  { capacityKwh := commandLine.number batteryOption, powerKw := commandLine.number powerOption }
+
+/-- The value of a whole-number option. The reading step makes sure that the value is whole,
+and the range step makes sure that it is not negative. -/
+def CommandLine.whole (commandLine : CommandLine) (option : NumberOption) : Nat :=
+  (commandLine.number option).toUInt64.toNat
+
+def CommandLine.simulate (commandLine : CommandLine) (strategy : Strategy) : Result :=
+  StoragePolicySim.simulate commandLine.site commandLine.battery strategy
+    (commandLine.whole seedOption) (commandLine.whole daysOption)
+
+/-- The width of the label and its spaces in a line of `sim run`. -/
+def labelWidth : Nat := 18
+
+def labelledLine (label value : String) : String :=
+  label ++ "".pushn ' ' (labelWidth - label.length) ++ value
+
+/-- The 11 lines of `sim run`. -/
+def runLines (commandLine : CommandLine) (totals : Totals) : List String :=
+  let energy (label : String) (kwh : Float) := labelledLine label (oneDecimal kwh ++ " kWh")
+  let ratio (label : String) (percent : Float) := labelledLine label (oneDecimal percent ++ " %")
+  [labelledLine "strategy" commandLine.strategy.name,
+   labelledLine "days" (toString (commandLine.whole daysOption)),
+   labelledLine "seed" (toString (commandLine.whole seedOption)),
+   energy "solar" totals.pvKwh, energy "load" totals.loadKwh,
+   energy "self-used" totals.selfUsedKwh, energy "import" totals.importKwh,
+   energy "export" totals.exportKwh, energy "losses" totals.lossKwh,
+   ratio "self-consumption" totals.selfConsumption,
+   ratio "self-sufficiency" totals.selfSufficiency]
+
+/-- The header, and then a row for each list of fields. The first column aligns left, and
+each other column aligns right under its header word. -/
+def table (header : List String) (rows : List (List String)) : List String :=
+  let alignedRow (fields : List String) : String :=
+    let cells := (header.zip fields).zipIdx.map fun ((word, field), column) =>
+      let spaces := "".pushn ' ' (word.length - field.length)
+      if column == 0 then field ++ spaces else spaces ++ field
+    " ".intercalate cells
+  " ".intercalate header :: rows.map alignedRow
+
+def monthHeader : List String :=
+  ["month", "solar-kWh", "load-kWh", "import-kWh", "export-kWh", "self-consumption-%",
+   "self-sufficiency-%"]
+
+def monthRow (month : Month) : List String :=
+  let totals := month.totals
+  month.name :: [totals.pvKwh, totals.loadKwh, totals.importKwh, totals.exportKwh,
+    totals.selfConsumption, totals.selfSufficiency].map oneDecimal
+
+def compareHeader : List String :=
+  ["strategy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh"]
+
+def compareRow (strategy : Strategy) (totals : Totals) : List String :=
+  strategy.name :: [totals.selfConsumption, totals.selfSufficiency, totals.importKwh,
+    totals.exportKwh].map oneDecimal
+
+/-- The stdout lines of a command with good options. -/
+def output (command : Command) (commandLine : CommandLine) : List String :=
+  match command with
+  | .run =>
+    let result := commandLine.simulate commandLine.strategy
+    let monthTable := if commandLine.monthly
+      then "" :: table monthHeader (result.months.toList.map monthRow) else []
+    runLines commandLine result.totals ++ monthTable
+  | .compare =>
+    table compareHeader (Strategy.all.map fun strategy =>
+      compareRow strategy (commandLine.simulate strategy).totals)
+
+/-! ## The command -/
+
+/-- The width of the option, its value and its spaces in a line of the usage. -/
+def usageOptionWidth : Nat := 18
+
+/-- A line of the usage: two spaces, the option and its value, spaces to fill
+`usageOptionWidth`, and the meaning. -/
+def usageLine (option meaning : String) : String :=
+  "  " ++ option ++ "".pushn ' ' (usageOptionWidth - option.length) ++ meaning
+
+def usage : List String :=
+  let numberLine (option : NumberOption) :=
+    usageLine s!"{option.flag} N" (s!"{option.meaning}. Default {boundText option.default}, " ++
+      s!"range {boundText option.lowest} to {boundText option.highest}.")
+  ["usage: sim run [options] | sim compare [options]",
+   "",
+   "sim run simulates one strategy and prints the totals.",
+   "sim compare simulates each strategy on the same weather.",
+   "",
+   "Options:",
+   usageLine s!"{strategyFlag} NAME"
+     s!"sim run only. Default {defaultStrategy.name}, one of {strategyNames}.",
+   usageLine monthlyFlag "sim run only. Also prints the totals of each month."] ++
+  rangedOptions.map numberLine ++
+  [usageLine s!"{flexFlag} N" (s!"kWh of the daily load that a strategy can move. " ++
+     s!"Default {boundText defaultFlexKwh}, or the --load value when that is less. " ++
+     "Range 0 to the --load value.")]
+
+/-- Reads the options of the command. The first problem gives the error. -/
+def runCommand (command : Command) (words : List String) : Except Problem (List String) := do
+  let commandLine ← readOptions command {} words
+  match commandLine.rangeProblem? with
+  | some problem => .error problem
+  | none => .ok (output command commandLine)
+
+def main (args : List String) : IO UInt32 := do
+  let outcome : Except Problem (List String) := match args with
+    | [] | "help" :: _ | "--help" :: _ => .ok usage
+    | "run" :: words => runCommand .run words
+    | "compare" :: words => runCommand .compare words
+    | word :: _ => .error (.unknownCommand word)
+  match outcome with
+  | .ok lines =>
+    IO.print (String.join (lines.map (· ++ "\n")))
+    return 0
+  | .error problem =>
+    IO.eprintln problem.line
+    return 2
diff --git a/README.md b/README.md
new file mode 100644
index 0000000..4411123
--- /dev/null
+++ b/README.md
@@ -0,0 +1,86 @@
+# storage-policy-sim
+
+`storage-policy-sim` simulates a home solar system with a battery, hour by hour. The `sim`
+command runs one battery strategy, or compares all strategies on the same weather.
+
+## Build
+
+Run this command in the root folder of the project:
+
+```
+lake build
+```
+
+The command is then at `.lake/build/bin/sim`. The toolchain is Lean 4.35.0.
+
+## Commands
+
+- `sim`, `sim help` and `sim --help` print the usage.
+- `sim run [options]` simulates one strategy. The command prints 11 lines: the strategy,
+  the days, the seed, the solar energy, the load, the self-used solar energy, the import,
+  the export, the battery losses, the self-consumption and the self-sufficiency.
+- `sim run --monthly [options]` prints the 11 lines, a blank line and a table. The table
+  has one row for each month of the run, with the totals of that month.
+- `sim compare [options]` simulates each strategy on the same weather. The command prints
+  one row for each strategy: `none`, `greedy`, `evening` and `shift`. Each row gives the
+  self-consumption, the self-sufficiency, the import and the export.
+
+For example:
+
+```
+.lake/build/bin/sim run --lat 45 --pv 6
+.lake/build/bin/sim run --monthly --strategy shift
+.lake/build/bin/sim compare --seed 9 --battery 5
+```
+
+## Options
+
+Each option takes one value, except `--monthly`. When you give an option two times, the
+last value counts. `sim compare` takes each option except `--strategy` and `--monthly`.
+
+| Option | Meaning | Default | Range |
+|---|---|---|---|
+| `--strategy` | The battery strategy (`sim run` only) | `greedy` | `none`, `greedy`, `evening` or `shift` |
+| `--monthly` | Also print the totals of each month (`sim run` only) | off | no value |
+| `--days` | The days to simulate, a whole number | 365 | 1 to 3650 |
+| `--seed` | The seed of the weather, a whole number | 1 | 0 to 4294967295 |
+| `--lat` | The latitude in degrees, south is negative | -41.3 | -90 to 90 |
+| `--pv` | The kW of the solar panels | 5 | 0 to 100 |
+| `--battery` | The kWh that the battery holds | 10 | 0 to 200 |
+| `--power` | The kW into or out of the battery in one hour | 5 | 0 to 100 |
+| `--load` | The kWh of household load each day | 20 | 0.1 to 1000 |
+| `--flex` | The kWh of the daily load that a strategy can move | 3, or the `--load` value when that is less | 0 to the `--load` value |
+
+A number has an optional sign, digits, and an optional point with more digits, for
+example `-41.3` or `+3`. `--days` and `--seed` take only whole numbers.
+
+## Repeatable weather
+
+The `--seed` option sets the weather. The same seed and the same options give the same
+output each time. Thus, when you change one other option, the result shows only the effect
+of that option. The `--seed` option is the only seam for the checks. No output depends on
+the clock.
+
+## Errors
+
+A bad command line prints one line on stderr and nothing on stdout. The exit code is 2.
+The line is `error: <code>: <detail>`, for example `error: OUT_OF_RANGE: --days 0 (1 to 3650)`.
+
+| Code | Cause |
+|---|---|
+| `UNKNOWN_COMMAND` | The first word is not `run`, `compare`, `help` or `--help` |
+| `UNKNOWN_OPTION` | The command does not take the word |
+| `MISSING_VALUE` | An option that needs a value comes last |
+| `BAD_NUMBER` | A value is not a number of the right form |
+| `OUT_OF_RANGE` | A number is outside the range of its option |
+| `UNKNOWN_STRATEGY` | The strategy name is not in the list |
+
+## Run the checks
+
+Run this command in the root folder of the project:
+
+```
+lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done
+```
+
+The command builds the project and runs each check file in `tests/`.
diff --git a/lakefile.toml b/lakefile.toml
index 0a10da9..6e7fcf4 100644
--- a/lakefile.toml
+++ b/lakefile.toml
@@ -1,7 +1,11 @@
 name = "storage-policy-sim"
 version = "0.1.0"
-defaultTargets = ["StoragePolicySim"]
+defaultTargets = ["StoragePolicySim", "sim"]
 
 [[lean_lib]]
 name = "StoragePolicySim"
 globs = ["StoragePolicySim.+"]
+
+[[lean_exe]]
+name = "sim"
+root = "Main"
````

### Main.lean

````
/-
The `sim` command. `sim run` simulates one strategy, and `sim compare` simulates each
strategy on the same weather. JOB-simulate (simulate a year of solar) gives the rules.
-/
import StoragePolicySim.Simulation

open StoragePolicySim

/-! ## Options -/

/-- A command that simulates. -/
inductive Command
  | run
  | compare
  deriving BEq

/-- An option that takes a number with a fixed range. -/
structure NumberOption where
  flag : String
  /-- What the number gives, for the usage. -/
  meaning : String
  /-- True when the option takes only whole numbers. -/
  wholeOnly : Bool := false
  default : Float
  lowest : Float
  highest : Float

def daysOption : NumberOption :=
  { flag := "--days", meaning := "days to simulate", wholeOnly := true,
    default := 365, lowest := 1, highest := 3650 }

def seedOption : NumberOption :=
  { flag := "--seed", meaning := "seed of the weather", wholeOnly := true,
    default := 1, lowest := 0, highest := 4294967295 }

def latitudeOption : NumberOption :=
  { flag := "--lat", meaning := "latitude in degrees, south is negative",
    default := -41.3, lowest := -90, highest := 90 }

def pvOption : NumberOption :=
  { flag := "--pv", meaning := "kW of the solar panels", default := 5, lowest := 0, highest := 100 }

def batteryOption : NumberOption :=
  { flag := "--battery", meaning := "kWh that the battery holds",
    default := 10, lowest := 0, highest := 200 }

def powerOption : NumberOption :=
  { flag := "--power", meaning := "kW in or out of the battery",
    default := 5, lowest := 0, highest := 100 }

def loadOption : NumberOption :=
  { flag := "--load", meaning := "kWh of household load each day",
    default := 20, lowest := 0.1, highest := 1000 }

/-- The number options with a fixed range, in the order that the range step reads them. -/
def rangedOptions : List NumberOption :=
  [daysOption, seedOption, latitudeOption, pvOption, batteryOption, powerOption, loadOption]

/-- The `--flex` range is from 0 to the `--load` value. Thus, `--flex` is not a ranged option. -/
def flexFlag : String := "--flex"

/-- The `--flex` value when the person gives none, unless the `--load` value is less. -/
def defaultFlexKwh : Float := 3

def strategyFlag : String := "--strategy"

def monthlyFlag : String := "--monthly"

def defaultStrategy : Strategy := .greedy

/-- A number option value, as the person typed it and as a number. -/
structure TypedNumber where
  text : String
  value : Float

/-- The options of a command line after the reading step. -/
structure CommandLine where
  strategy : Strategy := defaultStrategy
  monthly : Bool := false
  /-- The number options, the last typed first. -/
  numbers : List (String × TypedNumber) := []

/-- The last value that the person typed for the option. -/
def CommandLine.typed (commandLine : CommandLine) (flag : String) : Option TypedNumber :=
  (commandLine.numbers.find? (·.1 == flag)).map (·.2)

/-- The last typed value of the option, or its default. -/
def CommandLine.number (commandLine : CommandLine) (option : NumberOption) : Float :=
  ((commandLine.typed option.flag).map (·.value)).getD option.default

/-! ## Errors -/

/-- A problem of the command line. DES-errors (error codes) gives the codes. -/
inductive Problem
  | unknownCommand (word : String)
  | unknownOption (word : String)
  | missingValue (flag : String)
  | badNumber (flag text : String)
  | outOfRange (flag text lowest highest : String)
  | unknownStrategy (name : String)

/-- The strategy names, as the usage and the errors list them. -/
def strategyNames : String := ", ".intercalate (Strategy.all.map (·.name))

def Problem.line : Problem → String
  | .unknownCommand word => s!"error: UNKNOWN_COMMAND: {word}"
  | .unknownOption word => s!"error: UNKNOWN_OPTION: {word}"
  | .missingValue flag => s!"error: MISSING_VALUE: {flag}"
  | .badNumber flag text => s!"error: BAD_NUMBER: {flag} {text}"
  | .outOfRange flag text lowest highest =>
    s!"error: OUT_OF_RANGE: {flag} {text} ({lowest} to {highest})"
  | .unknownStrategy name =>
    s!"error: UNKNOWN_STRATEGY: {name} ({strategyNames})"

/-! ## Numbers -/

/-- The value of decimal digits. -/
def digitsValue (digits : List Char) : Nat :=
  digits.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads an optional sign, digits, and an optional point with more digits. A whole number
has no point. -/
def readNumber (wholeOnly : Bool) (text : String) : Option Float :=
  let (negative, unsigned) := match text.toList with
    | '-' :: rest => (true, rest)
    | '+' :: rest => (false, rest)
    | rest => (false, rest)
  let wholeDigits := unsigned.takeWhile Char.isDigit
  let fraction : Option (List Char) := match unsigned.dropWhile Char.isDigit with
    | [] => some []
    | '.' :: digits => if wholeOnly || digits.isEmpty || !digits.all Char.isDigit then none
      else some digits
    | _ => none
  match fraction with
  | some fractionDigits =>
    if wholeDigits.isEmpty then none
    else
      let magnitude := Float.ofScientific (digitsValue (wholeDigits ++ fractionDigits)) true
        fractionDigits.length
      some (if negative then -magnitude else magnitude)
  | none => none

/-- The value with one decimal, rounded half away from zero. -/
def oneDecimal (x : Float) : String :=
  let tenths := (x.abs * 10).round.toUInt64.toNat
  let sign := if x < 0 && tenths > 0 then "-" else ""
  s!"{sign}{tenths / 10}.{tenths % 10}"

/-- A bound of a range, as the usage and the errors write it: `-90`, `0.1` or `3650`. -/
def boundText (x : Float) : String :=
  if x.floor == x then
    let magnitude := x.abs.toUInt64.toNat
    if x < 0 then s!"-{magnitude}" else s!"{magnitude}"
  else oneDecimal x

/-! ## Reading the command line -/

def numberOption? (flag : String) : Option NumberOption :=
  rangedOptions.find? (·.flag == flag)

/-- Adds the value of an option that takes a value. A bad number or strategy name is a
problem. -/
def CommandLine.add (commandLine : CommandLine) (flag value : String) :
    Except Problem CommandLine :=
  if flag == strategyFlag then
    match Strategy.ofName? value with
    | some strategy => .ok { commandLine with strategy }
    | none => .error (.unknownStrategy value)
  else
    let wholeOnly := ((numberOption? flag).map (·.wholeOnly)).getD false
    match readNumber wholeOnly value with
    | some number =>
      .ok { commandLine with numbers := (flag, ⟨value, number⟩) :: commandLine.numbers }
    | none => .error (.badNumber flag value)

/-- True when the command takes the option and the option takes a value. -/
def takesValue (command : Command) (flag : String) : Bool :=
  (numberOption? flag).isSome || flag == flexFlag || (command == .run && flag == strategyFlag)

/-- Reads each option and its value, from left to right. The first problem stops the reading. -/
def readOptions (command : Command) (commandLine : CommandLine) :
    List String → Except Problem CommandLine
  | [] => .ok commandLine
  | flag :: rest =>
    if command == .run && flag == monthlyFlag then
      readOptions command { commandLine with monthly := true } rest
    else if !takesValue command flag then .error (.unknownOption flag)
    else match rest with
      | [] => .error (.missingValue flag)
      | value :: afterValue => do
        readOptions command (← commandLine.add flag value) afterValue

/-- Finds the first option outside its range. Then finds a `--flex` value outside 0 to the
`--load` value. -/
def CommandLine.rangeProblem? (commandLine : CommandLine) : Option Problem :=
  let outside (typed : TypedNumber) (lowest highest : Float) :=
    typed.value < lowest || typed.value > highest
  let ranged := rangedOptions.findSome? fun option =>
    (commandLine.typed option.flag).bind fun typed =>
      if outside typed option.lowest option.highest then
        some (.outOfRange option.flag typed.text (boundText option.lowest)
          (boundText option.highest))
      else none
  let loadText := ((commandLine.typed loadOption.flag).map (·.text)).getD
    (boundText loadOption.default)
  ranged <|> (commandLine.typed flexFlag).bind fun typed =>
    if outside typed 0 (commandLine.number loadOption) then
      some (.outOfRange flexFlag typed.text "0" loadText)
    else none

/-! ## Simulation and output -/

def CommandLine.site (commandLine : CommandLine) : Site :=
  let loadKwh := commandLine.number loadOption
  let flexKwh := ((commandLine.typed flexFlag).map (·.value)).getD (min defaultFlexKwh loadKwh)
  { latitude := commandLine.number latitudeOption, pvKw := commandLine.number pvOption,
    dailyLoadKwh := loadKwh, flexKwh }

def CommandLine.battery (commandLine : CommandLine) : Battery :=
  { capacityKwh := commandLine.number batteryOption, powerKw := commandLine.number powerOption }

/-- The value of a whole-number option. The reading step makes sure that the value is whole,
and the range step makes sure that it is not negative. -/
def CommandLine.whole (commandLine : CommandLine) (option : NumberOption) : Nat :=
  (commandLine.number option).toUInt64.toNat

def CommandLine.simulate (commandLine : CommandLine) (strategy : Strategy) : Result :=
  StoragePolicySim.simulate commandLine.site commandLine.battery strategy
    (commandLine.whole seedOption) (commandLine.whole daysOption)

/-- The width of the label and its spaces in a line of `sim run`. -/
def labelWidth : Nat := 18

def labelledLine (label value : String) : String :=
  label ++ "".pushn ' ' (labelWidth - label.length) ++ value

/-- The 11 lines of `sim run`. -/
def runLines (commandLine : CommandLine) (totals : Totals) : List String :=
  let energy (label : String) (kwh : Float) := labelledLine label (oneDecimal kwh ++ " kWh")
  let ratio (label : String) (percent : Float) := labelledLine label (oneDecimal percent ++ " %")
  [labelledLine "strategy" commandLine.strategy.name,
   labelledLine "days" (toString (commandLine.whole daysOption)),
   labelledLine "seed" (toString (commandLine.whole seedOption)),
   energy "solar" totals.pvKwh, energy "load" totals.loadKwh,
   energy "self-used" totals.selfUsedKwh, energy "import" totals.importKwh,
   energy "export" totals.exportKwh, energy "losses" totals.lossKwh,
   ratio "self-consumption" totals.selfConsumption,
   ratio "self-sufficiency" totals.selfSufficiency]

/-- The header, and then a row for each list of fields. The first column aligns left, and
each other column aligns right under its header word. -/
def table (header : List String) (rows : List (List String)) : List String :=
  let alignedRow (fields : List String) : String :=
    let cells := (header.zip fields).zipIdx.map fun ((word, field), column) =>
      let spaces := "".pushn ' ' (word.length - field.length)
      if column == 0 then field ++ spaces else spaces ++ field
    " ".intercalate cells
  " ".intercalate header :: rows.map alignedRow

def monthHeader : List String :=
  ["month", "solar-kWh", "load-kWh", "import-kWh", "export-kWh", "self-consumption-%",
   "self-sufficiency-%"]

def monthRow (month : Month) : List String :=
  let totals := month.totals
  month.name :: [totals.pvKwh, totals.loadKwh, totals.importKwh, totals.exportKwh,
    totals.selfConsumption, totals.selfSufficiency].map oneDecimal

def compareHeader : List String :=
  ["strategy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh"]

def compareRow (strategy : Strategy) (totals : Totals) : List String :=
  strategy.name :: [totals.selfConsumption, totals.selfSufficiency, totals.importKwh,
    totals.exportKwh].map oneDecimal

/-- The stdout lines of a command with good options. -/
def output (command : Command) (commandLine : CommandLine) : List String :=
  match command with
  | .run =>
    let result := commandLine.simulate commandLine.strategy
    let monthTable := if commandLine.monthly
      then "" :: table monthHeader (result.months.toList.map monthRow) else []
    runLines commandLine result.totals ++ monthTable
  | .compare =>
    table compareHeader (Strategy.all.map fun strategy =>
      compareRow strategy (commandLine.simulate strategy).totals)

/-! ## The command -/

/-- The width of the option, its value and its spaces in a line of the usage. -/
def usageOptionWidth : Nat := 18

/-- A line of the usage: two spaces, the option and its value, spaces to fill
`usageOptionWidth`, and the meaning. -/
def usageLine (option meaning : String) : String :=
  "  " ++ option ++ "".pushn ' ' (usageOptionWidth - option.length) ++ meaning

def usage : List String :=
  let numberLine (option : NumberOption) :=
    usageLine s!"{option.flag} N" (s!"{option.meaning}. Default {boundText option.default}, " ++
      s!"range {boundText option.lowest} to {boundText option.highest}.")
  ["usage: sim run [options] | sim compare [options]",
   "",
   "sim run simulates one strategy and prints the totals.",
   "sim compare simulates each strategy on the same weather.",
   "",
   "Options:",
   usageLine s!"{strategyFlag} NAME"
     s!"sim run only. Default {defaultStrategy.name}, one of {strategyNames}.",
   usageLine monthlyFlag "sim run only. Also prints the totals of each month."] ++
  rangedOptions.map numberLine ++
  [usageLine s!"{flexFlag} N" (s!"kWh of the daily load that a strategy can move. " ++
     s!"Default {boundText defaultFlexKwh}, or the --load value when that is less. " ++
     "Range 0 to the --load value.")]

/-- Reads the options of the command. The first problem gives the error. -/
def runCommand (command : Command) (words : List String) : Except Problem (List String) := do
  let commandLine ← readOptions command {} words
  match commandLine.rangeProblem? with
  | some problem => .error problem
  | none => .ok (output command commandLine)

def main (args : List String) : IO UInt32 := do
  let outcome : Except Problem (List String) := match args with
    | [] | "help" :: _ | "--help" :: _ => .ok usage
    | "run" :: words => runCommand .run words
    | "compare" :: words => runCommand .compare words
    | word :: _ => .error (.unknownCommand word)
  match outcome with
  | .ok lines =>
    IO.print (String.join (lines.map (· ++ "\n")))
    return 0
  | .error problem =>
    IO.eprintln problem.line
    return 2
````

### README.md

````
# storage-policy-sim

`storage-policy-sim` simulates a home solar system with a battery, hour by hour. The `sim`
command runs one battery strategy, or compares all strategies on the same weather.

## Build

Run this command in the root folder of the project:

```
lake build
```

The command is then at `.lake/build/bin/sim`. The toolchain is Lean 4.35.0.

## Commands

- `sim`, `sim help` and `sim --help` print the usage.
- `sim run [options]` simulates one strategy. The command prints 11 lines: the strategy,
  the days, the seed, the solar energy, the load, the self-used solar energy, the import,
  the export, the battery losses, the self-consumption and the self-sufficiency.
- `sim run --monthly [options]` prints the 11 lines, a blank line and a table. The table
  has one row for each month of the run, with the totals of that month.
- `sim compare [options]` simulates each strategy on the same weather. The command prints
  one row for each strategy: `none`, `greedy`, `evening` and `shift`. Each row gives the
  self-consumption, the self-sufficiency, the import and the export.

For example:

```
.lake/build/bin/sim run --lat 45 --pv 6
.lake/build/bin/sim run --monthly --strategy shift
.lake/build/bin/sim compare --seed 9 --battery 5
```

## Options

Each option takes one value, except `--monthly`. When you give an option two times, the
last value counts. `sim compare` takes each option except `--strategy` and `--monthly`.

| Option | Meaning | Default | Range |
|---|---|---|---|
| `--strategy` | The battery strategy (`sim run` only) | `greedy` | `none`, `greedy`, `evening` or `shift` |
| `--monthly` | Also print the totals of each month (`sim run` only) | off | no value |
| `--days` | The days to simulate, a whole number | 365 | 1 to 3650 |
| `--seed` | The seed of the weather, a whole number | 1 | 0 to 4294967295 |
| `--lat` | The latitude in degrees, south is negative | -41.3 | -90 to 90 |
| `--pv` | The kW of the solar panels | 5 | 0 to 100 |
| `--battery` | The kWh that the battery holds | 10 | 0 to 200 |
| `--power` | The kW into or out of the battery in one hour | 5 | 0 to 100 |
| `--load` | The kWh of household load each day | 20 | 0.1 to 1000 |
| `--flex` | The kWh of the daily load that a strategy can move | 3, or the `--load` value when that is less | 0 to the `--load` value |

A number has an optional sign, digits, and an optional point with more digits, for
example `-41.3` or `+3`. `--days` and `--seed` take only whole numbers.

## Repeatable weather

The `--seed` option sets the weather. The same seed and the same options give the same
output each time. Thus, when you change one other option, the result shows only the effect
of that option. The `--seed` option is the only seam for the checks. No output depends on
the clock.

## Errors

A bad command line prints one line on stderr and nothing on stdout. The exit code is 2.
The line is `error: <code>: <detail>`, for example `error: OUT_OF_RANGE: --days 0 (1 to 3650)`.

| Code | Cause |
|---|---|
| `UNKNOWN_COMMAND` | The first word is not `run`, `compare`, `help` or `--help` |
| `UNKNOWN_OPTION` | The command does not take the word |
| `MISSING_VALUE` | An option that needs a value comes last |
| `BAD_NUMBER` | A value is not a number of the right form |
| `OUT_OF_RANGE` | A number is outside the range of its option |
| `UNKNOWN_STRATEGY` | The strategy name is not in the list |

## Run the checks

Run this command in the root folder of the project:

```
lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done
```

The command builds the project and runs each check file in `tests/`.
````

### lakefile.toml

````
name = "storage-policy-sim"
version = "0.1.0"
defaultTargets = ["StoragePolicySim", "sim"]

[[lean_lib]]
name = "StoragePolicySim"
globs = ["StoragePolicySim.+"]

[[lean_exe]]
name = "sim"
root = "Main"
````

