/-
The harness of the slice tests. A test file ends with
`def main (args : List String) : IO UInt32 := Harness.run tests args`.
`tests/run.py` runs the program and reads its lines: `RUN <name>`, then `PASS <name>`,
`FAIL <name>: <message>` or `ERROR <name>: <message>`.
-/
namespace Harness

/-- One test. `run` gives `none` for a pass, and `some message` for a failure. -/
structure Test where
  name : String
  run : IO (Option String)

/-- The result of a `sim` process. -/
structure Out where
  code : UInt32
  out : String
  err : String
  deriving Repr, Inhabited

/-- True after a `sim` call of the test answered "not implemented". -/
initialize stubSeen : IO.Ref Bool ← IO.mkRef false

/-- True when `a` and `b` differ by `tol` or less. A NaN is never near. -/
def near (a b tol : Float) : Bool := (a - b).abs ≤ tol

/-- Runs `.lake/build/bin/sim` with the arguments, under `timeout 120`. -/
def sim (args : List String) : IO Out := do
  let r ← IO.Process.output
    { cmd := "timeout", args := #["120", ".lake/build/bin/sim"] ++ args.toArray }
  if (r.stderr.splitOn "not implemented").length > 1 then stubSeen.set true
  return { code := r.exitCode, out := r.stdout, err := r.stderr }

/-- The message of the first check that is false, or `none` when each check holds. -/
def firstFail (checks : List (Bool × String)) : Option String :=
  match checks.find? (fun (c : Bool × String) => !c.1) with
  | some c => some c.2
  | none => none

/-- One line: line breaks become spaces. -/
def oneLine (s : String) : String :=
  String.intercalate " " (s.splitOn "\n")

/-- Runs the tests from the index of `--from <k>` (default 0), and prints one result for each. -/
def run (tests : List Test) (args : List String) : IO UInt32 := do
  let start := match args with
    | "--from" :: k :: _ => k.toNat!
    | _ => 0
  let out ← IO.getStdout
  let mut failed := 0
  for t in tests.drop start do
    IO.println s!"RUN {t.name}"
    out.flush
    stubSeen.set false
    let res ← tryCatch (t.run) (fun e => pure (some s!"exception: {e}"))
    if (← stubSeen.get) then
      failed := failed + 1
      IO.println s!"ERROR {t.name}: not implemented"
    else match res with
      | none => IO.println s!"PASS {t.name}"
      | some msg =>
        failed := failed + 1
        IO.println s!"FAIL {t.name}: {oneLine msg}"
    out.flush
  return if failed > 0 then 1 else 0

end Harness
