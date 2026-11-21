# Proposal · CH-0003 · Hourly energy flows and results

Intent: IN-0001 · Base: pdlc/CH-0002-strategies · Tests-Locked: ba51e5b

## Visual review

![visual review](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review.gif?raw=true)

The GIF shows all 25 acceptance lines out of 25, in 27 frames. The lines cover R1 (energy flows of an hour) to R5 (strategy order). The last frame shows that all 123 checks pass.

## Requirements and checks

| Requirement | Checks | Result |
|---|---|---|
| CAP-simulation.R1 (energy flows of an hour) | 20 in `tests/CAP-simulation.lean` | pass |
| CAP-simulation.R2 (battery limits) | 13 in `tests/CAP-simulation.lean` | pass |
| CAP-simulation.R3 (totals and ratios) | 7 in `tests/CAP-simulation.lean` | pass |
| CAP-simulation.R4 (monthly totals) | 10 in `tests/CAP-simulation.lean` | pass |
| CAP-simulation.R5 (strategy order) | 4 in `tests/CAP-simulation.lean` | pass |

## Acceptance checks of the intent

The acceptance file is `tests/acceptance/IN-0001.acceptance.lean`, locked at `6cc1154`. Its review passed. The checks pass at the last change, CH-0004 (sim command).

## Reviews

| Remit | Result |
|---|---|
| [tests](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/tests/result.md) | pass |
| [specification](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/specification/result.md) | pass |
| [security](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/security/result.md) | pass |
| [quality](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/quality/result.md) | pass |
| [compliance](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/compliance/result.md) | pass (does not apply) |
| [privacy](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/privacy/result.md) | pass |
| [visual](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0003-simulation/pdlc/changes/CH-0003-simulation/review/visual/result.md) | pass |

## Manual checks

none

## Assumed

- The battery keeps 95% of the energy that goes in, and gives 95% of the energy that comes out (assumed).
- The battery is empty at the start (assumed).
- A ratio with nothing to divide by is 0% (assumed).
- A year has 365 days, with no leap day (assumed).
- The Lean names `Battery`, `Flow`, `stepHour`, `Totals`, `Month`, `Result` and `simulate` (assumed).

## Merge together

1. CH-0001 (scenario): proposed.
2. CH-0002 (strategies): proposed.
3. CH-0003 (simulation): this change.
4. CH-0004 (sim command): not started.

## New behaviour for you to approve

- IN-0005 (guards on inputs) also holds the follow-up on `Battery` and `Site` values from this change.
