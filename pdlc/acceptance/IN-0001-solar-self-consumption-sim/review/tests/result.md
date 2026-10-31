Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-simulation.R2 a battery with 2 kW of power charges and discharges 2 kWh or less · `stepHour` limits the charge by the battery power, but limits the discharge only by the shortfall and the stored energy · fails. In an evening hour with a shortfall over 2 kWh and over 2.1 kWh stored, that version gives more than 2 kWh, and `bad` catches it. If no such hour exists, no hour gives exactly 2 kWh, and the new `capped` value (line 1766 of the packet, `near h.flow.dischargeKwh 2 1e-6`) is false. The check then reports "no hour discharges 2 kWh".

Follow-ups: none

Notes:
- The earlier problem is fixed. The changed check now needs at least one hour where the discharge cap binds. Thus, a version with no discharge cap cannot pass.
- The new `capped` condition depends on the load profile, which the packet does not give. A correct app passes only if at least one hour of the run has a shortfall of 2 kWh or more while the battery holds 2.105 kWh or more (2 / 0.95). With 20 kWh of daily load, an evening peak, and 1 kWh of flexible load at 18:00 to 20:00, such an hour is likely. If the check fails on the built code with "no hour discharges 2 kWh", look at the load profile before you change the code.
- The check reads `dischargeKwh` as the energy after the loss. CAP-simulation.R1 (energy flows of an hour) and the CH-0003 (simulation) Interface agree: "the battery gives" up to the battery power for one hour. Thus, a version that caps the energy before the loss at 2 kWh (and gives only 1.9 kWh) is wrong, and the check correctly fails it.
