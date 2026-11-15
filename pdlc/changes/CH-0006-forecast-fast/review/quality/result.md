Result: pass

Remit: quality

Problems: none

Follow-ups: none

Notes:
- `forecast` now calls `forecastOf` on `scenario site seed days`. The two functions cannot give different periods, and the code has no repeated body. The signatures of `forecast` and `forecastOf` match the Interface of the change.
- Only `StoragePolicySim/Forecast.lean` changed. This matches the "Files" entry.
- The empty cases are safe. With no hours, or with a fetch hour of 8760 in a run of 8760 hours, `periodsLeft` is 0 and no `hours[...]!` read happens. Nat subtraction stops at 0, so a fetch hour past the run does not wrap.
- `sharedShare` (0.7) and `ownShare` (0.3) must sum to 1, or the doc comment "variance of a normal curve" becomes false. `ownShare` could be written as `1 - sharedShare`. The spec gives both numbers, so this is a taste point, not a problem.
- `normalDraw` is the mix of the shared part and the own part. `normalOfKey`, `periodDraw` and `dayDraw` are also normal draws. A name such as `errorDraw` would tell a reader which one to call. The doc comment of `normalDraw` does say what it is, so this is a taste point, not a problem.
- R7 says `d` depends on "the day of the run in which the period ends". The code uses the day of the hour that holds the period. The two readings differ only for the last period of a day, which ends at 00:00. The code and its comment agree with each other. No R7 line tests this period.
- DES-writing-style is under "Relies on" in the change spec, but its text is not in this packet. I judged the comments by the fallback rule: short sentences in the active voice. They pass. I cannot say if they meet the full file.
- DES-errors and DES-pdlc-check-tagging do not apply to this code. The code names no error. The check files are outside this remit.
