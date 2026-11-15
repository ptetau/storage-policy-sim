# Review packet · IN-0008-hot-water-policies · tests (acceptance checks)

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 423b91a35833ec8a8ed2b198657a8f71184b6745

Acceptance-Locked: d27aea8

These are the acceptance checks of an intent. Judge them by the section "Acceptance
checks of an intent" of the remit below, and by its "Wrong versions".

## Re-review

Earlier review: c05d3df

An earlier review of this remit judged the checks locked at c05d3df. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.
Write a "Wrong versions" line only for each check that changed. If no check
changed, write "none" under "Wrong versions".

### Earlier problems

- tests/acceptance/IN-0008.acceptance.lean:1477 (also :1478) · The check "CAP-homesim.R3 0 days give a total of 0 and a ratio of 0% in each field" puts `minTankKwh` and `finalTankKwh` in its list of fields that must be 0 (`!(v == 0.0)` fails the check). The line says these two fields are 10.5 kWh, the full tank at the start. A correct app fails this check, and an app that returns 0 for these two fields passes it. The comment above the check ("the line says that each total is 0") no longer matches the line · CAP-homesim.R3 (totals and ratios), last line: "The exceptions are `minTankKwh` and `finalTankKwh`, which are 10.5 kWh"
- tests/acceptance/IN-0008.acceptance.lean:1560 (also :1567, :1568) · The checks for the lines "the total unmet draw is their sum" and "`unmetSeeds` and `coldHours` are 0" use the default home with the static policy and the seeds 3 to 6. Each of these runs has an unmet draw of 0 kWh and 0 cold hours. Thus the sum, the mean, the maximum and the last run of the unmet draw are all 0, and a count that never counts also gives 0. No check evaluates a home with an unmet draw (for example an element of 0.2 kW) and compares `totalUnmetKwh`, `unmetSeeds` and `coldHours` with the runs. The check "CAP-homesim.R3 unmetKwh plus the served draw equals drawKwh" does use such a run, but only for `runHome`. The check "JOB-simulate.R9 --element 0.2 --days 90" reads only "more than 0.0" and "no" · CAP-homesim.R5 (robust evaluation), lines 4 and 5, and the remit rule that each check fails on a plausible wrong version

### Changes since the earlier review

````
diff --git a/tests/acceptance/IN-0008.acceptance.lean b/tests/acceptance/IN-0008.acceptance.lean
index 1f5b02d..8a0a3e6 100644
--- a/tests/acceptance/IN-0008.acceptance.lean
+++ b/tests/acceptance/IN-0008.acceptance.lean
@@ -437,6 +437,14 @@ def evalS3x4b : Evaluation := evaluate defaultHome pStatic 3 4 365
 def evalS3x1 : Evaluation := evaluate defaultHome pStatic 3 1 365
 def evalS3x0 : Evaluation := evaluate defaultHome pStatic 3 0 365
 
+/-- Runs of a home with an unmet draw: an element of 0.2 kW, the static policy with 0 heating
+hours, the seeds 3 to 6 and 30 days. The lines of CAP-homesim.R5 use them to prove that
+`evaluate` counts and sums. -/
+def runsE36 : List HomeResult :=
+  (List.range 4).map (fun i => runHome homeElem02 pThermo (3 + i) 30)
+
+def evalE3x4 : Evaluation := evaluate homeElem02 pThermo 3 4 30
+
 /-- The grid of the tuner: a start from 6 to 16, from 1 to 8 heating hours, and discharge from
 15 to 22, with the element of the home tank. -/
 def accGrid : List StaticParams :=
@@ -772,8 +780,9 @@ def forecastChecks : List Check := [
         return some s!"only {n} days have both periods"
       return if c ≥ 0.55 && c ≤ 0.85 then none
         else some s!"correlation {c} over {n} days" },
-  -- The line does not say if the two periods come from the fetch of the first day or from the
-  -- fetch of their own day. Both readings must give a correlation from -0.25 to 0.25.
+  -- The line says that each period comes from the fetch at 00:00 of its own day. The variable `a`
+  -- reads the line so. The variable `b` also takes both periods from the fetch of the first
+  -- day. Both readings must give a correlation from -0.25 to 0.25.
   { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25",
     run := do
       let a := pairsNextFetch
@@ -1466,20 +1475,22 @@ def homesimChecks : List Check := [
         (runPv0.hours.size == 8760, s!"{runPv0.hours.size} hours"),
         (near t.pvKwh 0.0 1e-9, s!"solar {t.pvKwh}"),
         (near t.selfConsumption 0.0 1e-9, s!"self-consumption {t.selfConsumption}")] },
-  -- A run of 0 days has no hours. The line says that each total is 0, so the check includes
-  -- `minTankKwh` and `finalTankKwh`.
-  { name := "CAP-homesim.R3 0 days give a total of 0 and a ratio of 0% in each field",
+  -- A run of 0 days has no hours. Each total and each ratio is 0, except `minTankKwh` and
+  -- `finalTankKwh`. These two are 10.5 kWh, the energy of the full tank at the start.
+  { name := "CAP-homesim.R3 0 days give a total of 0 and a ratio of 0% in each field, and 10.5 kWh in the tank",
     run := do
       let t := (runHome defaultHome pStatic 7 0).totals
       let zero := [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh),
         ("export", t.exportKwh), ("battery loss", t.batteryLossKwh),
         ("tank loss", t.tankLossKwh), ("heating", t.heatKwh), ("backstop", t.backstopKwh),
-        ("draw", t.drawKwh), ("unmet", t.unmetKwh), ("lowest tank", t.minTankKwh),
-        ("final tank", t.finalTankKwh), ("self-consumption", t.selfConsumption),
+        ("draw", t.drawKwh), ("unmet", t.unmetKwh), ("self-consumption", t.selfConsumption),
         ("self-sufficiency", t.selfSufficiency)]
-      return match zero.find? (fun (_, v) => !(v == 0.0)) with
-        | some (n, v) => some s!"{n} is {v}, want 0"
-        | none => if t.coldHours == 0 then none else some s!"cold hours {t.coldHours}" },
+      return firstSome [
+        (match zero.find? (fun (_, v) => !(v == 0.0)) with
+          | some (n, v) => some s!"{n} is {v}, want 0"
+          | none => none),
+        valsIs 1e-9 [("lowest tank", t.minTankKwh, 10.5), ("final tank", t.finalTankKwh, 10.5)],
+        if t.coldHours == 0 then none else some s!"cold hours {t.coldHours}"] },
 
   -- CAP-homesim.R4
   { name := "CAP-homesim.R4 the static policy asks for heating only in hours 10, 11, 12 and 13",
@@ -1566,6 +1577,32 @@ def homesimChecks : List Check := [
         (e.seeds == 4, s!"seeds {e.seeds}"),
         (e.unmetSeeds == 0, s!"unmetSeeds {e.unmetSeeds}"),
         (e.coldHours == 0, s!"coldHours {e.coldHours}")] },
+  -- The runs of the default home have an unmet draw of 0 kWh. Thus the two checks below use a
+  -- home with an element of 0.2 kW and no heating hours. A version of `evaluate` that never
+  -- counts, or that takes a mean where the line says a sum, fails them.
+  { name := "CAP-homesim.R5 for a home with an unmet draw the total unmet draw is the sum of the unmet draws of the runs",
+    run := do
+      let e := evalE3x4
+      let us := runsE36.map (·.totals.unmetKwh)
+      return firstFail [
+        (us.length == 4, s!"{us.length} runs"),
+        (sumF us > 0.0, "the runs have no unmet draw, so the check proves nothing"),
+        (e.totalUnmetKwh > 0.0, s!"total unmet draw {e.totalUnmetKwh}"),
+        (near e.totalUnmetKwh (sumF us) 1e-9,
+          s!"total unmet draw {e.totalUnmetKwh}, the sum of the runs is {sumF us}")] },
+  { name := "CAP-homesim.R5 for a home with an unmet draw unmetSeeds counts the runs with an unmet draw and coldHours is the sum of their cold hours",
+    run := do
+      let e := evalE3x4
+      let ts := runsE36.map (·.totals)
+      let n := (ts.filter (fun t => t.unmetKwh > 0.0)).length
+      let cold := ts.foldl (fun acc t => acc + t.coldHours) (0 : Nat)
+      return firstFail [
+        (ts.length == 4, s!"{ts.length} runs"),
+        (n > 0, "no run has an unmet draw, so the check proves nothing"),
+        (cold > 0, "no run has a cold hour, so the check proves nothing"),
+        (e.unmetSeeds > 0, s!"unmetSeeds {e.unmetSeeds}"),
+        (e.unmetSeeds == n, s!"unmetSeeds {e.unmetSeeds}, the runs with an unmet draw are {n}"),
+        (e.coldHours == cold, s!"coldHours {e.coldHours}, the sum of the runs is {cold}")] },
   { name := "CAP-homesim.R5 0 seeds give 0 in each field",
     run := do
       let e := evalS3x0
````

# Remit: tests

Default: yes

You judge the checks, not the code. You do not see the code. The list below is for the
component checks of a change. For the acceptance checks of an intent, the section
"Acceptance checks of an intent" gives the differences.

- Each acceptance line in the change spec has at least one check. The exception is a
  requirement marked `(retire)`: its acceptance lines get no check, and each check that
  only proved them is gone.
- The name of each check contains its requirement ID.
- Each check tests what the acceptance line says, through the "Interface" in the change
  spec. The check does not depend on the internal structure of the code.
- A component check is permitted to prepare state directly, for example with a fixture
  file. But the check reads each result through the interface, unless the requirement is
  about the stored form.
- A check proves each line at the surface that the line names. A line where the person
  clicks needs a check that clicks and reads what shows. A check of a helper below that
  surface is not sufficient alone.
- If a line depends on the current date or time, its check sets the clock through a seam
  at that same surface. A check that runs a command sets the clock with the environment
  variable or flag of the command. Each of these is a problem:
  - Using the real clock, or setting the time only on a helper below the surface.
  - Leaving a line to manual checks when a stand-in seam could reach the surface.
- Each check can fail. It fails on a plausible wrong version of the code (see "Wrong
  versions"). A check that passes, whatever the code does, does not count.
- A correct app passes each check. A fake that stands in for something real must use the
  names and the behaviour of the real thing. Then the check does not prove only the fake.
- No check can hang. Anything that waits for the app has a time limit.
- Each error that the Interface lists has a check that expects its exact message and
  result, and its code where the caller can see it.
  For a command, the check reads the message from the stream that the entry names.
- The checks control time, randomness, and vendors only through the "Test seams" of the
  Interface.
- The checks are sufficiently clear that a failure tells you what broke.

## Wrong versions

For each check, name one plausible wrong version of the code. Decide whether the check
fails on that version. Write one line for each check under "Wrong versions" in your
result: the check, the wrong version, and `fails` or `passes`. A check that passes a
plausible wrong version is a problem. Name the value or line that catches the wrong
version. On a re-review, write a line only for each check that changed since the earlier
review.

Look for these traps:

- Examples that also fit a wrong rule. These are common cases:
  - A rule about order, tested with items that are already in that order or in
    alphabetical order.
  - Values that come out the same if the code rounds up, rounds down, or rounds to the
    nearest value.
  - Text that is already in the case that the rule asks for.
- A limit that the check does not test exactly at the edge and one past the edge. For "at
  most 20", the value 20 passes and the value 21 fails. Values near the edge prove nothing
  about the edge.
- A rule about every member of a class that the check tests without a non-member.
  "Any other value is an error" needs a value close to an allowed value, not only a few
  far-off values. A close value differs by its case, a space, or a prefix. "Only the
  owner may" needs a person who is not the owner.

## Acceptance checks of an intent

The packet holds the intent, the full text of its requirements, and the "Interface" of
each of its changes. Judge the acceptance checks by the list at the top, with these
differences:

- Each acceptance line of each requirement that the intent lists has at least one check. A
  `retiring` requirement has no check. A stored-data line also has no check here.
- Each check uses only what a user uses: commands, HTTP requests, pages, or the public
  functions of a library. A check can use each feature of the intent, and each feature
  that exists already.
- No check reads or writes stored data directly. A check that opens a saved file or
  queries a store is a problem.
- A stored-data line needs direct access to the stored data. The line is about the stored
  form, or it needs a state that the interface cannot make. An example of such a state is
  an old or a broken data file. The comment at the top of the file lists each such line, with a change of the
  intent that lists its requirement. Such a line with no check is not a problem.
- A line in that list that the interface can prove is a problem. So is a listed line whose
  change does not list its requirement. The packet gives the requirements of each change.
- A check can leave the acceptance file of an earlier intent only when the check proved a
  requirement that this intent changes or retires. Then a check in this file proves the
  new line. Any other removal is a problem.
- Each check fails until the last change of the intent is built. That is not a problem.
- When the intent lists one change, these checks are also the checks of that change. Then
  each error code and each test seam in its "Interface" has a check.

Write "Wrong versions" for the acceptance checks in the same way as for other checks.

## The intent

````
# IN-0008 · Hot-water policy simulation

Status: ready · Ticket: none · Branch: pdlc/IN-0008-hot-water-policies · Added: 2026-11-15

The pdlc scripts read each header field. Thus, a header field holds only its bare value.
Do not add a name in brackets, and do not add backticks. For example, write
`Branch: pdlc/IN-0001-reset`, not `Branch: pdlc/IN-0001-reset (the intent branch)`.

## What and why

"build it out, use opus only if you need it. what I am trying to do is to be able to create the best daily profile for heating our hotwater and charging our battery, maximising self consumption without risking cold tanks or wasting sunlight. this sim will help me simulate a robust policy, both dynamic, precomputed or static."

## Requirements

- CAP-forecast.R6 (forecast from built hours): added
- CAP-forecast.R7 (shared error of a day): added
- CAP-hotwater.R1 (standby loss and draw): added
- CAP-hotwater.R2 (heating limits): added
- CAP-hotwater.R3 (thermostat): added
- CAP-hotwater.R4 (hot-water draw profile): added
- CAP-hotwater.R5 (daily full heating): added
- CAP-hotwater.R6 (daily draw factor): added
- CAP-simulation.R6 (allowed battery use): added
- CAP-policy.R1 (static profile): added
- CAP-policy.R2 (day-ahead plan): added
- CAP-policy.R3 (dynamic action): added
- CAP-policy.R4 (defaults and names): added
- CAP-homesim.R1 (hourly home flows): added
- CAP-homesim.R2 (no cold tank): added
- CAP-homesim.R3 (totals and ratios): added
- CAP-homesim.R4 (policies at work): added
- CAP-homesim.R5 (robust evaluation): added
- CAP-homesim.R6 (tuning a static profile): added
- JOB-simulate.R5 (bad command line): changed
- JOB-simulate.R6 (forecast command): added
- JOB-simulate.R7 (policy run): added
- JOB-simulate.R8 (policy compare): added
- JOB-simulate.R9 (policy robust): added
- JOB-simulate.R10 (policy tune): added
- JOB-simulate.R11 (policy options): added

## Changes

- CH-0006 (forecast-fast): CAP-forecast (simulated Solcast forecasts)
- CH-0007 (hotwater): CAP-hotwater (hot-water tank)
- CH-0008 (gated-battery): CAP-simulation (hourly energy flows)
- CH-0009 (policy): CAP-policy (daily-profile policies)
- CH-0010 (homesim): CAP-homesim (home simulation)
- CH-0011 (policy-commands): JOB-simulate (the sim command)

## Acceptance checks

Acceptance-File: tests/acceptance/IN-0008.acceptance.lean
Acceptance-Locked: d27aea8
Acceptance-Passed: none

## Notes

- IN-0008 (hot-water policy simulation): What is the policy for? → a daily profile that heats the hot water and charges the battery, with the most self-consumption, no cold tank and no wasted sun, from the words of the user.
- IN-0008 (hot-water policy simulation): Which kinds of policy? → static, precomputed and dynamic, from the words of the user. The old strategies of IN-0001 (simulator) stay as they are.
- IN-0008 (hot-water policy simulation): Does the battery charge from the grid? → no. The battery charges only from the solar surplus, because the aim is self-consumption.
- JOB-simulate.R5: was "usage: sim run [options] | sim compare [options]", now "usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]".
- IN-0008 (hot-water policy simulation): Where do the new commands live? → in JOB-simulate, so that the usage lists them. The checks of IN-0001 that name the old usage line change with it.
- CAP-hotwater.R1: How much of its energy does the tank lose in an hour? → 0.6% of the stored energy, which is 1.5 kWh in a day for a full tank, near the New Zealand average (assumed)
- CAP-hotwater.R2: In which order do the draw and the heating run in an hour? → the draw first, then the heating (assumed)
- CAP-hotwater.R3: When does the thermostat heat the tank? → when the tank holds less than half of its capacity, and then until the tank is full, like a real thermostat with a dead band (assumed)
- CAP-hotwater.R4: What is the hot-water draw profile? → peaks at 07:00 and 19:00, with a seasonal factor of 0.15 and the peak days of the load (assumed)
- CAP-hotwater.R5: When must the tank be full? → at least once each day, with the thermostat on from 20:00 if it has not been, because stored water below 60 °C can grow legionella bacteria (assumed)
- CAP-hotwater.R6: How does the draw change from day to day? → a random factor of mean 1 and a spread of 0.25, so that the checks of no cold tank test more than the average day (assumed)
- CAP-forecast.R7: How do the errors of the periods of one day relate? → they share 70% of their variance with the day, and the sum is still normal, because one weather front is wrong for the whole day (assumed)
- CAP-policy.R1: What happens to a heating window past the end of the day, and to a discharge hour of 24? → the window stops at the end of the day, and 24 never lets the battery discharge (assumed)
- CAP-policy.R2: How does the day-ahead plan size and place the heating? → the need is the target less the tank energy plus the expected draw, placed in the sunniest hours, and a tie goes to the earlier hour (assumed)
- CAP-policy.R3: What surplus does a dynamic policy see? → a surplus of 0 or more (assumed)
- CAP-policy.R4: What are the default parameters of the policies? → a full tank as the target, so that the sun does the daily full heating, and a sensible start for the default tank otherwise (assumed)
- CAP-homesim.R1: What does a run start with, and when does a precomputed policy plan? → a full tank and an empty battery, and a plan at hour 0 from the fetch at hour 0 and the expected draw without the factor of the day, with the forecast made only for a policy that reads it (assumed)
- CAP-homesim.R2: What does no cold tank mean? → no unmet draw, the tank ends each hour at or above the floor of 2.1 kWh, and the tank is full at least once each day (assumed)
- CAP-homesim.R3: What is a ratio with nothing to divide by? → 0% (assumed)
- CAP-homesim.R5: What does an evaluation of 0 seeds give? → 0 in every field (assumed)
- CAP-homesim.R6: How does the tuner rank its candidates? → the safe candidate with the highest mean self-consumption, then the lowest mean import within 0.05 points, then the first in order, and the lowest total unmet draw if none is safe (assumed)
- JOB-simulate.R6: What are the defaults and ranges of the forecast options? → --hour 0, --lon 174.8 and --forecast-error 1, with the ranges of the requirement (assumed)
- JOB-simulate.R7: What do the lines of the policy run look like, and what are the defaults? → a label, spaces to column 19 and a value, with the defaults of the home and the policies (assumed)
- JOB-simulate.R8: What header and rows does the policy comparison print? → the header of the requirement, and the rows thermostat, static, precomputed and dynamic (assumed)
- JOB-simulate.R9: What do the columns of the robust table mean, and what is the default of --seeds? → the header of the requirement, and 10 seeds (assumed)
- JOB-simulate.R10: What is the default of --seeds for the tuner? → 5 seeds (assumed)
- JOB-simulate.R11: What are the ranges of the policy options? → the table of the requirement (assumed)
- IN-0008 (hot-water policy simulation): What did the research of 2026-11-15 change? → a thermostat with a cut-in level in place of a floor, a daily full heating against legionella, a loss that matches the average New Zealand tank, a random draw for each day, a shared error for each day of the forecast, and a perfect-forecast row in the comparison (JOB-simulate.R8 to R10).

## Handoff

Handoff · IN-0008 · change → acceptance

Time: 2026-11-15T11:10:02+00:00

### Done

- Change planned six changes, in the order of their entries: CH-0006 (forecast-fast), CH-0007 (hotwater), CH-0008 (gated-battery), CH-0009 (policy), CH-0010 (homesim) and CH-0011 (policy-commands).
- Research of the problem changed the model before any check was written. CAP-hotwater now has a thermostat with a cut-in level and a daily full heating (R3, R5), a loss that matches the average New Zealand tank (R1), and a random draw for each day (R6).
- CAP-forecast.R7 (shared error of a day) is new. CAP-policy.R4 (defaults and names) now targets a full tank. CAP-homesim.R1 to R3 follow the new tank, and JOB-simulate.R7 to R11 add `--cut-in`, `--draw-cv` and the `perfect-forecast` row.
- The skill added the Interface of CAP-strategies (battery and load strategies) from the code, because the checks of CH-0008 call a strategy. No behaviour changed.

### Decided on defaults

- CAP-forecast.R7: How do the errors of the periods of one day relate? → they share 70% of their variance with the day, and the sum is still normal, because one weather front is wrong for the whole day (assumed)
- CAP-hotwater.R1: How much of its energy does the tank lose in an hour? → 0.6% of the stored energy, which is 1.5 kWh in a day for a full tank, near the New Zealand average (assumed)
- CAP-hotwater.R3: When does the thermostat heat the tank? → when the tank holds less than half of its capacity, and then until the tank is full, like a real thermostat with a dead band (assumed)
- CAP-hotwater.R5: When must the tank be full? → at least once each day, with the thermostat on from 20:00 if it has not been, because stored water below 60 °C can grow legionella bacteria (assumed)
- CAP-hotwater.R6: How does the draw change from day to day? → a random factor of mean 1 and a spread of 0.25, so that the checks of no cold tank test more than the average day (assumed)
- CAP-policy.R4: What are the default parameters of the policies? → a full tank as the target, so that the sun does the daily full heating, and a sensible start for the default tank otherwise (assumed)
- CAP-homesim.R1: What does a run start with, and when does a precomputed policy plan? → a full tank and an empty battery, and a plan at hour 0 from the fetch at hour 0 and the expected draw without the factor of the day, with the forecast made only for a policy that reads it (assumed)
- CAP-homesim.R2: What does no cold tank mean? → no unmet draw, the tank ends each hour at or above the floor of 2.1 kWh, and the tank is full at least once each day (assumed)

### Open

- none

### Look here

- The Interface of each change spec in `pdlc/changes/`.
- `pdlc/acceptance/IN-0008-hot-water-policies/brief.md` is stale. Rewrite it from the new specs before the test writer starts.

### Don't redo

- The six change specs and their order.

### Next: do this first

Write the acceptance checks of IN-0008 in `tests/acceptance/IN-0008.acceptance.lean`. They prove the commands through the `sim` process, and the capabilities through the library.
````

## The requirements, in full

### CAP-forecast.R6 · Forecast from built hours

Status: ready · Intents: IN-0008

A caller that makes many fetches builds the hours of the scenario once. `forecastOf` gives the
same periods as `forecast`, from these hours, and does not build the scenario again. A set of
hours that is empty has no period in any fetch.

- Given the hours of `scenario` for seed 7 and 365 days at latitude 45 with 5 kW of panels, and an error scale of 1, when `forecastOf` runs for the fetch hours 0, 4116 and 8750, then each result has the same periods as `forecast` for the same arguments. Each period has the same end and the same three values.
- Given the same hours and an error scale of 0, when `forecastOf` runs for the fetch hour 4000, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given the same hours, when `forecastOf` runs for the fetch hour 8760, then it has no period.
- Given no hours, when `forecastOf` runs for the fetch hour 0, then it has no period.
- Given the same hours and seeds 7 and 8, when `forecastOf` runs for the fetch hour 4000 with the hours of each seed, then at least one estimate differs.

### CAP-forecast.R7 · Shared error of a day

Status: ready · Intents: IN-0008

A forecast that is wrong about one hour of a day is often wrong about the other hours of that
day, because one cloud front covers the whole day. Thus, the random number of R2 (forecast
error) of a period has two parts: `sqrt(0.7) × d + sqrt(0.3) × e`, where `d` is a number from
a normal curve for the day of the period, and `e` is a number from a normal curve for the
period itself in the fetch (assumed). The number `d` depends only on the seed and the day of
the run in which the period ends. Thus, two fetches of the same day share `d`. The sum of the
two parts is still a number from a normal curve, so that the bands of R2 keep their meaning.

The relative error of a sunny period is its estimate less its actual power, divided by the
actual power and by the spread. For a sunny period in a fetch with the error scale 1, it is
the random number of the period, except where the estimate is cut to the range of R2.

In these lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is
365 days, and the error scale is 1, unless the line says otherwise. A fetch at 00:00 is a
fetch at an hour that is a multiple of 24. The periods that end at 11:30 and 13:30 are those
whose end is 690 and 810 minutes into the day.

- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny periods that end at 11:30 and 13:30 of the same day are compared, then their correlation over the days that have both is from 0.55 to 0.85. Days where either estimate is cut to the range of R2 do not count.
- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny period that ends at 11:30 of a day and of the next day are compared, each from the fetch at 00:00 of its own day, then their correlation is from -0.25 to 0.25.
- Given the fetches at hour 0 and at hour 10 of each day from 0 to 364, when the relative errors of the sunny period that ends at 13:30 of that day are compared, then at least 62% of the days have the same sign in both fetches. Days with a relative error of 0 in either fetch do not count.
- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given a fetch at 00:00 of each day, when the sunny periods are compared, then 60% to 95% of them have the actual power in the band.

### CAP-hotwater.R1 · Standby loss and draw

Status: ready · Intents: IN-0008

In each hour, the tank first loses a share of its energy, 0.6% in the default tank (assumed).
That is 1.5 kWh in a day for a full tank, near the average of the New Zealand tanks. Then the
household draws hot water. The tank serves the smaller of the draw and the energy that it
holds. The rest of the draw is the unmet draw.

In these lines, the tank is the default tank with a cut-in of 0 kWh, so that the thermostat
stays out of the line. The hour is 12, the thermostat is off, and the tank was full today.
The request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given 8.0 kWh stored and no draw, when the hour runs, then the loss is 0.048 kWh and the tank holds 7.952 kWh.
- Given 8.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.048 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 6.452 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.006 kWh, the served draw is 0.994 kWh and the unmet draw is 1.006 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.063 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits

Status: ready · Intents: IN-0008

The element heats the tank by the energy that the policy asks for. The heating is never more
than the element power for one hour, and never more than the room that the tank has left.
The draw of the hour comes before the heating (assumed). Thus, a tank that holds too little
energy has an unmet draw, also when the policy asks for heating in the same hour.

In these lines, the tank is the default tank with a cut-in of 0 kWh, the hour is 12, the
thermostat is off, and the tank was full today. The draw is 0 kWh, unless the line says
otherwise. The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.97 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.97 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.554 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.988 kWh and the unmet draw is 0.512 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat

Status: ready · Intents: IN-0008

After the heating of the policy, the thermostat decides. It cuts in when the tank holds less
than the cut-in level, 5.25 kWh in the default tank, which is half of the capacity (assumed).
Once in, it stays on from hour to hour, until the tank is full. That is the dead band of a
real thermostat. A tank is full when it holds its capacity, within 0.000000001 kWh.

While the thermostat is on, the backstop heating is the element power that the policy left in
the hour, and never more than the room that the tank has left. The backstop heating counts
apart from the heating that the policy asked for. When the thermostat is off, the backstop
heating is 0 kWh.

In these lines, the tank is the default tank, the hour is 12, the thermostat is off, the tank
was full today, the draw is 0 kWh and the request is 0 kWh, unless the line says otherwise.
The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 7.97 kWh and the thermostat is on.
- Given 6.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh, the tank holds 5.964 kWh and the thermostat is off.
- Given 6.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 8.964 kWh and the thermostat is on.
- Given 9.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and the thermostat is off.
- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the backstop heating is 0 kWh. The tank holds 6.97 kWh and the thermostat is off.
- Given 4.0 kWh stored and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 2.0 kWh. The tank holds 6.976 kWh and the thermostat is on.
- Given 9.0 kWh stored, the thermostat on and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 0.554 kWh. The tank holds 10.5 kWh and the thermostat is off.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the unmet draw is 1.006 kWh, the backstop heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a cut-in of 0 kWh and 1.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh.

### CAP-hotwater.R4 · Hot-water draw profile

Status: ready · Intents: IN-0008

The household draws more hot water in the morning and in the evening. The hours of a day share
the daily energy by a fixed profile with a peak at 07:00 and a peak at 19:00 (assumed). A
seasonal factor of 1 + 0.15 × cos(2π × (day - peak) / 365) scales the daily energy, because
the cold inlet is colder in winter (assumed). The peak is day 15 at latitude 0 or more, and
day 197 at a negative latitude (assumed).

In these lines, the daily energy is 6.0 kWh, unless the line says otherwise.

- Given latitude 45, when the draw of each hour of days 0 to 364 is added, then the sum is 2190.0 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the 24 hours of day 100 are added, then the sum is 6.0 × (1 + 0.15 × cos(2π × 85 / 365)) kWh. The tolerance is 0.000001 kWh.
- Given latitude 45, when the days 15 and 197 are compared, then the draw of day 15 is 1.34 to 1.37 times the draw of day 197.
- Given latitude -41, when the days 15 and 197 are compared, then the draw of day 197 is 1.34 to 1.37 times the draw of day 15.
- Given latitude 45, when the hours of day 100 are compared, then hour 7 draws more than hour 3, and hour 19 draws more than hour 13.
- Given a daily energy of 0.0 kWh, when each hour of day 100 is read, then each draw is 0 kWh.

### CAP-hotwater.R5 · Daily full heating

Status: ready · Intents: IN-0008

The tank is full at least once each day, so that the stored water stays hot enough against
legionella bacteria (assumed). From the guard hour, 20 in the default tank (assumed), the
thermostat cuts in when the tank has not been full since hour 0 of the day. It stays on until
the tank is full, as in R3. The state `fullToday` is false at the end of hour 0, unless the
tank is full after that hour. It becomes true in the hour in which the tank is full, and it
stays true to the end of the day.

In these lines, the tank is the default tank, the thermostat is off, the draw is 0 kWh and
the request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given hour 20, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 19, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh, the tank holds 8.946 kWh and `fullToday` is false.
- Given hour 20, 9.0 kWh stored and a tank that was full today, when the hour runs, then the backstop heating is 0 kWh and the tank holds 8.946 kWh.
- Given hour 22, 4.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 6.976 kWh and the thermostat is on.
- Given hour 0, 10.5 kWh stored and a tank that was full the day before, when the hour runs, then the tank holds 10.437 kWh and `fullToday` is false.
- Given hour 0, 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 12, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given a guard hour of 24, hour 23, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given the start state of the default tank, when `startState` is read, then the tank holds 10.5 kWh, the thermostat is off and `fullToday` is true.

### CAP-hotwater.R6 · Daily draw factor

Status: ready · Intents: IN-0008

A household draws more hot water on some days, and less on others. The factor of a day is
`exp(cv × z - cv × cv / 2)`, where `cv` is the spread of the draw and `z` is a random number
from a normal curve (assumed). The number `z` depends only on the seed and the day. Thus, the
mean of the factor is 1, and a spread of 0 gives the factor 1.

- Given a spread of 0, when the factors of days 0 to 364 are read, then each is 1.0. The tolerance is 0.000000000001.
- Given seed 7 and a spread of 0.25, when the factors of days 0 to 4999 are read, then each is more than 0. Their mean is from 0.98 to 1.02, and their standard deviation is from 0.23 to 0.27.
- Given seed 7 and a spread of 0.5, when the factors of days 0 to 4999 are read, then their mean is from 0.97 to 1.03, and their standard deviation is from 0.48 to 0.58.
- Given seed 7 and a spread of 0.25, when the factor of the same day is read two times, then the two factors are the same.
- Given the seeds 7 and 8 and a spread of 0.25, when the factors of days 0 to 364 are compared, then at least 300 days have a different factor.

### CAP-simulation.R6 · Allowed battery use

Status: ready · Intents: IN-0008

`stepHourGated` runs an hour as `stepHour` does with the `greedy` strategy, but a battery
that may not charge keeps the surplus as export, and a battery that may not discharge leaves
the shortfall as import. The battery limits of R1 and R2 still hold. In these lines, the
battery holds 10 kWh with 5 kW of power, unless the line says otherwise. The tolerance is
0.000000001 kWh.

- Given an empty battery that may charge and discharge, when the hour has 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given an empty battery that may not charge, when the hour has 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export. The battery still holds 0 kWh.
- Given 1.9 kWh stored and a battery that may discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored and a battery that may not discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 0 kWh and the import is 2.0 kWh. The battery still holds 1.9 kWh.
- Given 9.05 kWh stored and a battery that may charge, when the hour has a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery that may not charge and may not discharge, when an hour has a surplus of 2 kWh, then the export is 2 kWh. When the hour has a shortfall of 2 kWh, then the import is 2 kWh.
- Given a battery that may charge and discharge, when each of the 24 hours of day 100 of a run with latitude 45 and seed 7 runs with the battery energy of the hour before, then each flow equals the flow of `stepHour` with `greedy`. The tolerance is 0.000000001 kWh.
- Given a battery that may charge, and may discharge only from 17:00, when the same 24 hours run, then each flow equals the flow of `stepHour` with `evening`. The tolerance is 0.000000001 kWh.

### CAP-policy.R1 · Static profile

Status: ready · Intents: IN-0008

A static policy repeats one profile each day. The tank asks for the element power in each hour
from `heatStart` for `heatHours` hours, and for nothing in the other hours. The window stops at
the end of the day (assumed). The battery may always charge. It may discharge from the hour
`dischargeFrom` to the end of the day, and a value of 24 never lets it discharge (assumed).

In these lines, the parameters are `defaultStatic`, unless the line says otherwise.

- Given the default parameters, when the profile is made, then it has 24 actions.
- Given the default parameters, when the profile is made, then hours 10, 11, 12 and 13 ask for 3.0 kWh. Hours 9 and 14 ask for 0 kWh.
- Given the default parameters, when the profile is made, then the battery may discharge in hours 17 and 23, and may not discharge in hours 0 and 16.
- Given the default parameters, when the profile is made, then the battery may charge in each hour.
- Given 0 heating hours, when the profile is made, then each hour asks for 0 kWh.
- Given a start of 22 and 2 heating hours, when the profile is made, then hours 22 and 23 ask for 3.0 kWh. Hour 21 asks for 0 kWh.
- Given a start of 23 and 5 heating hours, when the profile is made, then hour 23 asks for 3.0 kWh. Hour 0 asks for 0 kWh.
- Given an element of 1.5 kW, when the profile is made, then each heating hour asks for 1.5 kWh.
- Given discharge from 24, when the profile is made, then the battery may not discharge in any hour.

### CAP-policy.R2 · Day-ahead plan

Status: ready · Intents: IN-0008

A precomputed policy makes one plan at the start of the day. The need is the target less the
energy in the tank, plus the hot water that the household is expected to draw, and never
less than 0 (assumed). Only an hour with a forecast of at least `minSolarKwh` can heat.
The plan gives the element power to these hours, from the highest forecast to the lowest,
until the need is met. A tie goes to the earlier hour (assumed). If the hours cannot meet
the need, the rest of the need stays unplanned. The battery rules are those of R1, with
`dischargeFrom` of the plan.

In these lines, the tank is the default tank and the parameters are `defaultPlan` with a target
of 9.0 kWh, unless the line says otherwise.

- Given a forecast of 1.0, 2.0, 3.5, 3.0, 4.0 and 1.5 kWh in hours 9 to 14 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hours 10, 11, 12 and 13 ask for 2.0, 3.0, 3.0 and 3.0 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 9.0 kWh in the tank and an expected draw of 0.5 kWh, when the day is planned, then hour 13 asks for 0.5 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 10.0 kWh in the tank and an expected draw of 0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.4 kWh in each hour, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.5 kWh in hour 12 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hour 12 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a minimum forecast of 0.0 kWh, a forecast of 0 kWh in each hour, 9.0 kWh in the tank and an expected draw of 3.0 kWh, when the day is planned, then hour 0 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a forecast of 2.0 kWh in hours 10 to 14, 9.0 kWh in the tank and an expected draw of 4.0 kWh, when the day is planned, then hour 10 asks for 3.0 kWh and hour 11 asks for 1.0 kWh.
- Given the default parameters, when a day is planned, then the battery may charge in each hour, may discharge in hour 17, and may not discharge in hour 16.

### CAP-policy.R3 · Dynamic action

Status: ready · Intents: IN-0008

A dynamic policy decides each hour from what it sees. First it soaks up surplus: when the
hour has a solar surplus and the tank holds less than the target, the tank asks for the
smallest of the element power, the surplus and the room to the target. If not, and the tank
holds less than the low level, and the forecast for the rest of the day is less than the
lack, the tank asks for the smaller of the element power and the lack. The lack is the low
level less the energy in the tank. In every other case the tank asks for 0 kWh. The battery rules are those of R1, with
`dischargeFrom` of the policy. The surplus is 0 or more (assumed).

In these lines, the tank is the default tank and the parameters are `defaultDynamic` with a low
level of 4.0 kWh and a target of 9.0 kWh, unless the line says otherwise.

- Given a surplus of 2.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 2.0 kWh.
- Given a surplus of 5.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 5.0 kWh and 8.0 kWh in the tank, when the hour is decided, then the tank asks for 1.0 kWh.
- Given a surplus of 5.0 kWh and 9.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh. With 9.5 kWh in the tank, the tank asks for 0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh for the rest of the day, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus, 0.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 1.0 kWh, 3.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given hour 16, when the hour is decided, then the battery may charge and may not discharge. Given hour 17, the battery may charge and may discharge.

### CAP-policy.R4 · Defaults and names

Status: ready · Intents: IN-0008

The defaults give a sensible start for a home with the default tank (assumed). The target is a
full tank, because the tank must be full once a day for the legionella guard, and the sun is
cheaper than the grid for that heating (assumed). A policy has a name that a command can print.

- Given `defaultStatic`, when it is read, then the heating starts at 10, lasts 4 hours, discharge starts at 17, and the element is 3.0 kW.
- Given `defaultPlan`, when it is read, then the target is 10.5 kWh, the minimum forecast is 0.5 kWh, and discharge starts at 17.
- Given `defaultDynamic`, when it is read, then the low level is 5.25 kWh, the target is 10.5 kWh, and discharge starts at 17.
- Given a static, a precomputed and a dynamic policy, when the names are read, then they are `static`, `precomputed` and `dynamic`.

### CAP-homesim.R1 · Hourly home flows

Status: ready · Intents: IN-0008

The run starts with a full tank (`startState`) and an empty battery (assumed). In each hour,
the policy gives an action. The tank takes the draw, the heating and the backstop by
CAP-hotwater (hot-water tank), with the hour of the day. The heating and the backstop heating
join the house load. The battery then runs the hour with its gate, by `stepHourGated`. The
draw of an hour is the `drawKwh` of the home for its day and hour, times the `drawFactor` of
the seed, the day and the spread `drawCv`.

A static policy uses its profile of the hour. A precomputed policy makes its plan at hour 0
of each day, from the forecast of the fetch at hour 0, the energy in the tank, and the draw
that the day is expected to have, which is the sum of the `drawKwh` of its 24 hours, without
the factor of the day (assumed). A dynamic policy sees the tank, the battery, the
surplus of the hour (the solar energy less the house load, and never less than 0), and the
forecast for the rest of the day from the latest fetch. The forecast is made only for a policy that reads it (assumed). It uses the seed of the run.

In these lines, the home is `defaultHome`, the policy is the static policy with
`defaultStatic`, the seed is 7, and the run is 365 days, unless the line says otherwise. The
tolerance is 0.000000001 kWh.

- Given the default run, when it ends, then it has 8760 hours, in order of day, then hour.
- Given the default run, when each hour is read, then its solar energy and its house load are those of the scenario hour for the same site, seed and days.
- Given the default run, when each hour is read, then `askKwh` is the heating of its hour in the static profile, and the battery gate is the gate of that hour.
- Given the default run, when each hour is read, then its tank energy is the `tankStep` result for the tank state of the hour before, its hour of the day, its request and its draw. The first hour starts with `startState` of the tank.
- Given the default run, when each hour is read, then its flow is the `stepHourGated` flow for the battery energy of the hour before, its gate, its solar energy, and its house load plus its heating plus its backstop heating. The first hour starts with 0 kWh.
- Given the default run, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour, times the `drawFactor` for seed 7, its day and the spread 0.25.
- Given the default run with a spread of 0, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour.
- Given the precomputed policy with `defaultPlan`, 1 fetch each day and seed 7, when each hour of day `d` is read, then its `askKwh` is the `heatKwh` of that hour in `planDay`. The call uses the first 24 values of `hourlyEnergy` of the fetch at hour `24 × d`, the tank energy after hour 23 of day `d - 1` (10.5 kWh for day 0), and the sum of `drawKwh` for the 24 hours of day `d`, without the factor of the day.
- Given 0 days, when the run ends, then it has no hours.

### CAP-homesim.R2 · No cold tank

Status: ready · Intents: IN-0008

The thermostat of the tank keeps the hot water ready for every policy. Thus, no hour has an
unmet draw, the tank never ends an hour below its floor, and the tank is full at least once
each day (assumed). The backstop heating is the price of a policy that lets the tank fall.
The days are different, because the draw changes from day to day. Thus, the lines hold also
with the spread of 0.25 of the default home, and with a spread of 0.5.

In these lines, the home is `defaultHome`, the run is 365 days, and the tolerance is 0.000000001
kWh. A policy is the static policy with `defaultStatic`, the precomputed policy with `defaultPlan`,
or the dynamic policy with `defaultDynamic`.

- Given each policy and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour.
- Given each policy and the seeds 1 to 5, when the run ends, then the tank holds at least 2.1 kWh after each hour, and `coldHours` is 0.
- Given each policy and the seeds 1 to 5, when the run ends, then each day has an hour after which the tank is full, within 0.000000001 kWh.
- Given each policy, a spread of 0.5 and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour and `coldHours` is 0.
- Given a static policy with 0 heating hours and seed 7, when the run ends, then the backstop heating is more than 500 kWh and the unmet draw is 0 kWh.
- Given a home with an element of 0.2 kW, and the static policy with 0 heating hours, when the run ends, then the unmet draw is more than 0 kWh and `coldHours` is more than 0.

### CAP-homesim.R3 · Totals and ratios

Status: ready · Intents: IN-0008

The totals add up the hours. The self-consumption is the solar energy less the export, as a
percentage of the solar energy. The self-sufficiency is the load less the import, as a
percentage of the load. A ratio with nothing to divide by is 0% (assumed). The solar energy and
the energy of the tank and the battery balance.

In these lines, the home is `defaultHome`, the policy is the static policy with
`defaultStatic`, and the seed is 7, unless the line says otherwise. The tolerance is 0.01 kWh.

- Given 365 days, when the run ends, then each total equals the sum of its hours.
- Given 365 days, when the run ends, then solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end.
- Given 365 days, when the run ends, then the energy in the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy.
- Given 365 days, when the run ends, then `unmetKwh` plus the served draw equals `drawKwh`. The draw is the sum of the hours.
- Given 365 days, when the run ends, then the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load.
- Given 365 days and a spread of 0, when the run ends, then the draw total is 2190.0 kWh, within 0.1 kWh.
- Given 365 days, a spread of 0.25 and each seed from 1 to 5, when the run ends, then the draw total is from 2060 to 2320 kWh.
- Given 0 kW of panels and 365 days, when the run ends, then the self-consumption is 0%.
- Given 0 days, when the run ends, then each total is 0 and each ratio is 0%. The exceptions are `minTankKwh` and `finalTankKwh`, which are 10.5 kWh, the energy of the full tank at the start.

### CAP-homesim.R4 · Policies at work

Status: ready · Intents: IN-0008

Each kind of policy acts as CAP-policy (daily-profile policies) says. A static policy heats
only in its window. A precomputed policy heats only in hours that its forecast calls sunny. A
dynamic policy heats only when it has a surplus or the tank is low. Heating the tank in the sun
makes the home use more of its sun.

In these lines, the home is `defaultHome` and the run is 365 days, unless the line says
otherwise. The tolerance of a solar energy against 0.5 kWh is 0.000001 kWh.

- Given the static policy with `defaultStatic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours 10, 11, 12 and 13.
- Given the precomputed policy with `defaultPlan`, an error scale of 0, 1 fetch each day and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours whose solar energy is at least 0.5 kWh.
- Given the dynamic policy with `defaultDynamic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in an hour whose solar energy is more than its house load, or whose tank held less than 5.25 kWh before the hour.
- Given the static policy with `defaultStatic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the first has a higher self-consumption.
- Given the dynamic policy with `defaultDynamic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the dynamic policy has a higher self-consumption.
- Given the same policy and seed twice, when the runs end, then the two runs have the same hours.

### CAP-homesim.R5 · Robust evaluation

Status: ready · Intents: IN-0008

An evaluation runs the policy for each seed from the first seed, and sums up the runs. The
mean values are the averages of the runs. The worst self-consumption is the lowest of the runs.
`unmetSeeds` counts the runs with an unmet draw. A count of 0 seeds gives 0 in every field
(assumed).

In these lines, the home is `defaultHome`, the policy is the static policy with `defaultStatic`,
and each run is 365 days, unless the line says otherwise. The tolerance is 0.000000001.

- Given the first seed 3 and 1 seed, when the policy is evaluated, then the mean and the worst self-consumption are the self-consumption of the run with seed 3.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean self-consumption is the average of the runs with seeds 3, 4, 5 and 6, and the worst is the lowest of them.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the worst self-consumption is not more than the mean.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean import, export and backstop heating are the averages of the runs, and the total unmet draw is their sum.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then `seeds` is 4, and `unmetSeeds` and `coldHours` are 0.
- Given 0 seeds, when the policy is evaluated, then each field is 0.
- Given the same arguments twice, when the policy is evaluated, then the two evaluations are the same.

### CAP-homesim.R6 · Tuning a static profile

Status: ready · Intents: IN-0008

The tuner tries each static profile of a fixed grid, with the element power of the home
tank: a start from 6 to 16, from 1 to 8 heating hours, and discharge from 15 to 22. That is 704
candidates. It evaluates each candidate. A candidate is safe when no seed has an unmet draw.
The best candidate is the safe candidate with the highest mean self-consumption. A safe
candidate within 0.05 points of the highest has the same standing, and then the lowest mean
import wins. A tie goes to the first candidate, in the order of the start, the heating hours
and the discharge hour (assumed). If no candidate is safe, the best is the candidate with the
lowest total unmet draw (assumed).

In these lines, the home is `defaultHome`. The tolerance is 0.000000001.

- Given 2 seeds from seed 1 and 30 days, when the profile is tuned, then `candidates` is 704, and `safe` is 704.
- Given the same arguments, when the profile is tuned, then the best start is from 6 to 16, its heating hours are from 1 to 8, and its discharge hour is from 15 to 22.
- Given the same arguments, when the profile is tuned, then the evaluation is the evaluation of the best static profile over the same seeds and days.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate has a mean self-consumption more than 0.05 points above the best.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate within 0.05 points of the highest has a lower mean import than the best.
- Given the same arguments twice, when the profile is tuned, then the two results are the same.
- Given a home with 0 kW of panels, 2 seeds from seed 1 and 30 days, when the profile is tuned, then `safe` is 704 and the best mean self-consumption is 0%.

### JOB-simulate.R5 · Bad command line

Status: ready · Intents: IN-0001, IN-0008

A bad command line prints one error line on stderr, prints nothing on stdout, and exits
with 2 (assumed). The line is `error: <code>: <detail>` (assumed). `sim`, `sim help` and
`sim --help` print the usage on stdout and exit with 0.

A number option takes an optional sign, digits, and an optional point with more digits
(assumed). `--days` and `--seed` take only whole numbers (assumed). When an option comes
twice, the last value counts (assumed). The `--flex` range shows the `--load` value as
the person typed it (assumed). Any other word is an unknown option (assumed). The ranges are these (assumed):

| Option | Lowest | Highest |
|---|---|---|
| `--days` | 1 | 3650 |
| `--seed` | 0 | 4294967295 |
| `--lat` | -90 | 90 |
| `--pv` | 0 | 100 |
| `--battery` | 0 | 200 |
| `--power` | 0 | 100 |
| `--load` | 0.1 | 1000 |
| `--flex` | 0 | the `--load` value |

The range in an `OUT_OF_RANGE` line is `(<lowest> to <highest>)`, written as in this table,
for example `(-90 to 90)` and `(0.1 to 1000)` (assumed).

- Given no arguments, when the person runs `sim`, then the first line on stdout is `usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]`. The exit code is 0.
- Given `help`, when the person runs `sim help`, then it prints the same usage and exits with 0.
- Given `--help`, when the person runs `sim --help`, then it prints the same usage and exits with 0.
- Given the command `fly`, when the person runs `sim fly`, then stderr is `error: UNKNOWN_COMMAND: fly`. The exit code is 2.
- Given `--colour red`, when the person runs `sim run`, then stderr is `error: UNKNOWN_OPTION: --colour`. The exit code is 2.
- Given `--days` with no value, when the person runs `sim run`, then stderr is `error: MISSING_VALUE: --days`. The exit code is 2.
- Given `--days abc`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days abc`. The exit code is 2.
- Given `--days ""`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days `. The exit code is 2.
- Given `--days 36.5`, when the person runs `sim run`, then stderr is `error: BAD_NUMBER: --days 36.5`. The exit code is 2.
- Given `--pv 1e3`, `--pv .5`, `--pv 5.` or `--pv 5kW`, when the person runs `sim run`, then each gives `BAD_NUMBER` and exit code 2.
- Given `--pv +3`, when the person runs `sim run`, then it exits with 0, and the result equals the result of `--pv 3`.
- Given `--days 0`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 0 (1 to 3650)`. The exit code is 2.
- Given `--days 3651`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --days 3651 (1 to 3650)`. The exit code is 2.
- Given `--days 99999999999999999999`, when the person runs `sim run`, then it gives `OUT_OF_RANGE` and exit code 2.
- Given `--seed -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)`. The exit code is 2.
- Given `--seed 4294967295`, when the person runs `sim run`, then it exits with 0. `--seed 4294967296` gives `OUT_OF_RANGE`.
- Given `--lat 90` and `--lat -90`, when the person runs `sim run`, then each exits with 0.
- Given `--lat 90.1` and `--lat -90.1`, when the person runs `sim run`, then each gives `OUT_OF_RANGE` and exit code 2.
- Given `--pv 100` and `--pv 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--pv -1`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --pv -1 (0 to 100)`. The exit code is 2.
- Given `--battery 200` and `--battery 200.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--power 100` and `--power 100.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 0.1` and `--load 0`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 1000` and `--load 1000.1`, when the person runs `sim run`, then the first exits with 0. The second gives `OUT_OF_RANGE`.
- Given `--load 10 --flex 10`, when the person runs `sim run`, then it exits with 0.
- Given `--load 10 --flex 10.5`, when the person runs `sim run`, then stderr is `error: OUT_OF_RANGE: --flex 10.5 (0 to 10)`. The exit code is 2.
- Given `--strategy wild`, when the person runs `sim run`, then stderr is `error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)`. The exit code is 2.
- Given the extra word `now`, when the person runs `sim run now`, then stderr is `error: UNKNOWN_OPTION: now`. The exit code is 2.
- Given `--days 10 --days 20`, when the person runs `sim run`, then the `days` line shows 20.
- Given each error above, when the person runs the command, then stdout is empty.

### JOB-simulate.R6 · Forecast command

Status: ready · Intents: IN-0008

`sim forecast` prints on stdout the Solcast JSON of CAP-forecast (simulated Solcast
forecasts) for one fetch, then a line break, and exits with 0. `--hour` gives the hour of the
run of the fetch, with the default 0 (assumed). Its range is 0 to 24 × days less 1, and the
value is a whole number. `--lon` is the longitude in degrees, east is positive, with the
default 174.8 and the range -180 to 180 (assumed). `--forecast-error` is the error scale, with
the default 1 and the range 0 to 5 (assumed). The command also takes `--lat`, `--pv`, `--days`
and `--seed` of `sim run`, with the same defaults and ranges. Any other option is an unknown
option.

- Given no options, when the person runs `sim forecast`, then stdout starts with `{"forecasts":[{"pv_estimate":` and has 96 periods.
- Given no options, when the person runs `sim forecast`, then the first `period_end` is `2024-12-31T13:00:00.0000000Z`.
- Given `--lon 0`, when the person runs `sim forecast`, then the first `period_end` is `2025-01-01T00:30:00.0000000Z`.
- Given `--hour 8759`, when the person runs `sim forecast`, then the JSON has 2 periods.
- Given `--forecast-error 0 --lat 45 --hour 4116`, when the person runs `sim forecast`, then each `pv_estimate10` and `pv_estimate90` equals its `pv_estimate`.
- Given `--seed 3 --hour 4116`, when the person runs `sim forecast` two times, then the two outputs are the same.
- Given `--hour 8760`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 8760 (0 to 8759)`. The exit code is 2.
- Given `--days 2 --hour 48`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --hour 48 (0 to 47)`. The exit code is 2.
- Given `--hour abc`, when the person runs `sim forecast`, then stderr is `error: BAD_NUMBER: --hour abc`. The exit code is 2.
- Given `--hour 2.5`, when the person runs `sim forecast`, then stderr is `error: BAD_NUMBER: --hour 2.5`. The exit code is 2.
- Given `--hour` with no value, when the person runs `sim forecast`, then stderr is `error: MISSING_VALUE: --hour`. The exit code is 2.
- Given `--lon 180.1`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --lon 180.1 (-180 to 180)`. The exit code is 2. `--lon 180` and `--lon -180` exit with 0.
- Given `--forecast-error 5.1`, when the person runs `sim forecast`, then stderr is `error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)`. The exit code is 2. `--forecast-error 5` and `--forecast-error 0` exit with 0.
- Given `--strategy greedy`, when the person runs `sim forecast`, then stderr is `error: UNKNOWN_OPTION: --strategy`. The exit code is 2.
- Given `--battery 5`, when the person runs `sim forecast`, then stderr is `error: UNKNOWN_OPTION: --battery`. The exit code is 2.
- Given each error above, when the person runs the command, then stdout is empty.

### JOB-simulate.R7 · Policy run

Status: ready · Intents: IN-0008

`sim policy run` simulates one policy for a home with a hot-water tank, prints the result on
stdout, and exits with 0. Each line is a label, spaces to column 19, and a value (assumed). An
energy has one decimal and `kWh`, and a ratio has one decimal and `%`. The lines are `policy`
(the name), `days`, `seed`, `solar`, `load`, `import`, `export`, `heating` (the heating that the
policy asked for and the tank took), `backstop`, `unmet-hot-water`, `cold-hours` (a whole
number), `self-consumption` and `self-sufficiency`, in this order. The `load` line includes the
heating and the backstop heating.

The options are those of `sim run` except `--strategy` and `--monthly`, and these options. The
defaults are those of CAP-homesim (home simulation) and CAP-policy (daily-profile policies):

- `--policy`: `static`, `precomputed` or `dynamic`. Default `static`.
- `--tank` (kWh), `--element` (kW), `--cut-in` (kWh, the level below which the thermostat cuts in), `--floor` (kWh, the level below which the tank counts as cold) and `--draw` (kWh of hot water each day): 10.5, 3.0, 5.25, 2.1 and 6.0.
- `--draw-cv` (the spread of the draw from day to day): 0.25.
- `--fetches` and `--forecast-error`: 10 and 1.
- `--heat-start`, `--heat-hours` and `--discharge-from` of the static policy: 10, 4 and 17.
- `--target` (kWh) and `--min-solar` (kWh) of the precomputed policy: 10.5 and 0.5.
- `--low` (kWh) of the dynamic policy: 5.25. The precomputed policy and the dynamic policy also use `--discharge-from`, and the dynamic policy also uses `--target`.

- Given no options, when the person runs `sim policy run`, then it prints the 13 lines in order and exits with 0.
- Given no options, when the person runs `sim policy run`, then the first three lines are `policy            static`, `days              365` and `seed              1`.
- Given `--policy dynamic --days 30 --lat 45 --seed 9`, when the person runs `sim policy run`, then the lines show `dynamic`, 30 days and seed 9. The values equal the totals of CAP-homesim (home simulation) for these options.
- Given `--policy precomputed --target 8 --min-solar 1`, when the person runs `sim policy run`, then the values equal the totals of CAP-homesim for the precomputed policy with this target and this minimum.
- Given `--heat-hours 0`, when the person runs `sim policy run`, then the `heating` line is `heating           0.0 kWh` and the `backstop` value is more than 0.0 kWh.
- Given `--tank 0 --draw-cv 0`, when the person runs `sim policy run`, then the `unmet-hot-water` value is 2190.0 kWh, within 0.1 kWh, and the `heating` and `backstop` values are 0.0 kWh.
- Given `--element 0.2 --heat-hours 0 --days 90`, when the person runs `sim policy run`, then the `unmet-hot-water` value is more than 0.0 kWh and the `cold-hours` value is more than 0.
- Given no options, when the person runs `sim policy run`, then the `unmet-hot-water` line is `unmet-hot-water   0.0 kWh` and the `cold-hours` line is `cold-hours        0`.
- Given `--seed 5`, when the person runs `sim policy run` two times, then the two outputs are the same.
- Given `--policy wild`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)`. The exit code is 2. A name that differs by its case, such as `Static`, gives the same error.
- Given `--seeds 3`, when the person runs `sim policy run`, then stderr is `error: UNKNOWN_OPTION: --seeds`. The exit code is 2. `--strategy` and `--monthly` give `UNKNOWN_OPTION` too.
- Given each error above, when the person runs the command, then stdout is empty.

### JOB-simulate.R8 · Policy compare

Status: ready · Intents: IN-0008

`sim policy compare` runs five policies on the same weather, and prints one row for each. The
`thermostat` policy is the static policy with 0 heating hours, so the tank gets only the
backstop heating of the thermostat. The next rows are the static, the precomputed and the
dynamic policy. The `perfect-forecast` row is the precomputed policy with a forecast error of
0, so that it knows the sun of the day. It shows what a better forecast can gain. The
header, which is a guess (assumed), is `policy self-consumption-% self-sufficiency-% import-kWh
export-kWh backstop-kWh`. The columns align by spaces. The command takes the options of `sim policy run`
except `--policy` and `--seeds`.

- Given no options, when the person runs `sim policy compare`, then it prints the header and the rows `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order, and exits with 0.
- Given `--seed 9 --lat 45 --days 90`, when the person runs `sim policy compare`, then each row shows the values of CAP-homesim (home simulation) for its policy and these options, with one decimal.
- Given `--seed 9 --lat 45`, when the person runs `sim policy compare`, then the `static` row shows the same five values as `sim policy run --seed 9 --lat 45`.
- Given `--heat-hours 0`, when the person runs `sim policy compare`, then the `static` row shows the same five values as the `thermostat` row.
- Given `--forecast-error 0`, when the person runs `sim policy compare`, then the `perfect-forecast` row shows the same five values as the `precomputed` row.
- Given `--seed 9 --lat 45 --days 90`, when the person runs `sim policy compare`, then the `perfect-forecast` row shows the values of CAP-homesim for the precomputed policy with an error scale of 0.
- Given no options, when the person runs `sim policy compare`, then the `static` self-consumption is more than the `thermostat` self-consumption, and so is the `dynamic` self-consumption.
- Given `--policy static`, when the person runs `sim policy compare`, then stderr is `error: UNKNOWN_OPTION: --policy`. The exit code is 2. `--seeds 3` gives `error: UNKNOWN_OPTION: --seeds`.

### JOB-simulate.R9 · Policy robust

Status: ready · Intents: IN-0008

`sim policy robust` evaluates the five policies of R8 over many weather seeds, from `--seed`,
and prints one row for each. The header is `policy mean-self-consumption-%
worst-self-consumption-% mean-self-sufficiency-% mean-export-kWh mean-backstop-kWh unmet-kWh
cold-hours safe` (assumed). `unmet-kWh` is the total unmet draw. `safe` is `yes` when no seed has an
unmet draw and `cold-hours` is 0, and else `no`. `--seeds` is the count of seeds, a whole number
from 1 to 100, with the default 10 (assumed). The command takes the options of `sim policy compare` and `--seeds`.

- Given no options, when the person runs `sim policy robust`, then it prints the header and the rows `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order, and exits with 0.
- Given no options, when the person runs `sim policy robust`, then each row shows the values of CAP-homesim (home simulation) for the evaluation over the seeds 1 to 10, with one decimal.
- Given `--seeds 1 --seed 4`, when the person runs `sim policy robust`, then the mean and the worst self-consumption of each row are the self-consumption of the same row of `sim policy compare --seed 4`.
- Given no options, when the person runs `sim policy robust`, then the worst self-consumption of each row is not more than its mean.
- Given no options, when the person runs `sim policy robust`, then each row has `unmet-kWh` 0.0, `cold-hours` 0 and `safe` `yes`.
- Given `--element 0.2 --days 90`, when the person runs `sim policy robust`, then the `thermostat` row has `safe` `no`, and its `unmet-kWh` is more than 0.0.
- Given `--seed 7 --seeds 3` two times, when the person runs `sim policy robust`, then the two outputs are the same.
- Given `--seeds 0`, when the person runs `sim policy robust`, then stderr is `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. The exit code is 2. `--seeds 101` gives `error: OUT_OF_RANGE: --seeds 101 (1 to 100)`, and `--seeds 100` exits with 0.
- Given `--seeds 2.5`, when the person runs `sim policy robust`, then stderr is `error: BAD_NUMBER: --seeds 2.5`. The exit code is 2.

### JOB-simulate.R10 · Policy tune

Status: ready · Intents: IN-0008

`sim policy tune` searches the best static profile (CAP-homesim, R6), and prints it. The
first five lines are `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`,
each as a label, spaces to column 19, and a whole number. Then comes a blank line, and the
table of `sim policy robust` for the same options, with the best static profile in the row
`static`. `--seeds` has the default 5 (assumed). The command takes the options of `sim policy
robust` except `--heat-start`, `--heat-hours` and `--discharge-from`, which the search sets.

- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the first lines are `candidates        704` and `safe              704`, and the command exits with 0.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then `heat-start` is from 6 to 16, `heat-hours` is from 1 to 8, and `discharge-from` is from 15 to 22.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the profile equals the best profile of CAP-homesim (home simulation) for these options.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the `static` row equals the `static` row of `sim policy robust` with the same options and the profile as `--heat-start`, `--heat-hours` and `--discharge-from`.
- Given `--seeds 2 --days 30`, when the person runs `sim policy tune`, then the `thermostat`, `precomputed`, `dynamic` and `perfect-forecast` rows equal the same rows of `sim policy robust` with the same options.
- Given `--seeds 2 --days 30` two times, when the person runs `sim policy tune`, then the two outputs are the same.
- Given `--heat-start 10`, when the person runs `sim policy tune`, then stderr is `error: UNKNOWN_OPTION: --heat-start`. The exit code is 2. `--heat-hours 4` and `--discharge-from 17` give `UNKNOWN_OPTION` too.
- Given `--seeds 0`, when the person runs `sim policy tune`, then stderr is `error: OUT_OF_RANGE: --seeds 0 (1 to 100)`. The exit code is 2.

### JOB-simulate.R11 · Policy options

Status: ready · Intents: IN-0008

The options of the policy commands follow the number rules of R5 (bad command line): a sign,
digits, and an optional point with digits. The options that count things are whole numbers. The
last value of an option counts. A range error shows the range as `(<lowest> to <highest>)`. The
ranges of the policy options are these (assumed):

| Option | Lowest | Highest | Whole |
|---|---|---|---|
| `--tank` | 0 | 50 | no |
| `--element` | 0 | 20 | no |
| `--cut-in` | 0 | 50 | no |
| `--floor` | 0 | 50 | no |
| `--draw` | 0 | 100 | no |
| `--draw-cv` | 0 | 1 | no |
| `--fetches` | 1 | 10 | yes |
| `--forecast-error` | 0 | 5 | no |
| `--heat-start` | 0 | 23 | yes |
| `--heat-hours` | 0 | 24 | yes |
| `--discharge-from` | 0 | 24 | yes |
| `--target` | 0 | 50 | no |
| `--min-solar` | 0 | 10 | no |
| `--low` | 0 | 50 | no |

- Given `--tank 0` and `--tank 50`, when the person runs `sim policy run`, then each exits with 0. `--tank 50.1` gives `error: OUT_OF_RANGE: --tank 50.1 (0 to 50)` and exit code 2.
- Given `--element 0` and `--element 20`, when the person runs `sim policy run`, then each exits with 0. `--element 20.1` gives `error: OUT_OF_RANGE: --element 20.1 (0 to 20)` and exit code 2.
- Given `--cut-in 0` and `--cut-in 50`, when the person runs `sim policy run`, then each exits with 0. `--cut-in 50.1` gives `error: OUT_OF_RANGE: --cut-in 50.1 (0 to 50)` and exit code 2.
- Given `--floor 0` and `--floor 50`, when the person runs `sim policy run`, then each exits with 0. `--floor 50.1` gives `error: OUT_OF_RANGE: --floor 50.1 (0 to 50)` and exit code 2.
- Given `--draw 0` and `--draw 100`, when the person runs `sim policy run`, then each exits with 0. `--draw 100.1` gives `error: OUT_OF_RANGE: --draw 100.1 (0 to 100)` and exit code 2.
- Given `--fetches 1` and `--fetches 10`, when the person runs `sim policy run --policy precomputed`, then each exits with 0. `--fetches 0` gives `error: OUT_OF_RANGE: --fetches 0 (1 to 10)` and `--fetches 11` gives `error: OUT_OF_RANGE: --fetches 11 (1 to 10)`. The exit code is 2.
- Given `--draw-cv 0` and `--draw-cv 1`, when the person runs `sim policy run`, then each exits with 0. `--draw-cv 1.1` gives `error: OUT_OF_RANGE: --draw-cv 1.1 (0 to 1)` and exit code 2.
- Given `--forecast-error 0` and `--forecast-error 5`, when the person runs `sim policy run`, then each exits with 0. `--forecast-error 5.1` gives `error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)` and exit code 2.
- Given `--heat-start 0` and `--heat-start 23`, when the person runs `sim policy run`, then each exits with 0. `--heat-start 24` gives `error: OUT_OF_RANGE: --heat-start 24 (0 to 23)` and exit code 2.
- Given `--heat-hours 0` and `--heat-hours 24`, when the person runs `sim policy run`, then each exits with 0. `--heat-hours 25` gives `error: OUT_OF_RANGE: --heat-hours 25 (0 to 24)` and exit code 2.
- Given `--discharge-from 0` and `--discharge-from 24`, when the person runs `sim policy run`, then each exits with 0. `--discharge-from 25` gives `error: OUT_OF_RANGE: --discharge-from 25 (0 to 24)` and exit code 2.
- Given `--target 0` and `--target 50`, when the person runs `sim policy run --policy dynamic`, then each exits with 0. `--target 50.1` gives `error: OUT_OF_RANGE: --target 50.1 (0 to 50)` and exit code 2.
- Given `--min-solar 0` and `--min-solar 10`, when the person runs `sim policy run --policy precomputed`, then each exits with 0. `--min-solar 10.1` gives `error: OUT_OF_RANGE: --min-solar 10.1 (0 to 10)` and exit code 2.
- Given `--low 0` and `--low 50`, when the person runs `sim policy run --policy dynamic`, then each exits with 0. `--low 50.1` gives `error: OUT_OF_RANGE: --low 50.1 (0 to 50)` and exit code 2.
- Given `--heat-hours 2.5`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --heat-hours 2.5`. The exit code is 2. `--fetches 2.5`, `--heat-start 1.5` and `--discharge-from 17.5` give the same error with their own option and value.
- Given `--tank abc`, when the person runs `sim policy run`, then stderr is `error: BAD_NUMBER: --tank abc`. The exit code is 2. `--element 1e3`, `--floor .5`, `--cut-in 3,5`, `--draw-cv x` and `--draw 5kW` give `BAD_NUMBER` with their own option and value.
- Given `--tank` with no value, when the person runs `sim policy run`, then stderr is `error: MISSING_VALUE: --tank`. The exit code is 2.
- Given `--tank -1`, when the person runs `sim policy run`, then stderr is `error: OUT_OF_RANGE: --tank -1 (0 to 50)`. The exit code is 2.
- Given `--tank 5 --tank 12`, when the person runs `sim policy run`, then the result equals the result of `--tank 12`.
- Given `--heat-start 20 --heat-hours 10`, when the person runs `sim policy run`, then it exits with 0, because the window stops at the end of the day.
- Given `sim policy fly`, when the person runs it, then stderr is `error: UNKNOWN_COMMAND: policy fly`. The exit code is 2. `sim policy` and `sim policy help` print the line `usage: sim policy run|compare|robust|tune [options]` first and exit with 0.
- Given each error above, when the person runs the command, then stdout is empty.

## The interface of each change of the intent

### CH-0006 · Forecast from built hours

Requirements: CAP-forecast.R6, CAP-forecast.R7

````
- `Period` · type · `StoragePolicySim/Forecast.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: the hours of `scenario site seed days`, built once by the caller, the same site and seed, the error scale, and the hour of the run at which the fetch is made
  - out: the same periods as `forecast site seed days errorScale fetchHour`, where `days` is the count of hours divided by 24
  - errors: none
- `Sky` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: `sunny`, `cloudy` or `overcast`, with `BEq`, `Repr` and `Inhabited`
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `Hour` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams
- `seed` · seam: randomness · `StoragePolicySim/Forecast.lean`
  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
  - errors: none
````

### CH-0007 · Hot-water tank with a thermostat

Requirements: CAP-hotwater.R1, CAP-hotwater.R2, CAP-hotwater.R3, CAP-hotwater.R4, CAP-hotwater.R5, CAP-hotwater.R6

````
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams
- `drawSeed` · seam: randomness · `StoragePolicySim/HotWater.lean`
  - in: the `seed` argument of `drawFactor`. The same seed gives the same factors.
  - errors: none
````

### CH-0008 · Allowed battery use

Requirements: CAP-simulation.R6

````
- `Battery` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `capacityKwh` and `powerKw`, each a `Float`
  - errors: none
- `Flow` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `directKwh`, `chargeKwh`, `dischargeKwh`, `exportKwh`, `importKwh`, `lossKwh` and `socKwh`.
  - errors: none
- `stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, a strategy, the hour of the day, and the solar energy and the load of the hour
  - out: the flows of the hour. `socKwh` of the flow is the energy that the battery holds after the hour.
  - errors: none
- `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, whether it may charge, whether it may discharge, and the solar energy and the load of the hour
  - out: the flows of the hour, with the same rules as `stepHour`. The battery charges only when it may charge, and discharges only when it may discharge.
  - errors: none
- `Strategy` · type · `StoragePolicySim/Strategy.lean`
  - in: not applicable
  - out: `none`, `greedy`, `evening` or `shift`, with `BEq`, `Repr` and `Inhabited`. Write a value in full, for example `Strategy.none`, so that it does not mean `Option.none`.
  - errors: none
- `Sky` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: `sunny`, `cloudy` or `overcast`, with `BEq`, `Repr` and `Inhabited`
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `Hour` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams
- `seed` · seam: randomness · `StoragePolicySim/Simulation.lean`
  - in: the `seed` argument of `simulate`. The same seed gives the same weather.
  - errors: none
````

### CH-0009 · Daily-profile policies

Requirements: CAP-policy.R1, CAP-policy.R2, CAP-policy.R3, CAP-policy.R4

````
- `Action` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Observation` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `hour : Nat`, and `tankKwh`, `socKwh`, `surplusKwh` and `forecastRestKwh`, each a `Float`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `Policy.name (policy : Policy) : String` · function · `StoragePolicySim/Policy.lean`
  - in: a policy
  - out: `"static"`, `"precomputed"` or `"dynamic"`
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `planDay (cfg : TankConfig) (params : PlanParams) (forecastKwh : Array Float) (tankKwh expectedDrawKwh : Float) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: a tank, the parameters of a precomputed policy, the forecast solar energy of the 24 hours of the day, the energy in the tank at the start of the day, and the hot water that the household is expected to draw in the day
  - out: 24 actions, one for each hour of the day
  - errors: none
- `dynamicAction (cfg : TankConfig) (params : DynamicParams) (obs : Observation) : Action` · function · `StoragePolicySim/Policy.lean`
  - in: a tank, the parameters of a dynamic policy, and what the policy sees in the hour
  - out: the action of the hour
  - errors: none
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none

### Test seams
none
````

### CH-0010 · Home simulation, robust evaluation and tuning

Requirements: CAP-homesim.R1, CAP-homesim.R2, CAP-homesim.R3, CAP-homesim.R4, CAP-homesim.R5, CAP-homesim.R6

````
- `HomeSetup` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `drawCv : Float` (the spread of that draw from day to day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day with a spread of 0.25, 10 fetches each day, and an error scale of 1.0
  - errors: none
- `HomeHour` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `day` and `hour` (each a `Nat`), `pvKwh`, `houseLoadKwh` (the base load and the flexible load), `drawKwh`, `askKwh` (the heating that the policy asked for), `heatKwh`, `backstopKwh`, `unmetKwh` and `tankKwh` (the energy in the tank after the hour), each a `Float`, `allowCharge` and `allowDischarge`, each a `Bool`, and `flow : Flow`.
  - errors: none
- `HomeTotals` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh` (the house load, the heating and the backstop heating), `importKwh`, `exportKwh`, `batteryLossKwh`, `tankLossKwh`, `heatKwh`, `backstopKwh`, `drawKwh`, `unmetKwh`, `minTankKwh`, `finalTankKwh`, `selfConsumption` and `selfSufficiency`. The field `coldHours` is a `Nat`.
  - errors: none
- `HomeResult` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HomeHour` and `totals : HomeTotals`
  - errors: none
- `runHome (setup : HomeSetup) (policy : Policy) (seed days : Nat) : HomeResult` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, a policy, a seed, and the days of the run
  - out: the hours and the totals of the run
  - errors: none
- `Evaluation` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `meanSelfConsumption`, `worstSelfConsumption`, `meanSelfSufficiency`, `meanImportKwh`, `meanExportKwh`, `meanBackstopKwh` and `totalUnmetKwh` are each a `Float`. The fields `seeds`, `unmetSeeds` and `coldHours` are each a `Nat`.
  - errors: none
- `evaluate (setup : HomeSetup) (policy : Policy) (seed seeds days : Nat) : Evaluation` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, a policy, the first seed, the count of seeds, and the days of each run
  - out: the evaluation over the seeds `seed` to `seed + seeds - 1`
  - errors: none
- `TuneResult` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `best : StaticParams`, `evaluation : Evaluation`, `candidates : Nat` and `safe : Nat`.
  - errors: none
- `tuneStatic (setup : HomeSetup) (seed seeds days : Nat) : TuneResult` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, the first seed, the count of seeds, and the days of each run
  - out: the best static profile that the search finds, its evaluation, the count of candidates, and the count of safe candidates
  - errors: none
- `Sky` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: `sunny`, `cloudy` or `overcast`, with `BEq`, `Repr` and `Inhabited`
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `Hour` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `Battery` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `capacityKwh` and `powerKw`, each a `Float`
  - errors: none
- `Flow` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `directKwh`, `chargeKwh`, `dischargeKwh`, `exportKwh`, `importKwh`, `lossKwh` and `socKwh`.
  - errors: none
- `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, whether it may charge, whether it may discharge, and the solar energy and the load of the hour
  - out: the flows of the hour, with the same rules as `stepHour`. The battery charges only when it may charge, and discharges only when it may discharge.
  - errors: none
- `Action` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams
- `homeSeed` · seam: randomness · `StoragePolicySim/HomeSim.lean`
  - in: the `seed` argument of `runHome`, `evaluate` and `tuneStatic`. The same seed gives the same weather and the same forecast.
  - errors: none
````

### CH-0011 · The forecast and policy commands

Requirements: JOB-simulate.R5, JOB-simulate.R6, JOB-simulate.R7, JOB-simulate.R8, JOB-simulate.R9, JOB-simulate.R10, JOB-simulate.R11

````
- `sim [help | --help]` · command · `Main.lean`
  - in: no argument, `help` or `--help`, or the name of a command
  - out: on standard output, the usage. The first line is `usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]`. Then the options follow, each on a line. The exit code is 0.
  - errors:
    - `UNKNOWN_COMMAND` · `error: UNKNOWN_COMMAND: <word>` · exit 2 · stderr
- `sim forecast [--hour H] [--lon L] [--forecast-error E] [--lat N] [--pv N] [--days N] [--seed N]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the Solcast JSON of CAP-forecast for one fetch, and a line break. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy [help]` · command · `Main.lean`
  - in: no argument, or `help`
  - out: on standard output, the line `usage: sim policy run|compare|robust|tune [options]` and the options. The exit code is 0.
  - errors:
    - `UNKNOWN_COMMAND` · `error: UNKNOWN_COMMAND: <word>` · exit 2 · stderr
- `sim policy run [--policy NAME] [policy options]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, 13 lines. Each line is a label, spaces to column 19, and a value. The labels are `policy`, `days`, `seed`, `solar`, `load`, `import`, `export`, `heating`, `backstop`, `unmet-hot-water`, `cold-hours`, `self-consumption` and `self-sufficiency`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
    - `UNKNOWN_POLICY` · `error: UNKNOWN_POLICY: <name> (static, precomputed, dynamic)` · exit 2 · stderr
- `sim policy compare [policy options]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the header `policy self-consumption-% self-sufficiency-% import-kWh export-kWh backstop-kWh`, and one row for each of `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy robust [--seeds N] [policy options]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the header `policy mean-self-consumption-% worst-self-consumption-% mean-self-sufficiency-% mean-export-kWh mean-backstop-kWh unmet-kWh cold-hours safe`, and one row for each of `thermostat`, `static`, `precomputed`, `dynamic` and `perfect-forecast`, in this order. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `sim policy tune [--seeds N] [policy options except the static profile]` · command · `Main.lean`
  - in: the options, each with one value
  - out: on standard output, the lines `candidates`, `safe`, `heat-start`, `heat-hours` and `discharge-from`, a blank line, and the table of `sim policy robust` with the best static profile in the row `static`. The exit code is 0.
  - errors:
    - `UNKNOWN_OPTION` · `error: UNKNOWN_OPTION: <word>` · exit 2 · stderr
    - `MISSING_VALUE` · `error: MISSING_VALUE: <option>` · exit 2 · stderr
    - `BAD_NUMBER` · `error: BAD_NUMBER: <option> <value>` · exit 2 · stderr
    - `OUT_OF_RANGE` · `error: OUT_OF_RANGE: <option> <value> (<lowest> to <highest>)` · exit 2 · stderr
- `HomeSetup` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `drawCv : Float` (the spread of that draw from day to day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day with a spread of 0.25, 10 fetches each day, and an error scale of 1.0
  - errors: none
- `HomeTotals` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh` (the house load, the heating and the backstop heating), `importKwh`, `exportKwh`, `batteryLossKwh`, `tankLossKwh`, `heatKwh`, `backstopKwh`, `drawKwh`, `unmetKwh`, `minTankKwh`, `finalTankKwh`, `selfConsumption` and `selfSufficiency`. The field `coldHours` is a `Nat`.
  - errors: none
- `HomeResult` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HomeHour` and `totals : HomeTotals`
  - errors: none
- `runHome (setup : HomeSetup) (policy : Policy) (seed days : Nat) : HomeResult` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, a policy, a seed, and the days of the run
  - out: the hours and the totals of the run
  - errors: none
- `Evaluation` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `meanSelfConsumption`, `worstSelfConsumption`, `meanSelfSufficiency`, `meanImportKwh`, `meanExportKwh`, `meanBackstopKwh` and `totalUnmetKwh` are each a `Float`. The fields `seeds`, `unmetSeeds` and `coldHours` are each a `Nat`.
  - errors: none
- `evaluate (setup : HomeSetup) (policy : Policy) (seed seeds days : Nat) : Evaluation` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, a policy, the first seed, the count of seeds, and the days of each run
  - out: the evaluation over the seeds `seed` to `seed + seeds - 1`
  - errors: none
- `TuneResult` · type · `StoragePolicySim/HomeSim.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `best : StaticParams`, `evaluation : Evaluation`, `candidates : Nat` and `safe : Nat`.
  - errors: none
- `tuneStatic (setup : HomeSetup) (seed seeds days : Nat) : TuneResult` · function · `StoragePolicySim/HomeSim.lean`
  - in: a home, the first seed, the count of seeds, and the days of each run
  - out: the best static profile that the search finds, its evaluation, the count of candidates, and the count of safe candidates
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `Period` · type · `StoragePolicySim/Forecast.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams
- `--seed` · seam: randomness · `Main.lean`
  - in: a whole number. The same seed gives the same weather and the same forecast.
  - errors: none
````

## Specs the changes rely on

### CAP-scenario

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the conditions that a strategy must handle, one hour at a time. It gives
the solar output of each hour from the season and the sun height, and a daily sky from a
seeded weather model. It also gives the household load of each hour, with a seasonal base
load and a flexible load that a strategy can move.

## Code map

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`

## Interface

- `Sky` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: `sunny`, `cloudy` or `overcast`, with `BEq`, `Repr` and `Inhabited`
  - errors: none
- `Sky.factor (sky : Sky) : Float` · function · `StoragePolicySim/Scenario.lean`
  - in: a sky
  - out: 1.0 for `sunny`, 0.5 for `cloudy`, and 0.15 for `overcast`
  - errors: none
- `Site` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `latitude`, `pvKw`, `dailyLoadKwh` and `flexKwh`, each a `Float`
  - errors: none
- `Hour` · type · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Its fields are `day`, `dayOfYear` and `hour` (each a `Nat`), `sky : Sky`, and `pvKwh`, `baseLoadKwh` and `flexKwh` (each a `Float`).
  - errors: none
- `daysInYear : Nat` · constant · `StoragePolicySim/Scenario.lean`
  - in: not applicable
  - out: 365
  - errors: none
- `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, the day of the year from 0, the hour of the day from 0 to 23, and a sky
  - out: the solar energy of the hour in kWh. It reads only `latitude` and `pvKw` of the site.
  - errors: none
- `scenario (site : Site) (seed days : Nat) : Array Hour` · function · `StoragePolicySim/Scenario.lean`
  - in: a site, a seed, and the days of the run
  - out: `24 × days` hours, in order of day, then hour. The same arguments give the same array.
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Scenario.lean`
  - in: the `seed` argument of `scenario`. The same seed gives the same skies.
  - errors: none

## Requirements

### CAP-scenario.R1 · Seasonal sun

Status: verified · Intents: IN-0001

The output of an hour is the panel power, times the sine of the sun height, times the sky
factor (assumed). The sun height uses the latitude, the day of the year, and the middle of
the hour in solar time (assumed).

The declination is 23.44 degrees times sin(2π × (285 + day) / 365), where day 0 is 1 January
(assumed). The sky factor is 1.0 for sunny, 0.5 for cloudy, and 0.15 for overcast (assumed).
When the sun is below the horizon, the output is 0. In these lines, the site has 5 kW of panels,
unless the line says otherwise.

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

Status: verified · Intents: IN-0001

A seed and a number of days give one sky for each day, and the same hours each time. The
scenario starts on 1 January and gives the hours in order of day, then hour.

Each day keeps the sky of the day before with a chance of 0.6 (assumed). Else, the day takes
a new sky from the chances of its half of the year (assumed):

- Summer half: sunny 0.55, cloudy 0.30, overcast 0.15 (assumed).
- Winter half: sunny 0.20, cloudy 0.35, overcast 0.45 (assumed).

The summer half is days 90 to 272 of each year at latitude 0 or more, and the other days at
a negative latitude (assumed). After day 364, the day of the year starts again at 0.

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

Status: verified · Intents: IN-0001

The daily load includes the flexible load. The base load is the daily load less the flexible
load, spread over the hours by a fixed profile (assumed).

The profile has a morning peak and an evening peak (assumed). A seasonal factor of
1 + 0.2 × cos(2π × (day - peak) / 365) scales the base load (assumed). The peak is day 15 at
latitude 0 or more, and day 197 at a negative latitude (assumed).

By default, the flexible load uses equal parts at 18:00, 19:00 and 20:00 (assumed). The load
does not depend on the seed. In these lines, the daily load is 20 kWh with 3 kWh flexible,
unless the line says otherwise.

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.
````

### DES-errors

````
# DES-errors · The project's error codes

Status: agreed · Default: yes · Ask at init: no

## Rule

Each error that the system can give has a code here, in `UPPER_SNAKE_CASE`. Acceptance
lines, Interface entries, and checks all use these codes. Thus, a check can expect the
exact error.

| Code | Meaning | Whose fault | Retry helps? |
|---|---|---|---|
| `UNKNOWN_COMMAND` | The first word of the command line is not a command | caller | no |
| `UNKNOWN_OPTION` | An option or a word that the command does not take | caller | no |
| `MISSING_VALUE` | An option that needs a value comes last, with no value | caller | no |
| `BAD_NUMBER` | The value of a number option is not a number of the right form | caller | no |
| `OUT_OF_RANGE` | A number is outside the range of its option | caller | no |
| `UNKNOWN_STRATEGY` | The name of the strategy is not in the list of strategies | caller | no |
| `UNKNOWN_POLICY` | The name of the policy is not in the list of policies | caller | no |

When a requirement needs a new error, add a row. When the meaning is the same, use the
existing code again.

Add rows at intake and ready. Do not add a row while a change is in tests, build, or
verify. When you add a row, leave `Default:` as it is. Write each row the same way:

- The code in backticks.
- "Whose fault": `caller`, `system`, or `outside service`.
- "Retry helps?": `yes` or `no`.

Checks and the code of the app match on the error code. Each requirement decides what a
person sees, for example a message or a status. The message or the status can omit the
error code. If the caller cannot see the error code, a check expects the exact message and
status instead.

## Why

A check that expects "an error" passes for any error, also for a typo. A named code makes
the check exact. A named code also gives callers a stable value to handle.
````

### DES-pdlc-check-tagging

````
# DES-pdlc-check-tagging · How checks name their requirement

Status: agreed · Default: yes · Ask at init: yes

## Rule

The requirement ID starts the name of the check, for example `CAP-email.R3 sends from a
template`. A check that proves two requirements names the two requirements.

If the check runner does not accept `.` or `-` in names (Python's `unittest`, for
example), write the ID with underscores instead: `test_CAP_email_R3_sends_from_a_template`.
The two forms count as the same ID. Use only one form in each project.

Lay checks out the same way everywhere:

- Put new check files in the check folder (`tests/` in a project that had none). Name
  each file after the spec it proves, in a form the runner finds: `test_CAP_email.py`,
  `CAP-email.test.js`.
- Inside a file, make one group per requirement (a test class or a `describe` block).
  Name the group with the requirement ID: `class CAP_email_R3(unittest.TestCase)`,
  `describe("CAP-email.R3", ...)`.
- Each check's name still starts with the ID, then says what it proves.

The acceptance checks of an intent go in one file for each intent, at the path of
"acceptance file" in `pdlc/config.md`. The name of the file holds the word "acceptance"
and the intent ID, for example `tests/acceptance_IN_0012.py` or
`acceptance/IN-0012.acceptance.js`. The "all" command does not run such a file. Inside the
file, make one group for each requirement, and start each check name with the requirement
ID.

## Why

The trace from a requirement to its checks is only as good as this naming. Thus, the
naming must be simple and the same everywhere.
````

### DES-lean-checks

````
# DES-lean-checks · How a Lean check file runs and reports

Status: agreed · Default: no

## Rule

Each check file is a Lean script that `lake env lean --run <file> [filter]` runs. The file
has these parts:

- One file for each spec, named after the spec: `tests/CAP-scenario.lean`. The acceptance
  file of an intent is `tests/acceptance/IN-0001.acceptance.lean`.
- The imports of the library modules that the file calls, for example
  `import StoragePolicySim.Scenario`. A check file does not import another check file.
  Thus, each file holds its own small helpers.
- `def main (args : List String) : IO UInt32`.
- Each check has a name that starts with its requirement ID and a space, for example
  `"CAP-scenario.R1 day 171 gives more than twice day 354"`.
- The checks of one requirement are together, under the comment `-- CAP-scenario.R1`.

When `main` gets a first argument, it runs only the checks whose names start with that
argument and a space. Thus, the filter `CAP-scenario.R1` does not run `CAP-scenario.R10`.

The file prints `FAIL <name>: <what went wrong>` for each failed check. Its last line is
`<n> checks, <k> failed`. It exits with 1 when `k` is more than 0, and else with 0. A
filter that matches no check gives `0 checks, 0 failed`. The checks port reads that line
as "no checks found".

A check that runs the `sim` command uses `IO.Process.output` with the command `timeout`
and the arguments `60`, `.lake/build/bin/sim`, and then the arguments of `sim`. The check
reads the exit code, stdout and stderr. A `Float` comparison uses a tolerance.

## Example

```lean
import StoragePolicySim.Scenario
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 night gives no output",
    run := do
      let v := pvOutput site45 171 0 .sunny
      return if v == 0 then none else some s!"got {v}" }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    match ← c.run with
    | none => pure ()
    | some msg => failed := failed + 1; IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
```

The toolchain is Lean 4.35.0. In this version, `String.trim` does not exist. Use
`String.trimAscii` and then `.toString`, or split with `String.splitOn`.

## Why

Lean has no standard check runner. One small form for every file gives each check a name
with its requirement ID. It also gives a filter for one requirement, and one count line for the checks
port.
````

### CAP-strategies

````
# CAP-strategies · Battery and load strategies to compare

Status: active

## What it is for

CAP-strategies (battery and load strategies) holds the rules that the simulation compares.
Each strategy has a name. For each hour, a strategy asks the battery to charge or to
discharge. For each day, a strategy also places the flexible load.

The four strategies are these:

- `none`: no battery use.
- `greedy`: battery use at any hour.
- `evening`: discharge only in the evening.
- `shift`: greedy battery use, and the flexible load in the sunniest hours.

## Code map

- `StoragePolicySim/Strategy.lean`

## Interface

- `Strategy` · type · `StoragePolicySim/Strategy.lean`
  - in: not applicable
  - out: `none`, `greedy`, `evening` or `shift`, with `BEq`, `Repr` and `Inhabited`. Write a value in full, for example `Strategy.none`, so that it does not mean `Option.none`.
  - errors: none
- `Strategy.all : List Strategy` · constant · `StoragePolicySim/Strategy.lean`
  - in: not applicable
  - out: `[.none, .greedy, .evening, .shift]`
  - errors: none
- `Strategy.name (strategy : Strategy) : String` · function · `StoragePolicySim/Strategy.lean`
  - in: a strategy
  - out: `"none"`, `"greedy"`, `"evening"` or `"shift"`
  - errors: none
- `Strategy.ofName? (name : String) : Option Strategy` · function · `StoragePolicySim/Strategy.lean`
  - in: a name
  - out: the strategy whose name matches exactly, or `Option.none`
  - errors: none
- `Request` · type · `StoragePolicySim/Strategy.lean`
  - in: not applicable
  - out: a structure with `Repr`, and the fields `chargeKwh : Float` and `dischargeKwh : Float`
  - errors: none
- `Strategy.decide (strategy : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request` · function · `StoragePolicySim/Strategy.lean`
  - in: a strategy, the hour of the day, and the surplus and the shortfall of the hour
  - out: the energy that the strategy asks the battery to charge and to discharge
  - errors: none
- `Strategy.placeFlex (strategy : Strategy) (pvKwh flexKwh : Array Float) : Array Float` · function · `StoragePolicySim/Strategy.lean`
  - in: a strategy, the solar energy of the 24 hours of a day, and the flexible load of the 24 hours at its default hours
  - out: the flexible load of the 24 hours after the strategy places it
  - errors: none

### Test seams

none

## Requirements

### CAP-strategies.R1 · Strategy names

Status: verified · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: verified · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: verified · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: verified · Intents: IN-0001

The `evening` strategy charges as `greedy` does. It discharges only from 17:00 to 23:59
(assumed), to keep the stored energy for the evening peak. It keeps the flexible load at its
default hours.

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

Status: verified · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.
````

### CAP-hotwater

````
# CAP-hotwater · Hot-water tank with a thermostat

Status: active

## What it is for

CAP-hotwater (hot-water tank) models an electric hot-water tank, one hour at a time. The
tank holds thermal energy in kWh above the cold inlet. The element heats the tank by the
energy that a policy asks for. A thermostat with a cut-in level adds backstop heating, so that
the tank is never cold. The tank also heats to full once each day, because water that stays
below 60 °C can grow legionella bacteria. The household draws hot water by a daily profile
that changes with the season, and with a random factor for each day.

## Code map

- `StoragePolicySim/HotWater.lean`

## Interface

- `TankConfig` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams

- `drawSeed` · seam: randomness · `StoragePolicySim/HotWater.lean` · proposed
  - in: the `seed` argument of `drawFactor`. The same seed gives the same factors.
  - errors: none

## Requirements

### CAP-hotwater.R1 · Standby loss and draw

Status: ready · Intents: IN-0008

In each hour, the tank first loses a share of its energy, 0.6% in the default tank (assumed).
That is 1.5 kWh in a day for a full tank, near the average of the New Zealand tanks. Then the
household draws hot water. The tank serves the smaller of the draw and the energy that it
holds. The rest of the draw is the unmet draw.

In these lines, the tank is the default tank with a cut-in of 0 kWh, so that the thermostat
stays out of the line. The hour is 12, the thermostat is off, and the tank was full today.
The request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given 8.0 kWh stored and no draw, when the hour runs, then the loss is 0.048 kWh and the tank holds 7.952 kWh.
- Given 8.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.048 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 6.452 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.006 kWh, the served draw is 0.994 kWh and the unmet draw is 1.006 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.063 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits

Status: ready · Intents: IN-0008

The element heats the tank by the energy that the policy asks for. The heating is never more
than the element power for one hour, and never more than the room that the tank has left.
The draw of the hour comes before the heating (assumed). Thus, a tank that holds too little
energy has an unmet draw, also when the policy asks for heating in the same hour.

In these lines, the tank is the default tank with a cut-in of 0 kWh, the hour is 12, the
thermostat is off, and the tank was full today. The draw is 0 kWh, unless the line says
otherwise. The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.97 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.97 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.554 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.988 kWh and the unmet draw is 0.512 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat

Status: ready · Intents: IN-0008

After the heating of the policy, the thermostat decides. It cuts in when the tank holds less
than the cut-in level, 5.25 kWh in the default tank, which is half of the capacity (assumed).
Once in, it stays on from hour to hour, until the tank is full. That is the dead band of a
real thermostat. A tank is full when it holds its capacity, within 0.000000001 kWh.

While the thermostat is on, the backstop heating is the element power that the policy left in
the hour, and never more than the room that the tank has left. The backstop heating counts
apart from the heating that the policy asked for. When the thermostat is off, the backstop
heating is 0 kWh.

In these lines, the tank is the default tank, the hour is 12, the thermostat is off, the tank
was full today, the draw is 0 kWh and the request is 0 kWh, unless the line says otherwise.
The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 7.97 kWh and the thermostat is on.
- Given 6.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh, the tank holds 5.964 kWh and the thermostat is off.
- Given 6.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 8.964 kWh and the thermostat is on.
- Given 9.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and the thermostat is off.
- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the backstop heating is 0 kWh. The tank holds 6.97 kWh and the thermostat is off.
- Given 4.0 kWh stored and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 2.0 kWh. The tank holds 6.976 kWh and the thermostat is on.
- Given 9.0 kWh stored, the thermostat on and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 0.554 kWh. The tank holds 10.5 kWh and the thermostat is off.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the unmet draw is 1.006 kWh, the backstop heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a cut-in of 0 kWh and 1.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh.

### CAP-hotwater.R4 · Hot-water draw profile

Status: ready · Intents: IN-0008

The household draws more hot water in the morning and in the evening. The hours of a day share
the daily energy by a fixed profile with a peak at 07:00 and a peak at 19:00 (assumed). A
seasonal factor of 1 + 0.15 × cos(2π × (day - peak) / 365) scales the daily energy, because
the cold inlet is colder in winter (assumed). The peak is day 15 at latitude 0 or more, and
day 197 at a negative latitude (assumed).

In these lines, the daily energy is 6.0 kWh, unless the line says otherwise.

- Given latitude 45, when the draw of each hour of days 0 to 364 is added, then the sum is 2190.0 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the 24 hours of day 100 are added, then the sum is 6.0 × (1 + 0.15 × cos(2π × 85 / 365)) kWh. The tolerance is 0.000001 kWh.
- Given latitude 45, when the days 15 and 197 are compared, then the draw of day 15 is 1.34 to 1.37 times the draw of day 197.
- Given latitude -41, when the days 15 and 197 are compared, then the draw of day 197 is 1.34 to 1.37 times the draw of day 15.
- Given latitude 45, when the hours of day 100 are compared, then hour 7 draws more than hour 3, and hour 19 draws more than hour 13.
- Given a daily energy of 0.0 kWh, when each hour of day 100 is read, then each draw is 0 kWh.

### CAP-hotwater.R5 · Daily full heating

Status: ready · Intents: IN-0008

The tank is full at least once each day, so that the stored water stays hot enough against
legionella bacteria (assumed). From the guard hour, 20 in the default tank (assumed), the
thermostat cuts in when the tank has not been full since hour 0 of the day. It stays on until
the tank is full, as in R3. The state `fullToday` is false at the end of hour 0, unless the
tank is full after that hour. It becomes true in the hour in which the tank is full, and it
stays true to the end of the day.

In these lines, the tank is the default tank, the thermostat is off, the draw is 0 kWh and
the request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given hour 20, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 19, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh, the tank holds 8.946 kWh and `fullToday` is false.
- Given hour 20, 9.0 kWh stored and a tank that was full today, when the hour runs, then the backstop heating is 0 kWh and the tank holds 8.946 kWh.
- Given hour 22, 4.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 6.976 kWh and the thermostat is on.
- Given hour 0, 10.5 kWh stored and a tank that was full the day before, when the hour runs, then the tank holds 10.437 kWh and `fullToday` is false.
- Given hour 0, 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 12, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given a guard hour of 24, hour 23, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given the start state of the default tank, when `startState` is read, then the tank holds 10.5 kWh, the thermostat is off and `fullToday` is true.

### CAP-hotwater.R6 · Daily draw factor

Status: ready · Intents: IN-0008

A household draws more hot water on some days, and less on others. The factor of a day is
`exp(cv × z - cv × cv / 2)`, where `cv` is the spread of the draw and `z` is a random number
from a normal curve (assumed). The number `z` depends only on the seed and the day. Thus, the
mean of the factor is 1, and a spread of 0 gives the factor 1.

- Given a spread of 0, when the factors of days 0 to 364 are read, then each is 1.0. The tolerance is 0.000000000001.
- Given seed 7 and a spread of 0.25, when the factors of days 0 to 4999 are read, then each is more than 0. Their mean is from 0.98 to 1.02, and their standard deviation is from 0.23 to 0.27.
- Given seed 7 and a spread of 0.5, when the factors of days 0 to 4999 are read, then their mean is from 0.97 to 1.03, and their standard deviation is from 0.48 to 0.58.
- Given seed 7 and a spread of 0.25, when the factor of the same day is read two times, then the two factors are the same.
- Given the seeds 7 and 8 and a spread of 0.25, when the factors of days 0 to 364 are compared, then at least 300 days have a different factor.
````

### CAP-forecast

````
# CAP-forecast · Simulated Solcast rooftop forecasts for policies

Status: active

## What it is for

CAP-forecast (simulated Solcast forecasts) acts like the Solcast hobbyist rooftop forecast
service, for a scenario. A fetch at an hour of the run gives 30-minute periods for the next
48 hours. Each period has an estimate, a 10% band and a 90% band. The forecast has an error
that grows with the lead time, from a seed.

A hobbyist account can fetch 10 times a day, so the fetch hours of a day come from a count
of fetches. The forecast can show as Solcast JSON, with UTC times from the longitude. A
policy reads the forecast as the solar energy of each coming hour.

## Code map

- `StoragePolicySim/Forecast.lean`

## Interface

- `Period` · type · `StoragePolicySim/Forecast.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `endMinute : Nat` (the end of the period, in minutes from the start of the run), and `estimateKw`, `p10Kw` and `p90Kw`, each a `Float` (a mean power in kW)
  - errors: none
- `forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean`
  - in: a site, a seed, the days of the run, the error scale, and the hour of the run at which the fetch is made
  - out: the periods of the fetch, in order of time. The array is empty when the fetch hour is not inside the run.
  - errors: none
- `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period` · function · `StoragePolicySim/Forecast.lean` · proposed
  - in: the hours of `scenario site seed days`, built once by the caller, the same site and seed, the error scale, and the hour of the run at which the fetch is made
  - out: the same periods as `forecast site seed days errorScale fetchHour`, where `days` is the count of hours divided by 24
  - errors: none
- `fetchHours (fetchesPerDay : Nat) : Array Nat` · function · `StoragePolicySim/Forecast.lean`
  - in: the fetches of one day, from 1 to 10
  - out: the hour of the day of each fetch, in order
  - errors: none
- `latestFetch (fetchesPerDay hour : Nat) : Nat` · function · `StoragePolicySim/Forecast.lean`
  - in: the fetches of one day, from 1 to 10, and an hour of the run
  - out: the hour of the run of the latest fetch at or before that hour
  - errors: none
- `hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float` · function · `StoragePolicySim/Forecast.lean`
  - in: the periods of a fetch, and the hour of that fetch
  - out: 48 values in kWh. Value `j` is the forecast solar energy of hour `fetchHour + j` of the run.
  - errors: none
- `forecastJson (periods : Array Period) (longitude : Float) : String` · function · `StoragePolicySim/Forecast.lean`
  - in: the periods of a fetch, and a longitude in degrees, east is positive
  - out: the Solcast reply as one line of JSON text
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Forecast.lean`
  - in: the `seed` argument of `forecast`. The same seed gives the same forecast.
  - errors: none

## Requirements

### CAP-forecast.R1 · Forecast periods

Status: verified · Intents: IN-0002

A fetch at the start of hour `h` of a run gives the periods of the next 48 hours (assumed).
Period `k`, for `k` from 1 to 96, is 30 minutes long and ends `60 × h + 30 × k` minutes
after the start of the run. A period after the end of the run is not in the fetch (assumed).

Each period has its end in minutes from the start of the run, an estimate, a 10% band and a
90% band (assumed). Each value is a mean power in kW, as Solcast gives. The actual power of
a period is the solar energy of its hour, per hour.

In these lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is
365 days, and the error scale is 1, unless the line says otherwise.

- Given a fetch at hour 0, when the forecast is made, then it has 96 periods. Their ends are 30, 60, and up to 2880 minutes.
- Given a fetch at hour 100, when the forecast is made, then the first period ends at 6030 minutes and the last at 8880 minutes.
- Given a fetch at hour 8750, when the forecast is made, then it has 20 periods, because the run ends after 10 hours.
- Given a fetch at hour 8760, when the forecast is made, then it has no period.
- Given a daily fetch at 00:00, when the forecasts are made, then no 10% band is above its estimate. No estimate is above its 90% band.
- Given a daily fetch at 00:00, when the forecasts are made, then each value is from 0 to 5 kW.
- Given a fetch at hour 0, when the forecast is made, then each period with no actual power has 0 kW in all three values.

### CAP-forecast.R2 · Forecast error

Status: verified · Intents: IN-0002

The estimate is the actual power, times 1 plus the error scale times a spread times a random
number from a normal curve (assumed). The spread is 0.05 plus 0.10 for each 24 hours of lead
time (assumed). The lead time is from the fetch to the end of the period.

The 10% band is the estimate times 1 less 1.28 times the error scale times the spread. The
90% band uses 1 plus that amount (assumed). Each value stays from 0 to the panel power. The
seed of the run gives the random numbers, and the forecast does not change the weather. The
error of a set of periods is the mean of the absolute differences from the actual power
(assumed). A sunny period is a period with an actual power of more than 0 kW (assumed).

- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given seed 7, when the same fetch is made two times, then the two forecasts are the same.
- Given seeds 7 and 8, when a fetch at hour 4000 is made with each, then at least one estimate differs.
- Given daily fetches, when sunny periods are compared, then the error 24 to 48 hours ahead is more than 0 to 4 hours ahead.
- Given a daily fetch at 00:00, when the forecasts are made, then 60% to 95% of sunny periods have the actual power in the band.

### CAP-forecast.R3 · Fetch limit

Status: verified · Intents: IN-0002

A day has from 1 to 10 fetches, because a Solcast hobbyist account has 10 calls each day
(assumed). Fetch `i` of `n` is at hour `i × 24 / n` of each day, rounded down (assumed), for
`i` from 0 to `n - 1`. At each hour, a policy sees the forecast of the latest fetch at or
before that hour.

- Given 10 fetches a day, when the fetch hours are found, then they are 0, 2, 4, 7, 9, 12, 14, 16, 19 and 21.
- Given 3 fetches a day, when the fetch hours are found, then they are 0, 8 and 16.
- Given 1 fetch a day, when the fetch hours are found, then the only hour is 0.
- Given 10 fetches a day, when the latest fetch for hour 27 is found, then it is the fetch at hour 26.
- Given 10 fetches a day, when the latest fetch for hour 26 is found, then it is the fetch at hour 26. The latest fetch for hour 25 is at hour 24.
- Given 1 fetch a day, when the latest fetch for hour 47 is found, then it is the fetch at hour 24.

### CAP-forecast.R4 · Solcast JSON

Status: verified · Intents: IN-0002

A forecast shows as the JSON of the Solcast hobbyist rooftop forecast reply. The text is
`{"forecasts":[` and the periods, split by commas, then `]}`, with no spaces or line breaks
(assumed). Each period is `{"pv_estimate":<v>,"pv_estimate10":<v>,"pv_estimate90":<v>,"period_end":"<time>","period":"PT30M"}`.

Each value has four decimals (assumed). The run starts on 1 January 2025 at 00:00 solar
time (assumed). The UTC time is the solar time less the longitude divided by 15 hours,
rounded to the nearest 30 minutes, and a tie rounds up (assumed). The time has the form
`2025-01-01T00:30:00.0000000Z`.

- Given longitude 0 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T00:30:00.0000000Z`.
- Given longitude 174.8 and a fetch at hour 0, when the JSON is made, then the first period ends at `2024-12-31T13:00:00.0000000Z`.
- Given longitude -75 and a fetch at hour 0, when the JSON is made, then the first period ends at `2025-01-01T05:30:00.0000000Z`.
- Given longitude 0 and a fetch at hour 8759, when the JSON is made, then the last period ends at `2026-01-01T00:00:00.0000000Z`.
- Given an error scale of 0 and a fetch at hour 4116, when the JSON is made, then each `pv_estimate` has four decimals.
- Given a fetch at hour 0, when the JSON is made, then each period has the five fields in the order above, and `"period":"PT30M"`.

### CAP-forecast.R5 · Hourly forecast energy

Status: verified · Intents: IN-0002

A policy reads a fetch as the forecast solar energy of each coming hour. Value `j` is the
estimate of the first period of hour `fetchHour + j`, plus the estimate of the second, each
times 0.5 hours. The array always has 48 values. An hour with no period in the fetch has the
value 0 (assumed).

- Given an error scale of 0 and a fetch at hour 0, when the hourly energy is made, then value `j` equals the solar output of hour `j` of the scenario for `j` from 0 to 47. The tolerance is 0.000001 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then it has 48 values, each from 0 to 5 kWh.
- Given a fetch at hour 8750, when the hourly energy is made, then it has 48 values. Values 10 to 47 are 0 kWh.
- Given a fetch at hour 8760, when the hourly energy is made, then it has 48 values, each 0 kWh.
- Given a fetch at hour 4116, when the hourly energy is made, then the sum of the 48 values is 0.5 times the sum of the estimates of the 96 periods. The tolerance is 0.000001 kWh.

### CAP-forecast.R6 · Forecast from built hours

Status: ready · Intents: IN-0008

A caller that makes many fetches builds the hours of the scenario once. `forecastOf` gives the
same periods as `forecast`, from these hours, and does not build the scenario again. A set of
hours that is empty has no period in any fetch.

- Given the hours of `scenario` for seed 7 and 365 days at latitude 45 with 5 kW of panels, and an error scale of 1, when `forecastOf` runs for the fetch hours 0, 4116 and 8750, then each result has the same periods as `forecast` for the same arguments. Each period has the same end and the same three values.
- Given the same hours and an error scale of 0, when `forecastOf` runs for the fetch hour 4000, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given the same hours, when `forecastOf` runs for the fetch hour 8760, then it has no period.
- Given no hours, when `forecastOf` runs for the fetch hour 0, then it has no period.
- Given the same hours and seeds 7 and 8, when `forecastOf` runs for the fetch hour 4000 with the hours of each seed, then at least one estimate differs.

### CAP-forecast.R7 · Shared error of a day

Status: ready · Intents: IN-0008

A forecast that is wrong about one hour of a day is often wrong about the other hours of that
day, because one cloud front covers the whole day. Thus, the random number of R2 (forecast
error) of a period has two parts: `sqrt(0.7) × d + sqrt(0.3) × e`, where `d` is a number from
a normal curve for the day of the period, and `e` is a number from a normal curve for the
period itself in the fetch (assumed). The number `d` depends only on the seed and the day of
the run in which the period ends. Thus, two fetches of the same day share `d`. The sum of the
two parts is still a number from a normal curve, so that the bands of R2 keep their meaning.

The relative error of a sunny period is its estimate less its actual power, divided by the
actual power and by the spread. For a sunny period in a fetch with the error scale 1, it is
the random number of the period, except where the estimate is cut to the range of R2.

In these lines, the site is at latitude 45 with 5 kW of panels. The seed is 7, the run is
365 days, and the error scale is 1, unless the line says otherwise. A fetch at 00:00 is a
fetch at an hour that is a multiple of 24. The periods that end at 11:30 and 13:30 are those
whose end is 690 and 810 minutes into the day.

- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny periods that end at 11:30 and 13:30 of the same day are compared, then their correlation over the days that have both is from 0.55 to 0.85. Days where either estimate is cut to the range of R2 do not count.
- Given the fetches at 00:00 of the days 0 to 364, when the relative errors of the sunny period that ends at 11:30 of a day and of the next day are compared, each from the fetch at 00:00 of its own day, then their correlation is from -0.25 to 0.25.
- Given the fetches at hour 0 and at hour 10 of each day from 0 to 364, when the relative errors of the sunny period that ends at 13:30 of that day are compared, then at least 62% of the days have the same sign in both fetches. Days with a relative error of 0 in either fetch do not count.
- Given an error scale of 0, when a fetch at hour 0 is made, then each value of each period equals its actual power. The tolerance is 0.000001 kW.
- Given a fetch at 00:00 of each day, when the sunny periods are compared, then 60% to 95% of them have the actual power in the band.
````

### CAP-simulation

````
# CAP-simulation · Hourly energy flows and self-consumption results

Status: active

## What it is for

CAP-simulation (hourly energy flows) runs one strategy over a scenario, hour by hour, with
a battery. It gives the energy flows of each hour, the totals, and the totals of each
month. The totals include the self-consumption and the self-sufficiency, so that a caller
can compare strategies on the same weather.

A caller can also gate the battery by hour: charging and discharging are each allowed or
not allowed. A policy uses this gate to plan the battery with the hot-water tank.

## Code map

- `StoragePolicySim/Simulation.lean`

## Interface

- `Battery` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `capacityKwh` and `powerKw`, each a `Float`
  - errors: none
- `efficiency : Float` · constant · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: 0.95
  - errors: none
- `Flow` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `directKwh`, `chargeKwh`, `dischargeKwh`, `exportKwh`, `importKwh`, `lossKwh` and `socKwh`.
  - errors: none
- `stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean`
  - in: a battery, the energy that it holds, a strategy, the hour of the day, and the solar energy and the load of the hour
  - out: the flows of the hour. `socKwh` of the flow is the energy that the battery holds after the hour.
  - errors: none
- `HourResult` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hour : Hour`, `loadKwh : Float` and `flow : Flow`
  - errors: none
- `Totals` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh`, `selfUsedKwh`, `importKwh`, `exportKwh`, `lossKwh`, `finalSocKwh`, `selfConsumption` and `selfSufficiency`.
  - errors: none
- `Month` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `name : String`, `days : Nat` and `totals : Totals`
  - errors: none
- `Result` · type · `StoragePolicySim/Simulation.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HourResult`, `totals : Totals` and `months : Array Month`
  - errors: none
- `simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days : Nat) : Result` · function · `StoragePolicySim/Simulation.lean`
  - in: a site, a battery, a strategy, a seed, and the days of the run
  - out: the hours, the totals and the months of the run
  - errors: none
- `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow` · function · `StoragePolicySim/Simulation.lean` · proposed
  - in: a battery, the energy that it holds, whether it may charge, whether it may discharge, and the solar energy and the load of the hour
  - out: the flows of the hour, with the same rules as `stepHour`. The battery charges only when it may charge, and discharges only when it may discharge.
  - errors: none

### Test seams

- `seed` · seam: randomness · `StoragePolicySim/Simulation.lean`
  - in: the `seed` argument of `simulate`. The same seed gives the same weather.
  - errors: none

## Requirements

### CAP-simulation.R1 · Energy flows of an hour

Status: verified · Intents: IN-0001

The house first uses solar energy directly. Then the battery takes what the strategy asks,
up to the surplus, the battery power for one hour, and the free room. The rest goes to
the grid as export.

For a shortfall, the battery gives what the strategy asks, up to the shortfall, the battery
power for one hour, and the stored energy. The rest comes from the grid as import.

The battery keeps 95% of the energy that goes in, and gives 95% of the energy that comes
out (assumed). The battery is empty at the start (assumed). In these lines, the battery
holds 10 kWh with 5 kW of power, unless the line says otherwise.

- Given an empty battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given a full battery, when `greedy` meets 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export.
- Given 9.05 kWh stored, when `greedy` meets a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery with 2 kW of power, when `greedy` meets a surplus of 3 kWh, then 2 kWh charges and 1 kWh is export.
- Given 1.9 kWh stored, when `greedy` meets a shortfall of 2 kWh, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored, when `none` meets 3 kWh of solar and 1 kWh of load, then 2 kWh is export. The battery still holds 1.9 kWh.
- Given `greedy` and seed 7, when the simulation runs 365 days, then the first hour imports its full load.

### CAP-simulation.R2 · Battery limits

Status: verified · Intents: IN-0001

Over a run, the battery never goes past its power or its capacity. The energy of each run
balances, with the battery losses included. In these lines, the site is at latitude 45
with 5 kW of panels and 20 kWh of daily load, 3 kWh of it flexible. The seed is 7, unless
the line says otherwise.

- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then no hour charges or discharges over 2 kWh.
- Given a 5 kWh battery with 2 kW of power, when `greedy` runs 365 days, then the battery holds 0 to 5 kWh each hour.
- Given a 10 kWh battery, when `greedy` runs 365 days, then solar plus import equals load, export, losses and the stored energy. The tolerance is 0.01 kWh.
- Given a battery of 0 kWh, when `greedy` and `none` each run 365 days, then the two runs have the same totals.

### CAP-simulation.R3 · Totals and ratios

Status: verified · Intents: IN-0001

The totals add up the hours of the run. The self-consumption is the solar energy less the
export, as a percentage of the solar energy. The self-sufficiency is the load less the
import, as a percentage of the load. A ratio with nothing to divide by is 0% (assumed).

- Given latitude 45 and `none`, when the simulation runs 365 days, then each total equals the sum of its hours. The tolerance is 0.01 kWh.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-consumption is 100 × (solar - export) / solar.
- Given latitude 45 and `greedy`, when the simulation runs 365 days, then the self-sufficiency is 100 × (load - import) / load.
- Given 0 kW of panels, when `greedy` runs 365 days, then the self-consumption is 0% and the self-sufficiency is 0%.
- Given 0 days, when `greedy` runs, then each total is 0, each ratio is 0%, and there are no months.

### CAP-simulation.R4 · Monthly totals

Status: verified · Intents: IN-0001

The result has the totals of each calendar month in the run, in order. A year has 365
days, with no leap day (assumed). Each month also has its own two ratios.

- Given 365 days, when `greedy` runs, then the result has 12 months. Their days are 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 and 31.
- Given 365 days, when `greedy` runs, then the solar totals of the 12 months add up to the solar total of the run. The tolerance is 0.01 kWh.
- Given 400 days, when `greedy` runs, then the result has 14 months. The last month is February with 4 days.
- Given 10 days, when `greedy` runs, then the result has one month, January with 10 days.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then July has more than twice the solar energy of December.
- Given latitude 45 and seed 7, when `greedy` runs 365 days, then the July self-sufficiency is more than the January self-sufficiency.

### CAP-simulation.R5 · Strategy order

Status: verified · Intents: IN-0001

On the same weather, a battery must raise the self-consumption, and a later discharge must
not raise it. In these lines, the site is at latitude 45 with 5 kW of panels and 20 kWh of
daily load, 3 kWh of it flexible. The seed is 7, and each run is 365 days.

- Given a battery of 10 kWh with 5 kW of power, when `none` and `greedy` run, then `greedy` has the higher self-consumption.
- Given a battery of 10 kWh with 5 kW of power, when `evening` and `greedy` run, then `evening` has a self-consumption no higher than `greedy`.
- Given a battery of 0 kWh, when `none` and `shift` run, then `shift` has the higher self-consumption.

### CAP-simulation.R6 · Allowed battery use

Status: ready · Intents: IN-0008

`stepHourGated` runs an hour as `stepHour` does with the `greedy` strategy, but a battery
that may not charge keeps the surplus as export, and a battery that may not discharge leaves
the shortfall as import. The battery limits of R1 and R2 still hold. In these lines, the
battery holds 10 kWh with 5 kW of power, unless the line says otherwise. The tolerance is
0.000000001 kWh.

- Given an empty battery that may charge and discharge, when the hour has 3 kWh of solar and 1 kWh of load, then 1 kWh is direct and 2 kWh charges. The battery then holds 1.9 kWh.
- Given an empty battery that may not charge, when the hour has 3 kWh of solar and 1 kWh of load, then 0 kWh charges and 2 kWh is export. The battery still holds 0 kWh.
- Given 1.9 kWh stored and a battery that may discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 1.805 kWh and the import is 0.195 kWh.
- Given 1.9 kWh stored and a battery that may not discharge, when the hour has 0 kWh of solar and 2 kWh of load, then the battery gives 0 kWh and the import is 2.0 kWh. The battery still holds 1.9 kWh.
- Given 9.05 kWh stored and a battery that may charge, when the hour has a surplus of 2 kWh, then 1 kWh charges and 1 kWh is export. The battery then holds 10 kWh.
- Given a battery that may not charge and may not discharge, when an hour has a surplus of 2 kWh, then the export is 2 kWh. When the hour has a shortfall of 2 kWh, then the import is 2 kWh.
- Given a battery that may charge and discharge, when each of the 24 hours of day 100 of a run with latitude 45 and seed 7 runs with the battery energy of the hour before, then each flow equals the flow of `stepHour` with `greedy`. The tolerance is 0.000000001 kWh.
- Given a battery that may charge, and may discharge only from 17:00, when the same 24 hours run, then each flow equals the flow of `stepHour` with `evening`. The tolerance is 0.000000001 kWh.
````

### CAP-policy

````
# CAP-policy · Daily-profile policies for the hot-water tank and the battery

Status: active

## What it is for

CAP-policy (daily-profile policies) decides, for each hour, how much heating the hot-water
tank asks for, and whether the battery may charge and may discharge. It has three kinds of
policy. A static policy repeats one fixed profile each day. A precomputed policy makes a
day-ahead plan from the solar forecast. A dynamic policy decides each hour from the state of
the tank and the surplus of that hour.

## Code map

- `StoragePolicySim/Policy.lean`

## Interface

- `Action` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Observation` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `hour : Nat`, and `tankKwh`, `socKwh`, `surplusKwh` and `forecastRestKwh`, each a `Float`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `Policy.name (policy : Policy) : String` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a policy
  - out: `"static"`, `"precomputed"` or `"dynamic"`
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `planDay (cfg : TankConfig) (params : PlanParams) (forecastKwh : Array Float) (tankKwh expectedDrawKwh : Float) : Array Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a tank, the parameters of a precomputed policy, the forecast solar energy of the 24 hours of the day, the energy in the tank at the start of the day, and the hot water that the household is expected to draw in the day
  - out: 24 actions, one for each hour of the day
  - errors: none
- `dynamicAction (cfg : TankConfig) (params : DynamicParams) (obs : Observation) : Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a tank, the parameters of a dynamic policy, and what the policy sees in the hour
  - out: the action of the hour
  - errors: none

### Test seams

none

## Requirements

### CAP-policy.R1 · Static profile

Status: ready · Intents: IN-0008

A static policy repeats one profile each day. The tank asks for the element power in each hour
from `heatStart` for `heatHours` hours, and for nothing in the other hours. The window stops at
the end of the day (assumed). The battery may always charge. It may discharge from the hour
`dischargeFrom` to the end of the day, and a value of 24 never lets it discharge (assumed).

In these lines, the parameters are `defaultStatic`, unless the line says otherwise.

- Given the default parameters, when the profile is made, then it has 24 actions.
- Given the default parameters, when the profile is made, then hours 10, 11, 12 and 13 ask for 3.0 kWh. Hours 9 and 14 ask for 0 kWh.
- Given the default parameters, when the profile is made, then the battery may discharge in hours 17 and 23, and may not discharge in hours 0 and 16.
- Given the default parameters, when the profile is made, then the battery may charge in each hour.
- Given 0 heating hours, when the profile is made, then each hour asks for 0 kWh.
- Given a start of 22 and 2 heating hours, when the profile is made, then hours 22 and 23 ask for 3.0 kWh. Hour 21 asks for 0 kWh.
- Given a start of 23 and 5 heating hours, when the profile is made, then hour 23 asks for 3.0 kWh. Hour 0 asks for 0 kWh.
- Given an element of 1.5 kW, when the profile is made, then each heating hour asks for 1.5 kWh.
- Given discharge from 24, when the profile is made, then the battery may not discharge in any hour.

### CAP-policy.R2 · Day-ahead plan

Status: ready · Intents: IN-0008

A precomputed policy makes one plan at the start of the day. The need is the target less the
energy in the tank, plus the hot water that the household is expected to draw, and never
less than 0 (assumed). Only an hour with a forecast of at least `minSolarKwh` can heat.
The plan gives the element power to these hours, from the highest forecast to the lowest,
until the need is met. A tie goes to the earlier hour (assumed). If the hours cannot meet
the need, the rest of the need stays unplanned. The battery rules are those of R1, with
`dischargeFrom` of the plan.

In these lines, the tank is the default tank and the parameters are `defaultPlan` with a target
of 9.0 kWh, unless the line says otherwise.

- Given a forecast of 1.0, 2.0, 3.5, 3.0, 4.0 and 1.5 kWh in hours 9 to 14 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hours 10, 11, 12 and 13 ask for 2.0, 3.0, 3.0 and 3.0 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 9.0 kWh in the tank and an expected draw of 0.5 kWh, when the day is planned, then hour 13 asks for 0.5 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 10.0 kWh in the tank and an expected draw of 0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.4 kWh in each hour, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.5 kWh in hour 12 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hour 12 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a minimum forecast of 0.0 kWh, a forecast of 0 kWh in each hour, 9.0 kWh in the tank and an expected draw of 3.0 kWh, when the day is planned, then hour 0 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a forecast of 2.0 kWh in hours 10 to 14, 9.0 kWh in the tank and an expected draw of 4.0 kWh, when the day is planned, then hour 10 asks for 3.0 kWh and hour 11 asks for 1.0 kWh.
- Given the default parameters, when a day is planned, then the battery may charge in each hour, may discharge in hour 17, and may not discharge in hour 16.

### CAP-policy.R3 · Dynamic action

Status: ready · Intents: IN-0008

A dynamic policy decides each hour from what it sees. First it soaks up surplus: when the
hour has a solar surplus and the tank holds less than the target, the tank asks for the
smallest of the element power, the surplus and the room to the target. If not, and the tank
holds less than the low level, and the forecast for the rest of the day is less than the
lack, the tank asks for the smaller of the element power and the lack. The lack is the low
level less the energy in the tank. In every other case the tank asks for 0 kWh. The battery rules are those of R1, with
`dischargeFrom` of the policy. The surplus is 0 or more (assumed).

In these lines, the tank is the default tank and the parameters are `defaultDynamic` with a low
level of 4.0 kWh and a target of 9.0 kWh, unless the line says otherwise.

- Given a surplus of 2.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 2.0 kWh.
- Given a surplus of 5.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 5.0 kWh and 8.0 kWh in the tank, when the hour is decided, then the tank asks for 1.0 kWh.
- Given a surplus of 5.0 kWh and 9.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh. With 9.5 kWh in the tank, the tank asks for 0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh for the rest of the day, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus, 0.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 1.0 kWh, 3.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given hour 16, when the hour is decided, then the battery may charge and may not discharge. Given hour 17, the battery may charge and may discharge.

### CAP-policy.R4 · Defaults and names

Status: ready · Intents: IN-0008

The defaults give a sensible start for a home with the default tank (assumed). The target is a
full tank, because the tank must be full once a day for the legionella guard, and the sun is
cheaper than the grid for that heating (assumed). A policy has a name that a command can print.

- Given `defaultStatic`, when it is read, then the heating starts at 10, lasts 4 hours, discharge starts at 17, and the element is 3.0 kW.
- Given `defaultPlan`, when it is read, then the target is 10.5 kWh, the minimum forecast is 0.5 kWh, and discharge starts at 17.
- Given `defaultDynamic`, when it is read, then the low level is 5.25 kWh, the target is 10.5 kWh, and discharge starts at 17.
- Given a static, a precomputed and a dynamic policy, when the names are read, then they are `static`, `precomputed` and `dynamic`.
````

### CAP-homesim

````
# CAP-homesim · Home simulation, robust evaluation and tuning of policies

Status: active

## What it is for

CAP-homesim (home simulation) runs one policy over a home for a number of days, hour by hour.
The home has solar panels, a battery, a hot-water tank and a household load. The policy sets
the heating of the tank and the battery gate for each hour. The result shows how much of the
sun the home used itself, how much it exported, and whether the tank ever ran cold.

A caller can also evaluate a policy over many weather seeds, so that the result is robust and
not one lucky year. A caller can search for the best static profile.

## Code map

- `StoragePolicySim/HomeSim.lean`

## Interface

- `HomeSetup` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `site : Site`, `battery : Battery`, `tank : TankConfig`, `drawKwhPerDay : Float` (the hot water that the household draws in a day), `drawCv : Float` (the spread of that draw from day to day), `fetchesPerDay : Nat` and `errorScale : Float` (both for the forecast).
  - errors: none
- `defaultHome : HomeSetup` · constant · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: latitude -41.3, 5 kW of panels, 20 kWh of daily load with 3 kWh flexible, a battery of 10 kWh with 5 kW, `defaultTank`, 6.0 kWh of hot water each day with a spread of 0.25, 10 fetches each day, and an error scale of 1.0
  - errors: none
- `HomeHour` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `day` and `hour` (each a `Nat`), `pvKwh`, `houseLoadKwh` (the base load and the flexible load), `drawKwh`, `askKwh` (the heating that the policy asked for), `heatKwh`, `backstopKwh`, `unmetKwh` and `tankKwh` (the energy in the tank after the hour), each a `Float`, `allowCharge` and `allowDischarge`, each a `Bool`, and `flow : Flow`.
  - errors: none
- `HomeTotals` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `pvKwh`, `loadKwh` (the house load, the heating and the backstop heating), `importKwh`, `exportKwh`, `batteryLossKwh`, `tankLossKwh`, `heatKwh`, `backstopKwh`, `drawKwh`, `unmetKwh`, `minTankKwh`, `finalTankKwh`, `selfConsumption` and `selfSufficiency`. The field `coldHours` is a `Nat`.
  - errors: none
- `HomeResult` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`, and the fields `hours : Array HomeHour` and `totals : HomeTotals`
  - errors: none
- `runHome (setup : HomeSetup) (policy : Policy) (seed days : Nat) : HomeResult` · function · `StoragePolicySim/HomeSim.lean` · proposed
  - in: a home, a policy, a seed, and the days of the run
  - out: the hours and the totals of the run
  - errors: none
- `Evaluation` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `meanSelfConsumption`, `worstSelfConsumption`, `meanSelfSufficiency`, `meanImportKwh`, `meanExportKwh`, `meanBackstopKwh` and `totalUnmetKwh` are each a `Float`. The fields `seeds`, `unmetSeeds` and `coldHours` are each a `Nat`.
  - errors: none
- `evaluate (setup : HomeSetup) (policy : Policy) (seed seeds days : Nat) : Evaluation` · function · `StoragePolicySim/HomeSim.lean` · proposed
  - in: a home, a policy, the first seed, the count of seeds, and the days of each run
  - out: the evaluation over the seeds `seed` to `seed + seeds - 1`
  - errors: none
- `TuneResult` · type · `StoragePolicySim/HomeSim.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `best : StaticParams`, `evaluation : Evaluation`, `candidates : Nat` and `safe : Nat`.
  - errors: none
- `tuneStatic (setup : HomeSetup) (seed seeds days : Nat) : TuneResult` · function · `StoragePolicySim/HomeSim.lean` · proposed
  - in: a home, the first seed, the count of seeds, and the days of each run
  - out: the best static profile that the search finds, its evaluation, the count of candidates, and the count of safe candidates
  - errors: none

### Test seams

- `homeSeed` · seam: randomness · `StoragePolicySim/HomeSim.lean` · proposed
  - in: the `seed` argument of `runHome`, `evaluate` and `tuneStatic`. The same seed gives the same weather and the same forecast.
  - errors: none

## Requirements

### CAP-homesim.R1 · Hourly home flows

Status: ready · Intents: IN-0008

The run starts with a full tank (`startState`) and an empty battery (assumed). In each hour,
the policy gives an action. The tank takes the draw, the heating and the backstop by
CAP-hotwater (hot-water tank), with the hour of the day. The heating and the backstop heating
join the house load. The battery then runs the hour with its gate, by `stepHourGated`. The
draw of an hour is the `drawKwh` of the home for its day and hour, times the `drawFactor` of
the seed, the day and the spread `drawCv`.

A static policy uses its profile of the hour. A precomputed policy makes its plan at hour 0
of each day, from the forecast of the fetch at hour 0, the energy in the tank, and the draw
that the day is expected to have, which is the sum of the `drawKwh` of its 24 hours, without
the factor of the day (assumed). A dynamic policy sees the tank, the battery, the
surplus of the hour (the solar energy less the house load, and never less than 0), and the
forecast for the rest of the day from the latest fetch. The forecast is made only for a policy that reads it (assumed). It uses the seed of the run.

In these lines, the home is `defaultHome`, the policy is the static policy with
`defaultStatic`, the seed is 7, and the run is 365 days, unless the line says otherwise. The
tolerance is 0.000000001 kWh.

- Given the default run, when it ends, then it has 8760 hours, in order of day, then hour.
- Given the default run, when each hour is read, then its solar energy and its house load are those of the scenario hour for the same site, seed and days.
- Given the default run, when each hour is read, then `askKwh` is the heating of its hour in the static profile, and the battery gate is the gate of that hour.
- Given the default run, when each hour is read, then its tank energy is the `tankStep` result for the tank state of the hour before, its hour of the day, its request and its draw. The first hour starts with `startState` of the tank.
- Given the default run, when each hour is read, then its flow is the `stepHourGated` flow for the battery energy of the hour before, its gate, its solar energy, and its house load plus its heating plus its backstop heating. The first hour starts with 0 kWh.
- Given the default run, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour, times the `drawFactor` for seed 7, its day and the spread 0.25.
- Given the default run with a spread of 0, when each hour is read, then its draw is the `drawKwh` of the home for its day and hour.
- Given the precomputed policy with `defaultPlan`, 1 fetch each day and seed 7, when each hour of day `d` is read, then its `askKwh` is the `heatKwh` of that hour in `planDay`. The call uses the first 24 values of `hourlyEnergy` of the fetch at hour `24 × d`, the tank energy after hour 23 of day `d - 1` (10.5 kWh for day 0), and the sum of `drawKwh` for the 24 hours of day `d`, without the factor of the day.
- Given 0 days, when the run ends, then it has no hours.

### CAP-homesim.R2 · No cold tank

Status: ready · Intents: IN-0008

The thermostat of the tank keeps the hot water ready for every policy. Thus, no hour has an
unmet draw, the tank never ends an hour below its floor, and the tank is full at least once
each day (assumed). The backstop heating is the price of a policy that lets the tank fall.
The days are different, because the draw changes from day to day. Thus, the lines hold also
with the spread of 0.25 of the default home, and with a spread of 0.5.

In these lines, the home is `defaultHome`, the run is 365 days, and the tolerance is 0.000000001
kWh. A policy is the static policy with `defaultStatic`, the precomputed policy with `defaultPlan`,
or the dynamic policy with `defaultDynamic`.

- Given each policy and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour.
- Given each policy and the seeds 1 to 5, when the run ends, then the tank holds at least 2.1 kWh after each hour, and `coldHours` is 0.
- Given each policy and the seeds 1 to 5, when the run ends, then each day has an hour after which the tank is full, within 0.000000001 kWh.
- Given each policy, a spread of 0.5 and the seeds 1 to 5, when the run ends, then the unmet draw is 0 kWh in each hour and `coldHours` is 0.
- Given a static policy with 0 heating hours and seed 7, when the run ends, then the backstop heating is more than 500 kWh and the unmet draw is 0 kWh.
- Given a home with an element of 0.2 kW, and the static policy with 0 heating hours, when the run ends, then the unmet draw is more than 0 kWh and `coldHours` is more than 0.

### CAP-homesim.R3 · Totals and ratios

Status: ready · Intents: IN-0008

The totals add up the hours. The self-consumption is the solar energy less the export, as a
percentage of the solar energy. The self-sufficiency is the load less the import, as a
percentage of the load. A ratio with nothing to divide by is 0% (assumed). The solar energy and
the energy of the tank and the battery balance.

In these lines, the home is `defaultHome`, the policy is the static policy with
`defaultStatic`, and the seed is 7, unless the line says otherwise. The tolerance is 0.01 kWh.

- Given 365 days, when the run ends, then each total equals the sum of its hours.
- Given 365 days, when the run ends, then solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end.
- Given 365 days, when the run ends, then the energy in the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy.
- Given 365 days, when the run ends, then `unmetKwh` plus the served draw equals `drawKwh`. The draw is the sum of the hours.
- Given 365 days, when the run ends, then the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load.
- Given 365 days and a spread of 0, when the run ends, then the draw total is 2190.0 kWh, within 0.1 kWh.
- Given 365 days, a spread of 0.25 and each seed from 1 to 5, when the run ends, then the draw total is from 2060 to 2320 kWh.
- Given 0 kW of panels and 365 days, when the run ends, then the self-consumption is 0%.
- Given 0 days, when the run ends, then each total is 0 and each ratio is 0%. The exceptions are `minTankKwh` and `finalTankKwh`, which are 10.5 kWh, the energy of the full tank at the start.

### CAP-homesim.R4 · Policies at work

Status: ready · Intents: IN-0008

Each kind of policy acts as CAP-policy (daily-profile policies) says. A static policy heats
only in its window. A precomputed policy heats only in hours that its forecast calls sunny. A
dynamic policy heats only when it has a surplus or the tank is low. Heating the tank in the sun
makes the home use more of its sun.

In these lines, the home is `defaultHome` and the run is 365 days, unless the line says
otherwise. The tolerance of a solar energy against 0.5 kWh is 0.000001 kWh.

- Given the static policy with `defaultStatic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours 10, 11, 12 and 13.
- Given the precomputed policy with `defaultPlan`, an error scale of 0, 1 fetch each day and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in hours whose solar energy is at least 0.5 kWh.
- Given the dynamic policy with `defaultDynamic` and seed 7, when each hour is read, then `askKwh` is more than 0 kWh only in an hour whose solar energy is more than its house load, or whose tank held less than 5.25 kWh before the hour.
- Given the static policy with `defaultStatic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the first has a higher self-consumption.
- Given the dynamic policy with `defaultDynamic` and the static policy with 0 heating hours, both with seed 7, when the runs end, then the dynamic policy has a higher self-consumption.
- Given the same policy and seed twice, when the runs end, then the two runs have the same hours.

### CAP-homesim.R5 · Robust evaluation

Status: ready · Intents: IN-0008

An evaluation runs the policy for each seed from the first seed, and sums up the runs. The
mean values are the averages of the runs. The worst self-consumption is the lowest of the runs.
`unmetSeeds` counts the runs with an unmet draw. A count of 0 seeds gives 0 in every field
(assumed).

In these lines, the home is `defaultHome`, the policy is the static policy with `defaultStatic`,
and each run is 365 days, unless the line says otherwise. The tolerance is 0.000000001.

- Given the first seed 3 and 1 seed, when the policy is evaluated, then the mean and the worst self-consumption are the self-consumption of the run with seed 3.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean self-consumption is the average of the runs with seeds 3, 4, 5 and 6, and the worst is the lowest of them.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the worst self-consumption is not more than the mean.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then the mean import, export and backstop heating are the averages of the runs, and the total unmet draw is their sum.
- Given the first seed 3 and 4 seeds, when the policy is evaluated, then `seeds` is 4, and `unmetSeeds` and `coldHours` are 0.
- Given 0 seeds, when the policy is evaluated, then each field is 0.
- Given the same arguments twice, when the policy is evaluated, then the two evaluations are the same.

### CAP-homesim.R6 · Tuning a static profile

Status: ready · Intents: IN-0008

The tuner tries each static profile of a fixed grid, with the element power of the home
tank: a start from 6 to 16, from 1 to 8 heating hours, and discharge from 15 to 22. That is 704
candidates. It evaluates each candidate. A candidate is safe when no seed has an unmet draw.
The best candidate is the safe candidate with the highest mean self-consumption. A safe
candidate within 0.05 points of the highest has the same standing, and then the lowest mean
import wins. A tie goes to the first candidate, in the order of the start, the heating hours
and the discharge hour (assumed). If no candidate is safe, the best is the candidate with the
lowest total unmet draw (assumed).

In these lines, the home is `defaultHome`. The tolerance is 0.000000001.

- Given 2 seeds from seed 1 and 30 days, when the profile is tuned, then `candidates` is 704, and `safe` is 704.
- Given the same arguments, when the profile is tuned, then the best start is from 6 to 16, its heating hours are from 1 to 8, and its discharge hour is from 15 to 22.
- Given the same arguments, when the profile is tuned, then the evaluation is the evaluation of the best static profile over the same seeds and days.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate has a mean self-consumption more than 0.05 points above the best.
- Given the same arguments, when each of the 704 candidates is evaluated, then no safe candidate within 0.05 points of the highest has a lower mean import than the best.
- Given the same arguments twice, when the profile is tuned, then the two results are the same.
- Given a home with 0 kW of panels, 2 seeds from seed 1 and 30 days, when the profile is tuned, then `safe` is 704 and the best mean self-consumption is 0%.
````

## The acceptance checks

### tests/acceptance/IN-0008.acceptance.lean

````
/-
Acceptance checks of IN-0008 (hot-water policy simulation).

Stored-data lines: none. No requirement of this intent reads or writes stored data.

The capability lines (CAP-forecast, CAP-hotwater, CAP-simulation, CAP-policy, CAP-homesim) use
the public functions of the library. The JOB-simulate lines run the `sim` command as a process
(arguments, stdout, stderr and the exit code). The checks of the library fail until the last
change of the intent is built. That is correct.

JOB-simulate.R5: this intent changes only the usage line. Thus this file proves the three
lines about the usage (`sim`, `sim help` and `sim --help`). The other lines of R5 did not
change, and tests/acceptance/IN-0001.acceptance.lean still proves them.

Shared runs. A run of the library or of `sim` can take long, so one run serves several checks:
- A library run is a value at the top level of this file. The first check that reads it
  makes the run. The next checks read the same value.
- A `sim` run goes through a small cache in `main`. The first check that runs an argument
  list makes the run. The next checks read the same output.

Cost. The checks of CAP-homesim run the home simulation for 365 days over many seeds, and
the lines of CAP-homesim.R6 evaluate each of the 704 candidates of the tuner. The interpreter
runs these checks. Thus this file needs minutes to run, not seconds. A line that does not
need a full year adds `--days 3`, `--days 10`, `--days 30` or `--days 1` to its command.

Statistics of CAP-forecast.R7. The relative error of a sunny period is its estimate less its
actual power, over the actual power. R7 divides it also by the spread. The spread depends only
on the lead time of the period. Each series that a line compares has one lead time (for
example, the period that ends at 11:30 in the fetches at 00:00). Thus the spread is one
constant for the series. A correlation does not change when a series is scaled by a constant,
and the sign does not change either. So the helper `relErr` leaves out the spread. It then
needs no rule for the spread (a step or a slope).
A sunny period is a period with an actual power of more than 0 kW, as CAP-forecast.R2 says.
An estimate is cut when it is 0 kW or it is the panel power (5 kW).

Terms of the checks:
- The actual power of a period that ends at minute `e` is the solar energy of hour
  `(e - 30) / 60` in the scenario with the same site, seed and days.
- The home of the lines of CAP-homesim is `defaultHome`. A policy is the static policy
  with `defaultStatic`, the precomputed policy with `defaultPlan` or the dynamic policy with
  `defaultDynamic`, unless the line says otherwise.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
import StoragePolicySim.Forecast
import StoragePolicySim.HotWater
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- Rounds to one decimal, half away from zero. -/
def round1 (x : Float) : Float :=
  if x < 0.0 then -(Float.round (-x * 10.0)) / 10.0 else Float.round (x * 10.0) / 10.0

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

def sumF (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0

def meanF (xs : List Float) : Float :=
  if xs.isEmpty then 0.0 else sumF xs / xs.length.toFloat

def minF (xs : List Float) : Float :=
  xs.foldl (fun acc x => if x < acc then x else acc) (xs.headD 0.0)

/-- The standard deviation of a list. The divisor is the count. -/
def stdF (xs : List Float) : Float :=
  let m := meanF xs
  Float.sqrt (meanF (xs.map (fun x => (x - m) * (x - m))))

/-- The correlation of two lists of the same length. It is 0 when a list has no spread. -/
def corrF (xs ys : List Float) : Float :=
  let mx := meanF xs
  let mv := meanF ys
  let cov := meanF ((xs.zip ys).map (fun (p : Float × Float) => (p.1 - mx) * (p.2 - mv)))
  let vx := meanF (xs.map (fun x => (x - mx) * (x - mx)))
  let vy := meanF (ys.map (fun y => (y - mv) * (y - mv)))
  if vx > 0.0 && vy > 0.0 then cov / Float.sqrt (vx * vy) else 0.0

def digitsVal (cs : List Char) : Nat :=
  cs.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads a printed number: an optional minus, digits, and an optional point with digits. -/
def parseNum (s : String) : Option Float :=
  let p : Bool × List Char := match s.toList with
    | '-' :: r => (true, r)
    | r => (false, r)
  let cs := p.2
  let ip := cs.takeWhile Char.isDigit
  let rest := cs.dropWhile Char.isDigit
  let q : List Char × List Char := match rest with
    | '.' :: r => (r.takeWhile Char.isDigit, r.dropWhile Char.isDigit)
    | r => ([], r)
  if ip.isEmpty || !q.2.isEmpty then none
  else
    let v := Float.ofNat (digitsVal ip) + Float.ofScientific (digitsVal q.1) true q.1.length
    some (if p.1 then -v else v)

/-- Compares named values with a tolerance. Gives the first value that is wrong. -/
def valsIs (tol : Float) (pairs : List (String × Float × Float)) : Option String :=
  match pairs.find? (fun (_, got, want) => !near got want tol) with
  | some (n, got, want) => some s!"{n} is {got}, want {want}"
  | none => none

-- Helpers for CAP-forecast

def site45 : Site :=
  { latitude := 45.0, pvKw := 5.0, dailyLoadKwh := 20.0, flexKwh := 3.0 }

/-- The hours of seed 7 and 365 days, built once. -/
def scen7 : Array Hour := scenario site45 7 365

/-- The hours of seed 8 and 365 days, for the lines that compare two seeds. -/
def scen8 : Array Hour := scenario site45 8 365

/-- A forecast of the lines: site 45, seed 7, 365 days, from the built hours. -/
def fo (scale : Float) (fetch : Nat) : Array Period :=
  forecastOf scen7 site45 7 scale fetch

/-- The hour of the run of a period that ends at minute `e`. -/
def accHourOf (e : Nat) : Nat := (e - 30) / 60

/-- The actual power of a period in kW: the solar energy of its hour, per hour. -/
def accActualKw (e : Nat) : Float := scen7[accHourOf e]!.pvKwh

def samePeriod (a b : Period) : Bool :=
  a.endMinute == b.endMinute && a.estimateKw == b.estimateKw && a.p10Kw == b.p10Kw &&
  a.p90Kw == b.p90Kw

def samePeriods (a b : Array Period) : Bool :=
  a.size == b.size && (List.zip a.toList b.toList).all (fun (x, y) => samePeriod x y)

def sumEst (ps : Array Period) : Float := sumF (ps.toList.map (fun p => p.estimateKw))

/-- Each value of each period must equal its actual power. -/
def badEqual (ps : Array Period) : Option String :=
  ps.toList.findSome? (fun p =>
    let a := accActualKw p.endMinute
    if near p.estimateKw a 1e-6 && near p.p10Kw a 1e-6 && near p.p90Kw a 1e-6 then none
    else some s!"end {p.endMinute}: actual {a}, estimate {p.estimateKw}, 10% {p.p10Kw}, 90% {p.p90Kw}")

/-- `forecastOf` and `forecast` must give the same periods for a fetch hour. -/
def sameAsForecast (f : Nat) : Option String :=
  let a := forecastOf scen7 site45 7 1.0 f
  let b := forecast site45 7 365 1.0 f
  if a.size > 0 && samePeriods a b then none
  else some s!"fetch {f}: forecastOf gives {a.size} periods and forecast gives {b.size}, or a value differs"

/-- The period of a fetch that ends at minute `e` of the run. -/
def periodEnding (ps : Array Period) (e : Nat) : Option Period :=
  ps.toList.find? (fun p => p.endMinute == e)

/-- The relative error of a period: its estimate less its actual power, over the actual power.
The spread is left out. See the comment at the top of the file. -/
def relErr (p : Period) : Float :=
  (p.estimateKw - accActualKw p.endMinute) / accActualKw p.endMinute

/-- An estimate is cut at 0 kW or at the panel power of 5 kW. -/
def isCut (p : Period) : Bool := p.estimateKw ≤ 1e-9 || p.estimateKw ≥ 5.0 - 1e-9

/-- A sunny period with an estimate that is not cut. -/
def okSunny (p : Period) : Bool := accActualKw p.endMinute > 0.0 && !isCut p

def inBand (p : Period) : Bool :=
  let a := accActualKw p.endMinute
  p.p10Kw - 1e-9 ≤ a && a ≤ p.p90Kw + 1e-9

/-- The fetches at 00:00 of the days 0 to 364, each with the hour of its fetch. -/
def dayFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d, fo 1.0 (24 * d)))

/-- The fetches at hour 10 of the days 0 to 364. -/
def tenFetches : List (Nat × Array Period) :=
  (List.range 365).map (fun d => (24 * d + 10, fo 1.0 (24 * d + 10)))

/-- The relative errors of the periods that end at 11:30 and at 13:30 of the same day, for
each day that has both, sunny and not cut. The fetch is at 00:00 of the day. -/
def pairsSameDay : List (Float × Float) :=
  dayFetches.filterMap (fun (f, ps) =>
    match periodEnding ps (60 * f + 690), periodEnding ps (60 * f + 810) with
    | some a, some b => if okSunny a && okSunny b then some (relErr a, relErr b) else none
    | _, _ => none)

/-- The relative error of the sunny period that ends at 11:30 of the day of a fetch at 00:00,
shifted by `shift` minutes. A day has none when its period is not in the fetch or it is not
sunny. -/
def err1130 (shift : Nat) : List (Option Float) :=
  dayFetches.map (fun (f, ps) =>
    match periodEnding ps (60 * f + 690 + shift) with
    | some p => if accActualKw p.endMinute > 0.0 then some (relErr p) else none
    | none => none)

def bothSome (a b : List (Option Float)) : List (Float × Float) :=
  (a.zip b).filterMap (fun (x, y) =>
    match x, y with
    | some u, some v => some (u, v)
    | _, _ => none)

/-- The periods that end at 11:30 of a day and of the next day. Each one comes from the fetch
at 00:00 of its own day. -/
def pairsNextFetch : List (Float × Float) :=
  bothSome (err1130 0) ((err1130 0).tail)

/-- The periods that end at 11:30 of a day and of the next day. Both come from the fetch at
00:00 of the first day. -/
def pairsNextSameFetch : List (Float × Float) :=
  bothSome (err1130 0) (err1130 1440)

/-- The relative errors of the period that ends at 13:30 of a day, from the fetch at 00:00 and
from the fetch at hour 10. Only a sunny period counts. -/
def signPairs : List (Float × Float) :=
  (dayFetches.zip tenFetches).filterMap (fun (a, b) =>
    match periodEnding a.2 (60 * a.1 + 810), periodEnding b.2 (60 * a.1 + 810) with
    | some p, some q =>
      if accActualKw p.endMinute > 0.0 then some (relErr p, relErr q) else none
    | _, _ => none)

/-- The sunny periods of the fetches at 00:00 of each day. -/
def sunnyAll : List Period :=
  dayFetches.foldl (fun acc (_, ps) =>
    acc ++ ps.toList.filter (fun p => accActualKw p.endMinute > 0.0)) []

-- Helpers for CAP-hotwater

/-- The default tank with a cut-in of 0 kWh, so that the thermostat stays out of a line. -/
def flatTank : TankConfig := { defaultTank with cutInKwh := 0.0 }

/-- A state with the thermostat off and with the tank full today. -/
def stOff (e : Float) : TankState := { energyKwh := e, heating := false, fullToday := true }

/-- A state with the thermostat on and with the tank full today. -/
def stOn (e : Float) : TankState := { energyKwh := e, heating := true, fullToday := true }

/-- A state with the thermostat off and with the tank not full today. -/
def stOpen (e : Float) : TankState := { energyKwh := e, heating := false, fullToday := false }

/-- The draw of one day, from the 24 hours. -/
def accDayDraw (daily lat : Float) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc h => acc + drawKwh daily lat d h) 0.0

/-- The draw of the days 0 to 364. -/
def accYearDraw (daily lat : Float) : Float :=
  (List.range 365).foldl (fun acc d => acc + accDayDraw daily lat d) 0.0

/-- The factors of the days 0 to `n - 1`. -/
def accFactors (seed : Nat) (cv : Float) (n : Nat) : List Float :=
  (List.range n).map (fun d => drawFactor seed d cv)

/-- The thermostat of the state after the hour must be on or off. -/
def thermoIs (s : TankStep) (want : Bool) : Option String :=
  if s.state.heating == want then none
  else some s!"the thermostat is {s.state.heating}, want {want}"

/-- `fullToday` of the state after the hour must be true or false. -/
def fullIs (s : TankStep) (want : Bool) : Option String :=
  if s.state.fullToday == want then none
  else some s!"fullToday is {s.state.fullToday}, want {want}"

-- Helpers for CAP-simulation.R6

def b105 : Battery := { capacityKwh := 10.0, powerKw := 5.0 }

/-- The solar energy and the load of the 24 hours of day 100: latitude 45, seed 7. -/
def dayLoads : Array (Float × Float) :=
  ((List.range 24).map (fun h =>
    let s := scen7[100 * 24 + h]!
    (s.pvKwh, s.baseLoadKwh + s.flexKwh))).toArray

def flowSame (a b : Flow) (tol : Float) : Bool :=
  near a.directKwh b.directKwh tol && near a.chargeKwh b.chargeKwh tol &&
  near a.dischargeKwh b.dischargeKwh tol && near a.exportKwh b.exportKwh tol &&
  near a.importKwh b.importKwh tol && near a.lossKwh b.lossKwh tol &&
  near a.socKwh b.socKwh tol

/-- Runs the 24 hours of day 100 with the battery energy of the hour before. The battery may
charge in each hour, and it may discharge from hour `from`. Each flow must equal the flow of
`stepHour` with `strat`. Gives the first hour that differs. -/
def gatedVersus (strat : Strategy) (dischargeFrom : Nat) (soc0 : Float) : Option String :=
  let step := fun (acc : Float × Option String) (h : Nat) =>
    let p := dayLoads[h]!
    let g := stepHourGated b105 acc.1 true (decide (h ≥ dischargeFrom)) p.1 p.2
    let s := stepHour b105 acc.1 strat h p.1 p.2
    let bad := if acc.2.isNone && !flowSame g s 1e-9 then
        some s!"hour {h}: gated {repr g}, stepHour {repr s}"
      else acc.2
    (g.socKwh, bad)
  ((List.range 24).foldl step (soc0, (none : Option String))).2

-- Helpers for CAP-policy

/-- A forecast of 24 hours: the listed hours have their value, the other hours have `other`. -/
def accFcOf (pairs : List (Nat × Float)) (other : Float := 0.0) : Array Float :=
  ((List.range 24).map (fun h =>
    ((pairs.find? (fun (k, _) => k == h)).map Prod.snd).getD other)).toArray

/-- The forecast of the lines of the day-ahead plan: hours 9 to 14. -/
def sunDay : Array Float :=
  accFcOf [(9, 1.0), (10, 2.0), (11, 3.5), (12, 3.0), (13, 4.0), (14, 1.5)]

/-- The parameters of the plan of the lines: a target of 9.0 kWh. -/
def plan9 : PlanParams := { defaultPlan with targetKwh := 9.0 }

/-- The plan must ask for the listed values in the listed hours, and for 0 kWh elsewhere. -/
def planAsks (acts : Array Action) (want : List (Nat × Float)) : Option String :=
  if acts.size != 24 then some s!"{acts.size} actions, want 24"
  else
    (List.range 24).findSome? (fun h =>
      let w := ((want.find? (fun (k, _) => k == h)).map Prod.snd).getD 0.0
      if near acts[h]!.heatKwh w 1e-9 then none
      else some s!"hour {h} asks for {acts[h]!.heatKwh} kWh, want {w}")

/-- What a dynamic policy sees. The battery energy does not matter for a line. -/
def accObs (hour : Nat) (tank surplus rest : Float) : Observation :=
  { hour := hour, tankKwh := tank, socKwh := 0.0, surplusKwh := surplus, forecastRestKwh := rest }

/-- The parameters of the lines of the dynamic action: a low level of 4.0 kWh and a target of
9.0 kWh. -/
def dyn49 : DynamicParams := { defaultDynamic with lowKwh := 4.0, targetKwh := 9.0 }

def asksDyn (o : Observation) (want : Float) : Option String :=
  let a := dynamicAction defaultTank dyn49 o
  if near a.heatKwh want 1e-9 then none
  else some s!"the tank asks for {a.heatKwh} kWh, want {want}"

-- Helpers for CAP-homesim

def pStatic : Policy := Policy.static defaultStatic
def pThermo : Policy := Policy.static { defaultStatic with heatHours := 0 }
def pPlan : Policy := Policy.precomputed defaultPlan
def pDyn : Policy := Policy.dynamic defaultDynamic

def homeCv (cv : Float) : HomeSetup := { defaultHome with drawCv := cv }
def homeLat45 : HomeSetup :=
  { defaultHome with site := { defaultHome.site with latitude := 45.0 } }
def homePv0 : HomeSetup :=
  { defaultHome with site := { defaultHome.site with pvKw := 0.0 } }
def homeElem02 : HomeSetup :=
  { defaultHome with tank := { defaultHome.tank with elementKw := 0.2 } }
def homeF1 : HomeSetup := { defaultHome with fetchesPerDay := 1 }
def homeE0F1 : HomeSetup := { defaultHome with errorScale := 0.0, fetchesPerDay := 1 }

/-- The hours of the scenario of the default home, seed 7 and 365 days. -/
def scenHome7 : Array Hour := scenario defaultHome.site 7 365

/-- The default run: the default home, the static policy, seed 7 and 365 days. -/
def runS7 : HomeResult := runHome defaultHome pStatic 7 365
def runS7cv0 : HomeResult := runHome (homeCv 0.0) pStatic 7 365
def runT7 : HomeResult := runHome defaultHome pThermo 7 365
def runD7 : HomeResult := runHome defaultHome pDyn 7 365
def runP7f1 : HomeResult := runHome homeF1 pPlan 7 365
def runP7e0 : HomeResult := runHome homeE0F1 pPlan 7 365
def runPv0 : HomeResult := runHome homePv0 pStatic 7 365

def seeds15 : List Nat := [1, 2, 3, 4, 5]

/-- The runs of the seeds 1 to 5 for a home and a policy. -/
def runsOf (setup : HomeSetup) (p : Policy) : List HomeResult :=
  seeds15.map (fun s => runHome setup p s 365)

def runsStatic : List HomeResult := runsOf defaultHome pStatic
def runsPlan : List HomeResult := runsOf defaultHome pPlan
def runsDyn : List HomeResult := runsOf defaultHome pDyn
def runsStaticCv5 : List HomeResult := runsOf (homeCv 0.5) pStatic
def runsPlanCv5 : List HomeResult := runsOf (homeCv 0.5) pPlan
def runsDynCv5 : List HomeResult := runsOf (homeCv 0.5) pDyn

def allRuns : List (String × List HomeResult) :=
  [("static", runsStatic), ("precomputed", runsPlan), ("dynamic", runsDyn)]

def allRunsCv5 : List (String × List HomeResult) :=
  [("static", runsStaticCv5), ("precomputed", runsPlanCv5), ("dynamic", runsDynCv5)]

def accSumHours (hs : Array HomeHour) (f : HomeHour → Float) : Float :=
  hs.foldl (fun acc h => acc + f h) 0.0

/-- The steps of the tank over the hours of a run, from the full tank. -/
def accReplayTank (cfg : TankConfig) (hs : Array HomeHour) : List TankStep :=
  let step := fun (acc : TankState × List TankStep) (h : HomeHour) =>
    let s := tankStep cfg acc.1 h.hour h.askKwh h.drawKwh
    (s.state, s :: acc.2)
  (hs.foldl step (startState cfg, ([] : List TankStep))).2.reverse

/-- The flows of the battery over the hours of a run, from an empty battery. -/
def accReplayFlows (b : Battery) (hs : Array HomeHour) : List Flow :=
  let step := fun (acc : Float × List Flow) (h : HomeHour) =>
    let f := stepHourGated b acc.1 h.allowCharge h.allowDischarge h.pvKwh
      (h.houseLoadKwh + h.heatKwh + h.backstopKwh)
    (f.socKwh, f :: acc.2)
  (hs.foldl step (0.0, ([] : List Flow))).2.reverse

def sameHomeHour (a b : HomeHour) : Bool :=
  a.day == b.day && a.hour == b.hour && a.pvKwh == b.pvKwh &&
  a.houseLoadKwh == b.houseLoadKwh && a.drawKwh == b.drawKwh && a.askKwh == b.askKwh &&
  a.heatKwh == b.heatKwh && a.backstopKwh == b.backstopKwh && a.unmetKwh == b.unmetKwh &&
  a.tankKwh == b.tankKwh && a.allowCharge == b.allowCharge &&
  a.allowDischarge == b.allowDischarge && flowSame a.flow b.flow 0.0

def sameRuns (a b : HomeResult) : Bool :=
  a.hours.size == b.hours.size &&
  (a.hours.toList.zip b.hours.toList).all (fun (x, y) => sameHomeHour x y)

/-- The first day of a run that has no hour with a full tank. -/
def dayWithoutFull (r : HomeResult) (cap : Float) : Option Nat :=
  (List.range (r.hours.size / 24)).find? (fun d =>
    !((List.range 24).any (fun h => r.hours[24 * d + h]!.tankKwh ≥ cap - 1e-9)))

def sameEval (a b : Evaluation) (tol : Float) : Bool :=
  near a.meanSelfConsumption b.meanSelfConsumption tol &&
  near a.worstSelfConsumption b.worstSelfConsumption tol &&
  near a.meanSelfSufficiency b.meanSelfSufficiency tol &&
  near a.meanImportKwh b.meanImportKwh tol && near a.meanExportKwh b.meanExportKwh tol &&
  near a.meanBackstopKwh b.meanBackstopKwh tol && near a.totalUnmetKwh b.totalUnmetKwh tol &&
  a.seeds == b.seeds && a.unmetSeeds == b.unmetSeeds && a.coldHours == b.coldHours

/-- Runs of the seeds 3 to 6 with the static policy, for the lines of the evaluation. -/
def runsS36 : List HomeResult :=
  (List.range 4).map (fun i => runHome defaultHome pStatic (3 + i) 365)

def evalS3x4 : Evaluation := evaluate defaultHome pStatic 3 4 365
def evalS3x4b : Evaluation := evaluate defaultHome pStatic 3 4 365
def evalS3x1 : Evaluation := evaluate defaultHome pStatic 3 1 365
def evalS3x0 : Evaluation := evaluate defaultHome pStatic 3 0 365

/-- Runs of a home with an unmet draw: an element of 0.2 kW, the static policy with 0 heating
hours, the seeds 3 to 6 and 30 days. The lines of CAP-homesim.R5 use them to prove that
`evaluate` counts and sums. -/
def runsE36 : List HomeResult :=
  (List.range 4).map (fun i => runHome homeElem02 pThermo (3 + i) 30)

def evalE3x4 : Evaluation := evaluate homeElem02 pThermo 3 4 30

/-- The grid of the tuner: a start from 6 to 16, from 1 to 8 heating hours, and discharge from
15 to 22, with the element of the home tank. -/
def accGrid : List StaticParams :=
  (List.range 704).map (fun n =>
    ({ heatStart := 6 + n / 64, heatHours := 1 + (n / 8) % 8, dischargeFrom := 15 + n % 8,
       elementKw := defaultHome.tank.elementKw } : StaticParams))

def accGridEvals : List (StaticParams × Evaluation) :=
  accGrid.map (fun p => (p, evaluate defaultHome (Policy.static p) 1 2 30))

def tune1 : TuneResult := tuneStatic defaultHome 1 2 30
def tune2 : TuneResult := tuneStatic defaultHome 1 2 30
def tunePv0 : TuneResult := tuneStatic homePv0 1 2 30

/-- The five policies of `sim policy compare` and `sim policy robust`, each with its home. -/
def rowSetups (home : HomeSetup) : List (String × HomeSetup × Policy) :=
  [("thermostat", home, pThermo), ("static", home, pStatic), ("precomputed", home, pPlan),
   ("dynamic", home, pDyn), ("perfect-forecast", { home with errorScale := 0.0 }, pPlan)]

/-- The totals of the five policies for latitude 45, seed 9 and 90 days. -/
def cmpLib90 : List (String × HomeTotals) :=
  (rowSetups homeLat45).map (fun (n, s, p) => (n, (runHome s p 9 90).totals))

/-- The evaluations of the five policies over the seeds 1 to 10 for 365 days. -/
def robustLib : List (String × Evaluation) :=
  (rowSetups defaultHome).map (fun (n, s, p) => (n, evaluate s p 1 10 365))

/-- The run of a home with an element of 0.2 kW and the thermostat policy: seed 7, 365 days. -/
def runE02 : HomeResult := runHome homeElem02 pThermo 7 365

/-- Each hour of a run must have the tank energy, the heating, the backstop heating and the
unmet draw of the `tankStep` result for the tank state of the hour before. -/
def tankMismatch (cfg : TankConfig) (hs : Array HomeHour) : Option String :=
  let steps := accReplayTank cfg hs
  match (hs.toList.zip steps).find? (fun (h, s) =>
      !(near h.tankKwh s.state.energyKwh 1e-9 && near h.heatKwh s.heatKwh 1e-9 &&
        near h.backstopKwh s.backstopKwh 1e-9 && near h.unmetKwh s.unmetKwh 1e-9)) with
  | some (h, s) =>
    some s!"day {h.day} hour {h.hour}: tank {h.tankKwh}, heating {h.heatKwh}, backstop {h.backstopKwh}, unmet {h.unmetKwh}; tankStep gives {s.state.energyKwh}, {s.heatKwh}, {s.backstopKwh}, {s.unmetKwh}"
  | none => if hs.size == steps.length then none else some "the replay has another length"

/-- Each hour of a run must have the flow of `stepHourGated` for the battery energy of the hour
before, its gate, its solar energy, and its house load plus its heating plus its backstop
heating. -/
def flowMismatch (b : Battery) (hs : Array HomeHour) : Option String :=
  let flows := accReplayFlows b hs
  match (hs.toList.zip flows).find? (fun (h, f) => !flowSame h.flow f 1e-9) with
  | some (h, f) =>
    some s!"day {h.day} hour {h.hour}: the flow is {repr h.flow}, stepHourGated gives {repr f}"
  | none => if hs.size == flows.length then none else some "the replay has another length"

/-- The first run of a policy (seeds 1 to 5) with an unmet draw in an hour. -/
def noUnmet (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    if r.hours.size != 8760 then some s!"{name}, seed {s}: {r.hours.size} hours"
    else
      match r.hours.toList.find? (fun h => h.unmetKwh > 1e-9) with
      | some h =>
        some s!"{name}, seed {s}: day {h.day} hour {h.hour} has an unmet draw of {h.unmetKwh} kWh"
      | none => none)

/-- The first run of a policy that ends an hour below the floor of 2.1 kWh, or that has a cold
hour. -/
def noCold (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    match r.hours.toList.find? (fun h => h.tankKwh < 2.1 - 1e-9) with
    | some h =>
      some s!"{name}, seed {s}: day {h.day} hour {h.hour} ends at {h.tankKwh} kWh, below the floor"
    | none =>
      if r.totals.coldHours == 0 && r.hours.size == 8760 then none
      else some s!"{name}, seed {s}: coldHours is {r.totals.coldHours}, {r.hours.size} hours")

/-- The first run of a policy with a cold hour. -/
def coldHoursZero (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    if r.totals.coldHours == 0 && r.hours.size == 8760 then none
    else some s!"{name}, seed {s}: coldHours is {r.totals.coldHours}, {r.hours.size} hours")

/-- The first run of a policy with a day that has no hour with a full tank. -/
def noEmptyDay (name : String) (rs : List HomeResult) : Option String :=
  (seeds15.zip rs).findSome? (fun (s, r) =>
    match dayWithoutFull r defaultHome.tank.capacityKwh with
    | some d => some s!"{name}, seed {s}: day {d} has no hour with a full tank"
    | none => if r.hours.size == 8760 then none else some s!"{name}, seed {s}: {r.hours.size} hours")

/-- A dynamic policy heats only in an hour with a surplus, or when the tank held less than
5.25 kWh before the hour. Gives the first hour that breaks this. -/
def badDynamic (hs : Array HomeHour) : Option String :=
  (List.range hs.size).findSome? (fun i =>
    let h := hs[i]!
    let before := if i == 0 then defaultHome.tank.capacityKwh else hs[i - 1]!.tankKwh
    if h.askKwh > 0.0 && !(h.pvKwh > h.houseLoadKwh || before < 5.25 + 1e-9) then
      some s!"day {h.day} hour {h.hour}: asks {h.askKwh}, solar {h.pvKwh}, load {h.houseLoadKwh}, tank before {before}"
    else none)

-- Helpers for the `sim` process

structure RunOut where
  code : UInt32
  out : String
  err : String

def sim (args : List String) : IO RunOut := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

/-- The runs of `sim` by argument list. A run is made once, and then it is read again. -/
structure Cache where
  runs : IO.Ref (List (List String × RunOut))

def mkCache : IO Cache := do
  let r ← IO.mkRef ([] : List (List String × RunOut))
  return { runs := r }

def cachedSim (c : Cache) (args : List String) : IO RunOut := do
  let known ← c.runs.get
  match known.find? (fun (k, _) => k == args) with
  | some (_, v) => return v
  | none =>
    let v ← sim args
    c.runs.set ((args, v) :: known)
    return v

def lines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")

/-- A line of `sim policy run`: the label, spaces to fill 18 characters, and the value. -/
def row (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
def labelled (l label : String) : Bool :=
  let cs := l.toList
  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '

def usageNew : String :=
  "usage: sim run [options] | sim compare [options] | sim forecast [options] | sim policy <command> [options]"

def usagePolicy : String := "usage: sim policy run|compare|robust|tune [options]"

def policyLabels : List String :=
  ["policy", "days", "seed", "solar", "load", "import", "export", "heating", "backstop",
   "unmet-hot-water", "cold-hours", "self-consumption", "self-sufficiency"]

def policyHeader : List String :=
  ["policy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh",
   "backstop-kWh"]

def robustHeader : List String :=
  ["policy", "mean-self-consumption-%", "worst-self-consumption-%", "mean-self-sufficiency-%",
   "mean-export-kWh", "mean-backstop-kWh", "unmet-kWh", "cold-hours", "safe"]

def rowNames : List String :=
  ["thermostat", "static", "precomputed", "dynamic", "perfect-forecast"]

def firstWords (out : String) : List String :=
  (lines out).map (fun l => (words l).head?.getD "")

def valueOf (out label : String) : Option String :=
  match (lines out).find? (fun l => (words l).head? == some label) with
  | some l => (words l)[1]?
  | none => none

def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum

/-- The words of the line that starts with `name`. -/
def rowWords (out name : String) : Option (List String) :=
  ((lines out).find? (fun l => (words l).head? == some name)).map words

def showsNum (s : Option String) (x : Float) : Bool :=
  match s.bind parseNum with
  | some v => near v (round1 x) 0.001
  | none => false

def checkShows (out : String) (pairs : List (String × Float)) : Option String :=
  match pairs.find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

def oneDecimal (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
  | _ => false

/-- The lines of `sim policy run` must show the totals of a run of the library. -/
def policyPairs (t : HomeTotals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh), ("export", t.exportKwh),
   ("heating", t.heatKwh), ("backstop", t.backstopKwh), ("unmet-hot-water", t.unmetKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

/-- A row of `sim policy compare` must show five values of the totals, with one decimal. -/
def compareRowShows (w : List String) (t : HomeTotals) : Bool :=
  w.length == 6 && (w.drop 1).all oneDecimal &&
  showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
  showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh && showsNum w[5]? t.backstopKwh

/-- A row of `sim policy robust` must show an evaluation. The column `safe` is `yes` when no
seed has an unmet draw and `cold-hours` is 0. -/
def robustRowShows (w : List String) (e : Evaluation) : Bool :=
  w.length == 9 && showsNum w[1]? e.meanSelfConsumption &&
  showsNum w[2]? e.worstSelfConsumption && showsNum w[3]? e.meanSelfSufficiency &&
  showsNum w[4]? e.meanExportKwh && showsNum w[5]? e.meanBackstopKwh &&
  showsNum w[6]? e.totalUnmetKwh && w[7]? == some (toString e.coldHours) &&
  w[8]? == some (if e.unmetSeeds == 0 && e.coldHours == 0 then "yes" else "no")

/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
def expectError (args : List String) (line : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]

/-- Expects each error line for its argument list. Gives the first failure. -/
def allErrors (cases : List (List String × String)) : IO (Option String) := do
  for (a, line) in cases do
    let r ← expectError a line
    if r.isSome then return r
  return none

/-- Expects exit code 0 and the 13 lines of `sim policy run`. -/
def okRun (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (firstWords r.out == policyLabels, s!"sim {args}: stdout is {repr r.out}")]

/-- Expects each argument list to run with exit code 0. Gives the first failure. -/
def allOk (cases : List (List String)) : IO (Option String) := do
  for a in cases do
    let r ← okRun a
    if r.isSome then return r
  return none

/-- Expects exit code 2 and empty stdout for each argument list. -/
def allEmptyOut (cases : List (List String)) : IO (Option String) := do
  for a in cases do
    let r ← sim a
    if r.out != "" || r.code != 2 || r.err == "" then
      return some s!"sim {a}: exit code {r.code}, stdout {repr r.out}"
  return none

/-- True when a row of `sim policy robust` has a worst self-consumption above its mean, or when
a value does not read as a number. -/
def worstAboveMean (w : List String) : Bool :=
  match w[1]?.bind parseNum, w[2]?.bind parseNum with
  | some m, some x => x > m
  | _, _ => true

/-- The start of the Solcast JSON. -/
def jsonStart : String := "{\"forecasts\":["

/-- The period end of each period of the JSON text. -/
def jsonEnds (js : String) : List String :=
  ((js.splitOn "\"period_end\":\"").drop 1).map (fun p => (p.splitOn "\"").headD "")

/-- The text after `"key":` up to the next comma, for each period of the JSON text. -/
def valuesOfKey (js key : String) : List String :=
  ((js.splitOn ("\"" ++ key ++ "\":")).drop 1).map (fun p => (p.splitOn ",").headD "")

/-- The line that starts with `label`. -/
def lineOf (out label : String) : Option String :=
  (lines out).find? (fun l => (words l).head? == some label)

/-- The value of the line `label` must be a number near `want`. -/
def numNear (out label : String) (want tol : Float) : Bool :=
  match numOf out label with
  | some v => near v want tol
  | none => false

/-- The self-consumption of a row of `sim policy compare` or `sim policy robust`. The mean is
the first value of both tables. -/
def firstOfRow (out name : String) : Option Float :=
  (rowWords out name).bind (fun w => w[1]?.bind parseNum)

/-- The words of a row without its name. -/
def tailOfRow (out name : String) : Option (List String) :=
  (rowWords out name).map (fun w => w.drop 1)

/-- A `sim policy run` argument list for an option that is checked at its edge. The run is 3
days, so that the check stays cheap. -/
def cheap (extra : List String) : List String :=
  ["policy", "run", "--days", "3"] ++ extra

def pr (extra : List String) : List String := ["policy", "run"] ++ extra

-- The checks of each spec

def forecastChecks : List Check := [
  -- CAP-forecast.R6
  { name := "CAP-forecast.R6 forecastOf gives the same periods as forecast for the fetch hours 0, 4116 and 8750",
    run := do
      let a := forecastOf scen7 site45 7 1.0 0
      let b := forecastOf scen7 site45 7 1.0 8750
      return firstSome [
        sameAsForecast 0, sameAsForecast 4116, sameAsForecast 8750,
        if a.size == 96 && b.size == 20 then none
        else some s!"{a.size} periods at hour 0 and {b.size} periods at hour 8750"] },
  { name := "CAP-forecast.R6 with an error scale of 0 each value of a fetch at hour 4000 equals its actual power",
    run := do
      let ps := forecastOf scen7 site45 7 0.0 4000
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R6 a fetch at hour 8760 has no period",
    run := do
      let ps := forecastOf scen7 site45 7 1.0 8760
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 no hours give no period for a fetch at hour 0",
    run := do
      let ps := forecastOf (#[] : Array Hour) site45 7 1.0 0
      return if ps.size == 0 then none else some s!"{ps.size} periods" },
  { name := "CAP-forecast.R6 seeds 7 and 8 give a different estimate for a fetch at hour 4000",
    run := do
      let a := forecastOf scen7 site45 7 1.0 4000
      let b := forecastOf scen8 site45 8 1.0 4000
      let differs := (List.zip a.toList b.toList).any (fun (x, y) => !(x.estimateKw == y.estimateKw))
      return firstFail [
        (a.size == 96 && b.size == 96, s!"{a.size} and {b.size} periods"),
        (differs, "each estimate is the same for the two seeds")] },

  -- CAP-forecast.R7
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 and at 13:30 of a day have a correlation from 0.55 to 0.85",
    run := do
      let n := pairsSameDay.length
      let c := corrF (pairsSameDay.map (·.1)) (pairsSameDay.map (·.2))
      if n < 150 then
        return some s!"only {n} days have both periods"
      return if c ≥ 0.55 && c ≤ 0.85 then none
        else some s!"correlation {c} over {n} days" },
  -- The line says that each period comes from the fetch at 00:00 of its own day. The variable `a`
  -- reads the line so. The variable `b` also takes both periods from the fetch of the first
  -- day. Both readings must give a correlation from -0.25 to 0.25.
  { name := "CAP-forecast.R7 the errors of the periods that end at 11:30 of a day and of the next day have a correlation from -0.25 to 0.25",
    run := do
      let a := pairsNextFetch
      let b := pairsNextSameFetch
      let ca := corrF (a.map (·.1)) (a.map (·.2))
      let cb := corrF (b.map (·.1)) (b.map (·.2))
      return firstFail [
        (a.length ≥ 150 && b.length ≥ 150, s!"only {a.length} and {b.length} pairs of days"),
        (ca ≥ -0.25 && ca ≤ 0.25,
          s!"fetch of each day: correlation {ca} over {a.length} pairs of days"),
        (cb ≥ -0.25 && cb ≤ 0.25,
          s!"one fetch for both days: correlation {cb} over {b.length} pairs of days")] },
  { name := "CAP-forecast.R7 at least 62% of the days have the same sign of the error at 13:30 in the fetches at hour 0 and at hour 10",
    run := do
      let usable := signPairs.filter (fun (x, y) => x.abs > 1e-12 && y.abs > 1e-12)
      let same := usable.filter (fun (x, y) => x * y > 0.0)
      let n := usable.length
      if n < 150 then
        return some s!"only {n} days count"
      return if same.length.toFloat ≥ 0.62 * n.toFloat then none
        else some s!"{same.length} of {n} days have the same sign" },
  { name := "CAP-forecast.R7 with an error scale of 0 each value of a fetch at hour 0 equals its actual power",
    run := do
      let ps := fo 0.0 0
      return firstSome [
        if ps.size == 96 then none else some s!"{ps.size} periods",
        badEqual ps,
        if sumEst ps > 0.5 then none else some s!"the estimates add up to {sumEst ps}"] },
  { name := "CAP-forecast.R7 60% to 95% of the sunny periods of a fetch at 00:00 of each day have the actual power in the band",
    run := do
      let n := sunnyAll.length
      let k := (sunnyAll.filter inBand).length
      if n < 1000 then
        return some s!"only {n} sunny periods"
      return if k.toFloat ≥ 0.6 * n.toFloat && k.toFloat ≤ 0.95 * n.toFloat then none
        else some s!"{k} of {n} sunny periods have the actual power in the band" }
]

def hotwaterChecks : List Check := [
  -- CAP-hotwater.R1
  { name := "CAP-hotwater.R1 8.0 kWh stored and no draw give a loss of 0.048 kWh and 7.952 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 8.0) 12 0.0 0.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.048), ("tank", s.state.energyKwh, 7.952)] },
  { name := "CAP-hotwater.R1 8.0 kWh stored and a draw of 1.5 kWh serve the draw and leave 6.452 kWh",
    run := do
      let s := tankStep flatTank (stOff 8.0) 12 0.0 1.5
      return valsIs 1e-9 [("loss", s.lossKwh, 0.048), ("served", s.servedKwh, 1.5),
        ("unmet", s.unmetKwh, 0.0), ("tank", s.state.energyKwh, 6.452)] },
  { name := "CAP-hotwater.R1 1.0 kWh stored and a draw of 2.0 kWh leave an unmet draw of 1.006 kWh",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.006), ("served", s.servedKwh, 0.994),
        ("unmet", s.unmetKwh, 1.006)] },
  { name := "CAP-hotwater.R1 0.0 kWh stored and a draw of 1.0 kWh give no loss and an unmet draw of 1.0 kWh",
    run := do
      let s := tankStep flatTank (stOff 0.0) 12 0.0 1.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.0), ("served", s.servedKwh, 0.0),
        ("unmet", s.unmetKwh, 1.0)] },
  { name := "CAP-hotwater.R1 10.5 kWh stored and no draw give a loss of 0.063 kWh",
    run := do
      let s := tankStep flatTank (stOff 10.5) 12 0.0 0.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.063)] },
  { name := "CAP-hotwater.R1 a tank with no loss keeps 5.0 kWh in an hour with no draw",
    run := do
      let s := tankStep { flatTank with lossPerHour := 0.0 } (stOff 5.0) 12 0.0 0.0
      return valsIs 1e-9 [("tank", s.state.energyKwh, 5.0)] },

  -- CAP-hotwater.R2
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 2.0 kWh give a heating of 2.0 kWh and 6.97 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 2.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 2.0), ("tank", s.state.energyKwh, 6.97)] },
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 5.0 kWh give a heating of 3.0 kWh, the element power",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 5.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 3.0), ("tank", s.state.energyKwh, 7.97)] },
  { name := "CAP-hotwater.R2 9.0 kWh stored and a request of 3.0 kWh give a heating of 1.554 kWh, the room that is left",
    run := do
      let s := tankStep flatTank (stOff 9.0) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 1.554), ("tank", s.state.energyKwh, 10.5)] },
  { name := "CAP-hotwater.R2 10.5 kWh stored and a request of 3.0 kWh give a heating of 0.063 kWh",
    run := do
      let s := tankStep flatTank (stOff 10.5) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 0.063), ("tank", s.state.energyKwh, 10.5)] },
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 0 kWh give no heating",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 0.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 0.0)] },
  { name := "CAP-hotwater.R2 the draw comes before the heating: 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh leave an unmet draw of 0.512 kWh",
    run := do
      let s := tankStep flatTank (stOff 2.0) 12 3.0 2.5
      return valsIs 1e-9 [("served", s.servedKwh, 1.988), ("unmet", s.unmetKwh, 0.512),
        ("heating", s.heatKwh, 3.0), ("tank", s.state.energyKwh, 3.0)] },
  { name := "CAP-hotwater.R2 a tank with a capacity of 0 kWh has an unmet draw of 1.0 kWh and takes no heating",
    run := do
      let s := tankStep { flatTank with capacityKwh := 0.0 } (stOff 0.0) 12 3.0 1.0
      return valsIs 1e-9 [("unmet", s.unmetKwh, 1.0), ("heating", s.heatKwh, 0.0),
        ("tank", s.state.energyKwh, 0.0)] },

  -- CAP-hotwater.R3
  { name := "CAP-hotwater.R3 a tank at 5.0 kWh cuts the thermostat in",
    run := do
      let s := tankStep defaultTank (stOff 5.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 7.97)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat off gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 6.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 5.964)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat on keeps heating",
    run := do
      let s := tankStep defaultTank (stOn 6.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 8.964)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a tank at 9.0 kWh with the thermostat on heats to full and then the thermostat goes off",
    run := do
      let s := tankStep defaultTank (stOn 9.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 1.554), ("tank", s.state.energyKwh, 10.5)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a request of 2.0 kWh at 5.0 kWh keeps the thermostat off and gives no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 5.0) 12 2.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 2.0), ("backstop", s.backstopKwh, 0.0),
          ("tank", s.state.energyKwh, 6.97)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a request of 1.0 kWh at 4.0 kWh leaves 2.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 4.0) 12 1.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("backstop", s.backstopKwh, 2.0),
          ("tank", s.state.energyKwh, 6.976)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a request of 1.0 kWh at 9.0 kWh with the thermostat on leaves 0.554 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOn 9.0) 12 1.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("backstop", s.backstopKwh, 0.554),
          ("tank", s.state.energyKwh, 10.5)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a draw that empties the tank gives an unmet draw of 1.006 kWh and 3.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("unmet", s.unmetKwh, 1.006), ("backstop", s.backstopKwh, 3.0),
        ("tank", s.state.energyKwh, 3.0)] },
  { name := "CAP-hotwater.R3 a cut-in of 0 kWh gives no backstop heating at 1.0 kWh",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },

  -- CAP-hotwater.R4
  { name := "CAP-hotwater.R4 at latitude 45 the draw of the days 0 to 364 adds up to 2190.0 kWh",
    run := do
      let t := accYearDraw 6.0 45.0
      return if near t 2190.0 0.1 then none else some s!"got {t}" },
  { name := "CAP-hotwater.R4 at latitude 45 the 24 hours of day 100 add up to the seasonal draw",
    run := do
      let t := accDayDraw 6.0 45.0 100
      let want := 6.0 * (1.0 + 0.15 * Float.cos (2.0 * 3.141592653589793 * 85.0 / 365.0))
      return if near t want 0.000001 then none else some s!"got {t}, want {want}" },
  { name := "CAP-hotwater.R4 at latitude 45 the draw of day 15 is 1.34 to 1.37 times the draw of day 197",
    run := do
      let q := accDayDraw 6.0 45.0 15 / accDayDraw 6.0 45.0 197
      return if q ≥ 1.34 && q ≤ 1.37 then none else some s!"ratio {q}" },
  { name := "CAP-hotwater.R4 at latitude -41 the draw of day 197 is 1.34 to 1.37 times the draw of day 15",
    run := do
      let q := accDayDraw 6.0 (-41.0) 197 / accDayDraw 6.0 (-41.0) 15
      return if q ≥ 1.34 && q ≤ 1.37 then none else some s!"ratio {q}" },
  { name := "CAP-hotwater.R4 on day 100 hour 7 draws more than hour 3, and hour 19 draws more than hour 13",
    run := do
      let h7 := drawKwh 6.0 45.0 100 7
      let h3 := drawKwh 6.0 45.0 100 3
      let h19 := drawKwh 6.0 45.0 100 19
      let h13 := drawKwh 6.0 45.0 100 13
      return firstFail [
        (h7 > h3, s!"hour 7 draws {h7}, hour 3 draws {h3}"),
        (h19 > h13, s!"hour 19 draws {h19}, hour 13 draws {h13}")] },
  { name := "CAP-hotwater.R4 a daily energy of 0.0 kWh gives a draw of 0 kWh in each hour of day 100",
    run := do
      let bad := (List.range 24).find? (fun h => !near (drawKwh 0.0 45.0 100 h) 0.0 1e-12)
      return match bad with
        | some h => some s!"hour {h} draws {drawKwh 0.0 45.0 100 h}"
        | none => none },

  -- CAP-hotwater.R5
  { name := "CAP-hotwater.R5 at hour 20 a tank at 9.0 kWh that was not full today heats to full",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 20 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 1.554), ("tank", s.state.energyKwh, 10.5)],
        fullIs s true] },
  { name := "CAP-hotwater.R5 at hour 19 a tank at 9.0 kWh that was not full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 19 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 8.946)],
        fullIs s false] },
  { name := "CAP-hotwater.R5 at hour 20 a tank at 9.0 kWh that was full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 9.0) 20 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 8.946)] },
  { name := "CAP-hotwater.R5 at hour 22 a tank at 4.0 kWh that was not full today gets 3.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 4.0) 22 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 6.976)],
        thermoIs s true] },
  { name := "CAP-hotwater.R5 at hour 0 a full tank loses energy and fullToday starts again as false",
    run := do
      let s := tankStep defaultTank (stOff 10.5) 0 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("tank", s.state.energyKwh, 10.437)],
        fullIs s false] },
  { name := "CAP-hotwater.R5 at hour 0 a request of 3.0 kWh at 10.5 kWh fills the tank and fullToday is true",
    run := do
      let s := tankStep defaultTank (stOpen 10.5) 0 3.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 0.063), ("tank", s.state.energyKwh, 10.5)],
        fullIs s true] },
  { name := "CAP-hotwater.R5 at hour 12 a tank at 9.0 kWh that was not full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 12 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  { name := "CAP-hotwater.R5 a guard hour of 24 gives no backstop heating at hour 23",
    run := do
      let s := tankStep { defaultTank with guardHour := 24 } (stOpen 9.0) 23 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  { name := "CAP-hotwater.R5 the start state of the default tank is full with the thermostat off and fullToday true",
    run := do
      let st := startState defaultTank
      return firstFail [
        (near st.energyKwh 10.5 1e-9, s!"the tank holds {st.energyKwh} kWh"),
        (st.heating == false, "the thermostat is on"),
        (st.fullToday == true, "fullToday is false")] },

  -- CAP-hotwater.R6
  { name := "CAP-hotwater.R6 a spread of 0 gives the factor 1.0 on each of the days 0 to 364",
    run := do
      let fs := accFactors 7 0.0 365
      let bad := fs.find? (fun f => !near f 1.0 0.000000000001)
      return if fs.length == 365 && bad.isNone then none
        else some s!"{fs.length} factors, a wrong one is {bad}" },
  { name := "CAP-hotwater.R6 seed 7 and a spread of 0.25 give factors above 0 with a mean from 0.98 to 1.02 and a standard deviation from 0.23 to 0.27",
    run := do
      let fs := accFactors 7 0.25 5000
      let m := meanF fs
      let sd := stdF fs
      return firstFail [
        (fs.length == 5000, s!"{fs.length} factors"),
        (fs.all (fun f => f > 0.0), "a factor is not above 0"),
        (m ≥ 0.98 && m ≤ 1.02, s!"mean {m}"),
        (sd ≥ 0.23 && sd ≤ 0.27, s!"standard deviation {sd}")] },
  { name := "CAP-hotwater.R6 seed 7 and a spread of 0.5 give a mean from 0.97 to 1.03 and a standard deviation from 0.48 to 0.58",
    run := do
      let fs := accFactors 7 0.5 5000
      let m := meanF fs
      let sd := stdF fs
      return firstFail [
        (fs.length == 5000, s!"{fs.length} factors"),
        (m ≥ 0.97 && m ≤ 1.03, s!"mean {m}"),
        (sd ≥ 0.48 && sd ≤ 0.58, s!"standard deviation {sd}")] },
  { name := "CAP-hotwater.R6 the factor of the same day is the same two times",
    run := do
      let a := accFactors 7 0.25 365
      let b := accFactors 7 0.25 365
      return if a == b && a.length == 365 && !(a.all (fun f => f == 1.0)) then none
        else some "the two reads differ, or the factors do not vary" },
  { name := "CAP-hotwater.R6 seeds 7 and 8 give a different factor on at least 300 of the days 0 to 364",
    run := do
      let a := accFactors 7 0.25 365
      let b := accFactors 8 0.25 365
      let n := ((a.zip b).filter (fun (x, y) => !(x == y))).length
      return if n ≥ 300 then none else some s!"{n} days differ" }
]

def simulationChecks : List Check := [
  -- CAP-simulation.R6
  { name := "CAP-simulation.R6 an empty battery that may charge takes 2 kWh and then holds 1.9 kWh",
    run := do
      let f := stepHourGated b105 0.0 true true 3.0 1.0
      return valsIs 1e-9 [("direct", f.directKwh, 1.0), ("charge", f.chargeKwh, 2.0),
        ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R6 an empty battery that may not charge exports 2 kWh and still holds 0 kWh",
    run := do
      let f := stepHourGated b105 0.0 false true 3.0 1.0
      return valsIs 1e-9 [("charge", f.chargeKwh, 0.0), ("export", f.exportKwh, 2.0),
        ("soc", f.socKwh, 0.0)] },
  { name := "CAP-simulation.R6 1.9 kWh stored and a battery that may discharge give 1.805 kWh and an import of 0.195 kWh",
    run := do
      let f := stepHourGated b105 1.9 true true 0.0 2.0
      return valsIs 1e-9 [("discharge", f.dischargeKwh, 1.805), ("import", f.importKwh, 0.195)] },
  { name := "CAP-simulation.R6 1.9 kWh stored and a battery that may not discharge give 0 kWh and an import of 2.0 kWh",
    run := do
      let f := stepHourGated b105 1.9 true false 0.0 2.0
      return valsIs 1e-9 [("discharge", f.dischargeKwh, 0.0), ("import", f.importKwh, 2.0),
        ("soc", f.socKwh, 1.9)] },
  { name := "CAP-simulation.R6 9.05 kWh stored and a battery that may charge take 1 kWh of a surplus of 2 kWh and then hold 10 kWh",
    run := do
      let f := stepHourGated b105 9.05 true true 3.0 1.0
      return valsIs 1e-9 [("charge", f.chargeKwh, 1.0), ("export", f.exportKwh, 1.0),
        ("soc", f.socKwh, 10.0)] },
  { name := "CAP-simulation.R6 a battery that may not charge and may not discharge exports a surplus of 2 kWh and imports a shortfall of 2 kWh",
    run := do
      let a := stepHourGated b105 5.0 false false 3.0 1.0
      let b := stepHourGated b105 5.0 false false 0.0 2.0
      return valsIs 1e-9 [("export of the surplus", a.exportKwh, 2.0),
        ("import of the shortfall", b.importKwh, 2.0)] },
  { name := "CAP-simulation.R6 a battery that may charge and discharge gives the flows of greedy in the 24 hours of day 100",
    run := do
      return gatedVersus Strategy.greedy 0 6.0 },
  { name := "CAP-simulation.R6 a battery that may charge and may discharge only from 17:00 gives the flows of evening in the 24 hours of day 100",
    run := do
      return gatedVersus Strategy.evening 17 6.0 }
]

def policyChecks : List Check := [
  -- CAP-policy.R1
  { name := "CAP-policy.R1 the default parameters give 24 actions",
    run := do
      let a := staticProfile defaultStatic
      return if a.size == 24 then none else some s!"{a.size} actions" },
  { name := "CAP-policy.R1 the default parameters ask for 3.0 kWh in hours 10 to 13 and for 0 kWh in hours 9 and 14",
    run := do
      let a := staticProfile defaultStatic
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 9", a[9]!.heatKwh, 0.0), ("hour 10", a[10]!.heatKwh, 3.0),
        ("hour 11", a[11]!.heatKwh, 3.0), ("hour 12", a[12]!.heatKwh, 3.0),
        ("hour 13", a[13]!.heatKwh, 3.0), ("hour 14", a[14]!.heatKwh, 0.0)] },
  { name := "CAP-policy.R1 the default parameters let the battery discharge in hours 17 and 23, and not in hours 0 and 16",
    run := do
      let a := staticProfile defaultStatic
      if a.size != 24 then
        return some s!"{a.size} actions"
      return firstFail [
        (a[17]!.allowDischarge, "the battery may not discharge in hour 17"),
        (a[23]!.allowDischarge, "the battery may not discharge in hour 23"),
        (!a[0]!.allowDischarge, "the battery may discharge in hour 0"),
        (!a[16]!.allowDischarge, "the battery may discharge in hour 16")] },
  { name := "CAP-policy.R1 the default parameters let the battery charge in each hour",
    run := do
      let a := staticProfile defaultStatic
      return if a.size == 24 && (List.range 24).all (fun h => a[h]!.allowCharge) then none
        else some s!"{a.size} actions, and the battery may not charge in an hour" },
  { name := "CAP-policy.R1 0 heating hours ask for 0 kWh in each hour",
    run := do
      let a := staticProfile { defaultStatic with heatHours := 0 }
      return if a.size == 24 && (List.range 24).all (fun h => a[h]!.heatKwh == 0.0) then none
        else some s!"{a.size} actions, and an hour asks for heating" },
  { name := "CAP-policy.R1 a start of 22 and 2 heating hours ask for 3.0 kWh in hours 22 and 23 and for 0 kWh in hour 21",
    run := do
      let a := staticProfile { defaultStatic with heatStart := 22, heatHours := 2 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 21", a[21]!.heatKwh, 0.0), ("hour 22", a[22]!.heatKwh, 3.0),
        ("hour 23", a[23]!.heatKwh, 3.0)] },
  { name := "CAP-policy.R1 a start of 23 and 5 heating hours stop at the end of the day",
    run := do
      let a := staticProfile { defaultStatic with heatStart := 23, heatHours := 5 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 23", a[23]!.heatKwh, 3.0), ("hour 0", a[0]!.heatKwh, 0.0)] },
  { name := "CAP-policy.R1 an element of 1.5 kW asks for 1.5 kWh in each heating hour",
    run := do
      let a := staticProfile { defaultStatic with elementKw := 1.5 }
      if a.size != 24 then
        return some s!"{a.size} actions"
      return valsIs 1e-9 [("hour 9", a[9]!.heatKwh, 0.0), ("hour 10", a[10]!.heatKwh, 1.5),
        ("hour 11", a[11]!.heatKwh, 1.5), ("hour 12", a[12]!.heatKwh, 1.5),
        ("hour 13", a[13]!.heatKwh, 1.5), ("hour 14", a[14]!.heatKwh, 0.0)] },
  { name := "CAP-policy.R1 discharge from 24 never lets the battery discharge",
    run := do
      let a := staticProfile { defaultStatic with dischargeFrom := 24 }
      return if a.size == 24 && (List.range 24).all (fun h => !a[h]!.allowDischarge) then none
        else some s!"{a.size} actions, and the battery may discharge in an hour" },

  -- CAP-policy.R2
  { name := "CAP-policy.R2 4.0 kWh in the tank and an expected draw of 6.0 kWh put 2.0, 3.0, 3.0 and 3.0 kWh in hours 10 to 13",
    run := do
      let a := planDay defaultTank plan9 sunDay 4.0 6.0
      return planAsks a [(10, 2.0), (11, 3.0), (12, 3.0), (13, 3.0)] },
  { name := "CAP-policy.R2 9.0 kWh in the tank and an expected draw of 0.5 kWh ask for 0.5 kWh in hour 13",
    run := do
      let a := planDay defaultTank plan9 sunDay 9.0 0.5
      return planAsks a [(13, 0.5)] },
  { name := "CAP-policy.R2 10.0 kWh in the tank and no expected draw ask for 0 kWh in each hour",
    run := do
      let a := planDay defaultTank plan9 sunDay 10.0 0.0
      return planAsks a [] },
  { name := "CAP-policy.R2 a forecast of 0.4 kWh in each hour asks for 0 kWh in each hour",
    run := do
      let a := planDay defaultTank plan9 (accFcOf [] 0.4) 4.0 6.0
      return planAsks a [] },
  { name := "CAP-policy.R2 a forecast of 0.5 kWh in hour 12 asks for 3.0 kWh in hour 12",
    run := do
      let a := planDay defaultTank plan9 (accFcOf [(12, 0.5)]) 4.0 6.0
      return planAsks a [(12, 3.0)] },
  { name := "CAP-policy.R2 a minimum forecast of 0.0 kWh and no sun put the heating in hour 0, because a tie goes to the earlier hour",
    run := do
      let p : PlanParams := { plan9 with minSolarKwh := 0.0 }
      let a := planDay defaultTank p (accFcOf []) 9.0 3.0
      return planAsks a [(0, 3.0)] },
  { name := "CAP-policy.R2 equal forecasts of 2.0 kWh in hours 10 to 14 put 3.0 kWh in hour 10 and 1.0 kWh in hour 11",
    run := do
      let fc := accFcOf [(10, 2.0), (11, 2.0), (12, 2.0), (13, 2.0), (14, 2.0)]
      let a := planDay defaultTank plan9 fc 9.0 4.0
      return planAsks a [(10, 3.0), (11, 1.0)] },
  { name := "CAP-policy.R2 the default parameters let the battery charge in each hour and discharge in hour 17 but not in hour 16",
    run := do
      let a := planDay defaultTank defaultPlan sunDay 5.0 6.0
      if a.size != 24 then
        return some s!"{a.size} actions"
      return firstFail [
        ((List.range 24).all (fun h => a[h]!.allowCharge), "the battery may not charge in an hour"),
        (a[17]!.allowDischarge, "the battery may not discharge in hour 17"),
        (!a[16]!.allowDischarge, "the battery may discharge in hour 16")] },

  -- CAP-policy.R3
  { name := "CAP-policy.R3 a surplus of 2.0 kWh and 5.0 kWh in the tank ask for 2.0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 2.0 0.0) 2.0 },
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 5.0 kWh in the tank ask for 3.0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 5.0 0.0) 3.0 },
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 8.0 kWh in the tank ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 8.0 5.0 0.0) 1.0 },
  { name := "CAP-policy.R3 a surplus of 5.0 kWh and 9.0 or 9.5 kWh in the tank ask for 0 kWh",
    run := do
      return firstSome [asksDyn (accObs 12 9.0 5.0 0.0) 0.0, asksDyn (accObs 12 9.5 5.0 0.0) 0.0] },
  { name := "CAP-policy.R3 no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 0.0 0.5) 1.0 },
  { name := "CAP-policy.R3 no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh ask for 0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 0.0 1.0) 0.0 },
  { name := "CAP-policy.R3 no surplus and 5.0 kWh in the tank ask for 0 kWh",
    run := do
      return asksDyn (accObs 12 5.0 0.0 0.0) 0.0 },
  { name := "CAP-policy.R3 no surplus, 0.0 kWh in the tank and no forecast ask for 3.0 kWh",
    run := do
      return asksDyn (accObs 12 0.0 0.0 0.0) 3.0 },
  { name := "CAP-policy.R3 a surplus of 1.0 kWh, 3.0 kWh in the tank and no forecast ask for 1.0 kWh",
    run := do
      return asksDyn (accObs 12 3.0 1.0 0.0) 1.0 },
  { name := "CAP-policy.R3 in hour 16 the battery may charge and may not discharge, and in hour 17 it may do both",
    run := do
      let a := dynamicAction defaultTank dyn49 (accObs 16 5.0 0.0 0.0)
      let b := dynamicAction defaultTank dyn49 (accObs 17 5.0 0.0 0.0)
      return firstFail [
        (a.allowCharge, "hour 16: the battery may not charge"),
        (!a.allowDischarge, "hour 16: the battery may discharge"),
        (b.allowCharge, "hour 17: the battery may not charge"),
        (b.allowDischarge, "hour 17: the battery may not discharge")] },

  -- CAP-policy.R4
  { name := "CAP-policy.R4 defaultStatic heats from hour 10 for 4 hours, discharges from hour 17 and has an element of 3.0 kW",
    run := do
      let p := defaultStatic
      return firstFail [
        (p.heatStart == 10, s!"the heating starts at {p.heatStart}"),
        (p.heatHours == 4, s!"the heating lasts {p.heatHours} hours"),
        (p.dischargeFrom == 17, s!"discharge starts at {p.dischargeFrom}"),
        (near p.elementKw 3.0 1e-9, s!"the element is {p.elementKw} kW")] },
  { name := "CAP-policy.R4 defaultPlan has a target of 10.5 kWh, a minimum forecast of 0.5 kWh and discharge from hour 17",
    run := do
      let p := defaultPlan
      return firstFail [
        (near p.targetKwh 10.5 1e-9, s!"the target is {p.targetKwh} kWh"),
        (near p.minSolarKwh 0.5 1e-9, s!"the minimum forecast is {p.minSolarKwh} kWh"),
        (p.dischargeFrom == 17, s!"discharge starts at {p.dischargeFrom}")] },
  { name := "CAP-policy.R4 defaultDynamic has a low level of 5.25 kWh, a target of 10.5 kWh and discharge from hour 17",
    run := do
      let p := defaultDynamic
      return firstFail [
        (near p.lowKwh 5.25 1e-9, s!"the low level is {p.lowKwh} kWh"),
        (near p.targetKwh 10.5 1e-9, s!"the target is {p.targetKwh} kWh"),
        (p.dischargeFrom == 17, s!"discharge starts at {p.dischargeFrom}")] },
  { name := "CAP-policy.R4 the names of the policies are static, precomputed and dynamic",
    run := do
      let a := Policy.name (Policy.static defaultStatic)
      let b := Policy.name (Policy.precomputed defaultPlan)
      let c := Policy.name (Policy.dynamic defaultDynamic)
      return firstFail [
        (a == "static", s!"the static policy is called {repr a}"),
        (b == "precomputed", s!"the precomputed policy is called {repr b}"),
        (c == "dynamic", s!"the dynamic policy is called {repr c}")] }
]

def homesimChecks : List Check := [
  -- CAP-homesim.R1
  { name := "CAP-homesim.R1 the default run has 8760 hours in order of day, then hour",
    run := do
      let hs := runS7.hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i =>
            !(hs[i]!.day == i / 24 && hs[i]!.hour == i % 24)) with
          | some i => some s!"item {i} is day {hs[i]!.day} hour {hs[i]!.hour}"
          | none => none },
  { name := "CAP-homesim.R1 the solar energy and the house load of each hour are those of the scenario hour",
    run := do
      let hs := runS7.hours
      let bad := (List.range hs.size).find? (fun i =>
        !(near hs[i]!.pvKwh scenHome7[i]!.pvKwh 1e-9 &&
          near hs[i]!.houseLoadKwh (scenHome7[i]!.baseLoadKwh + scenHome7[i]!.flexKwh) 1e-9))
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i}: solar {hs[i]!.pvKwh}, load {hs[i]!.houseLoadKwh}; the scenario has {scenHome7[i]!.pvKwh} and {scenHome7[i]!.baseLoadKwh + scenHome7[i]!.flexKwh}"
          | none => none },
  { name := "CAP-homesim.R1 askKwh and the battery gate of each hour are those of the static profile",
    run := do
      let prof := staticProfile defaultStatic
      let hs := runS7.hours
      let bad := hs.toList.find? (fun h =>
        !(h.hour < 24 && near h.askKwh prof[h.hour]!.heatKwh 1e-9 &&
          h.allowCharge == prof[h.hour]!.allowCharge &&
          h.allowDischarge == prof[h.hour]!.allowDischarge))
      return if hs.size != 8760 || prof.size != 24 then
          some s!"{hs.size} hours and {prof.size} actions"
        else match bad with
          | some h => some s!"day {h.day} hour {h.hour}: ask {h.askKwh}, charge {h.allowCharge}, discharge {h.allowDischarge}"
          | none => none },
  { name := "CAP-homesim.R1 the tank energy of each hour is the tankStep result for the tank state of the hour before",
    run := do
      let hs := runS7.hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else tankMismatch defaultHome.tank hs },
  { name := "CAP-homesim.R1 the flow of each hour is the stepHourGated flow for the battery energy of the hour before",
    run := do
      let hs := runS7.hours
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else flowMismatch defaultHome.battery hs },
  -- The spread of the home is 0.25 in the line. Thus the check uses the number 0.25.
  { name := "CAP-homesim.R1 the draw of each hour is the drawKwh of the home times the drawFactor for seed 7, its day and the spread 0.25",
    run := do
      let hs := runS7.hours
      let want := fun (i : Nat) =>
        let s := scenHome7[i]!
        drawKwh defaultHome.drawKwhPerDay defaultHome.site.latitude s.dayOfYear s.hour *
          drawFactor 7 s.day 0.25
      let bad := (List.range hs.size).find? (fun i => !near hs[i]!.drawKwh (want i) 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i} draws {hs[i]!.drawKwh} kWh, want {want i}"
          | none => if hs.any (fun h => h.drawKwh > 0.0) then none else some "no hour has a draw" },
  { name := "CAP-homesim.R1 with a spread of 0 the draw of each hour is the drawKwh of the home",
    run := do
      let hs := runS7cv0.hours
      let want := fun (i : Nat) =>
        let s := scenHome7[i]!
        drawKwh defaultHome.drawKwhPerDay defaultHome.site.latitude s.dayOfYear s.hour
      let bad := (List.range hs.size).find? (fun i => !near hs[i]!.drawKwh (want i) 1e-9)
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match bad with
          | some i => some s!"item {i} draws {hs[i]!.drawKwh} kWh, want {want i}"
          | none => if hs.any (fun h => h.drawKwh > 0.0) then none else some "no hour has a draw" },
  { name := "CAP-homesim.R1 the precomputed policy with 1 fetch each day asks for the heating of planDay from the forecast of the fetch at hour 24 × d",
    run := do
      let hs := runP7f1.hours
      if hs.size != 8760 then
        return some s!"{hs.size} hours"
      let bad := (List.range 365).findSome? (fun d =>
        let ps := forecastOf scenHome7 homeF1.site 7 homeF1.errorScale (24 * d)
        let fc := ((hourlyEnergy ps (24 * d)).toList.take 24).toArray
        let tank0 := if d == 0 then defaultTank.capacityKwh else hs[24 * d - 1]!.tankKwh
        let draw := accDayDraw homeF1.drawKwhPerDay homeF1.site.latitude d
        let plan := planDay homeF1.tank defaultPlan fc tank0 draw
        (List.range 24).findSome? (fun h =>
          if near hs[24 * d + h]!.askKwh plan[h]!.heatKwh 1e-9 then none
          else some s!"day {d} hour {h}: asks {hs[24 * d + h]!.askKwh} kWh, planDay gives {plan[h]!.heatKwh} kWh"))
      return firstSome [bad,
        if hs.any (fun h => h.askKwh > 0.0) then none else some "no hour asks for heating"] },
  { name := "CAP-homesim.R1 0 days give a run with no hours",
    run := do
      let r := runHome defaultHome pStatic 7 0
      return if r.hours.size == 0 then none else some s!"{r.hours.size} hours" },

  -- CAP-homesim.R2
  { name := "CAP-homesim.R2 each policy and the seeds 1 to 5 have an unmet draw of 0 kWh in each hour",
    run := do
      return allRuns.findSome? (fun (n, rs) => noUnmet n rs) },
  { name := "CAP-homesim.R2 each policy and the seeds 1 to 5 keep the tank at or above 2.1 kWh and have no cold hours",
    run := do
      return allRuns.findSome? (fun (n, rs) => noCold n rs) },
  { name := "CAP-homesim.R2 each policy and the seeds 1 to 5 have an hour after which the tank is full on each day",
    run := do
      return allRuns.findSome? (fun (n, rs) => noEmptyDay n rs) },
  { name := "CAP-homesim.R2 each policy with a spread of 0.5 and the seeds 1 to 5 have no unmet draw and no cold hours",
    run := do
      return allRunsCv5.findSome? (fun (n, rs) => firstSome [noUnmet n rs, coldHoursZero n rs]) },
  { name := "CAP-homesim.R2 a static policy with 0 heating hours has more than 500 kWh of backstop heating and no unmet draw",
    run := do
      let t := runT7.totals
      return firstFail [
        (runT7.hours.size == 8760, s!"{runT7.hours.size} hours"),
        (t.backstopKwh > 500.0, s!"backstop heating {t.backstopKwh} kWh"),
        (near t.unmetKwh 0.0 1e-9, s!"unmet draw {t.unmetKwh} kWh")] },
  { name := "CAP-homesim.R2 a home with an element of 0.2 kW and no heating hours has an unmet draw and cold hours",
    run := do
      let t := runE02.totals
      return firstFail [
        (runE02.hours.size == 8760, s!"{runE02.hours.size} hours"),
        (t.unmetKwh > 0.0, s!"unmet draw {t.unmetKwh} kWh"),
        (t.coldHours > 0, s!"cold hours {t.coldHours}")] },

  -- CAP-homesim.R3
  { name := "CAP-homesim.R3 each total equals the sum of its hours",
    run := do
      let hs := runS7.hours
      let t := runS7.totals
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (t.pvKwh > 0.0 && t.heatKwh > 0.0 && t.batteryLossKwh > 0.0, "a total is 0, so the run proves little"),
        (near t.pvKwh (accSumHours hs (·.pvKwh)) 0.01, s!"solar {t.pvKwh}"),
        (near t.loadKwh (accSumHours hs (fun h => h.houseLoadKwh + h.heatKwh + h.backstopKwh)) 0.01,
          s!"load {t.loadKwh}"),
        (near t.importKwh (accSumHours hs (·.flow.importKwh)) 0.01, s!"import {t.importKwh}"),
        (near t.exportKwh (accSumHours hs (·.flow.exportKwh)) 0.01, s!"export {t.exportKwh}"),
        (near t.batteryLossKwh (accSumHours hs (·.flow.lossKwh)) 0.01,
          s!"battery loss {t.batteryLossKwh}"),
        (near t.heatKwh (accSumHours hs (·.heatKwh)) 0.01, s!"heating {t.heatKwh}"),
        (near t.backstopKwh (accSumHours hs (·.backstopKwh)) 0.01, s!"backstop heating {t.backstopKwh}"),
        (near t.drawKwh (accSumHours hs (·.drawKwh)) 0.01, s!"draw {t.drawKwh}"),
        (near t.unmetKwh (accSumHours hs (·.unmetKwh)) 0.01, s!"unmet draw {t.unmetKwh}")] },
  { name := "CAP-homesim.R3 solar plus import equals load plus export plus battery loss plus the energy that the battery holds at the end",
    run := do
      let hs := runS7.hours
      let t := runS7.totals
      let soc := hs[hs.size - 1]!.flow.socKwh
      let lhs := t.pvKwh + t.importKwh
      let rhs := t.loadKwh + t.exportKwh + t.batteryLossKwh + soc
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (t.pvKwh > 0.0 && t.batteryLossKwh > 0.0, "solar or battery loss is 0, so the run proves little"),
        (near lhs rhs 0.01, s!"solar and import {lhs}, the rest {rhs}")] },
  { name := "CAP-homesim.R3 the full tank at the start plus the heating plus the backstop heating equals the served draw plus the tank loss plus the final tank energy",
    run := do
      let hs := runS7.hours
      let t := runS7.totals
      let steps := accReplayTank defaultHome.tank hs
      let served := sumF (steps.map (·.servedKwh))
      let lhs := defaultHome.tank.capacityKwh + t.heatKwh + t.backstopKwh
      let rhs := served + t.tankLossKwh + t.finalTankKwh
      return firstFail [
        (hs.size == 8760, s!"{hs.size} hours"),
        (t.tankLossKwh > 0.0 && served > 0.0, "the tank loss or the served draw is 0, so the run proves little"),
        (near lhs rhs 0.01, s!"start, heating and backstop {lhs}, the rest {rhs}")] },
  -- The second run has an unmet draw, so the check also proves that the unmet draw counts.
  { name := "CAP-homesim.R3 unmetKwh plus the served draw equals drawKwh, which is the sum of the hours",
    run := do
      let one := fun (r : HomeResult) (cfg : TankConfig) =>
        let served := sumF ((accReplayTank cfg r.hours).map (·.servedKwh))
        firstFail [
          (r.hours.size == 8760, s!"{r.hours.size} hours"),
          (near (r.totals.unmetKwh + served) r.totals.drawKwh 0.01,
            s!"unmet {r.totals.unmetKwh} and served {served}, draw {r.totals.drawKwh}"),
          (near r.totals.drawKwh (accSumHours r.hours (·.drawKwh)) 0.01,
            s!"draw {r.totals.drawKwh}, sum of the hours {accSumHours r.hours (·.drawKwh)}")]
      return firstSome [one runS7 defaultHome.tank, one runE02 homeElem02.tank,
        if runE02.totals.unmetKwh > 0.0 then none else some "the second run has no unmet draw"] },
  { name := "CAP-homesim.R3 the self-consumption is 100 × (solar - export) / solar and the self-sufficiency is 100 × (load - import) / load",
    run := do
      let t := runS7.totals
      let sc := 100.0 * (t.pvKwh - t.exportKwh) / t.pvKwh
      let ss := 100.0 * (t.loadKwh - t.importKwh) / t.loadKwh
      return firstFail [
        (t.pvKwh > 0.0 && t.loadKwh > 0.0, "solar or load is 0"),
        (near t.selfConsumption sc 1e-6, s!"self-consumption {t.selfConsumption}, want {sc}"),
        (near t.selfSufficiency ss 1e-6, s!"self-sufficiency {t.selfSufficiency}, want {ss}")] },
  { name := "CAP-homesim.R3 with a spread of 0 the draw total is 2190.0 kWh",
    run := do
      let t := runS7cv0.totals
      return if near t.drawKwh 2190.0 0.1 then none else some s!"draw {t.drawKwh}" },
  { name := "CAP-homesim.R3 with a spread of 0.25 and the seeds 1 to 5 the draw total is from 2060 to 2320 kWh",
    run := do
      let ds := runsStatic.map (·.totals.drawKwh)
      return match (seeds15.zip ds).find? (fun (_, d) => !(d ≥ 2060.0 && d ≤ 2320.0)) with
        | some (s, d) => some s!"seed {s} has a draw of {d} kWh"
        | none => if ds.length == 5 then none else some s!"{ds.length} runs" },
  { name := "CAP-homesim.R3 0 kW of panels give a self-consumption of 0%",
    run := do
      let t := runPv0.totals
      return firstFail [
        (runPv0.hours.size == 8760, s!"{runPv0.hours.size} hours"),
        (near t.pvKwh 0.0 1e-9, s!"solar {t.pvKwh}"),
        (near t.selfConsumption 0.0 1e-9, s!"self-consumption {t.selfConsumption}")] },
  -- A run of 0 days has no hours. Each total and each ratio is 0, except `minTankKwh` and
  -- `finalTankKwh`. These two are 10.5 kWh, the energy of the full tank at the start.
  { name := "CAP-homesim.R3 0 days give a total of 0 and a ratio of 0% in each field, and 10.5 kWh in the tank",
    run := do
      let t := (runHome defaultHome pStatic 7 0).totals
      let zero := [("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh),
        ("export", t.exportKwh), ("battery loss", t.batteryLossKwh),
        ("tank loss", t.tankLossKwh), ("heating", t.heatKwh), ("backstop", t.backstopKwh),
        ("draw", t.drawKwh), ("unmet", t.unmetKwh), ("self-consumption", t.selfConsumption),
        ("self-sufficiency", t.selfSufficiency)]
      return firstSome [
        (match zero.find? (fun (_, v) => !(v == 0.0)) with
          | some (n, v) => some s!"{n} is {v}, want 0"
          | none => none),
        valsIs 1e-9 [("lowest tank", t.minTankKwh, 10.5), ("final tank", t.finalTankKwh, 10.5)],
        if t.coldHours == 0 then none else some s!"cold hours {t.coldHours}"] },

  -- CAP-homesim.R4
  { name := "CAP-homesim.R4 the static policy asks for heating only in hours 10, 11, 12 and 13",
    run := do
      let hs := runS7.hours
      let bad := hs.toList.find? (fun h => h.askKwh > 0.0 && !(10 ≤ h.hour && h.hour ≤ 13))
      return match bad with
        | some h => some s!"day {h.day} hour {h.hour} asks for {h.askKwh} kWh"
        | none => if hs.size == 8760 && hs.any (fun h => h.askKwh > 0.0) then none
          else some s!"{hs.size} hours, and no hour asks for heating" },
  { name := "CAP-homesim.R4 the precomputed policy with an error scale of 0 asks for heating only in hours with at least 0.5 kWh of solar energy",
    run := do
      let hs := runP7e0.hours
      let bad := hs.toList.find? (fun h => h.askKwh > 0.0 && !(h.pvKwh ≥ 0.5 - 0.000001))
      return match bad with
        | some h => some s!"day {h.day} hour {h.hour} asks for {h.askKwh} kWh with {h.pvKwh} kWh of solar energy"
        | none => if hs.size == 8760 && hs.any (fun h => h.askKwh > 0.0) then none
          else some s!"{hs.size} hours, and no hour asks for heating" },
  { name := "CAP-homesim.R4 the dynamic policy asks for heating only with a surplus or when the tank held less than 5.25 kWh",
    run := do
      let hs := runD7.hours
      return firstSome [badDynamic hs,
        if hs.size == 8760 && hs.any (fun h => h.askKwh > 0.0) then none
        else some s!"{hs.size} hours, and no hour asks for heating"] },
  { name := "CAP-homesim.R4 the static policy has a higher self-consumption than the static policy with 0 heating hours",
    run := do
      let a := runS7.totals.selfConsumption
      let b := runT7.totals.selfConsumption
      return if a > b then none else some s!"static {a}, 0 heating hours {b}" },
  { name := "CAP-homesim.R4 the dynamic policy has a higher self-consumption than the static policy with 0 heating hours",
    run := do
      let a := runD7.totals.selfConsumption
      let b := runT7.totals.selfConsumption
      return if a > b then none else some s!"dynamic {a}, 0 heating hours {b}" },
  { name := "CAP-homesim.R4 the same policy and seed twice give the same hours",
    run := do
      let cases := [("static", pStatic), ("precomputed", pPlan), ("dynamic", pDyn)]
      return cases.findSome? (fun (n, p) =>
        let a := runHome defaultHome p 7 30
        let b := runHome defaultHome p 7 30
        if a.hours.size == 720 && sameRuns a b then none
        else some s!"the {n} policy gives {a.hours.size} and {b.hours.size} hours, or the hours differ") },

  -- CAP-homesim.R5
  { name := "CAP-homesim.R5 1 seed from seed 3 gives the self-consumption of the run with seed 3 as mean and as worst",
    run := do
      let sc := runsS36[0]!.totals.selfConsumption
      return firstFail [
        (near evalS3x1.meanSelfConsumption sc 1e-9, s!"mean {evalS3x1.meanSelfConsumption}, want {sc}"),
        (near evalS3x1.worstSelfConsumption sc 1e-9,
          s!"worst {evalS3x1.worstSelfConsumption}, want {sc}")] },
  { name := "CAP-homesim.R5 4 seeds from seed 3 give the average of the runs as mean and the lowest as worst",
    run := do
      let scs := runsS36.map (·.totals.selfConsumption)
      return firstFail [
        (scs.length == 4, s!"{scs.length} runs"),
        (near evalS3x4.meanSelfConsumption (meanF scs) 1e-9,
          s!"mean {evalS3x4.meanSelfConsumption}, want {meanF scs}"),
        (near evalS3x4.worstSelfConsumption (minF scs) 1e-9,
          s!"worst {evalS3x4.worstSelfConsumption}, want {minF scs}")] },
  { name := "CAP-homesim.R5 the worst self-consumption is not more than the mean",
    run := do
      let e := evalS3x4
      return if e.worstSelfConsumption ≤ e.meanSelfConsumption + 1e-9 then none
        else some s!"worst {e.worstSelfConsumption}, mean {e.meanSelfConsumption}" },
  { name := "CAP-homesim.R5 the mean import, export and backstop heating are the averages of the runs and the total unmet draw is their sum",
    run := do
      let e := evalS3x4
      let ts := runsS36.map (·.totals)
      return firstFail [
        (ts.length == 4, s!"{ts.length} runs"),
        (near e.meanImportKwh (meanF (ts.map (·.importKwh))) 1e-9, s!"mean import {e.meanImportKwh}"),
        (near e.meanExportKwh (meanF (ts.map (·.exportKwh))) 1e-9, s!"mean export {e.meanExportKwh}"),
        (near e.meanBackstopKwh (meanF (ts.map (·.backstopKwh))) 1e-9,
          s!"mean backstop heating {e.meanBackstopKwh}"),
        (near e.meanSelfSufficiency (meanF (ts.map (·.selfSufficiency))) 1e-9,
          s!"mean self-sufficiency {e.meanSelfSufficiency}"),
        (near e.totalUnmetKwh (sumF (ts.map (·.unmetKwh))) 1e-9,
          s!"total unmet draw {e.totalUnmetKwh}")] },
  { name := "CAP-homesim.R5 4 seeds give seeds 4 and no seed with an unmet draw and no cold hours",
    run := do
      let e := evalS3x4
      return firstFail [
        (e.seeds == 4, s!"seeds {e.seeds}"),
        (e.unmetSeeds == 0, s!"unmetSeeds {e.unmetSeeds}"),
        (e.coldHours == 0, s!"coldHours {e.coldHours}")] },
  -- The runs of the default home have an unmet draw of 0 kWh. Thus the two checks below use a
  -- home with an element of 0.2 kW and no heating hours. A version of `evaluate` that never
  -- counts, or that takes a mean where the line says a sum, fails them.
  { name := "CAP-homesim.R5 for a home with an unmet draw the total unmet draw is the sum of the unmet draws of the runs",
    run := do
      let e := evalE3x4
      let us := runsE36.map (·.totals.unmetKwh)
      return firstFail [
        (us.length == 4, s!"{us.length} runs"),
        (sumF us > 0.0, "the runs have no unmet draw, so the check proves nothing"),
        (e.totalUnmetKwh > 0.0, s!"total unmet draw {e.totalUnmetKwh}"),
        (near e.totalUnmetKwh (sumF us) 1e-9,
          s!"total unmet draw {e.totalUnmetKwh}, the sum of the runs is {sumF us}")] },
  { name := "CAP-homesim.R5 for a home with an unmet draw unmetSeeds counts the runs with an unmet draw and coldHours is the sum of their cold hours",
    run := do
      let e := evalE3x4
      let ts := runsE36.map (·.totals)
      let n := (ts.filter (fun t => t.unmetKwh > 0.0)).length
      let cold := ts.foldl (fun acc t => acc + t.coldHours) (0 : Nat)
      return firstFail [
        (ts.length == 4, s!"{ts.length} runs"),
        (n > 0, "no run has an unmet draw, so the check proves nothing"),
        (cold > 0, "no run has a cold hour, so the check proves nothing"),
        (e.unmetSeeds > 0, s!"unmetSeeds {e.unmetSeeds}"),
        (e.unmetSeeds == n, s!"unmetSeeds {e.unmetSeeds}, the runs with an unmet draw are {n}"),
        (e.coldHours == cold, s!"coldHours {e.coldHours}, the sum of the runs is {cold}")] },
  { name := "CAP-homesim.R5 0 seeds give 0 in each field",
    run := do
      let e := evalS3x0
      let zero := [("mean self-consumption", e.meanSelfConsumption),
        ("worst self-consumption", e.worstSelfConsumption),
        ("mean self-sufficiency", e.meanSelfSufficiency), ("mean import", e.meanImportKwh),
        ("mean export", e.meanExportKwh), ("mean backstop heating", e.meanBackstopKwh),
        ("total unmet draw", e.totalUnmetKwh)]
      return match zero.find? (fun (_, v) => !(v == 0.0)) with
        | some (n, v) => some s!"{n} is {v}, want 0"
        | none =>
          if e.seeds == 0 && e.unmetSeeds == 0 && e.coldHours == 0 then none
          else some s!"seeds {e.seeds}, unmetSeeds {e.unmetSeeds}, coldHours {e.coldHours}" },
  { name := "CAP-homesim.R5 the same arguments twice give the same evaluation",
    run := do
      return if sameEval evalS3x4 evalS3x4b 0.0 then none
        else some s!"first {repr evalS3x4}, second {repr evalS3x4b}" },

  -- CAP-homesim.R6
  { name := "CAP-homesim.R6 2 seeds from seed 1 and 30 days give 704 candidates and 704 safe candidates",
    run := do
      return firstFail [
        (tune1.candidates == 704, s!"candidates {tune1.candidates}"),
        (tune1.safe == 704, s!"safe {tune1.safe}")] },
  { name := "CAP-homesim.R6 the best start is from 6 to 16, its heating hours from 1 to 8 and its discharge hour from 15 to 22",
    run := do
      let b := tune1.best
      return firstFail [
        (6 ≤ b.heatStart && b.heatStart ≤ 16, s!"start {b.heatStart}"),
        (1 ≤ b.heatHours && b.heatHours ≤ 8, s!"heating hours {b.heatHours}"),
        (15 ≤ b.dischargeFrom && b.dischargeFrom ≤ 22, s!"discharge hour {b.dischargeFrom}")] },
  { name := "CAP-homesim.R6 the evaluation is the evaluation of the best static profile over the same seeds and days",
    run := do
      let e := evaluate defaultHome (Policy.static tune1.best) 1 2 30
      return if sameEval tune1.evaluation e 1e-9 then none
        else some s!"tuner {repr tune1.evaluation}, evaluate {repr e}" },
  { name := "CAP-homesim.R6 no safe candidate has a mean self-consumption more than 0.05 points above the best",
    run := do
      let best := tune1.evaluation.meanSelfConsumption
      let bad := accGridEvals.find? (fun (_, e) =>
        e.unmetSeeds == 0 && e.meanSelfConsumption > best + 0.05 + 1e-9)
      return if accGridEvals.length != 704 then some s!"{accGridEvals.length} candidates"
        else match bad with
          | some (p, e) => some s!"start {p.heatStart}, {p.heatHours} hours, discharge {p.dischargeFrom} has {e.meanSelfConsumption}, the best has {best}"
          | none => none },
  { name := "CAP-homesim.R6 no safe candidate within 0.05 points of the highest has a lower mean import than the best",
    run := do
      let safeEvals := accGridEvals.filter (fun (_, e) => e.unmetSeeds == 0)
      let top := safeEvals.foldl (fun acc (_, e) =>
        if e.meanSelfConsumption > acc then e.meanSelfConsumption else acc) (-1.0)
      let bestImport := tune1.evaluation.meanImportKwh
      let bad := safeEvals.find? (fun (_, e) =>
        e.meanSelfConsumption ≥ top - 0.05 && e.meanImportKwh < bestImport - 1e-9)
      return if accGridEvals.length != 704 then some s!"{accGridEvals.length} candidates"
        else match bad with
          | some (p, e) => some s!"start {p.heatStart}, {p.heatHours} hours, discharge {p.dischargeFrom} has an import of {e.meanImportKwh}, the best has {bestImport}"
          | none => none },
  { name := "CAP-homesim.R6 the same arguments twice give the same result",
    run := do
      let a := tune1
      let b := tune2
      return if a.best.heatStart == b.best.heatStart && a.best.heatHours == b.best.heatHours &&
          a.best.dischargeFrom == b.best.dischargeFrom && a.candidates == b.candidates &&
          a.safe == b.safe && sameEval a.evaluation b.evaluation 0.0 then none
        else some s!"first {repr a}, second {repr b}" },
  { name := "CAP-homesim.R6 a home with 0 kW of panels gives 704 safe candidates and a best mean self-consumption of 0%",
    run := do
      return firstFail [
        (tunePv0.safe == 704, s!"safe {tunePv0.safe}"),
        (near tunePv0.evaluation.meanSelfConsumption 0.0 1e-9,
          s!"best mean self-consumption {tunePv0.evaluation.meanSelfConsumption}")] }
]

def jobChecks (cache : Cache) : List Check := [
  -- JOB-simulate.R5
  { name := "JOB-simulate.R5 sim with no arguments prints the usage with the new commands and exits with 0",
    run := do
      let r ← sim []
      return if r.code == 0 && (lines r.out).head? == some usageNew then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim help prints the same usage and exits with 0",
    run := do
      let a ← sim []
      let r ← sim ["help"]
      return if r.code == 0 && (lines r.out).head? == some usageNew && r.out == a.out then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim --help prints the same usage and exits with 0",
    run := do
      let a ← sim []
      let r ← sim ["--help"]
      return if r.code == 0 && (lines r.out).head? == some usageNew && r.out == a.out then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },

  -- JOB-simulate.R6
  { name := "JOB-simulate.R6 sim forecast prints the Solcast JSON with 96 periods and a line break",
    run := do
      let r ← sim ["forecast"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (r.out.startsWith (jsonStart ++ "{\"pv_estimate\":"),
          s!"stdout starts with {repr (r.out.take 60).toString}"),
        ((jsonEnds r.out).length == 96, s!"{(jsonEnds r.out).length} periods"),
        (r.out.endsWith "]}\n" && (lines r.out).length == 1, "stdout is not one line")] },
  { name := "JOB-simulate.R6 sim forecast has a first period that ends at 2024-12-31T13:00:00.0000000Z",
    run := do
      let r ← sim ["forecast"]
      let got := (jsonEnds r.out).head?
      return if r.code == 0 && got == some "2024-12-31T13:00:00.0000000Z" then none
        else some s!"exit code {r.code}, the first period ends at {got}" },
  { name := "JOB-simulate.R6 --lon 0 gives a first period that ends at 2025-01-01T00:30:00.0000000Z",
    run := do
      let r ← sim ["forecast", "--lon", "0"]
      let got := (jsonEnds r.out).head?
      return if r.code == 0 && got == some "2025-01-01T00:30:00.0000000Z" then none
        else some s!"exit code {r.code}, the first period ends at {got}" },
  { name := "JOB-simulate.R6 --hour 8759 gives 2 periods",
    run := do
      let r ← sim ["forecast", "--hour", "8759"]
      return if r.code == 0 && (jsonEnds r.out).length == 2 then none
        else some s!"exit code {r.code}, {(jsonEnds r.out).length} periods, stderr {repr r.err}" },
  { name := "JOB-simulate.R6 --forecast-error 0 --lat 45 --hour 4116 gives pv_estimate10 and pv_estimate90 equal to pv_estimate",
    run := do
      let r ← sim ["forecast", "--forecast-error", "0", "--lat", "45", "--hour", "4116"]
      let est := valuesOfKey r.out "pv_estimate"
      let lo := valuesOfKey r.out "pv_estimate10"
      let hi := valuesOfKey r.out "pv_estimate90"
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (est.length == 96, s!"{est.length} periods"),
        (lo == est, "a pv_estimate10 differs from its pv_estimate"),
        (hi == est, "a pv_estimate90 differs from its pv_estimate"),
        (est.any (fun v => (parseNum v).getD 0.0 > 0.0), "no estimate is above 0")] },
  { name := "JOB-simulate.R6 --seed 3 --hour 4116 gives the same output two times",
    run := do
      let a ← sim ["forecast", "--seed", "3", "--hour", "4116"]
      let b ← sim ["forecast", "--seed", "3", "--hour", "4116"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (jsonEnds a.out).length == 96
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R6 --hour 8760 gives OUT_OF_RANGE",
    run := expectError ["forecast", "--hour", "8760"] "error: OUT_OF_RANGE: --hour 8760 (0 to 8759)" },
  { name := "JOB-simulate.R6 --days 2 --hour 48 gives OUT_OF_RANGE",
    run := expectError ["forecast", "--days", "2", "--hour", "48"]
      "error: OUT_OF_RANGE: --hour 48 (0 to 47)" },
  { name := "JOB-simulate.R6 --hour abc gives BAD_NUMBER",
    run := expectError ["forecast", "--hour", "abc"] "error: BAD_NUMBER: --hour abc" },
  { name := "JOB-simulate.R6 --hour 2.5 gives BAD_NUMBER",
    run := expectError ["forecast", "--hour", "2.5"] "error: BAD_NUMBER: --hour 2.5" },
  { name := "JOB-simulate.R6 --hour with no value gives MISSING_VALUE",
    run := expectError ["forecast", "--hour"] "error: MISSING_VALUE: --hour" },
  { name := "JOB-simulate.R6 --lon 180.1 gives OUT_OF_RANGE, and --lon 180 and --lon -180 are accepted",
    run := do
      let a ← expectError ["forecast", "--lon", "180.1"] "error: OUT_OF_RANGE: --lon 180.1 (-180 to 180)"
      let b ← sim ["forecast", "--lon", "180"]
      let c ← sim ["forecast", "--lon", "-180"]
      return firstSome [a,
        if b.code == 0 && b.out.startsWith jsonStart then none
        else some s!"--lon 180: exit code {b.code}, stderr {repr b.err}",
        if c.code == 0 && c.out.startsWith jsonStart then none
        else some s!"--lon -180: exit code {c.code}, stderr {repr c.err}"] },
  { name := "JOB-simulate.R6 --forecast-error 5.1 gives OUT_OF_RANGE, and --forecast-error 5 and 0 are accepted",
    run := do
      let a ← expectError ["forecast", "--forecast-error", "5.1"]
        "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"
      let b ← sim ["forecast", "--forecast-error", "5"]
      let c ← sim ["forecast", "--forecast-error", "0"]
      return firstSome [a,
        if b.code == 0 && b.out.startsWith jsonStart then none
        else some s!"--forecast-error 5: exit code {b.code}, stderr {repr b.err}",
        if c.code == 0 && c.out.startsWith jsonStart then none
        else some s!"--forecast-error 0: exit code {c.code}, stderr {repr c.err}"] },
  { name := "JOB-simulate.R6 --strategy greedy gives UNKNOWN_OPTION",
    run := expectError ["forecast", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
  { name := "JOB-simulate.R6 --battery 5 gives UNKNOWN_OPTION",
    run := expectError ["forecast", "--battery", "5"] "error: UNKNOWN_OPTION: --battery" },
  { name := "JOB-simulate.R6 each error gives empty stdout and exit code 2",
    run := allEmptyOut [
      ["forecast", "--hour", "8760"], ["forecast", "--days", "2", "--hour", "48"],
      ["forecast", "--hour", "abc"], ["forecast", "--hour", "2.5"], ["forecast", "--hour"],
      ["forecast", "--lon", "180.1"], ["forecast", "--forecast-error", "5.1"],
      ["forecast", "--strategy", "greedy"], ["forecast", "--battery", "5"]] },

  -- JOB-simulate.R7
  { name := "JOB-simulate.R7 sim policy run prints the 13 lines in order and exits with 0",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (firstWords r.out == policyLabels, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R7 each line of sim policy run has its label to column 19 and a value with its unit",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      let ls := lines r.out
      let bad := (List.range 13).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (policyLabels.getD i "") &&
          (if i < 3 then w.length == 2
           else if i == 10 then
             w.length == 2 && w.getD 1 "" != "" && (w.getD 1 "").toList.all Char.isDigit
           else if i < 10 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
      return if r.code != 0 || ls.length != 13 then some s!"stdout is {repr r.out}"
        else match bad with
          | some i => some s!"the line {ls[i]?} has the wrong form"
          | none => none },
  { name := "JOB-simulate.R7 the first three lines show static, 365 days and seed 1",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      let want := [row "policy" "static", row "days" "365", row "seed" "1"]
      return if r.code == 0 && (lines r.out).take 3 == want then none
        else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R7 --policy dynamic --days 30 --lat 45 --seed 9 shows the totals of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "dynamic", "--days", "30", "--lat", "45",
        "--seed", "9"]
      let t := (runHome homeLat45 pDyn 9 30).totals
      let want := [row "policy" "dynamic", row "days" "30", row "seed" "9"]
      return firstSome [
        (if r.code == 0 then none else some s!"exit code {r.code}, stderr {repr r.err}"),
        (if (lines r.out).take 3 == want then none else some s!"stdout is {repr r.out}"),
        checkShows r.out (policyPairs t),
        (if valueOf r.out "cold-hours" == some (toString t.coldHours) then none
          else some s!"cold-hours shows {valueOf r.out "cold-hours"}, want {t.coldHours}")] },
  -- The line has no --days. The check adds --days 30, so that the run stays short.
  { name := "JOB-simulate.R7 --policy precomputed --target 8 --min-solar 1 shows the totals of the home simulation",
    run := do
      let r ← cachedSim cache ["policy", "run", "--policy", "precomputed", "--target", "8",
        "--min-solar", "1", "--days", "30"]
      let p := Policy.precomputed { defaultPlan with targetKwh := 8.0, minSolarKwh := 1.0 }
      let t := (runHome defaultHome p 1 30).totals
      let want := [row "policy" "precomputed", row "days" "30", row "seed" "1"]
      return firstSome [
        (if r.code == 0 then none else some s!"exit code {r.code}, stderr {repr r.err}"),
        (if (lines r.out).take 3 == want then none else some s!"stdout is {repr r.out}"),
        checkShows r.out (policyPairs t),
        (if valueOf r.out "cold-hours" == some (toString t.coldHours) then none
          else some s!"cold-hours shows {valueOf r.out "cold-hours"}, want {t.coldHours}")] },
  { name := "JOB-simulate.R7 --heat-hours 0 shows a heating of 0.0 kWh and a backstop above 0.0 kWh",
    run := do
      let r ← cachedSim cache ["policy", "run", "--heat-hours", "0"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (lineOf r.out "heating" == some (row "heating" "0.0 kWh"),
          s!"the heating line is {lineOf r.out "heating"}"),
        ((numOf r.out "backstop").getD 0.0 > 0.0, s!"the backstop value is {valueOf r.out "backstop"}")] },
  { name := "JOB-simulate.R7 --tank 0 --draw-cv 0 shows an unmet hot water of 2190.0 kWh and no heating",
    run := do
      let r ← sim ["policy", "run", "--tank", "0", "--draw-cv", "0"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (numNear r.out "unmet-hot-water" 2190.0 0.1,
          s!"the unmet-hot-water value is {valueOf r.out "unmet-hot-water"}"),
        (numNear r.out "heating" 0.0 1e-9, s!"the heating value is {valueOf r.out "heating"}"),
        (numNear r.out "backstop" 0.0 1e-9, s!"the backstop value is {valueOf r.out "backstop"}")] },
  { name := "JOB-simulate.R7 --element 0.2 --heat-hours 0 --days 90 shows an unmet hot water and cold hours",
    run := do
      let r ← sim ["policy", "run", "--element", "0.2", "--heat-hours", "0", "--days", "90"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((numOf r.out "unmet-hot-water").getD 0.0 > 0.0,
          s!"the unmet-hot-water value is {valueOf r.out "unmet-hot-water"}"),
        ((numOf r.out "cold-hours").getD 0.0 > 0.0,
          s!"the cold-hours value is {valueOf r.out "cold-hours"}")] },
  { name := "JOB-simulate.R7 the default run shows an unmet hot water of 0.0 kWh and 0 cold hours",
    run := do
      let r ← cachedSim cache ["policy", "run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (lineOf r.out "unmet-hot-water" == some (row "unmet-hot-water" "0.0 kWh"),
          s!"the unmet-hot-water line is {lineOf r.out "unmet-hot-water"}"),
        (lineOf r.out "cold-hours" == some (row "cold-hours" "0"),
          s!"the cold-hours line is {lineOf r.out "cold-hours"}")] },
  { name := "JOB-simulate.R7 --seed 5 gives the same output two times",
    run := do
      let a ← sim ["policy", "run", "--seed", "5"]
      let b ← sim ["policy", "run", "--seed", "5"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 13
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R7 --policy wild gives UNKNOWN_POLICY, and so does a name that differs by its case",
    run := do
      let a ← expectError (pr ["--policy", "wild"])
        "error: UNKNOWN_POLICY: wild (static, precomputed, dynamic)"
      let b ← expectError (pr ["--policy", "Static"])
        "error: UNKNOWN_POLICY: Static (static, precomputed, dynamic)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R7 --seeds, --strategy and --monthly give UNKNOWN_OPTION",
    run := allErrors [
      (pr ["--seeds", "3"], "error: UNKNOWN_OPTION: --seeds"),
      (pr ["--strategy", "greedy"], "error: UNKNOWN_OPTION: --strategy"),
      (pr ["--monthly"], "error: UNKNOWN_OPTION: --monthly")] },
  { name := "JOB-simulate.R7 each error gives empty stdout and exit code 2",
    run := allEmptyOut [
      pr ["--policy", "wild"], pr ["--policy", "Static"], pr ["--seeds", "3"],
      pr ["--strategy", "greedy"], pr ["--monthly"]] },

  -- JOB-simulate.R8
  { name := "JOB-simulate.R8 sim policy compare prints the header and the rows thermostat, static, precomputed, dynamic and perfect-forecast",
    run := do
      let r ← cachedSim cache ["policy", "compare"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 6, s!"{ls.length} lines, want 6"),
        (Option.map words ls[0]? == some policyHeader, s!"the header is {ls[0]?}"),
        (firstWords r.out == "policy" :: rowNames, s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 6), "a row does not have six fields")] },
  { name := "JOB-simulate.R8 --seed 9 --lat 45 --days 90 shows the values of the home simulation in each row with one decimal",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--seed", "9", "--lat", "45", "--days", "90"]
      let bad := cmpLib90.find? (fun (n, t) =>
        match rowWords r.out n with
        | some w => !compareRowShows w t
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some (n, _) => some s!"the {n} row is wrong in {repr r.out}"
          | none => none },
  { name := "JOB-simulate.R8 the static row shows the same five values as sim policy run --seed 9 --lat 45",
    run := do
      let c ← cachedSim cache ["policy", "compare", "--seed", "9", "--lat", "45"]
      let r ← cachedSim cache ["policy", "run", "--seed", "9", "--lat", "45"]
      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
        valueOf r.out "import", valueOf r.out "export", valueOf r.out "backstop"]
      return match rowWords c.out "static" with
        | some w =>
          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?, w[5]?] then none
          else some s!"compare {w}, run {fromRun}"
        | none => some s!"no static row in {repr c.out}" },
  { name := "JOB-simulate.R8 --heat-hours 0 gives the static row the same five values as the thermostat row",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--heat-hours", "0"]
      let a := tailOfRow r.out "static"
      let b := tailOfRow r.out "thermostat"
      return if r.code == 0 && a.isSome && a == b then none
        else some s!"static {a}, thermostat {b}" },
  { name := "JOB-simulate.R8 --forecast-error 0 gives the perfect-forecast row the same five values as the precomputed row",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--forecast-error", "0"]
      let a := tailOfRow r.out "perfect-forecast"
      let b := tailOfRow r.out "precomputed"
      return if r.code == 0 && a.isSome && a == b then none
        else some s!"perfect-forecast {a}, precomputed {b}" },
  { name := "JOB-simulate.R8 --seed 9 --lat 45 --days 90 shows the perfect-forecast row of the precomputed policy with an error scale of 0",
    run := do
      let r ← cachedSim cache ["policy", "compare", "--seed", "9", "--lat", "45", "--days", "90"]
      return match cmpLib90.find? (fun (n, _) => n == "perfect-forecast"),
          rowWords r.out "perfect-forecast" with
        | some (_, t), some w =>
          if r.code == 0 && compareRowShows w t then none
          else some s!"the perfect-forecast row is {w}, the totals are {repr t}"
        | _, _ => some s!"no perfect-forecast row in {repr r.out}" },
  { name := "JOB-simulate.R8 the static and the dynamic self-consumption are more than the thermostat self-consumption",
    run := do
      let r ← cachedSim cache ["policy", "compare"]
      return match firstOfRow r.out "thermostat", firstOfRow r.out "static",
          firstOfRow r.out "dynamic" with
        | some t, some s, some d =>
          if r.code == 0 && s > t && d > t then none
          else some s!"thermostat {t}, static {s}, dynamic {d}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R8 --policy and --seeds give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "compare", "--policy", "static"], "error: UNKNOWN_OPTION: --policy"),
      (["policy", "compare", "--seeds", "3"], "error: UNKNOWN_OPTION: --seeds")] },

  -- JOB-simulate.R9
  { name := "JOB-simulate.R9 sim policy robust prints the header and the rows thermostat, static, precomputed, dynamic and perfect-forecast",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 6, s!"{ls.length} lines, want 6"),
        (Option.map words ls[0]? == some robustHeader, s!"the header is {ls[0]?}"),
        (firstWords r.out == "policy" :: rowNames, s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 9), "a row does not have nine fields")] },
  { name := "JOB-simulate.R9 each row shows the values of the home simulation for the evaluation over the seeds 1 to 10",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := robustLib.find? (fun (n, e) =>
        match rowWords r.out n with
        | some w => !robustRowShows w e
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some (n, e) => some s!"the {n} row is wrong in {repr r.out}; the evaluation is {repr e}"
          | none => none },
  { name := "JOB-simulate.R9 --seeds 1 --seed 4 gives the mean and the worst self-consumption of each row of sim policy compare --seed 4",
    run := do
      let a ← cachedSim cache ["policy", "robust", "--seeds", "1", "--seed", "4"]
      let c ← cachedSim cache ["policy", "compare", "--seed", "4"]
      let bad := rowNames.find? (fun n =>
        match rowWords a.out n, rowWords c.out n with
        | some x, some y => !(y[1]?.isSome && x[1]? == y[1]? && x[2]? == y[1]?)
        | _, _ => true)
      return if a.code != 0 || c.code != 0 then some s!"exit codes {a.code} and {c.code}"
        else match bad with
          | some n => some s!"the {n} row differs: robust {rowWords a.out n}, compare {rowWords c.out n}"
          | none => none },
  { name := "JOB-simulate.R9 the worst self-consumption of each row is not more than its mean",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := rowNames.find? (fun n =>
        match rowWords r.out n with
        | some w => worstAboveMean w
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some n => some s!"the {n} row has a worst self-consumption above its mean: {rowWords r.out n}"
          | none => none },
  { name := "JOB-simulate.R9 each row has an unmet draw of 0.0, 0 cold hours and safe yes",
    run := do
      let r ← cachedSim cache ["policy", "robust"]
      let bad := rowNames.find? (fun n =>
        match rowWords r.out n with
        | some w => !(w[6]? == some "0.0" && w[7]? == some "0" && w[8]? == some "yes")
        | none => true)
      return if r.code != 0 then some s!"exit code {r.code}, stderr {repr r.err}"
        else match bad with
          | some n => some s!"the {n} row is {rowWords r.out n}"
          | none => none },
  { name := "JOB-simulate.R9 --element 0.2 --days 90 gives the thermostat row safe no and an unmet draw above 0.0",
    run := do
      let r ← sim ["policy", "robust", "--element", "0.2", "--days", "90"]
      let w := (rowWords r.out "thermostat").getD []
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (w.length == 9, s!"the thermostat row is {w}"),
        (w[8]? == some "no", s!"safe is {w[8]?}"),
        ((w[6]?.bind parseNum).getD 0.0 > 0.0, s!"unmet-kWh is {w[6]?}")] },
  -- The line has no --days. The check adds --days 30, so that the two runs stay short.
  { name := "JOB-simulate.R9 --seed 7 --seeds 3 gives the same output two times",
    run := do
      let a ← sim ["policy", "robust", "--seed", "7", "--seeds", "3", "--days", "30"]
      let b ← sim ["policy", "robust", "--seed", "7", "--seeds", "3", "--days", "30"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 6
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  -- The accepted run uses --days 1, so that 100 seeds stay cheap.
  { name := "JOB-simulate.R9 --seeds 0 and --seeds 101 give OUT_OF_RANGE, and --seeds 100 is accepted",
    run := do
      let a ← allErrors [
        (["policy", "robust", "--seeds", "0"], "error: OUT_OF_RANGE: --seeds 0 (1 to 100)"),
        (["policy", "robust", "--seeds", "101"], "error: OUT_OF_RANGE: --seeds 101 (1 to 100)")]
      let r ← sim ["policy", "robust", "--seeds", "100", "--days", "1"]
      return firstSome [a,
        if r.code == 0 && firstWords r.out == "policy" :: rowNames then none
        else some s!"--seeds 100: exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}"] },
  { name := "JOB-simulate.R9 --seeds 2.5 gives BAD_NUMBER",
    run := expectError ["policy", "robust", "--seeds", "2.5"] "error: BAD_NUMBER: --seeds 2.5" },

  -- JOB-simulate.R10
  { name := "JOB-simulate.R10 sim policy tune --seeds 2 --days 30 starts with 704 candidates and 704 safe candidates",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls[0]? == some (row "candidates" "704"), s!"the first line is {ls[0]?}"),
        (ls[1]? == some (row "safe" "704"), s!"the second line is {ls[1]?}"),
        (firstWords r.out == ["candidates", "safe", "heat-start", "heat-hours", "discharge-from",
            "", "policy"] ++ rowNames, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R10 the best profile has a heat-start from 6 to 16, heat-hours from 1 to 8 and discharge-from from 15 to 22",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let hs := (valueOf r.out "heat-start").bind String.toNat?
      let hh := (valueOf r.out "heat-hours").bind String.toNat?
      let df := (valueOf r.out "discharge-from").bind String.toNat?
      return match hs, hh, df with
        | some a, some b, some c =>
          if r.code == 0 && 6 ≤ a && a ≤ 16 && 1 ≤ b && b ≤ 8 && 15 ≤ c && c ≤ 22 then none
          else some s!"heat-start {a}, heat-hours {b}, discharge-from {c}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R10 the profile is the best profile of the home simulation for these options",
    run := do
      let r ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let b := tune1.best
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (valueOf r.out "heat-start" == some (toString b.heatStart),
          s!"heat-start shows {valueOf r.out "heat-start"}, want {b.heatStart}"),
        (valueOf r.out "heat-hours" == some (toString b.heatHours),
          s!"heat-hours shows {valueOf r.out "heat-hours"}, want {b.heatHours}"),
        (valueOf r.out "discharge-from" == some (toString b.dischargeFrom),
          s!"discharge-from shows {valueOf r.out "discharge-from"}, want {b.dischargeFrom}")] },
  { name := "JOB-simulate.R10 the static row equals the static row of sim policy robust with the profile as options",
    run := do
      let t ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let hs := (valueOf t.out "heat-start").getD ""
      let hh := (valueOf t.out "heat-hours").getD ""
      let df := (valueOf t.out "discharge-from").getD ""
      let r ← cachedSim cache ["policy", "robust", "--seeds", "2", "--days", "30",
        "--heat-start", hs, "--heat-hours", hh, "--discharge-from", df]
      let a := rowWords t.out "static"
      let b := rowWords r.out "static"
      return if t.code == 0 && r.code == 0 && a.isSome && a == b then none
        else some s!"tune {a}, robust {b}" },
  { name := "JOB-simulate.R10 the thermostat, precomputed, dynamic and perfect-forecast rows equal the rows of sim policy robust",
    run := do
      let t ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let r ← cachedSim cache ["policy", "robust", "--seeds", "2", "--days", "30"]
      let bad := ["thermostat", "precomputed", "dynamic", "perfect-forecast"].find? (fun n =>
        let a := rowWords t.out n
        !(a.isSome && a == rowWords r.out n))
      return if t.code != 0 || r.code != 0 then some s!"exit codes {t.code} and {r.code}"
        else match bad with
          | some n => some s!"the {n} row differs: tune {rowWords t.out n}, robust {rowWords r.out n}"
          | none => none },
  { name := "JOB-simulate.R10 --seeds 2 --days 30 gives the same output two times",
    run := do
      let a ← cachedSim cache ["policy", "tune", "--seeds", "2", "--days", "30"]
      let b ← sim ["policy", "tune", "--seeds", "2", "--days", "30"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 12
        then none else some s!"first {repr a.out}, second {repr b.out}" },
  { name := "JOB-simulate.R10 --heat-start, --heat-hours and --discharge-from give UNKNOWN_OPTION",
    run := allErrors [
      (["policy", "tune", "--heat-start", "10"], "error: UNKNOWN_OPTION: --heat-start"),
      (["policy", "tune", "--heat-hours", "4"], "error: UNKNOWN_OPTION: --heat-hours"),
      (["policy", "tune", "--discharge-from", "17"], "error: UNKNOWN_OPTION: --discharge-from")] },
  { name := "JOB-simulate.R10 --seeds 0 gives OUT_OF_RANGE",
    run := expectError ["policy", "tune", "--seeds", "0"] "error: OUT_OF_RANGE: --seeds 0 (1 to 100)" },

  -- JOB-simulate.R11
  { name := "JOB-simulate.R11 --tank 0 and --tank 50 are accepted, and --tank 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--tank", "0"], cheap ["--tank", "50"]]
      let b ← expectError (pr ["--tank", "50.1"]) "error: OUT_OF_RANGE: --tank 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --element 0 and --element 20 are accepted, and --element 20.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--element", "0"], cheap ["--element", "20"]]
      let b ← expectError (pr ["--element", "20.1"]) "error: OUT_OF_RANGE: --element 20.1 (0 to 20)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --cut-in 0 and --cut-in 50 are accepted, and --cut-in 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--cut-in", "0"], cheap ["--cut-in", "50"]]
      let b ← expectError (pr ["--cut-in", "50.1"]) "error: OUT_OF_RANGE: --cut-in 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --floor 0 and --floor 50 are accepted, and --floor 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--floor", "0"], cheap ["--floor", "50"]]
      let b ← expectError (pr ["--floor", "50.1"]) "error: OUT_OF_RANGE: --floor 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --draw 0 and --draw 100 are accepted, and --draw 100.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--draw", "0"], cheap ["--draw", "100"]]
      let b ← expectError (pr ["--draw", "100.1"]) "error: OUT_OF_RANGE: --draw 100.1 (0 to 100)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --fetches 1 and --fetches 10 are accepted, and --fetches 0 and --fetches 11 give OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "precomputed", "--fetches", "1"],
        cheap ["--policy", "precomputed", "--fetches", "10"]]
      let b ← allErrors [
        (pr ["--policy", "precomputed", "--fetches", "0"], "error: OUT_OF_RANGE: --fetches 0 (1 to 10)"),
        (pr ["--policy", "precomputed", "--fetches", "11"],
          "error: OUT_OF_RANGE: --fetches 11 (1 to 10)")]
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --draw-cv 0 and --draw-cv 1 are accepted, and --draw-cv 1.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--draw-cv", "0"], cheap ["--draw-cv", "1"]]
      let b ← expectError (pr ["--draw-cv", "1.1"]) "error: OUT_OF_RANGE: --draw-cv 1.1 (0 to 1)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --forecast-error 0 and --forecast-error 5 are accepted, and --forecast-error 5.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--forecast-error", "0"], cheap ["--forecast-error", "5"]]
      let b ← expectError (pr ["--forecast-error", "5.1"])
        "error: OUT_OF_RANGE: --forecast-error 5.1 (0 to 5)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --heat-start 0 and --heat-start 23 are accepted, and --heat-start 24 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--heat-start", "0"], cheap ["--heat-start", "23"]]
      let b ← expectError (pr ["--heat-start", "24"]) "error: OUT_OF_RANGE: --heat-start 24 (0 to 23)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --heat-hours 0 and --heat-hours 24 are accepted, and --heat-hours 25 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--heat-hours", "0"], cheap ["--heat-hours", "24"]]
      let b ← expectError (pr ["--heat-hours", "25"]) "error: OUT_OF_RANGE: --heat-hours 25 (0 to 24)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --discharge-from 0 and --discharge-from 24 are accepted, and --discharge-from 25 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--discharge-from", "0"], cheap ["--discharge-from", "24"]]
      let b ← expectError (pr ["--discharge-from", "25"])
        "error: OUT_OF_RANGE: --discharge-from 25 (0 to 24)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --target 0 and --target 50 are accepted for the dynamic policy, and --target 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "dynamic", "--target", "0"],
        cheap ["--policy", "dynamic", "--target", "50"]]
      let b ← expectError (pr ["--policy", "dynamic", "--target", "50.1"])
        "error: OUT_OF_RANGE: --target 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --min-solar 0 and --min-solar 10 are accepted for the precomputed policy, and --min-solar 10.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "precomputed", "--min-solar", "0"],
        cheap ["--policy", "precomputed", "--min-solar", "10"]]
      let b ← expectError (pr ["--policy", "precomputed", "--min-solar", "10.1"])
        "error: OUT_OF_RANGE: --min-solar 10.1 (0 to 10)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 --low 0 and --low 50 are accepted for the dynamic policy, and --low 50.1 gives OUT_OF_RANGE",
    run := do
      let a ← allOk [cheap ["--policy", "dynamic", "--low", "0"],
        cheap ["--policy", "dynamic", "--low", "50"]]
      let b ← expectError (pr ["--policy", "dynamic", "--low", "50.1"])
        "error: OUT_OF_RANGE: --low 50.1 (0 to 50)"
      return firstSome [a, b] },
  { name := "JOB-simulate.R11 a whole-number option with a decimal point gives BAD_NUMBER",
    run := allErrors [
      (pr ["--heat-hours", "2.5"], "error: BAD_NUMBER: --heat-hours 2.5"),
      (pr ["--fetches", "2.5"], "error: BAD_NUMBER: --fetches 2.5"),
      (pr ["--heat-start", "1.5"], "error: BAD_NUMBER: --heat-start 1.5"),
      (pr ["--discharge-from", "17.5"], "error: BAD_NUMBER: --discharge-from 17.5")] },
  { name := "JOB-simulate.R11 a value that is not a number gives BAD_NUMBER with its option and value",
    run := allErrors [
      (pr ["--tank", "abc"], "error: BAD_NUMBER: --tank abc"),
      (pr ["--element", "1e3"], "error: BAD_NUMBER: --element 1e3"),
      (pr ["--floor", ".5"], "error: BAD_NUMBER: --floor .5"),
      (pr ["--cut-in", "3,5"], "error: BAD_NUMBER: --cut-in 3,5"),
      (pr ["--draw-cv", "x"], "error: BAD_NUMBER: --draw-cv x"),
      (pr ["--draw", "5kW"], "error: BAD_NUMBER: --draw 5kW")] },
  { name := "JOB-simulate.R11 --tank with no value gives MISSING_VALUE",
    run := expectError (pr ["--tank"]) "error: MISSING_VALUE: --tank" },
  { name := "JOB-simulate.R11 --tank -1 gives OUT_OF_RANGE",
    run := expectError (pr ["--tank", "-1"]) "error: OUT_OF_RANGE: --tank -1 (0 to 50)" },
  -- The three runs are 10 days. The run with --tank 5 must differ, or an app that ignores
  -- --tank would also pass.
  { name := "JOB-simulate.R11 --tank 5 --tank 12 gives the result of --tank 12",
    run := do
      let days := ["policy", "run", "--days", "10"]
      let a ← sim (days ++ ["--tank", "5", "--tank", "12"])
      let b ← sim (days ++ ["--tank", "12"])
      let c ← sim (days ++ ["--tank", "5"])
      return firstFail [
        (a.code == 0 && b.code == 0 && c.code == 0, s!"exit codes {a.code}, {b.code} and {c.code}"),
        (firstWords a.out == policyLabels, s!"stdout is {repr a.out}"),
        (a.out == b.out, s!"the last value is not used: {repr a.out} and {repr b.out}"),
        (a.out != c.out, "--tank 5 and --tank 12 give the same result")] },
  -- A window that stops at the end of the day heats in the hours 20 to 23 only. Thus a window of
  -- 10 hours from hour 20 gives the result of a window of 4 hours from hour 20.
  { name := "JOB-simulate.R11 --heat-start 20 --heat-hours 10 exits with 0, because the window stops at the end of the day",
    run := do
      let base := ["policy", "run", "--days", "30", "--heat-start", "20"]
      let a ← sim (base ++ ["--heat-hours", "10"])
      let b ← sim (base ++ ["--heat-hours", "4"])
      return firstFail [
        (a.code == 0 && b.code == 0, s!"exit codes {a.code} and {b.code}, stderr {repr a.err}"),
        (firstWords a.out == policyLabels, s!"stdout is {repr a.out}"),
        (a.out == b.out, s!"10 hours: {repr a.out}, 4 hours: {repr b.out}")] },
  { name := "JOB-simulate.R11 sim policy fly gives UNKNOWN_COMMAND, and sim policy and sim policy help print the usage of the policy commands",
    run := do
      let a ← expectError ["policy", "fly"] "error: UNKNOWN_COMMAND: policy fly"
      let b ← sim ["policy"]
      let c ← sim ["policy", "help"]
      return firstSome [a,
        if b.code == 0 && (lines b.out).head? == some usagePolicy then none
        else some s!"sim policy: exit code {b.code}, stdout {repr b.out}",
        if c.code == 0 && (lines c.out).head? == some usagePolicy && c.out == b.out then none
        else some s!"sim policy help: exit code {c.code}, stdout {repr c.out}"] },
  { name := "JOB-simulate.R11 each error gives empty stdout and exit code 2",
    run := allEmptyOut [
      ["policy", "fly"], pr ["--tank", "50.1"], pr ["--element", "20.1"], pr ["--cut-in", "50.1"],
      pr ["--floor", "50.1"], pr ["--draw", "100.1"], pr ["--draw-cv", "1.1"],
      pr ["--policy", "precomputed", "--fetches", "0"],
      pr ["--policy", "precomputed", "--fetches", "11"], pr ["--forecast-error", "5.1"],
      pr ["--heat-start", "24"], pr ["--heat-hours", "25"], pr ["--discharge-from", "25"],
      pr ["--policy", "dynamic", "--target", "50.1"],
      pr ["--policy", "precomputed", "--min-solar", "10.1"],
      pr ["--policy", "dynamic", "--low", "50.1"], pr ["--heat-hours", "2.5"],
      pr ["--tank", "abc"], pr ["--tank"], pr ["--tank", "-1"]] }
]

def checks (cache : Cache) : List Check :=
  forecastChecks ++ hotwaterChecks ++ simulationChecks ++ policyChecks ++ homesimChecks ++
    jobChecks cache

def main (args : List String) : IO UInt32 := do
  let cache ← mkCache
  let all := checks cache
  let sel := match args with
    | f :: _ => all.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => all
  let mut failed := 0
  for c in sel do
    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
    match res with
    | none => pure ()
    | some msg =>
      failed := failed + 1
      IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
````

## Checks removed from earlier intents

None. The lock changed no acceptance file of an earlier intent.

