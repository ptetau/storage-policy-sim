# Review packet · CH-0006-forecast-fast · tests

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 9e78f03f4a7d3f4c60de295a9a5df7ea72d17dc0

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
- Each error that the Interface lists has a check that expects its exact message and
  result, and its code where the caller can see it.
  For a command, the check reads the message from the stream that the entry names.
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
# CH-0006 · Forecast from built hours

Intent: IN-0008 · Scope: CAP-forecast · Status: testing · Ticket: none · Branch: pdlc/CH-0006-forecast-fast · Base: pdlc/CH-0005-forecast

Tests-Locked: 608aff7

## Delivers

The library makes a simulated forecast from scenario hours that the caller built once. The result equals the result of the older call, and it is fast enough for a run with many fetches. The forecast error of a day is shared by the periods of that day, as in real forecasts.

## Requirements

### CAP-forecast.R6 · Forecast from built hours
- Given the hours of `scenario` for seed 7 and 365 days at latitude 45 with 5 kW of panels, and an error scale of 1, when `forecastOf` runs for the fetch hours 0, 4116 and 8750, then each result has the same periods as `forecast` for the same arguments. Each period has the same end and the same three values.
- Given the same hours and an error scale of 0, when `forecastOf` runs for the fetch hour 4000, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given the same hours, when `forecastOf` runs for the fetch hour 8760, then it has no period.
- Given no hours, when `forecastOf` runs for the fetch hour 0, then it has no period.
- Given the same hours and seeds 7 and 8, when `forecastOf` runs for the fetch hour 4000 with the hours of each seed, then at least one estimate differs.

### CAP-forecast.R7 · Shared error of a day
- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny periods that end at 11:30 and 13:30 of the same day are compared, then their correlation over the days that have both is from 0.55 to 0.85. Days where either estimate is cut to the range of R2 do not count.
- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny period that ends at 11:30 of a day and of the next day are compared, each from the fetch at 00:00 of its own day, then their correlation is from -0.25 to 0.25.
- Given the fetches at hour 0 and at hour 10 of each day from 0 to 364, when the relative errors of the sunny period that ends at 13:30 of that day are compared, then at least 62% of the days have the same sign in both fetches. Days with a relative error of 0 in either fetch do not count.
- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given a fetch at 00:00 of each day, when the sunny periods are compared, then 60% to 95% of them have the actual power in the band.

## Relies on

- CAP-scenario (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `Period` · type · `StoragePolicySim/Forecast.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: the hours of `scenario site seed days`, built once by the caller, the same site and seed, the error scale, and the hour of the run at which the fetch is made
  - out: the same periods as `forecast site seed days errorScale fetchHour`, where `days` is the count of hours divided by 24
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
- `seed` · seam: randomness · `StoragePolicySim/Forecast.lean`
  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
  - errors: none

## Files

- `StoragePolicySim/Forecast.lean`

## Check files

- `tests/CAP-forecast.lean`

## Steps

### Step 1 · Forecast from built hours · [ ]

- Requirement: CAP-forecast.R6
- Check: the checks named `CAP-forecast.R6 …` in `tests/CAP-forecast.lean`
- Done when: the checks pass

### Step 2 · Shared error of a day · [ ]

- Requirement: CAP-forecast.R7
- Check: the checks named `CAP-forecast.R7 …` in `tests/CAP-forecast.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned first in IN-0008 (hot-water policy simulation), because the home simulation fetches the forecast many times.
````

## The spec it covers: title and summary

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
````

## The requirements, in full

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

### Diff against pdlc/CH-0005-forecast

````
diff --git a/tests/CAP-forecast.lean b/tests/CAP-forecast.lean
new file mode 100644
index 0000000..5d33f8c
--- /dev/null
+++ b/tests/CAP-forecast.lean
@@ -0,0 +1,336 @@
+/-
+Component checks of CAP-forecast, for CH-0006 (forecast from built hours). The change covers
+CAP-forecast.R6 (forecast from built hours) and CAP-forecast.R7 (shared error of a day).
+
+The checks call only `Period`, `forecast`, `forecastOf`, `Site`, `Hour` and `scenario`. No
+entry of the Interface can fail, so no check expects an error code. The `seed` argument of
+`forecast` and `forecastOf` is the only seam. No check uses the clock. No check waits for a
+process, so no check needs a time limit.
+
+In the lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is 365
+days, and the error scale is 1, unless the line says otherwise.
+
+Terms of the checks:
+- The actual power of a period that ends at minute `e` is the solar energy of hour
+  `(e - 30) / 60` in the scenario with the same site, seed and days.
+- A sunny period is a period with an actual power of more than 0 kW, as CAP-forecast.R2 says.
+- An estimate is cut when it is 0 kW or it is the panel power (5 kW).
+
+Statistics of CAP-forecast.R7. The relative error of a sunny period is its estimate less its
+actual power, over the actual power. R7 divides it also by the spread. The spread depends only
+on the lead time of the period. Each series that a line compares has one lead time (for
+example, the period that ends at 11:30 in the fetches at 00:00). Thus the spread is one
+constant for the series. A correlation does not change when a series is scaled by a constant,
+and the sign does not change either. So the helper `relErr` leaves out the spread. It then
+needs no rule for the spread (a step or a slope).
+
+Shared runs. A forecast from the built hours is cheap, and a call of `forecast` builds the
+scenario again. Thus the checks of R7 call `forecastOf` with the hours of seed 7, built once
+at the top level of this file.
+-/
+import StoragePolicySim.Scenario
+import StoragePolicySim.Forecast
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
+def firstSome : List (Option String) → Option String
+  | [] => none
+  | some m :: _ => some m
+  | none :: rest => firstSome rest
+
+def sumF (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0
+
+def meanF (xs : List Float) : Float :=
+  if xs.isEmpty then 0.0 else sumF xs / xs.length.toFloat
+
+/-- The correlation of two lists of the same length. It is 0 when a list has no spread. -/
+def corrF (xs ys : List Float) : Float :=
+  let mx := meanF xs
+  let mv := meanF ys
+  let cov := meanF ((xs.zip ys).map (fun (p : Float × Float) => (p.1 - mx) * (p.2 - mv)))
+  let vx := meanF (xs.map (fun x => (x - mx) * (x - mx)))
+  let vy := meanF (ys.map (fun y => (y - mv) * (y - mv)))
+  if vx > 0.0 && vy > 0.0 then cov / Float.sqrt (vx * vy) else 0.0
+
+-- Helpers for CAP-forecast
+
+def site45 : Site :=
+  { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }
+
+/-- The hours of seed 7 and 365 days, built once. -/
+def scen7 : Array Hour := scenario site45 7 365
+
+/-- The hours of seed 8 and 365 days, for the lines that compare two seeds. -/
+def scen8 : Array Hour := scenario site45 8 365
+
+/-- A forecast of the lines: site 45, seed 7, 365 days, from the built hours. -/
+def fo (scale : Float) (fetch : Nat) : Array Period :=
+  forecastOf scen7 site45 7 scale fetch
+
+/-- The hour of the run of a period that ends at minute `e`. -/
+def accHourOf (e : Nat) : Nat := (e - 30) / 60
+
+/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
+def accActualKw (e : Nat) : Float := scen7[accHourOf e]!.pvKwh
+
+def samePeriod (a b : Period) : Bool :=
+  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
+  a.p90Kw == b.p90Kw
+
+def samePeriods (a b : Array Period) : Bool :=
+  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)
+
+def sumEst (ps : Array Period) : Float := sumF (ps.toList.map (fun p => p.estimateKw))
+
+/-- Each value of each period must equal its actual power. -/
+def badEqual (ps : Array Period) : Option String :=
+  ps.toList.findSome? (fun p =>
+    let a := accActualKw p.endMinute
+    if near p.estimateKw a 1e-6 && near p.p10Kw a 1e-6 && near p.p90Kw a 1e-6 then none
+    else some s!"end {p.endMinute}: actual {a}, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}")
+
+/-- `forecastOf` and `forecast` must give the same periods for a fetch hour. -/
+def sameAsForecast (f : Nat) : Option String :=
+  let a := forecastOf scen7 site45 7 1.0 f
+  let b := forecast site45 7 365 1.0 f
+  if a.size > 0 && samePeriods a b then none
+  else some s!"fetch {f}: forecastOf gives {a.size} periods and forecast gives {b.size}, or a value differs"
+
+/-- The period of a fetch that ends at minute `e` of the run. -/
+def periodEnding (ps : Array Period) (e : Nat) : Option Period :=
+  ps.toList.find? (fun p => p.endMinute == e)
+
+/-- The relative error of a period: its estimate less its actual power, over the actual power.
+The spread is left out. See the comment at the top of the file. -/
+def relErr (p : Period) : Float :=
+  (p.estimateKw - accActualKw p.endMinute) / accActualKw p.endMinute
+
+/-- An estimate is cut at 0 kW or at the panel power of 5 kW. -/
+def isCut (p : Period) : Bool := p.estimateKw ≤ 1e-9 || p.estimateKw ≥ 5.0 - 1e-9
+
+/-- A sunny period with an estimate that is not cut. -/
+def okSunny (p : Period) : Bool := accActualKw p.endMinute > 0.0 && !isCut p
+
+def inBand (p : Period) : Bool :=
+  let a := accActualKw p.endMinute
+  p.p10Kw - 1e-9 ≤ a && a ≤ p.p90Kw + 1e-9
+
+/-- The fetches at 00:00 of the days 0 to 364, each with the hour of its fetch. -/
+def dayFetches : List (Nat × Array Period) :=
+  (List.range 365).map (fun d => (24 * d, fo 1.0 (24 * d)))
+
+/-- The fetches at hour 10 of the days 0 to 364. -/
+def tenFetches : List (Nat × Array Period) :=
+  (List.range 365).map (fun d => (24 * d + 10, fo 1.0 (24 * d + 10)))
+
+/-- The relative errors of the periods that end at 11:30 and at 13:30 of the same day, for
+each day that has both, sunny and not cut. The fetch is at 00:00 of the day. -/
+def pairsSameDay : List (Float × Float) :=
+  dayFetches.filterMap (fun (f, ps) =>
+    match periodEnding ps (60 * f + 690), periodEnding ps (60 * f + 810) with
+    | some a, some b => if okSunny a && okSunny b then some (relErr a, relErr b) else none
+    | _, _ => none)
+
+/-- The relative error of the sunny period that ends at 11:30 of the day of a fetch at 00:00,
+shifted by `shift` minutes. A day has none when its period is not in the fetch or it is not
+sunny. -/
+def err1130 (shift : Nat) : List (Option Float) :=
+  dayFetches.map (fun (f, ps) =>
+    match periodEnding ps (60 * f + 690 + shift) with
+    | some p => if accActualKw p.endMinute > 0.0 then some (relErr p) else none
+    | none => none)
+
+def bothSome (a b : List (Option Float)) : List (Float × Float) :=
+  (a.zip b).filterMap (fun (x, y) =>
+    match x, y with
+    | some u, some v => some (u, v)
+    | _, _ => none)
+
+/-- The periods that end at 11:30 of a day and of the next day. Each one comes from the fetch
+at 00:00 of its own day. -/
+def pairsNextFetch : List (Float × Float) :=
+  bothSome (err1130 0) ((err1130 0).tail)
+
+/-- The periods that end at 11:30 of a day and of the next day. Both come from the fetch at
+00:00 of the first day. -/
+def pairsNextSameFetch : List (Float × Float) :=
+  bothSome (err1130 0) (err1130 1440)
+
+/-- The relative errors of the period that ends at 13:30 of a day, from the fetch at 00:00 and
+from the fetch at hour 10. Only a sunny period counts. -/
+def signPairs : List (Float × Float) :=
+  (dayFetches.zip tenFetches).filterMap (fun (a, b) =>
+    match periodEnding a.2 (60 * a.1 + 810), periodEnding b.2 (60 * a.1 + 810) with
+    | some p, some q =>
+      if accActualKw p.endMinute > 0.0 then some (relErr p, relErr q) else none
+    | _, _ => none)
+
+/-- The sunny periods of the fetches at 00:00 of each day. -/
+def sunnyAll : List Period :=
+  dayFetches.foldl (fun acc (_, ps) =>
+    acc ++ ps.toList.filter (fun p => accActualKw p.endMinute > 0.0)) []
+
+def checks : List Check := [
+  -- CAP-forecast.R6
+  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast for the fetch hours 0, 4116 and 8750",
+    run := do
+      let a := forecastOf scen7 site45 7 1.0 0
+      let b := forecastOf scen7 site45 7 1.0 8750
+      return firstSome [
+        sameAsForecast 0, sameAsForecast 4116, sameAsForecast 8750,
+        if a.size == 96 && b.size == 20 then none
+        else some s!"{a.size} periods at hour 0 and {b.size} periods at hour 8750"] },
+  { name := "CAP-forecast.R6 with an error scale of 0 each value of a fetch at hour 4000 equals its actual power",
+    run := do
+      let ps := forecastOf scen7 site45 7 0.0 4000
+      return firstSome [
+        if ps.size == 96 then none else some s!"{ps.size} periods",
+        badEqual ps,
+        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
+  { name := "CAP-forecast.R6 a fetch at hour 8760 has no period",
+    run := do
+      let ps := forecastOf scen7 site45 7 1.0 8760
+      return if ps.size == 0 then none else some s!"{ps.size} periods" },
+  { name := "CAP-forecast.R6 no hours give no period for a fetch at hour 0",
+    run := do
+      let ps := forecastOf (#[] : Array Hour) site45 7 1.0 0
+      return if ps.size == 0 then none else some s!"{ps.size} periods" },
+  { name := "CAP-forecast.R6 seeds 7 and 8 give a different estimate for a fetch at hour 4000",
+    run := do
+      let a := forecastOf scen7 site45 7 1.0 4000
+      let b := forecastOf scen8 site45 8 1.0 4000
+      let differs := (List.zip a.toList b.toList).any (fun (x, y) => !(x.estimateKw == y.estimateKw))
+      return firstFail [
+        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
+        (differs, "each estimate is the same for the two seeds")] },
+  -- Checks that the acceptance file lacks: the seam `seed`, and the edges of the Interface.
+  { name := "CAP-forecast.R6 the same seed gives the same forecast from forecastOf and from forecast",
+    run := do
+      let again := scenario site45 7 365
+      let a := forecastOf scen7 site45 7 1.0 4116
+      let b := forecastOf again site45 7 1.0 4116
+      let c := forecast site45 7 365 1.0 4116
+      let d := forecast site45 7 365 1.0 4116
+      return firstFail [
+        (a.size == 96, s!"{a.size} periods"),
+        (samePeriods a b, "two calls of forecastOf with seed 7 give other periods"),
+        (samePeriods c d, "two calls of forecast with seed 7 give other periods")] },
+  { name := "CAP-forecast.R6 a fetch at hour 8759 has the 2 periods of the last hour, as forecast gives",
+    run := do
+      let a := fo 1.0 8759
+      let b := forecast site45 7 365 1.0 8759
+      let ends := a.toList.map (fun p => p.endMinute)
+      return firstFail [
+        (a.size == 2, s!"{a.size} periods, want 2"),
+        (ends == [525570, 525600], s!"the ends are {ends}, want [525570, 525600]"),
+        (samePeriods a b, "forecastOf and forecast give other periods")] },
+  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast with an error scale of 0.5",
+    run := do
+      let a := fo 0.5 4116
+      let b := forecast site45 7 365 0.5 4116
+      return firstFail [
+        (a.size == 96, s!"{a.size} periods"),
+        (samePeriods a b, "forecastOf and forecast give other periods with an error scale of 0.5")] },
+  { name := "CAP-forecast.R6 hours of 10 days make a run of 10 days: the fetch at hour 240 has no period",
+    run := do
+      let hs := scenario site45 7 10
+      let at230 := forecastOf hs site45 7 1.0 230
+      let at239 := forecastOf hs site45 7 1.0 239
+      let at240 := forecastOf hs site45 7 1.0 240
+      let ends := at230.toList.map (fun p => p.endMinute)
+      return firstFail [
+        (hs.size == 240, s!"{hs.size} hours, want 240"),
+        (at230.size == 20, s!"{at230.size} periods at hour 230, want 20"),
+        (ends.head? == some 13830 && ends.getLast? == some 14400,
+          s!"the first and the last end at hour 230 are {ends.head?} and {ends.getLast?}, want 13830 and 14400"),
+        (samePeriods at230 (forecast site45 7 10 1.0 230),
+          "forecastOf and forecast give other periods at hour 230"),
+        (at239.size == 2 && samePeriods at239 (forecast site45 7 10 1.0 239),
+          s!"hour 239 gives {at239.size} periods, want 2 as forecast gives"),
+        (at240.size == 0, s!"{at240.size} periods at hour 240, want 0")] },
+  { name := "CAP-forecast.R6 no hours give no period for each fetch hour and each error scale",
+    run := do
+      let cases : List (Nat × Float) :=
+        [(0, 1.0), (1, 1.0), (100, 1.0), (4116, 0.0), (8760, 1.0)]
+      let bad := cases.find? (fun (f, s) =>
+        (forecastOf (#[] : Array Hour) site45 7 s f).size != 0)
+      return match bad with
+        | some (f, s) => some s!"fetch hour {f} with error scale {s} has periods"
+        | none => none },
+
+  -- CAP-forecast.R7
+  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 and at 13:30 of a day have a correlation from 0.55 to 0.85",
+    run := do
+      let n := pairsSameDay.length
+      let c := corrF (pairsSameDay.map (·.1)) (pairsSameDay.map (·.2))
+      if n < 150 then
+        return some s!"only {n} days have both periods"
+      return if c ≥ 0.55 && c ≤ 0.85 then none
+        else some s!"correlation {c} over {n} days" },
+  -- The line says that each period comes from the fetch at 00:00 of its own day. The variable `a`
+  -- reads the line so. The variable `b` also takes both periods from the fetch of the first
+  -- day. Both readings must give a correlation from -0.25 to 0.25.
+  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25",
+    run := do
+      let a := pairsNextFetch
+      let b := pairsNextSameFetch
+      let ca := corrF (a.map (·.1)) (a.map (·.2))
+      let cb := corrF (b.map (·.1)) (b.map (·.2))
+      return firstFail [
+        (a.length ≥ 150 && b.length ≥ 150, s!"only {a.length} and {b.length} pairs of days"),
+        (ca ≥ -0.25 && ca ≤ 0.25,
+          s!"fetch of each day: correlation {ca} over {a.length} pairs of days"),
+        (cb ≥ -0.25 && cb ≤ 0.25,
+          s!"one fetch for both days: correlation {cb} over {b.length} pairs of days")] },
+  { name := "CAP-forecast.R7 at least 62% of the days have the same sign of the error at 13:30 in the fetches at hour 0 and at hour 10",
+    run := do
+      let usable := signPairs.filter (fun (x, y) => x.abs > 1e-12 && y.abs > 1e-12)
+      let same := usable.filter (fun (x, y) => x * y > 0.0)
+      let n := usable.length
+      if n < 150 then
+        return some s!"only {n} days count"
+      return if same.length.toFloat ≥ 0.62 * n.toFloat then none
+        else some s!"{same.length} of {n} days have the same sign" },
+  { name := "CAP-forecast.R7 with an error scale of 0 each value of a fetch at hour 0 equals its actual power",
+    run := do
+      let ps := fo 0.0 0
+      return firstSome [
+        if ps.size == 96 then none else some s!"{ps.size} periods",
+        badEqual ps,
+        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
+  { name := "CAP-forecast.R7 60% to 95% of the sunny periods of a fetch at 00:00 of each day have the actual power in the band",
+    run := do
+      let n := sunnyAll.length
+      let k := (sunnyAll.filter inBand).length
+      if n < 1000 then
+        return some s!"only {n} sunny periods"
+      return if k.toFloat ≥ 0.6 * n.toFloat && k.toFloat ≤ 0.95 * n.toFloat then none
+        else some s!"{k} of {n} sunny periods have the actual power in the band" }
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

### tests/CAP-forecast.lean

````
/-
Component checks of CAP-forecast, for CH-0006 (forecast from built hours). The change covers
CAP-forecast.R6 (forecast from built hours) and CAP-forecast.R7 (shared error of a day).

The checks call only `Period`, `forecast`, `forecastOf`, `Site`, `Hour` and `scenario`. No
entry of the Interface can fail, so no check expects an error code. The `seed` argument of
`forecast` and `forecastOf` is the only seam. No check uses the clock. No check waits for a
process, so no check needs a time limit.

In the lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is 365
days, and the error scale is 1, unless the line says otherwise.

Terms of the checks:
- The actual power of a period that ends at minute `e` is the solar energy of hour
  `(e - 30) / 60` in the scenario with the same site, seed and days.
- A sunny period is a period with an actual power of more than 0 kW, as CAP-forecast.R2 says.
- An estimate is cut when it is 0 kW or it is the panel power (5 kW).

Statistics of CAP-forecast.R7. The relative error of a sunny period is its estimate less its
actual power, over the actual power. R7 divides it also by the spread. The spread depends only
on the lead time of the period. Each series that a line compares has one lead time (for
example, the period that ends at 11:30 in the fetches at 00:00). Thus the spread is one
constant for the series. A correlation does not change when a series is scaled by a constant,
and the sign does not change either. So the helper `relErr` leaves out the spread. It then
needs no rule for the spread (a step or a slope).

Shared runs. A forecast from the built hours is cheap, and a call of `forecast` builds the
scenario again. Thus the checks of R7 call `forecastOf` with the hours of seed 7, built once
at the top level of this file.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Forecast
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

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

def sumF (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0

def meanF (xs : List Float) : Float :=
  if xs.isEmpty then 0.0 else sumF xs / xs.length.toFloat

/-- The correlation of two lists of the same length. It is 0 when a list has no spread. -/
def corrF (xs ys : List Float) : Float :=
  let mx := meanF xs
  let mv := meanF ys
  let cov := meanF ((xs.zip ys).map (fun (p : Float × Float) => (p.1 - mx) * (p.2 - mv)))
  let vx := meanF (xs.map (fun x => (x - mx) * (x - mx)))
  let vy := meanF (ys.map (fun y => (y - mv) * (y - mv)))
  if vx > 0.0 && vy > 0.0 then cov / Float.sqrt (vx * vy) else 0.0

-- Helpers for CAP-forecast

def site45 : Site :=
  { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

/-- The hours of seed 7 and 365 days, built once. -/
def scen7 : Array Hour := scenario site45 7 365

/-- The hours of seed 8 and 365 days, for the lines that compare two seeds. -/
def scen8 : Array Hour := scenario site45 8 365

/-- A forecast of the lines: site 45, seed 7, 365 days, from the built hours. -/
def fo (scale : Float) (fetch : Nat) : Array Period :=
  forecastOf scen7 site45 7 scale fetch

/-- The hour of the run of a period that ends at minute `e`. -/
def accHourOf (e : Nat) : Nat := (e - 30) / 60

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def accActualKw (e : Nat) : Float := scen7[accHourOf e]!.pvKwh

def samePeriod (a b : Period) : Bool :=
  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
  a.p90Kw == b.p90Kw

def samePeriods (a b : Array Period) : Bool :=
  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)

def sumEst (ps : Array Period) : Float := sumF (ps.toList.map (fun p => p.estimateKw))

/-- Each value of each period must equal its actual power. -/
def badEqual (ps : Array Period) : Option String :=
  ps.toList.findSome? (fun p =>
    let a := accActualKw p.endMinute
    if near p.estimateKw a 1e-6 && near p.p10Kw a 1e-6 && near p.p90Kw a 1e-6 then none
    else some s!"end {p.endMinute}: actual {a}, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}")

/-- `forecastOf` and `forecast` must give the same periods for a fetch hour. -/
def sameAsForecast (f : Nat) : Option String :=
  let a := forecastOf scen7 site45 7 1.0 f
  let b := forecast site45 7 365 1.0 f
  if a.size > 0 && samePeriods a b then none
  else some s!"fetch {f}: forecastOf gives {a.size} periods and forecast gives {b.size}, or a value differs"

/-- The period of a fetch that ends at minute `e` of the run. -/
def periodEnding (ps : Array Period) (e : Nat) : Option Period :=
  ps.toList.find? (fun p => p.endMinute == e)

/-- The relative error of a period: its estimate less its actual power, over the actual power.
The spread is left out. See the comment at the top of the file. -/
def relErr (p : Period) : Float :=
  (p.estimateKw - accActualKw p.endMinute) / accActualKw p.endMinute

/-- An estimate is cut at 0 kW or at the panel power of 5 kW. -/
def isCut (p : Period) : Bool := p.estimateKw ≤ 1e-9 || p.estimateKw ≥ 5.0 - 1e-9

/-- A sunny period with an estimate that is not cut. -/
def okSunny (p : Period) : Bool := accActualKw p.endMinute > 0.0 && !isCut p

def inBand (p : Period) : Bool :=
  let a := accActualKw p.endMinute
  p.p10Kw - 1e-9 ≤ a && a ≤ p.p90Kw + 1e-9

/-- The fetches at 00:00 of the days 0 to 364, each with the hour of its fetch. -/
def dayFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d, fo 1.0 (24 * d)))

/-- The fetches at hour 10 of the days 0 to 364. -/
def tenFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d + 10, fo 1.0 (24 * d + 10)))

/-- The relative errors of the periods that end at 11:30 and at 13:30 of the same day, for
each day that has both, sunny and not cut. The fetch is at 00:00 of the day. -/
def pairsSameDay : List (Float × Float) :=
  dayFetches.filterMap (fun (f, ps) =>
    match periodEnding ps (60 * f + 690), periodEnding ps (60 * f + 810) with
    | some a, some b => if okSunny a && okSunny b then some (relErr a, relErr b) else none
    | _, _ => none)

/-- The relative error of the sunny period that ends at 11:30 of the day of a fetch at 00:00,
shifted by `shift` minutes. A day has none when its period is not in the fetch or it is not
sunny. -/
def err1130 (shift : Nat) : List (Option Float) :=
  dayFetches.map (fun (f, ps) =>
    match periodEnding ps (60 * f + 690 + shift) with
    | some p => if accActualKw p.endMinute > 0.0 then some (relErr p) else none
    | none => none)

def bothSome (a b : List (Option Float)) : List (Float × Float) :=
  (a.zip b).filterMap (fun (x, y) =>
    match x, y with
    | some u, some v => some (u, v)
    | _, _ => none)

/-- The periods that end at 11:30 of a day and of the next day. Each one comes from the fetch
at 00:00 of its own day. -/
def pairsNextFetch : List (Float × Float) :=
  bothSome (err1130 0) ((err1130 0).tail)

/-- The periods that end at 11:30 of a day and of the next day. Both come from the fetch at
00:00 of the first day. -/
def pairsNextSameFetch : List (Float × Float) :=
  bothSome (err1130 0) (err1130 1440)

/-- The relative errors of the period that ends at 13:30 of a day, from the fetch at 00:00 and
from the fetch at hour 10. Only a sunny period counts. -/
def signPairs : List (Float × Float) :=
  (dayFetches.zip tenFetches).filterMap (fun (a, b) =>
    match periodEnding a.2 (60 * a.1 + 810), periodEnding b.2 (60 * a.1 + 810) with
    | some p, some q =>
      if accActualKw p.endMinute > 0.0 then some (relErr p, relErr q) else none
    | _, _ => none)

/-- The sunny periods of the fetches at 00:00 of each day. -/
def sunnyAll : List Period :=
  dayFetches.foldl (fun acc (_, ps) =>
    acc ++ ps.toList.filter (fun p => accActualKw p.endMinute > 0.0)) []

def checks : List Check := [
  -- CAP-forecast.R6
  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast for the fetch hours 0, 4116 and 8750",
    run := do
      let a := forecastOf scen7 site45 7 1.0 0
      let b := forecastOf scen7 site45 7 1.0 8750
      return firstSome [
        sameAsForecast 0, sameAsForecast 4116, sameAsForecast 8750,
        if a.size == 96 && b.size == 20 then none
        else some s!"{a.size} periods at hour 0 and {b.size} periods at hour 8750"] },
  { name := "CAP-forecast.R6 with an error scale of 0 each value of a fetch at hour 4000 equals its actual power",
    run := do
      let ps := forecastOf scen7 site45 7 0.0 4000
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R6 a fetch at hour 8760 has no period",
    run := do
      let ps := forecastOf scen7 site45 7 1.0 8760
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 no hours give no period for a fetch at hour 0",
    run := do
      let ps := forecastOf (#[] : Array Hour) site45 7 1.0 0
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 seeds 7 and 8 give a different estimate for a fetch at hour 4000",
    run := do
      let a := forecastOf scen7 site45 7 1.0 4000
      let b := forecastOf scen8 site45 8 1.0 4000
      let differs := (List.zip a.toList b.toList).any (fun (x, y) => !(x.estimateKw == y.estimateKw))
      return firstFail [
        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
        (differs, "each estimate is the same for the two seeds")] },
  -- Checks that the acceptance file lacks: the seam `seed`, and the edges of the Interface.
  { name := "CAP-forecast.R6 the same seed gives the same forecast from forecastOf and from forecast",
    run := do
      let again := scenario site45 7 365
      let a := forecastOf scen7 site45 7 1.0 4116
      let b := forecastOf again site45 7 1.0 4116
      let c := forecast site45 7 365 1.0 4116
      let d := forecast site45 7 365 1.0 4116
      return firstFail [
        (a.size == 96, s!"{a.size} periods"),
        (samePeriods a b, "two calls of forecastOf with seed 7 give other periods"),
        (samePeriods c d, "two calls of forecast with seed 7 give other periods")] },
  { name := "CAP-forecast.R6 a fetch at hour 8759 has the 2 periods of the last hour, as forecast gives",
    run := do
      let a := fo 1.0 8759
      let b := forecast site45 7 365 1.0 8759
      let ends := a.toList.map (fun p => p.endMinute)
      return firstFail [
        (a.size == 2, s!"{a.size} periods, want 2"),
        (ends == [525570, 525600], s!"the ends are {ends}, want [525570, 525600]"),
        (samePeriods a b, "forecastOf and forecast give other periods")] },
  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast with an error scale of 0.5",
    run := do
      let a := fo 0.5 4116
      let b := forecast site45 7 365 0.5 4116
      return firstFail [
        (a.size == 96, s!"{a.size} periods"),
        (samePeriods a b, "forecastOf and forecast give other periods with an error scale of 0.5")] },
  { name := "CAP-forecast.R6 hours of 10 days make a run of 10 days: the fetch at hour 240 has no period",
    run := do
      let hs := scenario site45 7 10
      let at230 := forecastOf hs site45 7 1.0 230
      let at239 := forecastOf hs site45 7 1.0 239
      let at240 := forecastOf hs site45 7 1.0 240
      let ends := at230.toList.map (fun p => p.endMinute)
      return firstFail [
        (hs.size == 240, s!"{hs.size} hours, want 240"),
        (at230.size == 20, s!"{at230.size} periods at hour 230, want 20"),
        (ends.head? == some 13830 && ends.getLast? == some 14400,
          s!"the first and the last end at hour 230 are {ends.head?} and {ends.getLast?}, want 13830 and 14400"),
        (samePeriods at230 (forecast site45 7 10 1.0 230),
          "forecastOf and forecast give other periods at hour 230"),
        (at239.size == 2 && samePeriods at239 (forecast site45 7 10 1.0 239),
          s!"hour 239 gives {at239.size} periods, want 2 as forecast gives"),
        (at240.size == 0, s!"{at240.size} periods at hour 240, want 0")] },
  { name := "CAP-forecast.R6 no hours give no period for each fetch hour and each error scale",
    run := do
      let cases : List (Nat × Float) :=
        [(0, 1.0), (1, 1.0), (100, 1.0), (4116, 0.0), (8760, 1.0)]
      let bad := cases.find? (fun (f, s) =>
        (forecastOf (#[] : Array Hour) site45 7 s f).size != 0)
      return match bad with
        | some (f, s) => some s!"fetch hour {f} with error scale {s} has periods"
        | none => none },

  -- CAP-forecast.R7
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 and at 13:30 of a day have a correlation from 0.55 to 0.85",
    run := do
      let n := pairsSameDay.length
      let c := corrF (pairsSameDay.map (·.1)) (pairsSameDay.map (·.2))
      if n < 150 then
        return some s!"only {n} days have both periods"
      return if c ≥ 0.55 && c ≤ 0.85 then none
        else some s!"correlation {c} over {n} days" },
  -- The line says that each period comes from the fetch at 00:00 of its own day. The variable `a`
  -- reads the line so. The variable `b` also takes both periods from the fetch of the first
  -- day. Both readings must give a correlation from -0.25 to 0.25.
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25",
    run := do
      let a := pairsNextFetch
      let b := pairsNextSameFetch
      let ca := corrF (a.map (·.1)) (a.map (·.2))
      let cb := corrF (b.map (·.1)) (b.map (·.2))
      return firstFail [
        (a.length ≥ 150 && b.length ≥ 150, s!"only {a.length} and {b.length} pairs of days"),
        (ca ≥ -0.25 && ca ≤ 0.25,
          s!"fetch of each day: correlation {ca} over {a.length} pairs of days"),
        (cb ≥ -0.25 && cb ≤ 0.25,
          s!"one fetch for both days: correlation {cb} over {b.length} pairs of days")] },
  { name := "CAP-forecast.R7 at least 62% of the days have the same sign of the error at 13:30 in the fetches at hour 0 and at hour 10",
    run := do
      let usable := signPairs.filter (fun (x, y) => x.abs > 1e-12 && y.abs > 1e-12)
      let same := usable.filter (fun (x, y) => x * y > 0.0)
      let n := usable.length
      if n < 150 then
        return some s!"only {n} days count"
      return if same.length.toFloat ≥ 0.62 * n.toFloat then none
        else some s!"{same.length} of {n} days have the same sign" },
  { name := "CAP-forecast.R7 with an error scale of 0 each value of a fetch at hour 0 equals its actual power",
    run := do
      let ps := fo 0.0 0
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R7 60% to 95% of the sunny periods of a fetch at 00:00 of each day have the actual power in the band",
    run := do
      let n := sunnyAll.length
      let k := (sunnyAll.filter inBand).length
      if n < 1000 then
        return some s!"only {n} sunny periods"
      return if k.toFloat ≥ 0.6 * n.toFloat && k.toFloat ≤ 0.95 * n.toFloat then none
        else some s!"{k} of {n} sunny periods have the actual power in the band" }
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

