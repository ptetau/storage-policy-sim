# Review packet · CH-0002-strategies · tests

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 7cc8c6b82b917635f2f8add001a95b5edddc93a7

## Re-review

Earlier review: f143658

An earlier review of this remit judged the checks locked at f143658. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.
Write a "Wrong versions" line only for each check that changed. If no check
changed, write "none" under "Wrong versions".

### Earlier problems

- tests/CAP-strategies.lean:192 · The three sunniest hours of `sunDay` are 11:00, 12:00 and 13:00, and these hours are next to each other. Thus, a wrong `shift` that takes the best window of three hours in a row also passes. The windows of `sunDay` sum to 9 (10:00 to 12:00), 10.5 (11:00 to 13:00) and 9 (12:00 to 14:00), so the window rule also picks 11:00 to 13:00. No other R5 check catches this version: the 4.5 kWh check uses `sunDay` too, `flatSun` gives the same result to both rules, and the no-sun and 0 kWh checks do not depend on the rule. Add a check with three top hours that are not next to each other, for example sun 4 at 09:00, 1 at 10:00 to 12:00, and 3.5 and 3 at 14:00 and 15:00. Then the result must be 1 kWh at 09:00, 14:00 and 15:00. · CAP-strategies.R5 ("the three hours with the most solar output"), and the remit rule that each check fails on a plausible wrong version (the trap "examples that also fit a wrong rule")

### Changes since the earlier review

````
diff --git a/tests/CAP-strategies.lean b/tests/CAP-strategies.lean
index a2abff8..c113046 100644
--- a/tests/CAP-strategies.lean
+++ b/tests/CAP-strategies.lean
@@ -193,6 +193,13 @@ def checks : List Check := [
     run := do
       return badDay (Strategy.placeFlex Strategy.shift sunDay defaultFlex)
         (mkDay [(11, 1), (12, 1), (13, 1)]) },
+  -- The three sunniest hours are not next to each other. A version that takes the best
+  -- window of three hours in a row gives 13:00 to 15:00 or 14:00 to 16:00, and fails here.
+  { name := "CAP-strategies.R5 3 kWh with the most sun at 09:00, 14:00 and 15:00 gives each 1 kWh",
+    run := do
+      let pv := mkDay [(9, 4), (10, 1), (11, 1), (12, 1), (14, 3.5), (15, 3)]
+      return badDay (Strategy.placeFlex Strategy.shift pv defaultFlex)
+        (mkDay [(9, 1), (14, 1), (15, 1)]) },
   -- Equal parts: a version that always puts 1 kWh in each hour fails here.
   { name := "CAP-strategies.R5 4.5 kWh at other default hours gives 1.5 kWh at 11:00, 12:00 and 13:00",
     run := do
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
# CH-0002 · Battery and load strategies

Intent: IN-0001 · Scope: CAP-strategies · Status: testing · Ticket: none · Branch: pdlc/CH-0002-strategies · Base: pdlc/CH-0001-scenario

Tests-Locked: 91d1e6b

## Delivers

The library has four named strategies. Each strategy asks the battery to charge or to
discharge for an hour, and places the flexible load of a day.

## Requirements

### CAP-strategies.R1 · Strategy names

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Strategy.lean`. A
check imports `StoragePolicySim.Strategy` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Strategy | none | greedy | evening | shift` with `BEq`, `Repr` and `Inhabited`
  (assumed). Write each value in full, for example `Strategy.none`, so that it does not
  mean `Option.none`.
- `Strategy.all : List Strategy`: `[.none, .greedy, .evening, .shift]`.
- `Strategy.name : Strategy → String`: `"none"`, `"greedy"`, `"evening"` or `"shift"`.
- `Strategy.ofName? (name : String) : Option Strategy`: the strategy whose name matches
  exactly, or `Option.none`.
- `structure Request` with `Repr` (assumed). The fields are `chargeKwh : Float` and
  `dischargeKwh : Float`: the energy that the strategy asks to charge and to discharge.
- `Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request`.
  The hour is 0 to 23, and hour 17 is 17:00 to 18:00. The surplus is the solar energy that
  the house does not use directly. The shortfall is the load that the solar energy does not
  meet. One of the two is 0.
- `Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float`. Each array
  has 24 items, one for each hour of a day. `pvKwh` is the solar energy of each hour, and
  `flexKwh` is the flexible load at its default hours. The result is the flexible load of
  each hour after the strategy places it.

### Test seams

none

## Files

- `StoragePolicySim/Strategy.lean`

## Check files

- `tests/CAP-strategies.lean`

## Steps

### Step 1 · Strategy names · [ ]

- Requirement: CAP-strategies.R1
- Check: the checks named `CAP-strategies.R1 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 2 · No battery use · [ ]

- Requirement: CAP-strategies.R2
- Check: the checks named `CAP-strategies.R2 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 3 · Greedy battery use · [ ]

- Requirement: CAP-strategies.R3
- Check: the checks named `CAP-strategies.R3 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 4 · Evening battery use · [ ]

- Requirement: CAP-strategies.R4
- Check: the checks named `CAP-strategies.R4 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 5 · Load shift into sun · [ ]

- Requirement: CAP-strategies.R5
- Check: the checks named `CAP-strategies.R5 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned after CH-0001 (scenario), so that the simulation can use both. The strategies do not need the scenario.
````

## The spec it covers: title and summary

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
````

## The requirements, in full

### CAP-strategies.R1 · Strategy names

Status: ready · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: ready · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: ready · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: ready · Intents: IN-0001

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

Status: ready · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

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

### Diff against pdlc/CH-0001-scenario

````
diff --git a/tests/CAP-strategies.lean b/tests/CAP-strategies.lean
new file mode 100644
index 0000000..c113046
--- /dev/null
+++ b/tests/CAP-strategies.lean
@@ -0,0 +1,235 @@
+/-
+Component checks of CAP-strategies (battery and load strategies), for CH-0002 (battery and
+load strategies).
+
+The checks call only `Strategy`, `Strategy.all`, `Strategy.name`, `Strategy.ofName?`,
+`Request`, `Strategy.decide` and `Strategy.placeFlex`. No entry of the Interface can fail,
+so no check expects an error code. The Interface has no test seam, and no check uses the
+clock.
+-/
+import StoragePolicySim.Strategy
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
+/-- The 24 hours of a day. Each listed hour gets its value, and each other hour gets 0. -/
+def mkDay (xs : List (Nat × Float)) : Array Float :=
+  (List.range 24).toArray.map (fun h =>
+    match xs.find? (fun p => p.1 == h) with
+    | some p => p.2
+    | none => 0)
+
+/-- The default flexible load: 1 kWh at 18:00, 19:00 and 20:00. -/
+def defaultFlex : Array Float := mkDay [(18, 1), (19, 1), (20, 1)]
+
+/-- A flexible load that is not at 18:00 to 20:00, and that does not have equal parts. -/
+def oddFlex : Array Float := mkDay [(7, 0.5), (19, 2)]
+
+/-- A sunny day. The most sun is at 13:00, then 11:00, then 12:00. -/
+def sunDay : Array Float :=
+  mkDay [(9, 1), (10, 2.5), (11, 3.5), (12, 3), (13, 4), (14, 2), (15, 0.5)]
+
+/-- Equal sun from 10:00 to 14:00, and no sun at other hours. -/
+def flatSun : Array Float := mkDay [(10, 2), (11, 2), (12, 2), (13, 2), (14, 2)]
+
+def noSun : Array Float := mkDay []
+
+/-- Compares the 24 hours of a result with the expected hours. -/
+def badDay (got want : Array Float) : Option String :=
+  if got.size != 24 then some s!"{got.size} hours, not 24"
+  else match (List.range 24).find? (fun h => !near got[h]! want[h]! 1e-9) with
+    | some h => some s!"hour {h} has {got[h]!} kWh, not {want[h]!} kWh, result {got}"
+    | none => none
+
+/-- Compares a request with the expected charge and discharge. -/
+def badRequest (r : Request) (charge discharge : Float) : Option String :=
+  if near r.chargeKwh charge 1e-9 && near r.dischargeKwh discharge 1e-9 then none
+  else some s!"charge {r.chargeKwh}, discharge {r.dischargeKwh}"
+
+def badDischarge (r : Request) (discharge : Float) : Option String :=
+  if near r.dischargeKwh discharge 1e-9 then none
+  else some s!"discharge {r.dischargeKwh}, charge {r.chargeKwh}"
+
+def checks : List Check := [
+  -- CAP-strategies.R1
+  { name := "CAP-strategies.R1 the list is none, greedy, evening and shift, in this order",
+    run := do
+      let want := [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]
+      return if Strategy.all == want then none
+        else some s!"got {repr Strategy.all}" },
+  { name := "CAP-strategies.R1 the names of the list are none, greedy, evening and shift",
+    run := do
+      let got := Strategy.all.map Strategy.name
+      return if got == ["none", "greedy", "evening", "shift"] then none else some s!"got {got}" },
+  { name := "CAP-strategies.R1 the name \"greedy\" finds the greedy strategy",
+    run := do
+      let got := Strategy.ofName? "greedy"
+      return if got == some Strategy.greedy then none else some s!"got {repr got}" },
+  -- A version that finds only "greedy", or that always gives the first strategy, fails here.
+  { name := "CAP-strategies.R1 each name of the list finds its own strategy",
+    run := do
+      let n := Strategy.ofName? "none"
+      let e := Strategy.ofName? "evening"
+      let s := Strategy.ofName? "shift"
+      return firstFail [
+        (n == some Strategy.none, s!"none gives {repr n}"),
+        (e == some Strategy.evening, s!"evening gives {repr e}"),
+        (s == some Strategy.shift, s!"shift gives {repr s}")] },
+  { name := "CAP-strategies.R1 the name \"Greedy\" finds no strategy",
+    run := do
+      let got := Strategy.ofName? "Greedy"
+      return if got.isNone then none else some s!"got {repr got}" },
+  { name := "CAP-strategies.R1 the name \"\" finds no strategy",
+    run := do
+      let got := Strategy.ofName? ""
+      return if got.isNone then none else some s!"got {repr got}" },
+  -- A version that ignores case, trims spaces, or matches a prefix fails here.
+  { name := "CAP-strategies.R1 names close to \"greedy\" find no strategy",
+    run := do
+      let close := ["GREEDY", " greedy", "greedy ", "greedy\n", "gree", "greedyx", "none ", "Shift"]
+      return match close.find? (fun n => (Strategy.ofName? n).isSome) with
+        | some n =>
+          let got := Strategy.ofName? n
+          some s!"{repr n} gives {repr got}"
+        | none => none },
+
+  -- CAP-strategies.R2
+  { name := "CAP-strategies.R2 a surplus of 2 kWh at 12:00 asks none to charge 0 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.none 12 2 0) 0 0 },
+  { name := "CAP-strategies.R2 a shortfall of 1.5 kWh at 19:00 asks none to charge 0 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.none 19 0 1.5) 0 0 },
+  -- The day has sun. Thus, a version that moves the load into the sun fails here.
+  { name := "CAP-strategies.R2 none keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.none sunDay defaultFlex) defaultFlex },
+  -- A version that always gives 1 kWh at 18:00 to 20:00 fails here.
+  { name := "CAP-strategies.R2 none does not change a flexible load at other hours",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.none sunDay oddFlex) oddFlex },
+
+  -- CAP-strategies.R3
+  { name := "CAP-strategies.R3 a surplus of 2 kWh at 12:00 asks greedy to charge 2 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.greedy 12 2 0) 2 0 },
+  -- A version that always charges 2 kWh fails here.
+  { name := "CAP-strategies.R3 a surplus of 0.7 kWh at 09:00 asks greedy to charge 0.7 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.greedy 9 0.7 0) 0.7 0 },
+  { name := "CAP-strategies.R3 a shortfall of 1.5 kWh at 03:00 asks greedy to charge 0 and discharge 1.5",
+    run := do
+      return badRequest (Strategy.decide Strategy.greedy 3 0 1.5) 0 1.5 },
+  { name := "CAP-strategies.R3 a shortfall of 1.5 kWh at 13:00 asks greedy to charge 0 and discharge 1.5",
+    run := do
+      return badRequest (Strategy.decide Strategy.greedy 13 0 1.5) 0 1.5 },
+  { name := "CAP-strategies.R3 no surplus and no shortfall at 19:00 asks greedy to charge 0 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.greedy 19 0 0) 0 0 },
+  { name := "CAP-strategies.R3 greedy keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.greedy sunDay defaultFlex) defaultFlex },
+  { name := "CAP-strategies.R3 greedy does not change a flexible load at other hours",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.greedy sunDay oddFlex) oddFlex },
+
+  -- CAP-strategies.R4
+  { name := "CAP-strategies.R4 a surplus of 2 kWh at 12:00 asks evening to charge 2 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.evening 12 2 0) 2 0 },
+  -- The evening strategy charges as greedy does, also in the evening.
+  { name := "CAP-strategies.R4 a surplus of 0.7 kWh at 19:00 asks evening to charge 0.7 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.evening 19 0.7 0) 0.7 0 },
+  -- 16:00 is one hour before the edge at 17:00.
+  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 16:00 asks evening to discharge 0",
+    run := do
+      return badDischarge (Strategy.decide Strategy.evening 16 0 1.5) 0 },
+  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 17:00 asks evening to discharge 1.5",
+    run := do
+      return badDischarge (Strategy.decide Strategy.evening 17 0 1.5) 1.5 },
+  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 23:00 asks evening to discharge 1.5",
+    run := do
+      return badDischarge (Strategy.decide Strategy.evening 23 0 1.5) 1.5 },
+  -- 00:00 is one hour after the edge at 23:00.
+  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 00:00 asks evening to discharge 0",
+    run := do
+      return badDischarge (Strategy.decide Strategy.evening 0 0 1.5) 0 },
+  -- A version that always discharges 1.5 kWh in the evening fails here.
+  { name := "CAP-strategies.R4 a shortfall of 0.4 kWh at 20:00 asks evening to discharge 0.4",
+    run := do
+      return badDischarge (Strategy.decide Strategy.evening 20 0 0.4) 0.4 },
+  { name := "CAP-strategies.R4 evening keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.evening sunDay defaultFlex) defaultFlex },
+  { name := "CAP-strategies.R4 evening does not change a flexible load at other hours",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.evening sunDay oddFlex) oddFlex },
+
+  -- CAP-strategies.R5
+  { name := "CAP-strategies.R5 a surplus of 2 kWh at 12:00 asks shift to charge 2 and discharge 0",
+    run := do
+      return badRequest (Strategy.decide Strategy.shift 12 2 0) 2 0 },
+  -- A version that discharges only in the evening, as evening does, fails here.
+  { name := "CAP-strategies.R5 a shortfall of 1.5 kWh at 03:00 asks shift to discharge 1.5",
+    run := do
+      return badDischarge (Strategy.decide Strategy.shift 3 0 1.5) 1.5 },
+  -- The order of the sun is 13:00, 11:00, 12:00, then 10:00. A version that takes the first
+  -- sunny hours, or the peak hour and its two neighbours, fails here.
+  { name := "CAP-strategies.R5 3 kWh with the most sun at 13:00, 11:00 and 12:00 gives each 1 kWh",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.shift sunDay defaultFlex)
+        (mkDay [(11, 1), (12, 1), (13, 1)]) },
+  -- The three sunniest hours are not next to each other. A version that takes the best
+  -- window of three hours in a row gives 13:00 to 15:00 or 14:00 to 16:00, and fails here.
+  { name := "CAP-strategies.R5 3 kWh with the most sun at 09:00, 14:00 and 15:00 gives each 1 kWh",
+    run := do
+      let pv := mkDay [(9, 4), (10, 1), (11, 1), (12, 1), (14, 3.5), (15, 3)]
+      return badDay (Strategy.placeFlex Strategy.shift pv defaultFlex)
+        (mkDay [(9, 1), (14, 1), (15, 1)]) },
+  -- Equal parts: a version that always puts 1 kWh in each hour fails here.
+  { name := "CAP-strategies.R5 4.5 kWh at other default hours gives 1.5 kWh at 11:00, 12:00 and 13:00",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.shift sunDay (mkDay [(7, 0.5), (18, 2), (19, 2)]))
+        (mkDay [(11, 1.5), (12, 1.5), (13, 1.5)]) },
+  -- A version that gives a tie to the later hour gives 12:00, 13:00 and 14:00.
+  { name := "CAP-strategies.R5 equal sun from 10:00 to 14:00 gives 1 kWh at 10:00, 11:00 and 12:00",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.shift flatSun defaultFlex)
+        (mkDay [(10, 1), (11, 1), (12, 1)]) },
+  -- A version that sorts the hours with no sun and takes 00:00 to 02:00 fails here.
+  { name := "CAP-strategies.R5 3 kWh and no sun stays at 18:00, 19:00 and 20:00",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.shift noSun defaultFlex) defaultFlex },
+  { name := "CAP-strategies.R5 0 kWh and sun at 12:00 gives 0 kWh of flexible load in each hour",
+    run := do
+      return badDay (Strategy.placeFlex Strategy.shift (mkDay [(12, 3)]) (mkDay [])) (mkDay []) }
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

### tests/CAP-strategies.lean

````
/-
Component checks of CAP-strategies (battery and load strategies), for CH-0002 (battery and
load strategies).

The checks call only `Strategy`, `Strategy.all`, `Strategy.name`, `Strategy.ofName?`,
`Request`, `Strategy.decide` and `Strategy.placeFlex`. No entry of the Interface can fail,
so no check expects an error code. The Interface has no test seam, and no check uses the
clock.
-/
import StoragePolicySim.Strategy
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

/-- The 24 hours of a day. Each listed hour gets its value, and each other hour gets 0. -/
def mkDay (xs : List (Nat × Float)) : Array Float :=
  (List.range 24).toArray.map (fun h =>
    match xs.find? (fun p => p.1 == h) with
    | some p => p.2
    | none => 0)

/-- The default flexible load: 1 kWh at 18:00, 19:00 and 20:00. -/
def defaultFlex : Array Float := mkDay [(18, 1), (19, 1), (20, 1)]

/-- A flexible load that is not at 18:00 to 20:00, and that does not have equal parts. -/
def oddFlex : Array Float := mkDay [(7, 0.5), (19, 2)]

/-- A sunny day. The most sun is at 13:00, then 11:00, then 12:00. -/
def sunDay : Array Float :=
  mkDay [(9, 1), (10, 2.5), (11, 3.5), (12, 3), (13, 4), (14, 2), (15, 0.5)]

/-- Equal sun from 10:00 to 14:00, and no sun at other hours. -/
def flatSun : Array Float := mkDay [(10, 2), (11, 2), (12, 2), (13, 2), (14, 2)]

def noSun : Array Float := mkDay []

/-- Compares the 24 hours of a result with the expected hours. -/
def badDay (got want : Array Float) : Option String :=
  if got.size != 24 then some s!"{got.size} hours, not 24"
  else match (List.range 24).find? (fun h => !near got[h]! want[h]! 1e-9) with
    | some h => some s!"hour {h} has {got[h]!} kWh, not {want[h]!} kWh, result {got}"
    | none => none

/-- Compares a request with the expected charge and discharge. -/
def badRequest (r : Request) (charge discharge : Float) : Option String :=
  if near r.chargeKwh charge 1e-9 && near r.dischargeKwh discharge 1e-9 then none
  else some s!"charge {r.chargeKwh}, discharge {r.dischargeKwh}"

def badDischarge (r : Request) (discharge : Float) : Option String :=
  if near r.dischargeKwh discharge 1e-9 then none
  else some s!"discharge {r.dischargeKwh}, charge {r.chargeKwh}"

def checks : List Check := [
  -- CAP-strategies.R1
  { name := "CAP-strategies.R1 the list is none, greedy, evening and shift, in this order",
    run := do
      let want := [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]
      return if Strategy.all == want then none
        else some s!"got {repr Strategy.all}" },
  { name := "CAP-strategies.R1 the names of the list are none, greedy, evening and shift",
    run := do
      let got := Strategy.all.map Strategy.name
      return if got == ["none", "greedy", "evening", "shift"] then none else some s!"got {got}" },
  { name := "CAP-strategies.R1 the name \"greedy\" finds the greedy strategy",
    run := do
      let got := Strategy.ofName? "greedy"
      return if got == some Strategy.greedy then none else some s!"got {repr got}" },
  -- A version that finds only "greedy", or that always gives the first strategy, fails here.
  { name := "CAP-strategies.R1 each name of the list finds its own strategy",
    run := do
      let n := Strategy.ofName? "none"
      let e := Strategy.ofName? "evening"
      let s := Strategy.ofName? "shift"
      return firstFail [
        (n == some Strategy.none, s!"none gives {repr n}"),
        (e == some Strategy.evening, s!"evening gives {repr e}"),
        (s == some Strategy.shift, s!"shift gives {repr s}")] },
  { name := "CAP-strategies.R1 the name \"Greedy\" finds no strategy",
    run := do
      let got := Strategy.ofName? "Greedy"
      return if got.isNone then none else some s!"got {repr got}" },
  { name := "CAP-strategies.R1 the name \"\" finds no strategy",
    run := do
      let got := Strategy.ofName? ""
      return if got.isNone then none else some s!"got {repr got}" },
  -- A version that ignores case, trims spaces, or matches a prefix fails here.
  { name := "CAP-strategies.R1 names close to \"greedy\" find no strategy",
    run := do
      let close := ["GREEDY", " greedy", "greedy ", "greedy\n", "gree", "greedyx", "none ", "Shift"]
      return match close.find? (fun n => (Strategy.ofName? n).isSome) with
        | some n =>
          let got := Strategy.ofName? n
          some s!"{repr n} gives {repr got}"
        | none => none },

  -- CAP-strategies.R2
  { name := "CAP-strategies.R2 a surplus of 2 kWh at 12:00 asks none to charge 0 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.none 12 2 0) 0 0 },
  { name := "CAP-strategies.R2 a shortfall of 1.5 kWh at 19:00 asks none to charge 0 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.none 19 0 1.5) 0 0 },
  -- The day has sun. Thus, a version that moves the load into the sun fails here.
  { name := "CAP-strategies.R2 none keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00",
    run := do
      return badDay (Strategy.placeFlex Strategy.none sunDay defaultFlex) defaultFlex },
  -- A version that always gives 1 kWh at 18:00 to 20:00 fails here.
  { name := "CAP-strategies.R2 none does not change a flexible load at other hours",
    run := do
      return badDay (Strategy.placeFlex Strategy.none sunDay oddFlex) oddFlex },

  -- CAP-strategies.R3
  { name := "CAP-strategies.R3 a surplus of 2 kWh at 12:00 asks greedy to charge 2 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.greedy 12 2 0) 2 0 },
  -- A version that always charges 2 kWh fails here.
  { name := "CAP-strategies.R3 a surplus of 0.7 kWh at 09:00 asks greedy to charge 0.7 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.greedy 9 0.7 0) 0.7 0 },
  { name := "CAP-strategies.R3 a shortfall of 1.5 kWh at 03:00 asks greedy to charge 0 and discharge 1.5",
    run := do
      return badRequest (Strategy.decide Strategy.greedy 3 0 1.5) 0 1.5 },
  { name := "CAP-strategies.R3 a shortfall of 1.5 kWh at 13:00 asks greedy to charge 0 and discharge 1.5",
    run := do
      return badRequest (Strategy.decide Strategy.greedy 13 0 1.5) 0 1.5 },
  { name := "CAP-strategies.R3 no surplus and no shortfall at 19:00 asks greedy to charge 0 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.greedy 19 0 0) 0 0 },
  { name := "CAP-strategies.R3 greedy keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00",
    run := do
      return badDay (Strategy.placeFlex Strategy.greedy sunDay defaultFlex) defaultFlex },
  { name := "CAP-strategies.R3 greedy does not change a flexible load at other hours",
    run := do
      return badDay (Strategy.placeFlex Strategy.greedy sunDay oddFlex) oddFlex },

  -- CAP-strategies.R4
  { name := "CAP-strategies.R4 a surplus of 2 kWh at 12:00 asks evening to charge 2 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.evening 12 2 0) 2 0 },
  -- The evening strategy charges as greedy does, also in the evening.
  { name := "CAP-strategies.R4 a surplus of 0.7 kWh at 19:00 asks evening to charge 0.7 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.evening 19 0.7 0) 0.7 0 },
  -- 16:00 is one hour before the edge at 17:00.
  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 16:00 asks evening to discharge 0",
    run := do
      return badDischarge (Strategy.decide Strategy.evening 16 0 1.5) 0 },
  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 17:00 asks evening to discharge 1.5",
    run := do
      return badDischarge (Strategy.decide Strategy.evening 17 0 1.5) 1.5 },
  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 23:00 asks evening to discharge 1.5",
    run := do
      return badDischarge (Strategy.decide Strategy.evening 23 0 1.5) 1.5 },
  -- 00:00 is one hour after the edge at 23:00.
  { name := "CAP-strategies.R4 a shortfall of 1.5 kWh at 00:00 asks evening to discharge 0",
    run := do
      return badDischarge (Strategy.decide Strategy.evening 0 0 1.5) 0 },
  -- A version that always discharges 1.5 kWh in the evening fails here.
  { name := "CAP-strategies.R4 a shortfall of 0.4 kWh at 20:00 asks evening to discharge 0.4",
    run := do
      return badDischarge (Strategy.decide Strategy.evening 20 0 0.4) 0.4 },
  { name := "CAP-strategies.R4 evening keeps 1 kWh of flexible load at 18:00, 19:00 and 20:00",
    run := do
      return badDay (Strategy.placeFlex Strategy.evening sunDay defaultFlex) defaultFlex },
  { name := "CAP-strategies.R4 evening does not change a flexible load at other hours",
    run := do
      return badDay (Strategy.placeFlex Strategy.evening sunDay oddFlex) oddFlex },

  -- CAP-strategies.R5
  { name := "CAP-strategies.R5 a surplus of 2 kWh at 12:00 asks shift to charge 2 and discharge 0",
    run := do
      return badRequest (Strategy.decide Strategy.shift 12 2 0) 2 0 },
  -- A version that discharges only in the evening, as evening does, fails here.
  { name := "CAP-strategies.R5 a shortfall of 1.5 kWh at 03:00 asks shift to discharge 1.5",
    run := do
      return badDischarge (Strategy.decide Strategy.shift 3 0 1.5) 1.5 },
  -- The order of the sun is 13:00, 11:00, 12:00, then 10:00. A version that takes the first
  -- sunny hours, or the peak hour and its two neighbours, fails here.
  { name := "CAP-strategies.R5 3 kWh with the most sun at 13:00, 11:00 and 12:00 gives each 1 kWh",
    run := do
      return badDay (Strategy.placeFlex Strategy.shift sunDay defaultFlex)
        (mkDay [(11, 1), (12, 1), (13, 1)]) },
  -- The three sunniest hours are not next to each other. A version that takes the best
  -- window of three hours in a row gives 13:00 to 15:00 or 14:00 to 16:00, and fails here.
  { name := "CAP-strategies.R5 3 kWh with the most sun at 09:00, 14:00 and 15:00 gives each 1 kWh",
    run := do
      let pv := mkDay [(9, 4), (10, 1), (11, 1), (12, 1), (14, 3.5), (15, 3)]
      return badDay (Strategy.placeFlex Strategy.shift pv defaultFlex)
        (mkDay [(9, 1), (14, 1), (15, 1)]) },
  -- Equal parts: a version that always puts 1 kWh in each hour fails here.
  { name := "CAP-strategies.R5 4.5 kWh at other default hours gives 1.5 kWh at 11:00, 12:00 and 13:00",
    run := do
      return badDay (Strategy.placeFlex Strategy.shift sunDay (mkDay [(7, 0.5), (18, 2), (19, 2)]))
        (mkDay [(11, 1.5), (12, 1.5), (13, 1.5)]) },
  -- A version that gives a tie to the later hour gives 12:00, 13:00 and 14:00.
  { name := "CAP-strategies.R5 equal sun from 10:00 to 14:00 gives 1 kWh at 10:00, 11:00 and 12:00",
    run := do
      return badDay (Strategy.placeFlex Strategy.shift flatSun defaultFlex)
        (mkDay [(10, 1), (11, 1), (12, 1)]) },
  -- A version that sorts the hours with no sun and takes 00:00 to 02:00 fails here.
  { name := "CAP-strategies.R5 3 kWh and no sun stays at 18:00, 19:00 and 20:00",
    run := do
      return badDay (Strategy.placeFlex Strategy.shift noSun defaultFlex) defaultFlex },
  { name := "CAP-strategies.R5 0 kWh and sun at 12:00 gives 0 kWh of flexible load in each hour",
    run := do
      return badDay (Strategy.placeFlex Strategy.shift (mkDay [(12, 3)]) (mkDay [])) (mkDay []) }
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

