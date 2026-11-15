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
