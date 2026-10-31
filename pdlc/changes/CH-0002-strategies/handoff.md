# Handoff · CH-0002 · tests → build

Time: 2026-10-31T23:56:41+00:00

## Done

- The test writer wrote 35 checks in `tests/CAP-strategies.lean`, for R1 (strategy names) to R5 (load shift into sun).
- The checks compile against the Interface, and they fail because `StoragePolicySim/Strategy.lean` does not exist yet.
- The first review failed on one check of R5 (load shift into sun). The re-review passed. The lock is `91d1e6b`.

## Decided on defaults

- none

## Open

- none

## Look here

- `tests/CAP-strategies.lean`
- The "Interface" of `pdlc/changes/CH-0002-strategies/change.md`

## Don't redo

- The checks and their lock.

## Next: do this first

Write `StoragePolicySim/Strategy.lean`. The `shift` strategy takes the three hours with the most solar output, which can be apart.
