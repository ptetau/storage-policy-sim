Result: pass

Remit: privacy

Problems: none

Follow-ups: none

Notes:
- Not applicable. The change touches no personal data. It adds a hot-water tank model: energy in kWh, a fixed draw profile, a season factor, and a random factor from a seed and a day number. No input names or identifies a person. The code does not log, print, store, or send any data.
- Earlier problems: none. There was nothing to check again.
- The diff since the earlier review moves the test "was the tank full earlier today" into a new private helper, `fullEarlierToday`. It adds no data, no output, and no new place that data goes to. It raises no privacy problem.
