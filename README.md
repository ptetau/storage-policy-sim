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
- `sim forecast [options]` prints the Solcast JSON of one forecast fetch and a line break.
  See "The forecast command".
- `sim policy compare [options]` simulates `thermostat` (the static policy with 0 heating
  hours), `static`, `precomputed`, `dynamic` and `perfect-forecast` (the precomputed policy with
  a forecast error of 0) on the same weather. The command prints a header and one row for each
  policy: the self-consumption, the self-sufficiency, the import, the export, the curtailed
  energy, the backstop heating and the starts each day, as plain numbers with one decimal. It
  takes each option of `sim policy run` except `--policy`, which gives `UNKNOWN_OPTION`.
- `sim policy robust [options]` evaluates the five policies of `sim policy compare` over
  `--seeds` weather years (1 to 100, default 10) from `--seed`. The table has one row for each
  policy: the mean and the worst self-consumption, the mean self-sufficiency, the mean export,
  the mean backstop heating, the total unmet hot water, the cold hours, the starts each day, and
  `safe` (`yes` when no seed has an unmet draw and no hour is cold). It takes the options of
  `sim policy run` except `--policy`.
- `sim policy tune [options]` tries 704 static profiles (heating start 6 to 16, 1 to 8 heating
  hours, discharge from 15 to 22) over `--seeds` years (default 5), and prints the `goal`,
  `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from` of the best, a blank line,
  and the table of `sim policy robust` with that profile in the row `static`. `--goal` is
  `self-consumption` (the default) or `import`. The options `--heat-start`, `--heat-hours` and
  `--discharge-from` give `UNKNOWN_OPTION`. With the defaults it takes about 25 seconds.
- Not built yet: `sim policy plan`. It prints `error: not implemented` on stderr and exits
  with 3.

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

The three policies are built. The policy `static` repeats one heating window each day. The
policy `precomputed` plans each day at hour 0 from the forecast: it heats in the sunniest hours
with at least `--min-solar` kWh of forecast, until the tank reaches `--target`. The policy
`dynamic` decides each hour: it heats with the solar surplus up to `--target`, and heats below
`--low` when the forecast for the rest of the day is too small. The flexible load runs inside its
day: the static policy runs it in 3 parts from `--flex-start`, the precomputed policy in the 3
sunniest hours that the tanks leave, and the dynamic policy in the hours with a solar surplus and
from 20:00 at the latest. A policy starts the element of a tank at most 2 times in a day: the
precomputed policy plans at most 2 runs of hours, and the dynamic policy keeps heating a tank that
it started 2 times, from the grid too, rather than start a third time.

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
| `--flex-start` | The hour that the static policy starts the flexible load, a whole number | 18 | 0 to 23 |
| `--target` | The kWh that a policy heats the tank to | 10.5 | 0 to 50 |
| `--min-solar` | The kWh of forecast that an hour needs to heat | 0.5 | 0 to 10 |
| `--low` | The kWh below which a dynamic policy heats | 5.25 | 0 to 50 |
| `--inverter` | The kW of the inverter limit: the most that the house and the grid take together. 0 is no limit | 0 | 0 to 100 |
| `--export-limit` | The kW of the export limit. 0 is no limit | 0 | 0 to 100 |
| `--array` | A panel array `KW:DIRECTION:TILT`. The direction is the compass angle that the array faces (0 north, 90 east, 180 south, 270 west) and the tilt is in degrees from flat. The first `--array` replaces the flat array of `--pv`, and each later one adds an array | one flat array of `--pv` | KW 0 to 100, DIRECTION 0 to 360, TILT 0 to 90 |

The solar energy of the home is the sum of its arrays. The solar surplus goes to the battery
first, then to the grid (inside the export limit and the inverter limit), and only the rest is
`curtailed`. A value of `--array` without three numbers gives `BAD_NUMBER` with the value as typed.

### Homes and tanks

`--home NAME` sets every home value at once. The names are `generic` (the default, with the
values above), `small`, `family`, `no-battery` and `mine`. Another name gives `UNKNOWN_HOME` with
the name as typed and the list of names. Each other option on the line changes one value of the
home, whatever the order. `--pv` and `--array` replace the arrays of the home, and `--tank`,
`--element`, `--cut-in` and `--floor` change its first tank.

| Home | Panels | Battery | Tanks | Load, hot water each day |
|---|---|---|---|---|
| `generic` | one flat 5 kW array | 10 kWh, 5 kW | 10.5 kWh, 3 kW | 20 kWh, 6 kWh |
| `small` | one north 3 kW array at 30° | 5 kWh, 3 kW | 7.1 kWh, 2 kW | 12 kWh, 4 kWh |
| `family` | one north 8 kW array at 30° | 13.5 kWh, 5 kW | 15.7 kWh, 3 kW | 30 kWh, 10 kWh |
| `no-battery` | as `generic` | none | as `generic` | as `generic` |
| `mine` | five arrays of 14.88 kW; inverter limit 11 kW, export limit 10 kW | 13.5 kWh, 11 kW | 13.1 kWh, 3.3 kW and 9.4 kWh, 2.5 kW (58% and 42% of the draw) | 20 kWh, 11 kWh |

A tank of `small`, `family` and `mine` cuts in at half of its capacity and is cold below 20% of it.
`--tank2 KWH:ELEMENT:SHARE` sets a second tank, with a draw share from 0 to 1 (the first tank gets
the rest). The tanks have their own heating and backstop, and their elements can run in the same
hour. Where tanks compete for the same energy (the dynamic surplus, the sunny hours of the
precomputed plan), the tank with the lowest share of its capacity goes first, and a tie goes to the
first tank. `--heat-start` and `--heat-hours` give the window of each tank. `sim policy tune` over
more tanks searches the window of one tank at a time, then the discharge hour, and prints
`heat-start-2` and `heat-hours-2` for the second tank.

## The forecast command

`sim forecast [options]` prints the simulated Solcast JSON of the fetch at one hour of the run,
and a line break. The JSON holds 96 periods of 30 minutes (48 hours). The options are
`--lat`, `--pv`, `--days` and `--seed` as above, and these:

| Option | Meaning | Default | Range |
|---|---|---|---|
| `--hour` | The hour of the run of the fetch, a whole number | 0 | 0 to 24 × days - 1 |
| `--lon` | The longitude in degrees, east is positive | 174.8 | -180 to 180 |
| `--forecast-error` | The scale of the forecast error | 1 | 0 to 5 |

Any other option gives `UNKNOWN_OPTION`.

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
| `UNKNOWN_GOAL` | The name after `--goal` is not `self-consumption` or `import` (`sim policy tune` only) |

## Run the checks

Run this command in the root folder of the project:

```
lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done
```

The command builds the project and runs each check file in `tests/`.
