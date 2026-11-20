# Domain: hot-water policies

This design document holds no code.

## Entities and value objects

- Home (value object): the site, the panel arrays, the battery, the tanks, the hot-water draw, the limits and the forecast settings of one house. A name such as `mine` picks a home, and two homes with the same values are the same.
- PanelArray (value object): a power, a direction and a tilt.
- Limits (value object): the inverter limit and the export limit. 0 means no limit.
- Tank (value object): the capacity, the element, the loss, the cut-in, the floor, the guard hour and the share of the draw of one cylinder.
- TankState (value object): the energy, the thermostat state and the full-today flag of one tank after an hour.
- Battery (value object): a capacity and a power.
- Policy (value object): `static`, `precomputed` or `dynamic`, with its parameters.
- Action (value object): what a policy asks for in one hour: a heating request for each tank, the battery gate, and the flexible load to run.
- Observation (value object): what a dynamic policy sees in an hour: the hour, each tank, the battery, the surplus and the forecast for the rest of the day.
- Run (entity): one simulation of a home with a policy, a seed and a count of days. Its arguments identify it, and the same arguments give the same run.
- HomeHour (value object): the record of one hour of a run.
- Totals (value object): the sums and ratios of a run.
- Evaluation (value object): the summary of a policy over several seeds.
- TuneResult (value object): the best static profile, its evaluation and the counts of the search.
- Forecast (value object): the periods of one fetch, from the code that exists.

## Relationships

- A Home has one or more PanelArrays: the solar energy of an hour is the sum of the arrays.
- A Home has one or more Tanks: each tank runs its own hour, and the shares of the draw add up to 1.
- A Run has many HomeHours: 24 for each day, in order of day, then hour.
- A Run has one Totals: each total is the sum of its hours.
- An Evaluation has many Runs: one for each seed.
- An Action has one request for each Tank of the Home.

## Invariants

- I1 (energy balance): solar plus import equals load plus export plus curtailed plus battery loss plus the change of the battery energy.
- I2 (tank balance): for each tank, the start energy plus the heating plus the backstop equals the served draw plus the loss plus the final energy.
- I3 (limits): the energy to the house and the grid is never more than the inverter limit, and the export is never more than the export limit.
- I4 (battery): the battery charges only from solar energy, and only when its gate allows it.
- I5 (daily sterilising): each tank is full at least once each day.
- I6 (flexible load): the flexible load of a day adds up to the same energy, and runs inside its day.
- I7 (starts): a policy starts the element of a tank at most 2 times in a day.

## State machines

### Machine: Thermostat

- States: off, heating
- Start: off
- End: none
- T1: off -> heating on level below the cut-in / the backstop heats the tank
- T2: off -> heating on guard hour [the tank was not full today] / the backstop heats the tank
- T3: heating -> off on tank full / the full-today flag is set

### Machine: ElementSchedule

- States: idle, requested
- Start: idle
- End: none
- T1: idle -> requested on policy request [fewer than 2 starts today] / one start is counted
- T2: requested -> idle on no policy request / the element stops unless the thermostat heats
- X1: idle on policy request refused: no third start in a day, the policy keeps its request at 0

## Bounded contexts and boundary

- Inside: the home simulation, the policies, the evaluation, the tuner, the gated and limited battery step, the panel arrays, the homes, and the `sim` commands.
- Outside: the real Solcast service, the real inverter and tank controllers, tariffs, and shade.
- Actors: the home owner, who runs `sim` in a terminal and reads stdout, stderr and the exit code. A program that calls the library functions of `StoragePolicySim`.

## Requirement map

- R1: Battery, I4, the gated battery step
- R2: Policy (static), Action
- R3: Policy (precomputed), Action, Tank, Forecast
- R4: Policy (dynamic), Action, Observation, Tank
- R5: Policy
- R6: Run, HomeHour, Home, Tank, TankState, Action
- R7: Tank, TankState, I5, Thermostat.T1, Thermostat.T2, Thermostat.T3
- R8: Totals, I1, I2
- R9: Run, Policy, Action
- R10: Evaluation, Run
- R11: TuneResult, Evaluation, Policy (static)
- R12: the `sim` commands, the home owner
- R13: Forecast, the `sim` commands
- R14: Run, Totals, the `sim` commands
- R15: Run, Totals, Policy, the `sim` commands
- R16: Evaluation, the `sim` commands
- R17: TuneResult, the `sim` commands
- R18: the `sim` commands, the home owner
- R19: PanelArray, Home
- R20: Limits, I1, I3, the limited battery step
- R21: Home
- R22: Tank, TankState, Home, Action, I2, I5
- R23: Policy (precomputed), Action, Forecast, the `sim` commands
- R24: Action, I6
- R25: Action, I7, ElementSchedule.T1, ElementSchedule.T2, ElementSchedule.X1
