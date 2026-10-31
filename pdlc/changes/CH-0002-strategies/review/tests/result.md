Result: fail

Remit: tests

Problems:
- tests/CAP-strategies.lean:192 · The three sunniest hours of `sunDay` are 11:00, 12:00 and 13:00, and these hours are next to each other. Thus, a wrong `shift` that takes the best window of three hours in a row also passes. The windows of `sunDay` sum to 9 (10:00 to 12:00), 10.5 (11:00 to 13:00) and 9 (12:00 to 14:00), so the window rule also picks 11:00 to 13:00. No other R5 check catches this version: the 4.5 kWh check uses `sunDay` too, `flatSun` gives the same result to both rules, and the no-sun and 0 kWh checks do not depend on the rule. Add a check with three top hours that are not next to each other, for example sun 4 at 09:00, 1 at 10:00 to 12:00, and 3.5 and 3 at 14:00 and 15:00. Then the result must be 1 kWh at 09:00, 14:00 and 15:00. · CAP-strategies.R5 ("the three hours with the most solar output"), and the remit rule that each check fails on a plausible wrong version (the trap "examples that also fit a wrong rule")

Wrong versions:
- CAP-strategies.R1 the list is none, greedy, evening and shift, in this order · `Strategy.all` in alphabetical order (evening, greedy, none, shift) · fails
- CAP-strategies.R1 the names of the list are none, greedy, evening and shift · `Strategy.name` gives "Greedy" with a capital letter · fails
- CAP-strategies.R1 the name "greedy" finds the greedy strategy · `ofName?` compares against the wrong field and gives `Option.none` for each name · fails
- CAP-strategies.R1 each name of the list finds its own strategy · `ofName?` gives `Strategy.greedy` for each name that it knows · fails (the value "none" gives greedy)
- CAP-strategies.R1 the name "Greedy" finds no strategy · `ofName?` compares names in lower case · fails
- CAP-strategies.R1 the name "" finds no strategy · `ofName?` matches when the input is a prefix of a name · fails (the empty string is a prefix of "none")
- CAP-strategies.R1 names close to "greedy" find no strategy · `ofName?` trims spaces before it compares · fails (" greedy" finds greedy)
- CAP-strategies.R2 a surplus of 2 kWh at 12:00 asks none to charge 0 and discharge 0 · `none` charges as `greedy` does · fails (charge 2)
- CAP-strategies.R2 a shortfall of 1.5 kWh at 19:00 asks none to charge 0 and discharge 0 · `none` discharges in the evening as `evening` does · fails (discharge 1.5)
- CAP-strategies.R2 none keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00 · `none` places the load as `shift` does · fails (hour 11 has 1 kWh)
- CAP-strategies.R2 none does not change a flexible load at other hours · `none` returns a fixed 1 kWh at 18:00 to 20:00 · fails (hour 7 has 0, not 0.5)
- CAP-strategies.R3 a surplus of 2 kWh at 12:00 asks greedy to charge 2 and discharge 0 · `greedy` swaps the charge and the discharge · fails
- CAP-strategies.R3 a surplus of 0.7 kWh at 09:00 asks greedy to charge 0.7 and discharge 0 · `greedy` always asks to charge 2 kWh when there is a surplus · fails (charge 2, not 0.7)
- CAP-strategies.R3 a shortfall of 1.5 kWh at 03:00 asks greedy to charge 0 and discharge 1.5 · `greedy` discharges only from 17:00 to 23:59 · fails
- CAP-strategies.R3 a shortfall of 1.5 kWh at 13:00 asks greedy to charge 0 and discharge 1.5 · `greedy` discharges only in the hours without sun (before 06:00 and from 18:00) · fails
- CAP-strategies.R3 no surplus and no shortfall at 19:00 asks greedy to charge 0 and discharge 0 · `greedy` asks for a fixed 0.5 kWh discharge in the evening · fails
- CAP-strategies.R3 greedy keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00 · `greedy` places the load as `shift` does · fails
- CAP-strategies.R3 greedy does not change a flexible load at other hours · `greedy` returns a fixed 1 kWh at 18:00 to 20:00 · fails
- CAP-strategies.R4 a surplus of 2 kWh at 12:00 asks evening to charge 2 and discharge 0 · `evening` never charges · fails
- CAP-strategies.R4 a surplus of 0.7 kWh at 19:00 asks evening to charge 0.7 and discharge 0 · `evening` charges only before 17:00 · fails
- CAP-strategies.R4 a shortfall of 1.5 kWh at 16:00 asks evening to discharge 0 · `evening` discharges from hour 16 · fails
- CAP-strategies.R4 a shortfall of 1.5 kWh at 17:00 asks evening to discharge 1.5 · `evening` discharges only when the hour is more than 17 · fails
- CAP-strategies.R4 a shortfall of 1.5 kWh at 23:00 asks evening to discharge 1.5 · `evening` discharges only when the hour is less than 23 · fails
- CAP-strategies.R4 a shortfall of 1.5 kWh at 00:00 asks evening to discharge 0 · `evening` treats 00:00 as the end of the evening (hour 0 or hour 17 and more) · fails
- CAP-strategies.R4 a shortfall of 0.4 kWh at 20:00 asks evening to discharge 0.4 · `evening` asks for a fixed 1.5 kWh in the evening · fails
- CAP-strategies.R4 evening keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00 · `evening` places the load as `shift` does · fails
- CAP-strategies.R4 evening does not change a flexible load at other hours · `evening` returns a fixed 1 kWh at 18:00 to 20:00 · fails
- CAP-strategies.R5 a surplus of 2 kWh at 12:00 asks shift to charge 2 and discharge 0 · `shift` uses the battery as `none` does · fails
- CAP-strategies.R5 a shortfall of 1.5 kWh at 03:00 asks shift to discharge 1.5 · `shift` discharges as `evening` does · fails
- CAP-strategies.R5 3 kWh with the most sun at 13:00, 11:00 and 12:00 gives each 1 kWh · `shift` takes the window of three hours in a row with the most sun · passes (see Problems)
- CAP-strategies.R5 4.5 kWh at other default hours gives 1.5 kWh at 11:00, 12:00 and 13:00 · `shift` always puts 1 kWh in each of the three hours · fails (1, not 1.5)
- CAP-strategies.R5 equal sun from 10:00 to 14:00 gives 1 kWh at 10:00, 11:00 and 12:00 · `shift` gives a tie to the later hour · fails (12:00 to 14:00)
- CAP-strategies.R5 3 kWh and no sun stays at 18:00, 19:00 and 20:00 · `shift` sorts all hours and takes 00:00 to 02:00 when no hour has sun · fails
- CAP-strategies.R5 0 kWh and sun at 12:00 gives 0 kWh of flexible load in each hour · `shift` puts a fixed 1 kWh in each of the three sunniest hours · fails

Follow-ups:
- R5 (load shift into sun) does not say what happens on a day with sun in only one or two hours and some flexible load. A new intent could decide whether the load goes to the hours with no sun or stays at its default hours, and add a line for it.

Notes:
- Each acceptance line of R1 to R5 has at least one check. Each check name starts with its requirement ID. The checks of each requirement sit under one `-- CAP-strategies.Rn` comment.
- The checks use only the Interface entries. The Interface lists no error code and no test seam, and no line depends on the clock. No check waits on anything, so no check can hang.
- The R4 checks test the edge at 17:00 with 16:00 and 17:00, and the edge at 23:59 with 23:00 and 00:00.
- `badDay` compares all 24 hours, so a version that adds the moved load and keeps the old load also fails.
