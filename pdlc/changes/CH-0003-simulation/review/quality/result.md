Result: pass

Remit: quality

Problems: none

Follow-ups: none

Notes:
- StoragePolicySim/Simulation.lean:1086 (the month check in `simulate`) is fixed. The condition is now `month != openMonth.month` alone. The result does not change: on day 0, both months are 0, so no month closes. The 0-day run still gives no months, because the check `openMonth.days > 0` after the loop stays.
- StoragePolicySim/Simulation.lean:1089 (the day count in `simulate`) is fixed. The update now sets only `days`. The month changes in one place, the reset on line 1088.
- StoragePolicySim/Simulation.lean:965 (the charge limit in `stepHour`) is fixed. The name `chargeToFillKwh` now tells what the value is: the charge before the loss that fills the free room.
- The changed lines bring no new problem.
