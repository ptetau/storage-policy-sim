# Proposal · CH-0006 · Forecast from built hours

Intent: IN-0008 · Base: pdlc/CH-0005-forecast · Tests-Locked: 608aff7

## Visual review

![visual review](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review.gif?raw=true)

The GIF shows all 10 acceptance lines out of 10, in 12 frames. The last frame shows that the checks pass.

## Requirements and checks

| Requirement | Checks | Result |
|---|---|---|
| CAP-forecast.R6 (forecast from built hours) | 10 in `tests/CAP-forecast.lean`, 5 in the acceptance file | pass |
| CAP-forecast.R7 (shared error of a day) | 5 in `tests/CAP-forecast.lean`, 5 in the acceptance file | pass |

## Acceptance checks of the intent

The acceptance file `tests/acceptance/IN-0008.acceptance.lean` was locked at `d27aea8`, and its review passed in round 2. For an earlier change, the acceptance checks of IN-0008 (hot-water policy simulation) pass at the last change, CH-0011 (policy commands).

## Reviews

| Remit | Result |
|---|---|
| [specification](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/specification/result.md) | pass |
| [security](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/security/result.md) | pass |
| [quality](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/quality/result.md) | pass |
| [compliance](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/compliance/result.md) | pass (does not apply) |
| [privacy](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/privacy/result.md) | pass |
| [visual](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/visual/result.md) | pass |
| [tests](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0006-forecast-fast/pdlc/changes/CH-0006-forecast-fast/review/tests/result.md) | pass |

## Manual checks

none

## Assumed

- The random number of a period shares 70% of its variance with the day of the period, and the sum stays normal (assumed).

## Merge together

1. CH-0001 (scenario) to CH-0004 (sim command), in IN-0001, and CH-0005 (forecast), in IN-0002: proposed.
2. CH-0006 (forecast-fast): this change.
3. CH-0007 (hotwater), CH-0008 (gated-battery), CH-0009 (policy), CH-0010 (homesim) and CH-0011 (policy-commands): planned, in IN-0008. They merge together, bottom first.

## New behaviour for you to approve

- IN-0005 (guards on library inputs) holds two follow-ups of this change: a check of the error scale, and a size cap on `days`.
