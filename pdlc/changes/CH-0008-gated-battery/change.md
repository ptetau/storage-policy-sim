# CH-0008 · Allowed battery use

Intent: IN-0008 · Scope: CAP-simulation · Status: planned · Ticket: none · Branch: none · Base: main

Tests-Locked: none

## Delivers

The library runs an hour of the battery with a gate: charging and discharging are each allowed or not allowed. A policy uses the gate to plan the battery.

## Requirements

### CAP-simulation.R6 · Allowed battery use
- Given an empty battery that may charge and discharge, when the hour has 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given an empty battery that may not charge, when the hour has 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export. The battery still holds 0 kWh.
- Given 1.9 kWh stored and a battery that may discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored and a battery that may not discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 0 kWh and the import is 2.0 kWh. The battery still holds 1.9 kWh.
- Given 9.05 kWh stored and a battery that may charge, when the hour has a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery that may not charge and may not discharge, when an hour has a surplus of 2 kWh, then the export is 2 kWh. When the hour has a shortfall of 2 kWh, then the import is 2 kWh.
- Given a battery that may charge and discharge, when each of the 24 hours of day 100 of a run with latitude 45 and seed 7 runs with the battery energy of the hour before, then each flow equals the flow of `stepHour` with `greedy`. The tolerance is 0.000000001 kWh.
- Given a battery that may charge, and may discharge only from 17:00, when the same 24 hours run, then each flow equals the flow of `stepHour` with `evening`. The tolerance is 0.000000001 kWh.

## Relies on

- CAP-scenario (used, not changed)
- CAP-strategies (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `Battery` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `capacityKwh` and `powerKw`, each a `Float`
  - errors: none
- `Flow` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `directKwh`, `chargeKwh`, `dischargeKwh`, `exportKwh`, `importKwh`, `lossKwh` and `socKwh`.
  - errors: none
- `stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, a strategy, the hour of the day, and the solar energy and the load of the hour
  - out: the flows of the hour. `socKwh` of the flow is the energy that the battery holds after the hour.
  - errors: none
- `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, whether it may charge, whether it may discharge, and the solar energy and the load of the hour
  - out: the flows of the hour, with the same rules as `stepHour`. The battery charges only when it may charge, and discharges only when it may discharge.
  - errors: none
- `Strategy` · type · `StoragePolicySim/Strategy.lean`
  - in: not applicable
  - out: `none`, `greedy`, `evening` or `shift`, with `BEq`, `Repr` and `Inhabited`. Write a value in full, for example `Strategy.none`, so that it does not mean `Option.none`.
  - errors: none
- `Sky` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: `sunny`, `cloudy` or `overcast`, with `BEq`, `Repr` and `Inhabited`
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `Hour` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams
- `seed` · seam: randomness · `StoragePolicySim/Simulation.lean`
  - in: the `seed` argument of `simulate`. The same seed gives the same weather.
  - errors: none

## Files

- `StoragePolicySim/Simulation.lean: stepHourGated`

## Check files

- `tests/CAP-simulation.lean`

## Steps

### Step 1 · Allowed battery use · [ ]

- Requirement: CAP-simulation.R6
- Check: the checks named `CAP-simulation.R6 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned third. The checks compare the gated hour with the hour of `stepHour` and the strategies `greedy` and `evening`.
