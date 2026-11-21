import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Forecast
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim

open StoragePolicySim

/- ---------- helpers ---------- -/

def mk (name : String) (run : IO (Option String)) : Harness.Test := { name := name, run := run }

def sumF (xs : Array Float) : Float := xs.foldl (fun (a b : Float) => a + b) 0.0

def meanF (xs : Array Float) : Float :=
  if xs.size == 0 then 0.0 else sumF xs / xs.size.toFloat

def minF (xs : Array Float) : Float :=
  xs.foldl (fun (a b : Float) => if b < a then b else a) (xs[0]!)

def maxF (xs : Array Float) : Float :=
  xs.foldl (fun (a b : Float) => if b > a then b else a) (xs[0]!)

def win (s h : Nat) : TankWindow := { heatStart := s, heatHours := h }

def tHome : Home := defaultHome

def tStatic : Policy := Policy.static defaultStatic

def tZero : Policy := Policy.static { defaultStatic with windows := #[win 10 0] }

def tWeak : Home :=
  { tHome with tanks := tHome.tanks.map (fun (t : TankConfig) => { t with elementKw := 0.2 }) }

def tPerfect : Home := { tHome with errorScale := 0.0 }

def totalsOf (h : Home) (p : Policy) (seed seeds days : Nat) : Array HomeTotals :=
  (Array.range seeds).map (fun (i : Nat) => (runHome h p (seed + i) days).totals)

def showEv (ev : Evaluation) : String := s!"{repr ev}"

/-- The label, spaces to column 19, and the value. -/
def lbl (a v : String) : String :=
  a ++ String.join (List.replicate (18 - a.length) " ") ++ v

def outLines (s : String) : List String :=
  let l := s.splitOn "\n"
  if l.getLast? == some "" then l.dropLast else l

def toks (s : String) : List String :=
  (s.splitOn " ").filter (fun (t : String) => t != "")

def parseF (s : String) : Float :=
  let keep := s.toList.filter (fun (c : Char) => c.isDigit || c == '.')
  let t := String.join (keep.map (fun (c : Char) => c.toString))
  let parts := t.splitOn "."
  let whole := ((parts[0]?.getD "").toNat?).getD 0
  let frac := parts[1]?.getD ""
  let fracV := ((frac.toNat?).getD 0)
  Float.ofNat whole + Float.ofNat fracV / Float.ofNat (10 ^ frac.length)

def errIs (o : Harness.Out) (msg : String) : Option String :=
  Harness.firstFail [
    (o.code == 2, s!"exit code {o.code}, stderr: {o.err}"),
    (o.out == "", s!"stdout not empty: {o.out}"),
    (o.err.trimAscii.toString == msg, s!"stderr was: {o.err} expected: {msg}")]

def rowOf (o : Harness.Out) (name : String) : List String :=
  match ((outLines o.out).map toks).find? (fun (r : List String) => r.head? == some name) with
  | some r => r
  | none => []

def valOf (o : Harness.Out) (label : String) : String := (rowOf o label).drop 1 |>.headD ""

def headerRobust : String :=
  "policy mean-self-consumption-% worst-self-consumption-% mean-self-sufficiency-% mean-export-kWh mean-backstop-kWh unmet-kWh cold-hours starts-per-day safe"

def rowNames : List String :=
  ["thermostat", "static", "precomputed", "dynamic", "perfect-forecast"]

def cached (ref : IO.Ref (Option Harness.Out)) (args : List String) : IO Harness.Out := do
  match (← ref.get) with
  | some o =>
    if (o.err.splitOn "not implemented").length > 1 then Harness.stubSeen.set true
    return o
  | none =>
    let o ← Harness.sim args
    ref.set (some o)
    return o

initialize tuneCliRef : IO.Ref (Option Harness.Out) ← IO.mkRef none

def tuneCli : IO Harness.Out :=
  cached tuneCliRef ["policy", "tune", "--seeds", "2", "--days", "30"]

/- ---------- the candidates of D12 ---------- -/

def candidates : Array StaticParams := Id.run do
  let mut a : Array StaticParams := #[]
  for s in [6:17] do
    for h in [1:9] do
      for d in [15:23] do
        a := a.push { windows := #[win s h], dischargeFrom := d, flexStart := defaultStatic.flexStart }
  return a

initialize candRef : IO.Ref (Option (Array (StaticParams × Evaluation))) ← IO.mkRef none

def candEvals : IO (Array (StaticParams × Evaluation)) := do
  match (← candRef.get) with
  | some v => return v
  | none =>
    let v := candidates.map (fun (p : StaticParams) => (p, evaluate tHome (Policy.static p) 1 2 30))
    candRef.set (some v)
    return v

initialize tuneScRef : IO.Ref (Option TuneResult) ← IO.mkRef none
initialize tuneImRef : IO.Ref (Option TuneResult) ← IO.mkRef none

def tuneSc : IO TuneResult := do
  match (← tuneScRef.get) with
  | some v => return v
  | none =>
    let v := tuneStatic tHome Goal.selfConsumption 1 2 30
    tuneScRef.set (some v)
    return v

def tuneIm : IO TuneResult := do
  match (← tuneImRef.get) with
  | some v => return v
  | none =>
    let v := tuneStatic tHome Goal.gridImport 1 2 30
    tuneImRef.set (some v)
    return v

def safeOf (cs : Array (StaticParams × Evaluation)) : Array (StaticParams × Evaluation) :=
  cs.filter (fun (c : StaticParams × Evaluation) => c.2.unmetSeeds == 0)

/- ---------- R10 ---------- -/

def r10Mean : IO (Option String) := do
  let ev := evaluate tHome tStatic 3 4 365
  let ts := totalsOf tHome tStatic 3 4 365
  let m := meanF (ts.map (fun (t : HomeTotals) => t.selfConsumption))
  return Harness.firstFail [
    (Harness.near ev.meanSelfConsumption m 0.000001, s!"mean {ev.meanSelfConsumption} expected {m}")]

def r10Worst : IO (Option String) := do
  let ev := evaluate tHome tStatic 3 4 365
  let ts := totalsOf tHome tStatic 3 4 365
  let w := minF (ts.map (fun (t : HomeTotals) => t.selfConsumption))
  return Harness.firstFail [
    (Harness.near ev.worstSelfConsumption w 0.000001, s!"worst {ev.worstSelfConsumption} expected {w}")]

def r10SeedsCount : IO (Option String) := do
  let ev := evaluate tHome tStatic 3 4 365
  return Harness.firstFail [(ev.seeds == 4, s!"seeds {ev.seeds}")]

def r10Others : IO (Option String) := do
  let ev := evaluate tHome tStatic 3 4 90
  let ts := totalsOf tHome tStatic 3 4 90
  let avg := fun (f : HomeTotals → Float) => meanF (ts.map f)
  let cold := ts.foldl (fun (a : Nat) (t : HomeTotals) => a + t.coldHours) 0
  return Harness.firstFail [
    (Harness.near ev.meanSelfSufficiency (avg (fun (t : HomeTotals) => t.selfSufficiency)) 0.000001,
      s!"sufficiency {showEv ev}"),
    (Harness.near ev.meanImportKwh (avg (fun (t : HomeTotals) => t.importKwh)) 0.000001,
      s!"import {showEv ev}"),
    (Harness.near ev.meanExportKwh (avg (fun (t : HomeTotals) => t.exportKwh)) 0.000001,
      s!"export {showEv ev}"),
    (Harness.near ev.meanBackstopKwh (avg (fun (t : HomeTotals) => t.backstopKwh)) 0.000001,
      s!"backstop {showEv ev}"),
    (ev.coldHours == cold, s!"cold hours {ev.coldHours} expected {cold}")]

def r10UnmetTotal : IO (Option String) := do
  let ev := evaluate tWeak tZero 3 4 30
  let ts := totalsOf tWeak tZero 3 4 30
  let s := sumF (ts.map (fun (t : HomeTotals) => t.unmetKwh))
  return Harness.firstFail [
    (s > 0.0, s!"the runs have no unmet draw: {s}"),
    (Harness.near ev.totalUnmetKwh s 0.000001, s!"total unmet {ev.totalUnmetKwh} expected {s}")]

def r10UnmetSeeds : IO (Option String) := do
  let ev := evaluate tWeak tZero 3 4 30
  let ts := totalsOf tWeak tZero 3 4 30
  let n := (ts.filter (fun (t : HomeTotals) => t.unmetKwh > 0.0)).size
  return Harness.firstFail [
    (ev.unmetSeeds > 0, s!"unmetSeeds {ev.unmetSeeds}"),
    (ev.unmetSeeds == n, s!"unmetSeeds {ev.unmetSeeds} expected {n}")]

def r10ZeroSeeds : IO (Option String) := do
  let ev := evaluate tHome tStatic 3 0 30
  return Harness.firstFail [
    (ev.meanSelfConsumption == 0.0 && ev.worstSelfConsumption == 0.0 && ev.meanSelfSufficiency == 0.0,
      s!"ratios {showEv ev}"),
    (ev.meanImportKwh == 0.0 && ev.meanExportKwh == 0.0 && ev.meanCurtailedKwh == 0.0,
      s!"energies {showEv ev}"),
    (ev.meanBackstopKwh == 0.0 && ev.totalUnmetKwh == 0.0 && ev.meanStartsPerDay == 0.0,
      s!"others {showEv ev}"),
    (ev.seeds == 0 && ev.unmetSeeds == 0 && ev.coldHours == 0, s!"counts {showEv ev}")]

/- ---------- R11 ---------- -/

def r11Candidates : IO (Option String) := do
  let tr ← tuneSc
  return Harness.firstFail [(tr.candidates == 704, s!"candidates {tr.candidates}")]

def r11Safe : IO (Option String) := do
  let tr ← tuneSc
  return Harness.firstFail [(tr.safe == 704, s!"safe {tr.safe}")]

def r11ScWithinTie : IO (Option String) := do
  let tr ← tuneSc
  let cs ← candEvals
  let safe := safeOf cs
  let best := tr.evaluation.meanSelfConsumption
  let mx := maxF (safe.map (fun (c : StaticParams × Evaluation) => c.2.meanSelfConsumption))
  return Harness.firstFail [
    (safe.size > 0, "no safe candidate"),
    (mx <= best + 0.05 + 0.000000001, s!"best {best}, but a safe candidate has {mx}")]

def r11ScTieBreak : IO (Option String) := do
  let tr ← tuneSc
  let cs ← candEvals
  let safe := safeOf cs
  let mx := maxF (safe.map (fun (c : StaticParams × Evaluation) => c.2.meanSelfConsumption))
  let near := safe.filter (fun (c : StaticParams × Evaluation) =>
    c.2.meanSelfConsumption >= mx - 0.05)
  let minImp := minF (near.map (fun (c : StaticParams × Evaluation) => c.2.meanImportKwh))
  return Harness.firstFail [
    (tr.evaluation.meanSelfConsumption + 0.05 + 0.000000001 >= mx, s!"best not in the near tie of {mx}"),
    (tr.evaluation.meanImportKwh <= minImp + 0.000000001,
      s!"best import {tr.evaluation.meanImportKwh}, lowest import in the near tie {minImp}")]

def r11ImWithinTie : IO (Option String) := do
  let tr ← tuneIm
  let cs ← candEvals
  let safe := safeOf cs
  let best := tr.evaluation.meanImportKwh
  let mn := minF (safe.map (fun (c : StaticParams × Evaluation) => c.2.meanImportKwh))
  return Harness.firstFail [
    (safe.size > 0, "no safe candidate"),
    (mn >= best - 0.5 - 0.000000001, s!"best {best}, but a safe candidate has {mn}")]

def r11ImTieBreak : IO (Option String) := do
  let tr ← tuneIm
  let cs ← candEvals
  let safe := safeOf cs
  let mn := minF (safe.map (fun (c : StaticParams × Evaluation) => c.2.meanImportKwh))
  let near := safe.filter (fun (c : StaticParams × Evaluation) =>
    c.2.meanImportKwh <= mn + 0.5)
  let maxSc := maxF (near.map (fun (c : StaticParams × Evaluation) => c.2.meanSelfConsumption))
  return Harness.firstFail [
    (tr.evaluation.meanImportKwh <= mn + 0.5 + 0.000000001, s!"best not in the near tie of {mn}"),
    (tr.evaluation.meanSelfConsumption + 0.000000001 >= maxSc,
      s!"best self-consumption {tr.evaluation.meanSelfConsumption}, highest in the near tie {maxSc}")]

def r11BestInGrid : IO (Option String) := do
  let tr ← tuneSc
  let w := tr.best.windows[0]!
  return Harness.firstFail [
    (tr.best.windows.size == 1, s!"windows {repr tr.best}"),
    (w.heatStart >= 6 && w.heatStart <= 16, s!"heatStart {w.heatStart}"),
    (w.heatHours >= 1 && w.heatHours <= 8, s!"heatHours {w.heatHours}"),
    (tr.best.dischargeFrom >= 15 && tr.best.dischargeFrom <= 22, s!"dischargeFrom {tr.best.dischargeFrom}")]

def r11BestEvaluation : IO (Option String) := do
  let tr ← tuneSc
  let ev := evaluate tHome (Policy.static tr.best) 1 2 30
  return Harness.firstFail [
    (Harness.near tr.evaluation.meanSelfConsumption ev.meanSelfConsumption 0.000000001,
      s!"tune {showEv tr.evaluation} evaluate {showEv ev}"),
    (Harness.near tr.evaluation.meanImportKwh ev.meanImportKwh 0.000000001,
      s!"tune {showEv tr.evaluation} evaluate {showEv ev}"),
    (tr.evaluation.unmetSeeds == 0, s!"best is not safe: {showEv tr.evaluation}")]

/- ---------- R16 ---------- -/

def r16Header : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust"]
  let first := (outLines o.out).headD ""
  return Harness.firstFail [
    (o.code == 0, s!"exit {o.code}, stderr: {o.err}"),
    (" ".intercalate (toks first) == headerRobust, s!"header was: {first}")]

def r16Rows : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust"]
  let rows := ((outLines o.out).drop 1).map toks
  let names := rows.map (fun (r : List String) => r.headD "")
  return Harness.firstFail [
    (o.code == 0, s!"exit {o.code}, stderr: {o.err}"),
    (names == rowNames, s!"rows were {names}")]

def r16Safe : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust"]
  let checks := rowNames.map (fun (n : String) =>
    let r := rowOf o n
    (r.length == 10 && parseF (r[6]?.getD "x") == 0.0 && r[6]?.getD "x" != "x"
      && r[7]? == some "0" && r[9]? == some "yes", s!"row {n}: {r}"))
  return Harness.firstFail ((o.code == 0, s!"exit {o.code}, stderr: {o.err}") :: checks)

def r16WorstBelowMean : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust"]
  let checks := rowNames.map (fun (n : String) =>
    let r := rowOf o n
    (r.length == 10 && parseF (r[2]?.getD "") <= parseF (r[1]?.getD "") + 0.000000001, s!"row {n}: {r}"))
  return Harness.firstFail ((o.code == 0, s!"exit {o.code}, stderr: {o.err}") :: checks)

def rowCheck (o : Harness.Out) (name : String) (ev : Evaluation) : List (Bool × String) :=
  let r := rowOf o name
  let g := fun (i : Nat) => parseF (r[i]?.getD "")
  let safeS := if ev.unmetSeeds == 0 && ev.coldHours == 0 then "yes" else "no"
  let m := s!"row {name}: {r} expected {showEv ev}"
  [(r.length == 10, m),
   (Harness.near (g 1) ev.meanSelfConsumption 0.051, "mean self-consumption " ++ m),
   (Harness.near (g 2) ev.worstSelfConsumption 0.051, "worst self-consumption " ++ m),
   (Harness.near (g 3) ev.meanSelfSufficiency 0.051, "self-sufficiency " ++ m),
   (Harness.near (g 4) ev.meanExportKwh 0.051, "export " ++ m),
   (Harness.near (g 5) ev.meanBackstopKwh 0.051, "backstop " ++ m),
   (Harness.near (g 6) ev.totalUnmetKwh 0.051, "unmet " ++ m),
   (r[7]? == some (toString ev.coldHours), "cold hours " ++ m),
   (Harness.near (g 8) ev.meanStartsPerDay 0.051, "starts " ++ m),
   (r[9]? == some safeS, "safe " ++ m)]

def r16MatchEvaluate : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds", "2", "--days", "30", "--seed", "4"]
  let pre := Policy.precomputed defaultPlan
  let dyn := Policy.dynamic defaultDynamic
  let checks :=
    rowCheck o "thermostat" (evaluate tHome tZero 4 2 30)
    ++ rowCheck o "static" (evaluate tHome tStatic 4 2 30)
    ++ rowCheck o "precomputed" (evaluate tHome pre 4 2 30)
    ++ rowCheck o "dynamic" (evaluate tHome dyn 4 2 30)
    ++ rowCheck o "perfect-forecast" (evaluate tPerfect pre 4 2 30)
  return Harness.firstFail ((o.code == 0, s!"exit {o.code}, stderr: {o.err}") :: checks)

def r16WeakThermostat : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--element", "0.2", "--days", "90"]
  let r := rowOf o "thermostat"
  return Harness.firstFail [
    (o.code == 0, s!"exit {o.code}, stderr: {o.err}"),
    (r.length == 10 && r[9]? == some "no", s!"thermostat row: {r}")]

def r16SeedsZero : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds", "0"]
  return errIs o "error: OUT_OF_RANGE: --seeds 0 (1 to 100)"

def r16Seeds101 : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds", "101"]
  return errIs o "error: OUT_OF_RANGE: --seeds 101 (1 to 100)"

def r16SeedsNotWhole : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds", "2.5"]
  return errIs o "error: BAD_NUMBER: --seeds 2.5"

def r16SeedsText : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds", "<script>"]
  return errIs o "error: BAD_NUMBER: --seeds <script>"

def r16SeedsMissing : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds"]
  return errIs o "error: MISSING_VALUE: --seeds"

def r16DefaultSeeds : IO (Option String) := do
  let a ← Harness.sim ["policy", "robust", "--days", "3"]
  let b ← Harness.sim ["policy", "robust", "--seeds", "10", "--days", "3"]
  return Harness.firstFail [
    (a.code == 0 && b.code == 0, s!"exit {a.code} {b.code}, stderr: {a.err} {b.err}"),
    (a.out != "" && a.out == b.out, s!"default: {a.out} --seeds 10: {b.out}")]

def r16OneSeed : IO (Option String) := do
  let o ← Harness.sim ["policy", "robust", "--seeds", "1", "--days", "30"]
  let checks := rowNames.map (fun (n : String) =>
    let r := rowOf o n
    (r.length == 10 && r[1]? == r[2]?, s!"row {n}: {r}"))
  return Harness.firstFail ((o.code == 0, s!"exit {o.code}, stderr: {o.err}") :: checks)

/- ---------- R17 ---------- -/

def r17GoalLine : IO (Option String) := do
  let o ← tuneCli
  let l := (outLines o.out)[0]?.getD ""
  return Harness.firstFail [
    (o.code == 0, s!"exit {o.code}, stderr: {o.err}"),
    (l == lbl "goal" "self-consumption", s!"line 0 was: {l}")]

def r17CandidatesLine : IO (Option String) := do
  let o ← tuneCli
  let l := (outLines o.out)[1]?.getD ""
  return Harness.firstFail [(l == lbl "candidates" "704", s!"line 1 was: {l}")]

def r17SafeLine : IO (Option String) := do
  let o ← tuneCli
  let l := (outLines o.out)[2]?.getD ""
  return Harness.firstFail [(l == lbl "safe" "704", s!"line 2 was: {l}")]

def r17Layout : IO (Option String) := do
  let o ← tuneCli
  let ls := outLines o.out
  let label := fun (i : Nat) => ((ls[i]?.getD "").splitOn " ").headD "x"
  let names := (ls.drop 8).map (fun (l : String) => (toks l).headD "")
  return Harness.firstFail [
    (o.code == 0, s!"exit {o.code}, stderr: {o.err}"),
    (label 3 == "heat-start" && label 4 == "heat-hours" && label 5 == "discharge-from",
      s!"lines 3 to 5: {ls}"),
    ((ls[6]?).getD "x" == "", s!"line 6 is not blank: {ls}"),
    (" ".intercalate (toks (ls[7]?.getD "")) == headerRobust, s!"table header: {ls[7]?}"),
    (names == rowNames, s!"table rows {names}")]

def r17ProfileMatchesTune : IO (Option String) := do
  let o ← tuneCli
  let tr ← tuneSc
  let w := tr.best.windows[0]!
  return Harness.firstFail [
    (valOf o "heat-start" == toString w.heatStart, s!"heat-start {valOf o "heat-start"}, tuneStatic {w.heatStart}"),
    (valOf o "heat-hours" == toString w.heatHours, s!"heat-hours {valOf o "heat-hours"}, tuneStatic {w.heatHours}"),
    (valOf o "discharge-from" == toString tr.best.dischargeFrom,
      s!"discharge-from {valOf o "discharge-from"}, tuneStatic {tr.best.dischargeFrom}")]

def r17StaticRowEqualsRobust : IO (Option String) := do
  let o ← tuneCli
  let r ← Harness.sim ["policy", "robust", "--seeds", "2", "--days", "30",
    "--heat-start", valOf o "heat-start", "--heat-hours", valOf o "heat-hours",
    "--discharge-from", valOf o "discharge-from"]
  let a := rowOf o "static"
  let b := rowOf r "static"
  return Harness.firstFail [
    (r.code == 0, s!"robust exit {r.code}, stderr: {r.err}"),
    (a.length == 10, s!"tune static row: {a}"),
    (a == b, s!"tune row {a}, robust row {b}")]

def r17GoalImport : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--goal", "import", "--seeds", "2", "--days", "30"]
  let ls := outLines o.out
  return Harness.firstFail [
    (o.code == 0, s!"exit {o.code}, stderr: {o.err}"),
    ((ls[0]?).getD "" == lbl "goal" "import", s!"line 0: {ls[0]?}"),
    ((ls[1]?).getD "" == lbl "candidates" "704", s!"line 1: {ls[1]?}")]

def r17DefaultSeeds : IO (Option String) := do
  let a ← Harness.sim ["policy", "tune", "--days", "3"]
  let b ← Harness.sim ["policy", "tune", "--seeds", "5", "--days", "3"]
  return Harness.firstFail [
    (a.code == 0 && b.code == 0, s!"exit {a.code} {b.code}, stderr: {a.err} {b.err}"),
    (a.out != "" && a.out == b.out, s!"default: {a.out} --seeds 5: {b.out}")]

def r17UnknownGoal : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--goal", "cheap"]
  return errIs o "error: UNKNOWN_GOAL: cheap (self-consumption, import)"

def r17GoalMissing : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--goal"]
  return errIs o "error: MISSING_VALUE: --goal"

def r17HeatStartUnknown : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--heat-start", "10"]
  return errIs o "error: UNKNOWN_OPTION: --heat-start"

def r17HeatHoursUnknown : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--heat-hours", "3"]
  return errIs o "error: UNKNOWN_OPTION: --heat-hours"

def r17DischargeUnknown : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--discharge-from", "17"]
  return errIs o "error: UNKNOWN_OPTION: --discharge-from"

def r17SeedsZero : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--seeds", "0"]
  return errIs o "error: OUT_OF_RANGE: --seeds 0 (1 to 100)"

def r17SeedsBad : IO (Option String) := do
  let o ← Harness.sim ["policy", "tune", "--seeds", "1e3"]
  return errIs o "error: BAD_NUMBER: --seeds 1e3"

/- ---------- the list ---------- -/

def tests : List Harness.Test := [
  mk "test_001_S4_R10_mean_self_consumption_of_seeds_3_to_6" r10Mean,
  mk "test_001_S4_R10_worst_is_lowest_of_seeds_3_to_6" r10Worst,
  mk "test_001_S4_R10_seeds_count_is_4" r10SeedsCount,
  mk "test_001_S4_R10_other_means_and_cold_hours_sum" r10Others,
  mk "test_001_S4_R10_weak_element_total_unmet_is_sum_and_positive" r10UnmetTotal,
  mk "test_001_S4_R10_weak_element_counts_seeds_with_unmet_draw" r10UnmetSeeds,
  mk "test_001_S4_R10_zero_seeds_gives_zero_in_each_field" r10ZeroSeeds,
  mk "test_001_S4_R11_candidates_is_704" r11Candidates,
  mk "test_001_S4_R11_safe_is_704" r11Safe,
  mk "test_001_S4_R11_self_consumption_goal_best_within_near_tie" r11ScWithinTie,
  mk "test_001_S4_R11_self_consumption_goal_tie_goes_to_lowest_import" r11ScTieBreak,
  mk "test_001_S4_R11_import_goal_best_within_near_tie" r11ImWithinTie,
  mk "test_001_S4_R11_import_goal_tie_goes_to_highest_self_consumption" r11ImTieBreak,
  mk "test_001_S4_R11_best_profile_is_a_candidate_of_the_grid" r11BestInGrid,
  mk "test_001_S4_R11_best_evaluation_matches_evaluate" r11BestEvaluation,
  mk "test_001_S4_R16_header_line" r16Header,
  mk "test_001_S4_R16_five_rows_in_order" r16Rows,
  mk "test_001_S4_R16_rows_have_no_unmet_no_cold_and_are_safe" r16Safe,
  mk "test_001_S4_R16_worst_is_not_more_than_mean" r16WorstBelowMean,
  mk "test_001_S4_R16_rows_match_evaluate" r16MatchEvaluate,
  mk "test_001_S4_R16_weak_element_thermostat_is_not_safe" r16WeakThermostat,
  mk "test_001_S4_R16_seeds_0_out_of_range" r16SeedsZero,
  mk "test_001_S4_R16_seeds_101_out_of_range" r16Seeds101,
  mk "test_001_S4_R16_seeds_not_whole_is_bad_number" r16SeedsNotWhole,
  mk "test_001_S4_R16_seeds_text_is_bad_number_as_typed" r16SeedsText,
  mk "test_001_S4_R16_seeds_without_value_is_missing_value" r16SeedsMissing,
  mk "test_001_S4_R16_default_seeds_is_10" r16DefaultSeeds,
  mk "test_001_S4_R16_one_seed_worst_equals_mean" r16OneSeed,
  mk "test_001_S4_R17_goal_line" r17GoalLine,
  mk "test_001_S4_R17_candidates_line" r17CandidatesLine,
  mk "test_001_S4_R17_safe_line" r17SafeLine,
  mk "test_001_S4_R17_layout_profile_lines_blank_line_and_table" r17Layout,
  mk "test_001_S4_R17_profile_lines_match_tune_static" r17ProfileMatchesTune,
  mk "test_001_S4_R17_static_row_equals_robust_with_tuned_profile" r17StaticRowEqualsRobust,
  mk "test_001_S4_R17_goal_import_is_accepted" r17GoalImport,
  mk "test_001_S4_R17_default_seeds_is_5" r17DefaultSeeds,
  mk "test_001_S4_R17_unknown_goal" r17UnknownGoal,
  mk "test_001_S4_R17_goal_without_value_is_missing_value" r17GoalMissing,
  mk "test_001_S4_R17_heat_start_is_unknown_option" r17HeatStartUnknown,
  mk "test_001_S4_R17_heat_hours_is_unknown_option" r17HeatHoursUnknown,
  mk "test_001_S4_R17_discharge_from_is_unknown_option" r17DischargeUnknown,
  mk "test_001_S4_R17_seeds_0_out_of_range" r17SeedsZero,
  mk "test_001_S4_R17_seeds_1e3_is_bad_number" r17SeedsBad
]

def main (args : List String) : IO UInt32 := Harness.run tests args
