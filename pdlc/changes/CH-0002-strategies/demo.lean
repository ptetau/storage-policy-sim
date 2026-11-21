import StoragePolicySim.Strategy
open StoragePolicySim

-- The demo of CH-0002 (strategies) for the visual review. Each key shows one acceptance line.
-- Run it from the project root: lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r1-1

def f2 (x : Float) : String :=
  let s := toString ((x * 100).round / 100)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 2).toString
  | _ => s

def day (pairs : List (Nat × Float)) : Array Float :=
  (Array.range 24).map fun h => (pairs.find? (·.1 == h)).map (·.2) |>.getD 0

def defaultFlex : Array Float := day [(18, 1), (19, 1), (20, 1)]

def showDay (label : String) (a : Array Float) : String :=
  let parts := (List.range 24).filterMap fun (h : Nat) =>
    let v : Float := a.getD h 0
    if v != 0 then some s!"{h}:00 {f2 v} kWh" else none
  s!"{label}: " ++ (if parts.isEmpty then "0 kWh in each hour" else ", ".intercalate parts)

def showDecide (s : Strategy) (hour : Nat) (surplus shortfall : Float) : String :=
  let r := s.decide hour surplus shortfall
  s!"{s.name}, {hour}:00, surplus {f2 surplus} kWh, shortfall {f2 shortfall} kWh\n" ++
    s!"→ charge {f2 r.chargeKwh} kWh, discharge {f2 r.dischargeKwh} kWh"

def showPlace (s : Strategy) (sun flex : Array Float) : String :=
  showDay "sun" sun ++ "\n" ++ showDay "flexible load before" flex ++ "\n" ++
    showDay s!"after {s.name} places the day" (s.placeFlex sun flex)

def sunnyDay : Array Float := day [(9, 1), (10, 2), (11, 3.5), (12, 3), (13, 4), (14, 1.5)]

def say (s : String) : IO Unit := IO.println s

def found (name : String) : String :=
  match Strategy.ofName? name with
  | some s => s!"find \"{name}\": the {s.name} strategy"
  | Option.none => s!"find \"{name}\": no result"

def run : String → IO Unit
  | "r1-1" => say s!"the list of strategies: {Strategy.all.map (·.name)}"
  | "r1-2" => say (found "greedy")
  | "r1-3" => say (found "Greedy")
  | "r1-4" => say (found "")
  | "r2-1" => say (showDecide .none 12 2 0)
  | "r2-2" => say (showDecide .none 19 0 1.5)
  | "r2-3" => say (showPlace .none sunnyDay defaultFlex)
  | "r3-1" => say (showDecide .greedy 12 2 0)
  | "r3-2" => say (showDecide .greedy 3 0 1.5)
  | "r3-3" => say (showDecide .greedy 13 0 1.5)
  | "r3-4" => say (showDecide .greedy 12 0 0)
  | "r3-5" => say (showPlace .greedy sunnyDay defaultFlex)
  | "r4-1" => say (showDecide .evening 12 2 0)
  | "r4-2" => say (showDecide .evening 16 0 1.5)
  | "r4-3" => say (showDecide .evening 17 0 1.5)
  | "r4-4" => say (showDecide .evening 23 0 1.5)
  | "r4-5" => say (showDecide .evening 0 0 1.5)
  | "r4-6" => say (showPlace .evening sunnyDay defaultFlex)
  | "r5-1" => say (showDecide .shift 12 2 0)
  | "r5-2" => say (showDecide .shift 3 0 1.5)
  | "r5-3" => say (showPlace .shift sunnyDay defaultFlex)
  | "r5-4" => say (showPlace .shift (day [(10, 2), (11, 2), (12, 2), (13, 2), (14, 2)]) defaultFlex)
  | "r5-5" => say (showPlace .shift (day []) defaultFlex)
  | "r5-6" => say (showPlace .shift (day [(12, 3)]) (day []))
  | k => say s!"unknown key {k}"

def main (args : List String) : IO Unit := run (args.headD "")
