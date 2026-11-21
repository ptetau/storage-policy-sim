# Review packet · CH-0002-strategies · privacy

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: e938ab0cd8d2b1a44d7365504c446d2f160a2d27

# Remit: privacy

Default: yes

You judge how the change treats personal data: anything that identifies a person.

- The change collects only the personal data that it needs.
- The change does not log personal data, print the data in errors, or send the data to
  an unexpected place.
- The change protects stored personal data, and keeps the data no longer than necessary.
- Where the spec says so, persons can see, correct, or remove their data.

If the change touches no personal data, reply `Result: pass` and say "not applicable".

## The change spec

````
# CH-0002 · Battery and load strategies

Intent: IN-0001 · Scope: CAP-strategies · Status: building · Ticket: none · Branch: pdlc/CH-0002-strategies · Base: pdlc/CH-0001-scenario

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

### Step 1 · Strategy names · [x]

- Requirement: CAP-strategies.R1
- Check: the checks named `CAP-strategies.R1 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 2 · No battery use · [x]

- Requirement: CAP-strategies.R2
- Check: the checks named `CAP-strategies.R2 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 3 · Greedy battery use · [x]

- Requirement: CAP-strategies.R3
- Check: the checks named `CAP-strategies.R3 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 4 · Evening battery use · [x]

- Requirement: CAP-strategies.R4
- Check: the checks named `CAP-strategies.R4 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 5 · Load shift into sun · [x]

- Requirement: CAP-strategies.R5
- Check: the checks named `CAP-strategies.R5 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned after CH-0001 (scenario), so that the simulation can use both. The strategies do not need the scenario.
- The first tests review found that a three-hour window passed the check of R5 (load shift into sun). The test writer added a check with hours apart, round 1 of 2.
- Build: the 35 checks of `tests/CAP-strategies.lean` and the 34 checks of `tests/CAP-scenario.lean` pass. No check changed since the lock `91d1e6b`.
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

Status: built · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: built · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: built · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: built · Intents: IN-0001

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

Status: built · Intents: IN-0001

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

## The code

### Diff against pdlc/CH-0001-scenario

````
diff --git a/StoragePolicySim/Strategy.lean b/StoragePolicySim/Strategy.lean
new file mode 100644
index 0000000..f2b426e
--- /dev/null
+++ b/StoragePolicySim/Strategy.lean
@@ -0,0 +1,88 @@
+/-
+The strategies that the simulation compares. For each hour, a strategy asks the battery to
+charge or to discharge. For each day, a strategy also places the flexible load.
+CAP-strategies (battery and load strategies) gives the rules.
+-/
+namespace StoragePolicySim
+
+/-- A named strategy for the battery and the flexible load. -/
+inductive Strategy
+  /-- No battery use. -/
+  | none
+  /-- Battery use at any hour. -/
+  | greedy
+  /-- Discharge only in the evening. -/
+  | evening
+  /-- Greedy battery use, and the flexible load in the sunniest hours. -/
+  | shift
+  deriving BEq, Repr, Inhabited
+
+/-- What a strategy asks the battery to do for one hour. -/
+structure Request where
+  /-- The energy that the strategy asks to charge. -/
+  chargeKwh : Float
+  /-- The energy that the strategy asks to discharge. -/
+  dischargeKwh : Float
+  deriving Repr
+
+/-- The strategies, in the order of the comparison. -/
+def Strategy.all : List Strategy :=
+  [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]
+
+/-- The name of a strategy on the command line. -/
+def Strategy.name : Strategy → String
+  | .none => "none"
+  | .greedy => "greedy"
+  | .evening => "evening"
+  | .shift => "shift"
+
+/-- The strategy whose name matches `name` exactly, or `Option.none`. -/
+def Strategy.ofName? (name : String) : Option Strategy :=
+  Strategy.all.find? (fun s => s.name == name)
+
+/-- The first hour of the evening. The evening is 17:00 to 23:59. -/
+private def eveningStartHour : Nat := 17
+
+/-- The number of hours that get the flexible load of the `shift` strategy. -/
+private def sunniestHourCount : Nat := 3
+
+/-- A request that charges with the full surplus and discharges for the full shortfall. -/
+private def fullRequest (surplusKwh shortfallKwh : Float) : Request :=
+  { chargeKwh := surplusKwh, dischargeKwh := shortfallKwh }
+
+/-- The request of a strategy for one hour. The simulation applies the limits of the
+battery. -/
+def Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request :=
+  match s with
+  | .none => { chargeKwh := 0, dischargeKwh := 0 }
+  | .greedy | .shift => fullRequest surplusKwh shortfallKwh
+  | .evening =>
+    let dischargeKwh := if hour ≥ eveningStartHour then shortfallKwh else 0
+    { chargeKwh := surplusKwh, dischargeKwh := dischargeKwh }
+
+/-- The hours of a day, from the most solar energy to the least. A tie goes to the earlier
+hour. -/
+private def hoursBySun (pvKwh : Array Float) : List Nat :=
+  let comesFirst (a b : Nat) : Bool :=
+    pvKwh[a]! > pvKwh[b]! || (pvKwh[a]! == pvKwh[b]! && a ≤ b)
+  (List.range pvKwh.size).mergeSort comesFirst
+
+/-- The flexible load of the `shift` strategy: equal parts in the sunniest hours. A day
+with no solar energy keeps the flexible load at its default hours. -/
+private def shiftIntoSun (pvKwh flexKwh : Array Float) : Array Float :=
+  if pvKwh.all (· ≤ 0) then flexKwh
+  else
+    let totalFlexKwh := flexKwh.foldl (· + ·) 0
+    let sunniestHours := (hoursBySun pvKwh).take sunniestHourCount
+    let partKwh := totalFlexKwh / sunniestHourCount.toFloat
+    (List.range flexKwh.size).toArray.map (fun h =>
+      if sunniestHours.contains h then partKwh else 0)
+
+/-- The flexible load of each hour of a day, after the strategy places it. `pvKwh` is the
+solar energy of each hour, and `flexKwh` is the flexible load at its default hours. -/
+def Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float :=
+  match s with
+  | .none | .greedy | .evening => flexKwh
+  | .shift => shiftIntoSun pvKwh flexKwh
+
+end StoragePolicySim
````

### StoragePolicySim/Strategy.lean

````
/-
The strategies that the simulation compares. For each hour, a strategy asks the battery to
charge or to discharge. For each day, a strategy also places the flexible load.
CAP-strategies (battery and load strategies) gives the rules.
-/
namespace StoragePolicySim

/-- A named strategy for the battery and the flexible load. -/
inductive Strategy
  /-- No battery use. -/
  | none
  /-- Battery use at any hour. -/
  | greedy
  /-- Discharge only in the evening. -/
  | evening
  /-- Greedy battery use, and the flexible load in the sunniest hours. -/
  | shift
  deriving BEq, Repr, Inhabited

/-- What a strategy asks the battery to do for one hour. -/
structure Request where
  /-- The energy that the strategy asks to charge. -/
  chargeKwh : Float
  /-- The energy that the strategy asks to discharge. -/
  dischargeKwh : Float
  deriving Repr

/-- The strategies, in the order of the comparison. -/
def Strategy.all : List Strategy :=
  [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]

/-- The name of a strategy on the command line. -/
def Strategy.name : Strategy → String
  | .none => "none"
  | .greedy => "greedy"
  | .evening => "evening"
  | .shift => "shift"

/-- The strategy whose name matches `name` exactly, or `Option.none`. -/
def Strategy.ofName? (name : String) : Option Strategy :=
  Strategy.all.find? (fun s => s.name == name)

/-- The first hour of the evening. The evening is 17:00 to 23:59. -/
private def eveningStartHour : Nat := 17

/-- The number of hours that get the flexible load of the `shift` strategy. -/
private def sunniestHourCount : Nat := 3

/-- A request that charges with the full surplus and discharges for the full shortfall. -/
private def fullRequest (surplusKwh shortfallKwh : Float) : Request :=
  { chargeKwh := surplusKwh, dischargeKwh := shortfallKwh }

/-- The request of a strategy for one hour. The simulation applies the limits of the
battery. -/
def Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request :=
  match s with
  | .none => { chargeKwh := 0, dischargeKwh := 0 }
  | .greedy | .shift => fullRequest surplusKwh shortfallKwh
  | .evening =>
    let dischargeKwh := if hour ≥ eveningStartHour then shortfallKwh else 0
    { chargeKwh := surplusKwh, dischargeKwh := dischargeKwh }

/-- The hours of a day, from the most solar energy to the least. A tie goes to the earlier
hour. -/
private def hoursBySun (pvKwh : Array Float) : List Nat :=
  let comesFirst (a b : Nat) : Bool :=
    pvKwh[a]! > pvKwh[b]! || (pvKwh[a]! == pvKwh[b]! && a ≤ b)
  (List.range pvKwh.size).mergeSort comesFirst

/-- The flexible load of the `shift` strategy: equal parts in the sunniest hours. A day
with no solar energy keeps the flexible load at its default hours. -/
private def shiftIntoSun (pvKwh flexKwh : Array Float) : Array Float :=
  if pvKwh.all (· ≤ 0) then flexKwh
  else
    let totalFlexKwh := flexKwh.foldl (· + ·) 0
    let sunniestHours := (hoursBySun pvKwh).take sunniestHourCount
    let partKwh := totalFlexKwh / sunniestHourCount.toFloat
    (List.range flexKwh.size).toArray.map (fun h =>
      if sunniestHours.contains h then partKwh else 0)

/-- The flexible load of each hour of a day, after the strategy places it. `pvKwh` is the
solar energy of each hour, and `flexKwh` is the flexible load at its default hours. -/
def Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float :=
  match s with
  | .none | .greedy | .evening => flexKwh
  | .shift => shiftIntoSun pvKwh flexKwh

end StoragePolicySim
````

