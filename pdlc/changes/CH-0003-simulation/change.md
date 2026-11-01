# CH-0003 · Hourly energy flows and results

Intent: IN-0001 · Scope: CAP-simulation · Status: testing · Ticket: none · Branch: pdlc/CH-0003-simulation · Base: pdlc/CH-0002-strategies

Tests-Locked: ba51e5b

## Delivers

The library runs one strategy with a battery over a scenario. It gives the flows of each
hour, the totals with the self-consumption and the self-sufficiency, and the totals of each
month.

## Requirements

### CAP-simulation.R1 · Energy flows of an hour

- Given an empty battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given a full battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export.
- Given 9.05 kWh stored, when `greedy` meets a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery with 2 kW of power, when `greedy` meets a surplus of 3 kWh, then 2 kWh charges and 1 kWh is export.
- Given 1.9 kWh stored, when `greedy` meets a shortfall of 2 kWh, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored, when `none` meets 3 kWh of solar and 1 kWh of load, then 2 kWh is export. The battery still holds 1.9 kWh.
- Given `greedy` and seed 7, when the simulation runs 365 days, then the first hour imports its full load.

### CAP-simulation.R2 · Battery limits

- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then no hour charges or discharges over 2 kWh.
- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then the battery holds 0 to 5 kWh each hour.
- Given a 10 kWh battery, when `greedy` runs 365 days, then solar plus import equals load, export, losses and the stored energy. The tolerance is 0.01 kWh.
- Given a battery of 0 kWh, when `greedy` and `none` each run 365 days, then the two runs have the same totals.

### CAP-simulation.R3 · Totals and ratios

- Given latitude 45 and `none`, when the simulation runs 365 days, then each total equals the sum of its hours. The tolerance is 0.01 kWh.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-consumption is 100 × (solar - export) / solar.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-sufficiency is 100 × (load - import) / load.
- Given 0 kW of panels, when `greedy` runs 365 days, then the self-consumption is 0% and the self-sufficiency is 0%.
- Given 0 days, when `greedy` runs, then each total is 0, each ratio is 0%, and there are no months.

### CAP-simulation.R4 · Monthly totals

- Given 365 days, when `greedy` runs, then the result has 12 months. Their days are 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31.
- Given 365 days, when `greedy` runs, then the solar totals of the 12 months add up to the solar total of the run. The tolerance is 0.01 kWh.
- Given 400 days, when `greedy` runs, then the result has 14 months. The last month is February with 4 days.
- Given 10 days, when `greedy` runs, then the result has one month, January with 10 days.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then July has more than twice the solar energy of December.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then the July self-sufficiency is more than the January self-sufficiency.

### CAP-simulation.R5 · Strategy order

- Given a battery of 10 kWh with 5 kW of power, when `none` and `greedy` run, then `greedy` has the higher self-consumption.
- Given a battery of 10 kWh with 5 kW of power, when `evening` and `greedy` run, then `evening` has a self-consumption no higher than `greedy`.
- Given a battery of 0 kWh, when `none` and `shift` run, then `shift` has the higher self-consumption.

## Relies on

- CAP-scenario (used, not changed)
- CAP-strategies (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Simulation.lean`.
A check imports `StoragePolicySim.Simulation`, which also gives the items of CH-0001
(scenario) and CH-0002 (strategies). No entry can fail, so no entry has an error code.

- `structure Battery` with `Repr` and `Inhabited` (assumed). The fields are
  `capacityKwh : Float` and `powerKw : Float`.
- `efficiency : Float`: 0.95, the share that the battery keeps of the energy in, and gives
  of the energy out.
- `structure Flow` with `Repr` and `Inhabited` (assumed). Each field is a `Float` in kWh:
  - `directKwh`: the solar energy that the house uses directly.
  - `chargeKwh`: the solar energy that goes into the battery, before the loss.
  - `dischargeKwh`: the energy that the battery gives to the house, after the loss.
  - `exportKwh` and `importKwh`: the energy to and from the grid.
  - `lossKwh`: the battery loss of the hour.
  - `socKwh`: the energy in the battery after the hour.
- `stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat)
  (pvKwh loadKwh : Float) : Flow` gives the flows of one hour. `socKwh` is the energy in
  the battery before the hour. The strategy gets the surplus and the shortfall through
  `Strategy.decide`.
- `structure HourResult` with `Repr` and `Inhabited` (assumed). The fields are
  `hour : Hour` from the scenario, `loadKwh : Float` (the base load and the placed flexible
  load), and `flow : Flow`.
- `structure Totals` with `Repr` and `Inhabited` (assumed). Each field is a `Float`:
  - `pvKwh`, `loadKwh`, `importKwh`, `exportKwh` and `lossKwh`: the sums of the hours.
  - `selfUsedKwh`: the solar energy less the export.
  - `finalSocKwh`: the energy in the battery at the end.
  - `selfConsumption` and `selfSufficiency`: each a percentage from 0 to 100.
- `structure Month` with `Repr` and `Inhabited` (assumed). The fields are `name : String`
  (`"Jan"` to `"Dec"`), `days : Nat` (the days of the run in this month), and
  `totals : Totals`.
- `structure Result` with `Repr` and `Inhabited` (assumed). The fields are
  `hours : Array HourResult`, `totals : Totals` and `months : Array Month`.
- `simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days : Nat) :
  Result`. The hours come from `scenario site seed days`. For each day, the flexible load
  comes from `Strategy.placeFlex` with the solar and the flexible load of that day.

The checks can also use these items of earlier changes, in the namespace `StoragePolicySim`:

- From CH-0001 (scenario), in `StoragePolicySim/Scenario.lean`:
  - `inductive Sky | sunny | cloudy | overcast`.
  - `structure Site` with `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`.
  - `structure Hour` with `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and
    `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float`.
  - `scenario (site : Site) (seed days : Nat) : Array Hour`.
- From CH-0002 (strategies), in `StoragePolicySim/Strategy.lean`:
  - `inductive Strategy | none | greedy | evening | shift`, written in full, for example
    `Strategy.none`.
  - `Strategy.all : List Strategy` and `Strategy.name : Strategy → String`.
  - `structure Request` with `chargeKwh : Float` and `dischargeKwh : Float`.
  - `Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request`.
  - `Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float`, with
    24 items in each array.

### Test seams

- randomness: the `seed` argument of `simulate`. The same seed gives the same weather.
- clock: none, because no line depends on the real date or time.

## Files

- `StoragePolicySim/Simulation.lean`

## Check files

- `tests/CAP-simulation.lean`

## Steps

### Step 1 · Energy flows of an hour · [ ]

- Requirement: CAP-simulation.R1
- Check: the checks named `CAP-simulation.R1 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 2 · Battery limits · [ ]

- Requirement: CAP-simulation.R2
- Check: the checks named `CAP-simulation.R2 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 3 · Totals and ratios · [ ]

- Requirement: CAP-simulation.R3
- Check: the checks named `CAP-simulation.R3 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 4 · Monthly totals · [ ]

- Requirement: CAP-simulation.R4
- Check: the checks named `CAP-simulation.R4 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 5 · Strategy order · [ ]

- Requirement: CAP-simulation.R5
- Check: the checks named `CAP-simulation.R5 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned after CH-0001 (scenario) and CH-0002 (strategies), because the simulation uses both.
- The first tests review could not see the items of CH-0001 (scenario) and CH-0002 (strategies). The skill listed these items under "Interface". The checks did not change.
