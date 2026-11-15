# IN-0002 · Simulated Solcast forecast for policies

Status: ready · Ticket: none · Branch: pdlc/IN-0002-solcast-forecast · Added: 2026-10-31

The pdlc scripts read each header field. Thus, a header field holds only its bare value.
Do not add a name in brackets, and do not add backticks. For example, write
`Branch: pdlc/IN-0001-reset`, not `Branch: pdlc/IN-0001-reset (the intent branch)`.

## What and why

"We can get weather data from solcast, so this should be available to policy too."

Answers of the user: "Understand the solcast api and sim it", and the policy sees a
"Forecast of coming hours".

The user later said what the policy is for: "the best daily profile for heating our hotwater
and charging our battery, maximising self consumption without risking cold tanks or wasting
sunlight". IN-0008 (hot-water policy simulation) builds those policies. They read this forecast.

## Requirements

- CAP-forecast.R1: added
- CAP-forecast.R5: added

## Changes

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

## Notes

- IN-0002 (Solcast forecast): Real API calls or a simulation? → a simulation of the Solcast hobbyist rooftop forecast reply, from the words of the user.
- IN-0002 (Solcast forecast): Who reads the forecast? → the policies of IN-0008 (hot-water policy simulation), not the strategies of IN-0001 (simulator), from the later words of the user.
- CAP-forecast.R1: How far ahead does a fetch look? → 48 hours of 30-minute periods (assumed).
- CAP-forecast.R5: What value has an hour with no period? → 0 kWh (assumed).
- CAP-strategies.R5 (load shift into sun): was "the three hours with the most forecast solar energy", now removed from this intent. The old strategies do not read the forecast. IN-0003 (shift into sunny hours that are apart) keeps the old rule.

## Handoff

Handoff · IN-0002 · ready → change

Time: 2026-11-15T09:58:57+00:00

### Done

- Ready re-scoped IN-0002 (Solcast forecast) to CAP-forecast (simulated Solcast forecasts) only. The old strategies do not read the forecast.
- Ready added R5 (hourly forecast energy) and an "Interface" section in the form of pdlc 0.6.0. The five requirements are now `ready`.
- Ready removed the patches of CAP-strategies (battery and load strategies), CAP-simulation (hourly energy flows) and JOB-simulate (the sim command). IN-0008 (hot-water policy simulation) holds the commands.

### Decided on defaults

- CAP-forecast.R1: How far ahead does a fetch look? → 48 hours of 30-minute periods (assumed).
- CAP-forecast.R5: What value has an hour with no period? → 0 kWh (assumed).

### Open

- none

### Look here

- `pdlc/specs/capabilities/CAP-forecast.md`

### Don't redo

- The requirements R1 to R5 and the Solcast field names.

### Next: do this first

Plan one change for CAP-forecast. Plan the changes of IN-0008 (hot-water policy simulation) after it.
