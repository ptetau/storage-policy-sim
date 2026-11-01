# Review packet · CH-0003-simulation · visual

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: f21a00d01dba323fd0febe587e1e15c4ebac9ea9

# Remit: visual

Default: yes

You judge the recording of the change: the frames of `review.gif`. The change passed its
checks and its code reviews already. You do not see the code or the checks.

The packet holds the acceptance lines of the change, the script of the recording
(`visual.json`), and the list of the frames. Read each frame.

- Each acceptance line of the change has one or more frames. The caption of its first
  frame starts with the requirement ID.
- Each frame shows what its caption claims, after its step. A blank frame, or a frame with
  the screen from before the step, is a problem.
- A caption with `setup:` after the ID only prepares a state. Its frame shows that state,
  and nothing more is necessary.
- When several frames share one caption, the last of them shows the claim. The frames
  before it show the steps toward it.
- Each part of a caption is visible on screen. A frame that shows less than its caption
  claims is a problem, also when the claim is probably true. Examples:
  - An exit code on screen comes from a different command, for example `wc` after a pipe.
  - The input is too small to show the effect, for example a limit of 7 on a file with 3
    words.
- The frames show the behaviour as a user meets it:
  - A web app: pages and clicks. A page cannot show a status code, a header, a redirect,
    or the target of a form. These show in a terminal frame of `curl -si`.
  - In a web app, a terminal frame that shows or searches the HTML of a page, in place of
    the page, is a `script` problem.
  - A CLI: commands and their output.
  - A library: a short script that calls the interface.
- An error on screen is a problem, unless its acceptance line asks for that error.
- Each recording ends with a frame that shows all checks pass.

Write each problem as `<frame> · <what is wrong> · <the acceptance line or rule> · <kind>`.
The kind is one of these:

- `script`: the recording is wrong. Examples are a wrong selector, a missing step, and a
  step that shows the screen from before the change. A frame that shows less than its
  caption claims is also a `script` problem.
- `app`: the step does what its acceptance line says, but the app does not meet the line.

Do not write follow-ups. Put a wish for new behaviour of the app under "Notes". A frame
that shows less than its caption claims is not a wish. It is a `script` problem.

On a re-review, judge only the frames that do not have the mark "unchanged since the
earlier review".

## The change spec

````
# CH-0003 · Hourly energy flows and results

Intent: IN-0001 · Scope: CAP-simulation · Status: in review · Ticket: none · Branch: pdlc/CH-0003-simulation · Base: pdlc/CH-0002-strategies

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

## Specs it relies on

## The script of the recording

````
{
  "kind": "terminal",
  "title": "CH-0003 \u00b7 Hourly energy flows and results",
  "width": 1100,
  "height": 640,
  "steps": [
    {
      "caption": "CAP-simulation \u00b7 setup: build the library",
      "run": "lake build 2>&1 | tail -1"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 empty battery, 3 kWh solar, 1 kWh load: 1 direct, 2 charge, holds 1.9",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-1"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 full battery: 0 kWh charges and 2 kWh is export",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-2"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 9.05 kWh stored, 2 kWh surplus: 1 charges, 1 export, holds 10",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-3"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 2 kW of power, 3 kWh surplus: 2 kWh charges and 1 kWh is export",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-4"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 1.9 kWh stored, 2 kWh shortfall: gives 1.805, import 0.195",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-5"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 none with 1.9 kWh stored: 2 kWh export, still holds 1.9",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-6"
    },
    {
      "caption": "CAP-simulation.R1 \u00b7 greedy, seed 7: the first hour imports its full load",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r1-7"
    },
    {
      "caption": "CAP-simulation.R2 \u00b7 5 kWh / 2 kW battery: no hour charges or discharges over 2 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r2-1"
    },
    {
      "caption": "CAP-simulation.R2 \u00b7 5 kWh / 2 kW battery: holds 0 to 5 kWh each hour",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r2-2"
    },
    {
      "caption": "CAP-simulation.R2 \u00b7 solar + import = load + export + losses + stored, within 0.01 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r2-3"
    },
    {
      "caption": "CAP-simulation.R2 \u00b7 0 kWh battery: greedy and none have the same totals",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r2-4"
    },
    {
      "caption": "CAP-simulation.R3 \u00b7 each total of none equals the sum of its hours",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r3-1"
    },
    {
      "caption": "CAP-simulation.R3 \u00b7 self-consumption is 100 \u00d7 (solar - export) / solar",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r3-2"
    },
    {
      "caption": "CAP-simulation.R3 \u00b7 self-sufficiency is 100 \u00d7 (load - import) / load",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r3-3"
    },
    {
      "caption": "CAP-simulation.R3 \u00b7 0 kW of panels: 0% self-consumption and 0% self-sufficiency",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r3-4"
    },
    {
      "caption": "CAP-simulation.R3 \u00b7 0 days: each total 0, each ratio 0%, no months",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r3-5"
    },
    {
      "caption": "CAP-simulation.R4 \u00b7 365 days: 12 months with 31, 28, 31, ... 31 days",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r4-1"
    },
    {
      "caption": "CAP-simulation.R4 \u00b7 the 12 monthly solar totals add up to the solar total",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r4-2"
    },
    {
      "caption": "CAP-simulation.R4 \u00b7 400 days: 14 months, the last is February with 4 days",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r4-3"
    },
    {
      "caption": "CAP-simulation.R4 \u00b7 10 days: one month, January with 10 days",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r4-4"
    },
    {
      "caption": "CAP-simulation.R4 \u00b7 latitude 45: July has over twice the solar of December",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r4-5"
    },
    {
      "caption": "CAP-simulation.R4 \u00b7 latitude 45: July self-sufficiency is more than January",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r4-6"
    },
    {
      "caption": "CAP-simulation.R5 \u00b7 10 kWh battery: greedy has a higher self-consumption than none",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r5-1"
    },
    {
      "caption": "CAP-simulation.R5 \u00b7 10 kWh battery: evening is no higher than greedy",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r5-2"
    },
    {
      "caption": "CAP-simulation.R5 \u00b7 0 kWh battery: shift has a higher self-consumption than none",
      "run": "lake env lean --run pdlc/changes/CH-0003-simulation/demo.lean r5-3"
    },
    {
      "caption": "CH-0003 \u00b7 all checks pass",
      "run": "for f in tests/*.lean; do lake env lean --run \"$f\" || exit 1; done"
    }
  ]
}
````

## The frames

Read each frame:

- pdlc/changes/CH-0003-simulation/frames/01.png
- pdlc/changes/CH-0003-simulation/frames/02.png
- pdlc/changes/CH-0003-simulation/frames/03.png
- pdlc/changes/CH-0003-simulation/frames/04.png
- pdlc/changes/CH-0003-simulation/frames/05.png
- pdlc/changes/CH-0003-simulation/frames/06.png
- pdlc/changes/CH-0003-simulation/frames/07.png
- pdlc/changes/CH-0003-simulation/frames/08.png
- pdlc/changes/CH-0003-simulation/frames/09.png
- pdlc/changes/CH-0003-simulation/frames/10.png
- pdlc/changes/CH-0003-simulation/frames/11.png
- pdlc/changes/CH-0003-simulation/frames/12.png
- pdlc/changes/CH-0003-simulation/frames/13.png
- pdlc/changes/CH-0003-simulation/frames/14.png
- pdlc/changes/CH-0003-simulation/frames/15.png
- pdlc/changes/CH-0003-simulation/frames/16.png
- pdlc/changes/CH-0003-simulation/frames/17.png
- pdlc/changes/CH-0003-simulation/frames/18.png
- pdlc/changes/CH-0003-simulation/frames/19.png
- pdlc/changes/CH-0003-simulation/frames/20.png
- pdlc/changes/CH-0003-simulation/frames/21.png
- pdlc/changes/CH-0003-simulation/frames/22.png
- pdlc/changes/CH-0003-simulation/frames/23.png
- pdlc/changes/CH-0003-simulation/frames/24.png
- pdlc/changes/CH-0003-simulation/frames/25.png
- pdlc/changes/CH-0003-simulation/frames/26.png
- pdlc/changes/CH-0003-simulation/frames/27.png
