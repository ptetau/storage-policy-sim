# Review packet · CH-0004-sim-command · visual

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: addad468029cde6a1fd762b4f3545b19d942e700

# Remit: visual

Default: yes

You judge the recording of the change: the frames of `review.gif`. The change passed its
checks and its code reviews already. You do not see the code or the checks.

The packet holds the acceptance lines of the change, the script of the recording
(`visual.json`), and the list of the frames. Read each frame.

- Each acceptance line of the change has one or more frames. The caption of its first
  frame starts with the requirement ID.
- Each frame shows what its caption claims, after its step. A blank frame, or a frame with
  the screen from before the step, is a problem.
- A caption with `setup:` after the ID only prepares a state. Its frame shows that state,
  and nothing more is necessary.
- When several frames share one caption, the last of them shows the claim. The frames
  before it show the steps toward it.
- Each part of a caption is visible on screen. A frame that shows less than its caption
  claims is a problem, also when the claim is probably true. Examples:
  - An exit code on screen comes from a different command, for example `wc` after a pipe.
  - The input is too small to show the effect, for example a limit of 7 on a file with 3
    words.
- The frames show the behaviour as a user meets it:
  - A web app: pages and clicks. A page cannot show a status code, a header, a redirect,
    or the target of a form. These show in a terminal frame of `curl -si`.
  - In a web app, a terminal frame that shows or searches the HTML of a page, in place of
    the page, is a `script` problem.
  - A CLI: commands and their output.
  - A library: a short script that calls the interface.
- An error on screen is a problem, unless its acceptance line asks for that error.
- Each recording ends with a frame that shows all checks pass.

Write each problem as `<frame> · <what is wrong> · <the acceptance line or rule> · <kind>`.
The kind is one of these:

- `script`: the recording is wrong. Examples are a wrong selector, a missing step, and a
  step that shows the screen from before the change. A frame that shows less than its
  caption claims is also a `script` problem.
- `app`: the step does what its acceptance line says, but the app does not meet the line.

Do not write follow-ups. Put a wish for new behaviour of the app under "Notes". A frame
that shows less than its caption claims is not a wish. It is a `script` problem.

On a re-review, judge only the frames that do not have the mark "unchanged since the
earlier review".

## The change spec

````
# CH-0004 · The sim command

Intent: IN-0001 · Scope: JOB-simulate · Status: in review · Ticket: none · Branch: pdlc/CH-0004-sim-command · Base: pdlc/CH-0003-simulation

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

Status: verified · Intents: IN-0001

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

Status: verified · Intents: IN-0001

`sim run --monthly` prints the 11 lines, a blank line, and a table with one row for each
month (assumed). The header is `month solar-kWh load-kWh import-kWh export-kWh
self-consumption-% self-sufficiency-%` with the columns aligned by spaces (assumed). Each
row starts with the short month name, for example `Jan`, and has seven fields.

- Given `--monthly`, when the person runs `sim run`, then the table has the header and 12 rows, from `Jan` to `Dec`.
- Given `--monthly --days 400`, when the person runs `sim run`, then the table has 14 rows. The last two rows are `Jan` and `Feb`.
- Given `--monthly --lat 45`, when the person runs `sim run`, then the `Jul` solar value is more than twice the `Dec` solar value.
- Given no `--monthly`, when the person runs `sim run`, then it prints only the 11 lines.

### JOB-simulate.R3 · Compare strategies

Status: verified · Intents: IN-0001

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

Status: verified · Intents: IN-0001

The seed sets the weather. The same options and seed give the same output each time.

- Given `--seed 5`, when the person runs `sim run` two times, then the two outputs are the same.
- Given `--seed 1` and `--seed 2`, when the person runs `sim run` with each, then the two `solar` values differ.

### JOB-simulate.R5 · Bad command line

Status: verified · Intents: IN-0001

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

## The script of the recording

````
{
  "kind": "terminal",
  "title": "CH-0004 \u00b7 The sim command",
  "width": 1100,
  "height": 680,
  "steps": [
    {
      "caption": "JOB-simulate \u00b7 setup: build the sim command",
      "run": "lake build 2>&1 | tail -1"
    },
    {
      "caption": "JOB-simulate.R1 \u00b7 sim run prints the 11 lines in order and exits with 0",
      "run": ".lake/build/bin/sim run; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R1 \u00b7 the first three lines are strategy greedy, days 365 and seed 1",
      "run": ".lake/build/bin/sim run | head -3"
    },
    {
      "caption": "JOB-simulate.R1 \u00b7 --pv 0: solar 0.0 kWh and self-consumption 0.0 %",
      "run": ".lake/build/bin/sim run --pv 0 | grep -E '^(solar|self-consumption) '"
    },
    {
      "caption": "JOB-simulate.R1 \u00b7 shift, 30 days, latitude 45: the values equal the library",
      "run": ".lake/build/bin/sim run --strategy shift --days 30 --lat 45 && lake env lean --run pdlc/changes/CH-0004-sim-command/library.lean"
    },
    {
      "caption": "JOB-simulate.R1 \u00b7 none, no battery: export equals solar less self-used",
      "run": ".lake/build/bin/sim run --strategy none --battery 0 | grep -E '^(solar|self-used|export) ' && .lake/build/bin/sim run --strategy none --battery 0 | awk '/^solar/{s=$2} /^self-used/{u=$2} /^export/{e=$2} END{print \"solar - self-used = \" s-u \", export = \" e}'"
    },
    {
      "caption": "JOB-simulate.R1 \u00b7 --days 3650 exits with 0 and shows 3650 days",
      "run": ".lake/build/bin/sim run --days 3650 | grep '^days'; echo \"exit ${PIPESTATUS[0]}\""
    },
    {
      "caption": "JOB-simulate.R2 \u00b7 --monthly: the header and 12 rows from Jan to Dec",
      "run": ".lake/build/bin/sim run --monthly | tail -13"
    },
    {
      "caption": "JOB-simulate.R2 \u00b7 --monthly --days 400: 14 rows, the last two Jan and Feb",
      "run": ".lake/build/bin/sim run --monthly --days 400 | tail -15"
    },
    {
      "caption": "JOB-simulate.R2 \u00b7 --monthly --lat 45: Jul solar is more than twice Dec solar",
      "run": ".lake/build/bin/sim run --monthly --lat 45 | grep -E '^(month|Jul|Dec) '"
    },
    {
      "caption": "JOB-simulate.R2 \u00b7 without --monthly, sim run prints only the 11 lines",
      "run": ".lake/build/bin/sim run | wc -l"
    },
    {
      "caption": "JOB-simulate.R3 \u00b7 sim compare: the header and none, greedy, evening, shift",
      "run": ".lake/build/bin/sim compare; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R3 \u00b7 --seed 9 --lat 45: the greedy row equals sim run",
      "run": ".lake/build/bin/sim compare --seed 9 --lat 45 | grep -E '^(strategy|greedy) ' && .lake/build/bin/sim run --seed 9 --lat 45 | grep -E '^(import|export|self-)'"
    },
    {
      "caption": "JOB-simulate.R3 \u00b7 --lat 45: greedy has more self-consumption than none",
      "run": ".lake/build/bin/sim compare --lat 45 | grep -E '^(strategy|none|greedy) '"
    },
    {
      "caption": "JOB-simulate.R3 \u00b7 sim compare --strategy greedy gives UNKNOWN_OPTION, exit 2",
      "run": ".lake/build/bin/sim compare --strategy greedy 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R4 \u00b7 --seed 5 two times gives the same output",
      "run": ".lake/build/bin/sim run --seed 5 > /tmp/a.txt; .lake/build/bin/sim run --seed 5 > /tmp/b.txt; cmp /tmp/a.txt /tmp/b.txt && echo 'the two outputs are the same'"
    },
    {
      "caption": "JOB-simulate.R4 \u00b7 --seed 1 and --seed 2 give different solar values",
      "run": ".lake/build/bin/sim run --seed 1 | grep '^solar'; .lake/build/bin/sim run --seed 2 | grep '^solar'"
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 sim prints the usage and exits with 0",
      "run": ".lake/build/bin/sim | head -1; echo \"exit ${PIPESTATUS[0]}\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 sim help prints the same usage and exits with 0",
      "run": ".lake/build/bin/sim help | head -1; echo \"exit ${PIPESTATUS[0]}\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 sim --help prints the same usage and exits with 0",
      "run": ".lake/build/bin/sim --help | head -1; echo \"exit ${PIPESTATUS[0]}\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 sim fly gives UNKNOWN_COMMAND, exit 2",
      "run": ".lake/build/bin/sim fly 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --colour red gives UNKNOWN_OPTION, exit 2",
      "run": ".lake/build/bin/sim run --colour red 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days with no value gives MISSING_VALUE, exit 2",
      "run": ".lake/build/bin/sim run --days 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days abc gives BAD_NUMBER, exit 2",
      "run": ".lake/build/bin/sim run --days abc 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days \"\" gives BAD_NUMBER, exit 2",
      "run": ".lake/build/bin/sim run --days \"\" 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days 36.5 gives BAD_NUMBER, exit 2",
      "run": ".lake/build/bin/sim run --days 36.5 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --pv 1e3, .5, 5. and 5kW each give BAD_NUMBER, exit 2",
      "run": ".lake/build/bin/sim run --pv 1e3 2>&1; echo \"exit $?\"; .lake/build/bin/sim run --pv .5 2>&1; echo \"exit $?\"; .lake/build/bin/sim run --pv 5. 2>&1; echo \"exit $?\"; .lake/build/bin/sim run --pv 5kW 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --pv +3 exits with 0 and equals --pv 3",
      "run": ".lake/build/bin/sim run --pv +3 > /tmp/a.txt; echo \"exit $?\"; .lake/build/bin/sim run --pv 3 > /tmp/b.txt; cmp /tmp/a.txt /tmp/b.txt && echo 'the same result as --pv 3'"
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days 0 gives OUT_OF_RANGE (1 to 3650), exit 2",
      "run": ".lake/build/bin/sim run --days 0 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days 3651 gives OUT_OF_RANGE (1 to 3650), exit 2",
      "run": ".lake/build/bin/sim run --days 3651 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days 99999999999999999999 gives OUT_OF_RANGE, exit 2",
      "run": ".lake/build/bin/sim run --days 99999999999999999999 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --seed -1 gives OUT_OF_RANGE (0 to 4294967295), exit 2",
      "run": ".lake/build/bin/sim run --seed -1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --seed 4294967295 exits with 0, and 4294967296 is out of range",
      "run": ".lake/build/bin/sim run --seed 4294967295 >/dev/null; echo \"--seed 4294967295: exit $?\"; .lake/build/bin/sim run --seed 4294967296 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --lat 90 and --lat -90 each exit with 0",
      "run": ".lake/build/bin/sim run --lat 90 >/dev/null; echo \"--lat 90: exit $?\"; .lake/build/bin/sim run --lat -90 >/dev/null; echo \"--lat -90: exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --lat 90.1 and --lat -90.1 each give OUT_OF_RANGE, exit 2",
      "run": ".lake/build/bin/sim run --lat 90.1 2>&1; echo \"exit $?\"; .lake/build/bin/sim run --lat -90.1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --pv 100 exits with 0, and --pv 100.1 is out of range",
      "run": ".lake/build/bin/sim run --pv 100 >/dev/null; echo \"--pv 100: exit $?\"; .lake/build/bin/sim run --pv 100.1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --pv -1 gives OUT_OF_RANGE (0 to 100), exit 2",
      "run": ".lake/build/bin/sim run --pv -1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --battery 200 exits with 0, and 200.1 is out of range",
      "run": ".lake/build/bin/sim run --battery 200 >/dev/null; echo \"--battery 200: exit $?\"; .lake/build/bin/sim run --battery 200.1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --power 100 exits with 0, and 100.1 is out of range",
      "run": ".lake/build/bin/sim run --power 100 >/dev/null; echo \"--power 100: exit $?\"; .lake/build/bin/sim run --power 100.1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --load 0.1 exits with 0, and --load 0 is out of range",
      "run": ".lake/build/bin/sim run --load 0.1 >/dev/null; echo \"--load 0.1: exit $?\"; .lake/build/bin/sim run --load 0 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --load 1000 exits with 0, and 1000.1 is out of range",
      "run": ".lake/build/bin/sim run --load 1000 >/dev/null; echo \"--load 1000: exit $?\"; .lake/build/bin/sim run --load 1000.1 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --load 10 --flex 10 exits with 0",
      "run": ".lake/build/bin/sim run --load 10 --flex 10 >/dev/null; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --load 10 --flex 10.5 gives OUT_OF_RANGE (0 to 10), exit 2",
      "run": ".lake/build/bin/sim run --load 10 --flex 10.5 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --strategy wild gives UNKNOWN_STRATEGY, exit 2",
      "run": ".lake/build/bin/sim run --strategy wild 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 sim run now gives UNKNOWN_OPTION, exit 2",
      "run": ".lake/build/bin/sim run now 2>&1; echo \"exit $?\""
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 --days 10 --days 20 shows 20 days",
      "run": ".lake/build/bin/sim run --days 10 --days 20 | grep '^days'"
    },
    {
      "caption": "JOB-simulate.R5 \u00b7 each error above prints nothing on stdout",
      "run": "for a in 'fly' 'run --colour red' 'run --days' 'run --days abc' 'run --days 0' 'run --seed -1' 'run --pv -1' 'run --load 10 --flex 10.5' 'run --strategy wild' 'run now' 'compare --strategy greedy'; do printf '%-28s stdout bytes: ' \"$a\"; .lake/build/bin/sim $a 2>/dev/null | wc -c; done"
    },
    {
      "caption": "CH-0004 \u00b7 all checks and the acceptance checks pass",
      "run": "for f in tests/*.lean tests/acceptance/IN-0001.acceptance.lean; do lake env lean --run \"$f\" | grep 'checks,'; done"
    }
  ]
}
````

## The frames

Read each frame:

- pdlc/changes/CH-0004-sim-command/frames/01.png
- pdlc/changes/CH-0004-sim-command/frames/02.png
- pdlc/changes/CH-0004-sim-command/frames/03.png
- pdlc/changes/CH-0004-sim-command/frames/04.png
- pdlc/changes/CH-0004-sim-command/frames/05.png
- pdlc/changes/CH-0004-sim-command/frames/06.png
- pdlc/changes/CH-0004-sim-command/frames/07.png
- pdlc/changes/CH-0004-sim-command/frames/08.png
- pdlc/changes/CH-0004-sim-command/frames/09.png
- pdlc/changes/CH-0004-sim-command/frames/10.png
- pdlc/changes/CH-0004-sim-command/frames/11.png
- pdlc/changes/CH-0004-sim-command/frames/12.png
- pdlc/changes/CH-0004-sim-command/frames/13.png
- pdlc/changes/CH-0004-sim-command/frames/14.png
- pdlc/changes/CH-0004-sim-command/frames/15.png
- pdlc/changes/CH-0004-sim-command/frames/16.png
- pdlc/changes/CH-0004-sim-command/frames/17.png
- pdlc/changes/CH-0004-sim-command/frames/18.png
- pdlc/changes/CH-0004-sim-command/frames/19.png
- pdlc/changes/CH-0004-sim-command/frames/20.png
- pdlc/changes/CH-0004-sim-command/frames/21.png
- pdlc/changes/CH-0004-sim-command/frames/22.png
- pdlc/changes/CH-0004-sim-command/frames/23.png
- pdlc/changes/CH-0004-sim-command/frames/24.png
- pdlc/changes/CH-0004-sim-command/frames/25.png
- pdlc/changes/CH-0004-sim-command/frames/26.png
- pdlc/changes/CH-0004-sim-command/frames/27.png
- pdlc/changes/CH-0004-sim-command/frames/28.png
- pdlc/changes/CH-0004-sim-command/frames/29.png
- pdlc/changes/CH-0004-sim-command/frames/30.png
- pdlc/changes/CH-0004-sim-command/frames/31.png
- pdlc/changes/CH-0004-sim-command/frames/32.png
- pdlc/changes/CH-0004-sim-command/frames/33.png
- pdlc/changes/CH-0004-sim-command/frames/34.png
- pdlc/changes/CH-0004-sim-command/frames/35.png
- pdlc/changes/CH-0004-sim-command/frames/36.png
- pdlc/changes/CH-0004-sim-command/frames/37.png
- pdlc/changes/CH-0004-sim-command/frames/38.png
- pdlc/changes/CH-0004-sim-command/frames/39.png
- pdlc/changes/CH-0004-sim-command/frames/40.png
- pdlc/changes/CH-0004-sim-command/frames/41.png
- pdlc/changes/CH-0004-sim-command/frames/42.png
- pdlc/changes/CH-0004-sim-command/frames/43.png
- pdlc/changes/CH-0004-sim-command/frames/44.png
- pdlc/changes/CH-0004-sim-command/frames/45.png
- pdlc/changes/CH-0004-sim-command/frames/46.png
- pdlc/changes/CH-0004-sim-command/frames/47.png
- pdlc/changes/CH-0004-sim-command/frames/48.png
