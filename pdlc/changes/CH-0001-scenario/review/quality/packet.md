# Review packet · CH-0001-scenario · quality

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 4c713c02812200de87d0a7841fe33ea7fb39b399

# Remit: quality

Default: yes

You judge if the code is easy to read and change.

- Names tell what things are and what they do.
- There is no unnecessary repetition and no dead code.
- The code handles the errors that the requirements name, and the error messages help the
  person who sees them.
- The code follows the design specs in this packet.
- The code is as simple as the requirement lets it be.

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

### Step 1 · Seasonal sun · [x]

- Requirement: CAP-scenario.R1
- Check: the checks named `CAP-scenario.R1 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 2 · Daily weather · [x]

- Requirement: CAP-scenario.R2
- Check: the checks named `CAP-scenario.R2 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 3 · Household load · [x]

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
- Build: the 34 checks of `tests/CAP-scenario.lean` pass. No check changed since the lock `5de000a`.
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

Status: built · Intents: IN-0001

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

Status: built · Intents: IN-0001

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

Status: built · Intents: IN-0001

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

## The code

### Diff against main

````
diff --git a/StoragePolicySim/Scenario.lean b/StoragePolicySim/Scenario.lean
new file mode 100644
index 0000000..a3922c0
--- /dev/null
+++ b/StoragePolicySim/Scenario.lean
@@ -0,0 +1,162 @@
+/-
+The scenario of a site: the solar output, the daily sky and the household load of each hour.
+CAP-scenario (sun, weather and load) gives the rules.
+-/
+namespace StoragePolicySim
+
+/-- The sky of a day. -/
+inductive Sky
+  | sunny
+  | cloudy
+  | overcast
+  deriving BEq, Repr, Inhabited
+
+/-- The share of the sunny output that the sky lets through. -/
+def Sky.factor : Sky → Float
+  | .sunny => 1.0
+  | .cloudy => 0.5
+  | .overcast => 0.15
+
+/-- A site with its panels and its household load. -/
+structure Site where
+  /-- Degrees. South is negative. -/
+  latitude : Float
+  /-- The kW of the panels. -/
+  pvKw : Float
+  /-- The load of a day, with the flexible load included. -/
+  dailyLoadKwh : Float
+  /-- The part of the daily load that a strategy can move. -/
+  flexKwh : Float
+  deriving Repr, Inhabited
+
+/-- One hour of a scenario. -/
+structure Hour where
+  /-- The day of the run, from 0. -/
+  day : Nat
+  /-- `day % 365`, from 0 (1 January) to 364. -/
+  dayOfYear : Nat
+  /-- The hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00. -/
+  hour : Nat
+  /-- The sky of the day. -/
+  sky : Sky
+  /-- The solar energy of the hour. -/
+  pvKwh : Float
+  /-- The base load of the hour. -/
+  baseLoadKwh : Float
+  /-- The flexible load of the hour, at its default hours. -/
+  flexKwh : Float
+  deriving Repr, Inhabited
+
+def daysInYear : Nat := 365
+
+private def pi : Float := 3.141592653589793
+
+private def radians (deg : Float) : Float := deg * pi / 180
+
+/-- The declination of the sun in degrees. Day 0 is 1 January. -/
+private def declination (dayOfYear : Nat) : Float :=
+  23.44 * Float.sin (2 * pi * (285 + dayOfYear.toFloat) / daysInYear.toFloat)
+
+/-- The sine of the sun height at the middle of the hour, in solar time. -/
+private def sinSunHeight (latitude : Float) (dayOfYear hour : Nat) : Float :=
+  let lat := radians latitude
+  let dec := radians (declination dayOfYear)
+  let hourAngle := radians (15 * (hour.toFloat + 0.5 - 12))
+  Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle
+
+/-- The solar energy of one hour in kWh. It reads only `latitude` and `pvKw` of the site. -/
+def pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float :=
+  let h := sinSunHeight site.latitude dayOfYear hour
+  if h ≤ 0 then 0 else site.pvKw * h * sky.factor
+
+/-! ## Weather -/
+
+/-- The state of the seeded random numbers (SplitMix64). -/
+private structure Rng where
+  state : UInt64
+
+/-- The next number from 0 to less than 1, and the next state. -/
+private def Rng.next (r : Rng) : Float × Rng :=
+  let s := r.state + 0x9E3779B97F4A7C15
+  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
+  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
+  let z := z ^^^ (z >>> 31)
+  ((z >>> 11).toFloat / 9007199254740992.0, ⟨s⟩)
+
+/-- The chance that a day keeps the sky of the day before. -/
+private def keepChance : Float := 0.6
+
+/-- True for a day in the summer half of the year at this latitude. -/
+private def inSummerHalf (latitude : Float) (dayOfYear : Nat) : Bool :=
+  let north := 90 ≤ dayOfYear && dayOfYear ≤ 272
+  if latitude ≥ 0 then north else !north
+
+/-- A new sky from the chances of the half of the year. -/
+private def newSky (summer : Bool) (u : Float) : Sky :=
+  let (sunny, cloudy) := if summer then (0.55, 0.30) else (0.20, 0.35)
+  if u < sunny then .sunny
+  else if u < sunny + cloudy then .cloudy
+  else .overcast
+
+/-- The sky of each day of the run. -/
+private def skies (latitude : Float) (seed days : Nat) : Array Sky := Id.run do
+  let mut rng : Rng := ⟨seed.toUInt64⟩
+  let mut out : Array Sky := Array.mkEmpty days
+  for d in [0:days] do
+    let (u, r) := rng.next
+    rng := r
+    match out.back? with
+    | some prev =>
+      if u < keepChance then
+        out := out.push prev
+        continue
+    | none => pure ()
+    let (v, r) := rng.next
+    rng := r
+    out := out.push (newSky (inSummerHalf latitude (d % daysInYear)) v)
+  return out
+
+/-! ## Load -/
+
+/-- The share of the base load of a day in each hour, in parts of 1000. The profile has a
+morning peak at 07:00 and an evening peak at 19:00. -/
+private def profile : Array Float :=
+  #[30, 22, 20, 20, 20, 25, 40, 55, 50, 40, 30, 30,
+    32, 30, 33, 30, 38, 55, 75, 85, 80, 65, 55, 40]
+
+/-- The day of the year with the most base load. -/
+private def peakDay (latitude : Float) : Nat := if latitude ≥ 0 then 15 else 197
+
+/-- The seasonal factor that scales the base load of a day. -/
+private def seasonalFactor (latitude : Float) (dayOfYear : Nat) : Float :=
+  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
+  1 + 0.2 * Float.cos (2 * pi * offset / daysInYear.toFloat)
+
+/-- The base load of one hour in kWh. -/
+private def baseLoad (site : Site) (dayOfYear hour : Nat) : Float :=
+  (site.dailyLoadKwh - site.flexKwh) * seasonalFactor site.latitude dayOfYear *
+    profile[hour]! / 1000
+
+/-- The flexible load of one hour at its default hours: equal parts at 18:00, 19:00 and 20:00. -/
+private def defaultFlex (site : Site) (hour : Nat) : Float :=
+  if hour == 18 || hour == 19 || hour == 20 then site.flexKwh / 3 else 0
+
+/-! ## Scenario -/
+
+/-- The `24 × days` hours of a run, in order of day, then hour. The same arguments give the
+same array. -/
+def scenario (site : Site) (seed days : Nat) : Array Hour := Id.run do
+  let sky := skies site.latitude seed days
+  let mut out : Array Hour := Array.mkEmpty (24 * days)
+  for d in [0:days] do
+    let doy := d % daysInYear
+    let s := sky[d]!
+    for h in [0:24] do
+      out := out.push {
+        day := d, dayOfYear := doy, hour := h, sky := s,
+        pvKwh := pvOutput site doy h s,
+        baseLoadKwh := baseLoad site doy h,
+        flexKwh := defaultFlex site h }
+  return out
+
+end StoragePolicySim
diff --git a/lake-manifest.json b/lake-manifest.json
new file mode 100644
index 0000000..e11e984
--- /dev/null
+++ b/lake-manifest.json
@@ -0,0 +1,6 @@
+{"version": "1.3.0",
+ "packagesDir": ".lake/packages",
+ "packages": [],
+ "name": "«storage-policy-sim»",
+ "lakeDir": ".lake",
+ "fixedToolchain": false}
diff --git a/lakefile.toml b/lakefile.toml
new file mode 100644
index 0000000..0a10da9
--- /dev/null
+++ b/lakefile.toml
@@ -0,0 +1,7 @@
+name = "storage-policy-sim"
+version = "0.1.0"
+defaultTargets = ["StoragePolicySim"]
+
+[[lean_lib]]
+name = "StoragePolicySim"
+globs = ["StoragePolicySim.+"]
diff --git a/lean-toolchain b/lean-toolchain
new file mode 100644
index 0000000..a6aff06
--- /dev/null
+++ b/lean-toolchain
@@ -0,0 +1 @@
+leanprover/lean4:v4.35.0
````

### StoragePolicySim/Scenario.lean

````
/-
The scenario of a site: the solar output, the daily sky and the household load of each hour.
CAP-scenario (sun, weather and load) gives the rules.
-/
namespace StoragePolicySim

/-- The sky of a day. -/
inductive Sky
  | sunny
  | cloudy
  | overcast
  deriving BEq, Repr, Inhabited

/-- The share of the sunny output that the sky lets through. -/
def Sky.factor : Sky → Float
  | .sunny => 1.0
  | .cloudy => 0.5
  | .overcast => 0.15

/-- A site with its panels and its household load. -/
structure Site where
  /-- Degrees. South is negative. -/
  latitude : Float
  /-- The kW of the panels. -/
  pvKw : Float
  /-- The load of a day, with the flexible load included. -/
  dailyLoadKwh : Float
  /-- The part of the daily load that a strategy can move. -/
  flexKwh : Float
  deriving Repr, Inhabited

/-- One hour of a scenario. -/
structure Hour where
  /-- The day of the run, from 0. -/
  day : Nat
  /-- `day % 365`, from 0 (1 January) to 364. -/
  dayOfYear : Nat
  /-- The hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00. -/
  hour : Nat
  /-- The sky of the day. -/
  sky : Sky
  /-- The solar energy of the hour. -/
  pvKwh : Float
  /-- The base load of the hour. -/
  baseLoadKwh : Float
  /-- The flexible load of the hour, at its default hours. -/
  flexKwh : Float
  deriving Repr, Inhabited

def daysInYear : Nat := 365

private def pi : Float := 3.141592653589793

private def radians (deg : Float) : Float := deg * pi / 180

/-- The declination of the sun in degrees. Day 0 is 1 January. -/
private def declination (dayOfYear : Nat) : Float :=
  23.44 * Float.sin (2 * pi * (285 + dayOfYear.toFloat) / daysInYear.toFloat)

/-- The sine of the sun height at the middle of the hour, in solar time. -/
private def sinSunHeight (latitude : Float) (dayOfYear hour : Nat) : Float :=
  let lat := radians latitude
  let dec := radians (declination dayOfYear)
  let hourAngle := radians (15 * (hour.toFloat + 0.5 - 12))
  Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle

/-- The solar energy of one hour in kWh. It reads only `latitude` and `pvKw` of the site. -/
def pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float :=
  let h := sinSunHeight site.latitude dayOfYear hour
  if h ≤ 0 then 0 else site.pvKw * h * sky.factor

/-! ## Weather -/

/-- The state of the seeded random numbers (SplitMix64). -/
private structure Rng where
  state : UInt64

/-- The next number from 0 to less than 1, and the next state. -/
private def Rng.next (r : Rng) : Float × Rng :=
  let s := r.state + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  let z := z ^^^ (z >>> 31)
  ((z >>> 11).toFloat / 9007199254740992.0, ⟨s⟩)

/-- The chance that a day keeps the sky of the day before. -/
private def keepChance : Float := 0.6

/-- True for a day in the summer half of the year at this latitude. -/
private def inSummerHalf (latitude : Float) (dayOfYear : Nat) : Bool :=
  let north := 90 ≤ dayOfYear && dayOfYear ≤ 272
  if latitude ≥ 0 then north else !north

/-- A new sky from the chances of the half of the year. -/
private def newSky (summer : Bool) (u : Float) : Sky :=
  let (sunny, cloudy) := if summer then (0.55, 0.30) else (0.20, 0.35)
  if u < sunny then .sunny
  else if u < sunny + cloudy then .cloudy
  else .overcast

/-- The sky of each day of the run. -/
private def skies (latitude : Float) (seed days : Nat) : Array Sky := Id.run do
  let mut rng : Rng := ⟨seed.toUInt64⟩
  let mut out : Array Sky := Array.mkEmpty days
  for d in [0:days] do
    let (u, r) := rng.next
    rng := r
    match out.back? with
    | some prev =>
      if u < keepChance then
        out := out.push prev
        continue
    | none => pure ()
    let (v, r) := rng.next
    rng := r
    out := out.push (newSky (inSummerHalf latitude (d % daysInYear)) v)
  return out

/-! ## Load -/

/-- The share of the base load of a day in each hour, in parts of 1000. The profile has a
morning peak at 07:00 and an evening peak at 19:00. -/
private def profile : Array Float :=
  #[30, 22, 20, 20, 20, 25, 40, 55, 50, 40, 30, 30,
    32, 30, 33, 30, 38, 55, 75, 85, 80, 65, 55, 40]

/-- The day of the year with the most base load. -/
private def peakDay (latitude : Float) : Nat := if latitude ≥ 0 then 15 else 197

/-- The seasonal factor that scales the base load of a day. -/
private def seasonalFactor (latitude : Float) (dayOfYear : Nat) : Float :=
  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
  1 + 0.2 * Float.cos (2 * pi * offset / daysInYear.toFloat)

/-- The base load of one hour in kWh. -/
private def baseLoad (site : Site) (dayOfYear hour : Nat) : Float :=
  (site.dailyLoadKwh - site.flexKwh) * seasonalFactor site.latitude dayOfYear *
    profile[hour]! / 1000

/-- The flexible load of one hour at its default hours: equal parts at 18:00, 19:00 and 20:00. -/
private def defaultFlex (site : Site) (hour : Nat) : Float :=
  if hour == 18 || hour == 19 || hour == 20 then site.flexKwh / 3 else 0

/-! ## Scenario -/

/-- The `24 × days` hours of a run, in order of day, then hour. The same arguments give the
same array. -/
def scenario (site : Site) (seed days : Nat) : Array Hour := Id.run do
  let sky := skies site.latitude seed days
  let mut out : Array Hour := Array.mkEmpty (24 * days)
  for d in [0:days] do
    let doy := d % daysInYear
    let s := sky[d]!
    for h in [0:24] do
      out := out.push {
        day := d, dayOfYear := doy, hour := h, sky := s,
        pvKwh := pvOutput site doy h s,
        baseLoadKwh := baseLoad site doy h,
        flexKwh := defaultFlex site h }
  return out

end StoragePolicySim
````

### lake-manifest.json

````
{"version": "1.3.0",
 "packagesDir": ".lake/packages",
 "packages": [],
 "name": "«storage-policy-sim»",
 "lakeDir": ".lake",
 "fixedToolchain": false}
````

### lakefile.toml

````
name = "storage-policy-sim"
version = "0.1.0"
defaultTargets = ["StoragePolicySim"]

[[lean_lib]]
name = "StoragePolicySim"
globs = ["StoragePolicySim.+"]
````

### lean-toolchain

````
leanprover/lean4:v4.35.0
````

