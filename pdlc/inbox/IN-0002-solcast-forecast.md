# IN-0002 · Simulated Solcast forecast for policies

Status: in review · Ticket: none · Branch: pdlc/IN-0002-solcast-forecast · Added: 2026-10-31

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

- CAP-forecast.R1 (forecast periods): added
- CAP-forecast.R2 (forecast error): added
- CAP-forecast.R3 (fetch limit): added
- CAP-forecast.R4 (Solcast JSON): added
- CAP-forecast.R5 (hourly forecast energy): added

## Changes

- CH-0005 (forecast): CAP-forecast (simulated Solcast forecasts)

## Acceptance checks

Acceptance-File: tests/acceptance/IN-0002.acceptance.lean
Acceptance-Locked: 3456206
Acceptance-Passed: 7dd2d92

## Notes

- IN-0002 (Solcast forecast): Real API calls or a simulation? → a simulation of the Solcast hobbyist rooftop forecast reply, from the words of the user.
- IN-0002 (Solcast forecast): Who reads the forecast? → the policies of IN-0008 (hot-water policy simulation), not the strategies of IN-0001 (simulator), from the later words of the user.
- CAP-forecast.R1: How far ahead does a fetch look? → 48 hours of 30-minute periods (assumed).
- CAP-forecast.R5: What value has an hour with no period? → 0 kWh (assumed).
- CAP-strategies.R5 (load shift into sun): was "the three hours with the most forecast solar energy", now removed from this intent. The old strategies do not read the forecast. IN-0003 (shift into sunny hours that are apart) keeps the old rule.

- CAP-forecast.R2: What is a sunny period? → a period with an actual power of more than 0 kW (assumed).
- CAP-forecast.R4: How does the UTC time round on a tie? → up (assumed).

## Handoff

Handoff · IN-0002 · acceptance → tests

Time: 2026-11-15T10:16:45+00:00

### Done

- The test writer wrote 55 checks in `tests/acceptance/IN-0002.acceptance.lean`, for R1 (forecast periods) to R5 (hourly forecast energy).
- IN-0002 has one change, so this file is also the check file of CH-0005 (forecast). The test writer found three gaps in the spec, and the skill closed them.

### Decided on defaults

- CAP-forecast.R2: What is a sunny period? → a period with an actual power of more than 0 kW (assumed).
- CAP-forecast.R4: How does the UTC time round on a tie? → up (assumed).

### Open

- The acceptance file runs 250 forecasts of a 365-day scenario. If the library is slow, the test writer lowers the number of days between fetches.

### Look here

- `tests/acceptance/IN-0002.acceptance.lean`

### Don't redo

- The spec text and the Interface of CAP-forecast.

### Next: do this first

Start CH-0005 (forecast). Its checks are the acceptance checks.
