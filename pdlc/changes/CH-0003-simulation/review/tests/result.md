Result: fail

Remit: tests

Problems:
- tests/CAP-simulation.lean:90 · The earlier problem (missing Interface of CH-0001 and CH-0002) is only partly fixed. The packet now lists the names and the types of `Site`, `Hour`, `scenario`, `Strategy` and `Strategy.placeFlex`, and the checks use them correctly. But two instances that the checks need are still not in the packet. First, `sameHour` compares `a.sky == b.sky` (line 90), and this needs a `BEq` (or `DecidableEq`) on `Sky`. The Interface lists `inductive Sky | sunny | cloudy | overcast` with no derived instance. Second, the check "CAP-simulation.R1 the hours of a run are the hours of the scenario" reads `hs[i]!` on the `Array Hour` of `scenario` (line 247), and this needs `Inhabited Hour`. The Interface lists `Hour` with no instances, but it marks `Repr` and `Inhabited` on each structure of CH-0003. If `Sky` has no `BEq`, the whole file does not compile, and each check fails on a correct app. Add the instances of `Sky` and `Hour` to the Interface, or change the checks so that they do not need them (for example, match the sky by a `match` or by `Sky.toCtorIdx`). · Remit rule "A correct app passes each check", and the reviewer rule "If something that you need is missing, report the missing item as a problem"

Wrong versions:
none

Follow-ups:
none

Notes:
- No check changed since the earlier review at ba51e5b (tests locked). Thus, this review judged only the earlier problem.
- Each other name that the earlier problem listed now matches the Interface: the four `Site` fields, the seven `Hour` fields, `scenario site seed days : Array Hour`, `Strategy.placeFlex s pv fl` on two `Array Float`, and `Strategy.none`, `Strategy.greedy`, `Strategy.evening` and `Strategy.shift` written in full.
- The file header names `Strategy.decide`, but no check calls it. This is harmless.
