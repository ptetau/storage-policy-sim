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
Acceptance-Locked: 36a6e76
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

## Handoff

### Handoff · IN-0001 · change → acceptance

Time: 2026-10-31T22:58:08+00:00

### Done

- Change planned four changes, one for each spec, in this order:
  1. CH-0001 (scenario): the hours of a scenario, in `StoragePolicySim/Scenario.lean`.
  2. CH-0002 (strategies): the four strategies, in `StoragePolicySim/Strategy.lean`.
  3. CH-0003 (simulation): the energy flows and the totals, in `StoragePolicySim/Simulation.lean`.
  4. CH-0004 (sim command): the `sim` command, in `Main.lean`, with the README.
- The order follows what each change uses. CH-0003 (simulation) uses the first two, and CH-0004 (sim command) uses all three.

### Decided on defaults

- CH-0001 (scenario): What are the Lean names? → `Sky`, `Site`, `Hour`, `pvOutput` and `scenario`, in the namespace `StoragePolicySim` (assumed).
- CH-0002 (strategies): What are the Lean names? → `Strategy`, `Request`, `Strategy.decide` and `Strategy.placeFlex` (assumed).
- CH-0003 (simulation): What are the Lean names? → `Battery`, `Flow`, `stepHour`, `Totals`, `Month`, `Result` and `simulate` (assumed).
- CH-0004 (sim command): In which order does `sim` find problems? → the command, then each option from left to right, then the ranges, then `--flex` (assumed).

### Open

- none

### Look here

- The "Interface" of each change spec in `pdlc/changes/`.
- `pdlc/specs/design/DES-lean-checks.md`: the form of a check file.

### Don't redo

- The four change specs and their order.

### Next: do this first

Write the acceptance checks in `tests/acceptance/IN-0001.acceptance.lean`. Prove the JOB-simulate (the `sim` command) lines through the `sim` process, and the capability lines through the library functions.
