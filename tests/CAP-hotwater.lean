/-
Component checks of CAP-hotwater (hot-water tank with a thermostat), for CH-0007 (hot-water tank
with a thermostat).

The checks call only `TankConfig`, `defaultTank`, `TankState`, `startState`, `TankStep`,
`tankStep`, `drawKwh` and `drawFactor`. No entry of the Interface can fail, so no check expects an
error code. The `seed` argument of `drawFactor` is the only seam (`drawSeed`). No check uses the
clock.

The first checks of each requirement prove the lines of the spec. They have the names and the
numbers of the checks of CAP-hotwater in tests/acceptance/IN-0008.acceptance.lean. The checks
after them prove more of the same requirement: a field of the tank that the lines leave at its
default, an edge, a chain of hours, a sweep of states, and the seam.

In the lines of R1 to R3 the tank is the default tank with a cut-in of 0 kWh (`flatTank`) where
the line says so. The hour is 12, the thermostat is off, and the tank was full today (`stOff`).
-/
import StoragePolicySim.HotWater
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

def firstSome : List (Option String) → Option String
  | [] => none
  | some m :: _ => some m
  | none :: rest => firstSome rest

def sumF (xs : List Float) : Float := xs.foldl (fun acc x => acc + x) 0.0

def meanF (xs : List Float) : Float :=
  if xs.isEmpty then 0.0 else sumF xs / xs.length.toFloat

/-- The standard deviation of a list. The divisor is the count. -/
def stdF (xs : List Float) : Float :=
  let m := meanF xs
  Float.sqrt (meanF (xs.map (fun x => (x - m) * (x - m))))

/-- The skewness of a list. It is 0 for a normal curve. -/
def skewF (xs : List Float) : Float :=
  let m := meanF xs
  let s := stdF xs
  meanF (xs.map (fun x => (x - m) * (x - m) * (x - m))) / (s * s * s)

/-- The excess kurtosis of a list. It is 0 for a normal curve. -/
def kurtF (xs : List Float) : Float :=
  let m := meanF xs
  let s := stdF xs
  meanF (xs.map (fun x => (x - m) * (x - m) * (x - m) * (x - m))) / (s * s * s * s) - 3.0

/-- Compares named values with a tolerance. Gives the first value that is wrong. -/
def valsIs (tol : Float) (pairs : List (String × Float × Float)) : Option String :=
  match pairs.find? (fun p => !near p.2.1 p.2.2 tol) with
  | some p => some s!"{p.1} is {p.2.1}, want {p.2.2}"
  | none => none

-- Helpers for the tank

/-- The default tank with a cut-in of 0 kWh, so that the thermostat stays out of a line. -/
def flatTank : TankConfig := { defaultTank with cutInKwh := 0.0 }

/-- A tank that differs from the default tank in each field that a rule reads. -/
def oddTank : TankConfig :=
  { defaultTank with
      capacityKwh := 9.0, elementKw := 2.0, lossPerHour := 0.02,
      cutInKwh := 7.0, floorKwh := 1.0, guardHour := 10 }

/-- A state with the thermostat off and with the tank full today. -/
def stOff (e : Float) : TankState := { energyKwh := e, heating := false, fullToday := true }

/-- A state with the thermostat on and with the tank full today. -/
def stOn (e : Float) : TankState := { energyKwh := e, heating := true, fullToday := true }

/-- A state with the thermostat off and with the tank not full today. -/
def stOpen (e : Float) : TankState := { energyKwh := e, heating := false, fullToday := false }

/-- The thermostat of the state after the hour must be on or off. -/
def thermoIs (s : TankStep) (want : Bool) : Option String :=
  if s.state.heating == want then none
  else some s!"the thermostat is {s.state.heating}, want {want}"

/-- `fullToday` of the state after the hour must be true or false. -/
def fullIs (s : TankStep) (want : Bool) : Option String :=
  if s.state.fullToday == want then none
  else some s!"fullToday is {s.state.fullToday}, want {want}"

-- Helpers for the draw

/-- The draw of one day, from the 24 hours. -/
def drawOfDay (daily lat : Float) (d : Nat) : Float :=
  (List.range 24).foldl (fun acc h => acc + drawKwh daily lat d h) 0.0

/-- The draw of the days 0 to 364. -/
def drawOfYear (daily lat : Float) : Float :=
  (List.range 365).foldl (fun acc d => acc + drawOfDay daily lat d) 0.0

/-- The share of each hour in the draw of a day, for a daily energy of 6.0 kWh. -/
def sharesOf (lat : Float) (d : Nat) : List Float :=
  let t := drawOfDay 6.0 lat d
  (List.range 24).map (fun h => drawKwh 6.0 lat d h / t)

/-- The seasonal factor of the spec: 1 + 0.15 × cos(2π × (day - peak) / 365). -/
def seasonOf (peak d : Nat) : Float :=
  1.0 + 0.15 * Float.cos (2.0 * 3.141592653589793 * (d.toFloat - peak.toFloat) / 365.0)

/-- Finds the first day whose draw is not 6.0 kWh times the seasonal factor of its peak. -/
def badSeason (lat : Float) (peak : Nat) (days : List Nat) : Option String :=
  match days.find? (fun d => !near (drawOfDay 6.0 lat d) (6.0 * seasonOf peak d) 0.000001) with
  | some d =>
    some s!"latitude {lat}, day {d} draws {drawOfDay 6.0 lat d}, want {6.0 * seasonOf peak d}"
  | none => none

-- Helpers for the factor

/-- The factors of the days 0 to `n - 1`. -/
def factorsOf (seed : Nat) (cv : Float) (n : Nat) : List Float :=
  (List.range n).map (fun d => drawFactor seed d cv)

/-- The normal number z of a day. The factor is `exp(cv × z - cv × cv / 2)`, so this undoes it. -/
def zOf (seed day : Nat) (cv : Float) : Float :=
  (Float.log (drawFactor seed day cv) + cv * cv / 2.0) / cv

/-- The factors of a seed over 5000 days with a spread of 0.25 must be above 0, with a mean from
0.98 to 1.02 and a standard deviation from 0.23 to 0.27. -/
def seedStatsBad (seed : Nat) : Option String :=
  let fs := factorsOf seed 0.25 5000
  let m := meanF fs
  let sd := stdF fs
  firstFail [
    (fs.length == 5000, s!"seed {seed}: {fs.length} factors"),
    (fs.all (fun f => f > 0.0), s!"seed {seed}: a factor is not above 0"),
    (m ≥ 0.98 && m ≤ 1.02, s!"seed {seed}: mean {m}"),
    (sd ≥ 0.23 && sd ≤ 0.27, s!"seed {seed}: standard deviation {sd}")]

-- Helpers for the sweeps of states

def sweepEnergies : List Float := [0.0, 1.3, 4.0, 5.25, 6.1, 8.2, 9.9, 10.5]
def sweepHours : List Nat := [0, 9, 10, 12, 19, 20, 23]
def sweepRequests : List Float := [0.0, 1.0, 4.0]
def sweepDraws : List Float := [0.0, 0.5, 5.0]

/-- Runs one hour for each combination of a stored energy, a thermostat state, a `fullToday`
state, an hour, a request and a draw. Gives the first combination for which `rule` finds a
problem. A state that no real day makes is left out: more energy than the capacity, or a tank at
its capacity that was not full today in an hour after hour 0. -/
def sweepRule (cfg : TankConfig)
    (rule : TankConfig → TankState → Nat → Float → Float → TankStep → Option String) :
    Option String := Id.run do
  for e in sweepEnergies do
    for thermo in [false, true] do
      for full in [false, true] do
        for hour in sweepHours do
          for req in sweepRequests do
            for dr in sweepDraws do
              let tooMuch : Bool := decide (e > cfg.capacityKwh + 1e-9)
              let atCap : Bool := decide (e ≥ cfg.capacityKwh - 1e-9)
              let impossible := tooMuch || (hour != 0 && atCap && !full)
              if !impossible then
                let st : TankState := { energyKwh := e, heating := thermo, fullToday := full }
                match rule cfg st hour req dr (tankStep cfg st hour req dr) with
                | some m =>
                  return some s!"energy {e}, thermostat {thermo}, fullToday {full}, hour {hour}, request {req}, draw {dr}: {m}"
                | none => pure ()
  return none

/-- The rules of R1 and R2 for one hour: the loss, the served draw and the unmet draw, the limits
of the heating, and the balance of the energy of the tank. The tolerance is wide enough for a
tank that rounds to its capacity. -/
def balanceBroken (cfg : TankConfig) (st : TankState) (_hour : Nat) (req dr : Float)
    (s : TankStep) : Option String :=
  let tol : Float := 1e-8
  let afterLoss := st.energyKwh - s.lossKwh
  let wantServed := if dr < afterLoss then dr else afterLoss
  let after := s.state.energyKwh
  let flows := afterLoss - s.servedKwh + s.heatKwh + s.backstopKwh
  firstFail [
    (near s.lossKwh (cfg.lossPerHour * st.energyKwh) tol, s!"the loss is {s.lossKwh}"),
    (near s.servedKwh wantServed tol, s!"the served draw is {s.servedKwh}, want {wantServed}"),
    (near (s.servedKwh + s.unmetKwh) dr tol,
      s!"the served draw {s.servedKwh} and the unmet draw {s.unmetKwh} do not add up to {dr}"),
    (s.heatKwh ≥ -tol && s.heatKwh ≤ req + tol && s.heatKwh ≤ cfg.elementKw + tol,
      s!"the heating is {s.heatKwh}"),
    (s.backstopKwh ≥ -tol && s.heatKwh + s.backstopKwh ≤ cfg.elementKw + tol,
      s!"the heating {s.heatKwh} and the backstop heating {s.backstopKwh} pass the element"),
    (after ≥ -tol && after ≤ cfg.capacityKwh + tol, s!"the tank holds {after}"),
    (near after flows tol, s!"the tank holds {after}, the flows give {flows}")]

/-- The rules of R3 for one hour. The level after the heating of the policy is the energy after
the hour, less the backstop heating. The thermostat is on at the start of the hour, or the level
is less than the cut-in, or the hour is from the guard hour in a tank that was not full today.
Then the backstop heating is the element power that the policy left, and never more than the room.
An hour whose level is at the cut-in is left out. The line gives the exact edge. -/
def thermoBroken (cfg : TankConfig) (st : TankState) (hour : Nat) (_req _dr : Float)
    (s : TankStep) : Option String :=
  let tol : Float := 1e-8
  let level := s.state.energyKwh - s.backstopKwh
  let fullBefore : Bool := hour != 0 && st.fullToday
  let guarded : Bool := decide (hour ≥ cfg.guardHour) && !fullBefore
  let below : Bool := decide (level < cfg.cutInKwh)
  let cut : Bool := st.heating || below || guarded
  let room := cfg.capacityKwh - level
  let left := cfg.elementKw - s.heatKwh
  let cap := if left < room then left else room
  let wantBackstop : Float := if !cut then 0.0 else if cap < 0.0 then 0.0 else cap
  let isFull := near s.state.energyKwh cfg.capacityKwh 1e-9
  if near level cfg.cutInKwh 1e-6 then none
  else
    firstFail [
      (near s.backstopKwh wantBackstop tol,
        s!"the backstop heating is {s.backstopKwh}, want {wantBackstop}"),
      (!isFull || s.state.heating == false, "the tank is full and the thermostat is on"),
      (s.backstopKwh ≤ tol || isFull || s.state.heating == true,
        "the thermostat is off after a backstop heating that did not fill the tank"),
      (cut || s.state.heating == false, "the thermostat is on, but it did not cut in")]

/-- The rule of R5 for one hour: `fullToday` is true when the tank is full after the hour, or
when it was true before the hour and the hour is not hour 0. -/
def fullTodayBroken (cfg : TankConfig) (st : TankState) (hour : Nat) (_req _dr : Float)
    (s : TankStep) : Option String :=
  let wantFull : Bool :=
    (hour != 0 && st.fullToday) || near s.state.energyKwh cfg.capacityKwh 1e-9
  if s.state.fullToday == wantFull then none
  else some s!"fullToday is {s.state.fullToday}, want {wantFull}"

/-- Runs the default tank from its start state with no request and no draw, for the 24 hours of a
day and then hour 0 of the next day. The tank loses 0.6% each hour. The guard hour 20 heats it to
full, because it was not full since hour 0. Gives the first rule that breaks. -/
def quietDay (_u : Unit) : Option String := Id.run do
  let mut st := startState defaultTank
  let mut level : Float := 10.5
  for i in List.range 25 do
    let hour := i % 24
    let s := tankStep defaultTank st hour 0.0 0.0
    let afterLoss := level * 0.994
    let wantLevel := if hour == 20 then 10.5 else afterLoss
    let wantBackstop := if hour == 20 then 10.5 - afterLoss else 0.0
    let wantFull : Bool := decide (hour ≥ 20)
    match firstFail [
        (near s.state.energyKwh wantLevel 1e-9,
          s!"the tank holds {s.state.energyKwh}, want {wantLevel}"),
        (near s.backstopKwh wantBackstop 1e-9,
          s!"the backstop heating is {s.backstopKwh}, want {wantBackstop}"),
        (s.state.heating == false, "the thermostat is on"),
        (s.state.fullToday == wantFull, s!"fullToday is {s.state.fullToday}, want {wantFull}")] with
    | some m => return some s!"hour {hour} (step {i}): {m}"
    | none => pure ()
    st := s.state
    level := wantLevel
  return none

def checks : List Check := [
  -- CAP-hotwater.R1
  { name := "CAP-hotwater.R1 8.0 kWh stored and no draw give a loss of 0.048 kWh and 7.952 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 8.0) 12 0.0 0.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.048), ("tank", s.state.energyKwh, 7.952)] },
  { name := "CAP-hotwater.R1 8.0 kWh stored and a draw of 1.5 kWh serve the draw and leave 6.452 kWh",
    run := do
      let s := tankStep flatTank (stOff 8.0) 12 0.0 1.5
      return valsIs 1e-9 [("loss", s.lossKwh, 0.048), ("served", s.servedKwh, 1.5),
        ("unmet", s.unmetKwh, 0.0), ("tank", s.state.energyKwh, 6.452)] },
  { name := "CAP-hotwater.R1 1.0 kWh stored and a draw of 2.0 kWh leave an unmet draw of 1.006 kWh",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.006), ("served", s.servedKwh, 0.994),
        ("unmet", s.unmetKwh, 1.006)] },
  { name := "CAP-hotwater.R1 0.0 kWh stored and a draw of 1.0 kWh give no loss and an unmet draw of 1.0 kWh",
    run := do
      let s := tankStep flatTank (stOff 0.0) 12 0.0 1.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.0), ("served", s.servedKwh, 0.0),
        ("unmet", s.unmetKwh, 1.0)] },
  { name := "CAP-hotwater.R1 10.5 kWh stored and no draw give a loss of 0.063 kWh",
    run := do
      let s := tankStep flatTank (stOff 10.5) 12 0.0 0.0
      return valsIs 1e-9 [("loss", s.lossKwh, 0.063)] },
  { name := "CAP-hotwater.R1 a tank with no loss keeps 5.0 kWh in an hour with no draw",
    run := do
      let s := tankStep { flatTank with lossPerHour := 0.0 } (stOff 5.0) 12 0.0 0.0
      return valsIs 1e-9 [("tank", s.state.energyKwh, 5.0)] },
  -- The line leaves the tank out. A draw above the stored energy leaves 0 kWh, not a negative value.
  { name := "CAP-hotwater.R1 a draw above the stored energy leaves 0.0 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("tank", s.state.energyKwh, 0.0)] },
  -- A version with a loss of 0.006 kWh in each tank fails here.
  { name := "CAP-hotwater.R1 a loss share of 0.01 gives a loss of 0.08 kWh at 8.0 kWh and leaves 6.42 kWh after a draw of 1.5 kWh",
    run := do
      let s := tankStep { flatTank with lossPerHour := 0.01 } (stOff 8.0) 12 0.0 1.5
      return valsIs 1e-9 [("loss", s.lossKwh, 0.08), ("served", s.servedKwh, 1.5),
        ("unmet", s.unmetKwh, 0.0), ("tank", s.state.energyKwh, 6.42)] },
  { name := "CAP-hotwater.R1 the default tank has a capacity of 10.5 kWh, an element of 3.0 kW, a loss of 0.006, a cut-in of 5.25 kWh, a floor of 2.1 kWh and a guard hour of 20",
    run := do
      let t := defaultTank
      return firstFail [
        (near t.capacityKwh 10.5 1e-9, s!"the capacity is {t.capacityKwh}"),
        (near t.elementKw 3.0 1e-9, s!"the element is {t.elementKw}"),
        (near t.lossPerHour 0.006 1e-12, s!"the loss share is {t.lossPerHour}"),
        (near t.cutInKwh 5.25 1e-9, s!"the cut-in is {t.cutInKwh}"),
        (near t.floorKwh 2.1 1e-9, s!"the floor is {t.floorKwh}"),
        (t.guardHour == 20, s!"the guard hour is {t.guardHour}")] },

  -- CAP-hotwater.R2
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 2.0 kWh give a heating of 2.0 kWh and 6.97 kWh in the tank",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 2.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 2.0), ("tank", s.state.energyKwh, 6.97)] },
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 5.0 kWh give a heating of 3.0 kWh, the element power",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 5.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 3.0), ("tank", s.state.energyKwh, 7.97)] },
  { name := "CAP-hotwater.R2 9.0 kWh stored and a request of 3.0 kWh give a heating of 1.554 kWh, the room that is left",
    run := do
      let s := tankStep flatTank (stOff 9.0) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 1.554), ("tank", s.state.energyKwh, 10.5)] },
  { name := "CAP-hotwater.R2 10.5 kWh stored and a request of 3.0 kWh give a heating of 0.063 kWh",
    run := do
      let s := tankStep flatTank (stOff 10.5) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 0.063), ("tank", s.state.energyKwh, 10.5)] },
  { name := "CAP-hotwater.R2 5.0 kWh stored and a request of 0 kWh give no heating",
    run := do
      let s := tankStep flatTank (stOff 5.0) 12 0.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 0.0)] },
  { name := "CAP-hotwater.R2 the draw comes before the heating: 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh leave an unmet draw of 0.512 kWh",
    run := do
      let s := tankStep flatTank (stOff 2.0) 12 3.0 2.5
      return valsIs 1e-9 [("served", s.servedKwh, 1.988), ("unmet", s.unmetKwh, 0.512),
        ("heating", s.heatKwh, 3.0), ("tank", s.state.energyKwh, 3.0)] },
  { name := "CAP-hotwater.R2 a tank with a capacity of 0 kWh has an unmet draw of 1.0 kWh and takes no heating",
    run := do
      let s := tankStep { flatTank with capacityKwh := 0.0 } (stOff 0.0) 12 3.0 1.0
      return valsIs 1e-9 [("unmet", s.unmetKwh, 1.0), ("heating", s.heatKwh, 0.0),
        ("tank", s.state.energyKwh, 0.0)] },
  -- A version with an element power of 3.0 kW in each tank fails here.
  { name := "CAP-hotwater.R2 an element of 1.0 kW limits the heating to 1.0 kWh",
    run := do
      let s := tankStep { flatTank with elementKw := 1.0 } (stOff 5.0) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("tank", s.state.energyKwh, 5.97)] },
  -- A version with a capacity of 10.5 kWh in each tank fails here.
  { name := "CAP-hotwater.R2 a capacity of 6.0 kWh limits the heating to the room that is left, 1.03 kWh",
    run := do
      let s := tankStep { flatTank with capacityKwh := 6.0 } (stOff 5.0) 12 3.0 0.0
      return valsIs 1e-9 [("heating", s.heatKwh, 1.03), ("tank", s.state.energyKwh, 6.0)] },
  { name := "CAP-hotwater.R2 over a sweep of states of the default tank each hour keeps the energy balance and the limits of the heating",
    run := do
      return sweepRule defaultTank balanceBroken },
  { name := "CAP-hotwater.R2 over a sweep of states of a tank with other limits each hour keeps the energy balance and the limits of the heating",
    run := do
      return sweepRule oddTank balanceBroken },

  -- CAP-hotwater.R3
  { name := "CAP-hotwater.R3 a tank at 5.0 kWh cuts the thermostat in",
    run := do
      let s := tankStep defaultTank (stOff 5.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 7.97)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat off gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 6.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 5.964)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a tank at 6.0 kWh with the thermostat on keeps heating",
    run := do
      let s := tankStep defaultTank (stOn 6.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 8.964)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a tank at 9.0 kWh with the thermostat on heats to full and then the thermostat goes off",
    run := do
      let s := tankStep defaultTank (stOn 9.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 1.554), ("tank", s.state.energyKwh, 10.5)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a request of 2.0 kWh at 5.0 kWh keeps the thermostat off and gives no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 5.0) 12 2.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 2.0), ("backstop", s.backstopKwh, 0.0),
          ("tank", s.state.energyKwh, 6.97)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a request of 1.0 kWh at 4.0 kWh leaves 2.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 4.0) 12 1.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("backstop", s.backstopKwh, 2.0),
          ("tank", s.state.energyKwh, 6.976)],
        thermoIs s true] },
  { name := "CAP-hotwater.R3 a request of 1.0 kWh at 9.0 kWh with the thermostat on leaves 0.554 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOn 9.0) 12 1.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 1.0), ("backstop", s.backstopKwh, 0.554),
          ("tank", s.state.energyKwh, 10.5)],
        thermoIs s false] },
  { name := "CAP-hotwater.R3 a draw that empties the tank gives an unmet draw of 1.006 kWh and 3.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 1.0) 12 0.0 2.0
      return valsIs 1e-9 [("unmet", s.unmetKwh, 1.006), ("backstop", s.backstopKwh, 3.0),
        ("tank", s.state.energyKwh, 3.0)] },
  { name := "CAP-hotwater.R3 a cut-in of 0 kWh gives no backstop heating at 1.0 kWh",
    run := do
      let s := tankStep flatTank (stOff 1.0) 12 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  -- The thermostat cuts in when the tank holds less than the cut-in. A version with "at most"
  -- cuts in at 5.25 kWh. The tank has no loss, so 5.25 kWh is exact after the hour.
  { name := "CAP-hotwater.R3 with no loss a tank at 5.25 kWh keeps the thermostat off and a tank at 5.24 kWh cuts it in",
    run := do
      let t : TankConfig := { defaultTank with lossPerHour := 0.0 }
      let a := tankStep t (stOff 5.25) 12 0.0 0.0
      let b := tankStep t (stOff 5.24) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop at 5.25", a.backstopKwh, 0.0), ("tank at 5.25", a.state.energyKwh, 5.25)],
        thermoIs a false,
        valsIs 1e-9 [("backstop at 5.24", b.backstopKwh, 3.0), ("tank at 5.24", b.state.energyKwh, 8.24)],
        thermoIs b true] },
  -- The thermostat decides after the loss. 5.26 kWh is above the cut-in, and 5.22844 kWh is below.
  { name := "CAP-hotwater.R3 a tank at 5.26 kWh falls below the cut-in after the loss and the thermostat cuts in",
    run := do
      let s := tankStep defaultTank (stOff 5.26) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 8.22844)],
        thermoIs s true] },
  -- The thermostat decides after the draw. 5.3676 kWh is above the cut-in, and 5.1676 kWh is below.
  { name := "CAP-hotwater.R3 a tank at 5.4 kWh with a draw of 0.2 kWh falls below the cut-in after the draw and the thermostat cuts in",
    run := do
      let s := tankStep defaultTank (stOff 5.4) 12 0.0 0.2
      return firstSome [
        valsIs 1e-9 [("served", s.servedKwh, 0.2), ("unmet", s.unmetKwh, 0.0),
          ("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 8.1676)],
        thermoIs s true] },
  -- A version with a cut-in of 5.25 kWh in each tank fails here.
  { name := "CAP-hotwater.R3 a cut-in of 7.0 kWh cuts the thermostat in at 6.0 kWh and not at 8.0 kWh",
    run := do
      let t : TankConfig := { defaultTank with cutInKwh := 7.0 }
      let a := tankStep t (stOff 6.0) 12 0.0 0.0
      let b := tankStep t (stOff 8.0) 12 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop at 6.0", a.backstopKwh, 3.0), ("tank at 6.0", a.state.energyKwh, 8.964)],
        thermoIs a true,
        valsIs 1e-9 [("backstop at 8.0", b.backstopKwh, 0.0), ("tank at 8.0", b.state.energyKwh, 7.952)],
        thermoIs b false] },
  -- The state of one hour is the state of the next. The thermostat stays on at 5.982 kWh and at
  -- 8.946108 kWh, above the cut-in, and then it goes off when the tank is full.
  { name := "CAP-hotwater.R3 a cold tank at 3.0 kWh heats for three hours and then the thermostat goes off",
    run := do
      let a := tankStep defaultTank (stOff 3.0) 12 0.0 0.0
      let b := tankStep defaultTank a.state 13 0.0 0.0
      let c := tankStep defaultTank b.state 14 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("hour 12 backstop", a.backstopKwh, 3.0), ("hour 12 tank", a.state.energyKwh, 5.982)],
        thermoIs a true,
        valsIs 1e-9 [("hour 13 backstop", b.backstopKwh, 3.0), ("hour 13 tank", b.state.energyKwh, 8.946108)],
        thermoIs b true,
        valsIs 1e-9 [("hour 14 backstop", c.backstopKwh, 1.607568648), ("hour 14 tank", c.state.energyKwh, 10.5)],
        thermoIs c false] },
  { name := "CAP-hotwater.R3 over a sweep of states of the default tank the backstop heating and the thermostat follow the rules",
    run := do
      return sweepRule defaultTank thermoBroken },
  { name := "CAP-hotwater.R3 over a sweep of states of a tank with other limits the backstop heating and the thermostat follow the rules",
    run := do
      return sweepRule oddTank thermoBroken },

  -- CAP-hotwater.R4
  { name := "CAP-hotwater.R4 at latitude 45 the draw of the days 0 to 364 adds up to 2190.0 kWh",
    run := do
      let t := drawOfYear 6.0 45.0
      return if near t 2190.0 0.1 then none else some s!"got {t}" },
  { name := "CAP-hotwater.R4 at latitude 45 the 24 hours of day 100 add up to the seasonal draw",
    run := do
      let t := drawOfDay 6.0 45.0 100
      let want := 6.0 * (1.0 + 0.15 * Float.cos (2.0 * 3.141592653589793 * 85.0 / 365.0))
      return if near t want 0.000001 then none else some s!"got {t}, want {want}" },
  { name := "CAP-hotwater.R4 at latitude 45 the draw of day 15 is 1.34 to 1.37 times the draw of day 197",
    run := do
      let q := drawOfDay 6.0 45.0 15 / drawOfDay 6.0 45.0 197
      return if q ≥ 1.34 && q ≤ 1.37 then none else some s!"ratio {q}" },
  { name := "CAP-hotwater.R4 at latitude -41 the draw of day 197 is 1.34 to 1.37 times the draw of day 15",
    run := do
      let q := drawOfDay 6.0 (-41.0) 197 / drawOfDay 6.0 (-41.0) 15
      return if q ≥ 1.34 && q ≤ 1.37 then none else some s!"ratio {q}" },
  { name := "CAP-hotwater.R4 on day 100 hour 7 draws more than hour 3, and hour 19 draws more than hour 13",
    run := do
      let h7 := drawKwh 6.0 45.0 100 7
      let h3 := drawKwh 6.0 45.0 100 3
      let h19 := drawKwh 6.0 45.0 100 19
      let h13 := drawKwh 6.0 45.0 100 13
      return firstFail [
        (h7 > h3, s!"hour 7 draws {h7}, hour 3 draws {h3}"),
        (h19 > h13, s!"hour 19 draws {h19}, hour 13 draws {h13}")] },
  { name := "CAP-hotwater.R4 a daily energy of 0.0 kWh gives a draw of 0 kWh in each hour of day 100",
    run := do
      let bad := (List.range 24).find? (fun h => !near (drawKwh 0.0 45.0 100 h) 0.0 1e-12)
      return match bad with
        | some h => some s!"hour {h} draws {drawKwh 0.0 45.0 100 h}"
        | none => none },
  -- The line 2 proves day 100 only. A version with a wrong phase or period away from day 100,
  -- or with the wrong peak at a negative latitude, fails here.
  { name := "CAP-hotwater.R4 at latitude 45 each day of 0 to 364 draws 6.0 kWh times the seasonal factor with its peak on day 15",
    run := do
      return badSeason 45.0 15 (List.range 365) },
  { name := "CAP-hotwater.R4 at latitude -41 each day of 0 to 364 draws 6.0 kWh times the seasonal factor with its peak on day 197",
    run := do
      return badSeason (-41.0) 197 (List.range 365) },
  -- The peak is day 15 at latitude 0 or more, and day 197 at a negative latitude.
  { name := "CAP-hotwater.R4 the peak is day 15 at the latitudes 0, 10 and 80, and day 197 at the latitudes -0.5 and -80",
    run := do
      let days := [0, 15, 100, 197, 300, 364]
      return firstSome [badSeason 0.0 15 days, badSeason 10.0 15 days, badSeason 80.0 15 days,
        badSeason (-0.5) 197 days, badSeason (-80.0) 197 days] },
  -- The hours of a day share the daily energy by a fixed profile.
  { name := "CAP-hotwater.R4 each hour has the same share of the day on day 15, day 197 and day 300",
    run := do
      let a := sharesOf 45.0 15
      let b := sharesOf 45.0 197
      let c := sharesOf 45.0 300
      let same := fun (x y : List Float) =>
        x.length == 24 && y.length == 24 && (List.zip x y).all (fun p => near p.1 p.2 1e-9)
      return firstFail [
        (same a b, s!"day 15 gives {a}, day 197 gives {b}"),
        (same a c, s!"day 15 gives {a}, day 300 gives {c}")] },
  { name := "CAP-hotwater.R4 a daily energy of 12.0 kWh draws twice as much as 6.0 kWh in each hour of day 100",
    run := do
      let bad := (List.range 24).find? (fun h =>
        !near (drawKwh 12.0 45.0 100 h) (2.0 * drawKwh 6.0 45.0 100 h) 1e-9)
      return match bad with
        | some h => some s!"hour {h} draws {drawKwh 12.0 45.0 100 h}, 6.0 kWh draws {drawKwh 6.0 45.0 100 h}"
        | none => if drawKwh 12.0 45.0 100 7 > 0.0 then none else some "hour 7 draws 0 kWh" },

  -- CAP-hotwater.R5
  { name := "CAP-hotwater.R5 at hour 20 a tank at 9.0 kWh that was not full today heats to full",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 20 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 1.554), ("tank", s.state.energyKwh, 10.5)],
        fullIs s true] },
  { name := "CAP-hotwater.R5 at hour 19 a tank at 9.0 kWh that was not full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 19 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 8.946)],
        fullIs s false] },
  { name := "CAP-hotwater.R5 at hour 20 a tank at 9.0 kWh that was full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOff 9.0) 20 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0), ("tank", s.state.energyKwh, 8.946)] },
  { name := "CAP-hotwater.R5 at hour 22 a tank at 4.0 kWh that was not full today gets 3.0 kWh of backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 4.0) 22 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("backstop", s.backstopKwh, 3.0), ("tank", s.state.energyKwh, 6.976)],
        thermoIs s true] },
  { name := "CAP-hotwater.R5 at hour 0 a full tank loses energy and fullToday starts again as false",
    run := do
      let s := tankStep defaultTank (stOff 10.5) 0 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("tank", s.state.energyKwh, 10.437)],
        fullIs s false] },
  { name := "CAP-hotwater.R5 at hour 0 a request of 3.0 kWh at 10.5 kWh fills the tank and fullToday is true",
    run := do
      let s := tankStep defaultTank (stOpen 10.5) 0 3.0 0.0
      return firstSome [
        valsIs 1e-9 [("heating", s.heatKwh, 0.063), ("tank", s.state.energyKwh, 10.5)],
        fullIs s true] },
  { name := "CAP-hotwater.R5 at hour 12 a tank at 9.0 kWh that was not full today gets no backstop heating",
    run := do
      let s := tankStep defaultTank (stOpen 9.0) 12 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  { name := "CAP-hotwater.R5 a guard hour of 24 gives no backstop heating at hour 23",
    run := do
      let s := tankStep { defaultTank with guardHour := 24 } (stOpen 9.0) 23 0.0 0.0
      return valsIs 1e-9 [("backstop", s.backstopKwh, 0.0)] },
  { name := "CAP-hotwater.R5 the start state of the default tank is full with the thermostat off and fullToday true",
    run := do
      let st := startState defaultTank
      return firstFail [
        (near st.energyKwh 10.5 1e-9, s!"the tank holds {st.energyKwh} kWh"),
        (st.heating == false, "the thermostat is on"),
        (st.fullToday == true, "fullToday is false")] },
  -- fullToday stays true to the end of the day. A version that sets it from the energy at the end
  -- of each hour sets it to false here.
  { name := "CAP-hotwater.R5 fullToday stays true in an hour after which the tank is no longer full",
    run := do
      let a := tankStep defaultTank (stOff 10.5) 1 0.0 0.0
      let b := tankStep defaultTank (stOff 9.0) 20 0.0 0.0
      let c := tankStep defaultTank (stOff 9.0) 23 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("hour 1 tank", a.state.energyKwh, 10.437)], fullIs a true,
        valsIs 1e-9 [("hour 20 tank", b.state.energyKwh, 8.946)], fullIs b true,
        valsIs 1e-9 [("hour 23 tank", c.state.energyKwh, 8.946)], fullIs c true] },
  -- A tank is full when it holds its capacity within 0.000000001 kWh. The tank has no loss.
  { name := "CAP-hotwater.R5 a tank 0.0000000005 kWh below its capacity is full, and a tank 0.000000002 kWh below it is not",
    run := do
      let t : TankConfig := { defaultTank with lossPerHour := 0.0 }
      let a := tankStep t (stOpen (10.5 - 0.0000000005)) 12 0.0 0.0
      let b := tankStep t (stOpen (10.5 - 0.000000002)) 12 0.0 0.0
      return firstSome [fullIs a true, fullIs b false] },
  -- A version with a guard hour of 20 in each tank fails here.
  { name := "CAP-hotwater.R5 a guard hour of 10 gives backstop heating at hour 10 and none at hour 9",
    run := do
      let t : TankConfig := { defaultTank with guardHour := 10 }
      let a := tankStep t (stOpen 9.0) 10 0.0 0.0
      let b := tankStep t (stOpen 9.0) 9 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("hour 10 backstop", a.backstopKwh, 1.554), ("hour 10 tank", a.state.energyKwh, 10.5)],
        fullIs a true,
        valsIs 1e-9 [("hour 9 backstop", b.backstopKwh, 0.0), ("hour 9 tank", b.state.energyKwh, 8.946)],
        fullIs b false] },
  -- The state of one hour is the state of the next. The tank heats at hour 20, and again at
  -- hour 21 up to full. Then fullToday stays true, and the guard heats no more.
  { name := "CAP-hotwater.R5 a tank at 6.0 kWh that was not full heats to full at hour 21 and keeps fullToday to hour 23",
    run := do
      let a := tankStep defaultTank (stOpen 6.0) 20 0.0 0.0
      let b := tankStep defaultTank a.state 21 0.0 0.0
      let c := tankStep defaultTank b.state 22 0.0 0.0
      let d := tankStep defaultTank c.state 23 0.0 0.0
      return firstSome [
        valsIs 1e-9 [("hour 20 backstop", a.backstopKwh, 3.0), ("hour 20 tank", a.state.energyKwh, 8.964)],
        thermoIs a true, fullIs a false,
        valsIs 1e-9 [("hour 21 backstop", b.backstopKwh, 1.589784), ("hour 21 tank", b.state.energyKwh, 10.5)],
        thermoIs b false, fullIs b true,
        valsIs 1e-9 [("hour 22 backstop", c.backstopKwh, 0.0), ("hour 22 tank", c.state.energyKwh, 10.437)],
        fullIs c true,
        valsIs 1e-9 [("hour 23 backstop", d.backstopKwh, 0.0), ("hour 23 tank", d.state.energyKwh, 10.374378)],
        fullIs d true] },
  -- A day with no policy and no draw: the guard heats the tank to full at hour 20 only.
  { name := "CAP-hotwater.R5 a default tank with no policy and no draw heats to full at hour 20 and not at another hour",
    run := do
      return quietDay () },
  { name := "CAP-hotwater.R5 over a sweep of states of the default tank fullToday follows the rules",
    run := do
      return sweepRule defaultTank fullTodayBroken },
  { name := "CAP-hotwater.R5 over a sweep of states of a tank with other limits fullToday follows the rules",
    run := do
      return sweepRule oddTank fullTodayBroken },

  -- CAP-hotwater.R6
  { name := "CAP-hotwater.R6 a spread of 0 gives the factor 1.0 on each of the days 0 to 364",
    run := do
      let fs := factorsOf 7 0.0 365
      let bad := fs.find? (fun f => !near f 1.0 0.000000000001)
      return if fs.length == 365 && bad.isNone then none
        else some s!"{fs.length} factors, a wrong one is {bad}" },
  { name := "CAP-hotwater.R6 seed 7 and a spread of 0.25 give factors above 0 with a mean from 0.98 to 1.02 and a standard deviation from 0.23 to 0.27",
    run := do
      let fs := factorsOf 7 0.25 5000
      let m := meanF fs
      let sd := stdF fs
      return firstFail [
        (fs.length == 5000, s!"{fs.length} factors"),
        (fs.all (fun f => f > 0.0), "a factor is not above 0"),
        (m ≥ 0.98 && m ≤ 1.02, s!"mean {m}"),
        (sd ≥ 0.23 && sd ≤ 0.27, s!"standard deviation {sd}")] },
  { name := "CAP-hotwater.R6 seed 7 and a spread of 0.5 give a mean from 0.97 to 1.03 and a standard deviation from 0.48 to 0.58",
    run := do
      let fs := factorsOf 7 0.5 5000
      let m := meanF fs
      let sd := stdF fs
      return firstFail [
        (fs.length == 5000, s!"{fs.length} factors"),
        (m ≥ 0.97 && m ≤ 1.03, s!"mean {m}"),
        (sd ≥ 0.48 && sd ≤ 0.58, s!"standard deviation {sd}")] },
  { name := "CAP-hotwater.R6 the factor of the same day is the same two times",
    run := do
      let a := factorsOf 7 0.25 365
      let b := factorsOf 7 0.25 365
      return if a == b && a.length == 365 && !(a.all (fun f => f == 1.0)) then none
        else some "the two reads differ, or the factors do not vary" },
  { name := "CAP-hotwater.R6 seeds 7 and 8 give a different factor on at least 300 of the days 0 to 364",
    run := do
      let a := factorsOf 7 0.25 365
      let b := factorsOf 8 0.25 365
      let n := ((a.zip b).filter (fun p => !(p.1 == p.2))).length
      return if n ≥ 300 then none else some s!"{n} days differ" },
  -- The seam drawSeed. The statistics of the lines hold for the seed 7 only. Any seed gives a
  -- stream. A version that starts a generator from the seed, and gets stuck at seed 0, fails here.
  { name := "CAP-hotwater.R6 the seeds 0, 1 and 99991 give factors above 0 with a mean from 0.98 to 1.02 and a standard deviation from 0.23 to 0.27",
    run := do
      return firstSome [seedStatsBad 0, seedStatsBad 1, seedStatsBad 99991] },
  -- A version that makes the factors of seed 8 from the factors of seed 7, shifted by one day,
  -- passes the line of the seeds 7 and 8 and fails here.
  { name := "CAP-hotwater.R6 the seeds 7 and 8 do not give the same stream shifted by one day",
    run := do
      let a := factorsOf 7 0.25 365
      let b := factorsOf 8 0.25 365
      let n1 := ((a.tail.zip b).filter (fun p => !(p.1 == p.2))).length
      let n2 := ((b.tail.zip a).filter (fun p => !(p.1 == p.2))).length
      return firstFail [
        (a.length == 365 && b.length == 365, s!"{a.length} and {b.length} factors"),
        (n1 ≥ 300, s!"seed 7 on day d + 1 and seed 8 on day d differ on {n1} of 364 days"),
        (n2 ≥ 300, s!"seed 8 on day d + 1 and seed 7 on day d differ on {n2} of 364 days")] },
  -- The factor of a day comes from the day. A version that keeps a number for several days fails here.
  { name := "CAP-hotwater.R6 seed 7 gives a different factor on at least 300 of the 364 days that follow a day",
    run := do
      let fs := factorsOf 7 0.25 365
      let n := ((fs.zip fs.tail).filter (fun p => !(p.1 == p.2))).length
      return if fs.length == 365 && n ≥ 300 then none else some s!"{n} of 364 days differ" },
  -- The number z depends only on the seed and the day, not on the spread.
  { name := "CAP-hotwater.R6 the days 0 to 364 of seed 7 have the same number z for the spreads 0.1, 0.25 and 0.5",
    run := do
      let bad := (List.range 365).find? (fun d =>
        !(near (zOf 7 d 0.25) (zOf 7 d 0.1) 1e-9 && near (zOf 7 d 0.25) (zOf 7 d 0.5) 1e-9))
      return match bad with
        | some d => some s!"day {d}: z is {zOf 7 d 0.1}, {zOf 7 d 0.25} and {zOf 7 d 0.5}"
        | none => none },
  -- The number z is from a normal curve. A version that draws z from a uniform curve with the
  -- same mean and spread keeps the mean and the spread of the factor, and fails on the kurtosis.
  { name := "CAP-hotwater.R6 the number z of seed 7 over 5000 days is from a normal curve",
    run := do
      let zs := (List.range 5000).map (fun d => zOf 7 d 0.5)
      let m := meanF zs
      let sd := stdF zs
      let sk := skewF zs
      let ku := kurtF zs
      return firstFail [
        (zs.length == 5000, s!"{zs.length} numbers"),
        (m ≥ -0.06 && m ≤ 0.06, s!"mean of z is {m}, want 0"),
        (sd ≥ 0.95 && sd ≤ 1.05, s!"standard deviation of z is {sd}, want 1"),
        (sk ≥ -0.2 && sk ≤ 0.2, s!"skewness of z is {sk}, want 0"),
        (ku ≥ -0.5 && ku ≤ 0.5, s!"excess kurtosis of z is {ku}, want 0")] }
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
