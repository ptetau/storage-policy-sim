Result: pass

Remit: specification

Problems: none

Follow-ups:
- `drawKwh` reads `profile[hour]!`. For an hour above 23, the array read prints a panic message and gives 0.0. The spec gives only the hours 0 to 23, so this is not a problem. A new intent could add a defined error code or a clamp for the hour.
- `drawFactor` accepts a negative `cv`, and `tankStep` accepts a negative `drawKwh`. No acceptance line names either input. A new intent could add a range check with an error code from DES-errors (the project's error codes).

Notes:
- Method: I traced each acceptance line of CAP-hotwater.R1 to R6 (42 lines) through `tankStep`, `drawKwh`, `drawFactor` and `startState`. Each line gives the stated numbers. I did not run the code. The statistical lines of R6 (mean and standard deviation over 5000 days) match the log-normal maths for a spread of 0.25 (standard deviation about 0.254) and 0.5 (about 0.533). The packet does not show the check results, so the claim in the progress log that the 73 checks pass is not something that I could confirm.
- Interface: each type, field, signature and default value in the change spec matches `StoragePolicySim/HotWater.lean`. The seam `drawSeed` is the `seed` argument of `drawFactor`, and the code takes it as that argument.
- Scope: the diff holds one new file, `StoragePolicySim/HotWater.lean`. That file is the only entry in "Files". The field `floorKwh` is in the interface, but no code reads it. The spec asks for the field, so this is correct.
- Extra behaviour: `tankStep` clamps the heating with `max 0.0`, so a negative request gives 0 heating. No acceptance line asks for this. It is a small guard, and I do not count it as a problem.
- Old wording: the title, the summary and the cross-references of CAP-hotwater match the code. The change has no README in "Files", so I judged no README. In `pdlc/specs/capabilities/CAP-hotwater.md`, each Interface entry still ends with `proposed`, but each requirement has the status `built`. The verify step probably changes the marker. Check that it does.
- Writing (guideline, not a problem): `pdlc/changes/CH-0007-hotwater/change.md:167` has four IDs with no short name: IN-0001, IN-0002, IN-0001 again, and CH-0011. This breaks the described-IDs rule (each ID needs a short description in the same sentence).
- Writing (guideline, not a problem): `StoragePolicySim/HotWater.lean:161` (the comment of `drawStream`) says "the draws of the hot-water factor" and "other random draws". The word "draw" also means the hot-water draw in this module, so the sentence can read two ways. Write "the random numbers of the hot-water factor" instead. This breaks STE rule 9.2 (use each word correctly) and rule 9.4 (use the same terms everywhere).
- Writing (guideline, not a problem): `StoragePolicySim/HotWater.lean:145` (the comment of `mix`) starts with the fragment "The SplitMix64 steps:". This breaks STE rule 4.2 (do not omit words).
