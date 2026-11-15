# Brief for the test writer · CH-0010-homesim

Write the component checks of this change, only in the files under its "Check files".

This brief holds each input of the checks. Read another file only when this brief names
it, for example an existing check file to match its style.

Made at: be5c0a5a16ff608f1e8c9ae6110a4382cf95aff5

## The change spec

Path: pdlc/changes/CH-0010-homesim/change.md

````
# CH-0010 · Home simulation, robust evaluation and tuning

Intent: IN-0008 · Scope: CAP-homesim · Status: planned · Ticket: none · Branch: none · Base: main

Tests-Locked: none

## Delivers

The library runs a policy over a home with panels, a battery and a hot-water tank. It evaluates a policy over many weather seeds, and searches for the best static profile.

## Requirements

### CAP-homesim.R1 · Hourly home flows
- Given the default run, when it ends, then it has 8760 hours, in order of day, then hour.
- Given the default run, when each hour is read, then its solar energy and its house load are those of the scenario hour for the same site, seed and days.
- Given the default run, when each hour is read, then `askKwh` is the heating of its hour in the static profile, and the battery gate is the gate of that hour.
- Given the default run, when each hour is read, then its tank energy is the `tankStep` result for the tank state of the hour before, its hour of the day, its request and its draw. The first hour starts with `startState` of the tank.
- Given the default run, when each hour is read, then its flow is the `stepHourGated` flow for the battery energy of the hour before, its gate, its solar energy, and its house load plus its heating plus its backstop heating. The first hour starts with 0 kWh.
- Given the default run, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour, times the `drawFactor` for seed 7, its day and the spread 0.25.
- Given the default run with a spread of 0, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour.
- Given the precomputed policy with `defaultPlan`, 1 fetch each day and seed 7, when each hour of day `d` is read, then its `askKwh` is the `heatKwh` of that hour in `planDay`. The call uses the first 24 values of `hourlyEnergy` of the fetch at hour `24 × d`, the tank energy after hour 23 of day `d - 1` (10.5 kWh for day 0), and the sum of `drawKwh` for the 24 hours of day `d`, without the factor of the day.
- Given 0 days, when the run ends, then it has no hours.

### CAP-homesim.R2 · No cold tank
- Given each policy and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour.
- Given each policy and the seeds 1 to 5, when the run ends, then the tank holds at least 2.1 kWh after each hour, and `coldHours` is 0.
- Given each policy and the seeds 1 to 5, when the run ends, then each day has an hour after which the tank is full, within 0.000000001 kWh.
- Given each policy, a spread of 0.5 and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour and `coldHours` is 0.
- Given a static policy with 0 heating hours and seed 7, when the run ends, then the backstop heating is more than 500 kWh and the unmet draw is 0 kWh.
- Given a home with an element of 0.2 kW, and the static policy with 0 heating hours, when the run ends, then the unmet draw is more than 0 kWh and `coldHours` is more than 0.

### CAP-homesim.R3 · Totals and ratios
- Given 365 days, when the run ends, then each total equals the sum of its hours.
- Given 365 days, when the run ends, then solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end.
- Given 365 days, when the run ends, then the energy in the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy.
- Given 365 days, when the run ends, then `unmetKwh` plus the served draw equals `drawKwh`. The draw is the sum of the hours.
- Given 365 days, when the run ends, then the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load.
- Given 365 days and a spread of 0, when the run ends, then the draw total is 2190.0 kWh, within 0.1 kWh.
- Given 365 days, a spread of 0.25 and each seed from 1 to 5, when the run ends, then the draw total is from 2060 to 2320 kWh.
- Given 0 kW of panels and 365 days, when the run ends, then the self-consumption is 0%.
- Given 0 days, when the run ends, then each total is 0 and each ratio is 0%. The exceptions are `minTankKwh` and `finalTankKwh`, which are 10.5 kWh, the energy of the full tank at the start.

### CAP-homesim.R4 · Policies at work
- Given the static policy with `defaultStatic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours 10, 11, 12 and 13.
- Given the precomputed policy with `defaultPlan`, an error scale of 0, 1 fetch each day and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours whose solar energy is at least 0.5 kWh.
- Given the dynamic policy with `defaultDynamic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in an hour whose solar energy is more than its house load, or whose tank held less than 5.25 kWh before the hour.
- Given the static policy with `defaultStatic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the first has a higher self-consumption.
- Given the dynamic policy with `defaultDynamic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the dynamic policy has a higher self-consumption.
- Given the same policy and seed twice, when the runs end, then the two runs have the same hours.

### CAP-homesim.R5 · Robust evaluation
- Given the first seed 3 and 1 seed, when the policy is evaluated, then the mean and the worst self-consumption are the self-consumption of the run with seed 3.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean self-consumption is the average of the runs with seeds 3, 4, 5 and 6, and the worst is the lowest of them.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the worst self-consumption is not more than the mean.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean import, export and backstop heating are the averages of the runs, and the total unmet draw is their sum.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then `seeds` is 4, and `unmetSeeds` and `coldHours` are 0.
- Given 0 seeds, when the policy is evaluated, then each field is 0.
- Given the same arguments twice, when the policy is evaluated, then the two evaluations are the same.

### CAP-homesim.R6 · Tuning a static profile
- Given 2 seeds from seed 1 and 30 days, when the profile is tuned, then `candidates` is 704, and `safe` is 704.
- Given the same arguments, when the profile is tuned, then the best start is from 6 to 16, its heating hours are from 1 to 8, and its discharge hour is from 15 to 22.
- Given the same arguments, when the profile is tuned, then the evaluation is the evaluation of the best static profile over the same seeds and days.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate has a mean self-consumption more than 0.05 points above the best.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate within 0.05 points of the highest has a lower mean import than the best.
- Given the same arguments twice, when the profile is tuned, then the two results are the same.
- Given a home with 0 kW of panels, 2 seeds from seed 1 and 30 days, when the profile is tuned, then `safe` is 704 and the best mean self-consumption is 0%.

## Relies on

- CAP-scenario (used, not changed)
- CAP-forecast (used, not changed)
- CAP-hotwater (used, not changed)
- CAP-simulation (used, not changed)
- CAP-policy (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `HomeSetup` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `drawCv : Float` (the spread of that draw from day to day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day with a spread of 0.25, 10 fetches each day, and an error scale of 1.0
  - errors: none
- `HomeHour` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `day` and `hour` (each a `Nat`), `pvKwh`, `houseLoadKwh` (the base load and the flexible load), `drawKwh`, `askKwh` (the heating that the policy asked for), `heatKwh`, `backstopKwh`, `unmetKwh` and `tankKwh` (the energy in the tank after the hour), each a `Float`, `allowCharge` and `allowDischarge`, each a `Bool`, and `flow : Flow`.
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
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `Battery` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `capacityKwh` and `powerKw`, each a `Float`
  - errors: none
- `Flow` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `directKwh`, `chargeKwh`, `dischargeKwh`, `exportKwh`, `importKwh`, `lossKwh` and `socKwh`.
  - errors: none
- `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, whether it may charge, whether it may discharge, and the solar energy and the load of the hour
  - out: the flows of the hour, with the same rules as `stepHour`. The battery charges only when it may charge, and discharges only when it may discharge.
  - errors: none
- `Action` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
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
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams
- `homeSeed` · seam: randomness · `StoragePolicySim/HomeSim.lean`
  - in: the `seed` argument of `runHome`, `evaluate` and `tuneStatic`. The same seed gives the same weather and the same forecast.
  - errors: none

## Files

- `StoragePolicySim/HomeSim.lean`

## Check files

- `tests/CAP-homesim.lean`

## Steps

### Step 1 · Hourly home flows · [ ]

- Requirement: CAP-homesim.R1
- Check: the checks named `CAP-homesim.R1 …` in `tests/CAP-homesim.lean`
- Done when: the checks pass

### Step 2 · No cold tank · [ ]

- Requirement: CAP-homesim.R2
- Check: the checks named `CAP-homesim.R2 …` in `tests/CAP-homesim.lean`
- Done when: the checks pass

### Step 3 · Totals and ratios · [ ]

- Requirement: CAP-homesim.R3
- Check: the checks named `CAP-homesim.R3 …` in `tests/CAP-homesim.lean`
- Done when: the checks pass

### Step 4 · Policies at work · [ ]

- Requirement: CAP-homesim.R4
- Check: the checks named `CAP-homesim.R4 …` in `tests/CAP-homesim.lean`
- Done when: the checks pass

### Step 5 · Robust evaluation · [ ]

- Requirement: CAP-homesim.R5
- Check: the checks named `CAP-homesim.R5 …` in `tests/CAP-homesim.lean`
- Done when: the checks pass

### Step 6 · Tuning a static profile · [ ]

- Requirement: CAP-homesim.R6
- Check: the checks named `CAP-homesim.R6 …` in `tests/CAP-homesim.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned fifth, after the capabilities that it uses.
````

## The specs

### pdlc/specs/capabilities/CAP-homesim.md

````
# CAP-homesim · Home simulation, robust evaluation and tuning of policies

Status: active

## What it is for

CAP-homesim (home simulation) runs one policy over a home for a number of days, hour by hour.
The home has solar panels, a battery, a hot-water tank and a household load. The policy sets
the heating of the tank and the battery gate for each hour. The result shows how much of the
sun the home used itself, how much it exported, and whether the tank ever ran cold.

A caller can also evaluate a policy over many weather seeds, so that the result is robust and
not one lucky year. A caller can search for the best static profile.

## Code map

- `StoragePolicySim/HomeSim.lean`

## Interface

- `HomeSetup` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `drawCv : Float` (the spread of that draw from day to day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day with a spread of 0.25, 10 fetches each day, and an error scale of 1.0
  - errors: none
- `HomeHour` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `day` and `hour` (each a `Nat`), `pvKwh`, `houseLoadKwh` (the base load and the flexible load), `drawKwh`, `askKwh` (the heating that the policy asked for), `heatKwh`, `backstopKwh`, `unmetKwh` and `tankKwh` (the energy in the tank after the hour), each a `Float`, `allowCharge` and `allowDischarge`, each a `Bool`, and `flow : Flow`.
  - errors: none
- `HomeTotals` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh` (the house load, the heating and the backstop heating), `importKwh`, `exportKwh`, `batteryLossKwh`, `tankLossKwh`, `heatKwh`, `backstopKwh`, `drawKwh`, `unmetKwh`, `minTankKwh`, `finalTankKwh`, `selfConsumption` and `selfSufficiency`. The field `coldHours` is a `Nat`.
  - errors: none
- `HomeResult` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HomeHour` and `totals : HomeTotals`
  - errors: none
- `runHome (setup : HomeSetup) (policy : Policy) (seed days : Nat) : HomeResult` · function · `StoragePolicySim/HomeSim.lean` · proposed
  - in: a home, a policy, a seed, and the days of the run
  - out: the hours and the totals of the run
  - errors: none
- `Evaluation` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `meanSelfConsumption`, `worstSelfConsumption`, `meanSelfSufficiency`, `meanImportKwh`, `meanExportKwh`, `meanBackstopKwh` and `totalUnmetKwh` are each a `Float`. The fields `seeds`, `unmetSeeds` and `coldHours` are each a `Nat`.
  - errors: none
- `evaluate (setup : HomeSetup) (policy : Policy) (seed seeds days : Nat) : Evaluation` · function · `StoragePolicySim/HomeSim.lean` · proposed
  - in: a home, a policy, the first seed, the count of seeds, and the days of each run
  - out: the evaluation over the seeds `seed` to `seed + seeds - 1`
  - errors: none
- `TuneResult` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `best : StaticParams`, `evaluation : Evaluation`, `candidates : Nat` and `safe : Nat`.
  - errors: none
- `tuneStatic (setup : HomeSetup) (seed seeds days : Nat) : TuneResult` · function · `StoragePolicySim/HomeSim.lean` · proposed
  - in: a home, the first seed, the count of seeds, and the days of each run
  - out: the best static profile that the search finds, its evaluation, the count of candidates, and the count of safe candidates
  - errors: none

### Test seams

- `homeSeed` · seam: randomness · `StoragePolicySim/HomeSim.lean` · proposed
  - in: the `seed` argument of `runHome`, `evaluate` and `tuneStatic`. The same seed gives the same weather and the same forecast.
  - errors: none

## Requirements

### CAP-homesim.R1 · Hourly home flows

Status: ready · Intents: IN-0008

The run starts with a full tank (`startState`) and an empty battery (assumed). In each hour,
the policy gives an action. The tank takes the draw, the heating and the backstop by
CAP-hotwater (hot-water tank), with the hour of the day. The heating and the backstop heating
join the house load. The battery then runs the hour with its gate, by `stepHourGated`. The
draw of an hour is the `drawKwh` of the home for its day and hour, times the `drawFactor` of
the seed, the day and the spread `drawCv`.

A static policy uses its profile of the hour. A precomputed policy makes its plan at hour 0
of each day, from the forecast of the fetch at hour 0, the energy in the tank, and the draw
that the day is expected to have, which is the sum of the `drawKwh` of its 24 hours, without
the factor of the day (assumed). A dynamic policy sees the tank, the battery, the
surplus of the hour (the solar energy less the house load, and never less than 0), and the
forecast for the rest of the day from the latest fetch. The forecast is made only for a policy that reads it (assumed). It uses the seed of the run.

In these lines, the home is `defaultHome`, the policy is the static policy with
`defaultStatic`, the seed is 7, and the run is 365 days, unless the line says otherwise. The
tolerance is 0.000000001 kWh.

- Given the default run, when it ends, then it has 8760 hours, in order of day, then hour.
- Given the default run, when each hour is read, then its solar energy and its house load are those of the scenario hour for the same site, seed and days.
- Given the default run, when each hour is read, then `askKwh` is the heating of its hour in the static profile, and the battery gate is the gate of that hour.
- Given the default run, when each hour is read, then its tank energy is the `tankStep` result for the tank state of the hour before, its hour of the day, its request and its draw. The first hour starts with `startState` of the tank.
- Given the default run, when each hour is read, then its flow is the `stepHourGated` flow for the battery energy of the hour before, its gate, its solar energy, and its house load plus its heating plus its backstop heating. The first hour starts with 0 kWh.
- Given the default run, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour, times the `drawFactor` for seed 7, its day and the spread 0.25.
- Given the default run with a spread of 0, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour.
- Given the precomputed policy with `defaultPlan`, 1 fetch each day and seed 7, when each hour of day `d` is read, then its `askKwh` is the `heatKwh` of that hour in `planDay`. The call uses the first 24 values of `hourlyEnergy` of the fetch at hour `24 × d`, the tank energy after hour 23 of day `d - 1` (10.5 kWh for day 0), and the sum of `drawKwh` for the 24 hours of day `d`, without the factor of the day.
- Given 0 days, when the run ends, then it has no hours.

### CAP-homesim.R2 · No cold tank

Status: ready · Intents: IN-0008

The thermostat of the tank keeps the hot water ready for every policy. Thus, no hour has an
unmet draw, the tank never ends an hour below its floor, and the tank is full at least once
each day (assumed). The backstop heating is the price of a policy that lets the tank fall.
The days are different, because the draw changes from day to day. Thus, the lines hold also
with the spread of 0.25 of the default home, and with a spread of 0.5.

In these lines, the home is `defaultHome`, the run is 365 days, and the tolerance is 0.000000001
kWh. A policy is the static policy with `defaultStatic`, the precomputed policy with `defaultPlan`,
or the dynamic policy with `defaultDynamic`.

- Given each policy and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour.
- Given each policy and the seeds 1 to 5, when the run ends, then the tank holds at least 2.1 kWh after each hour, and `coldHours` is 0.
- Given each policy and the seeds 1 to 5, when the run ends, then each day has an hour after which the tank is full, within 0.000000001 kWh.
- Given each policy, a spread of 0.5 and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour and `coldHours` is 0.
- Given a static policy with 0 heating hours and seed 7, when the run ends, then the backstop heating is more than 500 kWh and the unmet draw is 0 kWh.
- Given a home with an element of 0.2 kW, and the static policy with 0 heating hours, when the run ends, then the unmet draw is more than 0 kWh and `coldHours` is more than 0.

### CAP-homesim.R3 · Totals and ratios

Status: ready · Intents: IN-0008

The totals add up the hours. The self-consumption is the solar energy less the export, as a
percentage of the solar energy. The self-sufficiency is the load less the import, as a
percentage of the load. A ratio with nothing to divide by is 0% (assumed). The solar energy and
the energy of the tank and the battery balance.

In these lines, the home is `defaultHome`, the policy is the static policy with
`defaultStatic`, and the seed is 7, unless the line says otherwise. The tolerance is 0.01 kWh.

- Given 365 days, when the run ends, then each total equals the sum of its hours.
- Given 365 days, when the run ends, then solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end.
- Given 365 days, when the run ends, then the energy in the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy.
- Given 365 days, when the run ends, then `unmetKwh` plus the served draw equals `drawKwh`. The draw is the sum of the hours.
- Given 365 days, when the run ends, then the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load.
- Given 365 days and a spread of 0, when the run ends, then the draw total is 2190.0 kWh, within 0.1 kWh.
- Given 365 days, a spread of 0.25 and each seed from 1 to 5, when the run ends, then the draw total is from 2060 to 2320 kWh.
- Given 0 kW of panels and 365 days, when the run ends, then the self-consumption is 0%.
- Given 0 days, when the run ends, then each total is 0 and each ratio is 0%. The exceptions are `minTankKwh` and `finalTankKwh`, which are 10.5 kWh, the energy of the full tank at the start.

### CAP-homesim.R4 · Policies at work

Status: ready · Intents: IN-0008

Each kind of policy acts as CAP-policy (daily-profile policies) says. A static policy heats
only in its window. A precomputed policy heats only in hours that its forecast calls sunny. A
dynamic policy heats only when it has a surplus or the tank is low. Heating the tank in the sun
makes the home use more of its sun.

In these lines, the home is `defaultHome` and the run is 365 days, unless the line says
otherwise. The tolerance of a solar energy against 0.5 kWh is 0.000001 kWh.

- Given the static policy with `defaultStatic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours 10, 11, 12 and 13.
- Given the precomputed policy with `defaultPlan`, an error scale of 0, 1 fetch each day and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours whose solar energy is at least 0.5 kWh.
- Given the dynamic policy with `defaultDynamic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in an hour whose solar energy is more than its house load, or whose tank held less than 5.25 kWh before the hour.
- Given the static policy with `defaultStatic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the first has a higher self-consumption.
- Given the dynamic policy with `defaultDynamic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the dynamic policy has a higher self-consumption.
- Given the same policy and seed twice, when the runs end, then the two runs have the same hours.

### CAP-homesim.R5 · Robust evaluation

Status: ready · Intents: IN-0008

An evaluation runs the policy for each seed from the first seed, and sums up the runs. The
mean values are the averages of the runs. The worst self-consumption is the lowest of the runs.
`unmetSeeds` counts the runs with an unmet draw. A count of 0 seeds gives 0 in every field
(assumed).

In these lines, the home is `defaultHome`, the policy is the static policy with `defaultStatic`,
and each run is 365 days, unless the line says otherwise. The tolerance is 0.000000001.

- Given the first seed 3 and 1 seed, when the policy is evaluated, then the mean and the worst self-consumption are the self-consumption of the run with seed 3.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean self-consumption is the average of the runs with seeds 3, 4, 5 and 6, and the worst is the lowest of them.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the worst self-consumption is not more than the mean.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean import, export and backstop heating are the averages of the runs, and the total unmet draw is their sum.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then `seeds` is 4, and `unmetSeeds` and `coldHours` are 0.
- Given 0 seeds, when the policy is evaluated, then each field is 0.
- Given the same arguments twice, when the policy is evaluated, then the two evaluations are the same.

### CAP-homesim.R6 · Tuning a static profile

Status: ready · Intents: IN-0008

The tuner tries each static profile of a fixed grid, with the element power of the home
tank: a start from 6 to 16, from 1 to 8 heating hours, and discharge from 15 to 22. That is 704
candidates. It evaluates each candidate. A candidate is safe when no seed has an unmet draw.
The best candidate is the safe candidate with the highest mean self-consumption. A safe
candidate within 0.05 points of the highest has the same standing, and then the lowest mean
import wins. A tie goes to the first candidate, in the order of the start, the heating hours
and the discharge hour (assumed). If no candidate is safe, the best is the candidate with the
lowest total unmet draw (assumed).

In these lines, the home is `defaultHome`. The tolerance is 0.000000001.

- Given 2 seeds from seed 1 and 30 days, when the profile is tuned, then `candidates` is 704, and `safe` is 704.
- Given the same arguments, when the profile is tuned, then the best start is from 6 to 16, its heating hours are from 1 to 8, and its discharge hour is from 15 to 22.
- Given the same arguments, when the profile is tuned, then the evaluation is the evaluation of the best static profile over the same seeds and days.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate has a mean self-consumption more than 0.05 points above the best.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate within 0.05 points of the highest has a lower mean import than the best.
- Given the same arguments twice, when the profile is tuned, then the two results are the same.
- Given a home with 0 kW of panels, 2 seeds from seed 1 and 30 days, when the profile is tuned, then `safe` is 704 and the best mean self-consumption is 0%.
````

### pdlc/specs/capabilities/CAP-scenario.md

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the conditions that a strategy must handle, one hour at a time. It gives
the solar output of each hour from the season and the sun height, and a daily sky from a
seeded weather model. It also gives the household load of each hour, with a seasonal base
load and a flexible load that a strategy can move.

## Code map

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`

## Interface

- `Sky` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: `sunny`, `cloudy` or `overcast`, with `BEq`, `Repr` and `Inhabited`
  - errors: none
- `Sky.factor (sky : Sky) : Float` · function · `StoragePolicySim/Scenario.lean`
  - in: a sky
  - out: 1.0 for `sunny`, 0.5 for `cloudy`, and 0.15 for `overcast`
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `Hour` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - errors: none
- `daysInYear : Nat` · constant · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: 365
  - errors: none
- `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, the day of the year from 0, the hour of the day from 0 to 23, and a sky
  - out: the solar energy of the hour in kWh. It reads only `latitude` and `pvKw` of the site.
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Scenario.lean`
  - in: the `seed` argument of `scenario`. The same seed gives the same skies.
  - errors: none

## Requirements

### CAP-scenario.R1 · Seasonal sun

Status: verified · Intents: IN-0001

The output of an hour is the panel power, times the sine of the sun height, times the sky
factor (assumed). The sun height uses the latitude, the day of the year, and the middle of
the hour in solar time (assumed).

The declination is 23.44 degrees times sin(2π × (285 + day) / 365), where day 0 is 1 January
(assumed). The sky factor is 1.0 for sunny, 0.5 for cloudy, and 0.15 for overcast (assumed).
When the sun is below the horizon, the output is 0. In these lines, the site has 5 kW of panels,
unless the line says otherwise.

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

Status: verified · Intents: IN-0001

A seed and a number of days give one sky for each day, and the same hours each time. The
scenario starts on 1 January and gives the hours in order of day, then hour.

Each day keeps the sky of the day before with a chance of 0.6 (assumed). Else, the day takes
a new sky from the chances of its half of the year (assumed):

- Summer half: sunny 0.55, cloudy 0.30, overcast 0.15 (assumed).
- Winter half: sunny 0.20, cloudy 0.35, overcast 0.45 (assumed).

The summer half is days 90 to 272 of each year at latitude 0 or more, and the other days at
a negative latitude (assumed). After day 364, the day of the year starts again at 0.

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

Status: verified · Intents: IN-0001

The daily load includes the flexible load. The base load is the daily load less the flexible
load, spread over the hours by a fixed profile (assumed).

The profile has a morning peak and an evening peak (assumed). A seasonal factor of
1 + 0.2 × cos(2π × (day - peak) / 365) scales the base load (assumed). The peak is day 15 at
latitude 0 or more, and day 197 at a negative latitude (assumed).

By default, the flexible load uses equal parts at 18:00, 19:00 and 20:00 (assumed). The load
does not depend on the seed. In these lines, the daily load is 20 kWh with 3 kWh flexible,
unless the line says otherwise.

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.
````

### pdlc/specs/capabilities/CAP-forecast.md

````
# CAP-forecast · Simulated Solcast rooftop forecasts for policies

Status: active

## What it is for

CAP-forecast (simulated Solcast forecasts) acts like the Solcast hobbyist rooftop forecast
service, for a scenario. A fetch at an hour of the run gives 30-minute periods for the next
48 hours. Each period has an estimate, a 10% band and a 90% band. The forecast has an error
that grows with the lead time, from a seed.

A hobbyist account can fetch 10 times a day, so the fetch hours of a day come from a count
of fetches. The forecast can show as Solcast JSON, with UTC times from the longitude. A
policy reads the forecast as the solar energy of each coming hour.

## Code map

- `StoragePolicySim/Forecast.lean`

## Interface

- `Period` · type · `StoragePolicySim/Forecast.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: the hours of `scenario site seed days`, built once by the caller, the same site and seed, the error scale, and the hour of the run at which the fetch is made
  - out: the same periods as `forecast site seed days errorScale fetchHour`, where `days` is the count of hours divided by 24
  - errors: none
- `fetchHours (fetchesPerDay : Nat) : Array Nat` · function · `StoragePolicySim/Forecast.lean`
  - in: the fetches of one day, from 1 to 10
  - out: the hour of the day of each fetch, in order
  - errors: none
- `latestFetch (fetchesPerDay hour : Nat) : Nat` · function · `StoragePolicySim/Forecast.lean`
  - in: the fetches of one day, from 1 to 10, and an hour of the run
  - out: the hour of the run of the latest fetch at or before that hour
  - errors: none
- `hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float` · function · `StoragePolicySim/Forecast.lean`
  - in: the periods of a fetch, and the hour of that fetch
  - out: 48 values in kWh. Value `j` is the forecast solar energy of hour `fetchHour + j` of the run.
  - errors: none
- `forecastJson (periods : Array Period) (longitude : Float) : String` · function · `StoragePolicySim/Forecast.lean`
  - in: the periods of a fetch, and a longitude in degrees, east is positive
  - out: the Solcast reply as one line of JSON text
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Forecast.lean`
  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
  - errors: none

## Requirements

### CAP-forecast.R1 · Forecast periods

Status: verified · Intents: IN-0002

A fetch at the start of hour `h` of a run gives the periods of the next 48 hours (assumed).
Period `k`, for `k` from 1 to 96, is 30 minutes long and ends `60 × h + 30 × k` minutes
after the start of the run. A period after the end of the run is not in the fetch (assumed).

Each period has its end in minutes from the start of the run, an estimate, a 10% band and a
90% band (assumed). Each value is a mean power in kW, as Solcast gives. The actual power of
a period is the solar energy of its hour, per hour.

In these lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is
365 days, and the error scale is 1, unless the line says otherwise.

- Given a fetch at hour 0, when the forecast is made, then it has 96 periods. Their ends are 30, 60, and up to 2880 minutes.
- Given a fetch at hour 100, when the forecast is made, then the first period ends at 6030 minutes and the last at 8880 minutes.
- Given a fetch at hour 8750, when the forecast is made, then it has 20 periods, because the run ends after 10 hours.
- Given a fetch at hour 8760, when the forecast is made, then it has no period.
- Given a daily fetch at 00:00, when the forecasts are made, then no 10% band is above its estimate. No estimate is above its 90% band.
- Given a daily fetch at 00:00, when the forecasts are made, then each value is from 0 to 5 kW.
- Given a fetch at hour 0, when the forecast is made, then each period with no actual power has 0 kW in all three values.

### CAP-forecast.R2 · Forecast error

Status: verified · Intents: IN-0002

The estimate is the actual power, times 1 plus the error scale times a spread times a random
number from a normal curve (assumed). The spread is 0.05 plus 0.10 for each 24 hours of lead
time (assumed). The lead time is from the fetch to the end of the period.

The 10% band is the estimate times 1 less 1.28 times the error scale times the spread. The
90% band uses 1 plus that amount (assumed). Each value stays from 0 to the panel power. The
seed of the run gives the random numbers, and the forecast does not change the weather. The
error of a set of periods is the mean of the absolute differences from the actual power
(assumed). A sunny period is a period with an actual power of more than 0 kW (assumed).

- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given seed 7, when the same fetch is made two times, then the two forecasts are the same.
- Given seeds 7 and 8, when a fetch at hour 4000 is made with each, then at least one estimate differs.
- Given daily fetches, when sunny periods are compared, then the error 24 to 48 hours ahead is more than 0 to 4 hours ahead.
- Given a daily fetch at 00:00, when the forecasts are made, then 60% to 95% of sunny periods have the actual power in the band.

### CAP-forecast.R3 · Fetch limit

Status: verified · Intents: IN-0002

A day has from 1 to 10 fetches, because a Solcast hobbyist account has 10 calls each day
(assumed). Fetch `i` of `n` is at hour `i × 24 / n` of each day, rounded down (assumed), for
`i` from 0 to `n - 1`. At each hour, a policy sees the forecast of the latest fetch at or
before that hour.

- Given 10 fetches a day, when the fetch hours are found, then they are 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21.
- Given 3 fetches a day, when the fetch hours are found, then they are 0, 8 and 16.
- Given 1 fetch a day, when the fetch hours are found, then the only hour is 0.
- Given 10 fetches a day, when the latest fetch for hour 27 is found, then it is the fetch at hour 26.
- Given 10 fetches a day, when the latest fetch for hour 26 is found, then it is the fetch at hour 26. The latest fetch for hour 25 is at hour 24.
- Given 1 fetch a day, when the latest fetch for hour 47 is found, then it is the fetch at hour 24.

### CAP-forecast.R4 · Solcast JSON

Status: verified · Intents: IN-0002

A forecast shows as the JSON of the Solcast hobbyist rooftop forecast reply. The text is
`{"forecasts":[` and the periods, split by commas, then `]}`, with no spaces or line breaks
(assumed). Each period is `{"pv_estimate":<v>,"pv_estimate10":<v>,"pv_estimate90":<v>,"period_end":"<time>","period":"PT30M"}`.

Each value has four decimals (assumed). The run starts on 1 January 2025 at 00:00 solar
time (assumed). The UTC time is the solar time less the longitude divided by 15 hours,
rounded to the nearest 30 minutes, and a tie rounds up (assumed). The time has the form
`2025-01-01T00:30:00.0000000Z`.

- Given longitude 0 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T00:30:00.0000000Z`.
- Given longitude 174.8 and a fetch at hour 0, when the JSON is made, then the first period ends at `2024-12-31T13:00:00.0000000Z`.
- Given longitude -75 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T05:30:00.0000000Z`.
- Given longitude 0 and a fetch at hour 8759, when the JSON is made, then the last period ends at `2026-01-01T00:00:00.0000000Z`.
- Given an error scale of 0 and a fetch at hour 4116, when the JSON is made, then each `pv_estimate` has four decimals.
- Given a fetch at hour 0, when the JSON is made, then each period has the five fields in the order above, and `"period":"PT30M"`.

### CAP-forecast.R5 · Hourly forecast energy

Status: verified · Intents: IN-0002

A policy reads a fetch as the forecast solar energy of each coming hour. Value `j` is the
estimate of the first period of hour `fetchHour + j`, plus the estimate of the second, each
times 0.5 hours. The array always has 48 values. An hour with no period in the fetch has the
value 0 (assumed).

- Given an error scale of 0 and a fetch at hour 0, when the hourly energy is made, then value `j` equals the solar output of hour `j` of the scenario for `j` from 0 to 47. The tolerance is 0.000001 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then it has 48 values, each from 0 to 5 kWh.
- Given a fetch at hour 8750, when the hourly energy is made, then it has 48 values. Values 10 to 47 are 0 kWh.
- Given a fetch at hour 8760, when the hourly energy is made, then it has 48 values, each 0 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then the sum of the 48 values is 0.5 times the sum of the estimates of the 96 periods. The tolerance is 0.000001 kWh.

### CAP-forecast.R6 · Forecast from built hours

Status: ready · Intents: IN-0008

A caller that makes many fetches builds the hours of the scenario once. `forecastOf` gives the
same periods as `forecast`, from these hours, and does not build the scenario again. A set of
hours that is empty has no period in any fetch.

- Given the hours of `scenario` for seed 7 and 365 days at latitude 45 with 5 kW of panels, and an error scale of 1, when `forecastOf` runs for the fetch hours 0, 4116 and 8750, then each result has the same periods as `forecast` for the same arguments. Each period has the same end and the same three values.
- Given the same hours and an error scale of 0, when `forecastOf` runs for the fetch hour 4000, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given the same hours, when `forecastOf` runs for the fetch hour 8760, then it has no period.
- Given no hours, when `forecastOf` runs for the fetch hour 0, then it has no period.
- Given the same hours and seeds 7 and 8, when `forecastOf` runs for the fetch hour 4000 with the hours of each seed, then at least one estimate differs.

### CAP-forecast.R7 · Shared error of a day

Status: ready · Intents: IN-0008

A forecast that is wrong about one hour of a day is often wrong about the other hours of that
day, because one cloud front covers the whole day. Thus, the random number of R2 (forecast
error) of a period has two parts: `sqrt(0.7) × d + sqrt(0.3) × e`, where `d` is a number from
a normal curve for the day of the period, and `e` is a number from a normal curve for the
period itself in the fetch (assumed). The number `d` depends only on the seed and the day of
the run in which the period ends. Thus, two fetches of the same day share `d`. The sum of the
two parts is still a number from a normal curve, so that the bands of R2 keep their meaning.

The relative error of a sunny period is its estimate less its actual power, divided by the
actual power and by the spread. For a sunny period in a fetch with the error scale 1, it is
the random number of the period, except where the estimate is cut to the range of R2.

In these lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is
365 days, and the error scale is 1, unless the line says otherwise. A fetch at 00:00 is a
fetch at an hour that is a multiple of 24. The periods that end at 11:30 and 13:30 are those
whose end is 690 and 810 minutes into the day.

- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny periods that end at 11:30 and 13:30 of the same day are compared, then their correlation over the days that have both is from 0.55 to 0.85. Days where either estimate is cut to the range of R2 do not count.
- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny period that ends at 11:30 of a day and of the next day are compared, each from the fetch at 00:00 of its own day, then their correlation is from -0.25 to 0.25.
- Given the fetches at hour 0 and at hour 10 of each day from 0 to 364, when the relative errors of the sunny period that ends at 13:30 of that day are compared, then at least 62% of the days have the same sign in both fetches. Days with a relative error of 0 in either fetch do not count.
- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given a fetch at 00:00 of each day, when the sunny periods are compared, then 60% to 95% of them have the actual power in the band.
````

### pdlc/specs/capabilities/CAP-hotwater.md

````
# CAP-hotwater · Hot-water tank with a thermostat

Status: active

## What it is for

CAP-hotwater (hot-water tank) models an electric hot-water tank, one hour at a time. The
tank holds thermal energy in kWh above the cold inlet. The element heats the tank by the
energy that a policy asks for. A thermostat with a cut-in level adds backstop heating, so that
the tank is never cold. The tank also heats to full once each day, because water that stays
below 60 °C can grow legionella bacteria. The household draws hot water by a daily profile
that changes with the season, and with a random factor for each day.

## Code map

- `StoragePolicySim/HotWater.lean`

## Interface

- `TankConfig` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams

- `drawSeed` · seam: randomness · `StoragePolicySim/HotWater.lean` · proposed
  - in: the `seed` argument of `drawFactor`. The same seed gives the same factors.
  - errors: none

## Requirements

### CAP-hotwater.R1 · Standby loss and draw

Status: ready · Intents: IN-0008

In each hour, the tank first loses a share of its energy, 0.6% in the default tank (assumed).
That is 1.5 kWh in a day for a full tank, near the average of the New Zealand tanks. Then the
household draws hot water. The tank serves the smaller of the draw and the energy that it
holds. The rest of the draw is the unmet draw.

In these lines, the tank is the default tank with a cut-in of 0 kWh, so that the thermostat
stays out of the line. The hour is 12, the thermostat is off, and the tank was full today.
The request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given 8.0 kWh stored and no draw, when the hour runs, then the loss is 0.048 kWh and the tank holds 7.952 kWh.
- Given 8.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.048 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 6.452 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.006 kWh, the served draw is 0.994 kWh and the unmet draw is 1.006 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.063 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits

Status: ready · Intents: IN-0008

The element heats the tank by the energy that the policy asks for. The heating is never more
than the element power for one hour, and never more than the room that the tank has left.
The draw of the hour comes before the heating (assumed). Thus, a tank that holds too little
energy has an unmet draw, also when the policy asks for heating in the same hour.

In these lines, the tank is the default tank with a cut-in of 0 kWh, the hour is 12, the
thermostat is off, and the tank was full today. The draw is 0 kWh, unless the line says
otherwise. The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.97 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.97 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.554 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.988 kWh and the unmet draw is 0.512 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat

Status: ready · Intents: IN-0008

After the heating of the policy, the thermostat decides. It cuts in when the tank holds less
than the cut-in level, 5.25 kWh in the default tank, which is half of the capacity (assumed).
Once in, it stays on from hour to hour, until the tank is full. That is the dead band of a
real thermostat. A tank is full when it holds its capacity, within 0.000000001 kWh.

While the thermostat is on, the backstop heating is the element power that the policy left in
the hour, and never more than the room that the tank has left. The backstop heating counts
apart from the heating that the policy asked for. When the thermostat is off, the backstop
heating is 0 kWh.

In these lines, the tank is the default tank, the hour is 12, the thermostat is off, the tank
was full today, the draw is 0 kWh and the request is 0 kWh, unless the line says otherwise.
The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 7.97 kWh and the thermostat is on.
- Given 6.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh, the tank holds 5.964 kWh and the thermostat is off.
- Given 6.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 8.964 kWh and the thermostat is on.
- Given 9.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and the thermostat is off.
- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the backstop heating is 0 kWh. The tank holds 6.97 kWh and the thermostat is off.
- Given 4.0 kWh stored and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 2.0 kWh. The tank holds 6.976 kWh and the thermostat is on.
- Given 9.0 kWh stored, the thermostat on and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 0.554 kWh. The tank holds 10.5 kWh and the thermostat is off.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the unmet draw is 1.006 kWh, the backstop heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a cut-in of 0 kWh and 1.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh.

### CAP-hotwater.R4 · Hot-water draw profile

Status: ready · Intents: IN-0008

The household draws more hot water in the morning and in the evening. The hours of a day share
the daily energy by a fixed profile with a peak at 07:00 and a peak at 19:00 (assumed). A
seasonal factor of 1 + 0.15 × cos(2π × (day - peak) / 365) scales the daily energy, because
the cold inlet is colder in winter (assumed). The peak is day 15 at latitude 0 or more, and
day 197 at a negative latitude (assumed).

In these lines, the daily energy is 6.0 kWh, unless the line says otherwise.

- Given latitude 45, when the draw of each hour of days 0 to 364 is added, then the sum is 2190.0 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the 24 hours of day 100 are added, then the sum is 6.0 × (1 + 0.15 × cos(2π × 85 / 365)) kWh. The tolerance is 0.000001 kWh.
- Given latitude 45, when the days 15 and 197 are compared, then the draw of day 15 is 1.34 to 1.37 times the draw of day 197.
- Given latitude -41, when the days 15 and 197 are compared, then the draw of day 197 is 1.34 to 1.37 times the draw of day 15.
- Given latitude 45, when the hours of day 100 are compared, then hour 7 draws more than hour 3, and hour 19 draws more than hour 13.
- Given a daily energy of 0.0 kWh, when each hour of day 100 is read, then each draw is 0 kWh.

### CAP-hotwater.R5 · Daily full heating

Status: ready · Intents: IN-0008

The tank is full at least once each day, so that the stored water stays hot enough against
legionella bacteria (assumed). From the guard hour, 20 in the default tank (assumed), the
thermostat cuts in when the tank has not been full since hour 0 of the day. It stays on until
the tank is full, as in R3. The state `fullToday` is false at the end of hour 0, unless the
tank is full after that hour. It becomes true in the hour in which the tank is full, and it
stays true to the end of the day.

In these lines, the tank is the default tank, the thermostat is off, the draw is 0 kWh and
the request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given hour 20, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 19, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh, the tank holds 8.946 kWh and `fullToday` is false.
- Given hour 20, 9.0 kWh stored and a tank that was full today, when the hour runs, then the backstop heating is 0 kWh and the tank holds 8.946 kWh.
- Given hour 22, 4.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 6.976 kWh and the thermostat is on.
- Given hour 0, 10.5 kWh stored and a tank that was full the day before, when the hour runs, then the tank holds 10.437 kWh and `fullToday` is false.
- Given hour 0, 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 12, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given a guard hour of 24, hour 23, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given the start state of the default tank, when `startState` is read, then the tank holds 10.5 kWh, the thermostat is off and `fullToday` is true.

### CAP-hotwater.R6 · Daily draw factor

Status: ready · Intents: IN-0008

A household draws more hot water on some days, and less on others. The factor of a day is
`exp(cv × z - cv × cv / 2)`, where `cv` is the spread of the draw and `z` is a random number
from a normal curve (assumed). The number `z` depends only on the seed and the day. Thus, the
mean of the factor is 1, and a spread of 0 gives the factor 1.

- Given a spread of 0, when the factors of days 0 to 364 are read, then each is 1.0. The tolerance is 0.000000000001.
- Given seed 7 and a spread of 0.25, when the factors of days 0 to 4999 are read, then each is more than 0. Their mean is from 0.98 to 1.02, and their standard deviation is from 0.23 to 0.27.
- Given seed 7 and a spread of 0.5, when the factors of days 0 to 4999 are read, then their mean is from 0.97 to 1.03, and their standard deviation is from 0.48 to 0.58.
- Given seed 7 and a spread of 0.25, when the factor of the same day is read two times, then the two factors are the same.
- Given the seeds 7 and 8 and a spread of 0.25, when the factors of days 0 to 364 are compared, then at least 300 days have a different factor.
````

### pdlc/specs/capabilities/CAP-simulation.md

````
# CAP-simulation · Hourly energy flows and self-consumption results

Status: active

## What it is for

CAP-simulation (hourly energy flows) runs one strategy over a scenario, hour by hour, with
a battery. It gives the energy flows of each hour, the totals, and the totals of each
month. The totals include the self-consumption and the self-sufficiency, so that a caller
can compare strategies on the same weather.

A caller can also gate the battery by hour: charging and discharging are each allowed or
not allowed. A policy uses this gate to plan the battery with the hot-water tank.

## Code map

- `StoragePolicySim/Simulation.lean`

## Interface

- `Battery` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `capacityKwh` and `powerKw`, each a `Float`
  - errors: none
- `efficiency : Float` · constant · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: 0.95
  - errors: none
- `Flow` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `directKwh`, `chargeKwh`, `dischargeKwh`, `exportKwh`, `importKwh`, `lossKwh` and `socKwh`.
  - errors: none
- `stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, a strategy, the hour of the day, and the solar energy and the load of the hour
  - out: the flows of the hour. `socKwh` of the flow is the energy that the battery holds after the hour.
  - errors: none
- `HourResult` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hour : Hour`, `loadKwh : Float` and `flow : Flow`
  - errors: none
- `Totals` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh`, `selfUsedKwh`, `importKwh`, `exportKwh`, `lossKwh`, `finalSocKwh`, `selfConsumption` and `selfSufficiency`.
  - errors: none
- `Month` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `name : String`, `days : Nat` and `totals : Totals`
  - errors: none
- `Result` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HourResult`, `totals : Totals` and `months : Array Month`
  - errors: none
- `simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days : Nat) : Result` · function · `StoragePolicySim/Simulation.lean`
  - in: a site, a battery, a strategy, a seed, and the days of the run
  - out: the hours, the totals and the months of the run
  - errors: none
- `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean` · proposed
  - in: a battery, the energy that it holds, whether it may charge, whether it may discharge, and the solar energy and the load of the hour
  - out: the flows of the hour, with the same rules as `stepHour`. The battery charges only when it may charge, and discharges only when it may discharge.
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Simulation.lean`
  - in: the `seed` argument of `simulate`. The same seed gives the same weather.
  - errors: none

## Requirements

### CAP-simulation.R1 · Energy flows of an hour

Status: verified · Intents: IN-0001

The house first uses solar energy directly. Then the battery takes what the strategy asks,
up to the surplus, the battery power for one hour, and the free room. The rest goes to
the grid as export.

For a shortfall, the battery gives what the strategy asks, up to the shortfall, the battery
power for one hour, and the stored energy. The rest comes from the grid as import.

The battery keeps 95% of the energy that goes in, and gives 95% of the energy that comes
out (assumed). The battery is empty at the start (assumed). In these lines, the battery
holds 10 kWh with 5 kW of power, unless the line says otherwise.

- Given an empty battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given a full battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export.
- Given 9.05 kWh stored, when `greedy` meets a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery with 2 kW of power, when `greedy` meets a surplus of 3 kWh, then 2 kWh charges and 1 kWh is export.
- Given 1.9 kWh stored, when `greedy` meets a shortfall of 2 kWh, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored, when `none` meets 3 kWh of solar and 1 kWh of load, then 2 kWh is export. The battery still holds 1.9 kWh.
- Given `greedy` and seed 7, when the simulation runs 365 days, then the first hour imports its full load.

### CAP-simulation.R2 · Battery limits

Status: verified · Intents: IN-0001

Over a run, the battery never goes past its power or its capacity. The energy of each run
balances, with the battery losses included. In these lines, the site is at latitude 45
with 5 kW of panels and 20 kWh of daily load, 3 kWh of it flexible. The seed is 7, unless
the line says otherwise.

- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then no hour charges or discharges over 2 kWh.
- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then the battery holds 0 to 5 kWh each hour.
- Given a 10 kWh battery, when `greedy` runs 365 days, then solar plus import equals load, export, losses and the stored energy. The tolerance is 0.01 kWh.
- Given a battery of 0 kWh, when `greedy` and `none` each run 365 days, then the two runs have the same totals.

### CAP-simulation.R3 · Totals and ratios

Status: verified · Intents: IN-0001

The totals add up the hours of the run. The self-consumption is the solar energy less the
export, as a percentage of the solar energy. The self-sufficiency is the load less the
import, as a percentage of the load. A ratio with nothing to divide by is 0% (assumed).

- Given latitude 45 and `none`, when the simulation runs 365 days, then each total equals the sum of its hours. The tolerance is 0.01 kWh.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-consumption is 100 × (solar - export) / solar.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-sufficiency is 100 × (load - import) / load.
- Given 0 kW of panels, when `greedy` runs 365 days, then the self-consumption is 0% and the self-sufficiency is 0%.
- Given 0 days, when `greedy` runs, then each total is 0, each ratio is 0%, and there are no months.

### CAP-simulation.R4 · Monthly totals

Status: verified · Intents: IN-0001

The result has the totals of each calendar month in the run, in order. A year has 365
days, with no leap day (assumed). Each month also has its own two ratios.

- Given 365 days, when `greedy` runs, then the result has 12 months. Their days are 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31.
- Given 365 days, when `greedy` runs, then the solar totals of the 12 months add up to the solar total of the run. The tolerance is 0.01 kWh.
- Given 400 days, when `greedy` runs, then the result has 14 months. The last month is February with 4 days.
- Given 10 days, when `greedy` runs, then the result has one month, January with 10 days.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then July has more than twice the solar energy of December.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then the July self-sufficiency is more than the January self-sufficiency.

### CAP-simulation.R5 · Strategy order

Status: verified · Intents: IN-0001

On the same weather, a battery must raise the self-consumption, and a later discharge must
not raise it. In these lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of
daily load, 3 kWh of it flexible. The seed is 7, and each run is 365 days.

- Given a battery of 10 kWh with 5 kW of power, when `none` and `greedy` run, then `greedy` has the higher self-consumption.
- Given a battery of 10 kWh with 5 kW of power, when `evening` and `greedy` run, then `evening` has a self-consumption no higher than `greedy`.
- Given a battery of 0 kWh, when `none` and `shift` run, then `shift` has the higher self-consumption.

### CAP-simulation.R6 · Allowed battery use

Status: ready · Intents: IN-0008

`stepHourGated` runs an hour as `stepHour` does with the `greedy` strategy, but a battery
that may not charge keeps the surplus as export, and a battery that may not discharge leaves
the shortfall as import. The battery limits of R1 and R2 still hold. In these lines, the
battery holds 10 kWh with 5 kW of power, unless the line says otherwise. The tolerance is
0.000000001 kWh.

- Given an empty battery that may charge and discharge, when the hour has 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given an empty battery that may not charge, when the hour has 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export. The battery still holds 0 kWh.
- Given 1.9 kWh stored and a battery that may discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored and a battery that may not discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 0 kWh and the import is 2.0 kWh. The battery still holds 1.9 kWh.
- Given 9.05 kWh stored and a battery that may charge, when the hour has a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery that may not charge and may not discharge, when an hour has a surplus of 2 kWh, then the export is 2 kWh. When the hour has a shortfall of 2 kWh, then the import is 2 kWh.
- Given a battery that may charge and discharge, when each of the 24 hours of day 100 of a run with latitude 45 and seed 7 runs with the battery energy of the hour before, then each flow equals the flow of `stepHour` with `greedy`. The tolerance is 0.000000001 kWh.
- Given a battery that may charge, and may discharge only from 17:00, when the same 24 hours run, then each flow equals the flow of `stepHour` with `evening`. The tolerance is 0.000000001 kWh.
````

### pdlc/specs/capabilities/CAP-policy.md

````
# CAP-policy · Daily-profile policies for the hot-water tank and the battery

Status: active

## What it is for

CAP-policy (daily-profile policies) decides, for each hour, how much heating the hot-water
tank asks for, and whether the battery may charge and may discharge. It has three kinds of
policy. A static policy repeats one fixed profile each day. A precomputed policy makes a
day-ahead plan from the solar forecast. A dynamic policy decides each hour from the state of
the tank and the surplus of that hour.

## Code map

- `StoragePolicySim/Policy.lean`

## Interface

- `Action` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Observation` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `hour : Nat`, and `tankKwh`, `socKwh`, `surplusKwh` and `forecastRestKwh`, each a `Float`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `Policy.name (policy : Policy) : String` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a policy
  - out: `"static"`, `"precomputed"` or `"dynamic"`
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `planDay (cfg : TankConfig) (params : PlanParams) (forecastKwh : Array Float) (tankKwh expectedDrawKwh : Float) : Array Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a tank, the parameters of a precomputed policy, the forecast solar energy of the 24 hours of the day, the energy in the tank at the start of the day, and the hot water that the household is expected to draw in the day
  - out: 24 actions, one for each hour of the day
  - errors: none
- `dynamicAction (cfg : TankConfig) (params : DynamicParams) (obs : Observation) : Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a tank, the parameters of a dynamic policy, and what the policy sees in the hour
  - out: the action of the hour
  - errors: none

### Test seams

none

## Requirements

### CAP-policy.R1 · Static profile

Status: ready · Intents: IN-0008

A static policy repeats one profile each day. The tank asks for the element power in each hour
from `heatStart` for `heatHours` hours, and for nothing in the other hours. The window stops at
the end of the day (assumed). The battery may always charge. It may discharge from the hour
`dischargeFrom` to the end of the day, and a value of 24 never lets it discharge (assumed).

In these lines, the parameters are `defaultStatic`, unless the line says otherwise.

- Given the default parameters, when the profile is made, then it has 24 actions.
- Given the default parameters, when the profile is made, then hours 10, 11, 12 and 13 ask for 3.0 kWh. Hours 9 and 14 ask for 0 kWh.
- Given the default parameters, when the profile is made, then the battery may discharge in hours 17 and 23, and may not discharge in hours 0 and 16.
- Given the default parameters, when the profile is made, then the battery may charge in each hour.
- Given 0 heating hours, when the profile is made, then each hour asks for 0 kWh.
- Given a start of 22 and 2 heating hours, when the profile is made, then hours 22 and 23 ask for 3.0 kWh. Hour 21 asks for 0 kWh.
- Given a start of 23 and 5 heating hours, when the profile is made, then hour 23 asks for 3.0 kWh. Hour 0 asks for 0 kWh.
- Given an element of 1.5 kW, when the profile is made, then each heating hour asks for 1.5 kWh.
- Given discharge from 24, when the profile is made, then the battery may not discharge in any hour.

### CAP-policy.R2 · Day-ahead plan

Status: ready · Intents: IN-0008

A precomputed policy makes one plan at the start of the day. The need is the target less the
energy in the tank, plus the hot water that the household is expected to draw, and never
less than 0 (assumed). Only an hour with a forecast of at least `minSolarKwh` can heat.
The plan gives the element power to these hours, from the highest forecast to the lowest,
until the need is met. A tie goes to the earlier hour (assumed). If the hours cannot meet
the need, the rest of the need stays unplanned. The battery rules are those of R1, with
`dischargeFrom` of the plan.

In these lines, the tank is the default tank and the parameters are `defaultPlan` with a target
of 9.0 kWh, unless the line says otherwise.

- Given a forecast of 1.0, 2.0, 3.5, 3.0, 4.0 and 1.5 kWh in hours 9 to 14 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hours 10, 11, 12 and 13 ask for 2.0, 3.0, 3.0 and 3.0 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 9.0 kWh in the tank and an expected draw of 0.5 kWh, when the day is planned, then hour 13 asks for 0.5 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 10.0 kWh in the tank and an expected draw of 0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.4 kWh in each hour, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.5 kWh in hour 12 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hour 12 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a minimum forecast of 0.0 kWh, a forecast of 0 kWh in each hour, 9.0 kWh in the tank and an expected draw of 3.0 kWh, when the day is planned, then hour 0 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a forecast of 2.0 kWh in hours 10 to 14, 9.0 kWh in the tank and an expected draw of 4.0 kWh, when the day is planned, then hour 10 asks for 3.0 kWh and hour 11 asks for 1.0 kWh.
- Given the default parameters, when a day is planned, then the battery may charge in each hour, may discharge in hour 17, and may not discharge in hour 16.

### CAP-policy.R3 · Dynamic action

Status: ready · Intents: IN-0008

A dynamic policy decides each hour from what it sees. First it soaks up surplus: when the
hour has a solar surplus and the tank holds less than the target, the tank asks for the
smallest of the element power, the surplus and the room to the target. If not, and the tank
holds less than the low level, and the forecast for the rest of the day is less than the
lack, the tank asks for the smaller of the element power and the lack. The lack is the low
level less the energy in the tank. In every other case the tank asks for 0 kWh. The battery rules are those of R1, with
`dischargeFrom` of the policy. The surplus is 0 or more (assumed).

In these lines, the tank is the default tank and the parameters are `defaultDynamic` with a low
level of 4.0 kWh and a target of 9.0 kWh, unless the line says otherwise.

- Given a surplus of 2.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 2.0 kWh.
- Given a surplus of 5.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 5.0 kWh and 8.0 kWh in the tank, when the hour is decided, then the tank asks for 1.0 kWh.
- Given a surplus of 5.0 kWh and 9.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh. With 9.5 kWh in the tank, the tank asks for 0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh for the rest of the day, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus, 0.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 1.0 kWh, 3.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given hour 16, when the hour is decided, then the battery may charge and may not discharge. Given hour 17, the battery may charge and may discharge.

### CAP-policy.R4 · Defaults and names

Status: ready · Intents: IN-0008

The defaults give a sensible start for a home with the default tank (assumed). The target is a
full tank, because the tank must be full once a day for the legionella guard, and the sun is
cheaper than the grid for that heating (assumed). A policy has a name that a command can print.

- Given `defaultStatic`, when it is read, then the heating starts at 10, lasts 4 hours, discharge starts at 17, and the element is 3.0 kW.
- Given `defaultPlan`, when it is read, then the target is 10.5 kWh, the minimum forecast is 0.5 kWh, and discharge starts at 17.
- Given `defaultDynamic`, when it is read, then the low level is 5.25 kWh, the target is 10.5 kWh, and discharge starts at 17.
- Given a static, a precomputed and a dynamic policy, when the names are read, then they are `static`, `precomputed` and `dynamic`.
````

### pdlc/specs/design/DES-errors.md

````
# DES-errors · The project's error codes

Status: agreed · Default: yes · Ask at init: no

## Rule

Each error that the system can give has a code here, in `UPPER_SNAKE_CASE`. Acceptance
lines, Interface entries, and checks all use these codes. Thus, a check can expect the
exact error.

| Code | Meaning | Whose fault | Retry helps? |
|---|---|---|---|
| `UNKNOWN_COMMAND` | The first word of the command line is not a command | caller | no |
| `UNKNOWN_OPTION` | An option or a word that the command does not take | caller | no |
| `MISSING_VALUE` | An option that needs a value comes last, with no value | caller | no |
| `BAD_NUMBER` | The value of a number option is not a number of the right form | caller | no |
| `OUT_OF_RANGE` | A number is outside the range of its option | caller | no |
| `UNKNOWN_STRATEGY` | The name of the strategy is not in the list of strategies | caller | no |
| `UNKNOWN_POLICY` | The name of the policy is not in the list of policies | caller | no |

When a requirement needs a new error, add a row. When the meaning is the same, use the
existing code again.

Add rows at intake and ready. Do not add a row while a change is in tests, build, or
verify. When you add a row, leave `Default:` as it is. Write each row the same way:

- The code in backticks.
- "Whose fault": `caller`, `system`, or `outside service`.
- "Retry helps?": `yes` or `no`.

Checks and the code of the app match on the error code. Each requirement decides what a
person sees, for example a message or a status. The message or the status can omit the
error code. If the caller cannot see the error code, a check expects the exact message and
status instead.

## Why

A check that expects "an error" passes for any error, also for a typo. A named code makes
the check exact. A named code also gives callers a stable value to handle.
````

### pdlc/specs/design/DES-pdlc-check-tagging.md

````
# DES-pdlc-check-tagging · How checks name their requirement

Status: agreed · Default: yes · Ask at init: yes

## Rule

The requirement ID starts the name of the check, for example `CAP-email.R3 sends from a
template`. A check that proves two requirements names the two requirements.

If the check runner does not accept `.` or `-` in names (Python's `unittest`, for
example), write the ID with underscores instead: `test_CAP_email_R3_sends_from_a_template`.
The two forms count as the same ID. Use only one form in each project.

Lay checks out the same way everywhere:

- Put new check files in the check folder (`tests/` in a project that had none). Name
  each file after the spec it proves, in a form the runner finds: `test_CAP_email.py`,
  `CAP-email.test.js`.
- Inside a file, make one group per requirement (a test class or a `describe` block).
  Name the group with the requirement ID: `class CAP_email_R3(unittest.TestCase)`,
  `describe("CAP-email.R3", ...)`.
- Each check's name still starts with the ID, then says what it proves.

The acceptance checks of an intent go in one file for each intent, at the path of
"acceptance file" in `pdlc/config.md`. The name of the file holds the word "acceptance"
and the intent ID, for example `tests/acceptance_IN_0012.py` or
`acceptance/IN-0012.acceptance.js`. The "all" command does not run such a file. Inside the
file, make one group for each requirement, and start each check name with the requirement
ID.

## Why

The trace from a requirement to its checks is only as good as this naming. Thus, the
naming must be simple and the same everywhere.
````

### pdlc/specs/design/DES-lean-checks.md

````
# DES-lean-checks · How a Lean check file runs and reports

Status: agreed · Default: no

## Rule

Each check file is a Lean script that `lake env lean --run <file> [filter]` runs. The file
has these parts:

- One file for each spec, named after the spec: `tests/CAP-scenario.lean`. The acceptance
  file of an intent is `tests/acceptance/IN-0001.acceptance.lean`.
- The imports of the library modules that the file calls, for example
  `import StoragePolicySim.Scenario`. A check file does not import another check file.
  Thus, each file holds its own small helpers.
- `def main (args : List String) : IO UInt32`.
- Each check has a name that starts with its requirement ID and a space, for example
  `"CAP-scenario.R1 day 171 gives more than twice day 354"`.
- The checks of one requirement are together, under the comment `-- CAP-scenario.R1`.

When `main` gets a first argument, it runs only the checks whose names start with that
argument and a space. Thus, the filter `CAP-scenario.R1` does not run `CAP-scenario.R10`.

The file prints `FAIL <name>: <what went wrong>` for each failed check. Its last line is
`<n> checks, <k> failed`. It exits with 1 when `k` is more than 0, and else with 0. A
filter that matches no check gives `0 checks, 0 failed`. The checks port reads that line
as "no checks found".

A check that runs the `sim` command uses `IO.Process.output` with the command `timeout`
and the arguments `60`, `.lake/build/bin/sim`, and then the arguments of `sim`. The check
reads the exit code, stdout and stderr. A `Float` comparison uses a tolerance.

## Example

```lean
import StoragePolicySim.Scenario
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 night gives no output",
    run := do
      let v := pvOutput site45 171 0 .sunny
      return if v == 0 then none else some s!"got {v}" }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    match ← c.run with
    | none => pure ()
    | some msg => failed := failed + 1; IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
```

The toolchain is Lean 4.35.0. In this version, `String.trim` does not exist. Use
`String.trimAscii` and then `.toString`, or split with `String.splitOn`.

## Why

Lean has no standard check runner. One small form for every file gives each check a name
with its requirement ID. It also gives a filter for one requirement, and one count line for the checks
port.
````

## How the checks run (pdlc/config.md)

````
This section gives the command that runs the checks of this project, and the command that
runs only the checks for one requirement. Init writes this section. A project with no
checks yet keeps its checks in `tests/`.

- all: `lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done`
- one requirement: `lake build && for f in tests/*.lean; do lake env lean --run "$f" {req} || exit 1; done`
- check folders: `tests/`
- acceptance file: `tests/acceptance/{intent}.acceptance.lean`
- acceptance: `lake build && for f in {files}; do lake env lean --run "$f" || exit 1; done`
- ID form in check names: `dotted`
````

## The check files that exist now

- tests/CAP-scenario.lean
- tests/CAP-simulation.lean
- tests/CAP-strategies.lean
- tests/JOB-simulate.lean
- tests/acceptance/IN-0001.acceptance.lean
- tests/acceptance/IN-0002.acceptance.lean
- tests/acceptance/IN-0008.acceptance.lean
