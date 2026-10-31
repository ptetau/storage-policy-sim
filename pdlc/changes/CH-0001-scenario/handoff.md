# Handoff · CH-0001 · build → verify

Time: 2026-10-31T23:26:26+00:00

## Done

- The builder wrote `StoragePolicySim/Scenario.lean`, `lakefile.toml`, `lean-toolchain` and `lake-manifest.json`.
- All 34 checks of `tests/CAP-scenario.lean` pass with the "all" command of `pdlc/config.md`. No check changed since the lock `5de000a`.
- The weather uses a seeded SplitMix64 generator. The base load profile has its peaks at 07:00 and 19:00.
- CAP-scenario.R1 (seasonal sun), R2 (daily weather) and R3 (household load) are now `built`.

## Decided on defaults

- CH-0001 (scenario): Does `lake-manifest.json` go into "Files"? → yes, so that each build is the same (assumed).

## Open

- none

## Look here

- `StoragePolicySim/Scenario.lean`
- `tests/CAP-scenario.lean`

## Don't redo

- The code and the checks.

## Next: do this first

Run all checks, then make the review packets with `make_packets.py CH-0001 --verify`.
