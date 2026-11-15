# Review packet · CH-0005-forecast · visual

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 13e9afc67c3f284106fcfa26a0a05251777f3d41

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
# CH-0005 · Simulated Solcast forecast

Intent: IN-0002 · Scope: CAP-forecast · Status: in review · Ticket: none · Branch: pdlc/CH-0005-forecast · Base: pdlc/CH-0004-sim-command

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
- Verify round 1: each remit passed. The change is `in review`.
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

### CAP-forecast.R1 · Forecast periods

Status: verified · Intents: IN-0002

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

Status: verified · Intents: IN-0002

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

Status: verified · Intents: IN-0002

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

Status: verified · Intents: IN-0002

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

Status: verified · Intents: IN-0002

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

## The script of the recording

````
{
  "kind": "terminal",
  "title": "CH-0005 \u00b7 Simulated Solcast forecast",
  "width": 1100,
  "height": 700,
  "steps": [
    {
      "caption": "CAP-forecast \u00b7 setup: build the library",
      "run": "lake build 2>&1 | tail -1"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 a fetch at hour 0 has 96 periods, ending 30, 60 and up to 2880 minutes",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-1"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 a fetch at hour 100: first period ends at 6030 minutes, last at 8880",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-2"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 a fetch at hour 8750 has 20 periods, because the run ends after 10 hours",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-3"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 a fetch at hour 8760 has no period",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-4"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 no 10% band is above its estimate, and no estimate is above its 90% band",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-5"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 each value of a daily fetch at 00:00 is from 0 to 5 kW",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-6"
    },
    {
      "caption": "CAP-forecast.R1 \u00b7 each period with no actual power has 0 kW in all three values",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r1-7"
    },
    {
      "caption": "CAP-forecast.R2 \u00b7 error scale 0: each value equals its actual power",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r2-1"
    },
    {
      "caption": "CAP-forecast.R2 \u00b7 seed 7 gives the same forecast two times",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r2-2"
    },
    {
      "caption": "CAP-forecast.R2 \u00b7 seeds 7 and 8 give a different estimate at hour 4000",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r2-3"
    },
    {
      "caption": "CAP-forecast.R2 \u00b7 the error 24 to 48 hours ahead is more than 0 to 4 hours ahead",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r2-4"
    },
    {
      "caption": "CAP-forecast.R2 \u00b7 60% to 95% of sunny periods have the actual power in the band",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r2-5"
    },
    {
      "caption": "CAP-forecast.R3 \u00b7 10 fetches a day are at hours 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r3-1"
    },
    {
      "caption": "CAP-forecast.R3 \u00b7 3 fetches a day are at hours 0, 8 and 16",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r3-2"
    },
    {
      "caption": "CAP-forecast.R3 \u00b7 1 fetch a day is at hour 0",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r3-3"
    },
    {
      "caption": "CAP-forecast.R3 \u00b7 10 fetches a day: the latest fetch for hour 27 is at hour 26",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r3-4"
    },
    {
      "caption": "CAP-forecast.R3 \u00b7 10 fetches a day: the latest fetch for hour 26 is 26, and for hour 25 it is 24",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r3-5"
    },
    {
      "caption": "CAP-forecast.R3 \u00b7 1 fetch a day: the latest fetch for hour 47 is at hour 24",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r3-6"
    },
    {
      "caption": "CAP-forecast.R4 \u00b7 longitude 0: the first period ends at 2025-01-01T00:30:00.0000000Z",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r4-1"
    },
    {
      "caption": "CAP-forecast.R4 \u00b7 longitude 174.8: the first period ends at 2024-12-31T13:00:00.0000000Z",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r4-2"
    },
    {
      "caption": "CAP-forecast.R4 \u00b7 longitude -75: the first period ends at 2025-01-01T05:30:00.0000000Z",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r4-3"
    },
    {
      "caption": "CAP-forecast.R4 \u00b7 longitude 0, fetch at hour 8759: the last period ends at 2026-01-01T00:00:00.0000000Z",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r4-4"
    },
    {
      "caption": "CAP-forecast.R4 \u00b7 each pv_estimate has four decimals",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r4-5"
    },
    {
      "caption": "CAP-forecast.R4 \u00b7 each period has the five fields in order, and \"period\":\"PT30M\"",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r4-6"
    },
    {
      "caption": "CAP-forecast.R5 \u00b7 error scale 0: value j equals the solar output of hour j",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r5-1"
    },
    {
      "caption": "CAP-forecast.R5 \u00b7 a fetch at hour 4116 gives 48 values, each from 0 to 5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r5-2"
    },
    {
      "caption": "CAP-forecast.R5 \u00b7 a fetch at hour 8750 gives 48 values, and values 10 to 47 are 0",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r5-3"
    },
    {
      "caption": "CAP-forecast.R5 \u00b7 a fetch at hour 8760 gives 48 values, each 0 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r5-4"
    },
    {
      "caption": "CAP-forecast.R5 \u00b7 the sum of the 48 values is 0.5 times the sum of the estimates",
      "run": "lake env lean --run pdlc/changes/CH-0005-forecast/demo.lean r5-5"
    },
    {
      "caption": "CH-0005 \u00b7 all acceptance checks pass",
      "run": "for f in tests/*.lean tests/acceptance/*.lean; do lake env lean --run \"$f\" | grep 'checks,'; done"
    }
  ]
}
````

## The frames

Read each frame:

- pdlc/changes/CH-0005-forecast/frames/01.png
- pdlc/changes/CH-0005-forecast/frames/02.png
- pdlc/changes/CH-0005-forecast/frames/03.png
- pdlc/changes/CH-0005-forecast/frames/04.png
- pdlc/changes/CH-0005-forecast/frames/05.png
- pdlc/changes/CH-0005-forecast/frames/06.png
- pdlc/changes/CH-0005-forecast/frames/07.png
- pdlc/changes/CH-0005-forecast/frames/08.png
- pdlc/changes/CH-0005-forecast/frames/09.png
- pdlc/changes/CH-0005-forecast/frames/10.png
- pdlc/changes/CH-0005-forecast/frames/11.png
- pdlc/changes/CH-0005-forecast/frames/12.png
- pdlc/changes/CH-0005-forecast/frames/13.png
- pdlc/changes/CH-0005-forecast/frames/14.png
- pdlc/changes/CH-0005-forecast/frames/15.png
- pdlc/changes/CH-0005-forecast/frames/16.png
- pdlc/changes/CH-0005-forecast/frames/17.png
- pdlc/changes/CH-0005-forecast/frames/18.png
- pdlc/changes/CH-0005-forecast/frames/19.png
- pdlc/changes/CH-0005-forecast/frames/20.png
- pdlc/changes/CH-0005-forecast/frames/21.png
- pdlc/changes/CH-0005-forecast/frames/22.png
- pdlc/changes/CH-0005-forecast/frames/23.png
- pdlc/changes/CH-0005-forecast/frames/24.png
- pdlc/changes/CH-0005-forecast/frames/25.png
- pdlc/changes/CH-0005-forecast/frames/26.png
- pdlc/changes/CH-0005-forecast/frames/27.png
- pdlc/changes/CH-0005-forecast/frames/28.png
- pdlc/changes/CH-0005-forecast/frames/29.png
- pdlc/changes/CH-0005-forecast/frames/30.png
- pdlc/changes/CH-0005-forecast/frames/31.png
