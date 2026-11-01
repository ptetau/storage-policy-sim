Result: pass

Remit: privacy

Problems: none

Follow-ups: none

Notes:
- Not applicable. The change touches no personal data.
- `StoragePolicySim/Simulation.lean` takes a site, a battery, a strategy, a seed and a number of days. It gives energy flows and totals. No input or output names a person.
- The site holds a latitude only, with no longitude or address. The latitude sets the sun height, and it cannot identify a household alone.
- The code does no logging, no output, no file or network access, and no storage. The result exists only in memory for the caller.
