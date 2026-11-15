Result: pass

Remit: tests

Problems: none

Wrong versions:
- CAP-hotwater.R5 the start state of a tank with a capacity of 6.0 kWh holds 6.0 kWh with the thermostat off and fullToday true · a `startState` that ignores its tank and returns 10.5 kWh · fails (the tank holds 10.5 kWh, and the check wants 6.0 kWh within 1e-9)
- CAP-hotwater.R5 the start state of a tank with a capacity of 6.0 kWh holds 6.0 kWh with the thermostat off and fullToday true · a `startState` that returns the cut-in level or the floor level in place of the capacity · fails (5.25 kWh or 2.1 kWh is not 6.0 kWh)
- CAP-hotwater.R5 the start state of a tank with a capacity of 6.0 kWh holds 6.0 kWh with the thermostat off and fullToday true · a `startState` that sets the thermostat on or `fullToday` false · fails (the check reads both fields)

Follow-ups: none

Notes:
- Earlier problem 1 (the check "CAP-hotwater.R6 the seeds 7 and 8 do not give the same stream shifted by one day") is fixed. The diff removes the check, and the file at this lock no longer holds it. The line of the seeds 7 and 8 still has its check, "CAP-hotwater.R6 seeds 7 and 8 give a different factor on at least 300 of the days 0 to 364". That check did not change.
- Earlier problem 2 (the start state tested with the default tank only) is fixed. The new check calls `startState` with a tank of 6.0 kWh, reads the result through the Interface, and has the requirement ID CAP-hotwater.R5 in its name. A correct app returns a full tank of 6.0 kWh, so the check passes a correct app.
- The two changes add no other check, and no helper that a line of the diff leaves broken.
