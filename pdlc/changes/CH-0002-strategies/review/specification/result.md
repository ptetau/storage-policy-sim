Result: fail

Remit: specification

Problems:
- pdlc/changes/CH-0002-strategies/change.md:"Progress log", item 1 · The text "Planned after CH-0001 (scenario), so that the simulation can use both." omits the subject and the verb. Also, the pronoun "both" has no noun in the same item that it can refer to. Write, for example, "The plan puts this change after CH-0001 (scenario models), so that the simulation can use the scenario and the strategies." · DES-writing-style 4.2 (do not omit words) and the local-references rule
- pdlc/changes/CH-0002-strategies/change.md:"Progress log", item 2 · The text "The test writer added a check with hours apart, round 1 of 2." is not clear. "With hours apart" does not say which hours are apart. "Round 1 of 2" omits the subject and the verb. Write, for example, "The test writer added a check in which the three sunniest hours are not next to each other. This was round 1 of 2." · DES-writing-style 4.1 (accurate facts), GR-2 (one meaning with "with") and 4.2 (do not omit words)

Follow-ups:
- `shift` on a day with sun in fewer than three hours: `shiftIntoSun` takes the three top hours by sun, and ties go to the earlier hour. Thus, with sun only at 12:00, the flexible load goes to 12:00, 00:00 and 01:00. The spec permits this result, because the hours 00:00 and 01:00 tie for the next-most sun. A new intent can limit `shift` to hours with sun, and keep the remainder at the default hours, so that `shift` does not move load into the night.
- `shift` with a `NaN` value in `pvKwh`: the comparison in `hoursBySun` gives no stable order for `NaN`. No acceptance line names this input. A new intent can define the result for solar values that are not numbers.

Notes:
- R1 (strategy names): `Strategy.all` gives none, greedy, evening and shift, in this order. `Strategy.ofName?` matches exactly, so "Greedy" and "" give `Option.none`.
- R2 (no battery use): `none` asks for 0 kWh and 0 kWh, and keeps the flexible load.
- R3 (greedy battery use): `greedy` asks for the full surplus and the full shortfall at each hour, and keeps the flexible load.
- R4 (evening battery use): `evening` charges with the full surplus. `evening` discharges only when the hour is 17 or more, so 16:00 and 00:00 give 0 kWh, and 17:00 and 23:00 give 1.5 kWh. The interface limits the hour to 0 to 23.
- R5 (load shift into sun): `shift` uses the battery as `greedy` does. The sort in `hoursBySun` puts more sun first, and puts the earlier hour first for equal sun. Thus, equal sun from 10:00 to 14:00 gives 10:00, 11:00 and 12:00. A day with no sun keeps the default hours. A total of 0 kWh gives 0 kWh at each hour.
- Only `StoragePolicySim/Strategy.lean` changed, and "Files" lists this file. The change stays in CAP-strategies (battery and load strategies).
- The title and the summary of CAP-strategies show the four strategies as the code builds them. "Files" lists no README.
- The code comments in `StoragePolicySim/Strategy.lean` follow DES-writing-style. Some doc comments are noun phrases, for example "No battery use.". I judge these as labels for items, not as sentences with omitted words. The spec summary uses the same labels.
- The writing check gave no findings. The two problems above are in rules that a script cannot measure.
