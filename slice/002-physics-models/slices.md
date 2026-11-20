# Slices

## S1: Model the sun, the cloud and the panels

- Story: As a home owner, I get a solar curve from physical rules, so that cloud, heat and the direction of each array change my output as they do on my roof.
- Requirements: R1 (clear sky), R2 (cloud), R3 (panel light), R4 (panel output), R5 (temperatures)
- Acceptance:
  - Given a sun straight up (`cosZ` 1), when the clear-sky rule runs, then it gives 1035.1 W/m², within 0.1. With `cosZ` 0.5 it gives 487.9 W/m², within 0.1. With `cosZ` 0 or less it gives 0. (R1)
  - Given latitude -41.3, when the 96 steps of day 0 are read, then the clear-sky sunlight is 0 at step 0, is highest in steps 47 or 48, and the noon of day 0 gives more than the noon of day 171. (R1)
  - Given seed 7 and 365 days at latitude -41.3, when the clearness is made, then it has 35040 values, each from 0.15 to 1.0, and the same seed gives the same values. Seed 8 differs in at least 1000 values. (R2)
  - Given the same clearness of the days, when day `d` and day `d + 1` are compared over the year, then their correlation is from 0.4 to 0.8. The mean of days 0 to 89 is above the mean of days 152 to 242. (R2)
  - Given the clearness of the steps of a day, when step `s` and step `s + 1` are compared over the year, then their correlation is above 0.5. (R2)
  - Given a clearness of 1.0, when the diffuse share is read, then it is 0.1831, within 0.0005. With a clearness of 0.2 it is 0.9865, within 0.0005. (R3)
  - Given a flat panel, when the light on it is read in each step of day 0 with a clearness of 0.7, then it equals the clear-sky sunlight times 0.7, within 0.001 W/m². (R3)
  - Given latitude -41.3, day 0, step 48 and a clearness of 1.0, when a north panel and a south panel at 30° are compared, then the north panel gets more. With a clearness of 0.15, the two differ by less than 15% of the larger. (R3)
  - Given an array of 5 kW, light of 1000 W/m² and an air temperature such that the cell is 25 °C, when the output is read, then it is 4.5 kW. Given light of 800 W/m² and air of 20 °C, the cell is 45 °C and the output is 3.312 kW, within 0.001. With no light the output is 0 kW. (R4)
  - Given latitude -41.3 and a clear day, when the air temperature is read, then day 15 at 15:00 is 21.0 °C, within 0.01, day 15 at 03:00 is 14.0 °C, and day 197 at 15:00 is 12.0 °C. A day with a clearness of 0.5 is 1.0 °C lower. (R5)
  - Given latitude -41.3, when the inlet temperature is read, then day 45 gives 17.0 °C, within 0.01, and day 227 gives 11.0 °C, within 0.05. (R5)
- Layers: weather library
- Status: done
- Test rounds: 1
- Review rounds: 1

## S2: Model a tank in litres and degrees

- Story: As a home owner, I get tanks that lose heat through their walls and serve water in litres, so that a winter shower costs what it costs in my house.
- Requirements: R6 (tank physics), R7 (thermostat and sterilising)
- Acceptance:
  - Given a tank made from a capacity of 13.1 kWh, when its litres are read, then it holds 250.3 litres, within 0.1. A full tank with inlet water of 15 °C holds 13.1 kWh, within 0.001. (R6)
  - Given a full tank of 13.1 kWh with a cut-in share of 0, no request and no use, when one step runs with inlet water of 15 °C, then the loss is `0.006 × 13.1 / 42 × 42 × 0.25` kWh, which is 0.01965 kWh, within 0.00001. (R6)
  - Given a full tank and a use of 50 litres at the tap, when one step runs with inlet water of 15 °C, then the served energy is 1.4538 kWh, within 0.0005. With inlet water of 10 °C it is 1.7445 kWh. (R6)
  - Given a tank with 10 hot litres and a use of 50 litres at the tap, with inlet water of 15 °C and a cut-in share of 0, when one step runs, then the served energy is the energy of the hot litres after the loss, and the unmet use is the rest of the 1.4538 kWh. (R6)
  - Given a half-full tank, an element of 3.3 kW and a request of 2.0 kWh, when one step runs, then the heating is 0.825 kWh, the element power for a quarter of an hour. A request of 0.5 kWh heats 0.5 kWh. A full tank heats only its loss. (R6)
  - Given any state, request and use, when one step runs, then the start energy plus the heating plus the backstop equals the served energy plus the loss plus the end energy, within 0.000001 kWh. (R6)
  - Given a tank with a cut-in share of 0.5 and a hot share of 0.45, when one step runs with no request, then the backstop heats 0.825 kWh and the thermostat is on. With a hot share of 0.55 the backstop is 0 kWh. A thermostat that is on stays on until the tank is all hot. (R7)
  - Given a tank that was not all hot today and a guard hour of 20, when step 80 runs, then the backstop heats. At step 79 it does not. A tank that was all hot today gets no guard heating. Step 0 starts a new day. (R7)
- Layers: tank library
- Status: done
- Test rounds: 1
- Review rounds: 1

## S3: Model the battery, the appliances and the base load

- Story: As a home owner, I get a battery with real losses and appliances with real cycles, so that the timing of my loads matters as it does at home.
- Requirements: R8 (battery and inverter), R9 (flexible appliances), R10 (base load)
- Acceptance:
  - Given a battery of 13.5 kWh with 11 kW that holds 5.0 kWh, no solar and no load, when one step runs, then the battery holds 4.9975 kWh and no energy moves. Over 96 such steps it loses 0.24 kWh. (R8)
  - Given an empty battery, no limits, 2.0 kWh of solar and 0.5 kWh of load in a step, when the step runs, then the inverter loss is `(0.02 + 0.015 × 2.0) × 0.25`, which is 0.0125 kWh, 1.4875 kWh charges, the battery holds `0.97 × 1.4875 - 0.0025` kWh, and the export is 0 kWh. (R8)
  - Given 5.0 kWh stored, no solar and 1.0 kWh of load in a step, when the step runs, then the inverter loss is `(0.02 + 0.015 × 4.0) × 0.25`, which is 0.02 kWh, the battery gives the load and that loss, and the store falls by `(1.0 + 0.02) / 0.97 + 0.0025` kWh. (R8)
  - Given any step, when it runs, then solar plus import plus the fall of the store equals load plus export plus curtailed plus the losses, within 0.000001 kWh, and the limits of spec 001 hold with powers of a quarter of the hourly energy. (R8)
  - Given seed 7, when the cycles of the days 0 to 699 are read, then the dishwasher runs on 450 to 550 days, the washing machine on 350 to 450, and the dryer on 150 to 250. The same seed and day give the same cycles. (R9)
  - Given a cycle, when its steps are added, then the dishwasher uses 1.2 kWh in 8 steps, the washing machine 0.8 kWh in 6 steps, and the dryer 2.5 kWh in 6 steps, within 0.000001 kWh, and the largest step of the dishwasher is more than its smallest. (R9)
  - Given a daily base load of 17 kWh at latitude -41.3, when the steps of 365 days are added (kW times 0.25), then the sum is 6205 kWh, within 1%. Step 76 (19:00) of day 100 is more than step 12 (03:00). (R10)
  - Given the same home, when the steps of day 197 (winter) and day 15 (summer) are added, then winter is more, because the lights run longer. (R10)
- Layers: appliance library
- Status: review
- Test rounds: 1
- Review rounds: 3

## S4: Run the policies on the physics model

- Story: As a home owner, I run each policy command with `--model physics`, so that I see which policy wins when the weather and the appliances follow physical rules.
- Requirements: R11 (physics run), R12 (commands)
- Acceptance:
  - Given the home `generic`, the static policy, seed 7 and 30 days, when the physics run ends, then it has 2880 records in order of day, then step, and the same arguments give the same run. (R11)
  - Given the same run, when the totals are read, then each total equals the sum of its steps, and solar plus import equals load plus export plus curtailed plus battery loss plus the final battery energy, within 0.01 kWh. (R11)
  - Given each home of spec 001, each default policy and the seeds 1 to 3, when each 365-day physics run ends, then no tank has an unmet use, and each tank is all hot at least once each day. (R11)
  - Given the home `mine` and the static policy, when a physics run of 365 days is compared with the simple run, then the solar energy of the year differs by less than 35%, and the December day with the most solar energy gives more than the June day with the most. (R11)
  - Given the home `mine` and each default policy, when each day of a 365-day physics run is read, then each tank has at most 2 policy starts, where a start is an hour with a request after an hour with none. (R11)
  - Given `--model physics --days 30`, when the person runs `sim policy run`, then it prints the 15 lines of spec 001 and the values equal the totals of `runPhysics`, with one decimal. (R12)
  - Given no `--model` or `--model simple`, when the person runs `sim policy run --days 30`, then the output equals the output of spec 001. (R12)
  - Given `--model physics --days 30 --seeds 2`, when the person runs `sim policy compare`, `robust`, `tune` and `plan`, then each exits with 0 and prints its table of spec 001. `sim policy plan` prints 24 rows, one for each hour. (R12)
  - Given `--model magic`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_MODEL: magic (simple, physics)`, stdout is empty and the exit code is 2. (R12)
- Layers: command, physics run, policy
- Status: review
- Test rounds: 2
- Review rounds: 1
