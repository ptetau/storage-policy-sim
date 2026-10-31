# JOB-simulate · Simulate a year of solar and compare strategies

Status: active

## Who and why

A person who plans a home solar system runs `sim` in a terminal. They run one strategy over
seasons and weather with `sim run`, and see the self-consumption and self-sufficiency.
They add `--monthly` to see each month. They compare all strategies on the same weather
with `sim compare`. The same `--seed` gives the same weather, so that each change of an
option is a fair test. They see the simulated Solcast forecast of a fetch with `sim forecast`.
They set the fetches each day, the forecast error and the longitude with `--fetches`,
`--forecast-error` and `--lon`.

## Relies on

- Capabilities: CAP-scenario (sun, weather and load), CAP-strategies (battery and load strategies), CAP-simulation (hourly energy flows), CAP-forecast (simulated Solcast forecasts)
- Design: DES-errors (error codes), DES-writing-style (writing rules)

## Code map

- `Main.lean`
- `lakefile.toml: the sim executable`

## Requirements

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

Status: ready · Intents: IN-0001, IN-0002

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

- Given no arguments, when the person runs `sim`, then the first line on stdout is `usage: sim run [options] | sim compare [options] | sim forecast [options]`. The exit code is 0.
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

### JOB-simulate.R6 · Forecast options

Status: ready · Intents: IN-0002

`sim run` and `sim compare` take `--fetches` (fetches each day), `--forecast-error` (the error
scale) and `--lon` (degrees, east is positive). The defaults are 10, 1 and 174.8 (assumed).
The ranges are `--fetches` 1 to 10, whole numbers only, `--forecast-error` 0 to 5, and `--lon`
-180 to 180 (assumed). The output lines do not change.

- Given no forecast options, when the person runs `sim run --strategy shift`, then the output equals `sim run --strategy shift --fetches 10 --forecast-error 1`.
- Given `--strategy shift --lat 45`, when the person runs with `--forecast-error 0` and with `--forecast-error 3`, then the two `solar` values are the same.
- Given `--fetches 10` and `--fetches 1`, when the person runs `sim run`, then each exits with 0.
- Given `--fetches 0`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --fetches 0 (1 to 10)`. The exit code is 2.
- Given `--fetches 11`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --fetches 11 (1 to 10)`. The exit code is 2.
- Given `--fetches 2.5`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --fetches 2.5`. The exit code is 2.
- Given `--forecast-error 5` and `--forecast-error 0`, when the person runs `sim run`, then each exits with 0.
- Given `--forecast-error 5.1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)`. The exit code is 2.
- Given `--lon 180` and `--lon -180`, when the person runs `sim run`, then each exits with 0.
- Given `--lon 180.1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --lon 180.1 (-180 to 180)`. The exit code is 2.
- Given `--fetches`, `--forecast-error` and `--lon` in `sim compare`, when the person runs it, then it exits with 0.

### JOB-simulate.R7 · Forecast command

Status: ready · Intents: IN-0002

`sim forecast` prints on stdout the Solcast JSON of CAP-forecast (simulated Solcast
forecasts) for one fetch, then a line break, and exits with 0. `--hour` gives the hour of the
run, with the default 0 (assumed). The range of `--hour` is 0 to 24 × days less 1, whole
numbers only (assumed).

`sim forecast` takes each option of `sim run` except `--strategy`, `--monthly`, `--battery`
and `--power` (assumed).

- Given no options, when the person runs `sim forecast`, then stdout starts with `{"forecasts":[{"pv_estimate":` and has 96 periods.
- Given no options, when the person runs `sim forecast`, then the first `period_end` is `2024-12-31T13:00:00.0000000Z`.
- Given `--lon 0`, when the person runs `sim forecast`, then the first `period_end` is `2025-01-01T00:30:00.0000000Z`.
- Given `--hour 8759`, when the person runs `sim forecast`, then the JSON has 2 periods.
- Given `--hour 8760`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 8760 (0 to 8759)`. The exit code is 2.
- Given `--days 2 --hour 48`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 48 (0 to 47)`. The exit code is 2.
- Given `--forecast-error 0 --lat 45 --hour 4116`, when the person runs `sim forecast`, then each `pv_estimate10` and `pv_estimate90` equals its `pv_estimate`.
- Given `--seed 3 --hour 4116`, when the person runs `sim forecast` two times, then the two outputs are the same.
- Given `--hour abc`, when the person runs `sim forecast`, then stderr is `error: BAD_NUMBER: --hour abc`. The exit code is 2.
- Given `--hour 2.5`, when the person runs `sim forecast`, then stderr is `error: BAD_NUMBER: --hour 2.5`. The exit code is 2.
- Given `--hour -1`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour -1 (0 to 8759)`. The exit code is 2.
- Given `--hour` with no value, when the person runs `sim forecast`, then stderr is `error: MISSING_VALUE: --hour`. The exit code is 2.
- Given `--hour 3`, when the person runs `sim run`, then stderr is `error: UNKNOWN_OPTION: --hour`. The exit code is 2.
- Given `--strategy greedy`, when the person runs `sim forecast`, then stderr is `error: UNKNOWN_OPTION: --strategy`. The exit code is 2.
- Given `--battery 5`, when the person runs `sim forecast`, then stderr is `error: UNKNOWN_OPTION: --battery`. The exit code is 2.
