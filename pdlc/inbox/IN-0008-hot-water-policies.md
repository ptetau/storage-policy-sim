# IN-0008 · Hot-water policy simulation

Status: ready · Ticket: none · Branch: pdlc/IN-0008-hot-water-policies · Added: 2026-11-15

The pdlc scripts read each header field. Thus, a header field holds only its bare value.
Do not add a name in brackets, and do not add backticks. For example, write
`Branch: pdlc/IN-0001-reset`, not `Branch: pdlc/IN-0001-reset (the intent branch)`.

## What and why

"build it out, use opus only if you need it. what I am trying to do is to be able to create the best daily profile for heating our hotwater and charging our battery, maximising self consumption without risking cold tanks or wasting sunlight. this sim will help me simulate a robust policy, both dynamic, precomputed or static."

## Requirements

- CAP-forecast.R6 (forecast from built hours): added
- CAP-hotwater.R1 (standby loss and draw): added
- CAP-hotwater.R2 (heating limits): added
- CAP-hotwater.R3 (thermostat backstop): added
- CAP-hotwater.R4 (hot-water draw profile): added
- CAP-simulation.R6 (allowed battery use): added
- CAP-policy.R1 (static profile): added
- CAP-policy.R2 (day-ahead plan): added
- CAP-policy.R3 (dynamic action): added
- CAP-policy.R4 (defaults and names): added
- CAP-homesim.R1 (hourly home flows): added
- CAP-homesim.R2 (no cold tank): added
- CAP-homesim.R3 (totals and ratios): added
- CAP-homesim.R4 (policies at work): added
- CAP-homesim.R5 (robust evaluation): added
- CAP-homesim.R6 (tuning a static profile): added
- JOB-simulate.R5 (bad command line): changed
- JOB-simulate.R6 (forecast command): added
- JOB-simulate.R7 (policy run): added
- JOB-simulate.R8 (policy compare): added
- JOB-simulate.R9 (policy robust): added
- JOB-simulate.R10 (policy tune): added
- JOB-simulate.R11 (policy options): added

## Changes

- CH-0006 (forecast-fast): CAP-forecast (simulated Solcast forecasts)
- CH-0007 (hotwater): CAP-hotwater (hot-water tank)
- CH-0008 (gated-battery): CAP-simulation (hourly energy flows)
- CH-0009 (policy): CAP-policy (daily-profile policies)
- CH-0010 (homesim): CAP-homesim (home simulation)
- CH-0011 (policy-commands): JOB-simulate (the sim command)

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

## Notes

- IN-0008 (hot-water policy simulation): What is the policy for? → a daily profile that heats the hot water and charges the battery, with the most self-consumption, no cold tank and no wasted sun, from the words of the user.
- IN-0008 (hot-water policy simulation): Which kinds of policy? → static, precomputed and dynamic, from the words of the user. The old strategies of IN-0001 (simulator) stay as they are.
- IN-0008 (hot-water policy simulation): Does the battery charge from the grid? → no. The battery charges only from the solar surplus, because the aim is self-consumption.
- JOB-simulate.R5: was "usage: sim run [options] | sim compare [options]", now "usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]".
- IN-0008 (hot-water policy simulation): Where do the new commands live? → in JOB-simulate, so that the usage lists them. The checks of IN-0001 that name the old usage line change with it.
- CAP-hotwater.R1: How much of its energy does the tank lose in an hour? → 0.4% of the stored energy (assumed)
- CAP-hotwater.R2: In which order do the draw and the heating run in an hour? → the draw first, then the heating (assumed)
- CAP-hotwater.R3: What comfort floor does the thermostat keep? → 3.0 kWh in the default tank (assumed)
- CAP-hotwater.R4: What is the hot-water draw profile? → peaks at 07:00 and 19:00, with a seasonal factor of 0.15 and the peak days of the load (assumed)
- CAP-policy.R1: What happens to a heating window past the end of the day, and to a discharge hour of 24? → the window stops at the end of the day, and 24 never lets the battery discharge (assumed)
- CAP-policy.R2: How does the day-ahead plan size and place the heating? → the need is the target less the tank energy plus the expected draw, placed in the sunniest hours, and a tie goes to the earlier hour (assumed)
- CAP-policy.R3: What surplus does a dynamic policy see? → a surplus of 0 or more (assumed)
- CAP-policy.R4: What are the default parameters of the policies? → a sensible start for the default tank (assumed)
- CAP-homesim.R1: What does a run start with, and when does a precomputed policy plan? → a full tank and an empty battery, and a plan at hour 0 from the fetch at hour 0, with the forecast made only for a policy that reads it (assumed)
- CAP-homesim.R2: What does no cold tank mean? → no unmet draw, and the tank ends each hour at or above the comfort floor (assumed)
- CAP-homesim.R3: What is a ratio with nothing to divide by? → 0% (assumed)
- CAP-homesim.R5: What does an evaluation of 0 seeds give? → 0 in every field (assumed)
- CAP-homesim.R6: How does the tuner rank its candidates? → the safe candidate with the highest mean self-consumption, then the lowest mean import within 0.05 points, then the first in order, and the lowest total unmet draw if none is safe (assumed)
- JOB-simulate.R6: What are the defaults and ranges of the forecast options? → --hour 0, --lon 174.8 and --forecast-error 1, with the ranges of the requirement (assumed)
- JOB-simulate.R7: What do the lines of the policy run look like, and what are the defaults? → a label, spaces to column 19 and a value, with the defaults of the home and the policies (assumed)
- JOB-simulate.R8: What header and rows does the policy comparison print? → the header of the requirement, and the rows thermostat, static, precomputed and dynamic (assumed)
- JOB-simulate.R9: What do the columns of the robust table mean, and what is the default of --seeds? → the header of the requirement, and 10 seeds (assumed)
- JOB-simulate.R10: What is the default of --seeds for the tuner? → 5 seeds (assumed)
- JOB-simulate.R11: What are the ranges of the policy options? → the table of the requirement (assumed)

## Handoff

Handoff · IN-0008 · change → acceptance

Time: 2026-11-15T10:50:24+00:00

### Done

- Change planned six changes, in the order of their entries: CH-0006 (forecast-fast), CH-0007 (hotwater), CH-0008 (gated-battery), CH-0009 (policy), CH-0010 (homesim) and CH-0011 (policy-commands).
- The skill added the Interface of CAP-strategies (battery and load strategies) from the code, because the checks of CH-0008 call a strategy. No behaviour changed.

### Decided on defaults

- none

### Open

- none

### Look here

- The Interface of each change spec in `pdlc/changes/`.

### Don't redo

- The six change specs and their order.

### Next: do this first

Write the acceptance checks of IN-0008 in `tests/acceptance/IN-0008.acceptance.lean`. They prove the commands through the `sim` process, and the capabilities through the library.
