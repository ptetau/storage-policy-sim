# Proposal · CH-0005 · Simulated Solcast forecast

Intent: IN-0002 · Base: pdlc/CH-0004-sim-command · Tests-Locked: acceptance

## Visual review

![visual review](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review.gif?raw=true)

The GIF shows all 29 acceptance lines out of 29, in 31 frames. The lines cover R1 (forecast periods) to R5 (hourly forecast energy). The last frame shows that all checks pass.

## Requirements and checks

| Requirement | Checks | Result |
|---|---|---|
| CAP-forecast.R1 (forecast periods) | 13 in the acceptance file | pass |
| CAP-forecast.R2 (forecast error) | 12 in the acceptance file | pass |
| CAP-forecast.R3 (fetch limit) | 9 in the acceptance file | pass |
| CAP-forecast.R4 (Solcast JSON) | 14 in the acceptance file | pass |
| CAP-forecast.R5 (hourly forecast energy) | 10 in the acceptance file | pass |

## Acceptance checks of the intent

The acceptance file is `tests/acceptance/IN-0002.acceptance.lean`, locked at `3456206`. Its review passed. All 57 checks passed at `7dd2d92`. They are also the checks of this change.

## Reviews

| Remit | Result |
|---|---|
| [specification](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review/specification/result.md) | pass |
| [security](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review/security/result.md) | pass |
| [quality](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review/quality/result.md) | pass |
| [compliance](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review/compliance/result.md) | pass (does not apply) |
| [privacy](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review/privacy/result.md) | pass |
| [visual](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0005-forecast/pdlc/changes/CH-0005-forecast/review/visual/result.md) | pass |

## Manual checks

none

## Assumed

- A fetch looks 48 hours ahead, in 30-minute periods (assumed).
- The error has a spread of 0.05 plus 0.10 for each 24 hours of lead time, with a normal random number (assumed).
- A day has 1 to 10 fetches, from the hobbyist limit of 10 calls each day (assumed).
- The Solcast JSON is one line with four decimals, from 1 January 2025, and a tie in the UTC time rounds up (assumed).
- An hour with no period in a fetch has the forecast energy 0 kWh (assumed).

## Merge together

1. CH-0001 (scenario) to CH-0004 (sim command): proposed, in IN-0001.
2. CH-0005 (forecast): this change. IN-0002 has no other change.

## New behaviour for you to approve

- IN-0005 (guards on library inputs) holds three follow-ups of this change.
