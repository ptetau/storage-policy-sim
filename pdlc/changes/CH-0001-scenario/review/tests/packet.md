# Review packet · CH-0001-scenario · tests

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 9b40a79d6f20cdd5fa22569cf342433d1e1b4e94

## Re-review

Earlier review: 0185f3e

An earlier review of this remit judged the checks locked at 0185f3e. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.
Write a "Wrong versions" line only for each check that changed. If no check
changed, write "none" under "Wrong versions".

### Earlier problems

none

### Changes since the earlier review

````
diff --git a/tests/CAP-scenario.lean b/tests/CAP-scenario.lean
index cb90ab0..c67da5a 100644
--- a/tests/CAP-scenario.lean
+++ b/tests/CAP-scenario.lean
@@ -295,7 +295,7 @@ def checks : List Check := [
 
 def main (args : List String) : IO UInt32 := do
   let sel := match args with
-    | f :: _ => checks.filter (fun c => c.name.startsWith (f ++ " "))
+    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
     | [] => checks
   let mut failed := 0
   for c in sel do
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
- Each error code that the Interface lists has a check that expects that exact code.
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

## The change spec

````
# CH-0001 · Seasonal sun, daily weather and household load

Intent: IN-0001 · Scope: CAP-scenario · Status: building · Ticket: none · Branch: pdlc/CH-0001-scenario · Base: main

Tests-Locked: 5de000a

## Delivers

The library gives the hours of a scenario. Each hour has a solar output from the season,
the sun height and a seeded daily sky. Each hour also has a base load and a flexible load.

## Requirements

### CAP-scenario.R1 · Seasonal sun

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

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

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Scenario.lean`. A
check imports `StoragePolicySim.Scenario` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Sky | sunny | cloudy | overcast` with `BEq`, `Repr` and `Inhabited` (assumed).
- `Sky.factor : Sky → Float`: 1.0 for `sunny`, 0.5 for `cloudy`, and 0.15 for `overcast`.
- `structure Site` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `latitude : Float`: degrees, south is negative.
  - `pvKw : Float`: the kW of the panels.
  - `dailyLoadKwh : Float`: the load of a day, with the flexible load included.
  - `flexKwh : Float`: the part of the daily load that a strategy can move.
- `structure Hour` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `day : Nat`: the day of the run, from 0.
  - `dayOfYear : Nat`: `day % 365`, from 0 (1 January) to 364.
  - `hour : Nat`: the hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00.
  - `sky : Sky`: the sky of the day.
  - `pvKwh : Float`: the solar energy of the hour.
  - `baseLoadKwh : Float`: the base load of the hour.
  - `flexKwh : Float`: the flexible load of the hour, at its default hours.
- `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float` gives the solar energy
  of one hour in kWh. It reads only `latitude` and `pvKw` of the site.
- `scenario (site : Site) (seed days : Nat) : Array Hour` gives `24 × days` hours, in order of
  day, then hour. The same arguments give the same array.

### Test seams

- randomness: the `seed` argument of `scenario`. The same seed gives the same skies.
- clock: none, because no line depends on the real date or time.

## Files

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`

## Check files

- `tests/CAP-scenario.lean`

## Steps

### Step 1 · Seasonal sun · [ ]

- Requirement: CAP-scenario.R1
- Check: the checks named `CAP-scenario.R1 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 2 · Daily weather · [ ]

- Requirement: CAP-scenario.R2
- Check: the checks named `CAP-scenario.R2 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 3 · Household load · [ ]

- Requirement: CAP-scenario.R3
- Check: the checks named `CAP-scenario.R3 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned as the first change of IN-0001 (solar self-consumption simulator), because each other change uses its hours.
- The builder found that `tests/CAP-scenario.lean` does not compile. `fun c => c.name` needs the type `Check` in Lean 4.35.0. The check goes back to the test writer, round 1 of 2.
- `lake build` writes `lake-manifest.json`. The file goes into "Files" (assumed), so that the build is the same each time.
- After the fix, the 34 checks of `tests/CAP-scenario.lean` pass on the code of the builder. App code exists after a send-back, so a pass is permitted.
````

## The spec it covers: title and summary

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the world that a strategy must deal with, one hour at a time. It gives
the solar output of each hour from the season and the sun height, and a daily sky from a
seeded weather model. It also gives the household load of each hour, with a seasonal base
load and a flexible load that a strategy can move.

## Code map

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`
````

## The requirements, in full

### CAP-scenario.R1 · Seasonal sun

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

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

## Specs it relies on

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

## The checks

### Diff against main

````
diff --git a/tests/CAP-scenario.lean b/tests/CAP-scenario.lean
new file mode 100644
index 0000000..c67da5a
--- /dev/null
+++ b/tests/CAP-scenario.lean
@@ -0,0 +1,309 @@
+/-
+Component checks of CAP-scenario (sun, weather and load), for CH-0001 (seasonal sun, daily
+weather and household load).
+
+The checks call only `Sky`, `Sky.factor`, `Site`, `Hour`, `pvOutput` and `scenario`. No entry
+of the Interface can fail, so no check expects an error code. The `seed` argument of
+`scenario` is the only seam. No check uses the clock.
+-/
+import StoragePolicySim.Scenario
+open StoragePolicySim
+
+structure Check where
+  name : String
+  run : IO (Option String)   -- none: pass, some msg: fail
+
+-- Helpers for numbers
+
+def near (a b tol : Float) : Bool := (a - b).abs ≤ tol
+
+def firstFail : List (Bool × String) → Option String
+  | [] => none
+  | (true, _) :: rest => firstFail rest
+  | (false, m) :: _ => some m
+
+-- Helpers for the library
+
+/-- The site of the lines: 5 kW of panels, and 20 kWh of daily load with 3 kWh flexible. -/
+def site (lat : Float) (pv : Float := 5) (flex : Float := 3) (load : Float := 20) : Site :=
+  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }
+
+def noon (s : Site) (day : Nat) (sky : Sky) : Float := pvOutput s day 12 sky
+
+/-- The base load of one day of the run. -/
+def dayBase (hs : Array Hour) (d : Nat) : Float :=
+  (List.range 24).foldl (fun acc i => acc + hs[d * 24 + i]!.baseLoadKwh) 0
+
+def totalLoad (hs : Array Hour) : Float :=
+  hs.foldl (fun acc h => acc + h.baseLoadKwh + h.flexKwh) 0
+
+/-- The number of overcast days in the days that `inDays` selects, for seeds 1 to 20. -/
+def overcastDays (lat : Float) (inDays : Nat → Bool) : Nat :=
+  (List.range 20).foldl (fun acc i =>
+    let hs := scenario (site lat) (i + 1) 365
+    acc + ((List.range 365).filter (fun d =>
+      inDays d && hs[d * 24]!.sky == Sky.overcast)).length) 0
+
+-- Day of the year 0 is 1 January. A year has 365 days.
+def inDecToFeb (d : Nat) : Bool := d ≤ 58 || d ≥ 334
+def inJunToAug (d : Nat) : Bool := 151 ≤ d && d ≤ 242
+
+def sameHour (a b : Hour) : Bool :=
+  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
+  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh
+
+/-- Finds the first item whose solar output is not the seasonal sun of its hour. -/
+def badSolar (s : Site) (hs : Array Hour) : Option Nat :=
+  (List.range hs.size).find? (fun i =>
+    let h := hs[i]!
+    !near h.pvKwh (pvOutput s h.dayOfYear h.hour h.sky) 0.000001)
+
+/-- Finds the first hour whose flexible load is not `each` kWh at 18:00, 19:00 and 20:00. -/
+def badFlex (hs : Array Hour) (each : Float) : Option Nat :=
+  (List.range hs.size).find? (fun i =>
+    let want : Float := if i % 24 == 18 || i % 24 == 19 || i % 24 == 20 then each else 0
+    !near hs[i]!.flexKwh want 1e-9)
+
+def checks : List Check := [
+  -- CAP-scenario.R1
+  { name := "CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354",
+    run := do
+      let a := noon (site 45) 171 Sky.sunny
+      let b := noon (site 45) 354 Sky.sunny
+      return if b > 0 && a > 2 * b then none else some s!"day 171 {a}, day 354 {b}" },
+  { name := "CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171",
+    run := do
+      let a := noon (site (-41)) 354 Sky.sunny
+      let b := noon (site (-41)) 171 Sky.sunny
+      return if b > 0 && a > 2 * b then none else some s!"day 354 {a}, day 171 {b}" },
+  { name := "CAP-scenario.R1 at latitude 0 days 171 and 354 differ by less than 1%",
+    run := do
+      let a := noon (site 0) 171 Sky.sunny
+      let b := noon (site 0) 354 Sky.sunny
+      let big := if a > b then a else b
+      return if a > 0 && b > 0 && (a - b).abs < 0.01 * big then none
+        else some s!"day 171 {a}, day 354 {b}" },
+  { name := "CAP-scenario.R1 at latitude 45 00:00 of day 171 gives 0 kWh",
+    run := do
+      let v := pvOutput (site 45) 171 0 Sky.sunny
+      return if v == 0 then none else some s!"got {v}" },
+  { name := "CAP-scenario.R1 each sunny hour of days 0 to 364 at latitude 45 gives 0 to 5 kWh",
+    run := do
+      let bad := (List.range (365 * 24)).find? (fun i =>
+        let v := pvOutput (site 45) (i / 24) (i % 24) Sky.sunny
+        !(v ≥ 0 && v ≤ 5))
+      return match bad with
+        | some i =>
+          some s!"day {i / 24} hour {i % 24} gives {pvOutput (site 45) (i / 24) (i % 24) Sky.sunny}"
+        | none => none },
+  -- A version that omits the panel power gives 1 kWh or less, and stays from 0 to 5 kWh.
+  { name := "CAP-scenario.R1 the sunny noon of day 171 at latitude 45 uses the 5 kW of panels",
+    run := do
+      let full := noon (site 45) 171 Sky.sunny
+      let half := noon (site 45 (pv := 2.5)) 171 Sky.sunny
+      return firstFail [
+        (full > 4 && full ≤ 5, s!"5 kW gives {full}"),
+        (near half (0.5 * full) 0.001, s!"2.5 kW gives {half}, 5 kW gives {full}")] },
+  { name := "CAP-scenario.R1 a cloudy sky gives 0.5 times the sunny output",
+    run := do
+      let s := noon (site 45) 171 Sky.sunny
+      let c := noon (site 45) 171 Sky.cloudy
+      return if s > 1 && near c (0.5 * s) 0.001 then none else some s!"sunny {s}, cloudy {c}" },
+  { name := "CAP-scenario.R1 an overcast sky gives 0.15 times the sunny output",
+    run := do
+      let s := noon (site 45) 171 Sky.sunny
+      let o := noon (site 45) 171 Sky.overcast
+      return if s > 1 && near o (0.15 * s) 0.001 then none
+        else some s!"sunny {s}, overcast {o}" },
+  { name := "CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15",
+    run := do
+      return firstFail [
+        (Sky.factor Sky.sunny == 1.0, s!"sunny {Sky.factor Sky.sunny}"),
+        (Sky.factor Sky.cloudy == 0.5, s!"cloudy {Sky.factor Sky.cloudy}"),
+        (Sky.factor Sky.overcast == 0.15, s!"overcast {Sky.factor Sky.overcast}")] },
+  { name := "CAP-scenario.R1 0 kW of panels gives 0 kWh at 12:00 of day 171",
+    run := do
+      let v := noon (site 45 (pv := 0)) 171 Sky.sunny
+      return if v == 0 then none else some s!"got {v}" },
+  { name := "CAP-scenario.R1 the output does not change with the load of the site",
+    run := do
+      let a := noon (site 45) 171 Sky.sunny
+      let b := noon (site 45 (flex := 0) (load := 99)) 171 Sky.sunny
+      return if a > 0 && a == b then none else some s!"load 20 gives {a}, load 99 gives {b}" },
+
+  -- CAP-scenario.R2
+  { name := "CAP-scenario.R2 seed 7 at latitude 45 gives the same hours two times",
+    run := do
+      let a := scenario (site 45) 7 365
+      let b := scenario (site 45) 7 365
+      return if a.size == 8760 && b.size == 8760 &&
+          (List.range 8760).all (fun i => sameHour a[i]! b[i]!) then none
+        else some s!"the two runs differ, sizes {a.size} and {b.size}" },
+  { name := "CAP-scenario.R2 seeds 7 and 8 at latitude 45 give different skies on at least 50 days",
+    run := do
+      let a := scenario (site 45) 7 365
+      let b := scenario (site 45) 8 365
+      if a.size != 8760 || b.size != 8760 then
+        return some s!"sizes {a.size} and {b.size}"
+      let n := ((List.range 365).filter (fun d => !(a[d * 24]!.sky == b[d * 24]!.sky))).length
+      return if n ≥ 50 then none else some s!"{n} days differ" },
+  { name := "CAP-scenario.R2 seed 7 and 365 days give 8760 hours in order of day, then hour",
+    run := do
+      let hs := scenario (site 45) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match (List.range 8760).find? (fun i =>
+            !(hs[i]!.day == i / 24 && hs[i]!.hour == i % 24)) with
+          | some i => some s!"item {i} is day {hs[i]!.day} hour {hs[i]!.hour}"
+          | none => none },
+  { name := "CAP-scenario.R2 seed 7 and 0 days give no hours",
+    run := do
+      let hs := scenario (site 45) 7 0
+      return if hs.size == 0 then none else some s!"{hs.size} hours" },
+  { name := "CAP-scenario.R2 seed 7 and 1 day give the 24 hours of day 0",
+    run := do
+      let hs := scenario (site 45) 7 1
+      return if hs.size == 24 && (List.range 24).all (fun i =>
+          hs[i]!.day == 0 && hs[i]!.dayOfYear == 0 && hs[i]!.hour == i) then none
+        else some s!"{hs.size} hours" },
+  { name := "CAP-scenario.R2 the 24 hours of each day have the same sky",
+    run := do
+      let hs := scenario (site 45) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match (List.range 8760).find? (fun i => !(hs[i]!.sky == hs[(i / 24) * 24]!.sky)) with
+          | some i => some s!"day {i / 24} hour {i % 24} has a different sky"
+          | none => none },
+  { name := "CAP-scenario.R2 each solar output of seed 7 equals the seasonal sun of its hour",
+    run := do
+      let hs := scenario (site 45) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badSolar (site 45) hs with
+          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
+          | none => none },
+  { name := "CAP-scenario.R2 each solar output at latitude -41 equals the seasonal sun of its hour",
+    run := do
+      let hs := scenario (site (-41)) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badSolar (site (-41)) hs with
+          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
+          | none => none },
+  { name := "CAP-scenario.R2 at latitude 45 December to February has over twice the overcast days",
+    run := do
+      let w := overcastDays 45 inDecToFeb
+      let s := overcastDays 45 inJunToAug
+      return if w > 2 * s then none else some s!"Dec to Feb {w}, Jun to Aug {s}" },
+  { name := "CAP-scenario.R2 at latitude -41 June to August has over twice the overcast days",
+    run := do
+      let w := overcastDays (-41) inJunToAug
+      let s := overcastDays (-41) inDecToFeb
+      return if w > 2 * s then none else some s!"Jun to Aug {w}, Dec to Feb {s}" },
+  -- With no chance to keep the sky, about 40% of the days keep the sky of the day before.
+  { name := "CAP-scenario.R2 60% or more of days 1 to 364 of seed 7 keep the previous sky",
+    run := do
+      let hs := scenario (site 45) 7 365
+      if hs.size != 8760 then return some s!"{hs.size} hours"
+      let n := ((List.range 364).filter (fun d =>
+        hs[(d + 1) * 24]!.sky == hs[d * 24]!.sky)).length
+      return if n.toFloat ≥ 0.6 * 364 then none else some s!"{n} of 364 days keep" },
+  { name := "CAP-scenario.R2 with 730 days day 365 is day 0 and day 729 is day 364 of the year",
+    run := do
+      let hs := scenario (site 45) 7 730
+      if hs.size != 730 * 24 then return some s!"{hs.size} hours"
+      return firstFail [
+        (hs[365 * 24]!.day == 365 && hs[365 * 24]!.dayOfYear == 0,
+          s!"item {365 * 24} is day {hs[365 * 24]!.day}, day {hs[365 * 24]!.dayOfYear} of the year"),
+        (hs[729 * 24 + 23]!.day == 729 && hs[729 * 24 + 23]!.dayOfYear == 364,
+          s!"the last item is day {hs[729 * 24 + 23]!.day}, day {hs[729 * 24 + 23]!.dayOfYear} of the year"),
+        ((List.range hs.size).all (fun i =>
+            hs[i]!.day == i / 24 && hs[i]!.dayOfYear == (i / 24) % 365 && hs[i]!.hour == i % 24),
+          "an hour has the wrong day, day of the year or hour")] },
+  { name := "CAP-scenario.R2 with 730 days the solar output of the second year uses the day of the year",
+    run := do
+      let hs := scenario (site 45) 7 730
+      return if hs.size != 730 * 24 then some s!"{hs.size} hours"
+        else match badSolar (site 45) hs with
+          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
+          | none => none },
+
+  -- CAP-scenario.R3
+  { name := "CAP-scenario.R3 365 days at latitude 45 have 7300 kWh of load",
+    run := do
+      let hs := scenario (site 45) 7 365
+      let t := totalLoad hs
+      return if hs.size == 8760 && near t 7300 0.1 then none else some s!"total {t}" },
+  -- The daily load includes the flexible load. Thus, 0 kWh of flexible load keeps 7300 kWh.
+  { name := "CAP-scenario.R3 365 days with 0 kWh of flexible load also have 7300 kWh of load",
+    run := do
+      let hs := scenario (site 45 (flex := 0)) 7 365
+      let t := totalLoad hs
+      return if hs.size == 8760 && near t 7300 0.1 then none else some s!"total {t}" },
+  { name := "CAP-scenario.R3 at latitude 45 day 15 has 1.45 to 1.55 times the base load of day 197",
+    run := do
+      let hs := scenario (site 45) 7 365
+      if hs.size != 8760 then return some s!"{hs.size} hours"
+      let q := dayBase hs 15 / dayBase hs 197
+      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
+  { name := "CAP-scenario.R3 at latitude -41 day 197 has 1.45 to 1.55 times the base load of day 15",
+    run := do
+      let hs := scenario (site (-41)) 7 365
+      if hs.size != 8760 then return some s!"{hs.size} hours"
+      let q := dayBase hs 197 / dayBase hs 15
+      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
+  { name := "CAP-scenario.R3 on day 100 the base load at 19:00 is more than at 13:00",
+    run := do
+      let hs := scenario (site 45) 7 365
+      if hs.size != 8760 then return some s!"{hs.size} hours"
+      let a := hs[100 * 24 + 19]!.baseLoadKwh
+      let b := hs[100 * 24 + 13]!.baseLoadKwh
+      return if a > b then none else some s!"19:00 {a}, 13:00 {b}" },
+  { name := "CAP-scenario.R3 on day 100 the base load at 07:00 is more than at 03:00",
+    run := do
+      let hs := scenario (site 45) 7 365
+      if hs.size != 8760 then return some s!"{hs.size} hours"
+      let a := hs[100 * 24 + 7]!.baseLoadKwh
+      let b := hs[100 * 24 + 3]!.baseLoadKwh
+      return if a > b then none else some s!"07:00 {a}, 03:00 {b}" },
+  { name := "CAP-scenario.R3 3 kWh of flexible load is 1 kWh at 18:00, 19:00 and 20:00",
+    run := do
+      let hs := scenario (site 45) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badFlex hs 1 with
+          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
+          | none => none },
+  -- Equal parts: a version that always puts 1 kWh in each hour fails here.
+  { name := "CAP-scenario.R3 6 kWh of flexible load is 2 kWh at 18:00, 19:00 and 20:00",
+    run := do
+      let hs := scenario (site 45 (flex := 6)) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badFlex hs 2 with
+          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
+          | none => none },
+  { name := "CAP-scenario.R3 0 kWh of flexible load gives 0 kWh in each hour",
+    run := do
+      let hs := scenario (site 45 (flex := 0)) 7 365
+      return if hs.size != 8760 then some s!"{hs.size} hours"
+        else match badFlex hs 0 with
+          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
+          | none => none },
+  { name := "CAP-scenario.R3 seeds 7 and 8 at latitude 45 give the same base and flexible load",
+    run := do
+      let a := scenario (site 45) 7 365
+      let b := scenario (site 45) 8 365
+      return if a.size == 8760 && b.size == 8760 && (List.range 8760).all (fun i =>
+          a[i]!.baseLoadKwh == b[i]!.baseLoadKwh && a[i]!.flexKwh == b[i]!.flexKwh) then none
+        else some "the loads differ" }
+]
+
+def main (args : List String) : IO UInt32 := do
+  let sel := match args with
+    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
+    | [] => checks
+  let mut failed := 0
+  for c in sel do
+    let res ← tryCatch c.run (fun e => pure (some s!"exception: {e}"))
+    match res with
+    | none => pure ()
+    | some msg =>
+      failed := failed + 1
+      IO.println s!"FAIL {c.name}: {msg}"
+  IO.println s!"{sel.length} checks, {failed} failed"
+  return if failed > 0 then 1 else 0
````

### tests/CAP-scenario.lean

````
/-
Component checks of CAP-scenario (sun, weather and load), for CH-0001 (seasonal sun, daily
weather and household load).

The checks call only `Sky`, `Sky.factor`, `Site`, `Hour`, `pvOutput` and `scenario`. No entry
of the Interface can fail, so no check expects an error code. The `seed` argument of
`scenario` is the only seam. No check uses the clock.
-/
import StoragePolicySim.Scenario
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

-- Helpers for the library

/-- The site of the lines: 5 kW of panels, and 20 kWh of daily load with 3 kWh flexible. -/
def site (lat : Float) (pv : Float := 5) (flex : Float := 3) (load : Float := 20) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }

def noon (s : Site) (day : Nat) (sky : Sky) : Float := pvOutput s day 12 sky

/-- The base load of one day of the run. -/
def dayBase (hs : Array Hour) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc i => acc + hs[d * 24 + i]!.baseLoadKwh) 0

def totalLoad (hs : Array Hour) : Float :=
  hs.foldl (fun acc h => acc + h.baseLoadKwh + h.flexKwh) 0

/-- The number of overcast days in the days that `inDays` selects, for seeds 1 to 20. -/
def overcastDays (lat : Float) (inDays : Nat → Bool) : Nat :=
  (List.range 20).foldl (fun acc i =>
    let hs := scenario (site lat) (i + 1) 365
    acc + ((List.range 365).filter (fun d =>
      inDays d && hs[d * 24]!.sky == Sky.overcast)).length) 0

-- Day of the year 0 is 1 January. A year has 365 days.
def inDecToFeb (d : Nat) : Bool := d ≤ 58 || d ≥ 334
def inJunToAug (d : Nat) : Bool := 151 ≤ d && d ≤ 242

def sameHour (a b : Hour) : Bool :=
  a.day == b.day && a.dayOfYear == b.dayOfYear && a.hour == b.hour && a.sky == b.sky &&
  a.pvKwh == b.pvKwh && a.baseLoadKwh == b.baseLoadKwh && a.flexKwh == b.flexKwh

/-- Finds the first item whose solar output is not the seasonal sun of its hour. -/
def badSolar (s : Site) (hs : Array Hour) : Option Nat :=
  (List.range hs.size).find? (fun i =>
    let h := hs[i]!
    !near h.pvKwh (pvOutput s h.dayOfYear h.hour h.sky) 0.000001)

/-- Finds the first hour whose flexible load is not `each` kWh at 18:00, 19:00 and 20:00. -/
def badFlex (hs : Array Hour) (each : Float) : Option Nat :=
  (List.range hs.size).find? (fun i =>
    let want : Float := if i % 24 == 18 || i % 24 == 19 || i % 24 == 20 then each else 0
    !near hs[i]!.flexKwh want 1e-9)

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 at latitude 45 day 171 gives more than twice day 354",
    run := do
      let a := noon (site 45) 171 Sky.sunny
      let b := noon (site 45) 354 Sky.sunny
      return if b > 0 && a > 2 * b then none else some s!"day 171 {a}, day 354 {b}" },
  { name := "CAP-scenario.R1 at latitude -41 day 354 gives more than twice day 171",
    run := do
      let a := noon (site (-41)) 354 Sky.sunny
      let b := noon (site (-41)) 171 Sky.sunny
      return if b > 0 && a > 2 * b then none else some s!"day 354 {a}, day 171 {b}" },
  { name := "CAP-scenario.R1 at latitude 0 days 171 and 354 differ by less than 1%",
    run := do
      let a := noon (site 0) 171 Sky.sunny
      let b := noon (site 0) 354 Sky.sunny
      let big := if a > b then a else b
      return if a > 0 && b > 0 && (a - b).abs < 0.01 * big then none
        else some s!"day 171 {a}, day 354 {b}" },
  { name := "CAP-scenario.R1 at latitude 45 00:00 of day 171 gives 0 kWh",
    run := do
      let v := pvOutput (site 45) 171 0 Sky.sunny
      return if v == 0 then none else some s!"got {v}" },
  { name := "CAP-scenario.R1 each sunny hour of days 0 to 364 at latitude 45 gives 0 to 5 kWh",
    run := do
      let bad := (List.range (365 * 24)).find? (fun i =>
        let v := pvOutput (site 45) (i / 24) (i % 24) Sky.sunny
        !(v ≥ 0 && v ≤ 5))
      return match bad with
        | some i =>
          some s!"day {i / 24} hour {i % 24} gives {pvOutput (site 45) (i / 24) (i % 24) Sky.sunny}"
        | none => none },
  -- A version that omits the panel power gives 1 kWh or less, and stays from 0 to 5 kWh.
  { name := "CAP-scenario.R1 the sunny noon of day 171 at latitude 45 uses the 5 kW of panels",
    run := do
      let full := noon (site 45) 171 Sky.sunny
      let half := noon (site 45 (pv := 2.5)) 171 Sky.sunny
      return firstFail [
        (full > 4 && full ≤ 5, s!"5 kW gives {full}"),
        (near half (0.5 * full) 0.001, s!"2.5 kW gives {half}, 5 kW gives {full}")] },
  { name := "CAP-scenario.R1 a cloudy sky gives 0.5 times the sunny output",
    run := do
      let s := noon (site 45) 171 Sky.sunny
      let c := noon (site 45) 171 Sky.cloudy
      return if s > 1 && near c (0.5 * s) 0.001 then none else some s!"sunny {s}, cloudy {c}" },
  { name := "CAP-scenario.R1 an overcast sky gives 0.15 times the sunny output",
    run := do
      let s := noon (site 45) 171 Sky.sunny
      let o := noon (site 45) 171 Sky.overcast
      return if s > 1 && near o (0.15 * s) 0.001 then none
        else some s!"sunny {s}, overcast {o}" },
  { name := "CAP-scenario.R1 the sky factors are 1.0, 0.5 and 0.15",
    run := do
      return firstFail [
        (Sky.factor Sky.sunny == 1.0, s!"sunny {Sky.factor Sky.sunny}"),
        (Sky.factor Sky.cloudy == 0.5, s!"cloudy {Sky.factor Sky.cloudy}"),
        (Sky.factor Sky.overcast == 0.15, s!"overcast {Sky.factor Sky.overcast}")] },
  { name := "CAP-scenario.R1 0 kW of panels gives 0 kWh at 12:00 of day 171",
    run := do
      let v := noon (site 45 (pv := 0)) 171 Sky.sunny
      return if v == 0 then none else some s!"got {v}" },
  { name := "CAP-scenario.R1 the output does not change with the load of the site",
    run := do
      let a := noon (site 45) 171 Sky.sunny
      let b := noon (site 45 (flex := 0) (load := 99)) 171 Sky.sunny
      return if a > 0 && a == b then none else some s!"load 20 gives {a}, load 99 gives {b}" },

  -- CAP-scenario.R2
  { name := "CAP-scenario.R2 seed 7 at latitude 45 gives the same hours two times",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 7 365
      return if a.size == 8760 && b.size == 8760 &&
          (List.range 8760).all (fun i => sameHour a[i]! b[i]!) then none
        else some s!"the two runs differ, sizes {a.size} and {b.size}" },
  { name := "CAP-scenario.R2 seeds 7 and 8 at latitude 45 give different skies on at least 50 days",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 8 365
      if a.size != 8760 || b.size != 8760 then
        return some s!"sizes {a.size} and {b.size}"
      let n := ((List.range 365).filter (fun d => !(a[d * 24]!.sky == b[d * 24]!.sky))).length
      return if n ≥ 50 then none else some s!"{n} days differ" },
  { name := "CAP-scenario.R2 seed 7 and 365 days give 8760 hours in order of day, then hour",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i =>
            !(hs[i]!.day == i / 24 && hs[i]!.hour == i % 24)) with
          | some i => some s!"item {i} is day {hs[i]!.day} hour {hs[i]!.hour}"
          | none => none },
  { name := "CAP-scenario.R2 seed 7 and 0 days give no hours",
    run := do
      let hs := scenario (site 45) 7 0
      return if hs.size == 0 then none else some s!"{hs.size} hours" },
  { name := "CAP-scenario.R2 seed 7 and 1 day give the 24 hours of day 0",
    run := do
      let hs := scenario (site 45) 7 1
      return if hs.size == 24 && (List.range 24).all (fun i =>
          hs[i]!.day == 0 && hs[i]!.dayOfYear == 0 && hs[i]!.hour == i) then none
        else some s!"{hs.size} hours" },
  { name := "CAP-scenario.R2 the 24 hours of each day have the same sky",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match (List.range 8760).find? (fun i => !(hs[i]!.sky == hs[(i / 24) * 24]!.sky)) with
          | some i => some s!"day {i / 24} hour {i % 24} has a different sky"
          | none => none },
  { name := "CAP-scenario.R2 each solar output of seed 7 equals the seasonal sun of its hour",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badSolar (site 45) hs with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R2 each solar output at latitude -41 equals the seasonal sun of its hour",
    run := do
      let hs := scenario (site (-41)) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badSolar (site (-41)) hs with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R2 at latitude 45 December to February has over twice the overcast days",
    run := do
      let w := overcastDays 45 inDecToFeb
      let s := overcastDays 45 inJunToAug
      return if w > 2 * s then none else some s!"Dec to Feb {w}, Jun to Aug {s}" },
  { name := "CAP-scenario.R2 at latitude -41 June to August has over twice the overcast days",
    run := do
      let w := overcastDays (-41) inJunToAug
      let s := overcastDays (-41) inDecToFeb
      return if w > 2 * s then none else some s!"Jun to Aug {w}, Dec to Feb {s}" },
  -- With no chance to keep the sky, about 40% of the days keep the sky of the day before.
  { name := "CAP-scenario.R2 60% or more of days 1 to 364 of seed 7 keep the previous sky",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let n := ((List.range 364).filter (fun d =>
        hs[(d + 1) * 24]!.sky == hs[d * 24]!.sky)).length
      return if n.toFloat ≥ 0.6 * 364 then none else some s!"{n} of 364 days keep" },
  { name := "CAP-scenario.R2 with 730 days day 365 is day 0 and day 729 is day 364 of the year",
    run := do
      let hs := scenario (site 45) 7 730
      if hs.size != 730 * 24 then return some s!"{hs.size} hours"
      return firstFail [
        (hs[365 * 24]!.day == 365 && hs[365 * 24]!.dayOfYear == 0,
          s!"item {365 * 24} is day {hs[365 * 24]!.day}, day {hs[365 * 24]!.dayOfYear} of the year"),
        (hs[729 * 24 + 23]!.day == 729 && hs[729 * 24 + 23]!.dayOfYear == 364,
          s!"the last item is day {hs[729 * 24 + 23]!.day}, day {hs[729 * 24 + 23]!.dayOfYear} of the year"),
        ((List.range hs.size).all (fun i =>
            hs[i]!.day == i / 24 && hs[i]!.dayOfYear == (i / 24) % 365 && hs[i]!.hour == i % 24),
          "an hour has the wrong day, day of the year or hour")] },
  { name := "CAP-scenario.R2 with 730 days the solar output of the second year uses the day of the year",
    run := do
      let hs := scenario (site 45) 7 730
      return if hs.size != 730 * 24 then some s!"{hs.size} hours"
        else match badSolar (site 45) hs with
          | some i => some s!"item {i} has {hs[i]!.pvKwh} kWh"
          | none => none },

  -- CAP-scenario.R3
  { name := "CAP-scenario.R3 365 days at latitude 45 have 7300 kWh of load",
    run := do
      let hs := scenario (site 45) 7 365
      let t := totalLoad hs
      return if hs.size == 8760 && near t 7300 0.1 then none else some s!"total {t}" },
  -- The daily load includes the flexible load. Thus, 0 kWh of flexible load keeps 7300 kWh.
  { name := "CAP-scenario.R3 365 days with 0 kWh of flexible load also have 7300 kWh of load",
    run := do
      let hs := scenario (site 45 (flex := 0)) 7 365
      let t := totalLoad hs
      return if hs.size == 8760 && near t 7300 0.1 then none else some s!"total {t}" },
  { name := "CAP-scenario.R3 at latitude 45 day 15 has 1.45 to 1.55 times the base load of day 197",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let q := dayBase hs 15 / dayBase hs 197
      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
  { name := "CAP-scenario.R3 at latitude -41 day 197 has 1.45 to 1.55 times the base load of day 15",
    run := do
      let hs := scenario (site (-41)) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let q := dayBase hs 197 / dayBase hs 15
      return if q ≥ 1.45 && q ≤ 1.55 then none else some s!"ratio {q}" },
  { name := "CAP-scenario.R3 on day 100 the base load at 19:00 is more than at 13:00",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let a := hs[100 * 24 + 19]!.baseLoadKwh
      let b := hs[100 * 24 + 13]!.baseLoadKwh
      return if a > b then none else some s!"19:00 {a}, 13:00 {b}" },
  { name := "CAP-scenario.R3 on day 100 the base load at 07:00 is more than at 03:00",
    run := do
      let hs := scenario (site 45) 7 365
      if hs.size != 8760 then return some s!"{hs.size} hours"
      let a := hs[100 * 24 + 7]!.baseLoadKwh
      let b := hs[100 * 24 + 3]!.baseLoadKwh
      return if a > b then none else some s!"07:00 {a}, 03:00 {b}" },
  { name := "CAP-scenario.R3 3 kWh of flexible load is 1 kWh at 18:00, 19:00 and 20:00",
    run := do
      let hs := scenario (site 45) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badFlex hs 1 with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  -- Equal parts: a version that always puts 1 kWh in each hour fails here.
  { name := "CAP-scenario.R3 6 kWh of flexible load is 2 kWh at 18:00, 19:00 and 20:00",
    run := do
      let hs := scenario (site 45 (flex := 6)) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badFlex hs 2 with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R3 0 kWh of flexible load gives 0 kWh in each hour",
    run := do
      let hs := scenario (site 45 (flex := 0)) 7 365
      return if hs.size != 8760 then some s!"{hs.size} hours"
        else match badFlex hs 0 with
          | some i => some s!"day {i / 24} hour {i % 24} has {hs[i]!.flexKwh} kWh"
          | none => none },
  { name := "CAP-scenario.R3 seeds 7 and 8 at latitude 45 give the same base and flexible load",
    run := do
      let a := scenario (site 45) 7 365
      let b := scenario (site 45) 8 365
      return if a.size == 8760 && b.size == 8760 && (List.range 8760).all (fun i =>
          a[i]!.baseLoadKwh == b[i]!.baseLoadKwh && a[i]!.flexKwh == b[i]!.flexKwh) then none
        else some "the loads differ" }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
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

