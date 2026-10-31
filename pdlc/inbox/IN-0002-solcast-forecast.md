# IN-0002 · Simulated Solcast forecast for strategies

Status: specifying · Ticket: none · Branch: pdlc/IN-0002-solcast-forecast · Added: 2026-10-31

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

## Handoff

### Handoff · IN-0002 · intake → ready

Time: 2026-10-31T23:16:27+00:00

### Done

- Intake added CAP-forecast (simulated Solcast forecasts) with four requirements.
- Intake changed CAP-strategies.R5 (load shift into sun), so that `shift` places the load by the forecast. CAP-strategies.R6 (forecast for strategies) is new.
- Intake added CAP-simulation.R6 (forecast in the run), and JOB-simulate.R6 (forecast options) and R7 (forecast command).
- Intake changed the usage line of JOB-simulate.R5 (bad command line).

### Decided on defaults

- CAP-forecast.R1 (forecast periods): How far ahead? → 48 hours of 30-minute periods (assumed).
- CAP-forecast.R3 (fetch limit): How many fetches? → 1 to 10 each day (assumed).
- CAP-strategies.R5 (load shift into sun): How do two open intents fit? → IN-0002 wins, and its changes come after IN-0001 (assumed).

### Open

- Each unmerged change of IN-0001 (simulator) covers CAP-strategies.R5 (load shift into sun) and JOB-simulate.R5 (bad command line). The changes of IN-0002 (Solcast forecast) for those specs stack after them.

### Look here

- `pdlc/specs/capabilities/CAP-forecast.md`
- R5 (load shift into sun) and R6 (forecast for strategies) in `pdlc/specs/capabilities/CAP-strategies.md`

### Don't redo

- The Solcast field names `pv_estimate`, `pv_estimate10`, `pv_estimate90`, `period_end` and `period`.

### Next: do this first

Make the forecast error lines exact, and settle the bad forms of `--hour`.
