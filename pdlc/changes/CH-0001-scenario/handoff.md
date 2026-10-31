# Handoff · CH-0001 · verify → show

Time: 2026-10-31T23:39:18+00:00

## Done

- All 34 checks of `tests/CAP-scenario.lean` pass, and no check changed since the lock.
- Each remit passed: tests, specification, security, quality and privacy. Compliance does not apply.
- CAP-scenario.R1 (seasonal sun), R2 (daily weather) and R3 (household load) are `verified`.
- The run acceptance step is for the last change, CH-0004 (sim command). A failure now is expected.
- Verify filed no new intent.

## Decided on defaults

- none

## Open

- none

## Look here

- `pdlc/changes/CH-0001-scenario/review/`

## Don't redo

- The code, the checks and the reviews.

## Next: do this first

Record the GIF in a terminal, with a short Lean script that calls `pvOutput` and `scenario`.
