Result: pass

Remit: specification

Problems: none

Follow-ups: none

Notes:
- CAP-simulation.R1 (energy flows of an hour): I traced each of the six single-hour lines through `stepHour`. Each line gives the stated values. For example, 1.9 kWh stored and a shortfall of 2 kWh give a discharge of 1.805 kWh and an import of 0.195 kWh.
- CAP-simulation.R1 (energy flows of an hour): the first hour of a run starts with an empty battery (`socKwh` is 0). Thus, the battery cannot give energy in that hour.
- CAP-simulation.R2 (battery limits): the flows balance in each hour. Solar plus import equals load, export, loss, and the change of the stored energy. The charge limit (free room divided by the efficiency) keeps the stored energy at or below the capacity. The discharge limit (stored energy times the efficiency) keeps the stored energy at or above 0.
- CAP-simulation.R2 (battery limits): `stepHour` applies the power limit to `dischargeKwh`, which is the energy after the loss. The energy that leaves the battery can thus be up to the power divided by 0.95. The Interface defines `dischargeKwh` as the energy after the loss, and a code comment gives this choice. Thus, I read "discharges over 2 kWh" as `dischargeKwh`, and the code meets the line.
- CAP-simulation.R2 (battery limits): with a battery of 0 kWh, the free room and the stored energy are 0. Thus, `greedy` gives the same flows as `none`.
- CAP-simulation.R3 (totals and ratios): `percent` gives 0% when the divisor is 0. With 0 kW of panels, the import equals the load exactly. Thus, the self-sufficiency is 0%. With 0 days, the loop does not run, each total is 0, and `months` is empty.
- CAP-simulation.R4 (monthly totals): `simulate` uses `daysInYear`, which is not in this packet. I think that `daysInYear` comes from `StoragePolicySim/Scenario.lean`, because CAP-scenario.R2 (daily weather) starts the day of the year again after day 364. If `daysInYear` is 365, a run of 400 days gives 14 months, and the last month is February with 4 days. The Interface of CH-0001 (scenario) does not list `daysInYear`. This gap is not a problem for this remit.
- CAP-simulation.R4 (monthly totals) and CAP-simulation.R5 (strategy order): the lines about July, December, January, and the strategy order depend on the weather numbers. I cannot calculate these numbers from the packet. The code computes the monthly and run totals correctly, and the progress log says that the checks pass.
- CAP-simulation.R2, R3, and R4 (the lines that run a scenario): some lines do not give the site, for example the R3 line "Given 0 days" and the R4 line "Given 10 days". This gap is in the spec text, not in the code. The checks must select a site for these lines.
- `limitTo` sets a negative limit to 0. No acceptance line asks for this behaviour, but the behaviour has no effect when the inputs are valid. Thus, I did not record it as a problem.
- Files: the diff changes only `StoragePolicySim/Simulation.lean`, which is the only entry in "Files".
- Writing check: the check gave no findings. I read the spec text and the code comments again and found no break of DES-writing-style (how pdlc writes).
