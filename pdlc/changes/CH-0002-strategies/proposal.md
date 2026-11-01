# Proposal · CH-0002 · Battery and load strategies

Intent: IN-0001 · Base: pdlc/CH-0001-scenario · Tests-Locked: 91d1e6b

## Visual review

![visual review](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review.gif?raw=true)

The GIF shows all 24 acceptance lines out of 24, in 26 frames. The lines cover R1 (strategy names) to R5 (load shift into sun). The last frame shows that all checks pass.

## Requirements and checks

| Requirement | Checks | Result |
|---|---|---|
| CAP-strategies.R1 (strategy names) | 7 in `tests/CAP-strategies.lean` | pass |
| CAP-strategies.R2 (no battery use) | 4 in `tests/CAP-strategies.lean` | pass |
| CAP-strategies.R3 (greedy battery use) | 7 in `tests/CAP-strategies.lean` | pass |
| CAP-strategies.R4 (evening battery use) | 9 in `tests/CAP-strategies.lean` | pass |
| CAP-strategies.R5 (load shift into sun) | 8 in `tests/CAP-strategies.lean` | pass |

## Acceptance checks of the intent

The acceptance file is `tests/acceptance/IN-0001.acceptance.lean`, locked at `6cc1154`. Its review passed. The checks pass at the last change, CH-0004 (sim command).

## Reviews

| Remit | Result |
|---|---|
| [tests](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/tests/result.md) | pass |
| [specification](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/specification/result.md) | pass |
| [security](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/security/result.md) | pass |
| [quality](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/quality/result.md) | pass |
| [compliance](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/compliance/result.md) | pass (does not apply) |
| [privacy](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/privacy/result.md) | pass |
| [visual](https://github.com/ptetau/storage-policy-sim/blob/pdlc/CH-0002-strategies/pdlc/changes/CH-0002-strategies/review/visual/result.md) | pass |

## Manual checks

none

## Assumed

- The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
- A name finds its strategy only when the name matches exactly (assumed).
- The `evening` strategy discharges only from 17:00 to 23:59 (assumed).
- The `shift` strategy moves the flexible load, in equal parts, to the three hours with the most solar output (assumed).
- A tie goes to the earlier hour (assumed).
- The Lean names `Strategy`, `Request`, `Strategy.decide` and `Strategy.placeFlex` (assumed).

## Merge together

1. CH-0001 (scenario): proposed.
2. CH-0002 (strategies): this change.
3. CH-0003 (simulation): not started.
4. CH-0004 (sim command): not started.

## New behaviour for you to approve

- IN-0004 (shift on a day with little sun), from the tests review.
- IN-0005 (guards on strategy inputs), from the security and specification reviews.
