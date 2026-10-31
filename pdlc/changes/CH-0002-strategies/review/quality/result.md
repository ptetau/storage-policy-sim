Result: fail

Remit: quality

Problems:
- packet.md:78 · The change relies on DES-writing-style (the conventions for prose), but the packet does not hold that spec. Thus, this review cannot judge the doc comments of `StoragePolicySim/Strategy.lean` against it. · Remit rule "The code follows the design specs in this packet", and the reviewer rule to report a missing item as a problem

Follow-ups:
none

Notes:
- The names, the doc comments and the two named constants (`eveningStartHour`, `sunniestHourCount`) make the code easy to read. The code has no dead code. No entry can fail, so no error handling is due.
- `StoragePolicySim/Strategy.lean:576` · The `evening` branch spells out the charge again. It could reuse `fullRequest`, for example `{ fullRequest surplusKwh shortfallKwh with dischargeKwh := ... }`. Then the code says directly that `evening` charges as `greedy` does (R4, evening battery use). This repetition is small, so it is not a problem.
- `StoragePolicySim/Strategy.lean:584` · `List.mergeSort` is stable, so the `a ≤ b` part of `comesFirst` only restates the tie rule of R5 (load shift into sun). The explicit form is clear, so it is not a problem.
- `StoragePolicySim/Strategy.lean:595` · `shiftIntoSun` takes the hours from `pvKwh.size` and builds the result from `flexKwh.size`. The Interface says that each array has 24 items, so this is correct for the spec.
