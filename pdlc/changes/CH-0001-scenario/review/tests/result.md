Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15 · `Sky.factor` gives 0.2 for `overcast` instead of 0.15 · fails (the value 0.15 with tolerance 1e-9 catches 0.2; the same holds for a cloudy factor of 0.6 against 0.5)

Follow-ups: none

Notes:
- The earlier problem is fixed. Each factor in "CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15" now uses `near` with a tolerance of 1e-9. A correct app that computes 0.15 as `1.0 - 0.85` now passes.
- This re-review judged only the changed lines 121-123 of `tests/CAP-scenario.lean`. No other check changed.
