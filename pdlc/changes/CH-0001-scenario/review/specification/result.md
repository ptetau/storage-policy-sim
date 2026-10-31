Result: fail

Remit: specification

Problems:
- pdlc/specs/capabilities/CAP-scenario.md:"What it is for", first sentence · The sentence "makes the world that a strategy must deal with" uses the phrasal verb "deal with". Write, for example, "makes the world that a strategy must manage, one hour at a time." · DES-writing-style rule 9.3 (do not use phrasal verbs)

Follow-ups:
none

Notes:
- The code meets each acceptance line of CAP-scenario.R1 (seasonal sun), CAP-scenario.R2 (daily weather) and CAP-scenario.R3 (household load). I calculated these values by hand:
  - R1 at 12:00: latitude 45 gives a sine of 0.924 on day 171 and 0.362 on day 354 (ratio 2.55). Latitude -41 gives 0.948 on day 354 and 0.426 on day 171 (ratio 2.23). At latitude 0, the declination is +23.44 and -23.44 degrees, so the two outputs are equal. At 00:00 on day 171, the sine is less than 0, so the output is 0.
  - R3: the hourly profile adds up to 1000. The seasonal factor adds up to 365 over a year. Thus, the total load is 17 × 365 + 3 × 365 = 7300 kWh. The base load of day 15 is 1.49996 times the base load of day 197. The profile gives 85 at 19:00, 30 at 13:00, 55 at 07:00 and 20 at 03:00.
  - R2: the weather keeps the previous sky with a chance of 0.6, and uses the chances of the half of the year that the spec gives. The skies come only from the seed, so two runs with the same seed give the same hours. The load does not read the seed.
- The code matches the Interface: `Sky`, `Sky.factor`, `Site`, `Hour`, `pvOutput` and `scenario`, with the listed fields and derived instances. `pvOutput` reads only `latitude` and `pvKw`.
- `daysInYear` is public, but the Interface does not list `daysInYear`. This is not a change in behaviour. Usually, a helper constant is `private`. Think about making it `private`, or add it to the Interface.
- The diff changes only the four entries of "Files". The packet does not show the diffs of the spec files. The writing check lists `pdlc/specs/jobs/JOB-simulate.md` as changed since main. I cannot see if that change belongs to this change (scope CAP-scenario) or to intake. Make sure that this change edits only the specs of its scope.
- "Files" lists no README. Thus, the rule about how the README tells you to run the checks does not apply.
- The Writing check gave no findings. I found one break that the linter does not find (the problem above).
- Field comments such as "Degrees. South is negative." and "The kW of the panels." are short labels. I did not count them as breaks of rule 4.2 (do not omit words). The Interface uses the same wording.
