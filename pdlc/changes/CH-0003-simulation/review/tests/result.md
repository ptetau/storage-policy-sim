Result: pass

Remit: tests

Problems: none

Wrong versions: none

Follow-ups: none

Notes:
- The earlier problem is fixed. It was at tests/CAP-simulation.lean:90 (`sameHour` and the check "CAP-simulation.R1 the hours of a run are the hours of the scenario" needed instances that the Interface did not list). The Interface now gives `Sky` the instances `BEq`, `Repr` and `Inhabited`. Thus, `a.sky == b.sky` in `sameHour` compiles. The Interface also gives `Hour` the instances `Repr` and `Inhabited`. Thus, `hs[i]!` on the `Array Hour` of `scenario` compiles.
- The checks did not change since the earlier review (ba51e5b). Thus, no check needs a "Wrong versions" line.
- The other `!` reads and the `==` comparisons of the checks use types whose instances the Interface lists: `HourResult`, `Month` and `Flow` (`Inhabited`), `Strategy` (`BEq`), and `Nat`, `Float` and `String` (built in).
