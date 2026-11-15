# IN-0005 · Guards on library inputs

Status: new · Ticket: none · Branch: none · Added: 2026-10-31

## What and why

The reviews of CH-0002 (battery and load strategies) found three inputs that no acceptance line covers:

- "`placeFlex` could check that `pvKwh` and `flexKwh` each have 24 items. If the two arrays have different sizes, `shiftIntoSun` can drop part of the flexible load."
- "`decide` could reject an hour outside 0 to 23. It could also reject a negative or NaN surplus or shortfall."
- "No acceptance line says what `shift` does with `NaN` solar values."
- "Check the `Battery` and `Site` fields for negative or NaN values." (CH-0003, security)

- "`fetchHours` and `latestFetch` accept any count. A new intent could reject a count outside 1 to 10 with `OUT_OF_RANGE`." (CH-0005, specification)
- "`hourlyEnergy` takes any periods and any `fetchHour`. A new intent could reject periods that do not belong to the fetch hour." (CH-0005, specification)
- "Cap the sizes that a caller picks, for the count of fetches and the days of a run." (CH-0005, security)

## Requirements

- none yet

## Changes

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

## Notes

- Awaits approval: found reviewing CH-0002 (security, specification)
- Awaits approval: found reviewing CH-0006 (security): `forecast` and `forecastOf` take any error scale, so a NaN scale gives NaN estimates and a negative scale swaps the 10% and 90% bands. Also, a very large `days` makes `scenario` build 24 × days hours, with no size cap.

## Handoff

none
