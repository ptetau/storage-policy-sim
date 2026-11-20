# Domain: physics models

This design document holds no code.

## Entities and value objects

- Step (value object): a quarter of an hour of a day, from 0 to 95.
- Sky (value object): the clear-sky sunlight, the clearness, the air temperature and the inlet temperature of a step.
- PanelArray (value object): from spec 001: a power, a direction and a tilt.
- PhysTank (value object): the litres, the element, the loss, the cut-in share, the floor share and the guard hour of a tank.
- PhysTankState (value object): the hot litres, the thermostat state and the full-today flag.
- Battery (value object): from spec 001, with the losses of D10.
- Cycle (value object): one run of an appliance: its name and its energy in each step.
- Home, Policy, Action (value objects): from spec 001.
- PhysicsRun (entity): one run of a home with a policy, a seed and a count of days, on the physics model. Its arguments identify it.

## Relationships

- A PhysicsRun has 96 records for each day, and one Sky for each step.
- A Home has one PhysTank for each tank, made from its capacity.
- A day has zero to three Cycles.

## Invariants

- I1 (energy balance): solar plus import equals load plus export plus curtailed plus the losses plus the change of the store.
- I2 (tank balance): the start energy plus the heating plus the backstop equals the served energy plus the loss plus the end energy.
- I3 (light): a flat panel gets the flat sunlight.
- I4 (cycle): a cycle that started runs to its end without a gap, inside its day.
- I5 (daily sterilising): each tank is all hot at least once each day.

## State machines

### Machine: PhysThermostat

- States: off, heating
- Start: off
- End: none
- T1: off -> heating on hot share below the cut-in share / the backstop heats the tank
- T2: off -> heating on guard hour [the tank was not all hot today] / the backstop heats the tank
- T3: heating -> off on tank all hot / the full-today flag is set

## Bounded contexts and boundary

- Inside: the physics weather, the physics tank, the battery with losses, the appliance cycles, the base load, the physics run, and the `--model` option of the `sim policy` commands.
- Outside: real weather records, the historical data of the house, and the simple model of spec 001, which stays as it is.
- Actors: the home owner, who runs `sim` in a terminal. A program that calls the library.

## Requirement map

- R1: Sky, Step
- R2: Sky, Step
- R3: Sky, PanelArray, I3
- R4: PanelArray, Sky
- R5: Sky
- R6: PhysTank, PhysTankState, I2
- R7: PhysTank, PhysTankState, I5, PhysThermostat.T1, PhysThermostat.T2, PhysThermostat.T3
- R8: Battery, I1
- R9: Cycle, I4
- R10: Home, Step
- R11: PhysicsRun, Home, Policy, Action, I1, I2, I5
- R12: PhysicsRun, the `sim policy` commands, the home owner
