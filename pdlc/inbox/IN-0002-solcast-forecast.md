# IN-0002 · Simulated Solcast forecast for strategies

Status: ready · Ticket: none · Branch: pdlc/IN-0002-solcast-forecast · Added: 2026-10-31

## What and why

"We can get weather data from solcast, so this should be available to policy too."

Answers of the user: "Understand the solcast api and sim it", and the strategy sees a
"Forecast of coming hours".

## Requirements

- CAP-forecast.R1 (forecast periods): added
- CAP-forecast.R2 (forecast error): added
- CAP-forecast.R3 (fetch limit): added
- CAP-forecast.R4 (Solcast JSON): added
- CAP-strategies.R5 (load shift into sun): changed
- CAP-strategies.R6 (forecast for strategies): added
- CAP-simulation.R6 (forecast in the run): added
- JOB-simulate.R5 (bad command line): changed
- JOB-simulate.R6 (forecast options): added
- JOB-simulate.R7 (forecast command): added

## Changes

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

## Notes

- IN-0002 (Solcast forecast): Real API calls or a simulation? → a simulation of the Solcast hobbyist rooftop forecast reply, from the words of the user.
- IN-0002 (Solcast forecast): What does a strategy see? → the forecast of the coming hours, from the answer of the user.
- CAP-forecast.R1 (forecast periods): How far ahead? → 48 hours of 30-minute periods (assumed). The real service goes up to 14 days.
- CAP-forecast.R3 (fetch limit): How many fetches? → 1 to 10 each day, from the hobbyist limit of 10 calls each day (assumed).
- CAP-strategies.R5 (load shift into sun): was "the three hours with the most solar output", now "the three hours with the most forecast solar energy".
- JOB-simulate.R5 (bad command line): was "usage: sim run [options] | sim compare [options]", now "usage: sim run [options] | sim compare [options] | sim forecast [options]".
- CAP-strategies.R5 (load shift into sun): IN-0001 (simulator) also has this requirement open. IN-0002 wins where they differ, and its changes come after the changes of IN-0001 (assumed).
- JOB-simulate.R7 (forecast command): What do bad `--hour` values give? → the codes of R5 (bad command line), and `sim run --hour` gives `UNKNOWN_OPTION` (assumed).

## Handoff

### Handoff · IN-0002 · ready → change

Time: 2026-10-31T23:16:57+00:00

### Done

- Ready added five lines on the bad forms of `--hour` to JOB-simulate.R7 (forecast command).
- Each of the ten requirements of IN-0002 (Solcast forecast) is now `ready`. Ready found no contradiction.

### Decided on defaults

- JOB-simulate.R7 (forecast command): What do bad `--hour` values give? → the codes of R5 (bad command line), and `sim run --hour` gives `UNKNOWN_OPTION` (assumed).

### Open

- none

### Look here

- `pdlc/specs/capabilities/CAP-forecast.md`

### Don't redo

- The requirements of IN-0002 (Solcast forecast).

### Next: do this first

Plan CAP-forecast (simulated Solcast forecasts) first. Then plan the changes of CAP-strategies (strategies), CAP-simulation (energy flows) and JOB-simulate (the command), after the changes of IN-0001 (simulator).
