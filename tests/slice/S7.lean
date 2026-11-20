/-
Acceptance tests of slice S7 (simulate my home with two tanks): R21 (homes) and R22 (more tanks).
-/
import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy
import StoragePolicySim.Simulation
import StoragePolicySim.HotWater
import StoragePolicySim.Forecast
import StoragePolicySim.Policy
import StoragePolicySim.HomeSim
open StoragePolicySim

-- Helpers

def nr (a b tol : Float) : Bool := Harness.near a b tol

def outLines (s : String) : List String :=
  (s.splitOn "\n").filter (fun (l : String) => l != "")

def outTokens (l : String) : List String :=
  (l.splitOn " ").filter (fun (t : String) => t != "")

def parseDec (s : String) : Option Float :=
  let neg := s.startsWith "-"
  let body := if neg then (s.drop 1).toString else s
  let sign : Float := if neg then -1.0 else 1.0
  match body.splitOn "." with
  | [a] =>
    match a.toNat? with
    | some x => some (sign * x.toFloat)
    | none => none
  | [a, b] =>
    match a.toNat?, b.toNat? with
    | some x, some y => some (sign * (x.toFloat + y.toFloat / Float.pow 10.0 b.length.toFloat))
    | _, _ => none
  | _ => none

/-- The number of the line with this label: the second word, without a `%`. -/
def valueOf (out label : String) : Option Float :=
  match (outLines out).find? (fun (l : String) => (outTokens l).head? == some label) with
  | none => none
  | some l =>
    match (outTokens l)[1]? with
    | none => none
    | some t => parseDec (t.replace "%" "")

def showOut (o : Harness.Out) : String :=
  s!"code {o.code}, stdout [{Harness.oneLine o.out}], stderr [{Harness.oneLine o.err}]"

/-- The first label of `sim policy run` whose value is not the total, within one decimal. -/
def cliCheck (o : Harness.Out) (t : HomeTotals) : Option String := Id.run do
  let pairs : List (String × Float) :=
    [ ("solar", t.pvKwh), ("load", t.loadKwh), ("import", t.importKwh), ("export", t.exportKwh),
      ("curtailed", t.curtailedKwh), ("heating", t.heatKwh), ("backstop", t.backstopKwh),
      ("unmet-hot-water", t.unmetKwh), ("cold-hours", t.coldHours.toFloat),
      ("self-consumption", t.selfConsumption), ("self-sufficiency", t.selfSufficiency) ]
  for p in pairs do
    match valueOf o.out p.1 with
    | none => return some s!"no value for line {p.1}: {showOut o}"
    | some x =>
      if !nr x p.2 0.051 then
        return some s!"line {p.1} is {x}, runHome gives {p.2}"
  return none

def unknownHomeLine (name : String) : String :=
  s!"error: UNKNOWN_HOME: {name} (generic, small, family, no-battery, mine)"

-- R21: the home mine

def tMineValues : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let arrOk := fun (kw dir tilt : Float) =>
    h.arrays.any (fun (a : PanelArray) =>
      nr a.kw kw 0.000001 && nr a.direction dir 0.000001 && nr a.tilt tilt 0.000001)
  let sumKw := h.arrays.foldl (fun (acc : Float) (a : PanelArray) => acc + a.kw) 0.0
  let t0 := h.tanks[0]!
  let t1 := h.tanks[1]!
  return Harness.firstFail [
    (h.arrays.size == 5, s!"arrays: {h.arrays.size}, want 5"),
    (nr sumKw 14.88 0.000001, s!"array power sum {sumKw}, want 14.88"),
    (nr h.site.pvKw 14.88 0.000001, s!"site.pvKw {h.site.pvKw}, want 14.88"),
    (arrOk 4.32 0.0 15.0, "no array 4.32 kW north at 15"),
    (arrOk 2.88 270.0 30.0, "no array 2.88 kW west at 30"),
    (arrOk 2.88 90.0 30.0, "no array 2.88 kW east at 30"),
    (arrOk 2.40 0.0 30.0, "no array 2.40 kW north at 30"),
    (arrOk 2.40 180.0 30.0, "no array 2.40 kW south at 30"),
    (nr h.battery.capacityKwh 13.5 0.000001, s!"battery {h.battery.capacityKwh}, want 13.5"),
    (nr h.battery.powerKw 11.0 0.000001, s!"battery power {h.battery.powerKw}, want 11"),
    (nr h.limits.inverterKw 11.0 0.000001, s!"inverter {h.limits.inverterKw}, want 11"),
    (nr h.limits.exportKw 10.0 0.000001, s!"export limit {h.limits.exportKw}, want 10"),
    (h.tanks.size == 2, s!"tanks: {h.tanks.size}, want 2"),
    (nr t0.capacityKwh 13.1 0.000001, s!"tank 1 capacity {t0.capacityKwh}, want 13.1"),
    (nr t0.elementKw 3.3 0.000001, s!"tank 1 element {t0.elementKw}, want 3.3"),
    (nr t1.capacityKwh 9.4 0.000001, s!"tank 2 capacity {t1.capacityKwh}, want 9.4"),
    (nr t1.elementKw 2.5 0.000001, s!"tank 2 element {t1.elementKw}, want 2.5"),
    (nr t0.cutInKwh (t0.capacityKwh / 2.0) 0.000001, s!"tank 1 cut-in {t0.cutInKwh}, want half"),
    (nr t0.floorKwh (t0.capacityKwh * 0.2) 0.000001, s!"tank 1 floor {t0.floorKwh}, want 20%"),
    (nr t1.cutInKwh (t1.capacityKwh / 2.0) 0.000001, s!"tank 2 cut-in {t1.cutInKwh}, want half"),
    (nr t1.floorKwh (t1.capacityKwh * 0.2) 0.000001, s!"tank 2 floor {t1.floorKwh}, want 20%"),
    (nr h.drawKwhPerDay 11.0 0.000001, s!"draw {h.drawKwhPerDay}, want 11.0"),
    (h.drawShares.size == 2, s!"draw shares: {h.drawShares.size}, want 2"),
    (nr h.drawShares[0]! 0.58 0.005, s!"share 1 {h.drawShares[0]!}, want 0.58"),
    (nr h.drawShares[1]! 0.42 0.005, s!"share 2 {h.drawShares[1]!}, want 0.42"),
    (nr (h.drawShares[0]! + h.drawShares[1]!) 1.0 0.000000001, "shares do not add up to 1"),
    (nr h.site.latitude (-41.3) 0.000001, s!"latitude {h.site.latitude}, want -41.3"),
    (nr h.site.dailyLoadKwh 20.0 0.000001, s!"load {h.site.dailyLoadKwh}, want 20"),
    (nr h.site.flexKwh 3.0 0.000001, s!"flex {h.site.flexKwh}, want 3") ]

def tOtherHomes : IO (Option String) := do
  let some g := homeNamed "generic" | return some "homeNamed \"generic\" gave none"
  let some s := homeNamed "small" | return some "homeNamed \"small\" gave none"
  let some f := homeNamed "family" | return some "homeNamed \"family\" gave none"
  let some nb := homeNamed "no-battery" | return some "homeNamed \"no-battery\" gave none"
  let gt := g.tanks[0]!
  let st := s.tanks[0]!
  let ft := f.tanks[0]!
  let ga := g.arrays[0]!
  let sa := s.arrays[0]!
  let fa := f.arrays[0]!
  return Harness.firstFail [
    (g.arrays.size == 1, "generic: one array"),
    (nr ga.kw 5.0 0.000001 && nr ga.tilt 0.0 0.000001, "generic: one flat 5 kW array"),
    (nr g.battery.capacityKwh 10.0 0.000001 && nr g.battery.powerKw 5.0 0.000001,
      "generic: battery 10 kWh with 5 kW"),
    (nr g.limits.inverterKw 0.0 0.000001 && nr g.limits.exportKw 0.0 0.000001,
      "generic: no limits"),
    (g.tanks.size == 1 && nr gt.capacityKwh 10.5 0.000001 && nr gt.elementKw 3.0 0.000001,
      "generic: one tank of 10.5 kWh with 3.0 kW"),
    (nr g.site.latitude (-41.3) 0.000001 && nr g.site.dailyLoadKwh 20.0 0.000001
      && nr g.site.flexKwh 3.0 0.000001, "generic: latitude, load and flexible load"),
    (nr g.drawKwhPerDay 6.0 0.000001 && nr g.drawCv 0.25 0.000001, "generic: draw 6.0, spread 0.25"),
    (g.fetchesPerDay == 10 && nr g.errorScale 1.0 0.000001, "generic: 10 fetches, error scale 1"),
    (s.arrays.size == 1 && nr sa.kw 3.0 0.000001 && nr sa.direction 0.0 0.000001
      && nr sa.tilt 30.0 0.000001, "small: one north array of 3 kW at 30"),
    (nr s.battery.capacityKwh 5.0 0.000001 && nr s.battery.powerKw 3.0 0.000001,
      "small: battery 5 kWh with 3 kW"),
    (s.tanks.size == 1 && nr st.capacityKwh 7.1 0.000001 && nr st.elementKw 2.0 0.000001,
      "small: one tank of 7.1 kWh with 2 kW"),
    (nr st.cutInKwh (st.capacityKwh / 2.0) 0.000001 && nr st.floorKwh (st.capacityKwh * 0.2) 0.000001,
      "small: cut-in at half, floor at 20%"),
    (nr s.site.dailyLoadKwh 12.0 0.000001 && nr s.drawKwhPerDay 4.0 0.000001,
      "small: 12 kWh of load, 4 kWh of hot water"),
    (f.arrays.size == 1 && nr fa.kw 8.0 0.000001 && nr fa.direction 0.0 0.000001
      && nr fa.tilt 30.0 0.000001, "family: one north array of 8 kW at 30"),
    (nr f.battery.capacityKwh 13.5 0.000001 && nr f.battery.powerKw 5.0 0.000001,
      "family: battery 13.5 kWh with 5 kW"),
    (f.tanks.size == 1 && nr ft.capacityKwh 15.7 0.000001 && nr ft.elementKw 3.0 0.000001,
      "family: one tank of 15.7 kWh with 3 kW"),
    (nr ft.cutInKwh (ft.capacityKwh / 2.0) 0.000001 && nr ft.floorKwh (ft.capacityKwh * 0.2) 0.000001,
      "family: cut-in at half, floor at 20%"),
    (nr f.site.dailyLoadKwh 30.0 0.000001 && nr f.drawKwhPerDay 10.0 0.000001,
      "family: 30 kWh of load, 10 kWh of hot water"),
    (nr nb.battery.capacityKwh 0.0 0.000001, "no-battery: battery of 0 kWh"),
    (nb.arrays.size == 1 && nr nb.arrays[0]!.kw 5.0 0.000001 && nb.tanks.size == 1,
      "no-battery: the rest as generic") ]

def tHomeNames : IO (Option String) := do
  let want := ["generic", "small", "family", "no-battery", "mine"]
  return Harness.firstFail [
    (homeNames == want, s!"homeNames is {homeNames}, want {want}") ]

def tUnknownHomeNone : IO (Option String) := do
  return Harness.firstFail [
    ((homeNamed "mine").isSome, "homeNamed \"mine\" gave none"),
    ((homeNamed "castle").isNone, "homeNamed \"castle\" gave a home") ]

def tNoHomeEqualsGeneric : IO (Option String) := do
  let a ← Harness.sim ["policy", "run", "--days", "30"]
  let b ← Harness.sim ["policy", "run", "--home", "generic", "--days", "30"]
  let c ← Harness.sim ["policy", "compare", "--days", "30"]
  let d ← Harness.sim ["policy", "compare", "--home", "generic", "--days", "30"]
  return Harness.firstFail [
    (a.code == 0, s!"run without --home: {showOut a}"),
    (b.code == 0, s!"run --home generic: {showOut b}"),
    (a.out != "" && a.out == b.out, s!"run outputs differ: [{a.out}] and [{b.out}]"),
    (c.code == 0, s!"compare without --home: {showOut c}"),
    (d.code == 0, s!"compare --home generic: {showOut d}"),
    (c.out != "" && c.out == d.out, s!"compare outputs differ: [{c.out}] and [{d.out}]") ]

def tFamilyPv : IO (Option String) := do
  let a ← Harness.sim ["policy", "run", "--home", "family", "--pv", "6", "--days", "30"]
  let b ← Harness.sim ["policy", "run", "--home", "family", "--array", "6:0:0", "--days", "30"]
  let c ← Harness.sim ["policy", "run", "--home", "generic", "--pv", "6", "--days", "30"]
  let d ← Harness.sim ["policy", "run", "--home", "family", "--days", "30"]
  let some f := homeNamed "family" | return some "homeNamed \"family\" gave none"
  let flat : PanelArray := { f.arrays[0]! with kw := 6.0, direction := 0.0, tilt := 0.0 }
  let six : Home := { f with arrays := #[flat], site := { f.site with pvKw := 6.0 } }
  let r := runHome six (Policy.static defaultStatic) 1 30
  return Harness.firstFail [
    (a.code == 0, s!"family --pv 6: {showOut a}"),
    (d.code == 0, s!"family: {showOut d}"),
    ((cliCheck a r.totals).isNone,
      s!"family --pv 6 differs from family with one flat 6 kW array: {(cliCheck a r.totals).getD ""}"),
    (a.out == b.out, s!"--pv 6 is not one flat 6 kW array: [{a.out}] and [{b.out}]"),
    (valueOf a.out "solar" == valueOf c.out "solar" && (valueOf a.out "solar").isSome,
      s!"solar of family --pv 6 {valueOf a.out "solar"}, of generic --pv 6 {valueOf c.out "solar"}"),
    (a.out != d.out, "--pv 6 changed nothing of the family home") ]

def tUnknownHomeError : IO (Option String) := do
  let o ← Harness.sim ["policy", "run", "--home", "castle"]
  return Harness.firstFail [
    (o.code == 2, s!"exit code: {showOut o}"),
    (o.out == "", s!"stdout not empty: {showOut o}"),
    (o.err.trimAscii.toString == unknownHomeLine "castle", s!"stderr: {showOut o}") ]

def tUnknownHomeEcho : IO (Option String) := do
  let o ← Harness.sim ["policy", "run", "--home", "Mine"]
  let p ← Harness.sim ["policy", "compare", "--home", "castle"]
  return Harness.firstFail [
    (o.code == 2 && o.out == "", s!"run --home Mine: {showOut o}"),
    (o.err.trimAscii.toString == unknownHomeLine "Mine", s!"stderr: {showOut o}"),
    (p.code == 2 && p.out == "", s!"compare --home castle: {showOut p}"),
    (p.err.trimAscii.toString == unknownHomeLine "castle", s!"stderr: {showOut p}") ]

def tHomeMissingValue : IO (Option String) := do
  let o ← Harness.sim ["policy", "run", "--home"]
  return Harness.firstFail [
    (o.code == 2, s!"exit code: {showOut o}"),
    (o.out == "", s!"stdout not empty: {showOut o}"),
    (o.err.trimAscii.toString == "error: MISSING_VALUE: --home", s!"stderr: {showOut o}") ]

def tMineRunMatches : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let o ← Harness.sim ["policy", "run", "--home", "mine", "--days", "30"]
  let r := runHome h (Policy.static defaultStatic) 1 30
  if o.code != 0 then return some s!"sim failed: {showOut o}"
  if (outLines o.out).length != 15 then return some s!"not 15 lines: {showOut o}"
  return cliCheck o r.totals

def tOptionAfterHome : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let small : Home := { h with battery := { h.battery with capacityKwh := 5.0 } }
  let o ← Harness.sim ["policy", "run", "--home", "mine", "--battery", "5", "--days", "30"]
  let base ← Harness.sim ["policy", "run", "--home", "mine", "--days", "30"]
  let r := runHome small (Policy.static defaultStatic) 1 30
  if o.code != 0 then return some s!"sim failed: {showOut o}"
  if o.out == base.out then return some "--battery 5 after --home mine changed nothing"
  return cliCheck o r.totals

-- R22: more tanks

def tMineTwoTankRecords : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let r := runHome h (Policy.static defaultStatic) 7 30
  if r.hours.size != 720 then return some s!"hours: {r.hours.size}, want 720"
  for idx in [0:r.hours.size] do
    let hr := r.hours[idx]!
    if hr.tanks.size != 2 then return some s!"hour {idx} holds {hr.tanks.size} tank records"
  if r.totals.minTankKwh.size != 2 || r.totals.finalTankKwh.size != 2 then
    return some "the totals do not hold 2 tanks"
  return none

def tMineTankStep : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let r := runHome h (Policy.static defaultStatic) 7 30
  if r.hours.size != 720 then return some s!"hours: {r.hours.size}, want 720"
  let mut states : Array TankState := h.tanks.map startState
  for idx in [0:r.hours.size] do
    let hr := r.hours[idx]!
    if hr.tanks.size != 2 then return some s!"hour {idx} holds {hr.tanks.size} tank records"
    for i in [0:2] do
      let t := hr.tanks[i]!
      let cfg := h.tanks[i]!
      let st := tankStep cfg states[i]! hr.hour t.askKwh t.drawKwh
      if !nr st.heatKwh t.heatKwh 0.000000001 then
        return some s!"hour {idx} tank {i}: heat {t.heatKwh}, tankStep {st.heatKwh}"
      if !nr st.backstopKwh t.backstopKwh 0.000000001 then
        return some s!"hour {idx} tank {i}: backstop {t.backstopKwh}, tankStep {st.backstopKwh}"
      if !nr st.unmetKwh t.unmetKwh 0.000000001 then
        return some s!"hour {idx} tank {i}: unmet {t.unmetKwh}, tankStep {st.unmetKwh}"
      if !nr st.state.energyKwh t.energyKwh 0.000000001 then
        return some s!"hour {idx} tank {i}: energy {t.energyKwh}, tankStep {st.state.energyKwh}"
      states := states.set! i st.state
  return none

def tMineStaticRequests : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let r := runHome h (Policy.static defaultStatic) 7 30
  if r.hours.size != 720 then return some s!"hours: {r.hours.size}, want 720"
  for k in [0:24] do
    let hr := r.hours[3 * 24 + k]!
    if hr.tanks.size != 2 then return some s!"hour {k} holds {hr.tanks.size} tank records"
    for i in [0:2] do
      let want : Float := if k >= 10 && k < 14 then h.tanks[i]!.elementKw else 0.0
      let got := hr.tanks[i]!.askKwh
      if !nr got want 0.000000001 then
        return some s!"day 3 hour {k} tank {i}: request {got}, want {want}"
  return none

def tMineDrawSplit : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let r := runHome h (Policy.static defaultStatic) 7 30
  if r.hours.size != 720 then return some s!"hours: {r.hours.size}, want 720"
  let mut total := 0.0
  for idx in [0:r.hours.size] do
    let hr := r.hours[idx]!
    if hr.tanks.size != 2 then return some s!"hour {idx} holds {hr.tanks.size} tank records"
    let a := hr.tanks[0]!.drawKwh
    let b := hr.tanks[1]!.drawKwh
    total := total + a + b
    if a + b > 0.000000001 then
      if !nr (a / (a + b)) 0.58 0.005 then
        return some s!"hour {idx}: first tank has {a / (a + b)} of the draw, want 0.58"
  if total <= 0.0 then return some "the tanks draw nothing"
  return none

def tMineDrawProfile : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let r := runHome h (Policy.static defaultStatic) 7 30
  let sc := scenario h.site 7 30
  if r.hours.size != 720 then return some s!"hours: {r.hours.size}, want 720"
  for idx in [0:r.hours.size] do
    let hr := r.hours[idx]!
    if hr.tanks.size != 2 then return some s!"hour {idx} holds {hr.tanks.size} tank records"
    let want := drawKwh h.drawKwhPerDay h.site.latitude sc[idx]!.dayOfYear hr.hour
      * drawFactor 7 hr.day h.drawCv
    let got := hr.tanks[0]!.drawKwh + hr.tanks[1]!.drawKwh
    if !nr got want 0.000000001 then
      return some s!"hour {idx}: draw of the tanks {got}, want {want}"
  return none

/-- The checks of one run: the first problem of unmet draw or cold hours, and of the daily filling. -/
def checkRun (h : Home) (r : HomeResult) : Option String × Option String := Id.run do
  let mut bad : Option String := none
  let mut notFull : Option String := none
  if r.hours.size != 8760 then
    bad := some s!"hours: {r.hours.size}, want 8760"
    notFull := bad
    return (bad, notFull)
  if r.totals.coldHours != 0 then
    bad := some s!"cold hours {r.totals.coldHours}"
  if r.totals.unmetKwh > 0.000000001 then
    bad := some s!"unmet draw {r.totals.unmetKwh}"
  for i in [0:h.tanks.size] do
    let cfg := h.tanks[i]!
    for d in [0:365] do
      let mut full := false
      for k in [0:24] do
        let hr := r.hours[d * 24 + k]!
        if hr.tanks.size != h.tanks.size then
          if bad.isNone then bad := some s!"day {d} hour {k}: {hr.tanks.size} tank records"
        else
          let t := hr.tanks[i]!
          if t.unmetKwh > 0.000000001 then
            if bad.isNone then bad := some s!"tank {i} day {d} hour {k}: unmet {t.unmetKwh}"
          if t.energyKwh < cfg.floorKwh - 0.000000001 then
            if bad.isNone then bad := some s!"tank {i} day {d} hour {k}: energy {t.energyKwh} below the floor"
          if t.energyKwh >= cfg.capacityKwh - 0.000000001 then
            full := true
      if !full then
        if notFull.isNone then notFull := some s!"tank {i} day {d} never full"
  return (bad, notFull)

def policyList : List (String × Policy) :=
  [ ("static", Policy.static defaultStatic), ("precomputed", Policy.precomputed defaultPlan),
    ("dynamic", Policy.dynamic defaultDynamic) ]

def computeSweep : Option String × Option String := Id.run do
  let mut bad : Option String := none
  let mut notFull : Option String := none
  for n in ["generic", "small", "family", "no-battery", "mine"] do
    match homeNamed n with
    | none =>
      if bad.isNone then bad := some s!"homeNamed {n} gave none"
      if notFull.isNone then notFull := some s!"homeNamed {n} gave none"
    | some h =>
      for p in policyList do
        for seed in [1, 2, 3] do
          let r := runHome h p.2 seed 365
          let c := checkRun h r
          if bad.isNone then bad := c.1.map (fun (m : String) => s!"{n} {p.1} seed {seed}: {m}")
          if notFull.isNone then notFull := c.2.map (fun (m : String) => s!"{n} {p.1} seed {seed}: {m}")
  return (bad, notFull)

initialize sweepCache : IO.Ref (Option (Option String × Option String)) ← IO.mkRef none

def sweepResult : IO (Option String × Option String) := do
  match (← sweepCache.get) with
  | some r => return r
  | none =>
    let r := computeSweep
    sweepCache.set (some r)
    return r

def tSweepNoCold : IO (Option String) := do
  let r ← sweepResult
  return r.1

def tSweepFull : IO (Option String) := do
  let r ← sweepResult
  return r.2

/-- The heating requests of mine in a dynamic hour with a surplus of 3.0 kWh. -/
def dynRequest (h : Home) (f0 f1 : Float) : Array Float :=
  let params : DynamicParams :=
    { lowKwh := h.tanks.map (fun (t : TankConfig) => t.capacityKwh / 2.0)
      targetKwh := h.tanks.map (fun (t : TankConfig) => t.capacityKwh)
      dischargeFrom := 17 }
  let obs : Observation :=
    { hour := 12
      tankKwh := #[f0 * h.tanks[0]!.capacityKwh, f1 * h.tanks[1]!.capacityKwh]
      socKwh := 0.0
      surplusKwh := 3.0
      forecastRestKwh := 4.0
      flexLeftKwh := 0.0
      startsToday := #[0, 0]
      askedLastHour := #[false, false] }
  (dynamicAction h.tanks params obs).heatKwh

def tDynLowestFirst : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let a := dynRequest h 0.5 0.3
  return Harness.firstFail [
    (a.size == 2, s!"requests: {a.size}, want 2"),
    (nr a[1]! 2.5 0.000000001, s!"second tank (30%) asks {a[1]!}, want 2.5"),
    (nr a[0]! 0.5 0.000000001, s!"first tank (50%) asks {a[0]!}, want the 0.5 that is left") ]

def tDynTie : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let a := dynRequest h 0.5 0.5
  return Harness.firstFail [
    (a.size == 2, s!"requests: {a.size}, want 2"),
    (nr a[0]! 3.0 0.000000001, s!"first tank asks {a[0]!}, want 3.0"),
    (nr a[1]! 0.0 0.000000001, s!"second tank asks {a[1]!}, want 0") ]

def tDynFirstLower : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let a := dynRequest h 0.3 0.5
  return Harness.firstFail [
    (a.size == 2, s!"requests: {a.size}, want 2"),
    (nr a[0]! 3.0 0.000000001, s!"first tank (30%) asks {a[0]!}, want 3.0"),
    (nr a[1]! 0.0 0.000000001, s!"second tank (50%) asks {a[1]!}, want 0") ]

def tDynShareNotKwh : IO (Option String) := do
  let some h := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  -- first tank 40% of 13.1 = 5.24 kWh, second 50% of 9.4 = 4.7 kWh: the lower share holds more kWh
  let a := dynRequest h 0.4 0.5
  return Harness.firstFail [
    (a.size == 2, s!"requests: {a.size}, want 2"),
    (nr a[0]! 3.0 0.000000001, s!"first tank (40%, 5.24 kWh) asks {a[0]!}, want 3.0"),
    (nr a[1]! 0.0 0.000000001, s!"second tank (50%, 4.7 kWh) asks {a[1]!}, want 0") ]

def tTank2Option : IO (Option String) := do
  let some g := homeNamed "generic" | return some "homeNamed \"generic\" gave none"
  let some m := homeNamed "mine" | return some "homeNamed \"mine\" gave none"
  let two : Home := { g with tanks := #[g.tanks[0]!, m.tanks[1]!], drawShares := #[0.58, 0.42] }
  let r := runHome two (Policy.static defaultStatic) 1 30
  let o ← Harness.sim ["policy", "run", "--tank2", "9.4:2.5:0.42", "--days", "30"]
  let base ← Harness.sim ["policy", "run", "--days", "30"]
  if o.code != 0 then return some s!"sim failed: {showOut o}"
  if r.hours[0]!.tanks.size != 2 then return some "the library run has no 2 tanks"
  match cliCheck o r.totals with
  | some m => return some s!"--tank2 9.4:2.5:0.42 does not match a run of 2 tanks with a 42% share: {m}"
  | none => pure ()
  if valueOf o.out "heating" == valueOf base.out "heating" then
    return some "--tank2 gave the heating of one tank"
  return none

def tests : List Harness.Test := [
  { name := "test_001_S7_R21_mine_home_values", run := tMineValues },
  { name := "test_001_S7_R21_other_homes_values", run := tOtherHomes },
  { name := "test_001_S7_R21_home_names_list", run := tHomeNames },
  { name := "test_001_S7_R21_unknown_home_is_none", run := tUnknownHomeNone },
  { name := "test_001_S7_R21_no_home_equals_generic", run := tNoHomeEqualsGeneric },
  { name := "test_001_S7_R21_family_pv_changes_only_panels", run := tFamilyPv },
  { name := "test_001_S7_R21_unknown_home_error", run := tUnknownHomeError },
  { name := "test_001_S7_R21_unknown_home_echoes_value_as_typed", run := tUnknownHomeEcho },
  { name := "test_001_S7_R21_home_missing_value", run := tHomeMissingValue },
  { name := "test_001_S7_R21_mine_run_matches_runhome", run := tMineRunMatches },
  { name := "test_001_S7_R21_option_after_home_changes_one_value", run := tOptionAfterHome },
  { name := "test_001_S7_R22_mine_hour_holds_two_tank_records", run := tMineTwoTankRecords },
  { name := "test_001_S7_R22_mine_tank_result_equals_tankstep", run := tMineTankStep },
  { name := "test_001_S7_R22_mine_static_requests_each_tank", run := tMineStaticRequests },
  { name := "test_001_S7_R22_mine_draw_split_58_42", run := tMineDrawSplit },
  { name := "test_001_S7_R22_mine_draw_equals_profile_times_factor", run := tMineDrawProfile },
  { name := "test_001_S7_R22_all_homes_no_unmet_no_cold", run := tSweepNoCold },
  { name := "test_001_S7_R22_all_homes_each_tank_full_each_day", run := tSweepFull },
  { name := "test_001_S7_R22_dynamic_lowest_share_goes_first", run := tDynLowestFirst },
  { name := "test_001_S7_R22_dynamic_tie_goes_to_first_tank", run := tDynTie },
  { name := "test_001_S7_R22_dynamic_lower_first_tank_goes_first", run := tDynFirstLower },
  { name := "test_001_S7_R22_dynamic_share_not_kwh_decides_order", run := tDynShareNotKwh },
  { name := "test_001_S7_R22_tank2_option_adds_second_tank", run := tTank2Option } ]

def main (args : List String) : IO UInt32 := Harness.run tests args
