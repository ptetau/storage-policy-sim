Result: pass

Remit: security

Problems: none

Follow-ups:
- Check `errorScale` at the library edge. `forecastOf` accepts any `Float`. A NaN scale gives NaN spreads and NaN estimates, because `cutToPanels` does not clean a NaN. A negative scale swaps the p10 and p90 bands. The packet does not show the caller that checks the scale (the `OUT_OF_RANGE` and `BAD_NUMBER` codes of DES-errors suggest that the command line does). No acceptance line of CAP-forecast.R6 or CAP-forecast.R7 asks for this check, so a new intent could add it, with a new error or a clean empty result.
- Guard the size of `days` in `forecast`. A very large `days` makes `scenario` build `24 × days` hours. This code did not change in this diff, and no acceptance line asks for a limit. A new intent could add a size cap if a caller can pass `days` from outside.

Notes:
- Index safety: `forecastOf` reads `hours[hourOfPeriod endMinute]!`. The largest period is `k = 2 × (24 × D - fetchHour)` with `D = hours.size / 24`. Its end minute is `1440 × D`, and its hour index is `24 × D - 1`. That index is below `hours.size`, also when `hours.size` is not a multiple of 24. So the `!` access cannot panic.
- Fail closed: `24 × (hours.size / 24) - fetchHour` is a `Nat` subtraction that stops at 0. A fetch hour at or past the end of the run, such as 8760, gives no period. No hours give no period. Both cases match CAP-forecast.R6.
- Bounded work: `periodCount` is at most `horizonHours × 60 / periodMinutes`, which is 96. A large `fetchHour` cannot make a large loop. `60 × fetchHour` is a `Nat`, so it cannot overflow.
- No injection or secret: the diff builds no command, query, path or page. `forecastJson` and its text helpers did not change. The new constants `sharedShare`, `ownShare` and `dayStream` are mixing values for a simulation, not secrets. The generator is SplitMix64, so it is not for cryptography, and the spec does not ask for that.
- No new dependency: the module still imports only `StoragePolicySim.Scenario`.
- Caller contract: `forecastOf` trusts that `hours` came from `scenario site seed days` for the same site and seed. The interface says so. A mismatch gives a wrong forecast, but it opens no unsafe path.
