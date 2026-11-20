# storage-policy-sim

`storage-policy-sim` simulates a home solar system with a battery, hour by hour. The `sim`
command runs one battery strategy, or compares all strategies on the same weather. The
command `sim policy run` simulates a home with a hot-water tank under one policy.

## Build

Run this command in the root folder of the project:

```
lake build
```

The command is then at `.lake/build/bin/sim`. The toolchain is Lean 4.35.0.

## Commands

- `sim`, `sim help` and `sim --help` print the usage. The first line of the usage is
  `sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]`.
- `sim run [options]` simulates one strategy. The command prints 11 lines: the strategy,
  the days, the seed, the solar energy, the load, the self-used solar energy, the import,
  the export, the battery losses, the self-consumption and the self-sufficiency.
- `sim run --monthly [options]` prints the 11 lines, a blank line and a table. The table
  has one row for each month of the run, with the totals of that month.
- `sim compare [options]` simulates each strategy on the same weather. The command prints
  one row for each strategy: `none`, `greedy`, `evening` and `shift`. Each row gives the
  self-consumption, the self-sufficiency, the import and the export.
- `sim policy` and `sim policy help` print the usage of `sim policy`.
- `sim policy run [options]` simulates one home with one policy. See "The policy command".
- Not built yet: `sim policy compare`, `sim policy robust`, `sim policy tune`,
  `sim policy plan` and `sim forecast`. Each of them prints `error: not implemented` on
  stderr and exits with 3.

For example:

```
.lake/build/bin/sim run --lat 45 --pv 6
.lake/build/bin/sim run --monthly --strategy shift
.lake/build/bin/sim compare --seed 9 --battery 5
.lake/build/bin/sim policy run --heat-start 11 --heat-hours 3
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

## The policy command

`sim policy run [options]` simulates the home `generic` (one flat array, a battery and one
hot-water tank) under one policy, from a full tank and an empty battery on 1 January. The
command prints 15 lines, one label and one value on each line: `policy`, `days`, `seed`,
`solar`, `load`, `import`, `export`, `curtailed`, `heating`, `backstop`, `unmet-hot-water`,
`cold-hours`, `starts-per-day`, `self-consumption` and `self-sufficiency`. The energy lines
are in kWh and the two ratio lines are in percent.

The policy `static` is built. The names `precomputed` and `dynamic` are accepted, and their
runs are not built yet.

Each option takes one value, and the last value counts. The options `--days`, `--seed`,
`--lat`, `--pv`, `--battery`, `--power`, `--load` and `--flex` are the same as in the table
above. The other options are these:

| Option | Meaning | Default | Range |
|---|---|---|---|
| `--policy` | The policy | `static` | `static`, `precomputed` or `dynamic` |
| `--tank` | The kWh that the tank holds | 10.5 | 0 to 50 |
| `--element` | The kW of the element | 3 | 0 to 20 |
| `--cut-in` | The kWh below which the thermostat cuts in | 5.25 | 0 to 50 |
| `--floor` | The kWh below which the tank is cold | 2.1 | 0 to 50 |
| `--draw` | The kWh of hot water each day | 6 | 0 to 100 |
| `--draw-cv` | The spread of the draw from day to day | 0.25 | 0 to 1 |
| `--fetches` | The forecast fetches each day, a whole number | 10 | 1 to 10 |
| `--forecast-error` | The scale of the forecast error | 1 | 0 to 5 |
| `--heat-start` | The hour that the heating starts, a whole number | 10 | 0 to 23 |
| `--heat-hours` | The hours of heating, a whole number | 4 | 0 to 24 |
| `--discharge-from` | The hour from which the battery may discharge, a whole number | 17 | 0 to 24 |
| `--flex-start` | The hour that the flexible load starts, a whole number | 18 | 0 to 23 |
| `--target` | The kWh that a policy heats the tank to | 10.5 | 0 to 50 |
| `--min-solar` | The kWh of forecast that an hour needs to heat | 0.5 | 0 to 10 |
| `--low` | The kWh below which a dynamic policy heats | 5.25 | 0 to 50 |

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
| `UNKNOWN_COMMAND` | The first word is not `run`, `compare`, `policy`, `forecast`, `help` or `--help`, or the word after `policy` is not `run`, `compare`, `robust`, `tune`, `plan` or `help` |
| `UNKNOWN_OPTION` | The command does not take the word |
| `MISSING_VALUE` | An option that needs a value comes last |
| `BAD_NUMBER` | A value is not a number of the right form |
| `OUT_OF_RANGE` | A number is outside the range of its option |
| `UNKNOWN_STRATEGY` | The strategy name is not in the list |
| `UNKNOWN_POLICY` | The name after `--policy` is not `static`, `precomputed` or `dynamic` (`sim policy run` only) |

## Run the checks

Run this command in the root folder of the project:

```
lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done
```

The command builds the project and runs each check file in `tests/`.
