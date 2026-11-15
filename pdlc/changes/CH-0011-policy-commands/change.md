# CH-0011 · The forecast and policy commands

Intent: IN-0008 · Scope: JOB-simulate · Status: planned · Ticket: none · Branch: none · Base: main

Tests-Locked: none

## Delivers

A person runs `sim forecast` and `sim policy run`, `compare`, `robust` and `tune`. The usage lists the new commands, and each bad command line gives one coded error.

## Requirements

### JOB-simulate.R5 · Bad command line
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
- Given no options, when the person runs `sim policy run`, then it prints the 13 lines in order and exits with 0.
- Given no options, when the person runs `sim policy run`, then the first three lines are `policy            static`, `days              365` and `seed              1`.
- Given `--policy dynamic --days 30 --lat 45 --seed 9`, when the person runs `sim policy run`, then the lines show `dynamic`, 30 days and seed 9. The values equal the totals of CAP-homesim (home simulation) for these options.
- Given `--policy precomputed --target 8 --min-solar 1`, when the person runs `sim policy run`, then the values equal the totals of CAP-homesim for the precomputed policy with this target and this minimum.
- Given `--heat-hours 0`, when the person runs `sim policy run`, then the `heating` line is `heating           0.0 kWh` and the `backstop` value is more than 0.0 kWh.
- Given `--tank 0 --draw-cv 0`, when the person runs `sim policy run`, then the `unmet-hot-water` value is 2190.0 kWh, within 0.1 kWh, and the `heating` and `backstop` values are 0.0 kWh.
- Given `--element 0.2 --heat-hours 0 --days 90`, when the person runs `sim policy run`, then the `unmet-hot-water` value is more than 0.0 kWh and the `cold-hours` value is more than 0.
- Given no options, when the person runs `sim policy run`, then the `unmet-hot-water` line is `unmet-hot-water   0.0 kWh` and the `cold-hours` line is `cold-hours        0`.
- Given `--seed 5`, when the person runs `sim policy run` two times, then the two outputs are the same.
- Given `--policy wild`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)`. The exit code is 2. A name that differs by its case, such as `Static`, gives the same error.
- Given `--seeds 3`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_OPTION: --seeds`. The exit code is 2. `--strategy` and `--monthly` give `UNKNOWN_OPTION` too.
- Given each error above, when the person runs the command, then stdout is empty.

### JOB-simulate.R8 · Policy compare
- Given no options, when the person runs `sim policy compare`, then it prints the header and the rows `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order, and exits with 0.
- Given `--seed 9 --lat 45 --days 90`, when the person runs `sim policy compare`, then each row shows the values of CAP-homesim (home simulation) for its policy and these options, with one decimal.
- Given `--seed 9 --lat 45`, when the person runs `sim policy compare`, then the `static` row shows the same five values as `sim policy run --seed 9 --lat 45`.
- Given `--heat-hours 0`, when the person runs `sim policy compare`, then the `static` row shows the same five values as the `thermostat` row.
- Given `--forecast-error 0`, when the person runs `sim policy compare`, then the `perfect-forecast` row shows the same five values as the `precomputed` row.
- Given `--seed 9 --lat 45 --days 90`, when the person runs `sim policy compare`, then the `perfect-forecast` row shows the values of CAP-homesim for the precomputed policy with an error scale of 0.
- Given no options, when the person runs `sim policy compare`, then the `static` self-consumption is more than the `thermostat` self-consumption, and so is the `dynamic` self-consumption.
- Given `--policy static`, when the person runs `sim policy compare`, then stderr is `error: UNKNOWN_OPTION: --policy`. The exit code is 2. `--seeds 3` gives `error: UNKNOWN_OPTION: --seeds`.

### JOB-simulate.R9 · Policy robust
- Given no options, when the person runs `sim policy robust`, then it prints the header and the rows `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order, and exits with 0.
- Given no options, when the person runs `sim policy robust`, then each row shows the values of CAP-homesim (home simulation) for the evaluation over the seeds 1 to 10, with one decimal.
- Given `--seeds 1 --seed 4`, when the person runs `sim policy robust`, then the mean and the worst self-consumption of each row are the self-consumption of the same row of `sim policy compare --seed 4`.
- Given no options, when the person runs `sim policy robust`, then the worst self-consumption of each row is not more than its mean.
- Given no options, when the person runs `sim policy robust`, then each row has `unmet-kWh` 0.0, `cold-hours` 0 and `safe` `yes`.
- Given `--element 0.2 --days 90`, when the person runs `sim policy robust`, then the `thermostat` row has `safe` `no`, and its `unmet-kWh` is more than 0.0.
- Given `--seed 7 --seeds 3` two times, when the person runs `sim policy robust`, then the two outputs are the same.
- Given `--seeds 0`, when the person runs `sim policy robust`, then stderr is `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. The exit code is 2. `--seeds 101` gives `error: OUT_OF_RANGE: --seeds 101 (1 to 100)`, and `--seeds 100` exits with 0.
- Given `--seeds 2.5`, when the person runs `sim policy robust`, then stderr is `error: BAD_NUMBER: --seeds 2.5`. The exit code is 2.

### JOB-simulate.R10 · Policy tune
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the first lines are `candidates        704` and `safe              704`, and the command exits with 0.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then `heat-start` is from 6 to 16, `heat-hours` is from 1 to 8, and `discharge-from` is from 15 to 22.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the profile equals the best profile of CAP-homesim (home simulation) for these options.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the `static` row equals the `static` row of `sim policy robust` with the same options and the profile as `--heat-start`, `--heat-hours` and `--discharge-from`.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the `thermostat`, `precomputed`, `dynamic` and `perfect-forecast` rows equal the same rows of `sim policy robust` with the same options.
- Given `--seeds 2 --days 30` two times, when the person runs `sim policy tune`, then the two outputs are the same.
- Given `--heat-start 10`, when the person runs `sim policy tune`, then stderr is `error: UNKNOWN_OPTION: --heat-start`. The exit code is 2. `--heat-hours 4` and `--discharge-from 17` give `UNKNOWN_OPTION` too.
- Given `--seeds 0`, when the person runs `sim policy tune`, then stderr is `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. The exit code is 2.

### JOB-simulate.R11 · Policy options
- Given `--tank 0` and `--tank 50`, when the person runs `sim policy run`, then each exits with 0. `--tank 50.1` gives `error: OUT_OF_RANGE: --tank 50.1 (0 to 50)` and exit code 2.
- Given `--element 0` and `--element 20`, when the person runs `sim policy run`, then each exits with 0. `--element 20.1` gives `error: OUT_OF_RANGE: --element 20.1 (0 to 20)` and exit code 2.
- Given `--cut-in 0` and `--cut-in 50`, when the person runs `sim policy run`, then each exits with 0. `--cut-in 50.1` gives `error: OUT_OF_RANGE: --cut-in 50.1 (0 to 50)` and exit code 2.
- Given `--floor 0` and `--floor 50`, when the person runs `sim policy run`, then each exits with 0. `--floor 50.1` gives `error: OUT_OF_RANGE: --floor 50.1 (0 to 50)` and exit code 2.
- Given `--draw 0` and `--draw 100`, when the person runs `sim policy run`, then each exits with 0. `--draw 100.1` gives `error: OUT_OF_RANGE: --draw 100.1 (0 to 100)` and exit code 2.
- Given `--fetches 1` and `--fetches 10`, when the person runs `sim policy run --policy precomputed`, then each exits with 0. `--fetches 0` gives `error: OUT_OF_RANGE: --fetches 0 (1 to 10)` and `--fetches 11` gives `error: OUT_OF_RANGE: --fetches 11 (1 to 10)`. The exit code is 2.
- Given `--draw-cv 0` and `--draw-cv 1`, when the person runs `sim policy run`, then each exits with 0. `--draw-cv 1.1` gives `error: OUT_OF_RANGE: --draw-cv 1.1 (0 to 1)` and exit code 2.
- Given `--forecast-error 0` and `--forecast-error 5`, when the person runs `sim policy run`, then each exits with 0. `--forecast-error 5.1` gives `error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)` and exit code 2.
- Given `--heat-start 0` and `--heat-start 23`, when the person runs `sim policy run`, then each exits with 0. `--heat-start 24` gives `error: OUT_OF_RANGE: --heat-start 24 (0 to 23)` and exit code 2.
- Given `--heat-hours 0` and `--heat-hours 24`, when the person runs `sim policy run`, then each exits with 0. `--heat-hours 25` gives `error: OUT_OF_RANGE: --heat-hours 25 (0 to 24)` and exit code 2.
- Given `--discharge-from 0` and `--discharge-from 24`, when the person runs `sim policy run`, then each exits with 0. `--discharge-from 25` gives `error: OUT_OF_RANGE: --discharge-from 25 (0 to 24)` and exit code 2.
- Given `--target 0` and `--target 50`, when the person runs `sim policy run --policy dynamic`, then each exits with 0. `--target 50.1` gives `error: OUT_OF_RANGE: --target 50.1 (0 to 50)` and exit code 2.
- Given `--min-solar 0` and `--min-solar 10`, when the person runs `sim policy run --policy precomputed`, then each exits with 0. `--min-solar 10.1` gives `error: OUT_OF_RANGE: --min-solar 10.1 (0 to 10)` and exit code 2.
- Given `--low 0` and `--low 50`, when the person runs `sim policy run --policy dynamic`, then each exits with 0. `--low 50.1` gives `error: OUT_OF_RANGE: --low 50.1 (0 to 50)` and exit code 2.
- Given `--heat-hours 2.5`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --heat-hours 2.5`. The exit code is 2. `--fetches 2.5`, `--heat-start 1.5` and `--discharge-from 17.5` give the same error with their own option and value.
- Given `--tank abc`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --tank abc`. The exit code is 2. `--element 1e3`, `--floor .5`, `--cut-in 3,5`, `--draw-cv x` and `--draw 5kW` give `BAD_NUMBER` with their own option and value.
- Given `--tank` with no value, when the person runs `sim policy run`, then stderr is `error: MISSING_VALUE: --tank`. The exit code is 2.
- Given `--tank -1`, when the person runs `sim policy run`, then stderr is `error: OUT_OF_RANGE: --tank -1 (0 to 50)`. The exit code is 2.
- Given `--tank 5 --tank 12`, when the person runs `sim policy run`, then the result equals the result of `--tank 12`.
- Given `--heat-start 20 --heat-hours 10`, when the person runs `sim policy run`, then it exits with 0, because the window stops at the end of the day.
- Given `sim policy fly`, when the person runs it, then stderr is `error: UNKNOWN_COMMAND: policy fly`. The exit code is 2. `sim policy` and `sim policy help` print the line `usage: sim policy run|compare|robust|tune [options]` first and exit with 0.
- Given each error above, when the person runs the command, then stdout is empty.

## Relies on

- CAP-homesim (used, not changed)
- CAP-forecast (used, not changed)
- CAP-policy (used, not changed)
- CAP-hotwater (used, not changed)
- CAP-scenario (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `HomeSetup` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `drawCv : Float` (the spread of that draw from day to day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day with a spread of 0.25, 10 fetches each day, and an error scale of 1.0
  - errors: none
- `HomeTotals` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh` (the house load, the heating and the backstop heating), `importKwh`, `exportKwh`, `batteryLossKwh`, `tankLossKwh`, `heatKwh`, `backstopKwh`, `drawKwh`, `unmetKwh`, `minTankKwh`, `finalTankKwh`, `selfConsumption` and `selfSufficiency`. The field `coldHours` is a `Nat`.
  - errors: none
- `HomeResult` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HomeHour` and `totals : HomeTotals`
  - errors: none
- `runHome (setup : HomeSetup) (policy : Policy) (seed days : Nat) : HomeResult` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, a policy, a seed, and the days of the run
  - out: the hours and the totals of the run
  - errors: none
- `Evaluation` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `meanSelfConsumption`, `worstSelfConsumption`, `meanSelfSufficiency`, `meanImportKwh`, `meanExportKwh`, `meanBackstopKwh` and `totalUnmetKwh` are each a `Float`. The fields `seeds`, `unmetSeeds` and `coldHours` are each a `Nat`.
  - errors: none
- `evaluate (setup : HomeSetup) (policy : Policy) (seed seeds days : Nat) : Evaluation` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, a policy, the first seed, the count of seeds, and the days of each run
  - out: the evaluation over the seeds `seed` to `seed + seeds - 1`
  - errors: none
- `TuneResult` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `best : StaticParams`, `evaluation : Evaluation`, `candidates : Nat` and `safe : Nat`.
  - errors: none
- `tuneStatic (setup : HomeSetup) (seed seeds days : Nat) : TuneResult` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, the first seed, the count of seeds, and the days of each run
  - out: the best static profile that the search finds, its evaluation, the count of candidates, and the count of safe candidates
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `Period` · type · `StoragePolicySim/Forecast.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams

- `--seed` · seam: randomness · `Main.lean`
  - in: a whole number. The same seed gives the same weather and the same forecast.
  - errors: none

## Files

- `Main.lean`
- `StoragePolicySim/PolicyCommands.lean`
- `README.md`

## Check files

- `tests/JOB-simulate.lean`

## Steps

### Step 1 · Bad command line · [ ]

- Requirement: JOB-simulate.R5
- Check: the checks named `JOB-simulate.R5 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 2 · Forecast command · [ ]

- Requirement: JOB-simulate.R6
- Check: the checks named `JOB-simulate.R6 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 3 · Policy run · [ ]

- Requirement: JOB-simulate.R7
- Check: the checks named `JOB-simulate.R7 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 4 · Policy compare · [ ]

- Requirement: JOB-simulate.R8
- Check: the checks named `JOB-simulate.R8 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 5 · Policy robust · [ ]

- Requirement: JOB-simulate.R9
- Check: the checks named `JOB-simulate.R9 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 6 · Policy tune · [ ]

- Requirement: JOB-simulate.R10
- Check: the checks named `JOB-simulate.R10 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

### Step 7 · Policy options · [ ]

- Requirement: JOB-simulate.R11
- Check: the checks named `JOB-simulate.R11 …` in `tests/JOB-simulate.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned last, because the commands use every capability of IN-0008 (hot-water policy simulation).
