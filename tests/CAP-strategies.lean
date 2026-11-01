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
