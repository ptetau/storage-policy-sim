Result: fail

Remit: tests

Problems:
- tests/CAP-hotwater.lean:692 · The check "CAP-hotwater.R6 the seeds 7 and 8 do not give the same stream shifted by one day" can fail a correct app. The spec says only that z depends on the seed and the day, and that seeds 7 and 8 differ on at least 300 of 365 days. It leaves open how the seed and the day combine. An app that takes z from a hash of seed + day passes every R6 (daily draw factor) line and has the right statistics. In that app, seed 8 on day d equals seed 7 on day d + 1, so both parts of this check fail. Remove the check, or limit it to what the spec says · remit rule "A correct app passes each check", CAP-hotwater.R6 (daily draw factor)
- tests/CAP-hotwater.lean:583 · The check "CAP-hotwater.R5 the start state of the default tank is full with the thermostat off and fullToday true" tests `startState` with the default tank only. A `startState` that ignores its tank and returns 10.5 kWh passes it. The Interface says `startState` takes a tank and gives the state of a full tank. The file already tests each other field of the tank with a non-default value. Add a check with a capacity other than 10.5 kWh, for example 6.0 kWh, that expects that capacity in `energyKwh` · remit rule "A rule about every member of a class that the check tests without a non-member", CAP-hotwater.R5 (daily full heating) and the Interface entry `startState`

Wrong versions:
- CAP-hotwater.R1 8.0 kWh stored and no draw · the loss is taken on the capacity, 0.063 kWh · fails (loss 0.048)
- CAP-hotwater.R1 8.0 kWh stored and a draw of 1.5 kWh · the loss is taken after the draw, 0.039 kWh · fails (loss 0.048)
- CAP-hotwater.R1 1.0 kWh stored and a draw of 2.0 kWh · the unmet draw is taken from the energy before the loss, 1.0 kWh · fails (unmet 1.006, served 0.994)
- CAP-hotwater.R1 0.0 kWh stored and a draw of 1.0 kWh · the tank serves the draw and goes negative · fails (served 0.0)
- CAP-hotwater.R1 10.5 kWh stored and no draw · the loss is a fixed 0.048 kWh · fails (loss 0.063)
- CAP-hotwater.R1 a tank with no loss · the loss share is fixed at 0.006 · fails (tank 4.994)
- CAP-hotwater.R1 a draw above the stored energy · the tank goes negative, -1.006 kWh · fails (tank 0.0)
- CAP-hotwater.R1 a loss share of 0.01 · the loss share is fixed at 0.006 · fails (loss 0.08)
- CAP-hotwater.R1 the default tank fields · the guard hour is 21 or the floor is 2.0 · fails (each field has an exact value)
- CAP-hotwater.R2 5.0 kWh stored and a request of 2.0 kWh · the loss is taken after the heating, tank 6.958 · fails (tank 6.97)
- CAP-hotwater.R2 5.0 kWh stored and a request of 5.0 kWh · no element cap, heating 5.0 kWh · fails (heating 3.0)
- CAP-hotwater.R2 9.0 kWh stored and a request of 3.0 kWh · the room is taken before the loss, heating 1.5 kWh · fails (heating 1.554)
- CAP-hotwater.R2 10.5 kWh stored and a request of 3.0 kWh · the room is taken before the loss, heating 0 kWh · fails (heating 0.063)
- CAP-hotwater.R2 5.0 kWh stored and a request of 0 kWh · the request is ignored, heating 3.0 kWh · fails (heating 0.0)
- CAP-hotwater.R2 the draw comes before the heating · the heating comes before the draw, unmet 0 kWh · fails (unmet 0.512)
- CAP-hotwater.R2 a tank with a capacity of 0 kWh · no room cap, heating 3.0 kWh · fails (heating 0.0)
- CAP-hotwater.R2 an element of 1.0 kW · the element is fixed at 3.0 kW · fails (heating 1.0)
- CAP-hotwater.R2 a capacity of 6.0 kWh · the capacity is fixed at 10.5 kWh · fails (heating 1.03)
- CAP-hotwater.R2 sweep of the default tank · the loss is taken on the capacity · fails (loss rule)
- CAP-hotwater.R2 sweep of a tank with other limits · the element is fixed at 3.0 kW · fails (heating above 2.0 at a request of 4.0)
- CAP-hotwater.R3 a tank at 5.0 kWh · the thermostat never cuts in · fails (backstop 3.0)
- CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat off · the cut-in is 6.5 kWh · fails (backstop 0.0)
- CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat on · the thermostat decides by the level alone, with no state · fails (backstop 3.0)
- CAP-hotwater.R3 a tank at 9.0 kWh with the thermostat on · the thermostat stays on when the tank is full · fails (thermostat off)
- CAP-hotwater.R3 a request of 2.0 kWh at 5.0 kWh · the thermostat decides before the heating of the policy · fails (backstop 0.0)
- CAP-hotwater.R3 a request of 1.0 kWh at 4.0 kWh · the backstop heating is the whole element, 3.0 kWh · fails (backstop 2.0)
- CAP-hotwater.R3 a request of 1.0 kWh at 9.0 kWh with the thermostat on · the room ignores the heating of the policy, backstop 1.554 kWh · fails (backstop 0.554)
- CAP-hotwater.R3 a draw that empties the tank · no backstop heating when the tank is empty · fails (backstop 3.0)
- CAP-hotwater.R3 a cut-in of 0 kWh · the cut-in is fixed at 5.25 kWh · fails (backstop 0.0)
- CAP-hotwater.R3 5.25 kWh and 5.24 kWh with no loss · the thermostat cuts in at "at most" the cut-in · fails (backstop 3.0 at 5.25)
- CAP-hotwater.R3 5.26 kWh falls below the cut-in after the loss · the thermostat decides on the energy before the loss · fails (backstop 0.0)
- CAP-hotwater.R3 5.4 kWh with a draw of 0.2 kWh · the thermostat decides on the energy before the draw · fails (backstop 0.0)
- CAP-hotwater.R3 a cut-in of 7.0 kWh · the cut-in is fixed at 5.25 kWh · fails (backstop 0.0 at 6.0)
- CAP-hotwater.R3 a cold tank for three hours · the thermostat goes off once the level passes the cut-in, with no dead band · fails (hour 13 backstop 0.0)
- CAP-hotwater.R3 sweep of the default tank · the thermostat ignores its state, with no dead band · fails (backstop rule)
- CAP-hotwater.R3 sweep of a tank with other limits · the cut-in is fixed at 5.25 kWh · fails (backstop at levels from 5.25 to 7.0 kWh)
- CAP-hotwater.R4 the sum of days 0 to 364 · the shares of the hours add up to 1.05 · fails (sum 2299.5)
- CAP-hotwater.R4 the 24 hours of day 100 · the peak of the season is day 16 · fails (difference 0.015 kWh, tolerance 0.000001)
- CAP-hotwater.R4 day 15 against day 197 at latitude 45 · the peak is day 197 at a positive latitude · fails (ratio 0.74)
- CAP-hotwater.R4 day 197 against day 15 at latitude -41 · the sign of the latitude is ignored · fails (ratio 0.74)
- CAP-hotwater.R4 hour 7 against hour 3, hour 19 against hour 13 · all hours have the same share · fails (strict "more than")
- CAP-hotwater.R4 a daily energy of 0.0 kWh · the profile adds a constant to each hour · fails (draw above 0)
- CAP-hotwater.R4 each day at latitude 45 · the season uses Nat subtraction of the peak, which cuts days before day 15 to 0 · fails (days 0 to 14)
- CAP-hotwater.R4 each day at latitude -41 · the season uses Nat subtraction of the peak, which cuts days before day 197 to 0 · fails (days 0 to 196)
- CAP-hotwater.R4 the peak at latitudes 0, 10, 80, -0.5 and -80 · the test is `latitude > 0` instead of `latitude ≥ 0` · fails (latitude 0)
- CAP-hotwater.R4 the same share of each hour on three days · the shape of the profile shifts with the season · fails (shares differ)
- CAP-hotwater.R4 12.0 kWh against 6.0 kWh · the draw adds a fixed amount to the daily energy · fails (not twice)
- CAP-hotwater.R5 hour 20, 9.0 kWh, not full today · the guard test is `hour > guardHour` · fails (backstop 0.0)
- CAP-hotwater.R5 hour 19, 9.0 kWh, not full today · the guard starts one hour early · fails (backstop above 0)
- CAP-hotwater.R5 hour 20, 9.0 kWh, full today · the guard ignores `fullToday` · fails (backstop 1.554)
- CAP-hotwater.R5 hour 22, 4.0 kWh, not full today · the thermostat state stays off after a late backstop heating · fails (thermostat on)
- CAP-hotwater.R5 hour 0, 10.5 kWh, full the day before · `fullToday` is not reset at hour 0 · fails (fullToday false)
- CAP-hotwater.R5 hour 0, 10.5 kWh, request 3.0 kWh · `fullToday` is false at every hour 0 · fails (fullToday true)
- CAP-hotwater.R5 hour 12, 9.0 kWh, not full today · the guard is active at every hour · fails (backstop 0.0)
- CAP-hotwater.R5 a guard hour of 24 · the guard hour is fixed at 20 · fails (backstop 0.0 at hour 23)
- CAP-hotwater.R5 the start state of the default tank · `startState` gives `fullToday` false · fails
- CAP-hotwater.R5 `fullToday` stays true · `fullToday` is set from the energy at the end of each hour · fails (hour 1 gives false)
- CAP-hotwater.R5 0.0000000005 and 0.000000002 kWh below the capacity · "full" means exact equality, or a tolerance of 0.000001 · fails (case a, or case b)
- CAP-hotwater.R5 a guard hour of 10 · the guard hour is fixed at 20 · fails (backstop 0.0 at hour 10)
- CAP-hotwater.R5 a tank at 6.0 kWh over hours 20 to 23 · the guard does not turn the thermostat on, so the state is off after hour 20 · fails (thermostat on at hour 20)
- CAP-hotwater.R5 a quiet day of the default tank · the guard heats at hour 21 as well, or at hour 19 · fails (hour 19 or hour 21 values)
- CAP-hotwater.R5 sweep of the default tank · `fullToday` is set from the energy at the end of each hour · fails (hour 12, fullToday true, 9.9 kWh)
- CAP-hotwater.R5 sweep of a tank with other limits · `fullToday` is not reset at hour 0 · fails (hour 0, fullToday true, 4.0 kWh)
- CAP-hotwater.R6 a spread of 0 · a spread of 0 is read as the default spread 0.25 · fails (factor not 1.0)
- CAP-hotwater.R6 seed 7 and a spread of 0.25 · the factor is `exp(cv × z)` with no `- cv × cv / 2` term · fails (mean 1.032, above 1.02)
- CAP-hotwater.R6 seed 7 and a spread of 0.5 · the factor is `exp(cv × z)` with no `- cv × cv / 2` term · fails (mean 1.13)
- CAP-hotwater.R6 the same day two times · the factor reads a global counter or the clock · fails (two reads differ)
- CAP-hotwater.R6 seeds 7 and 8 differ on 300 days · the seed is ignored · fails (0 days differ)
- CAP-hotwater.R6 the seeds 0, 1 and 99991 · a generator that gets stuck at seed 0 · fails (a factor not above 0, or a wrong spread)
- CAP-hotwater.R6 not the same stream shifted by one day · seed 8 is seed 7 shifted by one day · fails (see the first problem: a correct app that hashes seed + day also fails)
- CAP-hotwater.R6 a different factor on at least 300 of 364 days that follow a day · one number is kept for seven days · fails (about 52 days differ)
- CAP-hotwater.R6 the same z for the spreads 0.1, 0.25 and 0.5 · the seed of z is mixed with the spread · fails (z differs)
- CAP-hotwater.R6 z of seed 7 is from a normal curve · z is uniform with the same mean and spread · fails (excess kurtosis -1.2)

Follow-ups:
none

Notes:
- All 42 acceptance lines of CAP-hotwater R1 to R6 have a check with the numbers of the spec. Each name starts with its requirement ID and a space. The checks use only the Interface and the seam `drawSeed` (the seed argument). The Interface lists no error, so no check expects an error. No check uses the clock.
- The extra checks of R1 to R5 follow the spec text. I found no open detail that makes them fail a correct app. The thermostat check "a tank at 6.0 kWh over hours 20 to 23" asserts that the thermostat is on after a guard-only cut-in. The spec text for R5 (daily full heating) says it "stays on until the tank is full, as in R3", so I accept it.
- The statistical checks keep a margin of 4.2 standard errors or more. The narrowest is the mean of z over 5000 days (limit 0.06), where a correct generator fails about 2 times in 100000. The spec lines use the same width. I do not count this as a problem.
- Gap, not a problem: no check pins the peak hours of R4 (hot-water draw profile). A profile with peaks at hours 8 and 20 passes every R4 check, because the line only says hour 7 draws more than hour 3 and hour 19 draws more than hour 13.
- Gap, not a problem: no check proves that the room for the heating of the policy is taken after the draw. The R2 sweep tests only the upper limits of the heating. A version that takes the room before the draw is served passes R2.
- The default-tank sweeps include the state "10.5 kWh with the thermostat on". A real day never makes this state, but the spec flow gives one answer for it (backstop 0.063 kWh, thermostat off), so a correct app passes.
