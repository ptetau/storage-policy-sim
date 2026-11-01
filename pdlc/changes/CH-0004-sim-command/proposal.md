# Proposal · CH-0004 · The sim command

Intent: IN-0001 · Base: pdlc/CH-0003-simulation · Tests-Locked: a7fe93a

## Visual review

![visual review](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review.gif?raw=true)

The GIF shows all 46 acceptance lines out of 46, in 48 frames. The lines cover R1 (run one strategy) to R5 (bad command line). The last frame shows that all 190 checks and the 154 acceptance checks pass.

## Requirements and checks

| Requirement | Checks | Result |
|---|---|---|
| JOB-simulate.R1 (run one strategy) | 10 in `tests/JOB-simulate.lean` | pass |
| JOB-simulate.R2 (monthly table) | 6 in `tests/JOB-simulate.lean` | pass |
| JOB-simulate.R3 (compare strategies) | 6 in `tests/JOB-simulate.lean` | pass |
| JOB-simulate.R4 (repeatable weather) | 3 in `tests/JOB-simulate.lean` | pass |
| JOB-simulate.R5 (bad command line) | 42 in `tests/JOB-simulate.lean` | pass |

## Acceptance checks of the intent

The acceptance file is `tests/acceptance/IN-0001.acceptance.lean`, locked at `f5cb760`. Its review passed. All 154 checks passed at `9bc6ba9`.

## Reviews

| Remit | Result |
|---|---|
| [tests](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/tests/result.md) | pass |
| [specification](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/specification/result.md) | pass |
| [security](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/security/result.md) | pass |
| [quality](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/quality/result.md) | pass |
| [compliance](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/compliance/result.md) | pass (does not apply) |
| [privacy](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/privacy/result.md) | pass |
| [visual](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0004-sim-command/pdlc/changes/CH-0004-sim-command/review/visual/result.md) | pass |

## Manual checks

none

## Assumed

- Each line of `sim run` is a label, spaces to column 19, and a value. Energies and ratios have one decimal (assumed).
- The defaults: `greedy`, 365 days, seed 1, latitude -41.3, 5 kW of panels, a 10 kWh / 5 kW battery, 20 kWh of load with 3 kWh flexible (assumed).
- The `--flex` default is 3, or the `--load` value when that is less (assumed).
- The headers of the monthly table and of `sim compare` (assumed).
- A bad command line prints one `error: <code>: <detail>` line on stderr and exits with 2 (assumed).
- The number forms, the ranges of each option, and that the last value of an option counts (assumed).
- `sim help` and `sim --help` print the usage also when more words follow (assumed).

## Merge together

1. CH-0001 (scenario): proposed.
2. CH-0002 (strategies): proposed.
3. CH-0003 (simulation): proposed.
4. CH-0004 (sim command): this change.

Merge the four changes together, with CH-0001 first.

## New behaviour for you to approve

- IN-0003 (shift into sunny hours that are apart).
- IN-0004 (shift on a day with little sun).
- IN-0005 (guards on inputs).
- IN-0006 (polish of the sim command).
