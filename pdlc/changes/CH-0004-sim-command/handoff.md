# Handoff · CH-0004 · tests → build

Time: 2026-11-01T01:37:33+00:00

## Done

- The test writer wrote 67 checks in `tests/JOB-simulate.lean`, for R1 (run one strategy) to R5 (bad command line). The lock is `a7fe93a`, and the tests review passed.
- The acceptance file `tests/acceptance/IN-0001.acceptance.lean` compiles. Its 78 checks of the capabilities pass, and its 76 checks of the `sim` command fail.

## Decided on defaults

- none

## Open

- none

## Look here

- `tests/JOB-simulate.lean` and `tests/acceptance/IN-0001.acceptance.lean`
- The "Interface" of `pdlc/changes/CH-0004-sim-command/change.md`

## Don't redo

- The checks and their locks.

## Next: do this first

Add the `sim` executable to `lakefile.toml`, and write `Main.lean` and `README.md`. This change is the last change of IN-0001 (simulator), so the acceptance file must pass too.
