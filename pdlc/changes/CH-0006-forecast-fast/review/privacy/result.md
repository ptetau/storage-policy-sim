Result: pass

Remit: privacy

Problems: none

Follow-ups: none

Notes:
- Not applicable. The change touches no personal data.
- The change adds `forecastOf` and a shared day error to `StoragePolicySim/Forecast.lean`. Its inputs are a site (latitude, panel power, load), a seed, the hours of a simulated scenario, an error scale, and a fetch hour. None of these identifies a person.
- The code does no logging, no printing of data in errors, no network call, and no storage. The functions return `Array Period` values only.
- The `longitude` argument of `forecastJson` is the location of a simulated site. This change did not alter that function.
