# Review packet · IN-0001-solar-self-consumption-sim · tests (acceptance checks)

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 8140b59cb6287722876e78c8b75412b987542569

Acceptance-Locked: a404bbe

These are the acceptance checks of an intent. Judge them by the section "Acceptance
checks of an intent" of the remit below, and by its "Wrong versions".

## Re-review

Earlier review: 67970d4

An earlier review of this remit judged the checks locked at 67970d4. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.
Write a "Wrong versions" line only for each check that changed. If no check
changed, write "none" under "Wrong versions".

### Earlier problems

none

### Changes since the earlier review

````
diff --git a/tests/acceptance/IN-0001.acceptance.lean b/tests/acceptance/IN-0001.acceptance.lean
index 17a7776..6833666 100644
--- a/tests/acceptance/IN-0001.acceptance.lean
+++ b/tests/acceptance/IN-0001.acceptance.lean
@@ -1011,7 +1011,7 @@ def checks : List Check := [
 
 def main (args : List String) : IO UInt32 := do
   let sel := match args with
-    | f :: _ => checks.filter (fun c => c.name.startsWith (f ++ " "))
+    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
     | [] => checks
   let mut failed := 0
   for c in sel do
````

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

## The intent

````
# IN-0001 · Solar self-consumption simulator

Status: building · Ticket: none · Branch: pdlc/IN-0001-solar-sim · Added: 2026-10-31

## What and why

"Build a simulator for both seasonal and weather variation so we can test strategies for
maximizing self consumption of solar captured power. Written in lean4 using latest pdlc."

## Requirements

- CAP-scenario.R1 (seasonal sun): added
- CAP-scenario.R2 (daily weather): added
- CAP-scenario.R3 (household load): added
- CAP-strategies.R1 (strategy names): added
- CAP-strategies.R2 (no battery use): added
- CAP-strategies.R3 (greedy battery use): added
- CAP-strategies.R4 (evening battery use): added
- CAP-strategies.R5 (load shift into sun): added
- CAP-simulation.R1 (energy flows of an hour): added
- CAP-simulation.R2 (battery limits): added
- CAP-simulation.R3 (totals and ratios): added
- CAP-simulation.R4 (monthly totals): added
- CAP-simulation.R5 (strategy order): added
- JOB-simulate.R1 (run one strategy): added
- JOB-simulate.R2 (monthly table): added
- JOB-simulate.R3 (compare strategies): added
- JOB-simulate.R4 (repeatable weather): added
- JOB-simulate.R5 (bad command line): added

## Changes

- CH-0001 (scenario): CAP-scenario (sun, weather and load)
- CH-0002 (strategies): CAP-strategies (battery and load strategies)
- CH-0003 (simulation): CAP-simulation (hourly energy flows)
- CH-0004 (sim command): JOB-simulate (the `sim` command)

## Acceptance checks

Acceptance-File: tests/acceptance/IN-0001.acceptance.lean
Acceptance-Locked: a404bbe
Acceptance-Passed: none

## Notes

- IN-0001 (simulator): Which language? → Lean 4, with Lake, from the words of the intent.
- IN-0001 (simulator): What does "self consumption" mean? → the share of the solar energy that the house uses itself, and does not export (assumed).
- IN-0001 (simulator): What is the time step? → one hour, from 1 January, for a number of days (assumed).
- IN-0001 (simulator): Where does weather come from? → a seeded random model, so that each run with the same seed is the same (assumed).
- IN-0001 (simulator): Which strategies? → none, greedy, evening, and shift (assumed), so that a battery strategy and a load strategy can be compared.
- JOB-simulate.R5 (bad command line): What do bad values give? → one `error: <code>: <detail>` line on stderr, empty stdout, and exit code 2 (assumed).
- JOB-simulate.R5 (bad command line): Which number forms count? → an optional sign, digits, and an optional point with digits. `--days` and `--seed` are whole (assumed).
- JOB-simulate.R5 (bad command line): What ranges hold? → the table of the requirement, for example `--days` 1 to 3650 (assumed).
- JOB-simulate.R5 (bad command line): What if an option comes twice? → the last value counts (assumed).
- JOB-simulate.R3 (compare strategies): Does `sim compare` take `--strategy` or `--monthly`? → no, each gives `UNKNOWN_OPTION` (assumed).
- CAP-scenario.R1 (seasonal sun): What if a latitude or a size is out of range? → JOB-simulate.R5 (bad command line) refuses it before the simulation (assumed).
- DES-lean-checks (Lean check files): How does a Lean check file run and report? → a Lean script with a name filter and a count line (assumed).
- JOB-simulate.R1 (run one strategy): was "`--flex`: 3", now "`--flex`: 3, or the `--load` value when that is less" (assumed).
- JOB-simulate.R5 (bad command line): How does a range show? → `(<lowest> to <highest>)` as in the table (assumed).

## Handoff

### Handoff · IN-0001 · acceptance → tests

Time: 2026-10-31T23:14:03+00:00

### Done

- The test writer wrote 154 acceptance checks in `tests/acceptance/IN-0001.acceptance.lean`, for all 18 requirements of IN-0001 (simulator).
- The checks failed before any code, because the library and `lakefile.toml` do not exist yet.
- The first review failed on one check of CAP-simulation.R2 (battery limits). The test writer fixed it, and the re-review passed.
- The lock is `67970d4`. The file has no stored-data line.

### Decided on defaults

- JOB-simulate.R1 (run one strategy): What is the `--flex` default when `--load` is less than 3? → the `--load` value (assumed).
- JOB-simulate.R5 (bad command line): How does a range show? → `(<lowest> to <highest>)` as in the table (assumed).

### Open

- The check of CAP-simulation.R2 (battery limits) needs one hour that discharges exactly 2 kWh. The load profile of CH-0001 (scenario) must give such an hour.

### Look here

- `tests/acceptance/IN-0001.acceptance.lean`
- `pdlc/acceptance/IN-0001-solar-self-consumption-sim/review/tests/result.md`

### Don't redo

- The acceptance checks and their lock.

### Next: do this first

Start CH-0001 (scenario) from `pdlc/IN-0001-solar-sim`. Its component checks go in `tests/CAP-scenario.lean`.
````

## The requirements, in full

### CAP-scenario.R1 · Seasonal sun

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

### CAP-strategies.R1 · Strategy names

Status: ready · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: ready · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: ready · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

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

### JOB-simulate.R1 · Run one strategy

Status: ready · Intents: IN-0001

`sim run` simulates one strategy, prints the result on stdout, and exits with 0. Each line
is a label, spaces to column 19, and a value (assumed). An energy has one decimal and `kWh`,
and a ratio has one decimal and `%` (assumed).

The lines are `strategy`, `days`, `seed`, `solar`, `load`, `self-used`, `import`, `export`,
`losses`, `self-consumption` and `self-sufficiency`, in this order (assumed).

The options and their defaults are these (assumed):

- `--strategy`: `greedy`.
- `--days`: 365. `--seed`: 1.
- `--lat`: -41.3 (degrees). `--pv`: 5 (kW of panels).
- `--battery`: 10 (kWh). `--power`: 5 (kW of the battery).
- `--load`: 20 (kWh each day). `--flex`: 3 (kWh of the daily load that can move), or the `--load` value when that is less.

- Given no options, when the person runs `sim run`, then it prints the 11 lines in order and exits with 0.
- Given no options, when the person runs `sim run`, then the first three lines are `strategy          greedy`, `days              365` and `seed              1`.
- Given `--pv 0`, when the person runs `sim run`, then the solar line is `solar             0.0 kWh`. The self-consumption line is `self-consumption  0.0 %`.
- Given `--strategy shift --days 30 --lat 45`, when the person runs `sim run`, then the lines show `shift` and 30 days. The values equal CAP-simulation (hourly energy flows) results for these options.
- Given `--strategy none --battery 0`, when the person runs `sim run`, then the `export` value equals `solar` less `self-used`, within 0.1 kWh.
- Given `--days 3650`, when the person runs `sim run`, then it exits with 0 and the `days` line shows 3650.

### JOB-simulate.R2 · Monthly table

Status: ready · Intents: IN-0001

`sim run --monthly` prints the 11 lines, a blank line, and a table with one row for each
month (assumed). The header is `month solar-kWh load-kWh import-kWh export-kWh
self-consumption-% self-sufficiency-%` with the columns aligned by spaces (assumed). Each
row starts with the short month name, for example `Jan`, and has seven fields.

- Given `--monthly`, when the person runs `sim run`, then the table has the header and 12 rows, from `Jan` to `Dec`.
- Given `--monthly --days 400`, when the person runs `sim run`, then the table has 14 rows. The last two rows are `Jan` and `Feb`.
- Given `--monthly --lat 45`, when the person runs `sim run`, then the `Jul` solar value is more than twice the `Dec` solar value.
- Given no `--monthly`, when the person runs `sim run`, then it prints only the 11 lines.

### JOB-simulate.R3 · Compare strategies

Status: ready · Intents: IN-0001

`sim compare` runs each strategy on the same weather, and prints one row for each strategy.
The header is `strategy self-consumption-% self-sufficiency-% import-kWh export-kWh`
(assumed). The rows come in the order of the strategy list, and the columns align by
spaces. `sim compare` takes each option of `sim run` except `--strategy` and `--monthly`
(assumed).

- Given no options, when the person runs `sim compare`, then it prints the header and the rows `none`, `greedy`, `evening` and `shift`, in this order.
- Given `--seed 9 --lat 45`, when the person runs `sim compare`, then the `greedy` row shows the same four values as `sim run --seed 9 --lat 45`.
- Given `--lat 45`, when the person runs `sim compare`, then the `greedy` self-consumption is more than the `none` self-consumption.
- Given `--strategy greedy`, when the person runs `sim compare`, then it prints `error: UNKNOWN_OPTION: --strategy` on stderr and exits with 2.

### JOB-simulate.R4 · Repeatable weather

Status: ready · Intents: IN-0001

The seed sets the weather. The same options and seed give the same output each time.

- Given `--seed 5`, when the person runs `sim run` two times, then the two outputs are the same.
- Given `--seed 1` and `--seed 2`, when the person runs `sim run` with each, then the two `solar` values differ.

### JOB-simulate.R5 · Bad command line

Status: ready · Intents: IN-0001

A bad command line prints one error line on stderr, prints nothing on stdout, and exits
with 2 (assumed). The line is `error: <code>: <detail>` (assumed). `sim`, `sim help` and
`sim --help` print the usage on stdout and exit with 0.

A number option takes an optional sign, digits, and an optional point with more digits
(assumed). `--days` and `--seed` take only whole numbers (assumed). When an option comes
twice, the last value counts (assumed). The `--flex` range shows the `--load` value as
the person typed it (assumed). Any other word is an unknown option (assumed). The ranges are these (assumed):

| Option | Lowest | Highest |
|---|---|---|
| `--days` | 1 | 3650 |
| `--seed` | 0 | 4294967295 |
| `--lat` | -90 | 90 |
| `--pv` | 0 | 100 |
| `--battery` | 0 | 200 |
| `--power` | 0 | 100 |
| `--load` | 0.1 | 1000 |
| `--flex` | 0 | the `--load` value |

The range in an `OUT_OF_RANGE` line is `(<lowest> to <highest>)`, written as in this table,
for example `(-90 to 90)` and `(0.1 to 1000)` (assumed).

- Given no arguments, when the person runs `sim`, then the first line on stdout is `usage: sim run [options] | sim compare [options]`. The exit code is 0.
- Given `help`, when the person runs `sim help`, then it prints the same usage and exits with 0.
- Given `--help`, when the person runs `sim --help`, then it prints the same usage and exits with 0.
- Given the command `fly`, when the person runs `sim fly`, then stderr is `error: UNKNOWN_COMMAND: fly`. The exit code is 2.
- Given `--colour red`, when the person runs `sim run`, then stderr is `error: UNKNOWN_OPTION: --colour`. The exit code is 2.
- Given `--days` with no value, when the person runs `sim run`, then stderr is `error: MISSING_VALUE: --days`. The exit code is 2.
- Given `--days abc`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days abc`. The exit code is 2.
- Given `--days ""`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days `. The exit code is 2.
- Given `--days 36.5`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days 36.5`. The exit code is 2.
- Given `--pv 1e3`, `--pv .5`, `--pv 5.` or `--pv 5kW`, when the person runs `sim run`, then each gives `BAD_NUMBER` and exit code 2.
- Given `--pv +3`, when the person runs `sim run`, then it exits with 0, and the result equals the result of `--pv 3`.
- Given `--days 0`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 0 (1 to 3650)`. The exit code is 2.
- Given `--days 3651`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 3651 (1 to 3650)`. The exit code is 2.
- Given `--days 99999999999999999999`, when the person runs `sim run`, then it gives `OUT_OF_RANGE` and exit code 2.
- Given `--seed -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)`. The exit code is 2.
- Given `--seed 4294967295`, when the person runs `sim run`, then it exits with 0. `--seed 4294967296` gives `OUT_OF_RANGE`.
- Given `--lat 90` and `--lat -90`, when the person runs `sim run`, then each exits with 0.
- Given `--lat 90.1` and `--lat -90.1`, when the person runs `sim run`, then each gives `OUT_OF_RANGE` and exit code 2.
- Given `--pv 100` and `--pv 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--pv -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --pv -1 (0 to 100)`. The exit code is 2.
- Given `--battery 200` and `--battery 200.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--power 100` and `--power 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 0.1` and `--load 0`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 1000` and `--load 1000.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 10 --flex 10`, when the person runs `sim run`, then it exits with 0.
- Given `--load 10 --flex 10.5`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --flex 10.5 (0 to 10)`. The exit code is 2.
- Given `--strategy wild`, when the person runs `sim run`, then stderr is `error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)`. The exit code is 2.
- Given the extra word `now`, when the person runs `sim run now`, then stderr is `error: UNKNOWN_OPTION: now`. The exit code is 2.
- Given `--days 10 --days 20`, when the person runs `sim run`, then the `days` line shows 20.
- Given each error above, when the person runs the command, then stdout is empty.

## The interface of each change of the intent

### CH-0001 · Seasonal sun, daily weather and household load

Requirements: CAP-scenario.R1, CAP-scenario.R2, CAP-scenario.R3

````
All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Scenario.lean`. A
check imports `StoragePolicySim.Scenario` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Sky | sunny | cloudy | overcast` with `BEq`, `Repr` and `Inhabited` (assumed).
- `Sky.factor : Sky → Float`: 1.0 for `sunny`, 0.5 for `cloudy`, and 0.15 for `overcast`.
- `structure Site` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `latitude : Float`: degrees, south is negative.
  - `pvKw : Float`: the kW of the panels.
  - `dailyLoadKwh : Float`: the load of a day, with the flexible load included.
  - `flexKwh : Float`: the part of the daily load that a strategy can move.
- `structure Hour` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `day : Nat`: the day of the run, from 0.
  - `dayOfYear : Nat`: `day % 365`, from 0 (1 January) to 364.
  - `hour : Nat`: the hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00.
  - `sky : Sky`: the sky of the day.
  - `pvKwh : Float`: the solar energy of the hour.
  - `baseLoadKwh : Float`: the base load of the hour.
  - `flexKwh : Float`: the flexible load of the hour, at its default hours.
- `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float` gives the solar energy
  of one hour in kWh. It reads only `latitude` and `pvKw` of the site.
- `scenario (site : Site) (seed days : Nat) : Array Hour` gives `24 × days` hours, in order of
  day, then hour. The same arguments give the same array.

### Test seams

- randomness: the `seed` argument of `scenario`. The same seed gives the same skies.
- clock: none, because no line depends on the real date or time.
````

### CH-0002 · Battery and load strategies

Requirements: CAP-strategies.R1, CAP-strategies.R2, CAP-strategies.R3, CAP-strategies.R4, CAP-strategies.R5

````
All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Strategy.lean`. A
check imports `StoragePolicySim.Strategy` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Strategy | none | greedy | evening | shift` with `BEq`, `Repr` and `Inhabited`
  (assumed). Write each value in full, for example `Strategy.none`, so that it does not
  mean `Option.none`.
- `Strategy.all : List Strategy`: `[.none, .greedy, .evening, .shift]`.
- `Strategy.name : Strategy → String`: `"none"`, `"greedy"`, `"evening"` or `"shift"`.
- `Strategy.ofName? (name : String) : Option Strategy`: the strategy whose name matches
  exactly, or `Option.none`.
- `structure Request` with `Repr` (assumed). The fields are `chargeKwh : Float` and
  `dischargeKwh : Float`: the energy that the strategy asks to charge and to discharge.
- `Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request`.
  The hour is 0 to 23, and hour 17 is 17:00 to 18:00. The surplus is the solar energy that
  the house does not use directly. The shortfall is the load that the solar energy does not
  meet. One of the two is 0.
- `Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float`. Each array
  has 24 items, one for each hour of a day. `pvKwh` is the solar energy of each hour, and
  `flexKwh` is the flexible load at its default hours. The result is the flexible load of
  each hour after the strategy places it.

### Test seams

none
````

### CH-0003 · Hourly energy flows and results

Requirements: CAP-simulation.R1, CAP-simulation.R2, CAP-simulation.R3, CAP-simulation.R4, CAP-simulation.R5

````
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

### Test seams

- randomness: the `seed` argument of `simulate`. The same seed gives the same weather.
- clock: none, because no line depends on the real date or time.
````

### CH-0004 · The sim command

Requirements: JOB-simulate.R1, JOB-simulate.R2, JOB-simulate.R3, JOB-simulate.R4, JOB-simulate.R5

````
The command is `.lake/build/bin/sim`, after `lake build`. Its source is `Main.lean`. A check
runs it as a process, as `DES-lean-checks` says. A check can also call the library of
CH-0003 (simulation) to compare values.

- `sim`, `sim help` and `sim --help`: the usage on stdout, exit code 0. The first line is
  `usage: sim run [options] | sim compare [options]`.
- `sim run [options]`: 11 lines on stdout, exit code 0.
  - Each line is a label, spaces to column 19, and a value. Thus, the label and its
    spaces fill 18 characters.
  - The first three lines are `strategy` (the name), `days` and `seed` (whole numbers).
  - Then come `solar`, `load`, `self-used`, `import`, `export` and `losses`. Each value
    has one decimal and ` kWh`.
  - The last two lines are `self-consumption` and `self-sufficiency`. Each value has one
    decimal and ` %`.
  - `solar` is `Totals.pvKwh`, `load` is `Totals.loadKwh`, `self-used` is
    `Totals.selfUsedKwh`, and `losses` is `Totals.lossKwh`. The ratios are
    `Totals.selfConsumption` and `Totals.selfSufficiency`.
  - The values come from `simulate` with `Site.mk lat pv load flex`,
    `Battery.mk battery power`, the strategy, the seed and the days. Each value is rounded
    to one decimal, half away from zero.
- `sim run --monthly [options]`: the 11 lines, a blank line, the header
  `month solar-kWh load-kWh import-kWh export-kWh self-consumption-% self-sufficiency-%`,
  and one row for each item of `Result.months`. Each row has seven fields split by spaces.
  The first field is the month name. The next six are one decimal each of `pvKwh`,
  `loadKwh`, `importKwh`, `exportKwh`, `selfConsumption` and `selfSufficiency`.
- `sim compare [options]`: the header
  `strategy self-consumption-% self-sufficiency-% import-kWh export-kWh` and one row for each
  strategy of `Strategy.all`. Each row has five fields split by spaces: the name, then one
  decimal each of `selfConsumption`, `selfSufficiency`, `importKwh` and `exportKwh`.
- The `--flex` default is 3, or the `--load` value when that is less.
- The options are `--strategy`, `--days`, `--seed`, `--lat`, `--pv`, `--battery`, `--power`,
  `--load` and `--flex`, each with one value, and `--monthly` with no value. The defaults
  and the ranges are in JOB-simulate.R1 (run one strategy) and R5 (bad command line).
- Errors: one line `error: <code>: <detail>` on stderr, nothing on stdout, exit code 2. The
  codes are `UNKNOWN_COMMAND`, `UNKNOWN_OPTION`, `MISSING_VALUE`, `BAD_NUMBER`,
  `OUT_OF_RANGE` and `UNKNOWN_STRATEGY`. The detail of each code is this:
  - `UNKNOWN_COMMAND`: the command word, for example `error: UNKNOWN_COMMAND: fly`.
  - `UNKNOWN_OPTION`: the word, for example `error: UNKNOWN_OPTION: --colour`.
  - `MISSING_VALUE`: the option, for example `error: MISSING_VALUE: --days`.
  - `BAD_NUMBER`: the option, a space, and the value as typed, for example
    `error: BAD_NUMBER: --days abc`.
  - `OUT_OF_RANGE`: the option, the value as typed, and the range in brackets, for example
    `error: OUT_OF_RANGE: --days 0 (1 to 3650)`. Each range is written as in the table of
    JOB-simulate.R5 (bad command line): `(1 to 3650)`, `(0 to 4294967295)`, `(-90 to 90)`,
    `(0 to 100)`, `(0 to 200)`, `(0 to 100)`, `(0.1 to 1000)`. The `--flex` range is `(0 to <the --load
    value as typed>)`.
  - `UNKNOWN_STRATEGY`: the name and the list, for example
    `error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)`.
- The command reads the command line in this order, and the first problem gives the error:
  1. The command word.
  2. Each option and its value, from left to right. A bad number or strategy name stops here.
  3. The range of each option.
  4. The `--flex` value against the `--load` value.

### Test seams

- randomness: the `--seed` option. The same seed gives the same weather. The README names
  this option.
- clock: none, because no line depends on the real date or time.
````

## Specs the changes rely on

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

### CAP-scenario

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the world that a strategy must deal with, one hour at a time. It gives
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

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: ready · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: ready · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

### CAP-simulation

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

## Requirements

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
````

## The acceptance checks

### tests/acceptance/IN-0001.acceptance.lean

````
/-
Acceptance checks of IN-0001 (solar self-consumption simulator).

Stored-data lines: none. No requirement of this intent reads or writes stored data.

The capability lines (CAP-scenario, CAP-strategies, CAP-simulation) use the public
functions of the library. The JOB-simulate lines run the `sim` command as a process.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- Rounds to one decimal, half away from zero. -/
def round1 (x : Float) : Float :=
  if x < 0 then -(Float.round (-x * 10)) / 10 else Float.round (x * 10) / 10

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def digitsVal (cs : List Char) : Nat :=
  cs.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads a printed number: an optional minus, digits, and an optional point with digits. -/
def parseNum (s : String) : Option Float :=
  let p : Bool × List Char := match s.toList with
    | '-' :: r => (true, r)
    | r => (false, r)
  let cs := p.2
  let ip := cs.takeWhile Char.isDigit
  let rest := cs.dropWhile Char.isDigit
  let q : List Char × List Char := match rest with
    | '.' :: r => (r.takeWhile Char.isDigit, r.dropWhile Char.isDigit)
    | r => ([], r)
  if ip.isEmpty || !q.2.isEmpty then none
  else
    let v := Float.ofNat (digitsVal ip) + Float.ofScientific (digitsVal q.1) true q.1.length
    some (if p.1 then -v else v)

-- Helpers for the library

def site (lat : Float) (pv : Float := 5) (flex : Float := 3) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := 20, flexKwh := flex }

def bat (cap power : Float) : Battery := { capacityKwh := cap, powerKw := power }

def dayBase (hs : Array Hour) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc i => acc + hs[d * 24 + i]!.baseLoadKwh) 0

def overcastDays (lat : Float) (inDays : Nat → Bool) : Nat :=
  (List.range 20).foldl (fun acc i =>
    let hs := scenario (site lat) (i + 1) 365
    acc + ((List.range 365).filter (fun d => inDays d && hs[d * 24]!.sky == Sky.overcast)).length) 0

-- Day of the year 0 is 1 January. A year has 365 days.
def inDecToFeb (d : Nat) : Bool := d ≤ 58 || d ≥ 334
def inJunToAug (d : Nat) : Bool := 151 ≤ d && d ≤ 242

def sameHour (a b : Hour) : Bool :=
  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh

def day24 (f : Nat → Float) : Array Float := ((List.range 24).map f).toArray

def sameArr (a b : Array Float) : Bool :=
  a.size == b.size && (List.range a.size).all (fun i => near a[i]! b[i]! 1e-9)

def showArr (a : Array Float) : String := toString a.toList

def defaultFlex : Array Float := day24 (fun h => if h == 18 || h == 19 || h == 20 then 1 else 0)

def middaySun : Array Float :=
  day24 (fun h => if h == 12 then 3.5 else if 8 ≤ h && h ≤ 16 then 1.5 else 0)

def asks (s : Strategy) (hour : Nat) (surplus shortfall charge discharge : Float) :
    Option String :=
  let r := Strategy.decide s hour surplus shortfall
  if near r.chargeKwh charge 1e-9 && near r.dischargeKwh discharge 1e-9 then none
  else some s!"charge {r.chargeKwh}, discharge {r.dischargeKwh}, want {charge} and {discharge}"

def asksDischarge (s : Strategy) (hour : Nat) (shortfall discharge : Float) : Option String :=
  let r := Strategy.decide s hour 0 shortfall
  if near r.dischargeKwh discharge 1e-9 then none
  else some s!"discharge {r.dischargeKwh}, want {discharge}"

def flowIs (f : Flow) (pairs : List (String × Float × Float)) : Option String :=
  match pairs.find? (fun (_, got, want) => !near got want 1e-6) with
  | some (n, got, want) => some s!"{n} is {got}, want {want}"
  | none => none

def sumOf (hs : Array HourResult) (f : HourResult → Float) : Float :=
  hs.foldl (fun acc h => acc + f h) 0

def sameTotals (a b : Totals) : Bool :=
  near a.pvKwh b.pvKwh 1e-6 && near a.loadKwh b.loadKwh 1e-6 &&
  near a.importKwh b.importKwh 1e-6 && near a.exportKwh b.exportKwh 1e-6 &&
  near a.lossKwh b.lossKwh 1e-6 && near a.selfUsedKwh b.selfUsedKwh 1e-6 &&
  near a.finalSocKwh b.finalSocKwh 1e-6 && near a.selfConsumption b.selfConsumption 1e-6 &&
  near a.selfSufficiency b.selfSufficiency 1e-6

def monthNames : List String :=
  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

-- Helpers for the `sim` process

structure RunOut where
  code : UInt32
  out : String
  err : String

def sim (args : List String) : IO RunOut := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

def lines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")

/-- A line of `sim run`: the label, spaces to fill 18 characters, and the value. -/
def row (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

def runLabels : List String :=
  ["strategy", "days", "seed", "solar", "load", "self-used", "import", "export", "losses",
   "self-consumption", "self-sufficiency"]

def monthHeader : List String :=
  ["month", "solar-kWh", "load-kWh", "import-kWh", "export-kWh", "self-consumption-%",
   "self-sufficiency-%"]

def compareHeader : List String :=
  ["strategy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh"]

def usage : String := "usage: sim run [options] | sim compare [options]"

def firstWords (out : String) : List String :=
  (lines out).map (fun l => (words l).head?.getD "")

def valueOf (out label : String) : Option String :=
  match (lines out).find? (fun l => (words l).head? == some label) with
  | some l => (words l)[1]?
  | none => none

def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum

def showsNum (s : Option String) (x : Float) : Bool :=
  match s.bind parseNum with
  | some v => near v (round1 x) 0.001
  | none => false

def checkShows (out : String) (pairs : List (String × Float)) : Option String :=
  match pairs.find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

def totalsPairs (t : Totals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("self-used", t.selfUsedKwh),
   ("import", t.importKwh), ("export", t.exportKwh), ("losses", t.lossKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

def rowShows (r : String) (m : Month) : Bool :=
  let w := words r
  w.length == 7 && w[0]? == some m.name &&
  showsNum w[1]? m.totals.pvKwh && showsNum w[2]? m.totals.loadKwh &&
  showsNum w[3]? m.totals.importKwh && showsNum w[4]? m.totals.exportKwh &&
  showsNum w[5]? m.totals.selfConsumption && showsNum w[6]? m.totals.selfSufficiency

def oneDecimal (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
  | _ => false

/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
def labelled (l label : String) : Bool :=
  let cs := l.toList
  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '

/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
def expectError (args : List String) (line : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]

/-- Expects exit code 2, empty stdout, and stderr that starts with `pre`. -/
def expectStart (args : List String) (pre : String) (oneLine : Bool := true) :
    IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (r.err.startsWith pre && (!oneLine || (lines r.err).length == 1),
      s!"sim {args}: stderr is {repr r.err}, want one line that starts with {repr pre}")]

/-- Expects exit code 0 and the 11 lines of `sim run`. -/
def expectRun (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (firstWords r.out == runLabels, s!"sim {args}: stdout is {repr r.out}")]

def errorCases : List (List String) := [
  ["fly"], ["Run"], ["run", "--colour", "red"], ["run", "--days"], ["run", "--strategy"],
  ["run", "--days", "abc"], ["run", "--days", ""], ["run", "--days", "36.5"],
  ["run", "--days", "2.0"], ["run", "--days", " 2"], ["run", "--days", "2\n"],
  ["run", "--pv", "1e3"], ["run", "--pv", ".5"], ["run", "--pv", "5."], ["run", "--pv", "5kW"],
  ["run", "--days", "0"], ["run", "--days", "3651"], ["run", "--days", "99999999999999999999"],
  ["run", "--seed", "-1"], ["run", "--seed", "4294967296"],
  ["run", "--lat", "90.1"], ["run", "--lat", "-90.1"],
  ["run", "--pv", "100.1"], ["run", "--pv", "-1"], ["run", "--battery", "200.1"],
  ["run", "--power", "100.1"], ["run", "--load", "0"], ["run", "--load", "1000.1"],
  ["run", "--load", "10", "--flex", "10.5"], ["run", "--strategy", "wild"],
  ["run", "--strategy", "Greedy"], ["run", "now"],
  ["compare", "--strategy", "greedy"], ["compare", "--monthly"]]

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354",
    run := do
      let a := pvOutput (site 45) 171 12 Sky.sunny
      let b := pvOutput (site 45) 354 12 Sky.sunny
      return if a > 2 * b && b > 0 then none else some s!"day 171 {a}, day 354 {b}" },
  { name := "CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171",
    run := do
      let a := pvOutput (site (-41)) 354 12 Sky.sunny
      let b := pvOutput (site (-41)) 171 12 Sky.sunny
      return if a > 2 * b && b > 0 then none else some s!"day 354 {a}, day 171 {b}" },
  { name := "CAP-scenario.R1 at latitude 0 days 171 and 354 differ by less than 1%",
    run := do
      let a := pvOutput (site 0) 171 12 Sky.sunny
      let b := pvOutput (site 0) 354 12 Sky.sunny
      let big := if a > b then a else b
      return if a > 0 && b > 0 && (a - b).abs < 0.01 * big then none
        else some s!"day 171 {a}, day 354 {b}" },
  { name := "CAP-scenario.R1 at latitude 45 midnight of day 171 gives 0 kWh",
    run := do
      let v := pvOutput (site 45) 171 0 Sky.sunny
      return if v == 0 then none else some s!"got {v}" },
  { name := "CAP-scenario.R1 each sunny hour of a year at latitude 45 gives 0 to 5 kWh",
    run := do
      let bad := (List.range (365 * 24)).find? (fun i =>
        let v := pvOutput (site 45) (i / 24) (i % 24) Sky.sunny
        !(v ≥ 0 && v ≤ 5))
      let noon := pvOutput (site 45) 171 12 Sky.sunny
      return match bad with
        | some i => some s!"day {i / 24} hour {i % 24} gives {pvOutput (site 45) (i / 24) (i % 24) Sky.sunny}"
        | none => if noon > 0 then none else some s!"noon of day 171 gives {noon}" },
  { name := "CAP-scenario.R1 a cloudy sky gives 0.5 times the sunny output",
    run := do
      let s := pvOutput (site 45) 171 12 Sky.sunny
      let c := pvOutput (site 45) 171 12 Sky.cloudy
      return if s > 1 && near c (0.5 * s) 0.001 then none else some s!"sunny {s}, cloudy {c}" },
  { name := "CAP-scenario.R1 an overcast sky gives 0.15 times the sunny output",
    run := do
      let s := pvOutput (site 45) 171 12 Sky.sunny
      let o := pvOutput (site 45) 171 12 Sky.overcast
      return if s > 1 && near o (0.15 * s) 0.001 then none else some s!"sunny {s}, overcast {o}" },
  { name := "CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15",
    run := do
      return firstFail [
        (Sky.factor Sky.sunny == 1.0, s!"sunny {Sky.factor Sky.sunny}"),
        (Sky.factor Sky.cloudy == 0.5, s!"cloudy {Sky.factor Sky.cloudy}"),
        (Sky.factor Sky.overcast == 0.15, s!"overcast {Sky.factor Sky.overcast}")] },
  { name := "CAP-scenario.R1 0 kW of panels gives 0 kWh at noon",
    run := do
      let v := pvOutput (site 45 (pv := 0)) 171 12 Sky.sunny
      return if v == 0 then none else some s!"got {v}" },

  -- CAP-scenario.R2
  { name := "CAP-scenario.R2 seed 7 gives the same hours two times",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 7 365
      return if a.size == 8760 && b.size == 8760 &&
          (List.range 8760).all (fun i => sameHour a[i]! b[i]!) then none
        else some "the two runs differ" },
  { name := "CAP-scenario.R2 seeds 7 and 8 give different skies on at least 50 days",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 8 365
      let n := ((List.range 365).filter (fun d => !(a[d * 24]!.sky == b[d * 24]!.sky))).length
      return if n ≥ 50 then none else some s!"{n} days differ" },
  { name := "CAP-scenario.R2 365 days give 8760 hours in order of day, then hour",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i =>
            !(hs[i]!.day == i / 24 && hs[i]!.hour == i % 24)) with
          | some i => some s!"item {i} is day {hs[i]!.day} hour {hs[i]!.hour}"
          | none => none },
  { name := "CAP-scenario.R2 0 days give no hours",
    run := do
      let hs := scenario (site 45) 7 0
      return if hs.size == 0 then none else some s!"{hs.size} hours" },
  { name := "CAP-scenario.R2 the 24 hours of each day have the same sky",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size == 8760 &&
          (List.range 8760).all (fun i => hs[i]!.sky == hs[(i / 24) * 24]!.sky) then none
        else some "a day has two skies" },
  { name := "CAP-scenario.R2 each solar output equals the seasonal sun of its hour",
    run := do
      let hs := scenario (site 45) 7 365
      let bad := (List.range hs.size).find? (fun i =>
        let h := hs[i]!
        !near h.pvKwh (pvOutput (site 45) h.dayOfYear h.hour h.sky) 0.000001)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R2 at latitude 45 winter has over twice the overcast days of summer",
    run := do
      let w := overcastDays 45 inDecToFeb
      let s := overcastDays 45 inJunToAug
      return if w > 2 * s then none else some s!"Dec to Feb {w}, Jun to Aug {s}" },
  { name := "CAP-scenario.R2 at latitude -41 June to August has over twice the overcast days",
    run := do
      let w := overcastDays (-41) inJunToAug
      let s := overcastDays (-41) inDecToFeb
      return if w > 2 * s then none else some s!"Jun to Aug {w}, Dec to Feb {s}" },
  { name := "CAP-scenario.R2 60% or more of days 1 to 364 keep the previous sky",
    run := do
      let hs := scenario (site 45) 7 365
      let n := ((List.range 364).filter (fun d =>
        hs[(d + 1) * 24]!.sky == hs[d * 24]!.sky)).length
      return if hs.size == 8760 && n.toFloat ≥ 0.6 * 364 then none else some s!"{n} days keep" },
  { name := "CAP-scenario.R2 after day 364 the day of the year starts again at 0",
    run := do
      let hs := scenario (site 45) 7 730
      return firstFail [
        (hs.size == 730 * 24, s!"{hs.size} hours"),
        (hs[365 * 24]!.day == 365 && hs[365 * 24]!.dayOfYear == 0,
          s!"day 365 is day {hs[365 * 24]!.dayOfYear} of the year"),
        (hs[729 * 24]!.day == 729 && hs[729 * 24]!.dayOfYear == 364,
          s!"day 729 is day {hs[729 * 24]!.dayOfYear} of the year")] },

  -- CAP-scenario.R3
  { name := "CAP-scenario.R3 365 days at latitude 45 have 7300 kWh of load",
    run := do
      let hs := scenario (site 45) 7 365
      let t := hs.foldl (fun acc h => acc + h.baseLoadKwh + h.flexKwh) 0
      return if near t 7300 0.1 then none else some s!"total {t}" },
  { name := "CAP-scenario.R3 at latitude 45 day 15 has 1.45 to 1.55 times the base load of day 197",
    run := do
      let hs := scenario (site 45) 7 365
      let q := dayBase hs 15 / dayBase hs 197
      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
  { name := "CAP-scenario.R3 at latitude -41 day 197 has 1.45 to 1.55 times the base load of day 15",
    run := do
      let hs := scenario (site (-41)) 7 365
      let q := dayBase hs 197 / dayBase hs 15
      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
  { name := "CAP-scenario.R3 on day 100 the base load at 19:00 is more than at 13:00",
    run := do
      let hs := scenario (site 45) 7 365
      let a := hs[100 * 24 + 19]!.baseLoadKwh
      let b := hs[100 * 24 + 13]!.baseLoadKwh
      return if a > b then none else some s!"19:00 {a}, 13:00 {b}" },
  { name := "CAP-scenario.R3 on day 100 the base load at 07:00 is more than at 03:00",
    run := do
      let hs := scenario (site 45) 7 365
      let a := hs[100 * 24 + 7]!.baseLoadKwh
      let b := hs[100 * 24 + 3]!.baseLoadKwh
      return if a > b then none else some s!"07:00 {a}, 03:00 {b}" },
  { name := "CAP-scenario.R3 3 kWh of flexible load is 1 kWh at 18:00, 19:00 and 20:00",
    run := do
      let hs := scenario (site 45) 7 365
      let bad := (List.range hs.size).find? (fun i =>
        let want : Float := if i % 24 == 18 || i % 24 == 19 || i % 24 == 20 then 1 else 0
        !near hs[i]!.flexKwh want 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R3 0 kWh of flexible load gives 0 kWh in each hour",
    run := do
      let hs := scenario (site 45 (flex := 0)) 7 365
      return if hs.size == 8760 && hs.all (fun h => h.flexKwh == 0) then none
        else some "an hour has flexible load" },
  { name := "CAP-scenario.R3 seeds 7 and 8 give the same base and flexible load",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 8 365
      return if a.size == 8760 && b.size == 8760 && (List.range 8760).all (fun i =>
          a[i]!.baseLoadKwh == b[i]!.baseLoadKwh && a[i]!.flexKwh == b[i]!.flexKwh) then none
        else some "the loads differ" },

  -- CAP-strategies.R1
  { name := "CAP-strategies.R1 the names are none, greedy, evening and shift in this order",
    run := do
      return firstFail [
        (Strategy.all.map Strategy.name == ["none", "greedy", "evening", "shift"],
          s!"names {Strategy.all.map Strategy.name}"),
        (Strategy.all == [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift],
          "the list has the wrong strategies")] },
  { name := "CAP-strategies.R1 the name greedy finds the greedy strategy",
    run := do
      return firstFail [
        (Strategy.ofName? "greedy" == some Strategy.greedy, "greedy is not found"),
        (Strategy.all.all (fun s => Strategy.ofName? s.name == some s),
          "a name does not find its strategy")] },
  { name := "CAP-strategies.R1 the name Greedy finds no strategy",
    run := do
      return if (Strategy.ofName? "Greedy").isNone then none else some "Greedy is found" },
  { name := "CAP-strategies.R1 a name that differs by a space or a case finds no strategy",
    run := do
      let close := ["GREEDY", " greedy", "greedy ", "greedy\n", "Shift", "nonE"]
      return match close.find? (fun n => (Strategy.ofName? n).isSome) with
        | some n => some s!"{repr n} is found"
        | none => none },
  { name := "CAP-strategies.R1 the empty name finds no strategy",
    run := do
      return if (Strategy.ofName? "").isNone then none else some "the empty name is found" },

  -- CAP-strategies.R2
  { name := "CAP-strategies.R2 none asks for nothing with a surplus of 2 kWh at 12:00",
    run := do return asks Strategy.none 12 2 0 0 0 },
  { name := "CAP-strategies.R2 none asks for nothing with a shortfall of 1.5 kWh at 19:00",
    run := do return asks Strategy.none 19 0 1.5 0 0 },
  { name := "CAP-strategies.R2 none keeps the flexible load",
    run := do
      let r := Strategy.placeFlex Strategy.none middaySun defaultFlex
      return if sameArr r defaultFlex then none else some s!"got {showArr r}" },

  -- CAP-strategies.R3
  { name := "CAP-strategies.R3 greedy charges 2 kWh with a surplus of 2 kWh at 12:00",
    run := do return asks Strategy.greedy 12 2 0 2 0 },
  { name := "CAP-strategies.R3 greedy discharges 1.5 kWh with a shortfall at 03:00",
    run := do return asks Strategy.greedy 3 0 1.5 0 1.5 },
  { name := "CAP-strategies.R3 greedy discharges 1.5 kWh with a shortfall at 13:00",
    run := do return asks Strategy.greedy 13 0 1.5 0 1.5 },
  { name := "CAP-strategies.R3 greedy asks for nothing with no surplus and no shortfall",
    run := do return asks Strategy.greedy 12 0 0 0 0 },
  { name := "CAP-strategies.R3 greedy keeps the flexible load",
    run := do
      let r := Strategy.placeFlex Strategy.greedy middaySun defaultFlex
      return if sameArr r defaultFlex then none else some s!"got {showArr r}" },

  -- CAP-strategies.R4
  { name := "CAP-strategies.R4 evening charges 2 kWh with a surplus of 2 kWh at 12:00",
    run := do return asks Strategy.evening 12 2 0 2 0 },
  { name := "CAP-strategies.R4 evening does not discharge at 16:00",
    run := do return asksDischarge Strategy.evening 16 1.5 0 },
  { name := "CAP-strategies.R4 evening discharges 1.5 kWh at 17:00",
    run := do return asksDischarge Strategy.evening 17 1.5 1.5 },
  { name := "CAP-strategies.R4 evening discharges 1.5 kWh at 23:00",
    run := do return asksDischarge Strategy.evening 23 1.5 1.5 },
  { name := "CAP-strategies.R4 evening does not discharge at 00:00",
    run := do return asksDischarge Strategy.evening 0 1.5 0 },
  { name := "CAP-strategies.R4 evening keeps the flexible load",
    run := do
      let r := Strategy.placeFlex Strategy.evening middaySun defaultFlex
      return if sameArr r defaultFlex then none else some s!"got {showArr r}" },

  -- CAP-strategies.R5
  { name := "CAP-strategies.R5 shift charges 2 kWh with a surplus of 2 kWh at 12:00",
    run := do return asks Strategy.shift 12 2 0 2 0 },
  { name := "CAP-strategies.R5 shift discharges 1.5 kWh with a shortfall at 03:00",
    run := do return asksDischarge Strategy.shift 3 1.5 1.5 },
  { name := "CAP-strategies.R5 shift puts 1 kWh in each of the three sunniest hours",
    run := do
      let pv := day24 (fun h =>
        if h == 13 then 4.0 else if h == 11 then 3.5 else if h == 12 then 3.0
        else if h == 10 then 2.9 else if h == 14 then 2.0 else if h == 9 || h == 15 then 1.0
        else 0)
      let want := day24 (fun h => if h == 11 || h == 12 || h == 13 then 1 else 0)
      let r := Strategy.placeFlex Strategy.shift pv defaultFlex
      return if sameArr r want then none else some s!"got {showArr r}" },
  { name := "CAP-strategies.R5 shift gives a tie to the earlier hour",
    run := do
      let pv := day24 (fun h => if 10 ≤ h && h ≤ 14 then 2.0 else 0)
      let want := day24 (fun h => if h == 10 || h == 11 || h == 12 then 1 else 0)
      let r := Strategy.placeFlex Strategy.shift pv defaultFlex
      return if sameArr r want then none else some s!"got {showArr r}" },
  { name := "CAP-strategies.R5 shift keeps the default hours on a day with no sun",
    run := do
      let r := Strategy.placeFlex Strategy.shift (day24 (fun _ => 0)) defaultFlex
      return if sameArr r defaultFlex then none else some s!"got {showArr r}" },
  { name := "CAP-strategies.R5 shift places 0 kWh of flexible load as 0 kWh in each hour",
    run := do
      let pv := day24 (fun h => if h == 12 then 3.0 else 0)
      let zero := day24 (fun _ => 0)
      let r := Strategy.placeFlex Strategy.shift pv zero
      return if sameArr r zero then none else some s!"got {showArr r}" },

  -- CAP-simulation.R1
  { name := "CAP-simulation.R1 an empty battery takes 2 kWh and then holds 1.9 kWh",
    run := do
      let f := stepHour (bat 10 5) 0 Strategy.greedy 12 3 1
      return flowIs f [("direct", f.directKwh, 1), ("charge", f.chargeKwh, 2),
        ("export", f.exportKwh, 0), ("import", f.importKwh, 0), ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R1 a full battery takes nothing and 2 kWh is export",
    run := do
      let f := stepHour (bat 10 5) 10 Strategy.greedy 12 3 1
      return flowIs f [("direct", f.directKwh, 1), ("charge", f.chargeKwh, 0),
        ("export", f.exportKwh, 2), ("soc", f.socKwh, 10)] },
  { name := "CAP-simulation.R1 9.05 kWh stored takes 1 kWh and then holds 10 kWh",
    run := do
      let f := stepHour (bat 10 5) 9.05 Strategy.greedy 12 3 1
      return flowIs f [("charge", f.chargeKwh, 1), ("export", f.exportKwh, 1),
        ("soc", f.socKwh, 10)] },
  { name := "CAP-simulation.R1 a battery with 2 kW of power takes 2 kWh of a 3 kWh surplus",
    run := do
      let f := stepHour (bat 10 2) 0 Strategy.greedy 12 4 1
      return flowIs f [("charge", f.chargeKwh, 2), ("export", f.exportKwh, 1),
        ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R1 1.9 kWh stored gives 1.805 kWh for a shortfall of 2 kWh",
    run := do
      let f := stepHour (bat 10 5) 1.9 Strategy.greedy 20 0 2
      return flowIs f [("discharge", f.dischargeKwh, 1.805), ("import", f.importKwh, 0.195),
        ("soc", f.socKwh, 0)] },
  { name := "CAP-simulation.R1 none exports the surplus and keeps 1.9 kWh stored",
    run := do
      let f := stepHour (bat 10 5) 1.9 Strategy.none 12 3 1
      return flowIs f [("charge", f.chargeKwh, 0), ("export", f.exportKwh, 2),
        ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R1 the first hour of greedy with seed 7 imports its full load",
    run := do
      let res := simulate (site 45) (bat 10 5) Strategy.greedy 7 365
      let h := res.hours[0]!
      return if res.hours.size == 8760 && h.loadKwh > 0 && near h.flow.importKwh h.loadKwh 1e-9
        then none else some s!"load {h.loadKwh}, import {h.flow.importKwh}" },

  -- CAP-simulation.R2
  { name := "CAP-simulation.R2 a battery with 2 kW of power charges and discharges 2 kWh or less",
    run := do
      let res := simulate (site 45) (bat 5 2) Strategy.greedy 7 365
      let bad := res.hours.toList.find? (fun h =>
        h.flow.chargeKwh > 2 + 1e-9 || h.flow.dischargeKwh > 2 + 1e-9)
      -- The discharge cap must bind in at least one hour. Else a version with no cap on the
      -- discharge also passes.
      let capped := res.hours.any (fun h => near h.flow.dischargeKwh 2 1e-6)
      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour}: charge {h.flow.chargeKwh}, discharge {h.flow.dischargeKwh}"
          | none => if capped then none else some "no hour discharges 2 kWh" },
  { name := "CAP-simulation.R2 a 5 kWh battery holds 0 to 5 kWh each hour",
    run := do
      let res := simulate (site 45) (bat 5 2) Strategy.greedy 7 365
      let bad := res.hours.toList.find? (fun h =>
        h.flow.socKwh < -1e-9 || h.flow.socKwh > 5 + 1e-9)
      return if res.hours.size != 8760 then some s!"{res.hours.size} hours"
        else match bad with
          | some h => some s!"day {h.hour.day} hour {h.hour.hour} holds {h.flow.socKwh}"
          | none => none },
  { name := "CAP-simulation.R2 the energy of a run balances",
    run := do
      let t := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).totals
      let lhs := t.pvKwh + t.importKwh
      let rhs := t.loadKwh + t.exportKwh + t.lossKwh + t.finalSocKwh
      return if t.pvKwh > 0 && t.lossKwh > 0 && near lhs rhs 0.01 then none
        else some s!"solar and import {lhs}, the rest {rhs}, losses {t.lossKwh}" },
  { name := "CAP-simulation.R2 a battery of 0 kWh gives the same totals for greedy and none",
    run := do
      let a := (simulate (site 45) (bat 0 5) Strategy.greedy 7 365).totals
      let b := (simulate (site 45) (bat 0 5) Strategy.none 7 365).totals
      return if sameTotals a b then none else some s!"greedy {repr a}, none {repr b}" },

  -- CAP-simulation.R3
  { name := "CAP-simulation.R3 each total of none equals the sum of its hours",
    run := do
      let res := simulate (site 45) (bat 10 5) Strategy.none 7 365
      let hs := res.hours
      let t := res.totals
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (near t.pvKwh (sumOf hs (·.hour.pvKwh)) 0.01, s!"solar {t.pvKwh}"),
        (near t.loadKwh (sumOf hs (·.loadKwh)) 0.01, s!"load {t.loadKwh}"),
        (near t.importKwh (sumOf hs (·.flow.importKwh)) 0.01, s!"import {t.importKwh}"),
        (near t.exportKwh (sumOf hs (·.flow.exportKwh)) 0.01, s!"export {t.exportKwh}"),
        (near t.lossKwh (sumOf hs (·.flow.lossKwh)) 0.01, s!"losses {t.lossKwh}")] },
  { name := "CAP-simulation.R3 each total of greedy equals the sum of its hours",
    run := do
      let res := simulate (site 45) (bat 10 5) Strategy.greedy 7 365
      let hs := res.hours
      let t := res.totals
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (near t.pvKwh (sumOf hs (·.hour.pvKwh)) 0.01, s!"solar {t.pvKwh}"),
        (near t.loadKwh (sumOf hs (·.loadKwh)) 0.01, s!"load {t.loadKwh}"),
        (near t.importKwh (sumOf hs (·.flow.importKwh)) 0.01, s!"import {t.importKwh}"),
        (near t.exportKwh (sumOf hs (·.flow.exportKwh)) 0.01, s!"export {t.exportKwh}"),
        (near t.lossKwh (sumOf hs (·.flow.lossKwh)) 0.01, s!"losses {t.lossKwh}"),
        (near t.selfUsedKwh (t.pvKwh - t.exportKwh) 0.01, s!"self-used {t.selfUsedKwh}"),
        (near t.finalSocKwh hs[hs.size - 1]!.flow.socKwh 1e-9, s!"final {t.finalSocKwh}")] },
  { name := "CAP-simulation.R3 the self-consumption is 100 × (solar - export) / solar",
    run := do
      let t := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).totals
      let want := 100 * (t.pvKwh - t.exportKwh) / t.pvKwh
      return if t.pvKwh > 0 && near t.selfConsumption want 1e-6 then none
        else some s!"got {t.selfConsumption}, want {want}" },
  { name := "CAP-simulation.R3 the self-sufficiency is 100 × (load - import) / load",
    run := do
      let t := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).totals
      let want := 100 * (t.loadKwh - t.importKwh) / t.loadKwh
      return if t.loadKwh > 0 && near t.selfSufficiency want 1e-6 then none
        else some s!"got {t.selfSufficiency}, want {want}" },
  { name := "CAP-simulation.R3 0 kW of panels gives 0% for each ratio",
    run := do
      let t := (simulate (site 45 (pv := 0)) (bat 10 5) Strategy.greedy 7 365).totals
      return if near t.selfConsumption 0 1e-9 && near t.selfSufficiency 0 1e-9 then none
        else some s!"self-consumption {t.selfConsumption}, self-sufficiency {t.selfSufficiency}" },
  { name := "CAP-simulation.R3 0 days give zero totals and no months",
    run := do
      let res := simulate (site 45) (bat 10 5) Strategy.greedy 7 0
      let t := res.totals
      let zero := [t.pvKwh, t.loadKwh, t.importKwh, t.exportKwh, t.lossKwh, t.selfUsedKwh,
        t.finalSocKwh, t.selfConsumption, t.selfSufficiency]
      return firstFail [
        (zero.all (fun v => v == 0), s!"totals {repr t}"),
        (res.months.size == 0, s!"{res.months.size} months"),
        (res.hours.size == 0, s!"{res.hours.size} hours")] },

  -- CAP-simulation.R4
  { name := "CAP-simulation.R4 365 days give 12 months with their days",
    run := do
      let ms := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).months
      return firstFail [
        (ms.toList.map (·.days) == [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
          s!"days {ms.toList.map (·.days)}"),
        (ms.toList.map (·.name) == monthNames, s!"names {ms.toList.map (·.name)}")] },
  { name := "CAP-simulation.R4 the solar of the 12 months adds up to the solar of the run",
    run := do
      let res := simulate (site 45) (bat 10 5) Strategy.greedy 7 365
      let s := res.months.foldl (fun acc m => acc + m.totals.pvKwh) 0
      return if res.months.size == 12 && near s res.totals.pvKwh 0.01 then none
        else some s!"months {s}, run {res.totals.pvKwh}" },
  { name := "CAP-simulation.R4 400 days give 14 months and the last is February with 4 days",
    run := do
      let ms := (simulate (site 45) (bat 10 5) Strategy.greedy 7 400).months
      let last := ms[ms.size - 1]!
      return if ms.size == 14 && last.name == "Feb" && last.days == 4 &&
          ms[12]!.name == "Jan" && ms[12]!.days == 31 then none
        else some s!"{ms.size} months, last {last.name} with {last.days} days" },
  { name := "CAP-simulation.R4 10 days give one month, January with 10 days",
    run := do
      let ms := (simulate (site 45) (bat 10 5) Strategy.greedy 7 10).months
      return if ms.size == 1 && ms[0]!.name == "Jan" && ms[0]!.days == 10 then none
        else some s!"{ms.size} months" },
  { name := "CAP-simulation.R4 July has more than twice the solar of December",
    run := do
      let ms := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).months
      return if ms.size == 12 && ms[6]!.totals.pvKwh > 2 * ms[11]!.totals.pvKwh then none
        else some s!"July {ms[6]!.totals.pvKwh}, December {ms[11]!.totals.pvKwh}" },
  { name := "CAP-simulation.R4 the July self-sufficiency is more than the January self-sufficiency",
    run := do
      let ms := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).months
      return if ms.size == 12 && ms[6]!.totals.selfSufficiency > ms[0]!.totals.selfSufficiency
        then none
        else some s!"July {ms[6]!.totals.selfSufficiency}, January {ms[0]!.totals.selfSufficiency}" },

  -- CAP-simulation.R5
  { name := "CAP-simulation.R5 greedy has a higher self-consumption than none",
    run := do
      let g := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).totals.selfConsumption
      let n := (simulate (site 45) (bat 10 5) Strategy.none 7 365).totals.selfConsumption
      return if g > n then none else some s!"greedy {g}, none {n}" },
  { name := "CAP-simulation.R5 evening has a self-consumption no higher than greedy",
    run := do
      let g := (simulate (site 45) (bat 10 5) Strategy.greedy 7 365).totals.selfConsumption
      let e := (simulate (site 45) (bat 10 5) Strategy.evening 7 365).totals.selfConsumption
      return if e ≤ g + 1e-9 then none else some s!"evening {e}, greedy {g}" },
  { name := "CAP-simulation.R5 with a battery of 0 kWh shift has a higher self-consumption than none",
    run := do
      let s := (simulate (site 45) (bat 0 5) Strategy.shift 7 365).totals.selfConsumption
      let n := (simulate (site 45) (bat 0 5) Strategy.none 7 365).totals.selfConsumption
      return if s > n then none else some s!"shift {s}, none {n}" },

  -- JOB-simulate.R1
  { name := "JOB-simulate.R1 sim run prints the 11 lines in order and exits with 0",
    run := do
      let r ← sim ["run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (firstWords r.out == runLabels, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R1 each line has its label to column 19 and a value with one decimal",
    run := do
      let r ← sim ["run"]
      let ls := lines r.out
      let bad := (List.range 11).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (runLabels.getD i "") &&
          (if i < 3 then w.length == 2
           else if i < 9 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
      return if r.code != 0 || ls.length != 11 then some s!"stdout is {repr r.out}"
        else match bad with
          | some i => some s!"the line {ls[i]?} has the wrong form"
          | none => none },
  { name := "JOB-simulate.R1 the first three lines show greedy, 365 days and seed 1",
    run := do
      let r ← sim ["run"]
      let want := [row "strategy" "greedy", row "days" "365", row "seed" "1"]
      return if r.code == 0 && (lines r.out).take 3 == want then none
        else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --pv 0 shows 0.0 kWh of solar and 0.0 % self-consumption",
    run := do
      let r ← sim ["run", "--pv", "0"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls[3]? == some (row "solar" "0.0 kWh"), s!"stdout is {repr r.out}"),
        (ls[9]? == some (row "self-consumption" "0.0 %"), s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R1 --strategy shift --days 30 --lat 45 shows the values of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "shift", "--days", "30", "--lat", "45"]
      let t := (simulate (site 45) (bat 10 5) Strategy.shift 1 30).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "shift", row "days" "30", row "seed" "1"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out (totalsPairs t) },
  { name := "JOB-simulate.R1 the default site and battery give the values of the simulation",
    run := do
      let r ← sim ["run"]
      let t := (simulate (site (-41.3)) (bat 10 5) Strategy.greedy 1 365).totals
      return (if r.code == 0 then none else some s!"exit code {r.code}") <|>
        checkShows r.out (totalsPairs t) },
  { name := "JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used",
    run := do
      let r ← sim ["run", "--strategy", "none", "--battery", "0"]
      return match numOf r.out "solar", numOf r.out "self-used", numOf r.out "export" with
        | some s, some u, some e =>
          if r.code == 0 && s > 0 && near e (s - u) 0.1 then none
          else some s!"solar {s}, self-used {u}, export {e}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --days 3650 exits with 0 and shows 3650 days",
    run := do
      let r ← sim ["run", "--days", "3650"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "3650") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },

  -- JOB-simulate.R2
  { name := "JOB-simulate.R2 --monthly prints the header and 12 rows from Jan to Dec",
    run := do
      let r ← sim ["run", "--monthly"]
      let ls := lines r.out
      let rows := ls.drop 13
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 25, s!"{ls.length} lines, want 25"),
        (firstWords (String.intercalate "\n" (ls.take 11)) == runLabels, "the 11 lines are wrong"),
        (ls[11]? == some "", "line 12 is not blank"),
        (Option.map words ls[12]? == some monthHeader, s!"the header is {ls[12]?}"),
        (rows.map (fun l => (words l).head?.getD "") == monthNames, s!"rows {rows}"),
        (rows.all (fun l => (words l).length == 7), "a row does not have seven fields")] },
  { name := "JOB-simulate.R2 each row shows the totals of its month",
    run := do
      let r ← sim ["run", "--monthly"]
      let ms := (simulate (site (-41.3)) (bat 10 5) Strategy.greedy 1 365).months
      let rows := (lines r.out).drop 13
      return if r.code == 0 && rows.length == ms.size &&
          (rows.zip ms.toList).all (fun (l, m) => rowShows l m) then none
        else some s!"rows {rows}" },
  { name := "JOB-simulate.R2 --monthly --days 400 prints 14 rows that end with Jan and Feb",
    run := do
      let r ← sim ["run", "--monthly", "--days", "400"]
      let rows := (lines r.out).drop 13
      let names := rows.map (fun l => (words l).head?.getD "")
      return if r.code == 0 && rows.length == 14 && names.drop 12 == ["Jan", "Feb"] then none
        else some s!"rows {names}" },
  { name := "JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45"]
      let rows := (lines r.out).drop 13
      let solar := fun (n : String) =>
        (rows.find? (fun l => (words l).head? == some n)).bind (fun l => (words l)[1]?.bind parseNum)
      return match solar "Jul", solar "Dec" with
        | some j, some d => if r.code == 0 && j > 2 * d then none else some s!"Jul {j}, Dec {d}"
        | _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 without --monthly sim run prints only the 11 lines",
    run := do
      let r ← sim ["run"]
      return if r.code == 0 && (lines r.out).length == 11 && firstWords r.out == runLabels
        then none else some s!"stdout is {repr r.out}" },

  -- JOB-simulate.R3
  { name := "JOB-simulate.R3 sim compare prints the header and none, greedy, evening and shift",
    run := do
      let r ← sim ["compare"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 5, s!"{ls.length} lines, want 5"),
        (Option.map words ls[0]? == some compareHeader, s!"the header is {ls[0]?}"),
        (firstWords r.out == ["strategy", "none", "greedy", "evening", "shift"],
          s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 5), "a row does not have five fields")] },
  { name := "JOB-simulate.R3 the greedy row shows the four values of sim run",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45"]
      let r ← sim ["run", "--seed", "9", "--lat", "45"]
      let g := ((lines c.out).find? (fun l => (words l).head? == some "greedy")).map words
      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
        valueOf r.out "import", valueOf r.out "export"]
      return match g with
        | some w =>
          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?] then none
          else some s!"compare {w}, run {fromRun}"
        | none => some s!"no greedy row in {repr c.out}" },
  { name := "JOB-simulate.R3 the compare rows show the values of the simulation",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45"]
      let rowOk := fun (s : Strategy) =>
        let t := (simulate (site 45) (bat 10 5) s 9 365).totals
        match (lines c.out).find? (fun l => (words l).head? == some s.name) with
        | some l =>
          let w := words l
          showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
          showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh
        | none => false
      return match Strategy.all.find? (fun s => !rowOk s) with
        | some s => some s!"the {s.name} row is wrong in {repr c.out}"
        | none => none },
  { name := "JOB-simulate.R3 --lat 45 gives greedy a higher self-consumption than none",
    run := do
      let c ← sim ["compare", "--lat", "45"]
      let sc := fun (n : String) =>
        ((lines c.out).find? (fun l => (words l).head? == some n)).bind
          (fun l => (words l)[1]?.bind parseNum)
      return match sc "greedy", sc "none" with
        | some g, some n => if c.code == 0 && g > n then none else some s!"greedy {g}, none {n}"
        | _, _ => some s!"stdout is {repr c.out}" },
  { name := "JOB-simulate.R3 sim compare --strategy greedy gives UNKNOWN_OPTION",
    run := expectError ["compare", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
  { name := "JOB-simulate.R3 sim compare --monthly gives UNKNOWN_OPTION",
    run := expectError ["compare", "--monthly"] "error: UNKNOWN_OPTION: --monthly" },

  -- JOB-simulate.R4
  { name := "JOB-simulate.R4 --seed 5 gives the same output two times",
    run := do
      let a ← sim ["run", "--seed", "5"]
      let b ← sim ["run", "--seed", "5"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R4 --seed 1 and --seed 2 give different solar values",
    run := do
      let a ← sim ["run", "--seed", "1"]
      let b ← sim ["run", "--seed", "2"]
      let sa := valueOf a.out "solar"
      let sb := valueOf b.out "solar"
      return if a.code == 0 && b.code == 0 && sa.isSome && sa != sb then none
        else some s!"seed 1 {sa}, seed 2 {sb}" },

  -- JOB-simulate.R5
  { name := "JOB-simulate.R5 sim with no arguments prints the usage and exits with 0",
    run := do
      let r ← sim []
      return if r.code == 0 && (lines r.out).head? == some usage then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim help prints the same usage and exits with 0",
    run := do
      let a ← sim []
      let r ← sim ["help"]
      return if r.code == 0 && (lines r.out).head? == some usage && r.out == a.out then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim --help prints the same usage and exits with 0",
    run := do
      let a ← sim []
      let r ← sim ["--help"]
      return if r.code == 0 && (lines r.out).head? == some usage && r.out == a.out then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim fly gives UNKNOWN_COMMAND",
    run := expectError ["fly"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 sim Run gives UNKNOWN_COMMAND",
    run := expectError ["Run"] "error: UNKNOWN_COMMAND: Run" },
  { name := "JOB-simulate.R5 --colour red gives UNKNOWN_OPTION",
    run := expectError ["run", "--colour", "red"] "error: UNKNOWN_OPTION: --colour" },
  { name := "JOB-simulate.R5 --days with no value gives MISSING_VALUE",
    run := expectError ["run", "--days"] "error: MISSING_VALUE: --days" },
  { name := "JOB-simulate.R5 --strategy with no value gives MISSING_VALUE",
    run := expectError ["run", "--strategy"] "error: MISSING_VALUE: --strategy" },
  { name := "JOB-simulate.R5 --days abc gives BAD_NUMBER",
    run := expectError ["run", "--days", "abc"] "error: BAD_NUMBER: --days abc" },
  { name := "JOB-simulate.R5 an empty --days gives BAD_NUMBER",
    run := expectError ["run", "--days", ""] "error: BAD_NUMBER: --days " },
  { name := "JOB-simulate.R5 --days 36.5 gives BAD_NUMBER",
    run := expectError ["run", "--days", "36.5"] "error: BAD_NUMBER: --days 36.5" },
  { name := "JOB-simulate.R5 --days 2.0 gives BAD_NUMBER",
    run := expectError ["run", "--days", "2.0"] "error: BAD_NUMBER: --days 2.0" },
  { name := "JOB-simulate.R5 --days with a leading space gives BAD_NUMBER",
    run := expectError ["run", "--days", " 2"] "error: BAD_NUMBER: --days  2" },
  { name := "JOB-simulate.R5 --days with a trailing newline gives BAD_NUMBER",
    run := expectStart ["run", "--days", "2\n"] "error: BAD_NUMBER: --days 2\n" (oneLine := false) },
  { name := "JOB-simulate.R5 --days +2 is a whole number with a sign",
    run := do
      let r ← sim ["run", "--days", "+2"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "2") then none
        else some s!"exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}" },
  { name := "JOB-simulate.R5 --pv 1e3 gives BAD_NUMBER",
    run := expectError ["run", "--pv", "1e3"] "error: BAD_NUMBER: --pv 1e3" },
  { name := "JOB-simulate.R5 --pv .5 gives BAD_NUMBER",
    run := expectError ["run", "--pv", ".5"] "error: BAD_NUMBER: --pv .5" },
  { name := "JOB-simulate.R5 --pv 5. gives BAD_NUMBER",
    run := expectError ["run", "--pv", "5."] "error: BAD_NUMBER: --pv 5." },
  { name := "JOB-simulate.R5 --pv 5kW gives BAD_NUMBER",
    run := expectError ["run", "--pv", "5kW"] "error: BAD_NUMBER: --pv 5kW" },
  { name := "JOB-simulate.R5 --pv with a trailing space gives BAD_NUMBER",
    run := expectError ["run", "--pv", "3 "] "error: BAD_NUMBER: --pv 3 " },
  { name := "JOB-simulate.R5 --pv +3 gives the result of --pv 3",
    run := do
      let a ← sim ["run", "--pv", "+3"]
      let b ← sim ["run", "--pv", "3"]
      let d ← sim ["run"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11 &&
          valueOf a.out "solar" != valueOf d.out "solar" then none
        else some s!"+3 {repr a.out}, 3 {repr b.out}" },
  { name := "JOB-simulate.R5 --days 0 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "0"] "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 1 is accepted",
    run := do
      let r ← sim ["run", "--days", "1"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "1") then none
        else some s!"exit code {r.code}, stderr {repr r.err}" },
  { name := "JOB-simulate.R5 --days 3651 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "3651"] "error: OUT_OF_RANGE: --days 3651 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 99999999999999999999 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "99999999999999999999"]
      "error: OUT_OF_RANGE: --days 99999999999999999999 (1 to 3650)" },
  { name := "JOB-simulate.R5 --seed -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--seed", "-1"] "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)" },
  { name := "JOB-simulate.R5 --seed 0 is accepted",
    run := expectRun ["run", "--seed", "0"] },
  { name := "JOB-simulate.R5 --seed 4294967295 is accepted",
    run := expectRun ["run", "--seed", "4294967295"] },
  { name := "JOB-simulate.R5 --seed 4294967296 gives OUT_OF_RANGE",
    run := expectError ["run", "--seed", "4294967296"]
      "error: OUT_OF_RANGE: --seed 4294967296 (0 to 4294967295)" },
  { name := "JOB-simulate.R5 --lat 90 is accepted",
    run := expectRun ["run", "--lat", "90"] },
  { name := "JOB-simulate.R5 --lat -90 is accepted",
    run := expectRun ["run", "--lat", "-90"] },
  { name := "JOB-simulate.R5 --lat 90.1 gives OUT_OF_RANGE",
    run := expectError ["run", "--lat", "90.1"] "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)" },
  { name := "JOB-simulate.R5 --lat -90.1 gives OUT_OF_RANGE",
    run := expectError ["run", "--lat", "-90.1"] "error: OUT_OF_RANGE: --lat -90.1 (-90 to 90)" },
  { name := "JOB-simulate.R5 --pv 100 is accepted",
    run := expectRun ["run", "--pv", "100"] },
  { name := "JOB-simulate.R5 --pv 100.1 gives OUT_OF_RANGE",
    run := expectError ["run", "--pv", "100.1"] "error: OUT_OF_RANGE: --pv 100.1 (0 to 100)" },
  { name := "JOB-simulate.R5 --pv -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--pv", "-1"] "error: OUT_OF_RANGE: --pv -1 (0 to 100)" },
  { name := "JOB-simulate.R5 --battery 200 is accepted",
    run := expectRun ["run", "--battery", "200"] },
  { name := "JOB-simulate.R5 --battery 200.1 gives OUT_OF_RANGE",
    run := expectError ["run", "--battery", "200.1"] "error: OUT_OF_RANGE: --battery 200.1 (0 to 200)" },
  { name := "JOB-simulate.R5 --power 100 is accepted",
    run := expectRun ["run", "--power", "100"] },
  { name := "JOB-simulate.R5 --power 100.1 gives OUT_OF_RANGE",
    run := expectError ["run", "--power", "100.1"] "error: OUT_OF_RANGE: --power 100.1 (0 to 100)" },
  -- With --load 0.1 and no --flex, the --flex default is 0.1, the --load value.
  { name := "JOB-simulate.R5 --load 0.1 is accepted",
    run := expectRun ["run", "--load", "0.1"] },
  { name := "JOB-simulate.R5 --load 0 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "0"] "error: OUT_OF_RANGE: --load 0 (0.1 to 1000)" },
  { name := "JOB-simulate.R5 --load 1000 is accepted",
    run := expectRun ["run", "--load", "1000"] },
  { name := "JOB-simulate.R5 --load 1000.1 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "1000.1"] "error: OUT_OF_RANGE: --load 1000.1 (0.1 to 1000)" },
  { name := "JOB-simulate.R5 --load 10 --flex 10 is accepted",
    run := expectRun ["run", "--load", "10", "--flex", "10"] },
  { name := "JOB-simulate.R5 --load 10 --flex 10.5 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "10", "--flex", "10.5"]
      "error: OUT_OF_RANGE: --flex 10.5 (0 to 10)" },
  { name := "JOB-simulate.R5 the --flex range shows the --load value as typed",
    run := expectError ["run", "--load", "10.0", "--flex", "10.5"]
      "error: OUT_OF_RANGE: --flex 10.5 (0 to 10.0)" },
  { name := "JOB-simulate.R5 --strategy wild gives UNKNOWN_STRATEGY",
    run := expectError ["run", "--strategy", "wild"]
      "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)" },
  { name := "JOB-simulate.R5 --strategy Greedy gives UNKNOWN_STRATEGY",
    run := expectError ["run", "--strategy", "Greedy"]
      "error: UNKNOWN_STRATEGY: Greedy (none, greedy, evening, shift)" },
  { name := "JOB-simulate.R5 sim run now gives UNKNOWN_OPTION",
    run := expectError ["run", "now"] "error: UNKNOWN_OPTION: now" },
  { name := "JOB-simulate.R5 --days 10 --days 20 shows 20 days",
    run := do
      let r ← sim ["run", "--days", "10", "--days", "20"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 a bad number stops the reading before a later unknown option",
    run := expectError ["run", "--days", "abc", "--colour", "red"] "error: BAD_NUMBER: --days abc" },
  { name := "JOB-simulate.R5 a bad strategy name comes before a range problem",
    run := expectError ["run", "--days", "0", "--strategy", "wild"]
      "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)" },
  { name := "JOB-simulate.R5 the command word comes before each option",
    run := expectError ["fly", "--colour", "red"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 each error gives empty stdout and exit code 2",
    run := do
      for a in errorCases do
        let r ← sim a
        if r.out != "" || r.code != 2 || r.err == "" then
          return some s!"sim {a}: exit code {r.code}, stdout {repr r.out}"
      return none }
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

## Checks removed from earlier intents

None. The lock changed no acceptance file of an earlier intent.

