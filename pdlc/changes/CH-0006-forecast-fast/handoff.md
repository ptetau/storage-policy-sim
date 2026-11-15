# Handoff · CH-0006 · verify → show

Time: 2026-11-15T12:17:27+00:00

### Done

- All 15 checks of `tests/CAP-forecast.lean` pass, with the older component checks and the acceptance files of IN-0001 and IN-0002. Three usage checks of IN-0001 fail until CH-0011, as expected.
- Round 2 passed in the remits specification, security, quality, privacy and compliance. The compliance remit does not apply. The tests review of the lock passed in round 1.
- Security follow-ups (no check of the error scale, no size cap on `days`) went into IN-0005 (guards on library inputs).

### Decided on defaults

- none

### Open

- none

### Look here

- `pdlc/changes/CH-0006-forecast-fast/review/`

### Don't redo

- The code and the checks.

### Next: do this first

Show CH-0006: write a short script that calls `forecastOf` and the shared error, record it, and propose the change.
