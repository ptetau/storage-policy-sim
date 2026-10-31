Result: pass

Remit: tests

Problems: none

Wrong versions: none

Follow-ups: none

Notes:
- This is a re-review. The earlier review at 67970d4 listed no problems.
- The diff changes one line in `main` of `tests/acceptance/IN-0001.acceptance.lean`. The line adds the type `Check` to the parameter of the name filter.
- The changed line matches the example in DES-lean-checks (how a Lean check file runs and reports). The filter still keeps a check only when its name starts with the argument and a space.
- No check changed. Thus, no "Wrong versions" line applies.
