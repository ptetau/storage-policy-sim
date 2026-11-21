Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-strategies.R5 3 kWh with the most sun at 09:00, 14:00 and 15:00 gives each 1 kWh · `shift` takes the best window of three hours in a row. The window sums are 6.5 for 13:00 to 15:00 and 6.5 for 14:00 to 16:00, so the window rule gives 13:00, 14:00 and 15:00. Hour 9 then has 0 kWh, not 1 kWh · fails
- CAP-strategies.R5 3 kWh with the most sun at 09:00, 14:00 and 15:00 gives each 1 kWh · `shift` takes the peak hour (09:00) and its two neighbours (08:00 and 10:00). Hour 14 then has 0 kWh, not 1 kWh · fails
- CAP-strategies.R5 3 kWh with the most sun at 09:00, 14:00 and 15:00 gives each 1 kWh · `shift` takes the first three hours with sun (09:00, 10:00 and 11:00). Hour 14 then has 0 kWh, not 1 kWh · fails

Follow-ups: none

Notes:
- The earlier problem at tests/CAP-strategies.lean:192 (a window rule also passes the `sunDay` check) is fixed. The new check at tests/CAP-strategies.lean:198 has three top hours that are not next to each other: 09:00 (4 kWh), 14:00 (3.5 kWh) and 15:00 (3 kWh).
- The fourth hour has 1 kWh, well below 3 kWh. Thus, the top three hours have no tie, and the expected result does not depend on the tie rule. The `flatSun` check still proves the tie rule.
- The comment above the new check is correct: the two best windows tie at 6.5, and each window misses 09:00.
- The new check reads the result only through `Strategy.placeFlex`, and its name starts with the requirement ID CAP-strategies.R5 (load shift into sun).
