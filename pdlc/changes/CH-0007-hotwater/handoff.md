# Handoff · CH-0007 · verify → build

Time: 2026-11-16T05:02:15+00:00

### Done

- Round 1 passed in the specification, security and privacy remits, and the compliance remit does not apply. The quality remit failed with one problem.

### Decided on defaults

- none

### Open

- `StoragePolicySim/HotWater.lean:82` and `:107`: the rule that the tank counts as full before the hour only when `hour != 0 && state.fullToday` is written twice (in `thermostatOn` and in `tankStep`). Make one private helper that both places call. This is a remit rule (no unnecessary repetition), so no check changes.

### Look here

- `pdlc/changes/CH-0007-hotwater/review/quality/result.md`

### Don't redo

- The checks, the spec and the other remits.

### Next: do this first

Fix the one problem in `StoragePolicySim/HotWater.lean`, run the checks of CH-0007, and run `verify` again.
