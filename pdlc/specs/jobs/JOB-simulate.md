# JOB-simulate · Simulate a year of solar and compare strategies

Status: active

## Who and why

A person who plans a home solar system runs `sim` in a terminal. They run one strategy over
seasons and weather with `sim run`, and see the self-consumption and self-sufficiency.
They add `--monthly` to see each month. They compare all strategies on the same weather
with `sim compare`. The same `--seed` gives the same weather, so that each change of an
option is a fair test.

They also plan the daily profile of a hot-water tank and a battery. They see the simulated
Solcast forecast of a fetch with `sim forecast`. They run one policy with `sim policy run`, and
compare a thermostat-only baseline with the static, the precomputed and the dynamic policy
with `sim policy compare`. They test a policy over many seeds with `sim policy robust`, and
search for the best static profile with `sim policy tune`.

## Relies on

- Capabilities: CAP-scenario (sun, weather and load), CAP-strategies (battery and load strategies), CAP-simulation (hourly energy flows), CAP-forecast (simulated Solcast forecasts), CAP-hotwater (hot-water tank), CAP-policy (daily-profile policies), CAP-homesim (home simulation)
- Design: DES-errors (error codes), DES-writing-style (writing rules)

## Code map

- `Main.lean`
- `StoragePolicySim/PolicyCommands.lean`
- `lakefile.toml: the sim executable`

## Interface

- `sim [help | --help]` · command · `Main.lean` · proposed
  - in: no argument, `help` or `--help`, or the name of a command
  - out: on standard output, the usage. The first line is `usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]`. Then the options follow, each on a line. The exit code is 0.
  - errors:
    - `UNKNOWN_COMMAND` · `error: UNKNOWN_COMMAND: <word>` · exit 2 · stderr
- `sim forecast [--hour H] [--lon L] [--forecast-error E] [--lat N] [--pv N] [--days N] [--seed N]` · command · `Main.lean` · proposed
  - in: the options, each with one value
  - out: on standard output, the Solcast JSON of CAP-forecast for one fetch, and a line break. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy [help]` · command · `Main.lean` · proposed
  - in: no argument, or `help`
  - out: on standard output, the line `usage: sim policy run|compare|robust|tune [options]` and the options. The exit code is 0.
  - errors:
    - `UNKNOWN_COMMAND` · `error: UNKNOWN_COMMAND: <word>` · exit 2 · stderr
- `sim policy run [--policy NAME] [policy options]` · command · `Main.lean` · proposed
  - in: the options, each with one value
  - out: on standard output, 13 lines. Each line is a label, spaces to column 19, and a value. The labels are `policy`, `days`, `seed`, `solar`, `load`, `import`, `export`, `heating`, `backstop`, `unmet-hot-water`, `cold-hours`, `self-consumption` and `self-sufficiency`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
    - `UNKNOWN_POLICY` · `error: UNKNOWN_POLICY: <name> (static, precomputed, dynamic)` · exit 2 · stderr
- `sim policy compare [policy options]` · command · `Main.lean` · proposed
  - in: the options, each with one value
  - out: on standard output, the header `policy self-consumption-% self-sufficiency-% import-kWh export-kWh backstop-kWh`, and one row for each of `thermostat`, `static`, `precomputed` and `dynamic`, in this order. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy robust [--seeds N] [policy options]` · command · `Main.lean` · proposed
  - in: the options, each with one value
  - out: on standard output, the header `policy mean-self-consumption-% worst-self-consumption-% mean-self-sufficiency-% mean-export-kWh mean-backstop-kWh unmet-kWh cold-hours safe`, and one row for each of `thermostat`, `static`, `precomputed` and `dynamic`, in this order. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean` · proposed
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr

### Test seams

- `--seed` · seam: randomness · `Main.lean` · proposed
  - in: a whole number. The same seed gives the same weather and the same forecast.
  - errors: none

## Requirements

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

Status: ready · Intents: IN-0001, IN-0008

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

- Given no arguments, when the person runs `sim`, then the first line on stdout is `usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]`. The exit code is 0.
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

### JOB-simulate.R6 · Forecast command

Status: ready · Intents: IN-0008

`sim forecast` prints on stdout the Solcast JSON of CAP-forecast (simulated Solcast
forecasts) for one fetch, then a line break, and exits with 0. `--hour` gives the hour of the
run of the fetch, with the default 0 (assumed). Its range is 0 to 24 × days less 1, and the
value is a whole number. `--lon` is the longitude in degrees, east is positive, with the
default 174.8 and the range -180 to 180 (assumed). `--forecast-error` is the error scale, with
the default 1 and the range 0 to 5 (assumed). The command also takes `--lat`, `--pv`, `--days`
and `--seed` of `sim run`, with the same defaults and ranges. Any other option is an unknown
option.

- Given no options, when the person runs `sim forecast`, then stdout starts with `{"forecasts":[{"pv_estimate":` and has 96 periods.
- Given no options, when the person runs `sim forecast`, then the first `period_end` is `2024-12-31T13:00:00.0000000Z`.
- Given `--lon 0`, when the person runs `sim forecast`, then the first `period_end` is `2025-01-01T00:30:00.0000000Z`.
- Given `--hour 8759`, when the person runs `sim forecast`, then the JSON has 2 periods.
- Given `--forecast-error 0 --lat 45 --hour 4116`, when the person runs `sim forecast`, then each `pv_estimate10` and `pv_estimate90` equals its `pv_estimate`.
- Given `--seed 3 --hour 4116`, when the person runs `sim forecast` two times, then the two outputs are the same.
- Given `--hour 8760`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 8760 (0 to 8759)`. The exit code is 2.
- Given `--days 2 --hour 48`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 48 (0 to 47)`. The exit code is 2.
- Given `--hour abc`, when the person runs `sim forecast`, then stderr is `error: BAD_NUMBER: --hour abc`. The exit code is 2.
- Given `--hour 2.5`, when the person runs `sim forecast`, then stderr is `error: BAD_NUMBER: --hour 2.5`. The exit code is 2.
- Given `--hour` with no value, when the person runs `sim forecast`, then stderr is `error: MISSING_VALUE: --hour`. The exit code is 2.
- Given `--lon 180.1`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --lon 180.1 (-180 to 180)`. The exit code is 2. `--lon 180` and `--lon -180` exit with 0.
- Given `--forecast-error 5.1`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)`. The exit code is 2. `--forecast-error 5` and `--forecast-error 0` exit with 0.
- Given `--strategy greedy`, when the person runs `sim forecast`, then stderr is `error: UNKNOWN_OPTION: --strategy`. The exit code is 2.
- Given `--battery 5`, when the person runs `sim forecast`, then stderr is `error: UNKNOWN_OPTION: --battery`. The exit code is 2.
- Given each error above, when the person runs the command, then stdout is empty.

### JOB-simulate.R7 · Policy run

Status: ready · Intents: IN-0008

`sim policy run` simulates one policy for a home with a hot-water tank, prints the result on
stdout, and exits with 0. Each line is a label, spaces to column 19, and a value (assumed). An
energy has one decimal and `kWh`, and a ratio has one decimal and `%`. The lines are `policy`
(the name), `days`, `seed`, `solar`, `load`, `import`, `export`, `heating` (the heating that the
policy asked for and the tank took), `backstop`, `unmet-hot-water`, `cold-hours` (a whole
number), `self-consumption` and `self-sufficiency`, in this order. The `load` line includes the
heating and the backstop heating.

The options are those of `sim run` except `--strategy` and `--monthly`, and these options. The
defaults are those of CAP-homesim (home simulation) and CAP-policy (daily-profile policies):

- `--policy`: `static`, `precomputed` or `dynamic`. Default `static`.
- `--tank` (kWh), `--element` (kW), `--floor` (kWh) and `--draw` (kWh of hot water each day): 10.5, 3.0, 3.0 and 6.0.
- `--fetches` and `--forecast-error`: 10 and 1.
- `--heat-start`, `--heat-hours` and `--discharge-from` of the static policy: 10, 4 and 17.
- `--target` (kWh) and `--min-solar` (kWh) of the precomputed policy: 9.0 and 0.5.
- `--low` (kWh) of the dynamic policy: 4.0. The precomputed policy and the dynamic policy also use `--discharge-from`, and the dynamic policy also uses `--target`.

- Given no options, when the person runs `sim policy run`, then it prints the 13 lines in order and exits with 0.
- Given no options, when the person runs `sim policy run`, then the first three lines are `policy            static`, `days              365` and `seed              1`.
- Given `--policy dynamic --days 30 --lat 45 --seed 9`, when the person runs `sim policy run`, then the lines show `dynamic`, 30 days and seed 9. The values equal the totals of CAP-homesim (home simulation) for these options.
- Given `--policy precomputed --target 8 --min-solar 1`, when the person runs `sim policy run`, then the values equal the totals of CAP-homesim for the precomputed policy with this target and this minimum.
- Given `--heat-hours 0`, when the person runs `sim policy run`, then the `heating` line is `heating           0.0 kWh` and the `backstop` value is more than 0.0 kWh.
- Given `--tank 0`, when the person runs `sim policy run`, then the `unmet-hot-water` value is 2190.0 kWh, within 0.1 kWh, and the `heating` and `backstop` values are 0.0 kWh.
- Given `--element 0.2 --heat-hours 0 --days 90`, when the person runs `sim policy run`, then the `unmet-hot-water` value is more than 0.0 kWh and the `cold-hours` value is more than 0.
- Given no options, when the person runs `sim policy run`, then the `unmet-hot-water` line is `unmet-hot-water   0.0 kWh` and the `cold-hours` line is `cold-hours        0`.
- Given `--seed 5`, when the person runs `sim policy run` two times, then the two outputs are the same.
- Given `--policy wild`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)`. The exit code is 2. A name that differs by its case, such as `Static`, gives the same error.
- Given `--seeds 3`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_OPTION: --seeds`. The exit code is 2. `--strategy` and `--monthly` give `UNKNOWN_OPTION` too.
- Given each error above, when the person runs the command, then stdout is empty.

### JOB-simulate.R8 · Policy compare

Status: ready · Intents: IN-0008

`sim policy compare` runs four policies on the same weather, and prints one row for each. The
`thermostat` policy is the static policy with 0 heating hours, so the tank gets only the
backstop heating. The other rows are the static, the precomputed and the dynamic policy. The
header, which is a guess (assumed), is `policy self-consumption-% self-sufficiency-% import-kWh
export-kWh backstop-kWh`. The columns align by spaces. The command takes the options of `sim policy run`
except `--policy` and `--seeds`.

- Given no options, when the person runs `sim policy compare`, then it prints the header and the rows `thermostat`, `static`, `precomputed` and `dynamic`, in this order, and exits with 0.
- Given `--seed 9 --lat 45 --days 90`, when the person runs `sim policy compare`, then each row shows the values of CAP-homesim (home simulation) for its policy and these options, with one decimal.
- Given `--seed 9 --lat 45`, when the person runs `sim policy compare`, then the `static` row shows the same five values as `sim policy run --seed 9 --lat 45`.
- Given `--heat-hours 0`, when the person runs `sim policy compare`, then the `static` row shows the same five values as the `thermostat` row.
- Given no options, when the person runs `sim policy compare`, then the `static` self-consumption is more than the `thermostat` self-consumption, and so is the `dynamic` self-consumption.
- Given `--policy static`, when the person runs `sim policy compare`, then stderr is `error: UNKNOWN_OPTION: --policy`. The exit code is 2. `--seeds 3` gives `error: UNKNOWN_OPTION: --seeds`.

### JOB-simulate.R9 · Policy robust

Status: ready · Intents: IN-0008

`sim policy robust` evaluates the four policies of R8 over many weather seeds, from `--seed`,
and prints one row for each. The header is `policy mean-self-consumption-%
worst-self-consumption-% mean-self-sufficiency-% mean-export-kWh mean-backstop-kWh unmet-kWh
cold-hours safe` (assumed). `unmet-kWh` is the total unmet draw. `safe` is `yes` when no seed has an
unmet draw and `cold-hours` is 0, and else `no`. `--seeds` is the count of seeds, a whole number
from 1 to 100, with the default 10 (assumed). The command takes the options of `sim policy compare` and `--seeds`.

- Given no options, when the person runs `sim policy robust`, then it prints the header and the rows `thermostat`, `static`, `precomputed` and `dynamic`, in this order, and exits with 0.
- Given no options, when the person runs `sim policy robust`, then each row shows the values of CAP-homesim (home simulation) for the evaluation over the seeds 1 to 10, with one decimal.
- Given `--seeds 1 --seed 4`, when the person runs `sim policy robust`, then the mean and the worst self-consumption of each row are the self-consumption of the same row of `sim policy compare --seed 4`.
- Given no options, when the person runs `sim policy robust`, then the worst self-consumption of each row is not more than its mean.
- Given no options, when the person runs `sim policy robust`, then each row has `unmet-kWh` 0.0, `cold-hours` 0 and `safe` `yes`.
- Given `--element 0.2 --days 90`, when the person runs `sim policy robust`, then the `thermostat` row has `safe` `no`, and its `unmet-kWh` is more than 0.0.
- Given `--seed 7 --seeds 3` two times, when the person runs `sim policy robust`, then the two outputs are the same.
- Given `--seeds 0`, when the person runs `sim policy robust`, then stderr is `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. The exit code is 2. `--seeds 101` gives `error: OUT_OF_RANGE: --seeds 101 (1 to 100)`, and `--seeds 100` exits with 0.
- Given `--seeds 2.5`, when the person runs `sim policy robust`, then stderr is `error: BAD_NUMBER: --seeds 2.5`. The exit code is 2.

### JOB-simulate.R10 · Policy tune

Status: ready · Intents: IN-0008

`sim policy tune` searches the best static profile (CAP-homesim, R6), and prints it. The
first five lines are `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`,
each as a label, spaces to column 19, and a whole number. Then comes a blank line, and the
table of `sim policy robust` for the same options, with the best static profile in the row
`static`. `--seeds` has the default 5 (assumed). The command takes the options of `sim policy
robust` except `--heat-start`, `--heat-hours` and `--discharge-from`, which the search sets.

- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the first lines are `candidates        704` and `safe              704`, and the command exits with 0.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then `heat-start` is from 6 to 16, `heat-hours` is from 1 to 8, and `discharge-from` is from 15 to 22.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the profile equals the best profile of CAP-homesim (home simulation) for these options.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the `static` row equals the `static` row of `sim policy robust` with the same options and the profile as `--heat-start`, `--heat-hours` and `--discharge-from`.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the `thermostat`, `precomputed` and `dynamic` rows equal the same rows of `sim policy robust` with the same options.
- Given `--seeds 2 --days 30` two times, when the person runs `sim policy tune`, then the two outputs are the same.
- Given `--heat-start 10`, when the person runs `sim policy tune`, then stderr is `error: UNKNOWN_OPTION: --heat-start`. The exit code is 2. `--heat-hours 4` and `--discharge-from 17` give `UNKNOWN_OPTION` too.
- Given `--seeds 0`, when the person runs `sim policy tune`, then stderr is `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. The exit code is 2.

### JOB-simulate.R11 · Policy options

Status: ready · Intents: IN-0008

The options of the policy commands follow the number rules of R5 (bad command line): a sign,
digits, and an optional point with digits. The options that count things are whole numbers. The
last value of an option counts. A range error shows the range as `(<lowest> to <highest>)`. The
ranges of the policy options are these (assumed):

| Option | Lowest | Highest | Whole |
|---|---|---|---|
| `--tank` | 0 | 50 | no |
| `--element` | 0 | 20 | no |
| `--floor` | 0 | 50 | no |
| `--draw` | 0 | 100 | no |
| `--fetches` | 1 | 10 | yes |
| `--forecast-error` | 0 | 5 | no |
| `--heat-start` | 0 | 23 | yes |
| `--heat-hours` | 0 | 24 | yes |
| `--discharge-from` | 0 | 24 | yes |
| `--target` | 0 | 50 | no |
| `--min-solar` | 0 | 10 | no |
| `--low` | 0 | 50 | no |

- Given `--tank 0` and `--tank 50`, when the person runs `sim policy run`, then each exits with 0. `--tank 50.1` gives `error: OUT_OF_RANGE: --tank 50.1 (0 to 50)` and exit code 2.
- Given `--element 0` and `--element 20`, when the person runs `sim policy run`, then each exits with 0. `--element 20.1` gives `error: OUT_OF_RANGE: --element 20.1 (0 to 20)` and exit code 2.
- Given `--floor 0` and `--floor 50`, when the person runs `sim policy run`, then each exits with 0. `--floor 50.1` gives `error: OUT_OF_RANGE: --floor 50.1 (0 to 50)` and exit code 2.
- Given `--draw 0` and `--draw 100`, when the person runs `sim policy run`, then each exits with 0. `--draw 100.1` gives `error: OUT_OF_RANGE: --draw 100.1 (0 to 100)` and exit code 2.
- Given `--fetches 1` and `--fetches 10`, when the person runs `sim policy run --policy precomputed`, then each exits with 0. `--fetches 0` gives `error: OUT_OF_RANGE: --fetches 0 (1 to 10)` and `--fetches 11` gives `error: OUT_OF_RANGE: --fetches 11 (1 to 10)`. The exit code is 2.
- Given `--forecast-error 0` and `--forecast-error 5`, when the person runs `sim policy run`, then each exits with 0. `--forecast-error 5.1` gives `error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)` and exit code 2.
- Given `--heat-start 0` and `--heat-start 23`, when the person runs `sim policy run`, then each exits with 0. `--heat-start 24` gives `error: OUT_OF_RANGE: --heat-start 24 (0 to 23)` and exit code 2.
- Given `--heat-hours 0` and `--heat-hours 24`, when the person runs `sim policy run`, then each exits with 0. `--heat-hours 25` gives `error: OUT_OF_RANGE: --heat-hours 25 (0 to 24)` and exit code 2.
- Given `--discharge-from 0` and `--discharge-from 24`, when the person runs `sim policy run`, then each exits with 0. `--discharge-from 25` gives `error: OUT_OF_RANGE: --discharge-from 25 (0 to 24)` and exit code 2.
- Given `--target 0` and `--target 50`, when the person runs `sim policy run --policy dynamic`, then each exits with 0. `--target 50.1` gives `error: OUT_OF_RANGE: --target 50.1 (0 to 50)` and exit code 2.
- Given `--min-solar 0` and `--min-solar 10`, when the person runs `sim policy run --policy precomputed`, then each exits with 0. `--min-solar 10.1` gives `error: OUT_OF_RANGE: --min-solar 10.1 (0 to 10)` and exit code 2.
- Given `--low 0` and `--low 50`, when the person runs `sim policy run --policy dynamic`, then each exits with 0. `--low 50.1` gives `error: OUT_OF_RANGE: --low 50.1 (0 to 50)` and exit code 2.
- Given `--heat-hours 2.5`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --heat-hours 2.5`. The exit code is 2. `--fetches 2.5`, `--heat-start 1.5` and `--discharge-from 17.5` give the same error with their own option and value.
- Given `--tank abc`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --tank abc`. The exit code is 2. `--element 1e3`, `--floor .5` and `--draw 5kW` give `BAD_NUMBER` with their own option and value.
- Given `--tank` with no value, when the person runs `sim policy run`, then stderr is `error: MISSING_VALUE: --tank`. The exit code is 2.
- Given `--tank -1`, when the person runs `sim policy run`, then stderr is `error: OUT_OF_RANGE: --tank -1 (0 to 50)`. The exit code is 2.
- Given `--tank 5 --tank 12`, when the person runs `sim policy run`, then the result equals the result of `--tank 12`.
- Given `--heat-start 20 --heat-hours 10`, when the person runs `sim policy run`, then it exits with 0, because the window stops at the end of the day.
- Given `sim policy fly`, when the person runs it, then stderr is `error: UNKNOWN_COMMAND: policy fly`. The exit code is 2. `sim policy` and `sim policy help` print the line `usage: sim policy run|compare|robust|tune [options]` first and exit with 0.
- Given each error above, when the person runs the command, then stdout is empty.

