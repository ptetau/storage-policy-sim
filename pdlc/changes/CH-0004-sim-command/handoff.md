# Handoff · CH-0004 · build → verify

Time: 2026-11-01T01:42:58+00:00

## Done

- The builder wrote `Main.lean` and `README.md`, and added the `sim` executable to `lakefile.toml`.
- All 190 checks pass: 34, 54, 35 and 67 in the four check files. No check changed since the lock `a7fe93a`.
- The acceptance file of IN-0001 (simulator) passes: 154 checks, 0 failed.
- JOB-simulate.R1 (run one strategy) to R5 (bad command line) are now `built`.

## Decided on defaults

- `sim help` and `sim --help` print the usage also when more words follow (assumed). No spec decides this case.

## Open

- none

## Look here

- `Main.lean`, `README.md`, `lakefile.toml`

## Don't redo

- The code and the checks.

## Next: do this first

Run all checks and the acceptance file, and make the review packets.
