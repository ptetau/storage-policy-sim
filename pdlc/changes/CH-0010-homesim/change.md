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
- Given the default run, when each hour is read, then its tank energy is the `tankStep` result for the tank energy of the hour before, its request and its draw. The first hour starts with 10.5 kWh.
- Given the default run, when each hour is read, then its flow is the `stepHourGated` flow for the battery energy of the hour before, its gate, its solar energy, and its house load plus its heating plus its backstop heating. The first hour starts with 0 kWh.
- Given the default run, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour.
- Given 0 days, when the run ends, then it has no hours.

### CAP-homesim.R2 · No cold tank
- Given each policy and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour.
- Given each policy and the seeds 1 to 5, when the run ends, then the tank holds at least 3.0 kWh after each hour, and `coldHours` is 0.
- Given a static policy with 0 heating hours and seed 7, when the run ends, then the backstop heating is more than 500 kWh and the unmet draw is 0 kWh.
- Given a home with an element of 0.2 kW, a floor of 3.0 kWh, and the static policy with 0 heating hours, when the run ends, then the unmet draw is more than 0 kWh and `coldHours` is more than 0.

### CAP-homesim.R3 · Totals and ratios
- Given 365 days, when the run ends, then each total equals the sum of its hours.
- Given 365 days, when the run ends, then solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end.
- Given 365 days, when the run ends, then the energy in the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy.
- Given 365 days, when the run ends, then `unmetKwh` plus the served draw equals `drawKwh`. The draw is the sum of the hours.
- Given 365 days, when the run ends, then the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load.
- Given 365 days, when the run ends, then the draw total is 2190.0 kWh, within 0.1 kWh.
- Given 0 kW of panels and 365 days, when the run ends, then the self-consumption is 0%.
- Given 0 days, when the run ends, then each total is 0 and each ratio is 0%.

### CAP-homesim.R4 · Policies at work
- Given the static policy with `defaultStatic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours 10, 11, 12 and 13.
- Given the precomputed policy with `defaultPlan`, an error scale of 0, 1 fetch each day and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours whose solar energy is at least 0.5 kWh.
- Given the dynamic policy with `defaultDynamic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in an hour whose solar energy is more than its house load, or whose tank held less than 4.0 kWh before the hour.
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
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day, 10 fetches each day, and an error scale of 1.0
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
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour) and `floorKwh` (the comfort floor).
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.004 each hour, and a floor of 3.0 kWh
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the policy asked for), `backstopKwh` and `energyKwh` (the energy that the tank holds after the hour).
  - errors: none
- `tankStep (cfg : TankConfig) (energyKwh requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank, the energy that it holds, the heating that a policy asks for, and the hot water that the household draws in the hour
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
  - out: a target of 9.0 kWh, a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a low level of 4.0 kWh, a target of 9.0 kWh, and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
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
