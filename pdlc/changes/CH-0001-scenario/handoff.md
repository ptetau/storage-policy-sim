# Handoff · CH-0001 · tests → build

Time: 2026-10-31T23:26:26+00:00

## Done

- The builder reported that `tests/CAP-scenario.lean` did not compile on Lean 4.35.0. This report is round 1 of 2 of CH-0001 (scenario).
- The test writer gave the name filter its type. The tests lock is now `5de000a`, and the re-review passed.
- The acceptance file had the same fault. The acceptance lock is now `a404bbe`, and its re-review passed.
- The file holds 34 checks, not 36.

## Decided on defaults

- CH-0001 (scenario): Does `lake-manifest.json` go into "Files"? → yes, so that each build is the same (assumed).

## Open

- none

## Look here

- `tests/CAP-scenario.lean`
- The code of the builder, not yet committed: `StoragePolicySim/Scenario.lean`, `lakefile.toml`, `lean-toolchain` and `lake-manifest.json`.

## Don't redo

- The checks, their lock, and the acceptance lock.

## Next: do this first

Run all checks on the code of the builder. Commit the code when the 34 checks pass.
