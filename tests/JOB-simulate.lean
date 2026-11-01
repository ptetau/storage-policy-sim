/-
Component checks of JOB-simulate (simulate a year of solar and compare strategies), for
CH-0004 (the sim command).

Each check runs `.lake/build/bin/sim` as a process through `timeout 60`, and reads the exit
code, stdout and stderr. Some checks also call `simulate` of CH-0003 (simulation), with
`Site`, `Battery` and `Strategy`, to compare the printed values. The `--seed` option is the
only seam. No check uses the clock.

Each error code of the Interface has at least one check that expects the exact line:
UNKNOWN_COMMAND, UNKNOWN_OPTION, MISSING_VALUE, BAD_NUMBER, OUT_OF_RANGE and
UNKNOWN_STRATEGY.

The defaults of `sim run` are latitude -41.3, 5 kW of panels, 20 kWh of daily load with
3 kWh flexible, a 10 kWh battery with 5 kW of power, `greedy`, seed 1 and 365 days.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

-- Helpers for numbers

def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- Rounds to one decimal, half away from zero. -/
def round1 (x : Float) : Float :=
  if x < 0 then -(Float.round (-x * 10)) / 10 else Float.round (x * 10) / 10

def firstFail : List (Bool × String) → Option String
  | [] => none
  | (true, _) :: rest => firstFail rest
  | (false, m) :: _ => some m

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

-- Helpers for the library

def site (lat : Float := -41.3) (pv : Float := 5) (load : Float := 20) (flex : Float := 3) :
    Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := load, flexKwh := flex }

def bat (cap : Float := 10) (power : Float := 5) : Battery :=
  { capacityKwh := cap, powerKw := power }

def monthNames : List String :=
  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

-- Helpers for the `sim` process

structure RunOut where
  code : UInt32
  out : String
  err : String

def sim (args : List String) : IO RunOut := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["60", ".lake/build/bin/sim"] ++ args.toArray }
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

def lines (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

def words (s : String) : List String := (s.splitOn " ").filter (fun w => w != "")

/-- A line of `sim run`: the label, spaces to fill 18 characters, and the value. -/
def row (label value : String) : String :=
  label ++ "".pushn ' ' (18 - label.length) ++ value

def runLabels : List String :=
  ["strategy", "days", "seed", "solar", "load", "self-used", "import", "export", "losses",
   "self-consumption", "self-sufficiency"]

def monthHeader : String :=
  "month solar-kWh load-kWh import-kWh export-kWh self-consumption-% self-sufficiency-%"

def compareHeader : String :=
  "strategy self-consumption-% self-sufficiency-% import-kWh export-kWh"

def usage : String := "usage: sim run [options] | sim compare [options]"

def firstWords (out : String) : List String :=
  (lines out).map (fun l => (words l).head?.getD "")

def valueOf (out label : String) : Option String :=
  match (lines out).find? (fun l => (words l).head? == some label) with
  | some l => (words l)[1]?
  | none => none

def numOf (out label : String) : Option Float := (valueOf out label).bind parseNum

def showsNum (s : Option String) (x : Float) : Bool :=
  match s.bind parseNum with
  | some v => near v (round1 x) 0.001
  | none => false

def totalsPairs (t : Totals) : List (String × Float) :=
  [("solar", t.pvKwh), ("load", t.loadKwh), ("self-used", t.selfUsedKwh),
   ("import", t.importKwh), ("export", t.exportKwh), ("losses", t.lossKwh),
   ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency)]

/-- Compares each value line of `sim run` with the totals of the simulation. -/
def checkShows (out : String) (t : Totals) : Option String :=
  match (totalsPairs t).find? (fun (l, x) => !showsNum (valueOf out l) x) with
  | some (l, x) => some s!"{l} shows {valueOf out l}, want {round1 x}"
  | none => none

def rowShows (r : String) (m : Month) : Bool :=
  let w := words r
  w.length == 7 && w[0]? == some m.name &&
  showsNum w[1]? m.totals.pvKwh && showsNum w[2]? m.totals.loadKwh &&
  showsNum w[3]? m.totals.importKwh && showsNum w[4]? m.totals.exportKwh &&
  showsNum w[5]? m.totals.selfConsumption && showsNum w[6]? m.totals.selfSufficiency

/-- The row of `sim compare` for a strategy, split into words. -/
def compareRow (out name : String) : Option (List String) :=
  ((lines out).find? (fun l => (words l).head? == some name)).map words

def compareShows (out : String) (s : Strategy) (t : Totals) : Bool :=
  match compareRow out s.name with
  | some w =>
    w.length == 5 && showsNum w[1]? t.selfConsumption && showsNum w[2]? t.selfSufficiency &&
    showsNum w[3]? t.importKwh && showsNum w[4]? t.exportKwh
  | none => false

def oneDecimal (v : String) : Bool :=
  match v.splitOn "." with
  | [a, b] => a != "" && b.length == 1 && (parseNum v).isSome
  | _ => false

/-- The label fills the first 18 characters with spaces, and the value starts at column 19. -/
def labelled (l label : String) : Bool :=
  let cs := l.toList
  cs.take 18 == (row label "").toList && cs.length > 18 && cs[18]? != some ' '

/-- Expects one exact error line on stderr, empty stdout, and exit code 2. -/
def expectError (args : List String) (line : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (lines r.err == [line], s!"sim {args}: stderr is {repr r.err}, want {repr line}")]

/-- Expects exit code 2, empty stdout, and stderr that starts with `pre`. -/
def expectStart (args : List String) (pre : String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 2, s!"sim {args}: exit code {r.code}, want 2"),
    (r.out == "", s!"sim {args}: stdout is {repr r.out}, want empty"),
    (r.err.startsWith pre, s!"sim {args}: stderr is {repr r.err}, want a start of {repr pre}")]

/-- Expects exit code 0, empty stderr, and the 11 lines of `sim run`. -/
def expectRun (args : List String) : IO (Option String) := do
  let r ← sim args
  return firstFail [
    (r.code == 0, s!"sim {args}: exit code {r.code}, stderr {repr r.err}"),
    (r.err == "", s!"sim {args}: stderr is {repr r.err}"),
    (firstWords r.out == runLabels, s!"sim {args}: stdout is {repr r.out}")]

/-- Runs the expectations in order and gives the first failure. -/
def allOf : List (IO (Option String)) → IO (Option String)
  | [] => pure none
  | c :: rest => do
    match ← c with
    | some m => return some m
    | none => allOf rest

/-- Each value of `ok` is accepted. Each pair of `bad` gives its exact error line. -/
def rangeOf (opt : String) (ok : List String) (bad : List (String × String)) :
    IO (Option String) :=
  allOf (ok.map (fun v => expectRun ["run", opt, v]) ++
    bad.map (fun p => expectError ["run", opt, p.1] p.2))

def checks : List Check := [
  -- JOB-simulate.R1
  { name := "JOB-simulate.R1 sim run prints the 11 lines in order and exits with 0",
    run := do
      let r ← sim ["run"]
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (r.err == "", s!"stderr is {repr r.err}"),
        ((lines r.out).length == 11, s!"{(lines r.out).length} lines"),
        (firstWords r.out == runLabels, s!"stdout is {repr r.out}")] },
  { name := "JOB-simulate.R1 each line has its label to column 19 and a value of the right form",
    run := do
      let r ← sim ["run"]
      let ls := lines r.out
      let bad := (List.range 11).find? (fun i =>
        let l := ls.getD i ""
        let w := words l
        !(labelled l (runLabels.getD i "") &&
          (if i < 3 then w.length == 2
           else if i < 9 then w.length == 3 && w[2]? == some "kWh" && oneDecimal (w.getD 1 "")
           else w.length == 3 && w[2]? == some "%" && oneDecimal (w.getD 1 ""))))
      return if r.code != 0 || ls.length != 11 then some s!"stdout is {repr r.out}"
        else match bad with
          | some i => some s!"the line {repr (ls.getD i "")} has the wrong form"
          | none => none },
  { name := "JOB-simulate.R1 the first three lines show greedy, 365 days and seed 1",
    run := do
      let r ← sim ["run"]
      let want := [row "strategy" "greedy", row "days" "365", row "seed" "1"]
      return if r.code == 0 && (lines r.out).take 3 == want then none
        else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --pv 0 shows 0.0 kWh of solar and 0.0 % self-consumption",
    run := do
      let r ← sim ["run", "--pv", "0"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls[3]? == some (row "solar" "0.0 kWh"), s!"the solar line is {ls[3]?}"),
        (ls[9]? == some (row "self-consumption" "0.0 %"), s!"the line is {ls[9]?}")] },
  { name := "JOB-simulate.R1 --strategy shift --days 30 --lat 45 shows the values of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "shift", "--days", "30", "--lat", "45"]
      let t := (simulate (site (lat := 45)) (bat) Strategy.shift 1 30).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "shift", row "days" "30", row "seed" "1"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
  { name := "JOB-simulate.R1 the defaults give the values of the simulation",
    run := do
      let r ← sim ["run"]
      let t := (simulate (site) (bat) Strategy.greedy 1 365).totals
      return (if r.code == 0 then none else some s!"exit code {r.code}") <|> checkShows r.out t },
  -- Each option has a value that differs from its default. Thus, a version that swaps two
  -- options, for example --battery and --power, fails here.
  { name := "JOB-simulate.R1 each option goes to its own part of the simulation",
    run := do
      let r ← sim ["run", "--strategy", "evening", "--days", "40", "--seed", "3", "--lat", "30",
        "--pv", "7.5", "--battery", "4", "--power", "2", "--load", "15", "--flex", "1.5"]
      let t := (simulate (site 30 7.5 15 1.5) (bat 4 2) Strategy.evening 3 40).totals
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        ((lines r.out).take 3 == [row "strategy" "evening", row "days" "40", row "seed" "3"],
          s!"stdout is {repr r.out}")] <|> checkShows r.out t },
  -- A version that keeps --flex at 3 with --load 2 fails the first run. A version that sets
  -- --flex to the --load value with --load 4 fails the second run.
  { name := "JOB-simulate.R1 the --flex default is 3, or the --load value when that is less",
    run := do
      let a ← sim ["run", "--load", "2", "--lat", "45"]
      let b ← sim ["run", "--load", "4", "--lat", "45"]
      let ta := (simulate (site 45 5 2 2) (bat) Strategy.greedy 1 365).totals
      let tb := (simulate (site 45 5 4 3) (bat) Strategy.greedy 1 365).totals
      return firstFail [
        (a.code == 0, s!"--load 2: exit code {a.code}, stderr {repr a.err}"),
        (b.code == 0, s!"--load 4: exit code {b.code}, stderr {repr b.err}")] <|>
        (checkShows a.out ta).map (s!"--load 2: " ++ ·) <|>
        (checkShows b.out tb).map (s!"--load 4: " ++ ·) },
  { name := "JOB-simulate.R1 --strategy none --battery 0 shows export as solar less self-used",
    run := do
      let r ← sim ["run", "--strategy", "none", "--battery", "0"]
      return match numOf r.out "solar", numOf r.out "self-used", numOf r.out "export" with
        | some s, some u, some e =>
          if r.code == 0 && s > 0 && e > 0 && near e (s - u) 0.1 then none
          else some s!"solar {s}, self-used {u}, export {e}"
        | _, _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R1 --days 3650 exits with 0 and shows 3650 days",
    run := do
      let r ← sim ["run", "--days", "3650"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "3650") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },

  -- JOB-simulate.R2
  { name := "JOB-simulate.R2 --monthly prints the 11 lines, a blank line, the header and 12 rows from Jan to Dec",
    run := do
      let r ← sim ["run", "--monthly"]
      let ls := lines r.out
      let rows := ls.drop 13
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 25, s!"{ls.length} lines, want 25"),
        ((ls.take 11).map (fun l => (words l).head?.getD "") == runLabels, "the 11 lines are wrong"),
        (ls[11]? == some "", s!"line 12 is {ls[11]?}, want blank"),
        (Option.map words ls[12]? == some (words monthHeader), s!"the header is {ls[12]?}"),
        (rows.map (fun l => (words l).head?.getD "") == monthNames, s!"rows {rows}"),
        (rows.all (fun l => (words l).length == 7), "a row does not have seven fields")] },
  { name := "JOB-simulate.R2 each row shows the totals of its month",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45", "--seed", "4"]
      let ms := (simulate (site (lat := 45)) (bat) Strategy.greedy 4 365).months
      let rows := (lines r.out).drop 13
      return if r.code == 0 && rows.length == ms.size && ms.size == 12 &&
          (rows.zip ms.toList).all (fun (l, m) => rowShows l m) then none
        else some s!"rows {rows}" },
  { name := "JOB-simulate.R2 --monthly --days 400 prints 14 rows that end with Jan and Feb",
    run := do
      let r ← sim ["run", "--monthly", "--days", "400"]
      let ms := (simulate (site) (bat) Strategy.greedy 1 400).months
      let rows := (lines r.out).drop 13
      let names := rows.map (fun l => (words l).head?.getD "")
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (rows.length == 14 && names.drop 12 == ["Jan", "Feb"], s!"rows {names}"),
        (ms.size == 14 && (rows.zip ms.toList).all (fun (l, m) => rowShows l m),
          s!"the rows do not show the months of the simulation: {rows}")] },
  { name := "JOB-simulate.R2 --monthly --lat 45 shows more than twice the Dec solar in Jul",
    run := do
      let r ← sim ["run", "--monthly", "--lat", "45"]
      let rows := (lines r.out).drop 13
      let solar := fun (n : String) =>
        (rows.find? (fun l => (words l).head? == some n)).bind (fun l => (words l)[1]?.bind parseNum)
      return match solar "Jul", solar "Dec" with
        | some j, some d => if r.code == 0 && d > 0 && j > 2 * d then none else some s!"Jul {j}, Dec {d}"
        | _, _ => some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 without --monthly sim run prints only the 11 lines",
    run := do
      let r ← sim ["run", "--lat", "45"]
      return if r.code == 0 && (lines r.out).length == 11 && firstWords r.out == runLabels
        then none else some s!"stdout is {repr r.out}" },
  { name := "JOB-simulate.R2 the 11 lines of --monthly are the lines of sim run",
    run := do
      let a ← sim ["run", "--lat", "45", "--monthly"]
      let b ← sim ["run", "--lat", "45"]
      return if a.code == 0 && b.code == 0 && (lines a.out).take 11 == lines b.out then none
        else some s!"--monthly {repr a.out}, without {repr b.out}" },

  -- JOB-simulate.R3
  { name := "JOB-simulate.R3 sim compare prints the header and none, greedy, evening and shift",
    run := do
      let r ← sim ["compare"]
      let ls := lines r.out
      return firstFail [
        (r.code == 0, s!"exit code {r.code}, stderr {repr r.err}"),
        (ls.length == 5, s!"{ls.length} lines, want 5"),
        (Option.map words ls[0]? == some (words compareHeader), s!"the header is {ls[0]?}"),
        (firstWords r.out == ["strategy", "none", "greedy", "evening", "shift"],
          s!"stdout is {repr r.out}"),
        ((ls.drop 1).all (fun l => (words l).length == 5), "a row does not have five fields")] },
  { name := "JOB-simulate.R3 the greedy row of --seed 9 --lat 45 shows the four values of sim run",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45"]
      let r ← sim ["run", "--seed", "9", "--lat", "45"]
      let fromRun := [valueOf r.out "self-consumption", valueOf r.out "self-sufficiency",
        valueOf r.out "import", valueOf r.out "export"]
      return match compareRow c.out "greedy" with
        | some w =>
          if c.code == 0 && r.code == 0 && fromRun.all Option.isSome &&
              fromRun == [w[1]?, w[2]?, w[3]?, w[4]?] then none
          else some s!"compare {w}, run {fromRun}"
        | none => some s!"no greedy row in {repr c.out}" },
  -- The options differ from the defaults. Thus, a version that ignores an option in
  -- sim compare fails here.
  { name := "JOB-simulate.R3 each row of sim compare shows the values of the simulation",
    run := do
      let c ← sim ["compare", "--seed", "9", "--lat", "45", "--battery", "4", "--load", "15",
        "--days", "100"]
      let bad := Strategy.all.find? (fun s =>
        !compareShows c.out s (simulate (site 45 5 15 3) (bat 4 5) s 9 100).totals)
      return if c.code != 0 then some s!"exit code {c.code}, stderr {repr c.err}"
        else match bad with
          | some s => some s!"the {s.name} row is wrong in {repr c.out}"
          | none => none },
  { name := "JOB-simulate.R3 --lat 45 gives greedy a higher self-consumption than none",
    run := do
      let c ← sim ["compare", "--lat", "45"]
      let sc := fun (n : String) => (compareRow c.out n).bind (fun w => w[1]?.bind parseNum)
      return match sc "greedy", sc "none" with
        | some g, some n => if c.code == 0 && g > n then none else some s!"greedy {g}, none {n}"
        | _, _ => some s!"stdout is {repr c.out}" },
  { name := "JOB-simulate.R3 sim compare --strategy greedy gives UNKNOWN_OPTION",
    run := expectError ["compare", "--strategy", "greedy"] "error: UNKNOWN_OPTION: --strategy" },
  { name := "JOB-simulate.R3 sim compare --monthly gives UNKNOWN_OPTION",
    run := expectError ["compare", "--monthly"] "error: UNKNOWN_OPTION: --monthly" },

  -- JOB-simulate.R4
  { name := "JOB-simulate.R4 --seed 5 gives the same output two times",
    run := do
      let a ← sim ["run", "--seed", "5"]
      let b ← sim ["run", "--seed", "5"]
      let c ← sim ["compare", "--seed", "5"]
      let d ← sim ["compare", "--seed", "5"]
      return firstFail [
        (a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11,
          s!"sim run: first {repr a.out}, second {repr b.out}"),
        (c.code == 0 && d.code == 0 && c.out == d.out && (lines c.out).length == 5,
          s!"sim compare: first {repr c.out}, second {repr d.out}")] },
  { name := "JOB-simulate.R4 --seed 1 and --seed 2 give different solar values",
    run := do
      let a ← sim ["run", "--seed", "1"]
      let b ← sim ["run", "--seed", "2"]
      let sa := valueOf a.out "solar"
      let sb := valueOf b.out "solar"
      return if a.code == 0 && b.code == 0 && sa.isSome && sb.isSome && sa != sb then none
        else some s!"seed 1 {sa}, seed 2 {sb}" },
  { name := "JOB-simulate.R4 --seed 2 gives the solar of the simulation with seed 2",
    run := do
      let r ← sim ["run", "--seed", "2"]
      let t := (simulate (site) (bat) Strategy.greedy 2 365).totals
      return if r.code == 0 && showsNum (valueOf r.out "solar") t.pvKwh then none
        else some s!"solar {valueOf r.out "solar"}, want {round1 t.pvKwh}" },

  -- JOB-simulate.R5
  { name := "JOB-simulate.R5 sim with no arguments prints the usage and exits with 0",
    run := do
      let r ← sim []
      return if r.code == 0 && (lines r.out).head? == some usage && r.err == "" then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 sim help and sim --help print the same usage and exit with 0",
    run := do
      let a ← sim []
      let h ← sim ["help"]
      let d ← sim ["--help"]
      return firstFail [
        (h.code == 0 && (lines h.out).head? == some usage && h.out == a.out,
          s!"sim help: exit code {h.code}, stdout {repr h.out}"),
        (d.code == 0 && (lines d.out).head? == some usage && d.out == a.out,
          s!"sim --help: exit code {d.code}, stdout {repr d.out}")] },
  { name := "JOB-simulate.R5 sim fly gives UNKNOWN_COMMAND",
    run := expectError ["fly"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 a command word that differs by its case or a space gives UNKNOWN_COMMAND",
    run := allOf [
      expectError ["Run"] "error: UNKNOWN_COMMAND: Run",
      expectError ["run "] "error: UNKNOWN_COMMAND: run ",
      expectError ["Compare"] "error: UNKNOWN_COMMAND: Compare"] },
  { name := "JOB-simulate.R5 --colour red gives UNKNOWN_OPTION",
    run := expectError ["run", "--colour", "red"] "error: UNKNOWN_OPTION: --colour" },
  { name := "JOB-simulate.R5 an option that differs by its case, a dash or an equals sign gives UNKNOWN_OPTION",
    run := allOf [
      expectError ["run", "--Days", "5"] "error: UNKNOWN_OPTION: --Days",
      expectError ["run", "-days", "5"] "error: UNKNOWN_OPTION: -days",
      expectError ["run", "--days=5"] "error: UNKNOWN_OPTION: --days=5"] },
  { name := "JOB-simulate.R5 sim run now gives UNKNOWN_OPTION",
    run := expectError ["run", "now"] "error: UNKNOWN_OPTION: now" },
  { name := "JOB-simulate.R5 --days with no value gives MISSING_VALUE",
    run := expectError ["run", "--days"] "error: MISSING_VALUE: --days" },
  { name := "JOB-simulate.R5 --strategy and --flex with no value give MISSING_VALUE",
    run := allOf [
      expectError ["run", "--strategy"] "error: MISSING_VALUE: --strategy",
      expectError ["run", "--days", "5", "--flex"] "error: MISSING_VALUE: --flex"] },
  { name := "JOB-simulate.R5 --days abc gives BAD_NUMBER",
    run := expectError ["run", "--days", "abc"] "error: BAD_NUMBER: --days abc" },
  { name := "JOB-simulate.R5 an empty --days gives BAD_NUMBER",
    run := expectError ["run", "--days", ""] "error: BAD_NUMBER: --days " },
  { name := "JOB-simulate.R5 --days 36.5 gives BAD_NUMBER",
    run := expectError ["run", "--days", "36.5"] "error: BAD_NUMBER: --days 36.5" },
  { name := "JOB-simulate.R5 a --days or --seed value that is close to a whole number gives BAD_NUMBER",
    run := allOf [
      expectError ["run", "--days", "2.0"] "error: BAD_NUMBER: --days 2.0",
      expectError ["run", "--days", " 2"] "error: BAD_NUMBER: --days  2",
      expectStart ["run", "--days", "2\n"] "error: BAD_NUMBER: --days 2\n",
      expectError ["run", "--seed", "1.5"] "error: BAD_NUMBER: --seed 1.5"] },
  { name := "JOB-simulate.R5 --days +2 is a whole number with a sign",
    run := do
      let r ← sim ["run", "--days", "+2"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "2") then none
        else some s!"exit code {r.code}, stdout {repr r.out}, stderr {repr r.err}" },
  { name := "JOB-simulate.R5 --pv 1e3, .5, 5. and 5kW give BAD_NUMBER",
    run := allOf [
      expectError ["run", "--pv", "1e3"] "error: BAD_NUMBER: --pv 1e3",
      expectError ["run", "--pv", ".5"] "error: BAD_NUMBER: --pv .5",
      expectError ["run", "--pv", "5."] "error: BAD_NUMBER: --pv 5.",
      expectError ["run", "--pv", "5kW"] "error: BAD_NUMBER: --pv 5kW"] },
  { name := "JOB-simulate.R5 a number with a trailing space, a lone sign or a misplaced sign gives BAD_NUMBER",
    run := allOf [
      expectError ["run", "--pv", "3 "] "error: BAD_NUMBER: --pv 3 ",
      expectError ["run", "--lat", "-"] "error: BAD_NUMBER: --lat -",
      expectError ["run", "--lat", "5-"] "error: BAD_NUMBER: --lat 5-",
      expectError ["run", "--load", "+-5"] "error: BAD_NUMBER: --load +-5"] },
  { name := "JOB-simulate.R5 --pv +3 gives the result of --pv 3",
    run := do
      let a ← sim ["run", "--pv", "+3"]
      let b ← sim ["run", "--pv", "3"]
      let d ← sim ["run"]
      return if a.code == 0 && b.code == 0 && a.out == b.out && (lines a.out).length == 11 &&
          valueOf a.out "solar" != valueOf d.out "solar" then none
        else some s!"+3 {repr a.out}, 3 {repr b.out}" },
  { name := "JOB-simulate.R5 --days 0 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "0"] "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 3651 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "3651"] "error: OUT_OF_RANGE: --days 3651 (1 to 3650)" },
  { name := "JOB-simulate.R5 --days 1 and --days 3650 are accepted",
    run := rangeOf "--days" ["1", "3650"] [] },
  { name := "JOB-simulate.R5 --days 99999999999999999999 gives OUT_OF_RANGE",
    run := expectError ["run", "--days", "99999999999999999999"]
      "error: OUT_OF_RANGE: --days 99999999999999999999 (1 to 3650)" },
  { name := "JOB-simulate.R5 --seed -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--seed", "-1"] "error: OUT_OF_RANGE: --seed -1 (0 to 4294967295)" },
  { name := "JOB-simulate.R5 --seed 0 and 4294967295 are accepted, and 4294967296 gives OUT_OF_RANGE",
    run := rangeOf "--seed" ["0", "4294967295"]
      [("4294967296", "error: OUT_OF_RANGE: --seed 4294967296 (0 to 4294967295)"),
       ("99999999999999999999", "error: OUT_OF_RANGE: --seed 99999999999999999999 (0 to 4294967295)")] },
  { name := "JOB-simulate.R5 --lat 90 and -90 are accepted, and 90.1 and -90.1 give OUT_OF_RANGE",
    run := rangeOf "--lat" ["90", "-90"]
      [("90.1", "error: OUT_OF_RANGE: --lat 90.1 (-90 to 90)"),
       ("-90.1", "error: OUT_OF_RANGE: --lat -90.1 (-90 to 90)")] },
  { name := "JOB-simulate.R5 --pv 0 and 100 are accepted, and 100.1 and -1 give OUT_OF_RANGE",
    run := rangeOf "--pv" ["0", "100"]
      [("100.1", "error: OUT_OF_RANGE: --pv 100.1 (0 to 100)"),
       ("-1", "error: OUT_OF_RANGE: --pv -1 (0 to 100)")] },
  { name := "JOB-simulate.R5 --battery 0 and 200 are accepted, and 200.1 and -0.1 give OUT_OF_RANGE",
    run := rangeOf "--battery" ["0", "200"]
      [("200.1", "error: OUT_OF_RANGE: --battery 200.1 (0 to 200)"),
       ("-0.1", "error: OUT_OF_RANGE: --battery -0.1 (0 to 200)")] },
  { name := "JOB-simulate.R5 --power 0 and 100 are accepted, and 100.1 gives OUT_OF_RANGE",
    run := rangeOf "--power" ["0", "100"]
      [("100.1", "error: OUT_OF_RANGE: --power 100.1 (0 to 100)")] },
  -- With --load 0.1 and no --flex, the --flex default is 0.1, the --load value.
  { name := "JOB-simulate.R5 --load 0.1 and 1000 are accepted, and 0 and 1000.1 give OUT_OF_RANGE",
    run := rangeOf "--load" ["0.1", "1000"]
      [("0", "error: OUT_OF_RANGE: --load 0 (0.1 to 1000)"),
       ("1000.1", "error: OUT_OF_RANGE: --load 1000.1 (0.1 to 1000)")] },
  { name := "JOB-simulate.R5 --load 10 --flex 10 is accepted",
    run := allOf [
      expectRun ["run", "--load", "10", "--flex", "10"],
      expectRun ["run", "--load", "10", "--flex", "0"]] },
  { name := "JOB-simulate.R5 --load 10 --flex 10.5 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "10", "--flex", "10.5"]
      "error: OUT_OF_RANGE: --flex 10.5 (0 to 10)" },
  { name := "JOB-simulate.R5 --flex -1 gives OUT_OF_RANGE",
    run := expectError ["run", "--load", "20", "--flex", "-1"]
      "error: OUT_OF_RANGE: --flex -1 (0 to 20)" },
  { name := "JOB-simulate.R5 the --flex range shows the last --load value as typed",
    run := allOf [
      expectError ["run", "--load", "10.0", "--flex", "10.5"]
        "error: OUT_OF_RANGE: --flex 10.5 (0 to 10.0)",
      expectError ["run", "--load", "10", "--load", "+2", "--flex", "3"]
        "error: OUT_OF_RANGE: --flex 3 (0 to +2)"] },
  { name := "JOB-simulate.R5 --strategy wild gives UNKNOWN_STRATEGY",
    run := expectError ["run", "--strategy", "wild"]
      "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)" },
  { name := "JOB-simulate.R5 a strategy name that differs by its case or a space gives UNKNOWN_STRATEGY",
    run := allOf [
      expectError ["run", "--strategy", "Greedy"]
        "error: UNKNOWN_STRATEGY: Greedy (none, greedy, evening, shift)",
      expectError ["run", "--strategy", "shift "]
        "error: UNKNOWN_STRATEGY: shift  (none, greedy, evening, shift)",
      expectError ["run", "--strategy", ""]
        "error: UNKNOWN_STRATEGY:  (none, greedy, evening, shift)"] },
  { name := "JOB-simulate.R5 each strategy name is accepted",
    run := allOf (Strategy.all.map (fun s => do
      let r ← sim ["run", "--strategy", s.name]
      return if r.code == 0 && (lines r.out).head? == some (row "strategy" s.name) then none
        else some s!"--strategy {s.name}: exit code {r.code}, stdout {repr r.out}")) },
  { name := "JOB-simulate.R5 --days 10 --days 20 shows 20 days",
    run := do
      let r ← sim ["run", "--days", "10", "--days", "20"]
      return if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"exit code {r.code}, stdout {repr r.out}" },
  { name := "JOB-simulate.R5 the last value counts before the range is read",
    run := do
      let r ← sim ["run", "--days", "0", "--days", "20"]
      let e ← expectError ["run", "--days", "20", "--days", "0"]
        "error: OUT_OF_RANGE: --days 0 (1 to 3650)"
      return (if r.code == 0 && (lines r.out)[1]? == some (row "days" "20") then none
        else some s!"--days 0 --days 20: exit code {r.code}, stderr {repr r.err}") <|> e },
  { name := "JOB-simulate.R5 the command word comes before each option",
    run := expectError ["fly", "--colour", "red"] "error: UNKNOWN_COMMAND: fly" },
  { name := "JOB-simulate.R5 the options are read from left to right and the first problem gives the error",
    run := allOf [
      expectError ["run", "--colour", "red", "--days", "abc"] "error: UNKNOWN_OPTION: --colour",
      expectError ["run", "--days", "abc", "--colour", "red"] "error: BAD_NUMBER: --days abc",
      expectError ["run", "--strategy", "wild", "--pv", "x"]
        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
      expectError ["run", "--pv", "x", "--days"] "error: BAD_NUMBER: --pv x"] },
  { name := "JOB-simulate.R5 a bad number or strategy comes before a range problem",
    run := allOf [
      expectError ["run", "--days", "0", "--pv", "x"] "error: BAD_NUMBER: --pv x",
      expectError ["run", "--days", "0", "--strategy", "wild"]
        "error: UNKNOWN_STRATEGY: wild (none, greedy, evening, shift)",
      expectError ["run", "--days", "0", "--colour"] "error: UNKNOWN_OPTION: --colour"] },
  { name := "JOB-simulate.R5 a range problem comes before the --flex check",
    run := expectError ["run", "--load", "2", "--flex", "5", "--days", "0"]
      "error: OUT_OF_RANGE: --days 0 (1 to 3650)" },
  { name := "JOB-simulate.R5 an error of sim compare gives the same line as an error of sim run",
    run := allOf [
      expectError ["compare", "--days", "abc"] "error: BAD_NUMBER: --days abc",
      expectError ["compare", "--lat", "91"] "error: OUT_OF_RANGE: --lat 91 (-90 to 90)",
      expectError ["compare", "--seed"] "error: MISSING_VALUE: --seed",
      expectError ["compare", "now"] "error: UNKNOWN_OPTION: now"] }
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
