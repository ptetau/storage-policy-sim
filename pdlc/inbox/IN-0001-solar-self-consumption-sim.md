# IN-0001 · Solar self-consumption simulator

Status: specifying · Ticket: none · Branch: none · Added: 2026-10-31

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

## Handoff

### Handoff · IN-0001 · intake → ready

Time: 2026-10-31T22:54:06+00:00

### Done

- Intake added four new specs for IN-0001 (solar self-consumption simulator).
- CAP-scenario (sun, weather and load) gets three requirements. CAP-strategies (battery and load strategies) gets five.
- CAP-simulation (hourly energy flows) gets five requirements. JOB-simulate (the `sim` command) gets five.
- The project has no code yet. Thus, no spec had a deep look from recon.

### Decided on defaults

- IN-0001 (simulator): What does "self consumption" mean? → the share of the solar energy that the house uses itself, and does not export (assumed).
- IN-0001 (simulator): What is the time step? → one hour, from 1 January, for a number of days (assumed).
- IN-0001 (simulator): Where does weather come from? → a seeded random model, so that each run with the same seed is the same (assumed).
- IN-0001 (simulator): Which strategies? → none, greedy, evening, and shift (assumed), so that a battery strategy and a load strategy can be compared.

### Open

- The bad forms of each command-line value need lines and error codes in `DES-errors` (error codes).
- The checks need a convention for Lean check files, because the project has no checks yet.

### Look here

- `pdlc/specs/capabilities/CAP-scenario.md`
- `pdlc/specs/capabilities/CAP-strategies.md`
- `pdlc/specs/capabilities/CAP-simulation.md`
- `pdlc/specs/jobs/JOB-simulate.md`

### Don't redo

- The split into three capabilities and one job.

### Next: do this first

Settle the bad command-line values and their error codes. Then agree how a Lean check file runs and reports.
