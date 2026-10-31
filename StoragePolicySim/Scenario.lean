/-
The scenario of a site: the solar output, the daily sky and the household load of each hour.
CAP-scenario (sun, weather and load) gives the rules.
-/
namespace StoragePolicySim

/-- The sky of a day. -/
inductive Sky
  | sunny
  | cloudy
  | overcast
  deriving BEq, Repr, Inhabited

/-- The share of the sunny output that the sky lets through. -/
def Sky.factor : Sky → Float
  | .sunny => 1.0
  | .cloudy => 0.5
  | .overcast => 0.15

/-- A site with its panels and its household load. -/
structure Site where
  /-- Degrees. South is negative. -/
  latitude : Float
  /-- The kW of the panels. -/
  pvKw : Float
  /-- The load of a day, with the flexible load included. -/
  dailyLoadKwh : Float
  /-- The part of the daily load that a strategy can move. -/
  flexKwh : Float
  deriving Repr, Inhabited

/-- One hour of a scenario. -/
structure Hour where
  /-- The day of the run, from 0. -/
  day : Nat
  /-- `day % 365`, from 0 (1 January) to 364. -/
  dayOfYear : Nat
  /-- The hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00. -/
  hour : Nat
  /-- The sky of the day. -/
  sky : Sky
  /-- The solar energy of the hour. -/
  pvKwh : Float
  /-- The base load of the hour. -/
  baseLoadKwh : Float
  /-- The flexible load of the hour, at its default hours. -/
  flexKwh : Float
  deriving Repr, Inhabited

def daysInYear : Nat := 365

private def pi : Float := 3.141592653589793

private def radians (deg : Float) : Float := deg * pi / 180

/-- The declination of the sun in degrees. Day 0 is 1 January. -/
private def declination (dayOfYear : Nat) : Float :=
  23.44 * Float.sin (2 * pi * (285 + dayOfYear.toFloat) / daysInYear.toFloat)

/-- The sine of the sun height at the middle of the hour, in solar time. -/
private def sinSunHeight (latitude : Float) (dayOfYear hour : Nat) : Float :=
  let lat := radians latitude
  let dec := radians (declination dayOfYear)
  let hourAngle := radians (15 * (hour.toFloat + 0.5 - 12))
  Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle

/-- The solar energy of one hour in kWh. It reads only `latitude` and `pvKw` of the site. -/
def pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float :=
  let h := sinSunHeight site.latitude dayOfYear hour
  if h ≤ 0 then 0 else site.pvKw * h * sky.factor

/-! ## Weather -/

/-- The state of the seeded random numbers (SplitMix64). -/
private structure Rng where
  state : UInt64

/-- The next number from 0 to less than 1, and the next state. -/
private def Rng.next (r : Rng) : Float × Rng :=
  let s := r.state + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  let z := z ^^^ (z >>> 31)
  ((z >>> 11).toFloat / 9007199254740992.0, ⟨s⟩)

/-- The chance that a day keeps the sky of the day before. -/
private def keepChance : Float := 0.6

/-- True for a day in the summer half of the year at this latitude. -/
private def inSummerHalf (latitude : Float) (dayOfYear : Nat) : Bool :=
  let north := 90 ≤ dayOfYear && dayOfYear ≤ 272
  if latitude ≥ 0 then north else !north

/-- A new sky from the chances of the half of the year. -/
private def newSky (summer : Bool) (u : Float) : Sky :=
  let (sunny, cloudy) := if summer then (0.55, 0.30) else (0.20, 0.35)
  if u < sunny then .sunny
  else if u < sunny + cloudy then .cloudy
  else .overcast

/-- The sky of each day of the run. -/
private def skies (latitude : Float) (seed days : Nat) : Array Sky := Id.run do
  let mut rng : Rng := ⟨seed.toUInt64⟩
  let mut out : Array Sky := Array.mkEmpty days
  for d in [0:days] do
    let (u, r) := rng.next
    rng := r
    match out.back? with
    | some prev =>
      if u < keepChance then
        out := out.push prev
        continue
    | none => pure ()
    let (v, r) := rng.next
    rng := r
    out := out.push (newSky (inSummerHalf latitude (d % daysInYear)) v)
  return out

/-! ## Load -/

/-- The share of the base load of a day in each hour, in parts of 1000. The profile has a
morning peak at 07:00 and an evening peak at 19:00. -/
private def profile : Array Float :=
  #[30, 22, 20, 20, 20, 25, 40, 55, 50, 40, 30, 30,
    32, 30, 33, 30, 38, 55, 75, 85, 80, 65, 55, 40]

/-- The day of the year with the most base load. -/
private def peakDay (latitude : Float) : Nat := if latitude ≥ 0 then 15 else 197

/-- The seasonal factor that scales the base load of a day. -/
private def seasonalFactor (latitude : Float) (dayOfYear : Nat) : Float :=
  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
  1 + 0.2 * Float.cos (2 * pi * offset / daysInYear.toFloat)

/-- The base load of one hour in kWh. -/
private def baseLoad (site : Site) (dayOfYear hour : Nat) : Float :=
  (site.dailyLoadKwh - site.flexKwh) * seasonalFactor site.latitude dayOfYear *
    profile[hour]! / 1000

/-- The flexible load of one hour at its default hours: equal parts at 18:00, 19:00 and 20:00. -/
private def defaultFlex (site : Site) (hour : Nat) : Float :=
  if hour == 18 || hour == 19 || hour == 20 then site.flexKwh / 3 else 0

/-! ## Scenario -/

/-- The `24 × days` hours of a run, in order of day, then hour. The same arguments give the
same array. -/
def scenario (site : Site) (seed days : Nat) : Array Hour := Id.run do
  let sky := skies site.latitude seed days
  let mut out : Array Hour := Array.mkEmpty (24 * days)
  for d in [0:days] do
    let doy := d % daysInYear
    let s := sky[d]!
    for h in [0:24] do
      out := out.push {
        day := d, dayOfYear := doy, hour := h, sky := s,
        pvKwh := pvOutput site doy h s,
        baseLoadKwh := baseLoad site doy h,
        flexKwh := defaultFlex site h }
  return out

end StoragePolicySim
