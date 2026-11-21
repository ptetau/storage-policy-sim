# Review packet · CH-0005-forecast · privacy

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: d9a8949e5769021532001b690ad12a9a359c8cbc

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
# CH-0005 · Simulated Solcast forecast

Intent: IN-0002 · Scope: CAP-forecast · Status: building · Ticket: none · Branch: pdlc/CH-0005-forecast · Base: pdlc/CH-0004-sim-command

Tests-Locked: acceptance

## Delivers

The library makes a simulated Solcast rooftop forecast for a scenario. Each fetch has periods with growing error and bands. The library also gives the fetch hours of a day, the hourly forecast energy that a policy reads, and the Solcast JSON.

## Requirements

### CAP-forecast.R1 · Forecast periods
- Given a fetch at hour 0, when the forecast is made, then it has 96 periods. Their ends are 30, 60, and up to 2880 minutes.
- Given a fetch at hour 100, when the forecast is made, then the first period ends at 6030 minutes and the last at 8880 minutes.
- Given a fetch at hour 8750, when the forecast is made, then it has 20 periods, because the run ends after 10 hours.
- Given a fetch at hour 8760, when the forecast is made, then it has no period.
- Given a daily fetch at 00:00, when the forecasts are made, then no 10% band is above its estimate. No estimate is above its 90% band.
- Given a daily fetch at 00:00, when the forecasts are made, then each value is from 0 to 5 kW.
- Given a fetch at hour 0, when the forecast is made, then each period with no actual power has 0 kW in all three values.

### CAP-forecast.R2 · Forecast error
- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given seed 7, when the same fetch is made two times, then the two forecasts are the same.
- Given seeds 7 and 8, when a fetch at hour 4000 is made with each, then at least one estimate differs.
- Given daily fetches, when sunny periods are compared, then the error 24 to 48 hours ahead is more than 0 to 4 hours ahead.
- Given a daily fetch at 00:00, when the forecasts are made, then 60% to 95% of sunny periods have the actual power in the band.

### CAP-forecast.R3 · Fetch limit
- Given 10 fetches a day, when the fetch hours are found, then they are 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21.
- Given 3 fetches a day, when the fetch hours are found, then they are 0, 8 and 16.
- Given 1 fetch a day, when the fetch hours are found, then the only hour is 0.
- Given 10 fetches a day, when the latest fetch for hour 27 is found, then it is the fetch at hour 26.
- Given 10 fetches a day, when the latest fetch for hour 26 is found, then it is the fetch at hour 26. The latest fetch for hour 25 is at hour 24.
- Given 1 fetch a day, when the latest fetch for hour 47 is found, then it is the fetch at hour 24.

### CAP-forecast.R4 · Solcast JSON
- Given longitude 0 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T00:30:00.0000000Z`.
- Given longitude 174.8 and a fetch at hour 0, when the JSON is made, then the first period ends at `2024-12-31T13:00:00.0000000Z`.
- Given longitude -75 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T05:30:00.0000000Z`.
- Given longitude 0 and a fetch at hour 8759, when the JSON is made, then the last period ends at `2026-01-01T00:00:00.0000000Z`.
- Given an error scale of 0 and a fetch at hour 4116, when the JSON is made, then each `pv_estimate` has four decimals.
- Given a fetch at hour 0, when the JSON is made, then each period has the five fields in the order above, and `"period":"PT30M"`.

### CAP-forecast.R5 · Hourly forecast energy
- Given an error scale of 0 and a fetch at hour 0, when the hourly energy is made, then value `j` equals the solar output of hour `j` of the scenario for `j` from 0 to 47. The tolerance is 0.000001 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then it has 48 values, each from 0 to 5 kWh.
- Given a fetch at hour 8750, when the hourly energy is made, then it has 48 values. Values 10 to 47 are 0 kWh.
- Given a fetch at hour 8760, when the hourly energy is made, then it has 48 values, each 0 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then the sum of the 48 values is 0.5 times the sum of the estimates of the 96 periods. The tolerance is 0.000001 kWh.

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

- none

## Steps

### Step 1 · Forecast periods · [x]

- Requirement: CAP-forecast.R1
- Check: the checks named `CAP-forecast.R1 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 2 · Forecast error · [x]

- Requirement: CAP-forecast.R2
- Check: the checks named `CAP-forecast.R2 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 3 · Fetch limit · [x]

- Requirement: CAP-forecast.R3
- Check: the checks named `CAP-forecast.R3 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 4 · Solcast JSON · [x]

- Requirement: CAP-forecast.R4
- Check: the checks named `CAP-forecast.R4 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 5 · Hourly forecast energy · [x]

- Requirement: CAP-forecast.R5
- Check: the checks named `CAP-forecast.R5 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned as the only change of IN-0002 (Solcast forecast). The policies of IN-0008 (hot-water policy simulation) read it.
- Build: the 57 acceptance checks of IN-0002 pass, with the earlier files. No check changed since the lock.
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

- `Period` · type · `StoragePolicySim/Forecast.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `fetchHours (fetchesPerDay : Nat) : Array Nat` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: the fetches of one day, from 1 to 10
  - out: the hour of the day of each fetch, in order
  - errors: none
- `latestFetch (fetchesPerDay hour : Nat) : Nat` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: the fetches of one day, from 1 to 10, and an hour of the run
  - out: the hour of the run of the latest fetch at or before that hour
  - errors: none
- `hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: the periods of a fetch, and the hour of that fetch
  - out: 48 values in kWh. Value `j` is the forecast solar energy of hour `fetchHour + j` of the run.
  - errors: none
- `forecastJson (periods : Array Period) (longitude : Float) : String` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: the periods of a fetch, and a longitude in degrees, east is positive
  - out: the Solcast reply as one line of JSON text
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Forecast.lean` · proposed
  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
  - errors: none
````

## The requirements, in full

### CAP-forecast.R1 · Forecast periods

Status: built · Intents: IN-0002

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

Status: built · Intents: IN-0002

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

Status: built · Intents: IN-0002

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

Status: built · Intents: IN-0002

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

Status: built · Intents: IN-0002

A policy reads a fetch as the forecast solar energy of each coming hour. Value `j` is the
estimate of the first period of hour `fetchHour + j`, plus the estimate of the second, each
times 0.5 hours. The array always has 48 values. An hour with no period in the fetch has the
value 0 (assumed).

- Given an error scale of 0 and a fetch at hour 0, when the hourly energy is made, then value `j` equals the solar output of hour `j` of the scenario for `j` from 0 to 47. The tolerance is 0.000001 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then it has 48 values, each from 0 to 5 kWh.
- Given a fetch at hour 8750, when the hourly energy is made, then it has 48 values. Values 10 to 47 are 0 kWh.
- Given a fetch at hour 8760, when the hourly energy is made, then it has 48 values, each 0 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then the sum of the 48 values is 0.5 times the sum of the estimates of the 96 periods. The tolerance is 0.000001 kWh.

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

### Diff against pdlc/CH-0004-sim-command

````
diff --git a/StoragePolicySim/Forecast.lean b/StoragePolicySim/Forecast.lean
new file mode 100644
index 0000000..c6d7459
--- /dev/null
+++ b/StoragePolicySim/Forecast.lean
@@ -0,0 +1,172 @@
+/-
+The simulated Solcast forecast of a scenario. A fetch gives periods with an error that grows
+with the lead time. The module also gives the fetch hours of a day, the forecast energy of
+each coming hour, and the Solcast JSON. CAP-forecast (simulated Solcast forecasts for
+policies) gives the rules.
+-/
+import StoragePolicySim.Scenario
+
+namespace StoragePolicySim
+
+/-- One period of a fetch. Each power is the mean power of the period in kW. -/
+structure Period where
+  /-- The end of the period, in minutes from the start of the run. -/
+  endMinute : Nat
+  /-- The forecast power. -/
+  estimateKw : Float
+  /-- The 10% band: the actual power is below this value one time in ten. -/
+  p10Kw : Float
+  /-- The 90% band: the actual power is below this value nine times in ten. -/
+  p90Kw : Float
+  deriving Repr, Inhabited
+
+/-! ## Periods -/
+
+/-- The length of a period in minutes. -/
+private def periodMinutes : Nat := 30
+
+/-- The hours that a fetch looks ahead. -/
+private def horizonHours : Nat := 48
+
+/-- The hour of the run in which a period lies, from the end of the period. -/
+private def hourOfPeriod (endMinute : Nat) : Nat := (endMinute - periodMinutes) / 60
+
+/-- The spread of the error at a lead time of 0 hours. -/
+private def baseSpread : Float := 0.05
+
+/-- The growth of the spread for each 24 hours of lead time. -/
+private def spreadPerDay : Float := 0.10
+
+/-- The distance of a band from the estimate, in spreads. It is the 10% point of a normal
+curve. -/
+private def bandSpreadFactor : Float := 1.28
+
+/-! ## Random numbers -/
+
+/-- Two times pi. -/
+private def twoPi : Float := 6.283185307179586
+
+/-- The SplitMix64 steps: a well-mixed number from a number. -/
+private def mix (x : UInt64) : UInt64 :=
+  let s := x + 0x9E3779B97F4A7C15
+  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
+  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
+  z ^^^ (z >>> 31)
+
+/-- A number above 0 and up to 1 from the top 53 bits of a number. -/
+private def unitFloat (x : UInt64) : Float :=
+  ((x >>> 11).toFloat + 1) / 9007199254740992.0
+
+/-- A number from a normal curve (Box-Muller). It depends only on the seed, the fetch hour
+and the period. -/
+private def normalDraw (seed fetchHour period : Nat) : Float :=
+  let key := mix (mix (mix seed.toUInt64 + fetchHour.toUInt64) + period.toUInt64)
+  let radius := Float.sqrt (-2 * Float.log (unitFloat (mix key)))
+  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))
+
+/-! ## Forecast -/
+
+/-- A power, cut to the range from 0 to the power of the panels. -/
+private def cutToPanels (site : Site) (kw : Float) : Float := max 0 (min site.pvKw kw)
+
+/-- Period `k` of the fetch at `fetchHour`, for `k` from 1. The `hours` are the hours of the
+scenario. The spread is 0.05 plus 0.10 for each 24 hours of lead time, times the error
+scale. -/
+private def periodOf (site : Site) (hours : Array Hour) (seed : Nat) (errorScale : Float)
+    (fetchHour k : Nat) : Period :=
+  let endMinute := 60 * fetchHour + periodMinutes * k
+  let leadHours := (periodMinutes * k).toFloat / 60
+  let scaledSpread := errorScale * (baseSpread + spreadPerDay * leadHours / 24)
+  let actualKw := hours[hourOfPeriod endMinute]!.pvKwh
+  let estimateKw := cutToPanels site (actualKw * (1 + scaledSpread * normalDraw seed fetchHour k))
+  { endMinute, estimateKw,
+    p10Kw := cutToPanels site (estimateKw * (1 - bandSpreadFactor * scaledSpread)),
+    p90Kw := cutToPanels site (estimateKw * (1 + bandSpreadFactor * scaledSpread)) }
+
+/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
+array is empty when the fetch is not inside the run. The same arguments give the same
+periods. -/
+def forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) :
+    Array Period :=
+  let hours := scenario site seed days
+  let periodsLeft := (24 * days - fetchHour) * 60 / periodMinutes
+  let periodCount := min (horizonHours * 60 / periodMinutes) periodsLeft
+  (Array.range periodCount).map (fun i => periodOf site hours seed errorScale fetchHour (i + 1))
+
+/-! ## Fetch limit -/
+
+/-- The hour of the day of each fetch. Fetch `i` of `n` is at hour `i × 24 / n`, rounded
+down. -/
+def fetchHours (fetchesPerDay : Nat) : Array Nat :=
+  (Array.range fetchesPerDay).map (fun i => i * 24 / fetchesPerDay)
+
+/-- The hour of the run of the latest fetch at or before `hour`. -/
+def latestFetch (fetchesPerDay hour : Nat) : Nat :=
+  let hourOfDay := hour % 24
+  let latestHourOfDay := (fetchHours fetchesPerDay).foldl
+    (fun latest h => if h ≤ hourOfDay then max latest h else latest) 0
+  24 * (hour / 24) + latestHourOfDay
+
+/-! ## Hourly energy -/
+
+/-- The forecast solar energy of the hours `fetchHour` to `fetchHour + 47` in kWh. Each value is
+the energy of the estimates of the periods of its hour. An hour with no period is 0. -/
+def hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float :=
+  periods.foldl (init := Array.replicate horizonHours 0.0) fun energy p =>
+    energy.modify (hourOfPeriod p.endMinute - fetchHour)
+      (· + p.estimateKw * periodMinutes.toFloat / 60)
+
+/-! ## Solcast JSON -/
+
+/-- The text of a number, with zeros at the front up to the given width. -/
+private def zeroPadded (width n : Nat) : String :=
+  let digits := toString n
+  "".pushn '0' (width - digits.length) ++ digits
+
+/-- A power as text, rounded to four decimals. -/
+private def fourDecimals (kw : Float) : String :=
+  let tenThousandths := (kw * 10000).round.toUInt64.toNat
+  toString (tenThousandths / 10000) ++ "." ++ zeroPadded 4 (tenThousandths % 10000)
+
+/-- The year of the first day of the run. -/
+private def startYear : Nat := 2025
+
+/-- The days of each month. As in the scenario, each year of the run has 365 days. -/
+private def monthDays : Array Nat := #[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
+
+/-- The month and the day of the month, both from 1, for a day of the year from 0. -/
+private def monthAndDay (dayOfYear : Nat) : Nat × Nat := Id.run do
+  let mut month := 1
+  let mut day := dayOfYear
+  for length in monthDays do
+    if day < length then break
+    day := day - length
+    month := month + 1
+  return (month, day + 1)
+
+/-- The UTC time of the end of a period, as `2025-01-01T00:30:00.0000000Z`. The UTC time is
+the solar time less the longitude divided by 15 hours, rounded to the nearest 30 minutes. A tie
+rounds up. -/
+private def utcTime (longitude : Float) (endMinute : Nat) : String :=
+  let solarMinute := endMinute.toFloat - 4 * longitude
+  let utcMinute : Int := 30 * (Float.floor (solarMinute / 30 + 0.5)).toInt64.toInt
+  let day := utcMinute / 1440
+  let minuteOfDay := (utcMinute % 1440).toNat
+  let (month, dayOfMonth) := monthAndDay (day % daysInYear).toNat
+  zeroPadded 4 ((startYear + day / daysInYear : Int).toNat) ++ "-" ++ zeroPadded 2 month ++ "-" ++
+    zeroPadded 2 dayOfMonth ++ "T" ++ zeroPadded 2 (minuteOfDay / 60) ++ ":" ++
+    zeroPadded 2 (minuteOfDay % 60) ++ ":00.0000000Z"
+
+/-- One period as the Solcast text. -/
+private def periodJson (longitude : Float) (p : Period) : String :=
+  "{\"pv_estimate\":" ++ fourDecimals p.estimateKw ++
+    ",\"pv_estimate10\":" ++ fourDecimals p.p10Kw ++
+    ",\"pv_estimate90\":" ++ fourDecimals p.p90Kw ++
+    ",\"period_end\":\"" ++ utcTime longitude p.endMinute ++ "\",\"period\":\"PT30M\"}"
+
+/-- The Solcast reply for the periods of a fetch, as one line of text. The longitude is in
+degrees, and east is positive. -/
+def forecastJson (periods : Array Period) (longitude : Float) : String :=
+  "{\"forecasts\":[" ++ ",".intercalate (periods.toList.map (periodJson longitude)) ++ "]}"
+
+end StoragePolicySim
````

### StoragePolicySim/Forecast.lean

````
/-
The simulated Solcast forecast of a scenario. A fetch gives periods with an error that grows
with the lead time. The module also gives the fetch hours of a day, the forecast energy of
each coming hour, and the Solcast JSON. CAP-forecast (simulated Solcast forecasts for
policies) gives the rules.
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

/-- A number from a normal curve (Box-Muller). It depends only on the seed, the fetch hour
and the period. -/
private def normalDraw (seed fetchHour period : Nat) : Float :=
  let key := mix (mix (mix seed.toUInt64 + fetchHour.toUInt64) + period.toUInt64)
  let radius := Float.sqrt (-2 * Float.log (unitFloat (mix key)))
  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))

/-! ## Forecast -/

/-- A power, cut to the range from 0 to the power of the panels. -/
private def cutToPanels (site : Site) (kw : Float) : Float := max 0 (min site.pvKw kw)

/-- Period `k` of the fetch at `fetchHour`, for `k` from 1. The `hours` are the hours of the
scenario. The spread is 0.05 plus 0.10 for each 24 hours of lead time, times the error
scale. -/
private def periodOf (site : Site) (hours : Array Hour) (seed : Nat) (errorScale : Float)
    (fetchHour k : Nat) : Period :=
  let endMinute := 60 * fetchHour + periodMinutes * k
  let leadHours := (periodMinutes * k).toFloat / 60
  let scaledSpread := errorScale * (baseSpread + spreadPerDay * leadHours / 24)
  let actualKw := hours[hourOfPeriod endMinute]!.pvKwh
  let estimateKw := cutToPanels site (actualKw * (1 + scaledSpread * normalDraw seed fetchHour k))
  { endMinute, estimateKw,
    p10Kw := cutToPanels site (estimateKw * (1 - bandSpreadFactor * scaledSpread)),
    p90Kw := cutToPanels site (estimateKw * (1 + bandSpreadFactor * scaledSpread)) }

/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
array is empty when the fetch is not inside the run. The same arguments give the same
periods. -/
def forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) :
    Array Period :=
  let hours := scenario site seed days
  let periodsLeft := (24 * days - fetchHour) * 60 / periodMinutes
  let periodCount := min (horizonHours * 60 / periodMinutes) periodsLeft
  (Array.range periodCount).map (fun i => periodOf site hours seed errorScale fetchHour (i + 1))

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

