import StoragePolicySim.Scenario
open StoragePolicySim

-- The demo of CH-0001 (scenario) for the visual review. Each key shows one acceptance line.
-- Run it from the project root: lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-1

def site (lat : Float) (pv : Float := 5) (flex : Float := 3) : Site :=
  { latitude := lat, pvKw := pv, dailyLoadKwh := 20, flexKwh := flex }

def f3 (x : Float) : String :=
  let s := toString ((x * 1000).round / 1000)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 3).toString
  | _ => s

def skyName : Sky → String
  | .sunny => "sunny" | .cloudy => "cloudy" | .overcast => "overcast"

def dayHours (hs : Array Hour) (d : Nat) : Array Hour := hs.filter (·.day == d)

def baseOfDay (hs : Array Hour) (d : Nat) : Float :=
  (dayHours hs d).foldl (fun a h => a + h.baseLoadKwh) 0

def total (hs : Array Hour) (f : Hour → Float) : Float := hs.foldl (fun a h => a + f h) 0

def inDecFeb (d : Nat) : Bool := d ≤ 58 || d ≥ 334
def inJunAug (d : Nat) : Bool := 151 ≤ d && d ≤ 242

def overcastDays (lat : Float) (pick : Nat → Bool) : Nat := Id.run do
  let mut n := 0
  for seed in [1:21] do
    let hs := scenario (site lat) seed 365
    for d in [0:365] do
      if pick d && hs[d * 24]!.sky == .overcast then n := n + 1
  return n

def say (s : String) : IO Unit := IO.println s

def run : String → IO Unit
  | "r1-1" => do
    let a := pvOutput (site 45) 171 12 .sunny
    let b := pvOutput (site 45) 354 12 .sunny
    say s!"latitude 45, sunny, 12:00\nday 171: {f3 a} kWh\nday 354: {f3 b} kWh\nratio: {f3 (a / b)} (more than 2)"
  | "r1-2" => do
    let a := pvOutput (site (-41)) 354 12 .sunny
    let b := pvOutput (site (-41)) 171 12 .sunny
    say s!"latitude -41, sunny, 12:00\nday 354: {f3 a} kWh\nday 171: {f3 b} kWh\nratio: {f3 (a / b)} (more than 2)"
  | "r1-3" => do
    let a := pvOutput (site 0) 171 12 .sunny
    let b := pvOutput (site 0) 354 12 .sunny
    say s!"latitude 0, sunny, 12:00\nday 171: {f3 a} kWh\nday 354: {f3 b} kWh\ndifference: {f3 ((a - b).abs / b * 100)}% (less than 1%)"
  | "r1-4" => do
    say s!"latitude 45, sunny, 00:00 on day 171: {f3 (pvOutput (site 45) 171 0 .sunny)} kWh"
  | "r1-5" => do
    let mut lo := 1000.0
    let mut hi := 0.0
    for d in [0:365] do
      for h in [0:24] do
        let v := pvOutput (site 45) d h .sunny
        lo := min lo v
        hi := max hi v
    say s!"latitude 45, each sunny hour of days 0 to 364\nlowest: {f3 lo} kWh\nhighest: {f3 hi} kWh (5 kWh or less)"
  | "r1-6" => do
    let s := pvOutput (site 45) 171 12 .sunny
    let c := pvOutput (site 45) 171 12 .cloudy
    say s!"latitude 45, day 171, 12:00\nsunny: {f3 s} kWh\ncloudy: {f3 c} kWh\ncloudy / sunny: {f3 (c / s)}"
  | "r1-7" => do
    let s := pvOutput (site 45) 171 12 .sunny
    let o := pvOutput (site 45) 171 12 .overcast
    say s!"latitude 45, day 171, 12:00\nsunny: {f3 s} kWh\novercast: {f3 o} kWh\novercast / sunny: {f3 (o / s)}"
  | "r1-8" => do
    say s!"latitude 45, 0 kW of panels, sunny, 12:00 on day 171: {f3 (pvOutput (site 45 0) 171 12 .sunny)} kWh"
  | "r2-1" => do
    let a := scenario (site 45) 7 365
    let b := scenario (site 45) 7 365
    let same := (a.zip b).all fun (x, y) => x.sky == y.sky && x.pvKwh == y.pvKwh && x.baseLoadKwh == y.baseLoadKwh
    say s!"seed 7, two runs of 365 days\nhours: {a.size} and {b.size}\nthe same hours: {same}"
  | "r2-2" => do
    let a := scenario (site 45) 7 365
    let b := scenario (site 45) 8 365
    let n := (List.range 365).filter (fun d => a[d * 24]!.sky != b[d * 24]!.sky) |>.length
    say s!"latitude 45, 365 days\ndays where seed 7 and seed 8 differ: {n} (50 or more)"
  | "r2-3" => do
    let a := scenario (site 45) 7 365
    let ordered := (List.range a.size).all fun i => a[i]!.day == i / 24 && a[i]!.hour == i % 24
    say s!"seed 7, 365 days\nhours: {a.size}\nfirst: day {a[0]!.day} hour {a[0]!.hour}\nlast: day {a[a.size - 1]!.day} hour {a[a.size - 1]!.hour}\nin order of day, then hour: {ordered}"
  | "r2-4" => do
    say s!"seed 7, 0 days\nhours: {(scenario (site 45) 7 0).size}"
  | "r2-5" => do
    let a := scenario (site 45) 7 365
    let one := (List.range 365).all fun d => (dayHours a d).all (·.sky == a[d * 24]!.sky)
    say s!"seed 7, 365 days\nfirst days: {(List.range 6).map (fun d => skyName a[d * 24]!.sky)}\neach day has one sky for its 24 hours: {one}"
  | "r2-6" => do
    let a := scenario (site 45) 7 365
    let worst := a.foldl (fun m h => max m (h.pvKwh - pvOutput (site 45) h.dayOfYear h.hour h.sky).abs) 0
    say s!"seed 7, 365 days\nlargest difference from R1 (seasonal sun): {worst} kWh (0.000001 or less)"
  | "r2-7" => do
    let w := overcastDays 45 inDecFeb
    let s := overcastDays 45 inJunAug
    say s!"latitude 45, seeds 1 to 20, 365 days each\novercast days, December to February: {w}\novercast days, June to August: {s}\nratio: {f3 (w.toFloat / s.toFloat)} (more than 2)"
  | "r2-8" => do
    let w := overcastDays (-41) inJunAug
    let s := overcastDays (-41) inDecFeb
    say s!"latitude -41, seeds 1 to 20, 365 days each\novercast days, June to August: {w}\novercast days, December to February: {s}\nratio: {f3 (w.toFloat / s.toFloat)} (more than 2)"
  | "r2-9" => do
    let a := scenario (site 45) 7 365
    let n := (List.range' 1 364).filter (fun d => a[d * 24]!.sky == a[(d - 1) * 24]!.sky) |>.length
    say s!"seed 7, days 1 to 364\ndays that keep the previous sky: {n} of 364 = {f3 (n.toFloat / 364 * 100)}% (60% or more)"
  | "r2-10" => do
    let a := scenario (site 45) 7 730
    say s!"seed 7, 730 days\nday 365 is day {a[365 * 24]!.dayOfYear} of the year\nday 729 is day {a[729 * 24]!.dayOfYear} of the year"
  | "r3-1" => do
    let a := scenario (site 45) 7 365
    say s!"latitude 45, 20 kWh a day, 365 days\ntotal load: {f3 (total a (fun h => h.baseLoadKwh + h.flexKwh))} kWh (7300)"
  | "r3-2" => do
    let a := scenario (site 45) 7 365
    say s!"latitude 45\nbase load, day 15: {f3 (baseOfDay a 15)} kWh\nbase load, day 197: {f3 (baseOfDay a 197)} kWh\nratio: {f3 (baseOfDay a 15 / baseOfDay a 197)} (1.45 to 1.55)"
  | "r3-3" => do
    let a := scenario (site (-41)) 7 365
    say s!"latitude -41\nbase load, day 197: {f3 (baseOfDay a 197)} kWh\nbase load, day 15: {f3 (baseOfDay a 15)} kWh\nratio: {f3 (baseOfDay a 197 / baseOfDay a 15)} (1.45 to 1.55)"
  | "r3-4" => do
    let a := scenario (site 45) 7 365
    say s!"latitude 45, day 100\nbase load at 19:00: {f3 a[100 * 24 + 19]!.baseLoadKwh} kWh\nbase load at 13:00: {f3 a[100 * 24 + 13]!.baseLoadKwh} kWh"
  | "r3-5" => do
    let a := scenario (site 45) 7 365
    say s!"latitude 45, day 100\nbase load at 07:00: {f3 a[100 * 24 + 7]!.baseLoadKwh} kWh\nbase load at 03:00: {f3 a[100 * 24 + 3]!.baseLoadKwh} kWh"
  | "r3-6" => do
    let a := scenario (site 45) 7 365
    let ok := a.all fun h => h.flexKwh == (if h.hour == 18 || h.hour == 19 || h.hour == 20 then 1 else 0)
    say s!"3 kWh of flexible load, day 0\nby hour: {(dayHours a 0).toList.map (fun h => f3 h.flexKwh)}\neach of the 365 days: 1 kWh at 18:00, 19:00 and 20:00, else 0: {ok}"
  | "r3-7" => do
    let a := scenario (site 45 5 0) 7 365
    say s!"0 kWh of flexible load, 365 days\nlargest flexible load of an hour: {a.foldl (fun m h => max m h.flexKwh) 0} kWh"
  | "r3-8" => do
    let a := scenario (site 45) 7 365
    let b := scenario (site 45) 8 365
    let same := (a.zip b).all fun (x, y) => x.baseLoadKwh == y.baseLoadKwh && x.flexKwh == y.flexKwh
    say s!"latitude 45, seed 7 and seed 8, 365 days\neach hour has the same base and flexible load: {same}"
  | k => say s!"unknown key {k}"

def main (args : List String) : IO Unit := run (args.headD "")
