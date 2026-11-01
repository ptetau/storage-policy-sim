Result: pass

Remit: security

Problems: none

Follow-ups:
- Check the `Battery` fields and the `Site` fields before a run. `stepHour` and `simulate` accept a negative capacity, a negative power, or a NaN value, and then give flows with no meaning. No acceptance line asks for this check, and the Interface says that no entry can fail. A new intent could add a check with an error code in DES-errors (the project's error codes), for example `OUT_OF_RANGE`, at the caller that reads user input.
- Cap the `days` argument of `simulate`. The run keeps one `HourResult` for each hour, so a very large value uses much memory and time. No acceptance line names a limit. A new intent could add a cap where a caller passes user input, for example in a future `sim` command.

Notes:
- The change is a pure library module. It reads no file, no network and no environment. It builds no command, query, path or HTML. It holds no secret and logs nothing.
- The change adds no dependency. It imports only `StoragePolicySim.Scenario` and `StoragePolicySim.Strategy` from earlier changes.
- The code reads arrays with `[k]!` and `calendar[...]!`. These reads stay in range: `placeFlex` gives 24 items (CAP-strategies), `monthOfDay` gives 0 to 11, and the scenario gives 24 hours for each day.
- `simulate` uses `daysInYear`, and the packet does not show it. It probably comes from `StoragePolicySim/Scenario.lean`. This item has no effect on security.
