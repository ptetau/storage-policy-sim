# CAP-forecast · Simulated Solcast rooftop forecasts for strategies

Status: active

## What it is for

CAP-forecast (simulated Solcast forecasts) acts like the Solcast hobbyist rooftop forecast
service, for a scenario. A fetch at an hour of the run gives 30-minute periods for the next
48 hours. Each period has an estimate, a 10% band and a 90% band. The forecast has an error that grows
with the lead time, from a seed.

A hobbyist account can fetch 10 times a day, so the fetch hours of a day come from a count
of fetches. The forecast can show as Solcast JSON, with UTC times from the longitude.

## Code map

- `StoragePolicySim/Forecast.lean`

## Requirements

### CAP-forecast.R1 · Forecast periods

Status: ready · Intents: IN-0002

A fetch at the start of hour `h` of a run gives the periods of the next 48 hours (assumed).
Each period is 30 minutes long, and ends 30, 60, and up to 2880 minutes after the fetch. A
period after the end of the run is not in the fetch (assumed).

Each period has its end in minutes from the start of the run, an estimate, a 10% band and a
90% band (assumed). Each value is a mean power in kW, as Solcast gives. The actual power of
a period is the solar energy of its hour, per hour.

In these lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is
365 days, and the error scale is 1, unless the line says otherwise.

- Given a fetch at hour 0, when the forecast is made, then it has 96 periods. Their ends are 30, 60, and up to 2880 minutes.
- Given a fetch at hour 8750, when the forecast is made, then it has 20 periods, because the run ends after 10 hours.
- Given a daily fetch at 00:00, when the forecasts are made, then no 10% band is above its estimate. No estimate is above its 90% band.
- Given a daily fetch at 00:00, when the forecasts are made, then each value is from 0 to 5 kW.
- Given a fetch at hour 0, when the forecast is made, then each period with no actual power has 0 kW in all three values.

### CAP-forecast.R2 · Forecast error

Status: ready · Intents: IN-0002

The estimate is the actual power, times 1 plus the error scale times a spread times a random
number from a normal curve (assumed). The spread is 0.05 plus 0.10 for each 24 hours of lead
time (assumed). The lead time is from the fetch to the end of the period.

The 10% band is the estimate times 1 less 1.28 times the error scale times the spread. The
90% band uses 1 plus that amount (assumed). Each value stays from 0 to the panel power. The
seed of the run gives the random numbers, and the forecast does not change the weather. The
error of a set of periods is the mean of the absolute differences from the actual power
(assumed).

- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given seed 7, when the same fetch is made two times, then the two forecasts are the same.
- Given seeds 7 and 8, when a fetch at hour 4000 is made with each, then at least one estimate differs.
- Given daily fetches, when sunny periods are compared, then the error 24 to 48 hours ahead is more than 0 to 4 hours ahead.
- Given a daily fetch at 00:00, when the forecasts are made, then 60% to 95% of sunny periods have the actual power in the band.

### CAP-forecast.R3 · Fetch limit

Status: ready · Intents: IN-0002

A day has from 1 to 10 fetches, because a Solcast hobbyist account has 10 calls each day
(assumed). Fetch `i` of `n` is at hour `i × 24 / n` of each day, rounded down (assumed). At
each hour, a strategy sees the forecast of the latest fetch at or before that hour.

- Given 10 fetches a day, when the fetch hours are found, then they are 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21.
- Given 3 fetches a day, when the fetch hours are found, then they are 0, 8 and 16.
- Given 1 fetch a day, when the fetch hours are found, then the only hour is 0.
- Given 10 fetches a day, when the latest fetch for hour 27 is found, then it is the fetch at hour 26.
- Given 1 fetch a day, when the latest fetch for hour 47 is found, then it is the fetch at hour 24.

### CAP-forecast.R4 · Solcast JSON

Status: ready · Intents: IN-0002

A forecast shows as the JSON of the Solcast hobbyist rooftop forecast reply. The text is
`{"forecasts":[` and the periods, split by commas, then `]}`, with no spaces or line breaks
(assumed). Each period is `{"pv_estimate":<v>,"pv_estimate10":<v>,"pv_estimate90":<v>,"period_end":"<time>","period":"PT30M"}`.

Each value has four decimals (assumed). The run starts on 1 January 2025 at 00:00 solar
time (assumed). The UTC time is the solar time less the longitude divided by 15 hours,
rounded to the nearest 30 minutes (assumed). The time has the form
`2025-01-01T00:30:00.0000000Z`.

- Given longitude 0 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T00:30:00.0000000Z`.
- Given longitude 174.8 and a fetch at hour 0, when the JSON is made, then the first period ends at `2024-12-31T13:00:00.0000000Z`.
- Given longitude -75 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T05:30:00.0000000Z`.
- Given longitude 0 and a fetch at hour 8759, when the JSON is made, then the last period ends at `2026-01-01T00:00:00.0000000Z`.
- Given an error scale of 0 and a fetch at hour 4116, when the JSON is made, then each `pv_estimate` has four decimals.
- Given a fetch at hour 0, when the JSON is made, then each period has the five fields in the order above, and `"period":"PT30M"`.
