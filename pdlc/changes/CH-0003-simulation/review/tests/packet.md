# Review packet · CH-0003-simulation · tests

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: b0f275366f30ccc386a4c97ab36d9baa8d9b180b

## Re-review

Earlier review: ba51e5b

An earlier review of this remit judged the checks locked at ba51e5b. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.
Write a "Wrong versions" line only for each check that changed. If no check
changed, write "none" under "Wrong versions".

### Earlier problems

- tests/CAP-simulation.lean:36 · The packet does not hold the Interface of CH-0001 (scenario) or CH-0002 (strategies). Thus, I cannot confirm that a correct app passes the checks. The checks use these names that the packet does not define: `Site` with `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh` (line 36). `Hour` with `day`, `dayOfYear`, `hour`, `sky`, `pvKwh`, `baseLoadKwh` and `flexKwh`, and a `BEq` on the sky (line 89). `scenario site seed days` that gives an `Array Hour` (line 244). `Strategy.placeFlex s pv fl` on two `Array Float` that gives an `Array Float` (line 83). `Strategy.greedy`, `Strategy.none`, `Strategy.evening` and `Strategy.shift` (line 183 and later). A wrong name or type fails each check, also on a correct app. Add the two Interfaces to the packet, and review these names again. · Remit rule "A correct app passes each check", and the reviewer rule "If something that you need is missing, report the missing item as a problem"

### Changes since the earlier review

Nothing changed.

# Remit: tests

Default: yes

You judge the checks, not the code. You do not see the code. The list below is for the
component checks of a change. For the acceptance checks of an intent, the section
"Acceptance checks of an intent" gives the differences.

- Each acceptance line in the change spec has at least one check. The exception is a
  requirement marked `(retire)`: its acceptance lines get no check, and each check that
  only proved them is gone.
- The name of each check contains its requirement ID.
- Each check tests what the acceptance line says, through the "Interface" in the change
  spec. The check does not depend on the internal structure of the code.
- A component check is permitted to prepare state directly, for example with a fixture
  file. But the check reads each result through the interface, unless the requirement is
  about the stored form.
- A check proves each line at the surface that the line names. A line where the person
  clicks needs a check that clicks and reads what shows. A check of a helper below that
  surface is not sufficient alone.
- If a line depends on the current date or time, its check sets the clock through a seam
  at that same surface. A check that runs a command sets the clock with the environment
  variable or flag of the command. Each of these is a problem:
  - Using the real clock, or setting the time only on a helper below the surface.
  - Leaving a line to manual checks when a stand-in seam could reach the surface.
- Each check can fail. It fails on a plausible wrong version of the code (see "Wrong
  versions"). A check that passes, whatever the code does, does not count.
- A correct app passes each check. A fake that stands in for something real must use the
  names and the behaviour of the real thing. Then the check does not prove only the fake.
- No check can hang. Anything that waits for the app has a time limit.
- Each error code that the Interface lists has a check that expects that exact code.
- The checks control time, randomness, and vendors only through the "Test seams" of the
  Interface.
- The checks are sufficiently clear that a failure tells you what broke.

## Wrong versions

For each check, name one plausible wrong version of the code. Decide whether the check
fails on that version. Write one line for each check under "Wrong versions" in your
result: the check, the wrong version, and `fails` or `passes`. A check that passes a
plausible wrong version is a problem. Name the value or line that catches the wrong
version. On a re-review, write a line only for each check that changed since the earlier
review.

Look for these traps:

- Examples that also fit a wrong rule. These are common cases:
  - A rule about order, tested with items that are already in that order or in
    alphabetical order.
  - Values that come out the same if the code rounds up, rounds down, or rounds to the
    nearest value.
  - Text that is already in the case that the rule asks for.
- A limit that the check does not test exactly at the edge and one past the edge. For "at
  most 20", the value 20 passes and the value 21 fails. Values near the edge prove nothing
  about the edge.
- A rule about every member of a class that the check tests without a non-member.
  "Any other value is an error" needs a value close to an allowed value, not only a few
  far-off values. A close value differs by its case, a space, or a prefix. "Only the
  owner may" needs a person who is not the owner.

## Acceptance checks of an intent

The packet holds the intent, the full text of its requirements, and the "Interface" of
each of its changes. Judge the acceptance checks by the list at the top, with these
differences:

- Each acceptance line of each requirement that the intent lists has at least one check. A
  `retiring` requirement has no check. A stored-data line also has no check here.
- Each check uses only what a user uses: commands, HTTP requests, pages, or the public
  functions of a library. A check can use each feature of the intent, and each feature
  that exists already.
- No check reads or writes stored data directly. A check that opens a saved file or
  queries a store is a problem.
- A stored-data line needs direct access to the stored data. The line is about the stored
  form, or it needs a state that the interface cannot make. An example of such a state is
  an old or a broken data file. The comment at the top of the file lists each such line, with a change of the
  intent that lists its requirement. Such a line with no check is not a problem.
- A line in that list that the interface can prove is a problem. So is a listed line whose
  change does not list its requirement. The packet gives the requirements of each change.
- A check can leave the acceptance file of an earlier intent only when the check proved a
  requirement that this intent changes or retires. Then a check in this file proves the
  new line. Any other removal is a problem.
- Each check fails until the last change of the intent is built. That is not a problem.
- When the intent lists one change, these checks are also the checks of that change. Then
  each error code and each test seam in its "Interface" has a check.

Write "Wrong versions" for the acceptance checks in the same way as for other checks.

## The change spec

````
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

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

Over a run, the battery never goes past its power or its capacity. The energy of each run
balances, with the battery losses included. In these lines, the site is at latitude 45
with 5 kW of panels and 20 kWh of daily load, 3 kWh of it flexible. The seed is 7, unless
the line says otherwise.

- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then no hour charges or discharges over 2 kWh.
- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then the battery holds 0 to 5 kWh each hour.
- Given a 10 kWh battery, when `greedy` runs 365 days, then solar plus import equals load, export, losses and the stored energy. The tolerance is 0.01 kWh.
- Given a battery of 0 kWh, when `greedy` and `none` each run 365 days, then the two runs have the same totals.

### CAP-simulation.R3 · Totals and ratios

Status: ready · Intents: IN-0001

The totals add up the hours of the run. The self-consumption is the solar energy less the
export, as a percentage of the solar energy. The self-sufficiency is the load less the
import, as a percentage of the load. A ratio with nothing to divide by is 0% (assumed).

- Given latitude 45 and `none`, when the simulation runs 365 days, then each total equals the sum of its hours. The tolerance is 0.01 kWh.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-consumption is 100 × (solar - export) / solar.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-sufficiency is 100 × (load - import) / load.
- Given 0 kW of panels, when `greedy` runs 365 days, then the self-consumption is 0% and the self-sufficiency is 0%.
- Given 0 days, when `greedy` runs, then each total is 0, each ratio is 0%, and there are no months.

### CAP-simulation.R4 · Monthly totals

Status: ready · Intents: IN-0001

The result has the totals of each calendar month in the run, in order. A year has 365
days, with no leap day (assumed). Each month also has its own two ratios.

- Given 365 days, when `greedy` runs, then the result has 12 months. Their days are 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31.
- Given 365 days, when `greedy` runs, then the solar totals of the 12 months add up to the solar total of the run. The tolerance is 0.01 kWh.
- Given 400 days, when `greedy` runs, then the result has 14 months. The last month is February with 4 days.
- Given 10 days, when `greedy` runs, then the result has one month, January with 10 days.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then July has more than twice the solar energy of December.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then the July self-sufficiency is more than the January self-sufficiency.

### CAP-simulation.R5 · Strategy order

Status: ready · Intents: IN-0001

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

## The checks

### Diff against pdlc/CH-0002-strategies

````
diff --git a/tests/CAP-simulation.lean b/tests/CAP-simulation.lean
new file mode 100644
index 0000000..499f707
--- /dev/null
+++ b/tests/CAP-simulation.lean
@@ -0,0 +1,534 @@
+/-
+Component checks of CAP-simulation (hourly energy flows), for CH-0003 (hourly energy flows
+and results).
+
+The checks call only `Battery`, `efficiency`, `Flow`, `stepHour`, `HourResult`, `Totals`,
+`Month`, `Result` and `simulate`. They also call `Site`, `Hour` and `scenario` of CH-0001
+(scenario), and `Strategy`, `Strategy.decide` and `Strategy.placeFlex` of CH-0002
+(strategies). No entry of the Interface can fail, so no check expects an error code. The
+`seed` argument of `simulate` is the only seam. No check uses the clock.
+
+In the lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of daily load,
+3 kWh of it flexible. The battery holds 10 kWh with 5 kW of power, and the seed is 7, unless
+the check says otherwise.
+-/
+import StoragePolicySim.Simulation
+open StoragePolicySim
+
+structure Check where
+  name : String
+  run : IO (Option String)   -- none: pass, some msg: fail
+
+-- Helpers for numbers
+
+def near (a b tol : Float) : Bool := (a - b).abs ≤ tol
+
+def firstFail : List (Bool × String) → Option String
+  | [] => none
+  | (true, _) :: rest => firstFail rest
+  | (false, m) :: _ => some m
+
+/-- A percentage. A ratio with nothing to divide by is 0%. -/
+def pct (part whole : Float) : Float := if whole == 0 then 0 else 100 * part / whole
+
+-- Helpers for the library
+
+def site (lat : Float) (pv : Float := 5) (flex : Float := 3) : Site :=
+  { latitude := lat, pvKw := pv, dailyLoadKwh := 20, flexKwh := flex }
+
+def bat (cap power : Float) : Battery := { capacityKwh := cap, powerKw := power }
+
+/-- A run at latitude 45 with seed 7. -/
+def run7 (s : Strategy) (b : Battery := bat 10 5) (days : Nat := 365) (pv : Float := 5) :
+    Result :=
+  simulate (site 45 pv) b s 7 days
+
+def flowFields (f : Flow) : List (String × Float) :=
+  [("direct", f.directKwh), ("charge", f.chargeKwh), ("discharge", f.dischargeKwh),
+   ("export", f.exportKwh), ("import", f.importKwh), ("loss", f.lossKwh), ("soc", f.socKwh)]
+
+/-- Compares a flow with the expected direct, charge, discharge, export, import, loss and
+soc, in this order. -/
+def badFlow (f : Flow) (want : List Float) : Option String :=
+  if want.length != 7 then some "the check gives the wrong number of values"
+  else match ((flowFields f).zip want).find? (fun p => !near p.1.2 p.2 1e-6) with
+    | some p => some s!"{p.1.1} is {p.1.2}, want {p.2}, flow {repr f}"
+    | none => none
+
+def sameFlow (a b : Flow) : Bool :=
+  ((flowFields a).zip (flowFields b)).all (fun p => near p.1.2 p.2.2 1e-9)
+
+/-- The energy of one hour balances, with the stored energy before and after the hour. -/
+def balanced (soc0 pv load : Float) (f : Flow) : Bool :=
+  near (f.directKwh + f.chargeKwh + f.exportKwh) pv 1e-6 &&
+  near (f.directKwh + f.dischargeKwh + f.importKwh) load 1e-6 &&
+  near (soc0 + pv + f.importKwh) (load + f.exportKwh + f.lossKwh + f.socKwh) 1e-6
+
+def socBefore (hs : Array HourResult) (i : Nat) : Float :=
+  if i == 0 then 0 else hs[i - 1]!.flow.socKwh
+
+/-- Finds the first hour whose flow is not `stepHour` with the energy of the hour before. -/
+def badChain (b : Battery) (s : Strategy) (hs : Array HourResult) : Option Nat :=
+  (List.range hs.size).find? (fun i =>
+    let h := hs[i]!
+    !sameFlow (stepHour b (socBefore hs i) s h.hour.hour h.hour.pvKwh h.loadKwh) h.flow)
+
+/-- Finds the first hour whose load is not the base load and the flexible load that
+`Strategy.placeFlex` places for its day. -/
+def badLoad (s : Strategy) (hs : Array HourResult) : Option Nat :=
+  let days := hs.size / 24
+  let badDay := (List.range days).find? (fun d =>
+    let pv := ((List.range 24).map (fun k => hs[d * 24 + k]!.hour.pvKwh)).toArray
+    let fl := ((List.range 24).map (fun k => hs[d * 24 + k]!.hour.flexKwh)).toArray
+    let placed := Strategy.placeFlex s pv fl
+    (List.range 24).any (fun k =>
+      let h := hs[d * 24 + k]!
+      !near h.loadKwh (h.hour.baseLoadKwh + placed[k]!) 1e-9))
+  badDay.map (fun d => d * 24)
+
+def sameHour (a b : Hour) : Bool :=
+  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
+  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh
+
+def sumOf (hs : Array HourResult) (f : HourResult → Float) : Float :=
+  hs.foldl (fun acc h => acc + f h) 0
+
+def totalsFields (t : Totals) : List (String × Float) :=
+  [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh),
+   ("export", t.exportKwh), ("losses", t.lossKwh), ("self-used", t.selfUsedKwh),
+   ("final soc", t.finalSocKwh), ("self-consumption", t.selfConsumption),
+   ("self-sufficiency", t.selfSufficiency)]
+
+def badTotals (a b : Totals) : Option String :=
+  match ((totalsFields a).zip (totalsFields b)).find? (fun p => !near p.1.2 p.2.2 1e-6) with
+  | some p => some s!"{p.1.1} is {p.1.2} and {p.2.2}"
+  | none => none
+
+/-- Compares each total with the sum of the hours of the run. -/
+def badSums (res : Result) : Option String :=
+  let hs := res.hours
+  let t := res.totals
+  firstFail [
+    (hs.size == 8760, s!"{hs.size} hours"),
+    (near t.pvKwh (sumOf hs (·.hour.pvKwh)) 0.01, s!"solar {t.pvKwh}, hours {sumOf hs (·.hour.pvKwh)}"),
+    (near t.loadKwh (sumOf hs (·.loadKwh)) 0.01, s!"load {t.loadKwh}, hours {sumOf hs (·.loadKwh)}"),
+    (near t.importKwh (sumOf hs (·.flow.importKwh)) 0.01,
+      s!"import {t.importKwh}, hours {sumOf hs (·.flow.importKwh)}"),
+    (near t.exportKwh (sumOf hs (·.flow.exportKwh)) 0.01,
+      s!"export {t.exportKwh}, hours {sumOf hs (·.flow.exportKwh)}"),
+    (near t.lossKwh (sumOf hs (·.flow.lossKwh)) 0.01,
+      s!"losses {t.lossKwh}, hours {sumOf hs (·.flow.lossKwh)}"),
+    (near t.selfUsedKwh (t.pvKwh - t.exportKwh) 0.01, s!"self-used {t.selfUsedKwh}"),
+    (near t.finalSocKwh (socBefore hs hs.size) 1e-9, s!"final soc {t.finalSocKwh}")]
+
+def monthNames : List String :=
+  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
+
+def monthDays : List Nat := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
+
+/-- The months of a run of `days` days from 1 January, with the days of the run in each. -/
+def wantMonths (days : Nat) : List (String × Nat) := Id.run do
+  let mut out : List (String × Nat) := []
+  let mut left := days
+  for i in List.range (days / 28 + 2) do
+    if left > 0 then
+      let len := monthDays.getD (i % 12) 0
+      let n := if left < len then left else len
+      out := out ++ [(monthNames.getD (i % 12) "", n)]
+      left := left - n
+  return out
+
+def gotMonths (res : Result) : List (String × Nat) :=
+  res.months.toList.map (fun m => (m.name, m.days))
+
+def sumDays (hs : Array HourResult) (startDay n : Nat) (f : HourResult → Float) : Float :=
+  (List.range (n * 24)).foldl (fun acc k => acc + f hs[startDay * 24 + k]!) 0
+
+/-- Compares the totals and the two ratios of each month with the hours of that month. -/
+def badMonths (res : Result) : Option String := Id.run do
+  let mut start := 0
+  for i in List.range res.months.size do
+    let m := res.months[i]!
+    let t := m.totals
+    let add := sumDays res.hours start m.days
+    let pv := add (·.hour.pvKwh)
+    let load := add (·.loadKwh)
+    let imp := add (·.flow.importKwh)
+    let exp := add (·.flow.exportKwh)
+    let loss := add (·.flow.lossKwh)
+    let r := firstFail [
+      (near t.pvKwh pv 0.01, s!"solar {t.pvKwh}, hours {pv}"),
+      (near t.loadKwh load 0.01, s!"load {t.loadKwh}, hours {load}"),
+      (near t.importKwh imp 0.01, s!"import {t.importKwh}, hours {imp}"),
+      (near t.exportKwh exp 0.01, s!"export {t.exportKwh}, hours {exp}"),
+      (near t.lossKwh loss 0.01, s!"losses {t.lossKwh}, hours {loss}"),
+      (near t.selfConsumption (pct (t.pvKwh - t.exportKwh) t.pvKwh) 1e-6,
+        s!"self-consumption {t.selfConsumption}"),
+      (near t.selfSufficiency (pct (t.loadKwh - t.importKwh) t.loadKwh) 1e-6,
+        s!"self-sufficiency {t.selfSufficiency}")]
+    match r with
+    | some msg => return some s!"{m.name} (month {i + 1}): {msg}"
+    | none => pure ()
+    start := start + m.days
+  return none
+
+def checks : List Check := [
+  -- CAP-simulation.R1
+  { name := "CAP-simulation.R1 the efficiency is 0.95",
+    run := do
+      return if near efficiency 0.95 1e-9 then none else some s!"got {efficiency}" },
+  -- A version with no loss gives 2 kWh stored.
+  { name := "CAP-simulation.R1 an empty battery with 3 kWh of solar and 1 kWh of load takes 2 kWh and holds 1.9 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 0 Strategy.greedy 12 3 1) [1, 2, 0, 0, 0, 0.1, 1.9] },
+  { name := "CAP-simulation.R1 a full battery takes 0 kWh and 2 kWh is export",
+    run := do
+      return badFlow (stepHour (bat 10 5) 10 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 10] },
+  -- A version that limits the charge to the free room with no loss takes 0.95 kWh.
+  { name := "CAP-simulation.R1 9.05 kWh stored takes 1 kWh of a 2 kWh surplus and then holds 10 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 9.05 Strategy.greedy 12 3 1) [1, 1, 0, 1, 0, 0.05, 10] },
+  -- A version that ignores the loss in the free room takes 1 kWh and holds 9.95 kWh.
+  { name := "CAP-simulation.R1 9 kWh stored takes 1/0.95 kWh of a 2 kWh surplus and then holds 10 kWh",
+    run := do
+      let c := 1 / 0.95
+      return badFlow (stepHour (bat 10 5) 9 Strategy.greedy 12 3 1)
+        [1, c, 0, 2 - c, 0, 0.05 * c, 10] },
+  -- A version that limits the energy stored, not the energy in, takes 2/0.95 kWh.
+  { name := "CAP-simulation.R1 a battery with 2 kW of power takes 2 kWh of a 3 kWh surplus and 1 kWh is export",
+    run := do
+      return badFlow (stepHour (bat 10 2) 0 Strategy.greedy 12 4 1) [1, 2, 0, 1, 0, 0.1, 1.9] },
+  -- A version with no loss on the way out gives 1.9 kWh.
+  { name := "CAP-simulation.R1 1.9 kWh stored gives 1.805 kWh for a shortfall of 2 kWh and 0.195 kWh is import",
+    run := do
+      return badFlow (stepHour (bat 10 5) 1.9 Strategy.greedy 20 0 2)
+        [0, 0, 1.805, 0, 0.195, 0.095, 0] },
+  -- A version that takes the shortfall as the full load asks for 2.5 kWh.
+  { name := "CAP-simulation.R1 0.5 kWh of solar and 2.5 kWh of load give 0.5 kWh direct and a shortfall of 2 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 1.9 Strategy.greedy 20 0.5 2.5)
+        [0.5, 0, 1.805, 0, 0.195, 0.095, 0] },
+  -- A version that takes the given energy from the store with no loss holds 3 kWh.
+  { name := "CAP-simulation.R1 5 kWh stored gives 2 kWh for a shortfall of 2 kWh and then holds 5 - 2/0.95 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 5 Strategy.greedy 20 0 2)
+        [0, 0, 2, 0, 0, 2 / 0.95 - 2, 5 - 2 / 0.95] },
+  { name := "CAP-simulation.R1 none with 1.9 kWh stored exports 2 kWh and still holds 1.9 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 1.9 Strategy.none 12 3 1) [1, 0, 0, 2, 0, 0, 1.9] },
+  { name := "CAP-simulation.R1 none with 1.9 kWh stored imports a shortfall of 2 kWh and still holds 1.9 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 1.9 Strategy.none 20 0 2) [0, 0, 0, 0, 2, 0, 1.9] },
+  -- The strategy gets the hour. A version that ignores the request of the strategy, or
+  -- gives the wrong hour to the strategy, fails one of these two checks.
+  { name := "CAP-simulation.R1 evening at 16:00 with 1.9 kWh stored gives 0 kWh and imports 2 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 1.9 Strategy.evening 16 0 2) [0, 0, 0, 0, 2, 0, 1.9] },
+  { name := "CAP-simulation.R1 evening at 17:00 with 1.9 kWh stored gives 1.805 kWh",
+    run := do
+      return badFlow (stepHour (bat 10 5) 1.9 Strategy.evening 17 0 2)
+        [0, 0, 1.805, 0, 0.195, 0.095, 0] },
+  -- A version that starts with a full or a half battery discharges in the first hour.
+  { name := "CAP-simulation.R1 the first hour of greedy with seed 7 and 365 days imports its full load",
+    run := do
+      let res := run7 Strategy.greedy
+      if res.hours.size != 8760 then return some s!"{res.hours.size} hours"
+      let h := res.hours[0]!
+      return firstFail [
+        (h.hour.day == 0 && h.hour.hour == 0, s!"the first hour is day {h.hour.day} hour {h.hour.hour}"),
+        (h.loadKwh > 0, s!"load {h.loadKwh}"),
+        (near h.flow.importKwh h.loadKwh 1e-9, s!"load {h.loadKwh}, import {h.flow.importKwh}"),
+        (near h.flow.dischargeKwh 0 1e-9, s!"discharge {h.flow.dischargeKwh}")] },
+  { name := "CAP-simulation.R1 the hours of a run are the hours of the scenario",
+    run := do
+      let res := run7 Strategy.greedy
+      let hs := scenario (site 45) 7 365
+      return if res.hours.size == 8760 && hs.size == 8760 &&
+          (List.range 8760).all (fun i => sameHour res.hours[i]!.hour hs[i]!) then none
+        else some s!"{res.hours.size} hours, the scenario has {hs.size}" },
+  -- A version that keeps the energy of the battery between hours wrongly, or that gives
+  -- the wrong hour, solar or load to the hour, fails here.
+  { name := "CAP-simulation.R1 each hour of greedy is the flow of stepHour with the energy of the hour before",
+    run := do
+      let res := run7 Strategy.greedy
+      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
+        else match badChain (bat 10 5) Strategy.greedy res.hours with
+          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr res.hours[i]!.flow}"
+          | none => none },
+  { name := "CAP-simulation.R1 each hour of evening is the flow of stepHour with the energy of the hour before",
+    run := do
+      let res := run7 Strategy.evening
+      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
+        else match badChain (bat 10 5) Strategy.evening res.hours with
+          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr res.hours[i]!.flow}"
+          | none => none },
+  { name := "CAP-simulation.R1 evening discharges only from 17:00 to 23:00 in a run",
+    run := do
+      let hs := (run7 Strategy.evening).hours
+      let bad := hs.toList.find? (fun h => h.hour.hour < 17 && h.flow.dischargeKwh > 1e-9)
+      let used := hs.toList.any (fun h => h.flow.dischargeKwh > 1e-9)
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match bad with
+          | some h => some s!"day {h.hour.day} hour {h.hour.hour} discharges {h.flow.dischargeKwh}"
+          | none => if used then none else some "no hour discharges" },
+  { name := "CAP-simulation.R1 each hour of greedy has the base load and the default flexible load",
+    run := do
+      let hs := (run7 Strategy.greedy).hours
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badLoad Strategy.greedy hs with
+          | some i => some s!"day {i / 24} has the wrong load"
+          | none => none },
+  -- A version that ignores placeFlex keeps the flexible load at 18:00 to 20:00.
+  { name := "CAP-simulation.R1 each hour of shift has the base load and the flexible load that placeFlex places",
+    run := do
+      let hs := (run7 Strategy.shift).hours
+      let moved := hs.toList.any (fun h =>
+        h.hour.hour == 12 && h.loadKwh > h.hour.baseLoadKwh + 0.5)
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badLoad Strategy.shift hs with
+          | some i => some s!"day {i / 24} has the wrong load"
+          | none => if moved then none else some "no day moves the flexible load to 12:00" },
+
+  -- CAP-simulation.R2
+  -- 2 kWh is at the edge of the power, and 2.5 kWh is past the edge.
+  { name := "CAP-simulation.R2 a battery with 2 kW of power takes all of a 2 kWh surplus",
+    run := do
+      return badFlow (stepHour (bat 5 2) 0 Strategy.greedy 12 3 1) [1, 2, 0, 0, 0, 0.1, 1.9] },
+  { name := "CAP-simulation.R2 a battery with 2 kW of power takes 2 kWh of a 2.5 kWh surplus",
+    run := do
+      return badFlow (stepHour (bat 5 2) 0 Strategy.greedy 12 3.5 1) [1, 2, 0, 0.5, 0, 0.1, 1.9] },
+  { name := "CAP-simulation.R2 a battery with 2 kW of power gives all of a 2 kWh shortfall",
+    run := do
+      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 20 0 2)
+        [0, 0, 2, 0, 0, 2 / 0.95 - 2, 5 - 2 / 0.95] },
+  { name := "CAP-simulation.R2 a battery with 2 kW of power gives 2 kWh of a 2.5 kWh shortfall",
+    run := do
+      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 20 0 2.5)
+        [0, 0, 2, 0, 0.5, 2 / 0.95 - 2, 5 - 2 / 0.95] },
+  { name := "CAP-simulation.R2 a full 5 kWh battery takes 0 kWh",
+    run := do
+      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 5] },
+  { name := "CAP-simulation.R2 a 5 kWh battery with 4 kWh stored takes 1/0.95 kWh and holds 5 kWh",
+    run := do
+      let c := 1 / 0.95
+      return badFlow (stepHour (bat 5 2) 4 Strategy.greedy 12 3 1)
+        [1, c, 0, 2 - c, 0, 0.05 * c, 5] },
+  { name := "CAP-simulation.R2 a 5 kWh battery with 2 kW of power charges and discharges 2 kWh or less each hour",
+    run := do
+      let hs := (run7 Strategy.greedy (bat 5 2)).hours
+      let bad := hs.toList.find? (fun h =>
+        h.flow.chargeKwh > 2 + 1e-9 || h.flow.dischargeKwh > 2 + 1e-9 ||
+        h.flow.chargeKwh < -1e-9 || h.flow.dischargeKwh < -1e-9)
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match bad with
+          | some h => some s!"day {h.hour.day} hour {h.hour.hour}: charge {h.flow.chargeKwh}, discharge {h.flow.dischargeKwh}"
+          | none => match badChain (bat 5 2) Strategy.greedy hs with
+            | some i => some s!"day {i / 24} hour {i % 24} is not the flow of stepHour"
+            | none => none },
+  { name := "CAP-simulation.R2 a 5 kWh battery with 2 kW of power holds 0 to 5 kWh each hour",
+    run := do
+      let hs := (run7 Strategy.greedy (bat 5 2)).hours
+      let bad := hs.toList.find? (fun h => h.flow.socKwh < -1e-9 || h.flow.socKwh > 5 + 1e-9)
+      let full := hs.toList.any (fun h => h.flow.socKwh > 4.9)
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match bad with
+          | some h => some s!"day {h.hour.day} hour {h.hour.hour} holds {h.flow.socKwh}"
+          | none => if full then none else some "no hour holds more than 4.9 kWh" },
+  { name := "CAP-simulation.R2 with a 10 kWh battery solar plus import equals load, export, losses and the stored energy",
+    run := do
+      let t := (run7 Strategy.greedy).totals
+      let lhs := t.pvKwh + t.importKwh
+      let rhs := t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh
+      return firstFail [
+        (t.pvKwh > 0 && t.lossKwh > 0, s!"solar {t.pvKwh}, losses {t.lossKwh}"),
+        (near lhs rhs 0.01, s!"solar and import {lhs}, load, export, losses and stored {rhs}")] },
+  { name := "CAP-simulation.R2 each hour of a greedy run balances with the energy of the hour before",
+    run := do
+      let hs := (run7 Strategy.greedy).hours
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match (List.range hs.size).find? (fun i =>
+            !balanced (socBefore hs i) hs[i]!.hour.pvKwh hs[i]!.loadKwh hs[i]!.flow) with
+          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr hs[i]!.flow}"
+          | none => none },
+  { name := "CAP-simulation.R2 the energy of an evening run and of a shift run balances",
+    run := do
+      let e := (run7 Strategy.evening).totals
+      let s := (run7 Strategy.shift).totals
+      let gap := fun (t : Totals) =>
+        t.pvKwh + t.importKwh - (t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh)
+      return firstFail [
+        (near (gap e) 0 0.01, s!"evening is off by {gap e}"),
+        (near (gap s) 0 0.01, s!"shift is off by {gap s}")] },
+  { name := "CAP-simulation.R2 a battery of 0 kWh takes 0 kWh and gives 0 kWh",
+    run := do
+      return badFlow (stepHour (bat 0 5) 0 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 0] <|>
+        badFlow (stepHour (bat 0 5) 0 Strategy.greedy 20 0 2) [0, 0, 0, 0, 2, 0, 0] },
+  { name := "CAP-simulation.R2 with a battery of 0 kWh greedy and none have the same totals",
+    run := do
+      let a := run7 Strategy.greedy (bat 0 5)
+      let b := run7 Strategy.none (bat 0 5)
+      return firstFail [
+        (a.hours.size == 8760 && b.hours.size == 8760, s!"{a.hours.size} and {b.hours.size} hours"),
+        (a.totals.pvKwh > 0, s!"solar {a.totals.pvKwh}")] <|>
+        badTotals a.totals b.totals },
+
+  -- CAP-simulation.R3
+  { name := "CAP-simulation.R3 at latitude 45 each total of none equals the sum of its hours",
+    run := do
+      return badSums (run7 Strategy.none) },
+  { name := "CAP-simulation.R3 at latitude 45 each total of greedy equals the sum of its hours",
+    run := do
+      return badSums (run7 Strategy.greedy) },
+  -- A version that leaves out the flexible load has 6205 kWh.
+  { name := "CAP-simulation.R3 the load total of greedy over 365 days is 7300 kWh",
+    run := do
+      let t := (run7 Strategy.greedy).totals
+      return if near t.loadKwh 7300 0.1 then none else some s!"load {t.loadKwh}" },
+  -- The solar total and the load total differ. Thus, a version that divides by the wrong
+  -- total fails here.
+  { name := "CAP-simulation.R3 at latitude 45 the self-consumption of greedy is 100 × (solar - export) / solar",
+    run := do
+      let t := (run7 Strategy.greedy).totals
+      let want := 100 * (t.pvKwh - t.exportKwh) / t.pvKwh
+      return firstFail [
+        (t.pvKwh > 0 && !near t.pvKwh t.loadKwh 1, s!"solar {t.pvKwh}, load {t.loadKwh}"),
+        (want > 0 && want < 100, s!"the formula gives {want}"),
+        (near t.selfConsumption want 1e-6, s!"got {t.selfConsumption}, want {want}")] },
+  { name := "CAP-simulation.R3 at latitude 45 the self-sufficiency of greedy is 100 × (load - import) / load",
+    run := do
+      let t := (run7 Strategy.greedy).totals
+      let want := 100 * (t.loadKwh - t.importKwh) / t.loadKwh
+      return firstFail [
+        (t.loadKwh > 0 && !near t.pvKwh t.loadKwh 1, s!"solar {t.pvKwh}, load {t.loadKwh}"),
+        (want > 0 && want < 100, s!"the formula gives {want}"),
+        (near t.selfSufficiency want 1e-6, s!"got {t.selfSufficiency}, want {want}")] },
+  -- A version that divides by 0 gives NaN, and NaN is not near 0.
+  { name := "CAP-simulation.R3 0 kW of panels gives 0% self-consumption and 0% self-sufficiency",
+    run := do
+      let t := (run7 Strategy.greedy (pv := 0)).totals
+      return firstFail [
+        (near t.pvKwh 0 1e-9, s!"solar {t.pvKwh}"),
+        (near t.selfConsumption 0 1e-9, s!"self-consumption {t.selfConsumption}"),
+        (near t.selfSufficiency 0 1e-9, s!"self-sufficiency {t.selfSufficiency}")] },
+  { name := "CAP-simulation.R3 0 days give each total 0, each ratio 0% and no months",
+    run := do
+      let res := run7 Strategy.greedy (days := 0)
+      return firstFail [
+        (res.hours.size == 0, s!"{res.hours.size} hours"),
+        (res.months.size == 0, s!"{res.months.size} months")] <|>
+        (match (totalsFields res.totals).find? (fun p => !near p.2 0 1e-12) with
+          | some p => some s!"{p.1} is {p.2}"
+          | none => none) },
+
+  -- CAP-simulation.R4
+  { name := "CAP-simulation.R4 365 days give 12 months with 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31 days",
+    run := do
+      let ms := (run7 Strategy.greedy).months.toList
+      return firstFail [
+        (ms.map (·.days) == [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
+          s!"days {ms.map (·.days)}"),
+        (ms.map (·.name) == monthNames, s!"names {ms.map (·.name)}")] },
+  { name := "CAP-simulation.R4 the solar totals of the 12 months add up to the solar total of the run",
+    run := do
+      let res := run7 Strategy.greedy
+      let s := res.months.foldl (fun acc m => acc + m.totals.pvKwh) 0
+      return if res.months.size == 12 && res.totals.pvKwh > 0 && near s res.totals.pvKwh 0.01
+        then none else some s!"{res.months.size} months, months {s}, run {res.totals.pvKwh}" },
+  -- A version that puts the hours in the wrong month keeps the sum and fails here.
+  { name := "CAP-simulation.R4 the totals and the ratios of each month of 365 days come from the hours of that month",
+    run := do
+      let res := run7 Strategy.greedy
+      return if res.months.size != 12 then some s!"{res.months.size} months" else badMonths res },
+  { name := "CAP-simulation.R4 400 days give 14 months and the last is February with 4 days",
+    run := do
+      let res := run7 Strategy.greedy (days := 400)
+      let got := gotMonths res
+      return firstFail [
+        (res.months.size == 14, s!"{res.months.size} months: {got}"),
+        (got.getLast? == some ("Feb", 4), s!"months {got}"),
+        (got == wantMonths 400, s!"months {got}")] <|> badMonths res },
+  -- 365 days is at the edge of a year, and 366 days is one past the edge.
+  { name := "CAP-simulation.R4 366 days give 13 months and the last is January with 1 day",
+    run := do
+      let got := gotMonths (run7 Strategy.greedy (days := 366))
+      return if got.length == 13 && got.getLast? == some ("Jan", 1) then none
+        else some s!"months {got}" },
+  { name := "CAP-simulation.R4 10 days give one month, January with 10 days",
+    run := do
+      let got := gotMonths (run7 Strategy.greedy (days := 10))
+      return if got == [("Jan", 10)] then none else some s!"months {got}" },
+  -- 31 days is at the edge of January, and 32 days is one past the edge.
+  { name := "CAP-simulation.R4 31 days give January with 31 days, and 32 days add February with 1 day",
+    run := do
+      let a := gotMonths (run7 Strategy.greedy (days := 31))
+      let b := gotMonths (run7 Strategy.greedy (days := 32))
+      return firstFail [
+        (a == [("Jan", 31)], s!"31 days give {a}"),
+        (b == [("Jan", 31), ("Feb", 1)], s!"32 days give {b}")] },
+  -- With no leap day, 59 days end at February, and 60 days add 1 March.
+  { name := "CAP-simulation.R4 59 days end with February and 60 days add March with 1 day",
+    run := do
+      let a := gotMonths (run7 Strategy.greedy (days := 59))
+      let b := gotMonths (run7 Strategy.greedy (days := 60))
+      return firstFail [
+        (a == [("Jan", 31), ("Feb", 28)], s!"59 days give {a}"),
+        (b == [("Jan", 31), ("Feb", 28), ("Mar", 1)], s!"60 days give {b}")] },
+  { name := "CAP-simulation.R4 at latitude 45 with seed 7 July has more than twice the solar energy of December",
+    run := do
+      let ms := (run7 Strategy.greedy).months
+      if ms.size != 12 then return some s!"{ms.size} months"
+      let jul := ms[6]!.totals.pvKwh
+      let dec := ms[11]!.totals.pvKwh
+      return if ms[6]!.name == "Jul" && ms[11]!.name == "Dec" && dec > 0 && jul > 2 * dec then none
+        else some s!"July {jul}, December {dec}" },
+  { name := "CAP-simulation.R4 at latitude 45 with seed 7 the July self-sufficiency is more than the January self-sufficiency",
+    run := do
+      let ms := (run7 Strategy.greedy).months
+      if ms.size != 12 then return some s!"{ms.size} months"
+      let jul := ms[6]!.totals.selfSufficiency
+      let jan := ms[0]!.totals.selfSufficiency
+      return if ms[6]!.name == "Jul" && ms[0]!.name == "Jan" && jul > jan then none
+        else some s!"July {jul}, January {jan}" },
+
+  -- CAP-simulation.R5
+  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW greedy has a higher self-consumption than none",
+    run := do
+      let g := (run7 Strategy.greedy).totals.selfConsumption
+      let n := (run7 Strategy.none).totals.selfConsumption
+      return if n > 0 && g > n then none else some s!"greedy {g}, none {n}" },
+  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW evening has a self-consumption no higher than greedy",
+    run := do
+      let g := (run7 Strategy.greedy).totals.selfConsumption
+      let e := (run7 Strategy.evening).totals.selfConsumption
+      return if g > 0 && e ≤ g + 1e-9 then none else some s!"evening {e}, greedy {g}" },
+  -- The text of R5 says that a battery must raise the self-consumption. A version in which
+  -- evening never uses the battery fails here.
+  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW evening has a higher self-consumption than none",
+    run := do
+      let e := (run7 Strategy.evening).totals.selfConsumption
+      let n := (run7 Strategy.none).totals.selfConsumption
+      return if e > n then none else some s!"evening {e}, none {n}" },
+  { name := "CAP-simulation.R5 with a battery of 0 kWh shift has a higher self-consumption than none",
+    run := do
+      let s := (run7 Strategy.shift (bat 0 5)).totals
+      let n := (run7 Strategy.none (bat 0 5)).totals
+      return firstFail [
+        (near s.loadKwh n.loadKwh 0.01, s!"shift load {s.loadKwh}, none load {n.loadKwh}"),
+        (s.selfConsumption > n.selfConsumption,
+          s!"shift {s.selfConsumption}, none {n.selfConsumption}")] }
+]
+
+def main (args : List String) : IO UInt32 := do
+  let sel := match args with
+    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
+    | [] => checks
+  let mut failed := 0
+  for c in sel do
+    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
+    match res with
+    | none => pure ()
+    | some msg =>
+      failed := failed + 1
+      IO.println s!"FAIL {c.name}: {msg}"
+  IO.println s!"{sel.length} checks, {failed} failed"
+  return if failed > 0 then 1 else 0
````

### tests/CAP-simulation.lean

````
/-
Component checks of CAP-simulation (hourly energy flows), for CH-0003 (hourly energy flows
and results).

The checks call only `Battery`, `efficiency`, `Flow`, `stepHour`, `HourResult`, `Totals`,
`Month`, `Result` and `simulate`. They also call `Site`, `Hour` and `scenario` of CH-0001
(scenario), and `Strategy`, `Strategy.decide` and `Strategy.placeFlex` of CH-0002
(strategies). No entry of the Interface can fail, so no check expects an error code. The
`seed` argument of `simulate` is the only seam. No check uses the clock.

In the lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of daily load,
3 kWh of it flexible. The battery holds 10 kWh with 5 kW of power, and the seed is 7, unless
the check says otherwise.
-/
import StoragePolicySim.Simulation
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

/-- A percentage. A ratio with nothing to divide by is 0%. -/
def pct (part whole : Float) : Float := if whole == 0 then 0 else 100 * part / whole

-- Helpers for the library

def site (lat : Float) (pv : Float := 5) (flex : Float := 3) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := 20, flexKwh := flex }

def bat (cap power : Float) : Battery := { capacityKwh := cap, powerKw := power }

/-- A run at latitude 45 with seed 7. -/
def run7 (s : Strategy) (b : Battery := bat 10 5) (days : Nat := 365) (pv : Float := 5) :
    Result :=
  simulate (site 45 pv) b s 7 days

def flowFields (f : Flow) : List (String × Float) :=
  [("direct", f.directKwh), ("charge", f.chargeKwh), ("discharge", f.dischargeKwh),
   ("export", f.exportKwh), ("import", f.importKwh), ("loss", f.lossKwh), ("soc", f.socKwh)]

/-- Compares a flow with the expected direct, charge, discharge, export, import, loss and
soc, in this order. -/
def badFlow (f : Flow) (want : List Float) : Option String :=
  if want.length != 7 then some "the check gives the wrong number of values"
  else match ((flowFields f).zip want).find? (fun p => !near p.1.2 p.2 1e-6) with
    | some p => some s!"{p.1.1} is {p.1.2}, want {p.2}, flow {repr f}"
    | none => none

def sameFlow (a b : Flow) : Bool :=
  ((flowFields a).zip (flowFields b)).all (fun p => near p.1.2 p.2.2 1e-9)

/-- The energy of one hour balances, with the stored energy before and after the hour. -/
def balanced (soc0 pv load : Float) (f : Flow) : Bool :=
  near (f.directKwh + f.chargeKwh + f.exportKwh) pv 1e-6 &&
  near (f.directKwh + f.dischargeKwh + f.importKwh) load 1e-6 &&
  near (soc0 + pv + f.importKwh) (load + f.exportKwh + f.lossKwh + f.socKwh) 1e-6

def socBefore (hs : Array HourResult) (i : Nat) : Float :=
  if i == 0 then 0 else hs[i - 1]!.flow.socKwh

/-- Finds the first hour whose flow is not `stepHour` with the energy of the hour before. -/
def badChain (b : Battery) (s : Strategy) (hs : Array HourResult) : Option Nat :=
  (List.range hs.size).find? (fun i =>
    let h := hs[i]!
    !sameFlow (stepHour b (socBefore hs i) s h.hour.hour h.hour.pvKwh h.loadKwh) h.flow)

/-- Finds the first hour whose load is not the base load and the flexible load that
`Strategy.placeFlex` places for its day. -/
def badLoad (s : Strategy) (hs : Array HourResult) : Option Nat :=
  let days := hs.size / 24
  let badDay := (List.range days).find? (fun d =>
    let pv := ((List.range 24).map (fun k => hs[d * 24 + k]!.hour.pvKwh)).toArray
    let fl := ((List.range 24).map (fun k => hs[d * 24 + k]!.hour.flexKwh)).toArray
    let placed := Strategy.placeFlex s pv fl
    (List.range 24).any (fun k =>
      let h := hs[d * 24 + k]!
      !near h.loadKwh (h.hour.baseLoadKwh + placed[k]!) 1e-9))
  badDay.map (fun d => d * 24)

def sameHour (a b : Hour) : Bool :=
  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh

def sumOf (hs : Array HourResult) (f : HourResult → Float) : Float :=
  hs.foldl (fun acc h => acc + f h) 0

def totalsFields (t : Totals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh),
   ("export", t.exportKwh), ("losses", t.lossKwh), ("self-used", t.selfUsedKwh),
   ("final soc", t.finalSocKwh), ("self-consumption", t.selfConsumption),
   ("self-sufficiency", t.selfSufficiency)]

def badTotals (a b : Totals) : Option String :=
  match ((totalsFields a).zip (totalsFields b)).find? (fun p => !near p.1.2 p.2.2 1e-6) with
  | some p => some s!"{p.1.1} is {p.1.2} and {p.2.2}"
  | none => none

/-- Compares each total with the sum of the hours of the run. -/
def badSums (res : Result) : Option String :=
  let hs := res.hours
  let t := res.totals
  firstFail [
    (hs.size == 8760, s!"{hs.size} hours"),
    (near t.pvKwh (sumOf hs (·.hour.pvKwh)) 0.01, s!"solar {t.pvKwh}, hours {sumOf hs (·.hour.pvKwh)}"),
    (near t.loadKwh (sumOf hs (·.loadKwh)) 0.01, s!"load {t.loadKwh}, hours {sumOf hs (·.loadKwh)}"),
    (near t.importKwh (sumOf hs (·.flow.importKwh)) 0.01,
      s!"import {t.importKwh}, hours {sumOf hs (·.flow.importKwh)}"),
    (near t.exportKwh (sumOf hs (·.flow.exportKwh)) 0.01,
      s!"export {t.exportKwh}, hours {sumOf hs (·.flow.exportKwh)}"),
    (near t.lossKwh (sumOf hs (·.flow.lossKwh)) 0.01,
      s!"losses {t.lossKwh}, hours {sumOf hs (·.flow.lossKwh)}"),
    (near t.selfUsedKwh (t.pvKwh - t.exportKwh) 0.01, s!"self-used {t.selfUsedKwh}"),
    (near t.finalSocKwh (socBefore hs hs.size) 1e-9, s!"final soc {t.finalSocKwh}")]

def monthNames : List String :=
  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

def monthDays : List Nat := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

/-- The months of a run of `days` days from 1 January, with the days of the run in each. -/
def wantMonths (days : Nat) : List (String × Nat) := Id.run do
  let mut out : List (String × Nat) := []
  let mut left := days
  for i in List.range (days / 28 + 2) do
    if left > 0 then
      let len := monthDays.getD (i % 12) 0
      let n := if left < len then left else len
      out := out ++ [(monthNames.getD (i % 12) "", n)]
      left := left - n
  return out

def gotMonths (res : Result) : List (String × Nat) :=
  res.months.toList.map (fun m => (m.name, m.days))

def sumDays (hs : Array HourResult) (startDay n : Nat) (f : HourResult → Float) : Float :=
  (List.range (n * 24)).foldl (fun acc k => acc + f hs[startDay * 24 + k]!) 0

/-- Compares the totals and the two ratios of each month with the hours of that month. -/
def badMonths (res : Result) : Option String := Id.run do
  let mut start := 0
  for i in List.range res.months.size do
    let m := res.months[i]!
    let t := m.totals
    let add := sumDays res.hours start m.days
    let pv := add (·.hour.pvKwh)
    let load := add (·.loadKwh)
    let imp := add (·.flow.importKwh)
    let exp := add (·.flow.exportKwh)
    let loss := add (·.flow.lossKwh)
    let r := firstFail [
      (near t.pvKwh pv 0.01, s!"solar {t.pvKwh}, hours {pv}"),
      (near t.loadKwh load 0.01, s!"load {t.loadKwh}, hours {load}"),
      (near t.importKwh imp 0.01, s!"import {t.importKwh}, hours {imp}"),
      (near t.exportKwh exp 0.01, s!"export {t.exportKwh}, hours {exp}"),
      (near t.lossKwh loss 0.01, s!"losses {t.lossKwh}, hours {loss}"),
      (near t.selfConsumption (pct (t.pvKwh - t.exportKwh) t.pvKwh) 1e-6,
        s!"self-consumption {t.selfConsumption}"),
      (near t.selfSufficiency (pct (t.loadKwh - t.importKwh) t.loadKwh) 1e-6,
        s!"self-sufficiency {t.selfSufficiency}")]
    match r with
    | some msg => return some s!"{m.name} (month {i + 1}): {msg}"
    | none => pure ()
    start := start + m.days
  return none

def checks : List Check := [
  -- CAP-simulation.R1
  { name := "CAP-simulation.R1 the efficiency is 0.95",
    run := do
      return if near efficiency 0.95 1e-9 then none else some s!"got {efficiency}" },
  -- A version with no loss gives 2 kWh stored.
  { name := "CAP-simulation.R1 an empty battery with 3 kWh of solar and 1 kWh of load takes 2 kWh and holds 1.9 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 0 Strategy.greedy 12 3 1) [1, 2, 0, 0, 0, 0.1, 1.9] },
  { name := "CAP-simulation.R1 a full battery takes 0 kWh and 2 kWh is export",
    run := do
      return badFlow (stepHour (bat 10 5) 10 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 10] },
  -- A version that limits the charge to the free room with no loss takes 0.95 kWh.
  { name := "CAP-simulation.R1 9.05 kWh stored takes 1 kWh of a 2 kWh surplus and then holds 10 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 9.05 Strategy.greedy 12 3 1) [1, 1, 0, 1, 0, 0.05, 10] },
  -- A version that ignores the loss in the free room takes 1 kWh and holds 9.95 kWh.
  { name := "CAP-simulation.R1 9 kWh stored takes 1/0.95 kWh of a 2 kWh surplus and then holds 10 kWh",
    run := do
      let c := 1 / 0.95
      return badFlow (stepHour (bat 10 5) 9 Strategy.greedy 12 3 1)
        [1, c, 0, 2 - c, 0, 0.05 * c, 10] },
  -- A version that limits the energy stored, not the energy in, takes 2/0.95 kWh.
  { name := "CAP-simulation.R1 a battery with 2 kW of power takes 2 kWh of a 3 kWh surplus and 1 kWh is export",
    run := do
      return badFlow (stepHour (bat 10 2) 0 Strategy.greedy 12 4 1) [1, 2, 0, 1, 0, 0.1, 1.9] },
  -- A version with no loss on the way out gives 1.9 kWh.
  { name := "CAP-simulation.R1 1.9 kWh stored gives 1.805 kWh for a shortfall of 2 kWh and 0.195 kWh is import",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.greedy 20 0 2)
        [0, 0, 1.805, 0, 0.195, 0.095, 0] },
  -- A version that takes the shortfall as the full load asks for 2.5 kWh.
  { name := "CAP-simulation.R1 0.5 kWh of solar and 2.5 kWh of load give 0.5 kWh direct and a shortfall of 2 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.greedy 20 0.5 2.5)
        [0.5, 0, 1.805, 0, 0.195, 0.095, 0] },
  -- A version that takes the given energy from the store with no loss holds 3 kWh.
  { name := "CAP-simulation.R1 5 kWh stored gives 2 kWh for a shortfall of 2 kWh and then holds 5 - 2/0.95 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 5 Strategy.greedy 20 0 2)
        [0, 0, 2, 0, 0, 2 / 0.95 - 2, 5 - 2 / 0.95] },
  { name := "CAP-simulation.R1 none with 1.9 kWh stored exports 2 kWh and still holds 1.9 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.none 12 3 1) [1, 0, 0, 2, 0, 0, 1.9] },
  { name := "CAP-simulation.R1 none with 1.9 kWh stored imports a shortfall of 2 kWh and still holds 1.9 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.none 20 0 2) [0, 0, 0, 0, 2, 0, 1.9] },
  -- The strategy gets the hour. A version that ignores the request of the strategy, or
  -- gives the wrong hour to the strategy, fails one of these two checks.
  { name := "CAP-simulation.R1 evening at 16:00 with 1.9 kWh stored gives 0 kWh and imports 2 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.evening 16 0 2) [0, 0, 0, 0, 2, 0, 1.9] },
  { name := "CAP-simulation.R1 evening at 17:00 with 1.9 kWh stored gives 1.805 kWh",
    run := do
      return badFlow (stepHour (bat 10 5) 1.9 Strategy.evening 17 0 2)
        [0, 0, 1.805, 0, 0.195, 0.095, 0] },
  -- A version that starts with a full or a half battery discharges in the first hour.
  { name := "CAP-simulation.R1 the first hour of greedy with seed 7 and 365 days imports its full load",
    run := do
      let res := run7 Strategy.greedy
      if res.hours.size != 8760 then return some s!"{res.hours.size} hours"
      let h := res.hours[0]!
      return firstFail [
        (h.hour.day == 0 && h.hour.hour == 0, s!"the first hour is day {h.hour.day} hour {h.hour.hour}"),
        (h.loadKwh > 0, s!"load {h.loadKwh}"),
        (near h.flow.importKwh h.loadKwh 1e-9, s!"load {h.loadKwh}, import {h.flow.importKwh}"),
        (near h.flow.dischargeKwh 0 1e-9, s!"discharge {h.flow.dischargeKwh}")] },
  { name := "CAP-simulation.R1 the hours of a run are the hours of the scenario",
    run := do
      let res := run7 Strategy.greedy
      let hs := scenario (site 45) 7 365
      return if res.hours.size == 8760 && hs.size == 8760 &&
          (List.range 8760).all (fun i => sameHour res.hours[i]!.hour hs[i]!) then none
        else some s!"{res.hours.size} hours, the scenario has {hs.size}" },
  -- A version that keeps the energy of the battery between hours wrongly, or that gives
  -- the wrong hour, solar or load to the hour, fails here.
  { name := "CAP-simulation.R1 each hour of greedy is the flow of stepHour with the energy of the hour before",
    run := do
      let res := run7 Strategy.greedy
      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
        else match badChain (bat 10 5) Strategy.greedy res.hours with
          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr res.hours[i]!.flow}"
          | none => none },
  { name := "CAP-simulation.R1 each hour of evening is the flow of stepHour with the energy of the hour before",
    run := do
      let res := run7 Strategy.evening
      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
        else match badChain (bat 10 5) Strategy.evening res.hours with
          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr res.hours[i]!.flow}"
          | none => none },
  { name := "CAP-simulation.R1 evening discharges only from 17:00 to 23:00 in a run",
    run := do
      let hs := (run7 Strategy.evening).hours
      let bad := hs.toList.find? (fun h => h.hour.hour < 17 && h.flow.dischargeKwh > 1e-9)
      let used := hs.toList.any (fun h => h.flow.dischargeKwh > 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour} discharges {h.flow.dischargeKwh}"
          | none => if used then none else some "no hour discharges" },
  { name := "CAP-simulation.R1 each hour of greedy has the base load and the default flexible load",
    run := do
      let hs := (run7 Strategy.greedy).hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badLoad Strategy.greedy hs with
          | some i => some s!"day {i / 24} has the wrong load"
          | none => none },
  -- A version that ignores placeFlex keeps the flexible load at 18:00 to 20:00.
  { name := "CAP-simulation.R1 each hour of shift has the base load and the flexible load that placeFlex places",
    run := do
      let hs := (run7 Strategy.shift).hours
      let moved := hs.toList.any (fun h =>
        h.hour.hour == 12 && h.loadKwh > h.hour.baseLoadKwh + 0.5)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badLoad Strategy.shift hs with
          | some i => some s!"day {i / 24} has the wrong load"
          | none => if moved then none else some "no day moves the flexible load to 12:00" },

  -- CAP-simulation.R2
  -- 2 kWh is at the edge of the power, and 2.5 kWh is past the edge.
  { name := "CAP-simulation.R2 a battery with 2 kW of power takes all of a 2 kWh surplus",
    run := do
      return badFlow (stepHour (bat 5 2) 0 Strategy.greedy 12 3 1) [1, 2, 0, 0, 0, 0.1, 1.9] },
  { name := "CAP-simulation.R2 a battery with 2 kW of power takes 2 kWh of a 2.5 kWh surplus",
    run := do
      return badFlow (stepHour (bat 5 2) 0 Strategy.greedy 12 3.5 1) [1, 2, 0, 0.5, 0, 0.1, 1.9] },
  { name := "CAP-simulation.R2 a battery with 2 kW of power gives all of a 2 kWh shortfall",
    run := do
      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 20 0 2)
        [0, 0, 2, 0, 0, 2 / 0.95 - 2, 5 - 2 / 0.95] },
  { name := "CAP-simulation.R2 a battery with 2 kW of power gives 2 kWh of a 2.5 kWh shortfall",
    run := do
      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 20 0 2.5)
        [0, 0, 2, 0, 0.5, 2 / 0.95 - 2, 5 - 2 / 0.95] },
  { name := "CAP-simulation.R2 a full 5 kWh battery takes 0 kWh",
    run := do
      return badFlow (stepHour (bat 5 2) 5 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 5] },
  { name := "CAP-simulation.R2 a 5 kWh battery with 4 kWh stored takes 1/0.95 kWh and holds 5 kWh",
    run := do
      let c := 1 / 0.95
      return badFlow (stepHour (bat 5 2) 4 Strategy.greedy 12 3 1)
        [1, c, 0, 2 - c, 0, 0.05 * c, 5] },
  { name := "CAP-simulation.R2 a 5 kWh battery with 2 kW of power charges and discharges 2 kWh or less each hour",
    run := do
      let hs := (run7 Strategy.greedy (bat 5 2)).hours
      let bad := hs.toList.find? (fun h =>
        h.flow.chargeKwh > 2 + 1e-9 || h.flow.dischargeKwh > 2 + 1e-9 ||
        h.flow.chargeKwh < -1e-9 || h.flow.dischargeKwh < -1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour}: charge {h.flow.chargeKwh}, discharge {h.flow.dischargeKwh}"
          | none => match badChain (bat 5 2) Strategy.greedy hs with
            | some i => some s!"day {i / 24} hour {i % 24} is not the flow of stepHour"
            | none => none },
  { name := "CAP-simulation.R2 a 5 kWh battery with 2 kW of power holds 0 to 5 kWh each hour",
    run := do
      let hs := (run7 Strategy.greedy (bat 5 2)).hours
      let bad := hs.toList.find? (fun h => h.flow.socKwh < -1e-9 || h.flow.socKwh > 5 + 1e-9)
      let full := hs.toList.any (fun h => h.flow.socKwh > 4.9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour} holds {h.flow.socKwh}"
          | none => if full then none else some "no hour holds more than 4.9 kWh" },
  { name := "CAP-simulation.R2 with a 10 kWh battery solar plus import equals load, export, losses and the stored energy",
    run := do
      let t := (run7 Strategy.greedy).totals
      let lhs := t.pvKwh + t.importKwh
      let rhs := t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh
      return firstFail [
        (t.pvKwh > 0 && t.lossKwh > 0, s!"solar {t.pvKwh}, losses {t.lossKwh}"),
        (near lhs rhs 0.01, s!"solar and import {lhs}, load, export, losses and stored {rhs}")] },
  { name := "CAP-simulation.R2 each hour of a greedy run balances with the energy of the hour before",
    run := do
      let hs := (run7 Strategy.greedy).hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range hs.size).find? (fun i =>
            !balanced (socBefore hs i) hs[i]!.hour.pvKwh hs[i]!.loadKwh hs[i]!.flow) with
          | some i => some s!"day {i / 24} hour {i % 24}: flow {repr hs[i]!.flow}"
          | none => none },
  { name := "CAP-simulation.R2 the energy of an evening run and of a shift run balances",
    run := do
      let e := (run7 Strategy.evening).totals
      let s := (run7 Strategy.shift).totals
      let gap := fun (t : Totals) =>
        t.pvKwh + t.importKwh - (t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh)
      return firstFail [
        (near (gap e) 0 0.01, s!"evening is off by {gap e}"),
        (near (gap s) 0 0.01, s!"shift is off by {gap s}")] },
  { name := "CAP-simulation.R2 a battery of 0 kWh takes 0 kWh and gives 0 kWh",
    run := do
      return badFlow (stepHour (bat 0 5) 0 Strategy.greedy 12 3 1) [1, 0, 0, 2, 0, 0, 0] <|>
        badFlow (stepHour (bat 0 5) 0 Strategy.greedy 20 0 2) [0, 0, 0, 0, 2, 0, 0] },
  { name := "CAP-simulation.R2 with a battery of 0 kWh greedy and none have the same totals",
    run := do
      let a := run7 Strategy.greedy (bat 0 5)
      let b := run7 Strategy.none (bat 0 5)
      return firstFail [
        (a.hours.size == 8760 && b.hours.size == 8760, s!"{a.hours.size} and {b.hours.size} hours"),
        (a.totals.pvKwh > 0, s!"solar {a.totals.pvKwh}")] <|>
        badTotals a.totals b.totals },

  -- CAP-simulation.R3
  { name := "CAP-simulation.R3 at latitude 45 each total of none equals the sum of its hours",
    run := do
      return badSums (run7 Strategy.none) },
  { name := "CAP-simulation.R3 at latitude 45 each total of greedy equals the sum of its hours",
    run := do
      return badSums (run7 Strategy.greedy) },
  -- A version that leaves out the flexible load has 6205 kWh.
  { name := "CAP-simulation.R3 the load total of greedy over 365 days is 7300 kWh",
    run := do
      let t := (run7 Strategy.greedy).totals
      return if near t.loadKwh 7300 0.1 then none else some s!"load {t.loadKwh}" },
  -- The solar total and the load total differ. Thus, a version that divides by the wrong
  -- total fails here.
  { name := "CAP-simulation.R3 at latitude 45 the self-consumption of greedy is 100 × (solar - export) / solar",
    run := do
      let t := (run7 Strategy.greedy).totals
      let want := 100 * (t.pvKwh - t.exportKwh) / t.pvKwh
      return firstFail [
        (t.pvKwh > 0 && !near t.pvKwh t.loadKwh 1, s!"solar {t.pvKwh}, load {t.loadKwh}"),
        (want > 0 && want < 100, s!"the formula gives {want}"),
        (near t.selfConsumption want 1e-6, s!"got {t.selfConsumption}, want {want}")] },
  { name := "CAP-simulation.R3 at latitude 45 the self-sufficiency of greedy is 100 × (load - import) / load",
    run := do
      let t := (run7 Strategy.greedy).totals
      let want := 100 * (t.loadKwh - t.importKwh) / t.loadKwh
      return firstFail [
        (t.loadKwh > 0 && !near t.pvKwh t.loadKwh 1, s!"solar {t.pvKwh}, load {t.loadKwh}"),
        (want > 0 && want < 100, s!"the formula gives {want}"),
        (near t.selfSufficiency want 1e-6, s!"got {t.selfSufficiency}, want {want}")] },
  -- A version that divides by 0 gives NaN, and NaN is not near 0.
  { name := "CAP-simulation.R3 0 kW of panels gives 0% self-consumption and 0% self-sufficiency",
    run := do
      let t := (run7 Strategy.greedy (pv := 0)).totals
      return firstFail [
        (near t.pvKwh 0 1e-9, s!"solar {t.pvKwh}"),
        (near t.selfConsumption 0 1e-9, s!"self-consumption {t.selfConsumption}"),
        (near t.selfSufficiency 0 1e-9, s!"self-sufficiency {t.selfSufficiency}")] },
  { name := "CAP-simulation.R3 0 days give each total 0, each ratio 0% and no months",
    run := do
      let res := run7 Strategy.greedy (days := 0)
      return firstFail [
        (res.hours.size == 0, s!"{res.hours.size} hours"),
        (res.months.size == 0, s!"{res.months.size} months")] <|>
        (match (totalsFields res.totals).find? (fun p => !near p.2 0 1e-12) with
          | some p => some s!"{p.1} is {p.2}"
          | none => none) },

  -- CAP-simulation.R4
  { name := "CAP-simulation.R4 365 days give 12 months with 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31 days",
    run := do
      let ms := (run7 Strategy.greedy).months.toList
      return firstFail [
        (ms.map (·.days) == [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
          s!"days {ms.map (·.days)}"),
        (ms.map (·.name) == monthNames, s!"names {ms.map (·.name)}")] },
  { name := "CAP-simulation.R4 the solar totals of the 12 months add up to the solar total of the run",
    run := do
      let res := run7 Strategy.greedy
      let s := res.months.foldl (fun acc m => acc + m.totals.pvKwh) 0
      return if res.months.size == 12 && res.totals.pvKwh > 0 && near s res.totals.pvKwh 0.01
        then none else some s!"{res.months.size} months, months {s}, run {res.totals.pvKwh}" },
  -- A version that puts the hours in the wrong month keeps the sum and fails here.
  { name := "CAP-simulation.R4 the totals and the ratios of each month of 365 days come from the hours of that month",
    run := do
      let res := run7 Strategy.greedy
      return if res.months.size != 12 then some s!"{res.months.size} months" else badMonths res },
  { name := "CAP-simulation.R4 400 days give 14 months and the last is February with 4 days",
    run := do
      let res := run7 Strategy.greedy (days := 400)
      let got := gotMonths res
      return firstFail [
        (res.months.size == 14, s!"{res.months.size} months: {got}"),
        (got.getLast? == some ("Feb", 4), s!"months {got}"),
        (got == wantMonths 400, s!"months {got}")] <|> badMonths res },
  -- 365 days is at the edge of a year, and 366 days is one past the edge.
  { name := "CAP-simulation.R4 366 days give 13 months and the last is January with 1 day",
    run := do
      let got := gotMonths (run7 Strategy.greedy (days := 366))
      return if got.length == 13 && got.getLast? == some ("Jan", 1) then none
        else some s!"months {got}" },
  { name := "CAP-simulation.R4 10 days give one month, January with 10 days",
    run := do
      let got := gotMonths (run7 Strategy.greedy (days := 10))
      return if got == [("Jan", 10)] then none else some s!"months {got}" },
  -- 31 days is at the edge of January, and 32 days is one past the edge.
  { name := "CAP-simulation.R4 31 days give January with 31 days, and 32 days add February with 1 day",
    run := do
      let a := gotMonths (run7 Strategy.greedy (days := 31))
      let b := gotMonths (run7 Strategy.greedy (days := 32))
      return firstFail [
        (a == [("Jan", 31)], s!"31 days give {a}"),
        (b == [("Jan", 31), ("Feb", 1)], s!"32 days give {b}")] },
  -- With no leap day, 59 days end at February, and 60 days add 1 March.
  { name := "CAP-simulation.R4 59 days end with February and 60 days add March with 1 day",
    run := do
      let a := gotMonths (run7 Strategy.greedy (days := 59))
      let b := gotMonths (run7 Strategy.greedy (days := 60))
      return firstFail [
        (a == [("Jan", 31), ("Feb", 28)], s!"59 days give {a}"),
        (b == [("Jan", 31), ("Feb", 28), ("Mar", 1)], s!"60 days give {b}")] },
  { name := "CAP-simulation.R4 at latitude 45 with seed 7 July has more than twice the solar energy of December",
    run := do
      let ms := (run7 Strategy.greedy).months
      if ms.size != 12 then return some s!"{ms.size} months"
      let jul := ms[6]!.totals.pvKwh
      let dec := ms[11]!.totals.pvKwh
      return if ms[6]!.name == "Jul" && ms[11]!.name == "Dec" && dec > 0 && jul > 2 * dec then none
        else some s!"July {jul}, December {dec}" },
  { name := "CAP-simulation.R4 at latitude 45 with seed 7 the July self-sufficiency is more than the January self-sufficiency",
    run := do
      let ms := (run7 Strategy.greedy).months
      if ms.size != 12 then return some s!"{ms.size} months"
      let jul := ms[6]!.totals.selfSufficiency
      let jan := ms[0]!.totals.selfSufficiency
      return if ms[6]!.name == "Jul" && ms[0]!.name == "Jan" && jul > jan then none
        else some s!"July {jul}, January {jan}" },

  -- CAP-simulation.R5
  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW greedy has a higher self-consumption than none",
    run := do
      let g := (run7 Strategy.greedy).totals.selfConsumption
      let n := (run7 Strategy.none).totals.selfConsumption
      return if n > 0 && g > n then none else some s!"greedy {g}, none {n}" },
  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW evening has a self-consumption no higher than greedy",
    run := do
      let g := (run7 Strategy.greedy).totals.selfConsumption
      let e := (run7 Strategy.evening).totals.selfConsumption
      return if g > 0 && e ≤ g + 1e-9 then none else some s!"evening {e}, greedy {g}" },
  -- The text of R5 says that a battery must raise the self-consumption. A version in which
  -- evening never uses the battery fails here.
  { name := "CAP-simulation.R5 with a battery of 10 kWh and 5 kW evening has a higher self-consumption than none",
    run := do
      let e := (run7 Strategy.evening).totals.selfConsumption
      let n := (run7 Strategy.none).totals.selfConsumption
      return if e > n then none else some s!"evening {e}, none {n}" },
  { name := "CAP-simulation.R5 with a battery of 0 kWh shift has a higher self-consumption than none",
    run := do
      let s := (run7 Strategy.shift (bat 0 5)).totals
      let n := (run7 Strategy.none (bat 0 5)).totals
      return firstFail [
        (near s.loadKwh n.loadKwh 0.01, s!"shift load {s.loadKwh}, none load {n.loadKwh}"),
        (s.selfConsumption > n.selfConsumption,
          s!"shift {s.selfConsumption}, none {n.selfConsumption}")] }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
    match res with
    | none => pure ()
    | some msg =>
      failed := failed + 1
      IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
````

