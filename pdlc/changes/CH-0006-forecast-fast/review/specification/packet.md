# Review packet · CH-0006-forecast-fast · specification

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: d08f5374626a4b77dba30bfbc176109fea615595

## Re-review

Earlier review: bde71c519e8061afa20631cd573ed28e0e4900f9

An earlier review of this remit judged this change at bde71c519e80. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.

### Earlier problems

- pdlc/specs/capabilities/CAP-forecast.md:7-14 · The summary in "What it is for" does not show what the change adds. It does not say that the periods of one day share a part of their error (R7, shared error of a day). It does not say that a caller can build the hours once and give them to `forecastOf` (R6, forecast from built hours). The summary still says only "an error that grows with the lead time, from a seed". · Remit rule: the title and the summary of the spec show the behaviour as it is now, and include what the change adds.
- pdlc/specs/capabilities/CAP-forecast.md:175-176 · The sentence "The number `d` depends only on the seed and the day of the run in which the period ends" has two meanings for a period that ends at 00:00. The period from 23:30 to 24:00 of day N ends at 00:00 of day N+1. The same spec writes "a fetch at 00:00 of the day" for the start of a day, so a reader can take day N+1. The code takes day N: `day := hourOfPeriod endMinute / 24` (`StoragePolicySim/Forecast.lean`, `periodOf`). The acceptance lines of R7 test only the periods that end at 11:30 and 13:30, so no line settles this. · Remit rule: a text that is unclear about what the code does, here a sentence with two possible meanings, is a problem. CAP-forecast.R7 is a requirement that this change wrote. Fix: write "the day of the run in which the period lies". The sentence is only in CAP-forecast.md, so one fix is enough.

### Changes since the earlier review

````
diff --git a/StoragePolicySim/Forecast.lean b/StoragePolicySim/Forecast.lean
index 1472e22..3370be2 100644
--- a/StoragePolicySim/Forecast.lean
+++ b/StoragePolicySim/Forecast.lean
@@ -82,7 +82,7 @@ the day of the run. -/
 private def dayDraw (seed day : Nat) : Float :=
   normalOfKey (mix (mix (mix (mix seed.toUInt64) + dayStream) + day.toUInt64))
 
-/-- The random number of a period. It has the variance of a normal curve. It adds the shared
+/-- The random number of a period. It has a variance of 1. It adds the shared
 part of its day and the part of the period. -/
 private def normalDraw (seed fetchHour period day : Nat) : Float :=
   Float.sqrt sharedShare * dayDraw seed day + Float.sqrt ownShare * periodDraw seed fetchHour period
diff --git a/pdlc/changes/CH-0006-forecast-fast/change.md b/pdlc/changes/CH-0006-forecast-fast/change.md
index 74f1088..36dac15 100644
--- a/pdlc/changes/CH-0006-forecast-fast/change.md
+++ b/pdlc/changes/CH-0006-forecast-fast/change.md
@@ -6,7 +6,7 @@ Tests-Locked: 608aff7
 
 ## Delivers
 
-The library makes a simulated forecast from scenario hours that the caller built once. The result equals the result of the older call, and it is fast enough for a run with many fetches. The forecast error of a day is shared by the periods of that day, as in real forecasts.
+The library makes a simulated forecast from scenario hours that the caller built once. The result equals the result of `forecast`, and it is fast enough for a run with many fetches. The forecast error of a day is shared by the periods of that day, as in real forecasts.
 
 ## Requirements
 
@@ -65,7 +65,7 @@ The library makes a simulated forecast from scenario hours that the caller built
 
 ### Test seams
 - `seed` · seam: randomness · `StoragePolicySim/Forecast.lean`
-  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
+  - in: the `seed` argument of `forecast` and of `forecastOf`. The same seed gives the same forecast.
   - errors: none
 
 ## Files
diff --git a/pdlc/specs/capabilities/CAP-forecast.md b/pdlc/specs/capabilities/CAP-forecast.md
index f23f289..012cfa8 100644
--- a/pdlc/specs/capabilities/CAP-forecast.md
+++ b/pdlc/specs/capabilities/CAP-forecast.md
@@ -7,11 +7,13 @@ Status: active
 CAP-forecast (simulated Solcast forecasts) acts like the Solcast hobbyist rooftop forecast
 service, for a scenario. A fetch at an hour of the run gives 30-minute periods for the next
 48 hours. Each period has an estimate, a 10% band and a 90% band. The forecast has an error
-that grows with the lead time, from a seed.
+that grows with the lead time, from a seed. The periods of one day share a part of their
+error, because one weather front covers a whole day.
 
 A hobbyist account can fetch 10 times a day, so the fetch hours of a day come from a count
 of fetches. The forecast can show as Solcast JSON, with UTC times from the longitude. A
-policy reads the forecast as the solar energy of each coming hour.
+policy reads the forecast as the solar energy of each coming hour. A caller that makes many
+fetches builds the hours of the scenario once, and gives them to `forecastOf`.
 
 ## Code map
 
@@ -27,7 +29,7 @@ policy reads the forecast as the solar energy of each coming hour.
   - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
   - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
   - errors: none
-- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean` · proposed
+- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
   - in: the hours of `scenario site seed days`, built once by the caller, the same site and seed, the error scale, and the hour of the run at which the fetch is made
   - out: the same periods as `forecast site seed days errorScale fetchHour`, where `days` is the count of hours divided by 24
   - errors: none
@@ -51,7 +53,7 @@ policy reads the forecast as the solar energy of each coming hour.
 ### Test seams
 
 - `seed` · seam: randomness · `StoragePolicySim/Forecast.lean`
-  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
+  - in: the `seed` argument of `forecast` and of `forecastOf`. The same seed gives the same forecast.
   - errors: none
 
 ## Requirements
@@ -173,7 +175,7 @@ day, because one cloud front covers the whole day. Thus, the random number of R2
 error) of a period has two parts: `sqrt(0.7) × d + sqrt(0.3) × e`, where `d` is a number from
 a normal curve for the day of the period, and `e` is a number from a normal curve for the
 period itself in the fetch (assumed). The number `d` depends only on the seed and the day of
-the run in which the period ends. Thus, two fetches of the same day share `d`. The sum of the
+the run that holds the hour of the period. Thus, two fetches of the same day share `d`. The sum of the
 two parts is still a number from a normal curve, so that the bands of R2 keep their meaning.
 
 The relative error of a sunny period is its estimate less its actual power, divided by the
````

# Remit: specification

Default: no

You judge if the code does what the spec says. You do not see the checks.

- The code meets the acceptance lines of each requirement. For a requirement marked
  `(retire)`, the change removes the code that served the requirement instead.
- The code does nothing that the spec did not ask for.
- Only the files in "Files" changed. In a file that "Files" lists with parts, only those
  parts changed. The change stays in its one scope. A job change must not edit the code of
  a capability.
- No old wording survives. The title and the summary of the spec, the cross-references in
  its requirements, and a README in "Files" show the behaviour as it is now. They include
  what the change adds. Nothing that the change removes or changes still shows the old
  way. The README says how to run the checks, and names any seam that a user can set.
- In this project, the writing rules (`DES-writing-style`, in the packet) are a guideline,
  not a hard rule. A break of a writing rule, or a finding under "Writing check", goes under
  "Notes" with its line and rule. It is not a problem, and it does not fail the review.
- A text that is wrong or unclear about what the code does is still a problem. Examples are
  a wrong fact, a wrong number, and a sentence with two possible meanings.
- On a re-review, the writing check covers only the lines that changed since the earlier
  review.

## The change spec

````
# CH-0006 · Forecast from built hours

Intent: IN-0008 · Scope: CAP-forecast · Status: building · Ticket: none · Branch: pdlc/CH-0006-forecast-fast · Base: pdlc/CH-0005-forecast

Tests-Locked: 608aff7

## Delivers

The library makes a simulated forecast from scenario hours that the caller built once. The result equals the result of `forecast`, and it is fast enough for a run with many fetches. The forecast error of a day is shared by the periods of that day, as in real forecasts.

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
  - in: the `seed` argument of `forecast` and of `forecastOf`. The same seed gives the same forecast.
  - errors: none

## Files

- `StoragePolicySim/Forecast.lean`

## Check files

- `tests/CAP-forecast.lean`

## Steps

### Step 1 · Forecast from built hours · [x]

- Requirement: CAP-forecast.R6
- Check: the checks named `CAP-forecast.R6 …` in `tests/CAP-forecast.lean`
- Done when: the checks pass

### Step 2 · Shared error of a day · [x]

- Requirement: CAP-forecast.R7
- Check: the checks named `CAP-forecast.R7 …` in `tests/CAP-forecast.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned first in IN-0008 (hot-water policy simulation), because the home simulation fetches the forecast many times.
- Build: the 15 checks of `tests/CAP-forecast.lean` pass, with the earlier component checks and the acceptance files of IN-0001 and IN-0002. The three usage checks of IN-0001 fail until CH-0011, as expected. No check changed since the lock.
````

## The spec it covers: title and summary

````
# CAP-forecast · Simulated Solcast rooftop forecasts for policies

Status: active

## What it is for

CAP-forecast (simulated Solcast forecasts) acts like the Solcast hobbyist rooftop forecast
service, for a scenario. A fetch at an hour of the run gives 30-minute periods for the next
48 hours. Each period has an estimate, a 10% band and a 90% band. The forecast has an error
that grows with the lead time, from a seed. The periods of one day share a part of their
error, because one weather front covers a whole day.

A hobbyist account can fetch 10 times a day, so the fetch hours of a day come from a count
of fetches. The forecast can show as Solcast JSON, with UTC times from the longitude. A
policy reads the forecast as the solar energy of each coming hour. A caller that makes many
fetches builds the hours of the scenario once, and gives them to `forecastOf`.

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
- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
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
  - in: the `seed` argument of `forecast` and of `forecastOf`. The same seed gives the same forecast.
  - errors: none
````

## The requirements, in full

### CAP-forecast.R6 · Forecast from built hours

Status: built · Intents: IN-0008

A caller that makes many fetches builds the hours of the scenario once. `forecastOf` gives the
same periods as `forecast`, from these hours, and does not build the scenario again. A set of
hours that is empty has no period in any fetch.

- Given the hours of `scenario` for seed 7 and 365 days at latitude 45 with 5 kW of panels, and an error scale of 1, when `forecastOf` runs for the fetch hours 0, 4116 and 8750, then each result has the same periods as `forecast` for the same arguments. Each period has the same end and the same three values.
- Given the same hours and an error scale of 0, when `forecastOf` runs for the fetch hour 4000, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given the same hours, when `forecastOf` runs for the fetch hour 8760, then it has no period.
- Given no hours, when `forecastOf` runs for the fetch hour 0, then it has no period.
- Given the same hours and seeds 7 and 8, when `forecastOf` runs for the fetch hour 4000 with the hours of each seed, then at least one estimate differs.

### CAP-forecast.R7 · Shared error of a day

Status: built · Intents: IN-0008

A forecast that is wrong about one hour of a day is often wrong about the other hours of that
day, because one cloud front covers the whole day. Thus, the random number of R2 (forecast
error) of a period has two parts: `sqrt(0.7) × d + sqrt(0.3) × e`, where `d` is a number from
a normal curve for the day of the period, and `e` is a number from a normal curve for the
period itself in the fetch (assumed). The number `d` depends only on the seed and the day of
the run that holds the hour of the period. Thus, two fetches of the same day share `d`. The sum of the
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

### DES-writing-style

````
# DES-writing-style · How pdlc writes

Status: agreed · Default: no · Ask at init: yes

In this project, these rules are a guideline, not a hard rule, for now. A review notes a
break of a rule, but the break does not fail the review. The user decided this on
2026-11-01, and https://github.com/ptetau/pskills/issues/24 tracks the rules in pdlc.

## Rule

This rule is a copy of `WRITING-GUIDELINES.md` from the pskills repository.

These guidelines apply to all writing in this repository. They also apply to all text that
an agent writes when it uses the skills in this repository. They have four parts:

1. Part 1 gives the rules of ASD-STE100 Simplified Technical English (STE) in short form.
2. Part 2 gives two more rules: the local-references rule and the described-IDs rule.
3. Part 3 tells you how to apply the rules to each type of text.
4. Part 4 tells you how to examine your text against the rules.

### Where these guidelines apply

Use these guidelines for all of these types of text:

- The replies that an agent writes to the user in a conversation.
- Skills: the `SKILL.md` file, its reference files, and its templates.
- Agent definitions, system prompts, and the prompts that an agent writes for other agents.
- The documents that a skill or an agent writes: specs, designs, plans, reports, and web
  pages.
- Commit messages, pull request text, and code comments.

These items are not prose. Do not change them to obey the rules:

- Code, commands, file paths, and identifiers.
- Error codes, field names, and values.
- Header fields, for example `Intent:`, `Scope:`, `Status:`, `Branch:`, and `Base:`. A
  script reads each value. Thus, a header field holds only the bare value, with no name
  and no backticks. Write `Intent: IN-0001`, not `Intent: IN-0001 (poll-input-errors)`.
- Quoted text. For example, the words of a user, or the trigger phrases in the description
  of a skill.
- The names of products, organisations, and published works.

### Part 1: STE rules

STE is a controlled language for technical text. The standard has 53 rules in nine
sections, and a dictionary of approved words. This part gives the rules in short form,
with the rule numbers of the standard. This repository does not contain the dictionary.
Part 4 tells you how to get the dictionary and how to use it.

#### Words (STE section 1)

- **1.1** Use approved words, technical nouns, and technical verbs.
- **1.2 to 1.4** Use an approved word only as its approved part of speech. Use the word
  only with its approved meaning and in its approved forms. For example, "check" is
  approved as a noun. As a verb, write "make sure that".
- **1.5, 1.6, 1.8 to 1.10** Technical nouns are the names of items in your subject.
  Examples in software are "commit", "branch", "file", "schema", and "pull request". Use
  the terms that your project uses. Select short terms. Do not use slang or jargon.
- **1.7** Do not use a technical noun as a verb. For example, do not write "action the
  ticket". Write "close the ticket".
- **1.11** Use one technical noun for one item. Do not use a different noun for the same
  item in a different part of the text.
- **1.12, 1.13** Technical verbs are the actions in your subject. In software, "commit",
  "merge", "deploy", "parse", and "click" are technical verbs. Do not use a technical verb
  as a noun. Write "merge the branch", not "do a merge of the branch".
- **1.14** Use New Zealand English spelling, for example "behaviour", "colour", and
  "organise". STE uses American English unless your own rules give a different standard.
  These guidelines give New Zealand English. Do not change the spelling of code, field
  names, or quoted text.

#### Multi-word nouns (STE section 2)

- **2.1** Do not write a multi-word noun of more than three words. For example, do not
  write "test result cache file path". Write "the path of the cache file for test
  results".
- **2.2** If a technical noun has more than three words, write it in full one time. Then
  use a shorter form, or join the words with hyphens.

#### Verbs (STE section 3)

- **3.1, 3.2** Use only these verb forms:
  - The infinitive: "to run".
  - The imperative: "Run the tests."
  - The simple present, the simple past, and the simple future: "runs", "ran", "will run".
  - The past participle as an adjective: "the merged branch".
- **3.3** Use the past participle as an adjective, for example "the merged branch".
- **3.4** Do not use auxiliary verbs to make complex verb constructions. For example, do
  not write "the file should have been updated". Write "update the file".
- **3.5** Use the "-ing" form of a verb only in a technical noun, for example "load
  balancing". Do not write "When running the tests, read the log". Write "When you run
  the tests, read the log".
- **3.6** Use the active voice. In descriptive text, you can use the passive voice only
  when you do not know who or what does the action.
- **Modal verbs (3.2, 3.4).** STE has "must" and "can". It does not have "should" or "may".
  Keep the strength of the original text:
  - A rule that always holds: write "must" or "must not".
  - Advice or a default: write "Try to …" or "Usually, …". Do not write "must".
  - A permission: write "is permitted to …". Write "can" for an ability.
  - The word "never": write "Do not …".
- **3.7** Use a verb to show an action, not a noun. Write "install the package", not "do
  the installation of the package".

#### Sentences (STE section 4)

- **4.1** Write short and clear sentences. Give one topic in each sentence. Give accurate
  facts, not abstract statements. For example, do not write "Large inputs change the run
  time". Write "When the input has more than 1,000 rows, the run time increases".
- **4.2** Do not omit words to make a sentence shorter. Do not omit articles, verbs, or
  subjects. Do not use contractions. Write "do not", not "don't".
- **4.3** Use a vertical list for complex text.
- **4.4** Use connecting words to connect related sentences, for example "and", "but",
  "then", "thus", and "as a result".
- **4.5** When applicable, put "the", "a", "an", "this", or "these" before a noun.

#### Instructions (STE section 5)

STE calls this type of text a procedure.

- **5.1** Write a maximum of 20 words in each instruction.
- **5.2** Write only one instruction in each sentence, unless the actions occur at the
  same time.
- **5.3** Write instructions in the imperative: "Run the tests."
- **5.4** If the reader must know a condition first, start with the condition. Put a comma
  after the condition: "If the tests fail, stop."
- **5.5** Use a note only to give information, not to give an instruction.

#### Descriptive text (STE section 6)

Descriptive text gives information, not instructions. Do not use the imperative in
descriptive text.

- **6.1** Give information gradually. Give the primary point first, then the details.
- **6.2** Use key words and headings to show the structure of the text.
- **6.3** Write a maximum of 25 words in each descriptive sentence.
- **6.4 to 6.6** Use paragraphs to show related information. Give each paragraph only one
  topic. Write a maximum of six sentences in each paragraph.

#### Safety instructions (STE section 7)

In software, a safety instruction tells the reader about an action that can cause loss of
data or other damage. Examples are a force push, a deleted table, and a message to other
persons.

- **7.1** Start with a word that shows the level of risk. Write "Warning" for a risk to
  persons. Write "Caution" for a risk to data or equipment.
- **7.2** Then give a clear command or condition.
- **7.3** Then give the risk or the possible result.

For example: "Caution: Do not force push to a shared branch. A force push can erase the
commits of other persons."

#### Punctuation and word count (STE section 8)

- **8.1** Do not use the semicolon. Write two sentences.
- **8.2** Use a hyphen to join words that are directly related, for example "read-only".
- **8.3** Use parentheses for references, identifiers, abbreviations, short explanations,
  and alternatives.
- **8.4** In a vertical list, a colon ends a sentence for the word count.
- **8.5 to 8.7** For the word count, count each of these items as one word:
  - Text in parentheses.
  - A number, or a number with its unit.
  - An abbreviation or an identifier.
  - Quoted text.
  - A title or a heading.
  - A proper noun.
  - A hyphenated word.

#### Writing practices (STE section 9)

- **9.1** If you cannot replace a word with an approved word, write the sentence again
  with a different structure.
- **9.2** Use each word correctly.
- **9.3** Do not use phrasal verbs. For example, write "prepare" or "configure", not "set
  up". Write "find", not "find out".
- **9.4** Use the same terms and the same style in all of the text.

#### General recommendations (STE)

- **GR-1** Write "that" after verbs such as "make sure", "show", and "recommend". For
  example: "Make sure that the tests pass."
- **GR-2** When you use "with", read the sentence again. Make sure that the sentence has
  only one meaning.
- **GR-3, GR-4** If a pronoun can refer to more than one noun, write the noun. The
  local-references rule in Part 2 makes this rule stricter.
- **GR-6** Do not use Latin abbreviations. Write "for example", not "e.g.". Write "that
  is", not "i.e.". Do not write "etc.".
- **GR-7** Use gender-neutral language. Use "they" for a person whose pronouns you do not
  know.
- **GR-8** Use the possessive form, for example "the user's file", only when you are sure
  that it is correct.

### Part 2: Two more rules

These two rules apply together with the STE rules.

#### The local-references rule

The reader must not look back far to find what a word refers to.

- A pronoun ("it", "they", "this", "that", "these", "those") must refer to a noun in the
  same paragraph. A short noun, for example "the file" or "the change", must also refer
  to a noun in the same paragraph.
- Only one noun in that paragraph can match the reference. If two nouns can match, write
  the full noun.
- At the start of a paragraph, a list item, a table cell, or a reply, write the full noun.
  Do not use "It", "This", or "They" to refer to an earlier paragraph.
- A heading does not give a noun to the text below the heading. Under the heading
  "OutboxAccess", do not start with "It stores". Write "OutboxAccess stores".
- In a conversation, each reply must make sense alone. Do not write "the PR" or "the
  second option" to refer to an earlier reply. Write the name or the full description.

For example, do not write: "The run found a problem in the template and in the checker.
It is now correct." Write: "The run found a problem in the template and in the checker. I
corrected the template."

#### The described-IDs rule

An ID is a short code that names an item, for example "B2", "R3", "V1", "UC2", "PR #6",
"task #4", or a commit hash. An ID without a description makes the reader look back.

- Each time that you write an ID, write a short description of the item in the same
  sentence. For example: "B2 (cache the results)".
- When the reader must select an alternative, give each alternative its ID and its
  description in the question. Do not ask "B1, B2, or B3?".
- In a table, a row that gives the ID and the description is sufficient for that row.
- A header field, for example `Intent: IN-0001`, holds only the ID. Do not add a
  description to the ID there.
- Make each description short and simple: two to eight words.
- If the ID is not necessary for the reader, do not use the ID. Use the description only.

For example, do not write: "Do you want B1 or B3?" Write: "Do you want B1 (keep the
cache) or B3 (remove the cache)?"

### Part 3: How to apply the rules

#### Replies to the user

- Give the answer or the result first. Then give the details.
- Use plain words, and give the context that the reader must have.
- Use short sentences. Use a list for three or more items. Do not write a paragraph when
  sentences in a list are sufficient.
- Write only about the topic. Do not add text that does not relate to the topic.
- Make each reply clear alone. Obey the local-references rule.
- When you ask a question with alternatives, obey the described-IDs rule.

#### Skills, agent definitions, and prompts

- If a skill gives an exact output format, the format has priority over these
  guidelines. For example, a skill can tell an agent to write one sentence for each
  option. Then the agent writes one sentence, also when the sentence has two topics.
- Write each step in the imperative. Write one instruction in each sentence.
- Put the condition first: "If the suite exists, load the suite."
- Give numbers to the steps of a procedure.
- Write the purpose of a skill, and other descriptive text, with the descriptive rules.
- In the `description` of a skill, keep the name and the trigger phrases of the skill.
  Do not change these quoted phrases. Write the other text of the description with the
  rules.
- A prompt for a different agent must make sense alone, because that agent does not see
  your conversation.

#### Documents and artifacts

- Start each section with its primary point.
- Use headings as key words.
- Give each technical noun that a reader possibly does not know in a "Words used here"
  list. Use one line for each word.
- Use a table to compare items. Use a list for steps and alternatives.

#### Commit messages and pull requests

- Write the subject line of a commit in the imperative, for example "Add the linter".
- Write the body as descriptive text.

### Part 4: Examine your text

1. Run the linter: `python check_writing.py FILE`. The linter is in the `scripts` folder of
   the `improve-writing` skill. The linter finds the problems that a script can measure.
2. To examine words against the STE dictionary, get the standard. The standard is free
   from <https://www.asd-ste100.org>. Then give the linter your copy:
   `--dictionary PATH`. The path can be the PDF file or a text file of the PDF.
3. Read the text again for the rules that a script cannot measure. Examples are one topic
   in each sentence, the local-references rule, and accurate facts.

The `/improve-writing` skill does these three steps and writes the text again.

### Source

- ASD-STE100 Simplified Technical English, Issue 9, 2025-01-15, by ASD (the Aerospace,
  Security and Defence Industries Association of Europe). Part 1 gives the rules of the
  standard in short form, with the rule numbers of the standard.
- The standard is free from <https://www.asd-ste100.org>. ASD does not let other persons
  distribute the standard. Thus, this file does not contain the text of the standard or
  its dictionary.
- ASD-STE100 is a registered trademark of ASD.
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

### Diff against pdlc/CH-0005-forecast

````
diff --git a/StoragePolicySim/Forecast.lean b/StoragePolicySim/Forecast.lean
index c6d7459..3370be2 100644
--- a/StoragePolicySim/Forecast.lean
+++ b/StoragePolicySim/Forecast.lean
@@ -1,8 +1,9 @@
 /-
 The simulated Solcast forecast of a scenario. A fetch gives periods with an error that grows
-with the lead time. The module also gives the fetch hours of a day, the forecast energy of
-each coming hour, and the Solcast JSON. CAP-forecast (simulated Solcast forecasts for
-policies) gives the rules.
+with the lead time. The periods of one day share a part of their error. A caller that fetches
+many times builds the hours of the scenario once, and gives them to `forecastOf`. The module
+also gives the fetch hours of a day, the forecast energy of each coming hour, and the Solcast
+JSON. CAP-forecast (simulated Solcast forecasts for policies) gives the rules.
 -/
 import StoragePolicySim.Scenario
 
@@ -41,6 +42,12 @@ private def spreadPerDay : Float := 0.10
 curve. -/
 private def bandSpreadFactor : Float := 1.28
 
+/-- The part of the variance of the error that the periods of one day share. -/
+private def sharedShare : Float := 0.7
+
+/-- The part of the variance of the error that belongs to one period. -/
+private def ownShare : Float := 0.3
+
 /-! ## Random numbers -/
 
 /-- Two times pi. -/
@@ -57,13 +64,29 @@ private def mix (x : UInt64) : UInt64 :=
 private def unitFloat (x : UInt64) : Float :=
   ((x >>> 11).toFloat + 1) / 9007199254740992.0
 
-/-- A number from a normal curve (Box-Muller). It depends only on the seed, the fetch hour
-and the period. -/
-private def normalDraw (seed fetchHour period : Nat) : Float :=
-  let key := mix (mix (mix seed.toUInt64 + fetchHour.toUInt64) + period.toUInt64)
+/-- A number from a normal curve (Box-Muller). It depends only on the key. -/
+private def normalOfKey (key : UInt64) : Float :=
   let radius := Float.sqrt (-2 * Float.log (unitFloat (mix key)))
   radius * Float.cos (twoPi * unitFloat (mix (key + 1)))
 
+/-- The part of the error that belongs to one period. It depends only on the seed, the fetch
+hour and the period. -/
+private def periodDraw (seed fetchHour period : Nat) : Float :=
+  normalOfKey (mix (mix (mix seed.toUInt64 + fetchHour.toUInt64) + period.toUInt64))
+
+/-- The number that tells the draws of a day apart from the draws of a period. -/
+private def dayStream : UInt64 := 0xDA7
+
+/-- The part of the error that the periods of one day share. It depends only on the seed and
+the day of the run. -/
+private def dayDraw (seed day : Nat) : Float :=
+  normalOfKey (mix (mix (mix (mix seed.toUInt64) + dayStream) + day.toUInt64))
+
+/-- The random number of a period. It has a variance of 1. It adds the shared
+part of its day and the part of the period. -/
+private def normalDraw (seed fetchHour period day : Nat) : Float :=
+  Float.sqrt sharedShare * dayDraw seed day + Float.sqrt ownShare * periodDraw seed fetchHour period
+
 /-! ## Forecast -/
 
 /-- A power, cut to the range from 0 to the power of the panels. -/
@@ -71,27 +94,38 @@ private def cutToPanels (site : Site) (kw : Float) : Float := max 0 (min site.pv
 
 /-- Period `k` of the fetch at `fetchHour`, for `k` from 1. The `hours` are the hours of the
 scenario. The spread is 0.05 plus 0.10 for each 24 hours of lead time, times the error
-scale. -/
+scale. The random number shares a part with the other periods that end in the same day of the
+run. -/
 private def periodOf (site : Site) (hours : Array Hour) (seed : Nat) (errorScale : Float)
     (fetchHour k : Nat) : Period :=
   let endMinute := 60 * fetchHour + periodMinutes * k
   let leadHours := (periodMinutes * k).toFloat / 60
   let scaledSpread := errorScale * (baseSpread + spreadPerDay * leadHours / 24)
   let actualKw := hours[hourOfPeriod endMinute]!.pvKwh
-  let estimateKw := cutToPanels site (actualKw * (1 + scaledSpread * normalDraw seed fetchHour k))
+  let day := hourOfPeriod endMinute / 24
+  let estimateKw :=
+    cutToPanels site (actualKw * (1 + scaledSpread * normalDraw seed fetchHour k day))
   { endMinute, estimateKw,
     p10Kw := cutToPanels site (estimateKw * (1 - bandSpreadFactor * scaledSpread)),
     p90Kw := cutToPanels site (estimateKw * (1 + bandSpreadFactor * scaledSpread)) }
 
+/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
+`hours` are the hours of `scenario site seed days`, built once by the caller. The run has
+`hours.size / 24` days. The array is empty when the fetch is not inside the run. The same
+arguments give the same periods. -/
+def forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float)
+    (fetchHour : Nat) : Array Period :=
+  let periodsLeft := (24 * (hours.size / 24) - fetchHour) * 60 / periodMinutes
+  let periodCount := min (horizonHours * 60 / periodMinutes) periodsLeft
+  (Array.range periodCount).map (fun i => periodOf site hours seed errorScale fetchHour (i + 1))
+
 /-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
 array is empty when the fetch is not inside the run. The same arguments give the same
-periods. -/
+periods. The call builds the scenario again: a caller that fetches many times uses
+`forecastOf`. -/
 def forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) :
     Array Period :=
-  let hours := scenario site seed days
-  let periodsLeft := (24 * days - fetchHour) * 60 / periodMinutes
-  let periodCount := min (horizonHours * 60 / periodMinutes) periodsLeft
-  (Array.range periodCount).map (fun i => periodOf site hours seed errorScale fetchHour (i + 1))
+  forecastOf (scenario site seed days) site seed errorScale fetchHour
 
 /-! ## Fetch limit -/
````

### StoragePolicySim/Forecast.lean

````
/-
The simulated Solcast forecast of a scenario. A fetch gives periods with an error that grows
with the lead time. The periods of one day share a part of their error. A caller that fetches
many times builds the hours of the scenario once, and gives them to `forecastOf`. The module
also gives the fetch hours of a day, the forecast energy of each coming hour, and the Solcast
JSON. CAP-forecast (simulated Solcast forecasts for policies) gives the rules.
-/
import StoragePolicySim.Scenario

namespace StoragePolicySim

/-- One period of a fetch. Each power is the mean power of the period in kW. -/
structure Period where
  /-- The end of the period, in minutes from the start of the run. -/
  endMinute : Nat
  /-- The forecast power. -/
  estimateKw : Float
  /-- The 10% band: the actual power is below this value one time in ten. -/
  p10Kw : Float
  /-- The 90% band: the actual power is below this value nine times in ten. -/
  p90Kw : Float
  deriving Repr, Inhabited

/-! ## Periods -/

/-- The length of a period in minutes. -/
private def periodMinutes : Nat := 30

/-- The hours that a fetch looks ahead. -/
private def horizonHours : Nat := 48

/-- The hour of the run in which a period lies, from the end of the period. -/
private def hourOfPeriod (endMinute : Nat) : Nat := (endMinute - periodMinutes) / 60

/-- The spread of the error at a lead time of 0 hours. -/
private def baseSpread : Float := 0.05

/-- The growth of the spread for each 24 hours of lead time. -/
private def spreadPerDay : Float := 0.10

/-- The distance of a band from the estimate, in spreads. It is the 10% point of a normal
curve. -/
private def bandSpreadFactor : Float := 1.28

/-- The part of the variance of the error that the periods of one day share. -/
private def sharedShare : Float := 0.7

/-- The part of the variance of the error that belongs to one period. -/
private def ownShare : Float := 0.3

/-! ## Random numbers -/

/-- Two times pi. -/
private def twoPi : Float := 6.283185307179586

/-- The SplitMix64 steps: a well-mixed number from a number. -/
private def mix (x : UInt64) : UInt64 :=
  let s := x + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  z ^^^ (z >>> 31)

/-- A number above 0 and up to 1 from the top 53 bits of a number. -/
private def unitFloat (x : UInt64) : Float :=
  ((x >>> 11).toFloat + 1) / 9007199254740992.0

/-- A number from a normal curve (Box-Muller). It depends only on the key. -/
private def normalOfKey (key : UInt64) : Float :=
  let radius := Float.sqrt (-2 * Float.log (unitFloat (mix key)))
  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))

/-- The part of the error that belongs to one period. It depends only on the seed, the fetch
hour and the period. -/
private def periodDraw (seed fetchHour period : Nat) : Float :=
  normalOfKey (mix (mix (mix seed.toUInt64 + fetchHour.toUInt64) + period.toUInt64))

/-- The number that tells the draws of a day apart from the draws of a period. -/
private def dayStream : UInt64 := 0xDA7

/-- The part of the error that the periods of one day share. It depends only on the seed and
the day of the run. -/
private def dayDraw (seed day : Nat) : Float :=
  normalOfKey (mix (mix (mix (mix seed.toUInt64) + dayStream) + day.toUInt64))

/-- The random number of a period. It has a variance of 1. It adds the shared
part of its day and the part of the period. -/
private def normalDraw (seed fetchHour period day : Nat) : Float :=
  Float.sqrt sharedShare * dayDraw seed day + Float.sqrt ownShare * periodDraw seed fetchHour period

/-! ## Forecast -/

/-- A power, cut to the range from 0 to the power of the panels. -/
private def cutToPanels (site : Site) (kw : Float) : Float := max 0 (min site.pvKw kw)

/-- Period `k` of the fetch at `fetchHour`, for `k` from 1. The `hours` are the hours of the
scenario. The spread is 0.05 plus 0.10 for each 24 hours of lead time, times the error
scale. The random number shares a part with the other periods that end in the same day of the
run. -/
private def periodOf (site : Site) (hours : Array Hour) (seed : Nat) (errorScale : Float)
    (fetchHour k : Nat) : Period :=
  let endMinute := 60 * fetchHour + periodMinutes * k
  let leadHours := (periodMinutes * k).toFloat / 60
  let scaledSpread := errorScale * (baseSpread + spreadPerDay * leadHours / 24)
  let actualKw := hours[hourOfPeriod endMinute]!.pvKwh
  let day := hourOfPeriod endMinute / 24
  let estimateKw :=
    cutToPanels site (actualKw * (1 + scaledSpread * normalDraw seed fetchHour k day))
  { endMinute, estimateKw,
    p10Kw := cutToPanels site (estimateKw * (1 - bandSpreadFactor * scaledSpread)),
    p90Kw := cutToPanels site (estimateKw * (1 + bandSpreadFactor * scaledSpread)) }

/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
`hours` are the hours of `scenario site seed days`, built once by the caller. The run has
`hours.size / 24` days. The array is empty when the fetch is not inside the run. The same
arguments give the same periods. -/
def forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float)
    (fetchHour : Nat) : Array Period :=
  let periodsLeft := (24 * (hours.size / 24) - fetchHour) * 60 / periodMinutes
  let periodCount := min (horizonHours * 60 / periodMinutes) periodsLeft
  (Array.range periodCount).map (fun i => periodOf site hours seed errorScale fetchHour (i + 1))

/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
array is empty when the fetch is not inside the run. The same arguments give the same
periods. The call builds the scenario again: a caller that fetches many times uses
`forecastOf`. -/
def forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) :
    Array Period :=
  forecastOf (scenario site seed days) site seed errorScale fetchHour

/-! ## Fetch limit -/

/-- The hour of the day of each fetch. Fetch `i` of `n` is at hour `i × 24 / n`, rounded
down. -/
def fetchHours (fetchesPerDay : Nat) : Array Nat :=
  (Array.range fetchesPerDay).map (fun i => i * 24 / fetchesPerDay)

/-- The hour of the run of the latest fetch at or before `hour`. -/
def latestFetch (fetchesPerDay hour : Nat) : Nat :=
  let hourOfDay := hour % 24
  let latestHourOfDay := (fetchHours fetchesPerDay).foldl
    (fun latest h => if h ≤ hourOfDay then max latest h else latest) 0
  24 * (hour / 24) + latestHourOfDay

/-! ## Hourly energy -/

/-- The forecast solar energy of the hours `fetchHour` to `fetchHour + 47` in kWh. Each value is
the energy of the estimates of the periods of its hour. An hour with no period is 0. -/
def hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float :=
  periods.foldl (init := Array.replicate horizonHours 0.0) fun energy p =>
    energy.modify (hourOfPeriod p.endMinute - fetchHour)
      (· + p.estimateKw * periodMinutes.toFloat / 60)

/-! ## Solcast JSON -/

/-- The text of a number, with zeros at the front up to the given width. -/
private def zeroPadded (width n : Nat) : String :=
  let digits := toString n
  "".pushn '0' (width - digits.length) ++ digits

/-- A power as text, rounded to four decimals. -/
private def fourDecimals (kw : Float) : String :=
  let tenThousandths := (kw * 10000).round.toUInt64.toNat
  toString (tenThousandths / 10000) ++ "." ++ zeroPadded 4 (tenThousandths % 10000)

/-- The year of the first day of the run. -/
private def startYear : Nat := 2025

/-- The days of each month. As in the scenario, each year of the run has 365 days. -/
private def monthDays : Array Nat := #[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

/-- The month and the day of the month, both from 1, for a day of the year from 0. -/
private def monthAndDay (dayOfYear : Nat) : Nat × Nat := Id.run do
  let mut month := 1
  let mut day := dayOfYear
  for length in monthDays do
    if day < length then break
    day := day - length
    month := month + 1
  return (month, day + 1)

/-- The UTC time of the end of a period, as `2025-01-01T00:30:00.0000000Z`. The UTC time is
the solar time less the longitude divided by 15 hours, rounded to the nearest 30 minutes. A tie
rounds up. -/
private def utcTime (longitude : Float) (endMinute : Nat) : String :=
  let solarMinute := endMinute.toFloat - 4 * longitude
  let utcMinute : Int := 30 * (Float.floor (solarMinute / 30 + 0.5)).toInt64.toInt
  let day := utcMinute / 1440
  let minuteOfDay := (utcMinute % 1440).toNat
  let (month, dayOfMonth) := monthAndDay (day % daysInYear).toNat
  zeroPadded 4 ((startYear + day / daysInYear : Int).toNat) ++ "-" ++ zeroPadded 2 month ++ "-" ++
    zeroPadded 2 dayOfMonth ++ "T" ++ zeroPadded 2 (minuteOfDay / 60) ++ ":" ++
    zeroPadded 2 (minuteOfDay % 60) ++ ":00.0000000Z"

/-- One period as the Solcast text. -/
private def periodJson (longitude : Float) (p : Period) : String :=
  "{\"pv_estimate\":" ++ fourDecimals p.estimateKw ++
    ",\"pv_estimate10\":" ++ fourDecimals p.p10Kw ++
    ",\"pv_estimate90\":" ++ fourDecimals p.p90Kw ++
    ",\"period_end\":\"" ++ utcTime longitude p.endMinute ++ "\",\"period\":\"PT30M\"}"

/-- The Solcast reply for the periods of a fetch, as one line of text. The longitude is in
degrees, and east is positive. -/
def forecastJson (periods : Array Period) (longitude : Float) : String :=
  "{\"forecasts\":[" ++ ",".intercalate (periods.toList.map (periodJson longitude)) ++ "]}"

end StoragePolicySim
````

## Writing check

`pdlc/bin/check_writing.py --since bde71c519e8061afa20631cd573ed28e0e4900f9` on pdlc/changes/CH-0006-forecast-fast/change.md, pdlc/specs/capabilities/CAP-forecast.md, pdlc/specs/capabilities/CAP-homesim.md, pdlc/specs/capabilities/CAP-hotwater.md, pdlc/specs/capabilities/CAP-policy.md, pdlc/specs/capabilities/CAP-simulation.md, pdlc/specs/capabilities/CAP-strategies.md, pdlc/specs/design/DES-errors.md, pdlc/specs/jobs/JOB-simulate.md:

````
No findings.
````

