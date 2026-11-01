Result: fail

Remit: tests

Problems:
- tests/CAP-simulation.lean:36 · The packet does not hold the Interface of CH-0001 (scenario) or CH-0002 (strategies). Thus, I cannot confirm that a correct app passes the checks. The checks use these names that the packet does not define: `Site` with `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh` (line 36). `Hour` with `day`, `dayOfYear`, `hour`, `sky`, `pvKwh`, `baseLoadKwh` and `flexKwh`, and a `BEq` on the sky (line 89). `scenario site seed days` that gives an `Array Hour` (line 244). `Strategy.placeFlex s pv fl` on two `Array Float` that gives an `Array Float` (line 83). `Strategy.greedy`, `Strategy.none`, `Strategy.evening` and `Strategy.shift` (line 183 and later). A wrong name or type fails each check, also on a correct app. Add the two Interfaces to the packet, and review these names again. · Remit rule "A correct app passes each check", and the reviewer rule "If something that you need is missing, report the missing item as a problem"

Wrong versions:
- R1 the efficiency is 0.95 · `efficiency := 0.9` · fails (0.9 is not near 0.95)
- R1 an empty battery ... holds 1.9 kWh · no charge loss, so the battery holds 2 · fails (soc 2, want 1.9)
- R1 a full battery takes 0 kWh ... · no free-room limit, so the battery takes 2 · fails (charge 2, want 0)
- R1 9.05 kWh stored takes 1 kWh ... · free room limits the charge with no loss, so the charge is 0.95 · fails (charge 0.95, want 1)
- R1 9 kWh stored takes 1/0.95 kWh ... · the code ignores the loss in the free room, so the charge is 1 and the battery holds 9.95 · fails (charge 1, want 1.0526)
- R1 a battery with 2 kW of power takes 2 kWh ... · the power limits the stored energy, so the charge is 2/0.95 · fails (charge 2.105, want 2)
- R1 1.9 kWh stored gives 1.805 kWh ... · no discharge loss, so the battery gives 1.9 · fails (discharge 1.9, want 1.805)
- R1 0.5 kWh of solar and 2.5 kWh of load ... · the shortfall is the full load, 2.5 · fails (direct 0, want 0.5)
- R1 5 kWh stored gives 2 kWh ... · the store loses only the given 2 kWh, so it holds 3 · fails (soc 3, want 2.895)
- R1 none with 1.9 kWh stored exports 2 kWh ... · the code ignores the strategy and charges · fails (charge 2, want 0)
- R1 none with 1.9 kWh stored imports ... · the code ignores the strategy and discharges · fails (discharge 1.805, want 0)
- R1 evening at 16:00 ... gives 0 kWh · `stepHour` gives hour 0 to `decide` in place of the hour · passes; the 17:00 check catches it (discharge 0, want 1.805)
- R1 evening at 17:00 ... gives 1.805 kWh · `stepHour` gives hour 0 to `decide` · fails (discharge 0, want 1.805)
- R1 the first hour of greedy ... imports its full load · the battery starts full · fails (discharge > 0, import < load)
- R1 the hours of a run are the hours of the scenario · `simulate` uses seed 0 in place of `seed` · fails (`sameHour` finds a different sky)
- R1 each hour of greedy is the flow of stepHour ... · `simulate` resets the stored energy to 0 each day · fails (`badChain` finds hour 0 of day 1)
- R1 each hour of evening is the flow of stepHour ... · `simulate` passes the day number as the hour · fails (`badChain` finds an evening hour)
- R1 evening discharges only from 17:00 to 23:00 in a run · `simulate` always calls `decide` with `greedy` · fails (an hour before 17:00 discharges)
- R1 each hour of greedy has the base load and the default flexible load · `loadKwh` leaves out the flexible load · fails (`badLoad` finds day 0)
- R1 each hour of shift has ... the flexible load that placeFlex places · `simulate` ignores `placeFlex` · fails (`badLoad` finds a sunny day)
- R2 a battery with 2 kW of power takes all of a 2 kWh surplus · the limit uses `<` and takes 0 at the edge · fails (charge 0, want 2)
- R2 ... takes 2 kWh of a 2.5 kWh surplus · no power limit · fails (charge 2.5, want 2)
- R2 ... gives all of a 2 kWh shortfall · the power limits the drawn energy, so the battery gives 1.9 · fails (discharge 1.9, want 2)
- R2 ... gives 2 kWh of a 2.5 kWh shortfall · no power limit on the discharge · fails (discharge 2.5, want 2)
- R2 a full 5 kWh battery takes 0 kWh · the free room uses 10 kWh in place of the capacity · fails (charge 2, want 0)
- R2 a 5 kWh battery with 4 kWh stored takes 1/0.95 kWh ... · the free room ignores the loss · fails (charge 1, want 1.0526)
- R2 a 5 kWh battery with 2 kW of power charges and discharges 2 kWh or less · `simulate` uses a power of 5 kW · fails (a summer hour charges more than 2)
- R2 a 5 kWh battery ... holds 0 to 5 kWh each hour · no capacity limit in `simulate` · fails (soc over 5)
- R2 with a 10 kWh battery solar plus import equals ... · the totals leave out the discharge loss · fails (the gap is over 0.01)
- R2 each hour of a greedy run balances ... · `lossKwh` holds only the charge loss · fails (the third sum is off)
- R2 the energy of an evening run and of a shift run balances · `finalSocKwh` is 0 · fails (the gap is the stored energy)
- R2 a battery of 0 kWh takes 0 kWh and gives 0 kWh · a 0 kWh capacity means no limit · fails (charge 2, want 0)
- R2 with a battery of 0 kWh greedy and none have the same totals · the free room is negative and gives a negative charge · fails (`badTotals` finds export)
- R3 at latitude 45 each total of none equals the sum of its hours · `exportKwh` total counts only the last day · fails (export differs)
- R3 at latitude 45 each total of greedy equals the sum of its hours · `lossKwh` total is 0 · fails (losses differ)
- R3 the load total of greedy over 365 days is 7300 kWh · the load leaves out the flexible load · fails (6205, want 7300)
- R3 ... the self-consumption ... · the code divides by the load · fails (the solar and the load totals differ by more than 1)
- R3 ... the self-sufficiency ... · the code gives a fraction, not a percentage · fails (0.4, want 40)
- R3 0 kW of panels gives 0% ... · the code divides 0 by 0 · fails (NaN is not near 0)
- R3 0 days give each total 0 ... · the code divides 0 by 0, or gives one empty January · fails (NaN, or 1 month)
- R4 365 days give 12 months with 31, 28, ... · the code uses a leap year · fails (Feb has 29)
- R4 the solar totals of the 12 months add up ... · the last month is lost · fails (11 months)
- R4 the totals and the ratios of each month ... come from the hours of that month · the code uses 30-day months · fails (`badMonths` finds Jan)
- R4 400 days give 14 months ... · the code groups by the day of the year · fails (12 months)
- R4 366 days give 13 months ... · the code stops after December · fails (12 months)
- R4 10 days give one month, January with 10 days · the code always gives 12 months · fails (12 months)
- R4 31 days ... and 32 days add February with 1 day · the month ends one day early (`<` in place of `≤`) · fails (Jan 30 and Feb 1)
- R4 59 days end with February and 60 days add March with 1 day · a leap day · fails (Feb 29 at 60 days)
- R4 ... July has more than twice the solar energy of December · the months are in reverse order · fails (index 6 is not "Jul")
- R4 ... the July self-sufficiency is more than the January self-sufficiency · each month copies the ratios of the run · fails (the two are equal)
- R5 ... greedy has a higher self-consumption than none · `greedy` is not given to `stepHour` and no hour charges · fails (the two are equal)
- R5 ... evening has a self-consumption no higher than greedy · `greedy` never discharges, so its battery stays full · fails (evening frees room and exports less)
- R5 ... evening has a higher self-consumption than none · `evening` never charges · fails (the two are equal)
- R5 with a battery of 0 kWh shift has a higher self-consumption than none · `simulate` ignores `placeFlex` · fails (the two are equal)

Follow-ups: none

Notes:
- The checks of R5 line 2 (evening no higher than greedy) are weak alone, because a wrong `evening` that acts as `greedy` passes the line. The R1 checks at 16:00 and 17:00 and the run check of the evening hours catch such a version.
- The check "R5 ... evening has a higher self-consumption than none" comes from the requirement text ("a battery must raise the self-consumption"). It is in scope.
- `badChain` expects that each hour of `simulate` equals `stepHour` within 1e-9. A correct app that uses the same rules meets this. A correct app that computes the same rules in a different order can differ by a rounding error, but 1e-9 is far over such an error for values under 10 kWh.
- About 40 checks each run a full year. No check waits on a process, so no check can hang.
