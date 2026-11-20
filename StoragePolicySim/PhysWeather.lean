/-
The physics model of the sun, the cloud, the panels and the temperatures.
-/
import StoragePolicySim.Scenario

namespace StoragePolicySim

/-- The steps of a day: a step is a quarter of an hour. -/
def stepsPerDay : Nat := 96

/-- The steps in an hour. -/
def stepsPerHour : Nat := 4

/-- The length of a step in hours. -/
def stepHours : Float := 0.25

private def pi : Float := 3.141592653589793

private def radians (deg : Float) : Float := deg * pi / 180

/-- The declination of the sun in degrees, as in `Scenario`. Day 0 is 1 January. -/
private def declination (dayOfYear : Nat) : Float :=
  23.44 * Float.sin (2 * pi * (285 + dayOfYear.toFloat) / 365.0)

/-- The hour angle in radians at the middle of a step, in solar time. -/
private def stepHourAngle (step : Nat) : Float :=
  radians (15 * ((step.toFloat + 0.5) / 4 - 12))

/-- The sun from the latitude, the day and the step: the east, north and up parts of its
direction. -/
private def sunDirection (latitude : Float) (dayOfYear step : Nat) : Float × Float × Float :=
  let lat := radians latitude
  let dec := radians (declination dayOfYear)
  let hourAngle := stepHourAngle step
  let up := Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle
  let east := -(Float.cos dec * Float.sin hourAngle)
  let north := Float.sin dec * Float.cos lat - Float.cos dec * Float.sin lat * Float.cos hourAngle
  (east, north, up)

/-- The clear-sky sunlight on flat ground in W/m² for the cosine of the angle of the sun from
straight up (the Haurwitz model). It is 0 when the sun is down. -/
def haurwitzWm2 (cosZ : Float) : Float :=
  if cosZ ≤ 0 then 0 else 1098 * cosZ * Float.exp (-0.059 / cosZ)

/-- The clear-sky sunlight on flat ground in W/m² at the middle of a step. -/
def clearSkyWm2 (latitude : Float) (dayOfYear step : Nat) : Float :=
  let (_, _, up) := sunDirection latitude dayOfYear step
  haurwitzWm2 up

/-! ## Random numbers -/

/-- The SplitMix64 steps: a well-mixed number from a number. -/
private def mix (x : UInt64) : UInt64 :=
  let s := x + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  z ^^^ (z >>> 31)

/-- A number above 0 and up to 1 from the top 53 bits of a number. -/
private def unitFloat (x : UInt64) : Float :=
  ((x >>> 11).toFloat + 1) / 9007199254740992.0

/-- A number from a normal curve (Box-Muller). It depends only on the key. -/
private def normalOfKey (key : UInt64) : Float :=
  Float.sqrt (-2 * Float.log (unitFloat (mix key))) *
    Float.cos (2 * pi * unitFloat (mix (key + 1)))

/-- The normal number of an index in a stream of a seed. -/
private def draw (stream : UInt64) (seed index : Nat) : Float :=
  normalOfKey (mix (mix (mix seed.toUInt64 + stream) + index.toUInt64))

/-- The stream of the days. -/
private def dayStream : UInt64 := 0xC10D

/-- The stream of the steps. -/
private def stepStream : UInt64 := 0x57E9

/-! ## Cloud -/

/-- True for a day in the summer half of the year at this latitude. -/
private def inSummerHalf (latitude : Float) (dayOfYear : Nat) : Bool :=
  let north := 90 ≤ dayOfYear && dayOfYear ≤ 272
  if latitude ≥ 0 then north else !north

/-- The lowest clearness. -/
private def minClearness : Float := 0.15

/-- A value cut to the range of the clearness. -/
private def cutClearness (x : Float) : Float := max minClearness (min 1.0 x)

/-- The share of the clearness of the day before that a day keeps. -/
private def daySharePrev : Float := 0.6

/-- The size of the random part of the clearness of a day. -/
private def daySigma : Float := 0.17

/-- The mean of the clearness of a day: 0.65 in the summer half, 0.45 in the winter half. -/
private def dayMean (latitude : Float) (dayOfYear : Nat) : Float :=
  if inSummerHalf latitude dayOfYear then 0.65 else 0.45

/-- The clearness of each day, from 0.15 to 1.0. A day keeps 0.6 of the day before, and takes
the rest from the mean of its half of the year and a random part. The same arguments give the
same values. -/
def dayClearness (latitude : Float) (seed days : Nat) : Array Float := Id.run do
  let mut out : Array Float := Array.mkEmpty days
  let mut prev := dayMean latitude 0
  for d in [0:days] do
    let m := dayMean latitude (d % 365)
    let c := cutClearness
      (daySharePrev * prev + (1 - daySharePrev) * m + daySigma * draw dayStream seed d)
    out := out.push c
    prev := c
  return out

/-- The share of the step factor that the next step keeps. -/
private def stepKeep : Float := 0.9

/-- The size of the random part of the step factor. -/
private def stepSigma : Float := 0.04

/-- The clearness of each step: the clearness of its day times a factor near 1 that follows the
step before, from 0.15 to 1.0. There are `96 × days` values, in order. The same arguments give
the same values. -/
def clearness (latitude : Float) (seed days : Nat) : Array Float := Id.run do
  let perDay := dayClearness latitude seed days
  let mut out : Array Float := Array.mkEmpty (stepsPerDay * days)
  let mut factor := 1.0
  for d in [0:days] do
    for s in [0:stepsPerDay] do
      factor := 1 + stepKeep * (factor - 1) +
        stepSigma * draw stepStream seed (d * stepsPerDay + s)
      out := out.push (cutClearness (perDay[d]! * factor))
  return out

/-! ## Panels -/

/-- The share of the flat sunlight that is diffuse (the Erbs rule at `kt = 0.75 × clearness`). -/
def diffuseShare (clearness : Float) : Float :=
  let kt := 0.75 * clearness
  if kt ≤ 0.22 then 1 - 0.09 * kt
  else if kt ≤ 0.8 then
    0.9511 - 0.1604 * kt + 4.388 * kt ^ 2 - 16.638 * kt ^ 3 + 12.336 * kt ^ 4
  else 0.165

/-- The light on the panels of an array in W/m²: the direct light times the cosine of its angle
to the panels, plus the diffuse light of the sky, plus the light of the ground. A flat array gets
the flat sunlight times the clearness. -/
def panelWm2 (latitude : Float) (array : PanelArray) (dayOfYear step : Nat) (clearness : Float) :
    Float :=
  let (east, north, up) := sunDirection latitude dayOfYear step
  if up ≤ 0 then 0
  else
    let flat := haurwitzWm2 up * clearness
    let diffuse := flat * diffuseShare clearness
    let direct := flat - diffuse
    let tilt := radians array.tilt
    let facing := radians array.direction
    let cosAngle := east * (Float.sin tilt * Float.sin facing) +
      north * (Float.sin tilt * Float.cos facing) + up * Float.cos tilt
    let directOnPanel := if cosAngle ≤ 0 then 0 else direct * cosAngle / up
    directOnPanel + diffuse * (1 + Float.cos tilt) / 2 + 0.2 * flat * (1 - Float.cos tilt) / 2

/-- The temperature of the cells in °C: the air plus the light times `(45 - 20) / 800`. -/
def cellTempC (airC lightWm2 : Float) : Float := airC + lightWm2 * (45 - 20) / 800

/-- The output of an array in kW: its power, times the light over 1000 W/m², times the loss of a
hot cell, times 0.9 for wiring and dirt. -/
def arrayKw (array : PanelArray) (lightWm2 airC : Float) : Float :=
  if lightWm2 ≤ 0 then 0
  else
    array.kw * lightWm2 / 1000 * (1 - 0.004 * (cellTempC airC lightWm2 - 25)) * 0.9

/-! ## Temperatures -/

/-- The day of the seasonal peak of the air: day 15 at a negative latitude, else day 197. -/
private def peakDay (latitude : Float) : Float := if latitude < 0 then 15 else 197

/-- The air temperature in °C at the start of a step: 13, plus a seasonal swing of 4.5 that
peaks in midsummer, plus a daily swing of 3.5 that peaks at 15:00, less `2 × (1 - clearness)`
on a dull day. -/
def airTempC (latitude : Float) (dayOfYear step : Nat) (clearnessOfDay : Float) : Float :=
  let seasonal := 4.5 * Float.cos (2 * pi * (dayOfYear.toFloat - peakDay latitude) / 365.0)
  let daily := 3.5 * Float.cos (2 * pi * (step.toFloat / 4 - 15) / 24)
  13 + seasonal + daily - 2 * (1 - clearnessOfDay)

/-- The temperature of the water that enters a tank in °C: 14, plus a seasonal swing of 3 that
lags the air by 30 days. -/
def inletTempC (latitude : Float) (dayOfYear : Nat) : Float :=
  14 + 3 * Float.cos (2 * pi * (dayOfYear.toFloat - (peakDay latitude + 30)) / 365.0)

end StoragePolicySim
