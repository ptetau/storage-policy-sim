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

## Requirements

### JOB-simulate.R1 · Run one strategy

Status: proposed · Intents: IN-0001

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
- `--load`: 20 (kWh each day). `--flex`: 3 (kWh of the daily load that can move).

- Given no options, when the person runs `sim run`, then it prints the 11 lines in order and exits with 0.
- Given no options, when the person runs `sim run`, then the first three lines are `strategy          greedy`, `days              365` and `seed              1`.
- Given `--pv 0`, when the person runs `sim run`, then the solar line is `solar             0.0 kWh`. The self-consumption line is `self-consumption  0.0 %`.
- Given `--strategy shift --days 30 --lat 45`, when the person runs `sim run`, then the lines show `shift` and 30 days. The values equal CAP-simulation (hourly energy flows) results for these options.
- Given `--strategy none --battery 0`, when the person runs `sim run`, then the `export` value equals `solar` less `self-used`, within 0.1 kWh.
- Given `--days 3650`, when the person runs `sim run`, then it exits with 0 and the `days` line shows 3650.

### JOB-simulate.R2 · Monthly table

Status: proposed · Intents: IN-0001

`sim run --monthly` prints the 11 lines, a blank line, and a table with one row for each
month (assumed). The header is `month solar-kWh load-kWh import-kWh export-kWh
self-consumption-% self-sufficiency-%` with the columns aligned by spaces (assumed). Each
row starts with the short month name, for example `Jan`, and has seven fields.

- Given `--monthly`, when the person runs `sim run`, then the table has the header and 12 rows, from `Jan` to `Dec`.
- Given `--monthly --days 400`, when the person runs `sim run`, then the table has 14 rows. The last two rows are `Jan` and `Feb`.
- Given `--monthly --lat 45`, when the person runs `sim run`, then the `Jul` solar value is more than twice the `Dec` solar value.
- Given no `--monthly`, when the person runs `sim run`, then it prints only the 11 lines.

### JOB-simulate.R3 · Compare strategies

Status: proposed · Intents: IN-0001

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

Status: proposed · Intents: IN-0001

The seed sets the weather. The same options and seed give the same output each time.

- Given `--seed 5`, when the person runs `sim run` two times, then the two outputs are the same.
- Given `--seed 1` and `--seed 2`, when the person runs `sim run` with each, then the two `solar` values differ.

### JOB-simulate.R5 · Bad command line

Status: proposed · Intents: IN-0001

A bad command line prints one error line on stderr, prints nothing on stdout, and exits
with 2 (assumed). The line is `error: <code>: <detail>` (assumed). `sim`, `sim help` and
`sim --help` print the usage on stdout and exit with 0.
