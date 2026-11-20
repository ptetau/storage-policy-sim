# Slices

## S1: Run the static policy

- Story: As a home owner, I run `sim policy run` with a static heating window, so that I see how much of my solar energy the home uses and whether the tank stays hot.
- Requirements: R1 (gated battery step), R2 (static profile), R6 (hourly home flows), R8 (totals and ratios), R12 (usage line), R14 (policy run)
- Acceptance:
  - Given an empty battery of 10 kWh with 5 kW that may not charge, when an hour has 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export. (R1)
  - Given 1.9 kWh stored and a battery that may not discharge, when an hour has 0 kWh of solar and 2 kWh of load, then the battery gives 0 kWh, the import is 2.0 kWh and the battery still holds 1.9 kWh. (R1)
  - Given 1.9 kWh stored and a battery that may discharge, when an hour has 0 kWh of solar and 2 kWh of load, then the battery gives 1.805 kWh and the import is 0.195 kWh, within 0.000000001 kWh. (R1)
  - Given a battery that may charge and discharge, when each of the 24 hours of day 100 at latitude 45 with seed 7 runs, then each flow equals `stepHour` with `greedy`. With discharge only from 17:00, each flow equals `stepHour` with `evening`. (R1)
  - Given `defaultStatic`, when the profile is made, then it has 24 actions, hours 10 to 13 ask for 3.0 kWh, and hours 9 and 14 ask for 0 kWh. (R2)
  - Given a start of 23 and 5 heating hours, when the profile is made, then hour 23 asks for 3.0 kWh and hour 0 asks for 0 kWh. (R2)
  - Given `defaultStatic`, when the profile is made, then the battery may charge in each hour, may discharge in hours 17 and 23, and may not in hours 0 and 16. With discharge from 24, it may not discharge in any hour. (R2)
  - Given the home `generic`, the static policy, seed 7 and 365 days, when the run ends, then it has 8760 hours in order of day, then hour, and each hour holds the solar energy and the house load of the scenario hour. (R6)
  - Given the same run, when each hour is read, then its tank result equals `tankStep` for the tank state of the hour before, its hour of the day, its request and its draw, and its flow equals `stepHourGated` for the house load plus the heating plus the backstop heating. (R6)
  - Given the same run, when each hour is read, then its draw equals `drawKwh` for its day and hour times `drawFactor 7 day 0.25`. (R6)
  - Given the same arguments twice, when the runs end, then they are equal. Given 0 days, the run has no hours. (R6)
  - Given the same run, when the totals are read, then each total equals the sum of its hours, and solar plus import equals load plus export plus curtailed plus battery loss plus the final battery energy, within 0.01 kWh. (R8)
  - Given the same run, when the ratios are read, then the self-consumption is 100 × (solar - export - curtailed) / solar and the self-sufficiency is 100 × (load - import) / load. (R8)
  - Given 0 kW of panels, when the run ends, then the self-consumption is 0%. Given 0 days, each total is 0, except the lowest and the final tank energy, which are 10.5 kWh. (R8)
  - Given no arguments, when the person runs `sim`, then the first line is `usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]` and the exit code is 0. `sim help` and `sim --help` print the same. (R12)
  - Given `sim policy` or `sim policy help`, when the person runs it, then the first line is `usage: sim policy run|compare|robust|tune|plan [options]` and the exit code is 0. `sim policy fly` gives `error: UNKNOWN_COMMAND: policy fly` and exit code 2. (R12)
  - Given no options, when the person runs `sim policy run`, then it prints the 15 lines of R14 in order, and the first three are `policy            static`, `days              365` and `seed              1`. (R14)
  - Given `--days 30 --lat 45 --seed 9`, when the person runs `sim policy run`, then each value equals the total of `runHome` for these options, with one decimal. (R14)
  - Given `--heat-hours 0`, when the person runs `sim policy run`, then the `heating` line is `heating           0.0 kWh` and the `backstop` value is more than 0.0 kWh. (R14)
  - Given `--policy wild`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)`, stdout is empty and the exit code is 2. (R14)
- Layers: command, home simulation, policy, battery step
- Status: done
- Test rounds: 1
- Review rounds: 2

## S2: Run the precomputed and the dynamic policy

- Story: As a home owner, I run a policy that plans from the forecast and a policy that reacts each hour, so that I can compare them with my static window.
- Requirements: R3 (day-ahead plan), R4 (dynamic action), R5 (defaults and names), R9 (policies at work), R13 (forecast command)
- Acceptance:
  - Given the default tank, a target of 9.0 kWh, a forecast of 1.0, 2.0, 3.5, 3.0, 4.0 and 1.5 kWh in hours 9 to 14, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hours 10 to 13 ask for 2.0, 3.0, 3.0 and 3.0 kWh and the other hours for 0 kWh. (R3)
  - Given the same forecast and target, 9.0 kWh in the tank and an expected draw of 0.5 kWh, when the day is planned, then only hour 13 asks, for 0.5 kWh. (R3)
  - Given a forecast of 0.4 kWh in each hour, when the day is planned with a need of 11 kWh, then each hour asks for 0 kWh. (R3)
  - Given a target of 9.0 kWh, a forecast of 2.0 kWh in hours 10 to 14, 9.0 kWh in the tank and an expected draw of 4.0 kWh, when the day is planned, then hour 10 asks for 3.0 kWh and hour 11 for 1.0 kWh. (R3)
  - Given a low level of 4.0 kWh and a target of 9.0 kWh, when the hour has a surplus of 5.0 kWh and 8.0 kWh in the tank, then the tank asks for 1.0 kWh. With 5.0 kWh in the tank it asks for 3.0 kWh. With 9.0 kWh it asks for 0 kWh. (R4)
  - Given the same levels and no surplus, when the tank holds 3.0 kWh and the forecast for the rest of the day is 0.5 kWh, then the tank asks for 1.0 kWh. With a forecast of 1.0 kWh it asks for 0 kWh. (R4)
  - Given the defaults, when they are read, then `defaultPlan` has a target of 10.5 kWh, a minimum forecast of 0.5 kWh and discharge from 17, and `defaultDynamic` has a low level of 5.25 kWh, a target of 10.5 kWh and discharge from 17. The names are `static`, `precomputed` and `dynamic`. (R5)
  - Given the precomputed policy, a forecast error of 0, 1 fetch each day and seed 7, when each hour of a 365-day run is read, then the tank asks for heat only in hours with at least 0.5 kWh of solar energy. (R9)
  - Given the dynamic policy and seed 7, when each hour is read, then the tank asks for heat only in an hour whose solar energy is more than its house load, or whose tank held less than 5.25 kWh. (R9)
  - Given seed 7, when the default static, the default dynamic and the static policy with 0 heating hours run, then the first two each have a higher self-consumption than the third. (R9)
  - Given `--policy dynamic --days 30 --seed 9`, when the person runs `sim policy run`, then the first line shows `dynamic` and the values equal the totals of `runHome`. (R9)
  - Given no options, when the person runs `sim forecast`, then stdout starts with `{"forecasts":[{"pv_estimate":`, has 96 periods, and the first `period_end` is `2024-12-31T13:00:00.0000000Z`. (R13)
  - Given `--hour 8760`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 8760 (0 to 8759)` and the exit code is 2. `--battery 5` gives `error: UNKNOWN_OPTION: --battery`. (R13)
- Layers: command, home simulation, policy, forecast
- Status: red
- Test rounds: 0
- Review rounds: 0

## S3: Compare the policies and prove no cold tank

- Story: As a home owner, I compare the policies on the same weather, so that I see which uses the most solar energy with no cold tank.
- Requirements: R7 (no cold tank), R15 (policy compare)
- Acceptance:
  - Given the home `generic`, each default policy and the seeds 1 to 5, when each 365-day run ends, then the unmet draw is 0 kWh in each hour, the tank holds at least 2.1 kWh after each hour, and each day has an hour after which the tank is full, within 0.000000001 kWh. (R7)
  - Given a draw spread of 0.5 and the seeds 1 to 5, when each default policy runs, then the unmet draw is 0 kWh and the cold hours are 0. (R7)
  - Given the static policy with 0 heating hours and seed 7, when the run ends, then the backstop heating is more than 500 kWh and the unmet draw is 0 kWh. (R7)
  - Given an element of 0.2 kW and the static policy with 0 heating hours, when the run ends, then the unmet draw and the cold hours are more than 0. (R7)
  - Given no options, when the person runs `sim policy compare`, then it prints the header of R15 and the rows `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order, and exits with 0. (R15)
  - Given `--seed 9 --lat 45 --days 90`, when the person runs `sim policy compare`, then each row shows the values of `runHome` for its policy, and the `perfect-forecast` row those of the precomputed policy with an error scale of 0. (R15)
  - Given `--heat-hours 0`, when the person runs `sim policy compare`, then the `static` row equals the `thermostat` row. `--policy static` gives `error: UNKNOWN_OPTION: --policy`. (R15)
- Layers: command, home simulation
- Status: red
- Test rounds: 0
- Review rounds: 0

## S4: Test a policy over many years and tune the static profile

- Story: As a home owner, I test the policies over many weather years and search the best static profile, so that my choice is robust and not one lucky year.
- Requirements: R10 (robust evaluation), R11 (static tuner), R16 (policy robust), R17 (policy tune)
- Acceptance:
  - Given the first seed 3 and 4 seeds, when the static policy is evaluated, then the mean self-consumption is the average of the runs with seeds 3 to 6, the worst is the lowest of them, and `seeds` is 4. (R10)
  - Given an element of 0.2 kW, the static policy with 0 heating hours, the first seed 3, 4 seeds and 30 days, when the policy is evaluated, then the total unmet draw is the sum of the runs and more than 0, and the count of seeds with an unmet draw is more than 0. (R10)
  - Given 0 seeds, when a policy is evaluated, then each field is 0. (R10)
  - Given the home `generic`, the goal `self-consumption`, 2 seeds from seed 1 and 30 days, when the profile is tuned, then `candidates` is 704, `safe` is 704, and no safe candidate has a mean self-consumption more than 0.05 points above the best. (R11)
  - Given the goal `import` and the same arguments, when the profile is tuned, then no safe candidate has a mean import more than 0.5 kWh below the best. (R11)
  - Given no options, when the person runs `sim policy robust`, then it prints the header of R16 and the five rows of D11, each row has `unmet-kWh` 0.0, `cold-hours` 0 and `safe` `yes`, and the worst self-consumption of each row is not more than its mean. (R16)
  - Given `--element 0.2 --days 90`, when the person runs `sim policy robust`, then the `thermostat` row has `safe` `no`. `--seeds 0` gives `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. (R16)
  - Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the first lines are `goal              self-consumption`, `candidates        704` and `safe              704`, and the `static` row equals the row of `sim policy robust` with the tuned profile as options. (R17)
  - Given `--goal cheap`, when the person runs `sim policy tune`, then stderr is `error: UNKNOWN_GOAL: cheap (self-consumption, import)` and the exit code is 2. `--heat-start 10` gives `error: UNKNOWN_OPTION: --heat-start`. (R17)
- Layers: command, home simulation
- Status: red
- Test rounds: 0
- Review rounds: 0

## S5: Refuse a bad option

- Story: As a home owner, I get one clear error line for a bad option, so that I can fix my command.
- Requirements: R18 (option errors)
- Acceptance:
  - Given `--tank 0` and `--tank 50`, when the person runs `sim policy run`, then each exits with 0. `--tank 50.1` gives `error: OUT_OF_RANGE: --tank 50.1 (0 to 50)` and `--tank -1` gives `error: OUT_OF_RANGE: --tank -1 (0 to 50)`, each with exit code 2. (R18)
  - Given each option of D15, when the person gives its lowest and its highest value, then the command exits with 0, and a value just above the highest gives `OUT_OF_RANGE` with the range of D15. (R18)
  - Given `--heat-hours 2.5`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --heat-hours 2.5`. `--tank abc`, `--element 1e3` and `--floor .5` give `BAD_NUMBER` too. (R18)
  - Given `--tank` with no value, when the person runs `sim policy run`, then stderr is `error: MISSING_VALUE: --tank`. `--seeds 3` gives `error: UNKNOWN_OPTION: --seeds`. (R18)
  - Given `--tank 5 --tank 12`, when the person runs `sim policy run`, then the result equals the result of `--tank 12`. Given each error, stdout is empty. (R18)
- Layers: command
- Status: red
- Test rounds: 0
- Review rounds: 0

## S6: Model panel arrays and the limits of the inverter

- Story: As a home owner with panels that face several ways, I give each array and my limits, so that the solar curve of my day is right.
- Requirements: R19 (panel arrays), R20 (limits)
- Acceptance:
  - Given latitude -41.3 and one flat array of 5 kW, when each hour of 365 days with seed 7 is read, then the solar energy equals the old scenario, within 0.000001 kWh. (R19)
  - Given latitude -41.3, a sunny day 0, and an array of 3 kW at 30° that faces east (90), when the hours are added, then the hours before 12:00 give more than the hours after. An array that faces west (270) gives the reverse. (R19)
  - Given latitude -41.3 at 12:00 on a sunny day 171, when a north array at 30° and a south array at 30° of the same power are compared, then the north array gives more. (R19)
  - Given `--array 3:90:30 --array 3:270:30`, when the person runs `sim policy run`, then the `solar` value equals the sum of the two arrays, and the flat 5 kW array of the home is gone. `--array 3:90` gives `error: BAD_NUMBER: --array 3:90`. (R19)
  - Given an inverter limit of 5 kW, no export limit and an empty battery of 10 kWh with 5 kW, when an hour has 8 kWh of solar and 1 kWh of load, then 1 kWh is direct, 3 kWh charges the battery, 4 kWh is export and 0 kWh is curtailed. (R20)
  - Given an inverter limit of 5 kW, an export limit of 2 kW and a full battery, when an hour has 8 kWh of solar and 1 kWh of load, then the export is 2 kWh and 5 kWh is curtailed. (R20)
  - Given limits of 0, when any hour runs, then the flows equal `stepHourGated` and 0 kWh is curtailed. (R20)
  - Given `--inverter 3 --export-limit 1`, when the person runs `sim policy run`, then the `curtailed` value is more than 0.0 kWh, and in each hour of `runHome` the export is at most 1 kWh. `--inverter 100.1` gives `error: OUT_OF_RANGE: --inverter 100.1 (0 to 100)`. (R20)
- Layers: command, home simulation, scenario, battery step
- Status: red
- Test rounds: 0
- Review rounds: 0

## S7: Simulate my home with two tanks

- Story: As the owner of the home `mine`, I pick my home by name, so that each command shows my two tanks, my arrays and my battery.
- Requirements: R21 (homes), R22 (more tanks)
- Acceptance:
  - Given `--home mine`, when the home is read, then it has five arrays that add up to 14.88 kW, a battery of 13.5 kWh, an inverter limit of 11 kW, an export limit of 10 kW, and tanks of 13.1 kWh with 3.3 kW and 9.4 kWh with 2.5 kW, with a draw of 11.0 kWh each day. (R21)
  - Given no `--home`, when the person runs `sim policy run`, then the output equals `sim policy run --home generic`. `--home family --pv 6` changes only the panels. (R21)
  - Given `--home castle`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_HOME: castle (generic, small, family, no-battery, mine)` and the exit code is 2. (R21)
  - Given the home `mine` and the static policy, when each hour of a 30-day run is read, then it holds a request, a heating, a backstop, a draw and an energy for each of the 2 tanks, and each tank result equals `tankStep` for that tank. (R22)
  - Given the home `mine`, when the draw of a day is read, then the first tank has 58% of it and the second 42%. (R22)
  - Given each home of D20, each default policy and the seeds 1 to 3, when each 365-day run ends, then no tank has an unmet draw or a cold hour, and each tank is full at least once each day. (R22)
  - Given the dynamic policy, a surplus of 3.0 kWh, a first tank at 50% of its capacity and a second at 30%, when the hour is decided, then the second tank gets its request first. (R22)
  - Given `--tank2 9.4:2.5:0.42`, when the person runs `sim policy run`, then the run has 2 tanks and the second draws 42% of the hot water. (R22)
- Layers: command, home simulation, policy, tank
- Status: red
- Test rounds: 0
- Review rounds: 0

## S8: Shift the flexible load and stop thrashing

- Story: As a home owner, I let the policy move each load that can move, with few starts, so that I use the most solar energy and my elements do not switch all day.
- Requirements: R24 (shiftable flexible load), R25 (no thrashing)
- Acceptance:
  - Given the home `generic` with 3 kWh of flexible load and each default policy, when each day of a 365-day run is read, then the flexible load of the day adds up to 3 kWh, within 0.000001 kWh. (R24)
  - Given the static policy with `--flex-start 11`, when each day is read, then the flexible load starts at hour 11. `--flex-start 24` gives `error: OUT_OF_RANGE: --flex-start 24 (0 to 23)`. (R24)
  - Given the dynamic policy and a day with no surplus, when the day is read, then the flexible load runs from 20:00. (R24)
  - Given each home of D20, each default policy and the seeds 1 to 3, when each day of a 365-day run is read, then each tank has at most 2 policy starts and the battery gate changes at most 2 times. (R25)
  - Given the home `generic`, when the person runs `sim policy run`, then the `starts-per-day` value equals the policy starts of the tanks of `runHome` divided by the days, with one decimal. (R25)
- Layers: command, home simulation, policy
- Status: red
- Test rounds: 0
- Review rounds: 0

## S9: Print the plan of a day

- Story: As a home owner, I print the plan of one day, so that I know when to heat each tank and when the battery may discharge.
- Requirements: R23 (plan of a day)
- Acceptance:
  - Given `--home mine --day 10`, when the person runs `sim policy plan`, then it prints a header and 24 lines, one for each hour from 0 to 23, each with the forecast solar energy, the heating of each of the 2 tanks, and `yes` or `no` for the battery discharge. (R23)
  - Given the same options, when the lines are compared with `runHome` for the precomputed policy, then the heating of each tank in each hour equals the request of that hour on day 10, with one decimal. (R23)
  - Given no `--day`, when the person runs `sim policy plan`, then it prints the plan of day 0. `--day 365` with 365 days gives `error: OUT_OF_RANGE: --day 365 (0 to 364)`. (R23)
- Layers: command, home simulation, policy
- Status: red
- Test rounds: 0
- Review rounds: 0
