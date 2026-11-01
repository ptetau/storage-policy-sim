# Proposal · CH-0001 · Seasonal sun, daily weather and household load

Intent: IN-0001 · Base: main · Tests-Locked: 6feecd6

## Visual review

![visual review](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review.gif?raw=true)

The GIF shows all 26 acceptance lines out of 26, in 28 frames. The lines cover R1 (seasonal sun), R2 (daily weather) and R3 (household load). The last frame shows "34 checks, 0 failed".

## Requirements and checks

| Requirement | Checks | Result |
|---|---|---|
| CAP-scenario.R1 (seasonal sun) | 11 in `tests/CAP-scenario.lean` | pass |
| CAP-scenario.R2 (daily weather) | 13 in `tests/CAP-scenario.lean` | pass |
| CAP-scenario.R3 (household load) | 10 in `tests/CAP-scenario.lean` | pass |

## Acceptance checks of the intent

The acceptance file is `tests/acceptance/IN-0001.acceptance.lean`, locked at `6cc1154`. Its review passed. The checks pass at the last change, CH-0004 (sim command).

## Reviews

| Remit | Result |
|---|---|
| [tests](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/tests/result.md) | pass |
| [specification](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/specification/result.md) | pass |
| [security](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/security/result.md) | pass |
| [quality](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/quality/result.md) | pass |
| [compliance](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/compliance/result.md) | pass (does not apply) |
| [privacy](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/privacy/result.md) | pass |
| [visual](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0001-scenario/pdlc/changes/CH-0001-scenario/review/visual/result.md) | pass |

## Manual checks

none

## Assumed

- The output of an hour is the panel power, times the sine of the sun height, times the sky factor (assumed).
- The sun height uses the middle of the hour in solar time, and day 0 is 1 January (assumed).
- The sky factors are 1.0 for sunny, 0.5 for cloudy and 0.15 for overcast (assumed).
- Each day keeps the sky of the day before with a chance of 0.6 (assumed).
- The chances of the summer half and the winter half of the year (assumed).
- The summer half is days 90 to 272 at latitude 0 or more (assumed).
- The base load uses a fixed profile with a morning peak and an evening peak (assumed).
- A seasonal factor of 1 + 0.2 × cos scales the base load, with its peak on day 15 or day 197 (assumed).
- The flexible load uses equal parts at 18:00, 19:00 and 20:00 by default (assumed).
- `lake-manifest.json` is in "Files", so that each build is the same (assumed).

## Merge together

1. CH-0001 (scenario): this change.
2. CH-0002 (strategies): not started.
3. CH-0003 (simulation): not started.
4. CH-0004 (sim command): not started.

## New behaviour for you to approve

- IN-0003 (shift into sunny hours that are apart), from the review of the acceptance checks.
