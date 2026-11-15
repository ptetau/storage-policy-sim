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

### Step 1 · Forecast periods · [ ]

- Requirement: CAP-forecast.R1
- Check: the checks named `CAP-forecast.R1 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 2 · Forecast error · [ ]

- Requirement: CAP-forecast.R2
- Check: the checks named `CAP-forecast.R2 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 3 · Fetch limit · [ ]

- Requirement: CAP-forecast.R3
- Check: the checks named `CAP-forecast.R3 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 4 · Solcast JSON · [ ]

- Requirement: CAP-forecast.R4
- Check: the checks named `CAP-forecast.R4 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

### Step 5 · Hourly forecast energy · [ ]

- Requirement: CAP-forecast.R5
- Check: the checks named `CAP-forecast.R5 …` in `tests/acceptance/IN-0002.acceptance.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned as the only change of IN-0002 (Solcast forecast). The policies of IN-0008 (hot-water policy simulation) read it.
