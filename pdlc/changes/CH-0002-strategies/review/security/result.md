Result: pass

Remit: security

Problems: none

Follow-ups:
- `Strategy.placeFlex` could check that `pvKwh` and `flexKwh` each have 24 items. The Interface says each array has 24 items, but no acceptance line asks for a check. With arrays of different sizes, `shiftIntoSun` can pick a sunny hour past the end of `flexKwh`, and that part of the flexible load is lost. A new intent could add a length check, or a rule that says how the simulation builds the arrays.
- `Strategy.decide` could check that the hour is 0 to 23, and that the surplus and the shortfall are not negative and not NaN. No acceptance line asks for these checks. Today the code passes such a value through to the simulation without a change.

Notes:
- The change is a pure library module. It has no file, network, process, or command-line input. It builds no command, query, path, or HTML.
- `Strategy.ofName?` matches names exactly against a fixed list. It cannot match an unknown name.
- `hoursBySun` uses `pvKwh[a]!` only with indices from `List.range pvKwh.size`. Thus, the index is always in range, and the code cannot panic.
- The change has no secrets, no logs, no error messages, and no access checks.
- The change adds no dependency. The file has no imports.
