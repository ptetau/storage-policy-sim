# IN-0001 · Solar self-consumption simulator

Status: building · Ticket: none · Branch: pdlc/IN-0001-solar-sim · Added: 2026-10-31

## What and why

"Build a simulator for both seasonal and weather variation so we can test strategies for
maximizing self consumption of solar captured power. Written in lean4 using latest pdlc."

## Requirements

- CAP-scenario.R1 (seasonal sun): added
- CAP-scenario.R2 (daily weather): added
- CAP-scenario.R3 (household load): added
- CAP-strategies.R1 (strategy names): added
- CAP-strategies.R2 (no battery use): added
- CAP-strategies.R3 (greedy battery use): added
- CAP-strategies.R4 (evening battery use): added
- CAP-strategies.R5 (load shift into sun): added
- CAP-simulation.R1 (energy flows of an hour): added
- CAP-simulation.R2 (battery limits): added
- CAP-simulation.R3 (totals and ratios): added
- CAP-simulation.R4 (monthly totals): added
- CAP-simulation.R5 (strategy order): added
- JOB-simulate.R1 (run one strategy): added
- JOB-simulate.R2 (monthly table): added
- JOB-simulate.R3 (compare strategies): added
- JOB-simulate.R4 (repeatable weather): added
- JOB-simulate.R5 (bad command line): added

## Changes

- CH-0001 (scenario): CAP-scenario (sun, weather and load)
- CH-0002 (strategies): CAP-strategies (battery and load strategies)
- CH-0003 (simulation): CAP-simulation (hourly energy flows)
- CH-0004 (sim command): JOB-simulate (the `sim` command)

## Acceptance checks

Acceptance-File: tests/acceptance/IN-0001.acceptance.lean
Acceptance-Locked: 6cc1154
Acceptance-Passed: none

## Notes

- IN-0001 (simulator): Which language? → Lean 4, with Lake, from the words of the intent.
- IN-0001 (simulator): What does "self consumption" mean? → the share of the solar energy that the house uses itself, and does not export (assumed).
- IN-0001 (simulator): What is the time step? → one hour, from 1 January, for a number of days (assumed).
- IN-0001 (simulator): Where does weather come from? → a seeded random model, so that each run with the same seed is the same (assumed).
- IN-0001 (simulator): Which strategies? → none, greedy, evening, and shift (assumed), so that a battery strategy and a load strategy can be compared.
- JOB-simulate.R5 (bad command line): What do bad values give? → one `error: <code>: <detail>` line on stderr, empty stdout, and exit code 2 (assumed).
- JOB-simulate.R5 (bad command line): Which number forms count? → an optional sign, digits, and an optional point with digits. `--days` and `--seed` are whole (assumed).
- JOB-simulate.R5 (bad command line): What ranges hold? → the table of the requirement, for example `--days` 1 to 3650 (assumed).
- JOB-simulate.R5 (bad command line): What if an option comes twice? → the last value counts (assumed).
- JOB-simulate.R3 (compare strategies): Does `sim compare` take `--strategy` or `--monthly`? → no, each gives `UNKNOWN_OPTION` (assumed).
- CAP-scenario.R1 (seasonal sun): What if a latitude or a size is out of range? → JOB-simulate.R5 (bad command line) refuses it before the simulation (assumed).
- DES-lean-checks (Lean check files): How does a Lean check file run and report? → a Lean script with a name filter and a count line (assumed).
- JOB-simulate.R1 (run one strategy): was "`--flex`: 3", now "`--flex`: 3, or the `--load` value when that is less" (assumed).
- JOB-simulate.R5 (bad command line): How does a range show? → `(<lowest> to <highest>)` as in the table (assumed).
- IN-0001 (simulator): Does a review that fails only on the words of pdlc records count as a round? → no, in this project. The skill fixes the words and reviews again. The user decided this, and https://github.com/ptetau/pskills/issues/24 tracks a fix in pdlc.

## Handoff

### Handoff · IN-0001 · acceptance → tests

Time: 2026-10-31T23:14:03+00:00

### Done

- The test writer wrote 154 acceptance checks in `tests/acceptance/IN-0001.acceptance.lean`, for all 18 requirements of IN-0001 (simulator).
- The checks failed before any code, because the library and `lakefile.toml` do not exist yet.
- The first review failed on one check of CAP-simulation.R2 (battery limits). The test writer fixed it, and the re-review passed.
- The lock is `67970d4`. The file has no stored-data line.

### Decided on defaults

- JOB-simulate.R1 (run one strategy): What is the `--flex` default when `--load` is less than 3? → the `--load` value (assumed).
- JOB-simulate.R5 (bad command line): How does a range show? → `(<lowest> to <highest>)` as in the table (assumed).

### Open

- The check of CAP-simulation.R2 (battery limits) needs one hour that discharges exactly 2 kWh. The load profile of CH-0001 (scenario) must give such an hour.

### Look here

- `tests/acceptance/IN-0001.acceptance.lean`
- `pdlc/acceptance/IN-0001-solar-self-consumption-sim/review/tests/result.md`

### Don't redo

- The acceptance checks and their lock.

### Next: do this first

Start CH-0001 (scenario) from `pdlc/IN-0001-solar-sim`. Its component checks go in `tests/CAP-scenario.lean`.
