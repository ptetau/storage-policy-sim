# IN-0005 · Guards on strategy inputs

Status: new · Ticket: none · Branch: none · Added: 2026-10-31

## What and why

The reviews of CH-0002 (battery and load strategies) found three inputs that no acceptance line covers:

- "`placeFlex` could check that `pvKwh` and `flexKwh` each have 24 items. If the two arrays have different sizes, `shiftIntoSun` can drop part of the flexible load."
- "`decide` could reject an hour outside 0 to 23. It could also reject a negative or NaN surplus or shortfall."
- "No acceptance line says what `shift` does with `NaN` solar values."

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

## Handoff

none
