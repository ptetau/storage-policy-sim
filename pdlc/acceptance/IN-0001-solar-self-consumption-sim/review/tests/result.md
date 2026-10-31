Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-simulation.R2 a battery with 2 kW of power charges and discharges 2 kWh or less · `stepHour` caps the discharge only by the ask, the shortfall and the stored energy, with no power cap · fails: `dis` (5 kWh stored, a 3 kWh shortfall at 19:00) gives `dischargeKwh` 3, not 2, so the line "discharge with a 3 kWh shortfall is 3, want 2" fails the check. A version with no charge cap also fails, because `chg` (empty battery, a 3 kWh surplus) gives `chargeKwh` 3, not 2.

Follow-ups: none

Notes:
- The earlier problem is fixed. The check no longer needs an hour of the seed-7 run that discharges exactly 2 kWh, so it no longer depends on the load profile of CAP-scenario.R3 (household load). The run-wide bound on each hour stays. The two `stepHour` calls make each power cap bind through the Interface of CH-0003 (simulation).
- The `dis` call expects `dischargeKwh` 2. This follows CAP-simulation.R1 (energy flows of an hour): "the battery gives what the strategy asks, up to ... the battery power for one hour", and the Interface defines `dischargeKwh` as the energy that the battery gives to the house, after the loss. A builder who applies the power cap to the energy that leaves the cell, before the loss, gets 1.9 kWh and fails this check. The spec text supports 2 kWh, but the builder of CH-0003 (simulation) should know that this check fixes the reading.
- The Open item in the handoff ("needs one hour that discharges exactly 2 kWh") no longer applies, and the handoff can drop it.
- The other three CAP-simulation.R2 (battery limits) checks did not change, so this review did not judge them.
