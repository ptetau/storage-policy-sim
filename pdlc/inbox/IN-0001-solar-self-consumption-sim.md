# IN-0001 · Solar self-consumption simulator

Status: ready · Ticket: none · Branch: none · Added: 2026-10-31

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

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
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

## Handoff

### Handoff · IN-0001 · ready → change

Time: 2026-10-31T22:55:38+00:00

### Done

- Ready added the bad command-line lines to JOB-simulate.R5 (bad command line), with six error codes in DES-errors (error codes).
- Ready agreed DES-lean-checks (Lean check files), because the project had no checks yet.
- Each of the 18 requirements of IN-0001 (solar self-consumption simulator) is now `ready`.
- Ready found no contradiction.

### Decided on defaults

- JOB-simulate.R5 (bad command line): What do bad values give? → one `error: <code>: <detail>` line on stderr, empty stdout, and exit code 2 (assumed).
- JOB-simulate.R5 (bad command line): Which number forms count? → an optional sign, digits, and an optional point with digits. `--days` and `--seed` are whole (assumed).
- JOB-simulate.R5 (bad command line): What ranges hold? → the table of the requirement, for example `--days` 1 to 3650 (assumed).
- JOB-simulate.R5 (bad command line): What if an option comes twice? → the last value counts (assumed).
- JOB-simulate.R3 (compare strategies): Does `sim compare` take `--strategy` or `--monthly`? → no, each gives `UNKNOWN_OPTION` (assumed).
- CAP-scenario.R1 (seasonal sun): What if a latitude or a size is out of range? → JOB-simulate.R5 (bad command line) refuses it before the simulation (assumed).
- DES-lean-checks (Lean check files): How does a Lean check file run and report? → a Lean script with a name filter and a count line (assumed).

### Open

- none

### Look here

- `pdlc/specs/jobs/JOB-simulate.md`: the range table and the error lines of R5 (bad command line).
- `pdlc/specs/design/DES-lean-checks.md`: how each check file runs.

### Don't redo

- The requirements of the four specs, and the six new error codes.

### Next: do this first

Plan one change for each spec. CAP-scenario (sun, weather and load) comes first, then CAP-strategies (strategies), CAP-simulation (energy flows), and JOB-simulate (the command).
