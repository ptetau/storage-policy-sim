# Review packet · CH-0003-simulation · privacy

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: d319606219d6f2af3ee86de3e71e8d17bec7fc51

## Re-review

Earlier review: 707f29d2c925b709a259d7d912e0d0faf1d54d5f

An earlier review of this remit judged this change at 707f29d2c925. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.

### Earlier problems

none

### Changes since the earlier review

````
diff --git a/StoragePolicySim/Simulation.lean b/StoragePolicySim/Simulation.lean
index 37a119f..e6544c2 100644
--- a/StoragePolicySim/Simulation.lean
+++ b/StoragePolicySim/Simulation.lean
@@ -44,15 +44,17 @@ private def limitTo (a b c : Float) : Float :=
 /-- The flows of one hour. `socKwh` is the energy in the battery before the hour. The
 battery takes what the strategy asks, up to the surplus, the power and the free room. The
 battery gives what the strategy asks, up to the shortfall, the power and the stored energy.
-The power limit applies to the energy in, and to the energy out after the loss. -/
+The power limit applies to the energy in, and to the energy out after the loss. The
+stored energy after the hour stays from 0 to the capacity, so that a rounding error of the
+floats cannot move it out of this range. -/
 def stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat)
     (pvKwh loadKwh : Float) : Flow :=
   let directKwh := min pvKwh loadKwh
   let surplusKwh := pvKwh - directKwh
   let shortfallKwh := loadKwh - directKwh
   let request := strategy.decide hour surplusKwh shortfallKwh
-  let freeRoomKwh := (battery.capacityKwh - socKwh) / efficiency
-  let chargeKwh := limitTo request.chargeKwh surplusKwh (min battery.powerKw freeRoomKwh)
+  let chargeToFillKwh := (battery.capacityKwh - socKwh) / efficiency
+  let chargeKwh := limitTo request.chargeKwh surplusKwh (min battery.powerKw chargeToFillKwh)
   let storedAfterChargeKwh := socKwh + chargeKwh * efficiency
   let dischargeKwh := limitTo request.dischargeKwh shortfallKwh
     (min battery.powerKw (storedAfterChargeKwh * efficiency))
@@ -61,7 +63,7 @@ def stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour :
     exportKwh := surplusKwh - chargeKwh,
     importKwh := shortfallKwh - dischargeKwh,
     lossKwh := chargeKwh - chargeKwh * efficiency + takenOutKwh - dischargeKwh,
-    socKwh := storedAfterChargeKwh - takenOutKwh }
+    socKwh := max 0 (min battery.capacityKwh (storedAfterChargeKwh - takenOutKwh)) }
 
 /-- One hour of a run. -/
 structure HourResult where
@@ -172,10 +174,10 @@ def simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days
     let dayHours := scenarioHours.extract (24 * day) (24 * day + 24)
     let flexKwh := strategy.placeFlex (dayHours.map (·.pvKwh)) (dayHours.map (·.flexKwh))
     let month := monthOfDay (day % daysInYear)
-    if month != openMonth.month && openMonth.days > 0 then
+    if month != openMonth.month then
       months := months.push (openMonth.close socKwh)
       openMonth := { month }
-    openMonth := { openMonth with month, days := openMonth.days + 1 }
+    openMonth := { openMonth with days := openMonth.days + 1 }
     for k in [0:dayHours.size] do
       let hour := dayHours[k]!
       let loadKwh := hour.baseLoadKwh + flexKwh[k]!
````

# Remit: privacy

Default: yes

You judge how the change treats personal data: anything that identifies a person.

- The change collects only the personal data that it needs.
- The change does not log personal data, print the data in errors, or send the data to
  an unexpected place.
- The change protects stored personal data, and keeps the data no longer than necessary.
- Where the spec says so, persons can see, correct, or remove their data.

If the change touches no personal data, reply `Result: pass` and say "not applicable".

## The change spec

````
# CH-0003 · Hourly energy flows and results

Intent: IN-0001 · Scope: CAP-simulation · Status: building · Ticket: none · Branch: pdlc/CH-0003-simulation · Base: pdlc/CH-0002-strategies

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
  - `inductive Sky | sunny | cloudy | overcast` with `BEq`, `Repr` and `Inhabited`.
  - `structure Site` with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`,
    `dailyLoadKwh` and `flexKwh`, each a `Float`.
  - `structure Hour` with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and
    `hour` (each a `Nat`), `sky : Sky`, and
    `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float`.
  - `scenario (site : Site) (seed days : Nat) : Array Hour`.
- From CH-0002 (strategies), in `StoragePolicySim/Strategy.lean`:
  - `inductive Strategy | none | greedy | evening | shift` with `BEq`, `Repr` and
    `Inhabited`. Each value is written in full, for example
    `Strategy.none`.
  - `Strategy.all : List Strategy` and `Strategy.name : Strategy → String`.
  - `structure Request` with `Repr`, and the fields `chargeKwh : Float` and
    `dischargeKwh : Float`.
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

### Step 1 · Energy flows of an hour · [x]

- Requirement: CAP-simulation.R1
- Check: the checks named `CAP-simulation.R1 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 2 · Battery limits · [x]

- Requirement: CAP-simulation.R2
- Check: the checks named `CAP-simulation.R2 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 3 · Totals and ratios · [x]

- Requirement: CAP-simulation.R3
- Check: the checks named `CAP-simulation.R3 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 4 · Monthly totals · [x]

- Requirement: CAP-simulation.R4
- Check: the checks named `CAP-simulation.R4 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

### Step 5 · Strategy order · [x]

- Requirement: CAP-simulation.R5
- Check: the checks named `CAP-simulation.R5 …` in `tests/CAP-simulation.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned after CH-0001 (scenario) and CH-0002 (strategies), because the simulation uses both.
- The first tests review could not see the items of CH-0001 (scenario) and CH-0002 (strategies). The skill listed these items under "Interface". The checks did not change.
- The second tests review could not see the derived instances of these items. The skill added them. The checks did not change.
- Build: the 123 checks of the three check files pass. No check changed since the lock `ba51e5b`.
- The first verify failed on quality. The change went back to build.
````

## The spec it covers: title and summary

````
# CAP-simulation · Hourly energy flows and self-consumption results

Status: active

## What it is for

CAP-simulation (hourly energy flows) runs one strategy over a scenario, hour by hour, with
a battery. It gives the energy flows of each hour, the totals, and the totals of each
month. The totals include the self-consumption and the self-sufficiency, so that a caller
can compare strategies on the same weather.

## Code map

- `StoragePolicySim/Simulation.lean`
````

## The requirements, in full

### CAP-simulation.R1 · Energy flows of an hour

Status: built · Intents: IN-0001

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

Status: built · Intents: IN-0001

Over a run, the battery never goes past its power or its capacity. The energy of each run
balances, with the battery losses included. In these lines, the site is at latitude 45
with 5 kW of panels and 20 kWh of daily load, 3 kWh of it flexible. The seed is 7, unless
the line says otherwise.

- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then no hour charges or discharges over 2 kWh.
- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then the battery holds 0 to 5 kWh each hour.
- Given a 10 kWh battery, when `greedy` runs 365 days, then solar plus import equals load, export, losses and the stored energy. The tolerance is 0.01 kWh.
- Given a battery of 0 kWh, when `greedy` and `none` each run 365 days, then the two runs have the same totals.

### CAP-simulation.R3 · Totals and ratios

Status: built · Intents: IN-0001

The totals add up the hours of the run. The self-consumption is the solar energy less the
export, as a percentage of the solar energy. The self-sufficiency is the load less the
import, as a percentage of the load. A ratio with nothing to divide by is 0% (assumed).

- Given latitude 45 and `none`, when the simulation runs 365 days, then each total equals the sum of its hours. The tolerance is 0.01 kWh.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-consumption is 100 × (solar - export) / solar.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-sufficiency is 100 × (load - import) / load.
- Given 0 kW of panels, when `greedy` runs 365 days, then the self-consumption is 0% and the self-sufficiency is 0%.
- Given 0 days, when `greedy` runs, then each total is 0, each ratio is 0%, and there are no months.

### CAP-simulation.R4 · Monthly totals

Status: built · Intents: IN-0001

The result has the totals of each calendar month in the run, in order. A year has 365
days, with no leap day (assumed). Each month also has its own two ratios.

- Given 365 days, when `greedy` runs, then the result has 12 months. Their days are 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31.
- Given 365 days, when `greedy` runs, then the solar totals of the 12 months add up to the solar total of the run. The tolerance is 0.01 kWh.
- Given 400 days, when `greedy` runs, then the result has 14 months. The last month is February with 4 days.
- Given 10 days, when `greedy` runs, then the result has one month, January with 10 days.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then July has more than twice the solar energy of December.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then the July self-sufficiency is more than the January self-sufficiency.

### CAP-simulation.R5 · Strategy order

Status: built · Intents: IN-0001

On the same weather, a battery must raise the self-consumption, and a later discharge must
not raise it. In these lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of
daily load, 3 kWh of it flexible. The seed is 7, and each run is 365 days.

- Given a battery of 10 kWh with 5 kW of power, when `none` and `greedy` run, then `greedy` has the higher self-consumption.
- Given a battery of 10 kWh with 5 kW of power, when `evening` and `greedy` run, then `evening` has a self-consumption no higher than `greedy`.
- Given a battery of 0 kWh, when `none` and `shift` run, then `shift` has the higher self-consumption.

## Specs it relies on

### CAP-scenario

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

### CAP-strategies

````
# CAP-strategies · Battery and load strategies to compare

Status: active

## What it is for

CAP-strategies (battery and load strategies) holds the rules that the simulation compares.
Each strategy has a name. For each hour, a strategy asks the battery to charge or to
discharge. For each day, a strategy also places the flexible load.

The four strategies are these:

- `none`: no battery use.
- `greedy`: battery use at any hour.
- `evening`: discharge only in the evening.
- `shift`: greedy battery use, and the flexible load in the sunniest hours.

## Code map

- `StoragePolicySim/Strategy.lean`

## Requirements

### CAP-strategies.R1 · Strategy names

Status: verified · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: verified · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: verified · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: verified · Intents: IN-0001

The `evening` strategy charges as `greedy` does. It discharges only from 17:00 to 23:59
(assumed), to keep the stored energy for the evening peak. It keeps the flexible load at its
default hours.

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

Status: verified · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.
````

### DES-errors

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

### DES-pdlc-check-tagging

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

### DES-lean-checks

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

## The code

### Diff against pdlc/CH-0002-strategies

````
diff --git a/StoragePolicySim/Simulation.lean b/StoragePolicySim/Simulation.lean
new file mode 100644
index 0000000..e6544c2
--- /dev/null
+++ b/StoragePolicySim/Simulation.lean
@@ -0,0 +1,194 @@
+/-
+The simulation: one strategy with a battery over a scenario, hour by hour. It gives the
+energy flows of each hour, the totals of the run, and the totals of each month.
+CAP-simulation (hourly energy flows) gives the rules.
+-/
+import StoragePolicySim.Scenario
+import StoragePolicySim.Strategy
+
+namespace StoragePolicySim
+
+/-- A home battery. -/
+structure Battery where
+  /-- The most energy that the battery can hold. -/
+  capacityKwh : Float
+  /-- The most energy that can go in, or come out, in one hour. -/
+  powerKw : Float
+  deriving Repr, Inhabited
+
+/-- The share that the battery keeps of the energy in, and gives of the energy out. -/
+def efficiency : Float := 0.95
+
+/-- The energy flows of one hour, each in kWh. -/
+structure Flow where
+  /-- The solar energy that the house uses directly. -/
+  directKwh : Float
+  /-- The solar energy that goes into the battery, before the loss. -/
+  chargeKwh : Float
+  /-- The energy that the battery gives to the house, after the loss. -/
+  dischargeKwh : Float
+  /-- The energy to the grid. -/
+  exportKwh : Float
+  /-- The energy from the grid. -/
+  importKwh : Float
+  /-- The battery loss of the hour. -/
+  lossKwh : Float
+  /-- The energy in the battery after the hour. -/
+  socKwh : Float
+  deriving Repr, Inhabited
+
+/-- The smallest of three values, and 0 if that value is less than 0. -/
+private def limitTo (a b c : Float) : Float :=
+  max 0 (min a (min b c))
+
+/-- The flows of one hour. `socKwh` is the energy in the battery before the hour. The
+battery takes what the strategy asks, up to the surplus, the power and the free room. The
+battery gives what the strategy asks, up to the shortfall, the power and the stored energy.
+The power limit applies to the energy in, and to the energy out after the loss. The
+stored energy after the hour stays from 0 to the capacity, so that a rounding error of the
+floats cannot move it out of this range. -/
+def stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat)
+    (pvKwh loadKwh : Float) : Flow :=
+  let directKwh := min pvKwh loadKwh
+  let surplusKwh := pvKwh - directKwh
+  let shortfallKwh := loadKwh - directKwh
+  let request := strategy.decide hour surplusKwh shortfallKwh
+  let chargeToFillKwh := (battery.capacityKwh - socKwh) / efficiency
+  let chargeKwh := limitTo request.chargeKwh surplusKwh (min battery.powerKw chargeToFillKwh)
+  let storedAfterChargeKwh := socKwh + chargeKwh * efficiency
+  let dischargeKwh := limitTo request.dischargeKwh shortfallKwh
+    (min battery.powerKw (storedAfterChargeKwh * efficiency))
+  let takenOutKwh := dischargeKwh / efficiency
+  { directKwh, chargeKwh, dischargeKwh,
+    exportKwh := surplusKwh - chargeKwh,
+    importKwh := shortfallKwh - dischargeKwh,
+    lossKwh := chargeKwh - chargeKwh * efficiency + takenOutKwh - dischargeKwh,
+    socKwh := max 0 (min battery.capacityKwh (storedAfterChargeKwh - takenOutKwh)) }
+
+/-- One hour of a run. -/
+structure HourResult where
+  /-- The hour of the scenario. -/
+  hour : Hour
+  /-- The base load and the flexible load that the strategy placed. -/
+  loadKwh : Float
+  /-- The energy flows of the hour. -/
+  flow : Flow
+  deriving Repr, Inhabited
+
+/-- The totals of a run, or of a month of a run. -/
+structure Totals where
+  pvKwh : Float
+  loadKwh : Float
+  importKwh : Float
+  exportKwh : Float
+  lossKwh : Float
+  /-- The solar energy less the export. -/
+  selfUsedKwh : Float
+  /-- The energy in the battery at the end. -/
+  finalSocKwh : Float
+  /-- The self-used solar energy as a percentage of the solar energy. -/
+  selfConsumption : Float
+  /-- The load less the import, as a percentage of the load. -/
+  selfSufficiency : Float
+  deriving Repr, Inhabited
+
+/-- The totals of one calendar month of a run. -/
+structure Month where
+  /-- `"Jan"` to `"Dec"`. -/
+  name : String
+  /-- The days of the run in this month. -/
+  days : Nat
+  totals : Totals
+  deriving Repr, Inhabited
+
+/-- The result of a run. -/
+structure Result where
+  hours : Array HourResult
+  totals : Totals
+  months : Array Month
+  deriving Repr, Inhabited
+
+/-- The sums of the hours that the totals need. -/
+private structure HourSums where
+  pvKwh : Float := 0
+  loadKwh : Float := 0
+  importKwh : Float := 0
+  exportKwh : Float := 0
+  lossKwh : Float := 0
+
+/-- The sums with one more hour added. -/
+private def HourSums.add (sums : HourSums) (hourResult : HourResult) : HourSums :=
+  { pvKwh := sums.pvKwh + hourResult.hour.pvKwh,
+    loadKwh := sums.loadKwh + hourResult.loadKwh,
+    importKwh := sums.importKwh + hourResult.flow.importKwh,
+    exportKwh := sums.exportKwh + hourResult.flow.exportKwh,
+    lossKwh := sums.lossKwh + hourResult.flow.lossKwh }
+
+/-- `part` as a percentage of `whole`. A ratio with nothing to divide by is 0%. -/
+private def percent (part whole : Float) : Float :=
+  if whole == 0 then 0 else 100 * part / whole
+
+/-- The totals of the sums, with the energy in the battery at the end. -/
+private def HourSums.toTotals (sums : HourSums) (finalSocKwh : Float) : Totals :=
+  let selfUsedKwh := sums.pvKwh - sums.exportKwh
+  { pvKwh := sums.pvKwh, loadKwh := sums.loadKwh, importKwh := sums.importKwh,
+    exportKwh := sums.exportKwh, lossKwh := sums.lossKwh, selfUsedKwh, finalSocKwh,
+    selfConsumption := percent selfUsedKwh sums.pvKwh,
+    selfSufficiency := percent (sums.loadKwh - sums.importKwh) sums.loadKwh }
+
+/-- The name and the length of each month of a year with no leap day. -/
+private def calendar : Array (String × Nat) :=
+  #[("Jan", 31), ("Feb", 28), ("Mar", 31), ("Apr", 30), ("May", 31), ("Jun", 30),
+    ("Jul", 31), ("Aug", 31), ("Sep", 30), ("Oct", 31), ("Nov", 30), ("Dec", 31)]
+
+/-- The month of a day of the year, from 0 (January) to 11 (December). -/
+private def monthOfDay (dayOfYear : Nat) : Nat := Id.run do
+  let mut nextFirstDay := 0
+  for month in [0:calendar.size] do
+    nextFirstDay := nextFirstDay + calendar[month]!.2
+    if dayOfYear < nextFirstDay then return month
+  return calendar.size - 1
+
+/-- The month of the run that is in progress. -/
+private structure OpenMonth where
+  month : Nat
+  days : Nat := 0
+  sums : HourSums := {}
+
+/-- The month with its name, its days and its totals. -/
+private def OpenMonth.close (openMonth : OpenMonth) (socKwh : Float) : Month :=
+  { name := calendar[openMonth.month]!.1, days := openMonth.days,
+    totals := openMonth.sums.toTotals socKwh }
+
+/-- The run of one strategy with a battery over the scenario of the site. The battery is
+empty at the start. For each day, the strategy places the flexible load. -/
+def simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days : Nat) :
+    Result := Id.run do
+  let scenarioHours := scenario site seed days
+  let mut hours : Array HourResult := Array.mkEmpty scenarioHours.size
+  let mut socKwh : Float := 0
+  let mut runSums : HourSums := {}
+  let mut months : Array Month := #[]
+  let mut openMonth : OpenMonth := { month := 0 }
+  for day in [0:days] do
+    let dayHours := scenarioHours.extract (24 * day) (24 * day + 24)
+    let flexKwh := strategy.placeFlex (dayHours.map (·.pvKwh)) (dayHours.map (·.flexKwh))
+    let month := monthOfDay (day % daysInYear)
+    if month != openMonth.month then
+      months := months.push (openMonth.close socKwh)
+      openMonth := { month }
+    openMonth := { openMonth with days := openMonth.days + 1 }
+    for k in [0:dayHours.size] do
+      let hour := dayHours[k]!
+      let loadKwh := hour.baseLoadKwh + flexKwh[k]!
+      let flow := stepHour battery socKwh strategy hour.hour hour.pvKwh loadKwh
+      let hourResult : HourResult := { hour, loadKwh, flow }
+      socKwh := flow.socKwh
+      hours := hours.push hourResult
+      runSums := runSums.add hourResult
+      openMonth := { openMonth with sums := openMonth.sums.add hourResult }
+  if openMonth.days > 0 then
+    months := months.push (openMonth.close socKwh)
+  return { hours, totals := runSums.toTotals socKwh, months }
+
+end StoragePolicySim
````

### StoragePolicySim/Simulation.lean

````
/-
The simulation: one strategy with a battery over a scenario, hour by hour. It gives the
energy flows of each hour, the totals of the run, and the totals of each month.
CAP-simulation (hourly energy flows) gives the rules.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy

namespace StoragePolicySim

/-- A home battery. -/
structure Battery where
  /-- The most energy that the battery can hold. -/
  capacityKwh : Float
  /-- The most energy that can go in, or come out, in one hour. -/
  powerKw : Float
  deriving Repr, Inhabited

/-- The share that the battery keeps of the energy in, and gives of the energy out. -/
def efficiency : Float := 0.95

/-- The energy flows of one hour, each in kWh. -/
structure Flow where
  /-- The solar energy that the house uses directly. -/
  directKwh : Float
  /-- The solar energy that goes into the battery, before the loss. -/
  chargeKwh : Float
  /-- The energy that the battery gives to the house, after the loss. -/
  dischargeKwh : Float
  /-- The energy to the grid. -/
  exportKwh : Float
  /-- The energy from the grid. -/
  importKwh : Float
  /-- The battery loss of the hour. -/
  lossKwh : Float
  /-- The energy in the battery after the hour. -/
  socKwh : Float
  deriving Repr, Inhabited

/-- The smallest of three values, and 0 if that value is less than 0. -/
private def limitTo (a b c : Float) : Float :=
  max 0 (min a (min b c))

/-- The flows of one hour. `socKwh` is the energy in the battery before the hour. The
battery takes what the strategy asks, up to the surplus, the power and the free room. The
battery gives what the strategy asks, up to the shortfall, the power and the stored energy.
The power limit applies to the energy in, and to the energy out after the loss. The
stored energy after the hour stays from 0 to the capacity, so that a rounding error of the
floats cannot move it out of this range. -/
def stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat)
    (pvKwh loadKwh : Float) : Flow :=
  let directKwh := min pvKwh loadKwh
  let surplusKwh := pvKwh - directKwh
  let shortfallKwh := loadKwh - directKwh
  let request := strategy.decide hour surplusKwh shortfallKwh
  let chargeToFillKwh := (battery.capacityKwh - socKwh) / efficiency
  let chargeKwh := limitTo request.chargeKwh surplusKwh (min battery.powerKw chargeToFillKwh)
  let storedAfterChargeKwh := socKwh + chargeKwh * efficiency
  let dischargeKwh := limitTo request.dischargeKwh shortfallKwh
    (min battery.powerKw (storedAfterChargeKwh * efficiency))
  let takenOutKwh := dischargeKwh / efficiency
  { directKwh, chargeKwh, dischargeKwh,
    exportKwh := surplusKwh - chargeKwh,
    importKwh := shortfallKwh - dischargeKwh,
    lossKwh := chargeKwh - chargeKwh * efficiency + takenOutKwh - dischargeKwh,
    socKwh := max 0 (min battery.capacityKwh (storedAfterChargeKwh - takenOutKwh)) }

/-- One hour of a run. -/
structure HourResult where
  /-- The hour of the scenario. -/
  hour : Hour
  /-- The base load and the flexible load that the strategy placed. -/
  loadKwh : Float
  /-- The energy flows of the hour. -/
  flow : Flow
  deriving Repr, Inhabited

/-- The totals of a run, or of a month of a run. -/
structure Totals where
  pvKwh : Float
  loadKwh : Float
  importKwh : Float
  exportKwh : Float
  lossKwh : Float
  /-- The solar energy less the export. -/
  selfUsedKwh : Float
  /-- The energy in the battery at the end. -/
  finalSocKwh : Float
  /-- The self-used solar energy as a percentage of the solar energy. -/
  selfConsumption : Float
  /-- The load less the import, as a percentage of the load. -/
  selfSufficiency : Float
  deriving Repr, Inhabited

/-- The totals of one calendar month of a run. -/
structure Month where
  /-- `"Jan"` to `"Dec"`. -/
  name : String
  /-- The days of the run in this month. -/
  days : Nat
  totals : Totals
  deriving Repr, Inhabited

/-- The result of a run. -/
structure Result where
  hours : Array HourResult
  totals : Totals
  months : Array Month
  deriving Repr, Inhabited

/-- The sums of the hours that the totals need. -/
private structure HourSums where
  pvKwh : Float := 0
  loadKwh : Float := 0
  importKwh : Float := 0
  exportKwh : Float := 0
  lossKwh : Float := 0

/-- The sums with one more hour added. -/
private def HourSums.add (sums : HourSums) (hourResult : HourResult) : HourSums :=
  { pvKwh := sums.pvKwh + hourResult.hour.pvKwh,
    loadKwh := sums.loadKwh + hourResult.loadKwh,
    importKwh := sums.importKwh + hourResult.flow.importKwh,
    exportKwh := sums.exportKwh + hourResult.flow.exportKwh,
    lossKwh := sums.lossKwh + hourResult.flow.lossKwh }

/-- `part` as a percentage of `whole`. A ratio with nothing to divide by is 0%. -/
private def percent (part whole : Float) : Float :=
  if whole == 0 then 0 else 100 * part / whole

/-- The totals of the sums, with the energy in the battery at the end. -/
private def HourSums.toTotals (sums : HourSums) (finalSocKwh : Float) : Totals :=
  let selfUsedKwh := sums.pvKwh - sums.exportKwh
  { pvKwh := sums.pvKwh, loadKwh := sums.loadKwh, importKwh := sums.importKwh,
    exportKwh := sums.exportKwh, lossKwh := sums.lossKwh, selfUsedKwh, finalSocKwh,
    selfConsumption := percent selfUsedKwh sums.pvKwh,
    selfSufficiency := percent (sums.loadKwh - sums.importKwh) sums.loadKwh }

/-- The name and the length of each month of a year with no leap day. -/
private def calendar : Array (String × Nat) :=
  #[("Jan", 31), ("Feb", 28), ("Mar", 31), ("Apr", 30), ("May", 31), ("Jun", 30),
    ("Jul", 31), ("Aug", 31), ("Sep", 30), ("Oct", 31), ("Nov", 30), ("Dec", 31)]

/-- The month of a day of the year, from 0 (January) to 11 (December). -/
private def monthOfDay (dayOfYear : Nat) : Nat := Id.run do
  let mut nextFirstDay := 0
  for month in [0:calendar.size] do
    nextFirstDay := nextFirstDay + calendar[month]!.2
    if dayOfYear < nextFirstDay then return month
  return calendar.size - 1

/-- The month of the run that is in progress. -/
private structure OpenMonth where
  month : Nat
  days : Nat := 0
  sums : HourSums := {}

/-- The month with its name, its days and its totals. -/
private def OpenMonth.close (openMonth : OpenMonth) (socKwh : Float) : Month :=
  { name := calendar[openMonth.month]!.1, days := openMonth.days,
    totals := openMonth.sums.toTotals socKwh }

/-- The run of one strategy with a battery over the scenario of the site. The battery is
empty at the start. For each day, the strategy places the flexible load. -/
def simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days : Nat) :
    Result := Id.run do
  let scenarioHours := scenario site seed days
  let mut hours : Array HourResult := Array.mkEmpty scenarioHours.size
  let mut socKwh : Float := 0
  let mut runSums : HourSums := {}
  let mut months : Array Month := #[]
  let mut openMonth : OpenMonth := { month := 0 }
  for day in [0:days] do
    let dayHours := scenarioHours.extract (24 * day) (24 * day + 24)
    let flexKwh := strategy.placeFlex (dayHours.map (·.pvKwh)) (dayHours.map (·.flexKwh))
    let month := monthOfDay (day % daysInYear)
    if month != openMonth.month then
      months := months.push (openMonth.close socKwh)
      openMonth := { month }
    openMonth := { openMonth with days := openMonth.days + 1 }
    for k in [0:dayHours.size] do
      let hour := dayHours[k]!
      let loadKwh := hour.baseLoadKwh + flexKwh[k]!
      let flow := stepHour battery socKwh strategy hour.hour hour.pvKwh loadKwh
      let hourResult : HourResult := { hour, loadKwh, flow }
      socKwh := flow.socKwh
      hours := hours.push hourResult
      runSums := runSums.add hourResult
      openMonth := { openMonth with sums := openMonth.sums.add hourResult }
  if openMonth.days > 0 then
    months := months.push (openMonth.close socKwh)
  return { hours, totals := runSums.toTotals socKwh, months }

end StoragePolicySim
````

