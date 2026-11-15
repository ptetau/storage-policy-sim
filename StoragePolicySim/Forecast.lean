/-
The simulated Solcast forecast of a scenario. A fetch gives periods with an error that grows
with the lead time. The periods of one day share a part of their error. A caller that fetches
many times builds the hours of the scenario once, and gives them to `forecastOf`. The module
also gives the fetch hours of a day, the forecast energy of each coming hour, and the Solcast
JSON. CAP-forecast (simulated Solcast forecasts for policies) gives the rules.
-/
import StoragePolicySim.Scenario

namespace StoragePolicySim

/-- One period of a fetch. Each power is the mean power of the period in kW. -/
structure Period where
  /-- The end of the period, in minutes from the start of the run. -/
  endMinute : Nat
  /-- The forecast power. -/
  estimateKw : Float
  /-- The 10% band: the actual power is below this value one time in ten. -/
  p10Kw : Float
  /-- The 90% band: the actual power is below this value nine times in ten. -/
  p90Kw : Float
  deriving Repr, Inhabited

/-! ## Periods -/

/-- The length of a period in minutes. -/
private def periodMinutes : Nat := 30

/-- The hours that a fetch looks ahead. -/
private def horizonHours : Nat := 48

/-- The hour of the run in which a period lies, from the end of the period. -/
private def hourOfPeriod (endMinute : Nat) : Nat := (endMinute - periodMinutes) / 60

/-- The spread of the error at a lead time of 0 hours. -/
private def baseSpread : Float := 0.05

/-- The growth of the spread for each 24 hours of lead time. -/
private def spreadPerDay : Float := 0.10

/-- The distance of a band from the estimate, in spreads. It is the 10% point of a normal
curve. -/
private def bandSpreadFactor : Float := 1.28

/-- The part of the variance of the error that the periods of one day share. -/
private def sharedShare : Float := 0.7

/-- The part of the variance of the error that belongs to one period. -/
private def ownShare : Float := 0.3

/-! ## Random numbers -/

/-- Two times pi. -/
private def twoPi : Float := 6.283185307179586

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
  let radius := Float.sqrt (-2 * Float.log (unitFloat (mix key)))
  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))

/-- The part of the error that belongs to one period. It depends only on the seed, the fetch
hour and the period. -/
private def periodDraw (seed fetchHour period : Nat) : Float :=
  normalOfKey (mix (mix (mix seed.toUInt64 + fetchHour.toUInt64) + period.toUInt64))

/-- The number that tells the draws of a day apart from the draws of a period. -/
private def dayStream : UInt64 := 0xDA7

/-- The part of the error that the periods of one day share. It depends only on the seed and
the day of the run. -/
private def dayDraw (seed day : Nat) : Float :=
  normalOfKey (mix (mix (mix (mix seed.toUInt64) + dayStream) + day.toUInt64))

/-- The random number of a period. It has a variance of 1. It adds the shared
part of its day and the part of the period. -/
private def normalDraw (seed fetchHour period day : Nat) : Float :=
  Float.sqrt sharedShare * dayDraw seed day + Float.sqrt ownShare * periodDraw seed fetchHour period

/-! ## Forecast -/

/-- A power, cut to the range from 0 to the power of the panels. -/
private def cutToPanels (site : Site) (kw : Float) : Float := max 0 (min site.pvKw kw)

/-- Period `k` of the fetch at `fetchHour`, for `k` from 1. The `hours` are the hours of the
scenario. The spread is 0.05 plus 0.10 for each 24 hours of lead time, times the error
scale. The random number shares a part with the other periods that end in the same day of the
run. -/
private def periodOf (site : Site) (hours : Array Hour) (seed : Nat) (errorScale : Float)
    (fetchHour k : Nat) : Period :=
  let endMinute := 60 * fetchHour + periodMinutes * k
  let leadHours := (periodMinutes * k).toFloat / 60
  let scaledSpread := errorScale * (baseSpread + spreadPerDay * leadHours / 24)
  let actualKw := hours[hourOfPeriod endMinute]!.pvKwh
  let day := hourOfPeriod endMinute / 24
  let estimateKw :=
    cutToPanels site (actualKw * (1 + scaledSpread * normalDraw seed fetchHour k day))
  { endMinute, estimateKw,
    p10Kw := cutToPanels site (estimateKw * (1 - bandSpreadFactor * scaledSpread)),
    p90Kw := cutToPanels site (estimateKw * (1 + bandSpreadFactor * scaledSpread)) }

/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
`hours` are the hours of `scenario site seed days`, built once by the caller. The run has
`hours.size / 24` days. The array is empty when the fetch is not inside the run. The same
arguments give the same periods. -/
def forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float)
    (fetchHour : Nat) : Array Period :=
  let periodsLeft := (24 * (hours.size / 24) - fetchHour) * 60 / periodMinutes
  let periodCount := min (horizonHours * 60 / periodMinutes) periodsLeft
  (Array.range periodCount).map (fun i => periodOf site hours seed errorScale fetchHour (i + 1))

/-- The periods of the fetch at `fetchHour`, in order of time, up to the end of the run. The
array is empty when the fetch is not inside the run. The same arguments give the same
periods. The call builds the scenario again: a caller that fetches many times uses
`forecastOf`. -/
def forecast (site : Site) (seed days : Nat) (errorScale : Float) (fetchHour : Nat) :
    Array Period :=
  forecastOf (scenario site seed days) site seed errorScale fetchHour

/-! ## Fetch limit -/

/-- The hour of the day of each fetch. Fetch `i` of `n` is at hour `i × 24 / n`, rounded
down. -/
def fetchHours (fetchesPerDay : Nat) : Array Nat :=
  (Array.range fetchesPerDay).map (fun i => i * 24 / fetchesPerDay)

/-- The hour of the run of the latest fetch at or before `hour`. -/
def latestFetch (fetchesPerDay hour : Nat) : Nat :=
  let hourOfDay := hour % 24
  let latestHourOfDay := (fetchHours fetchesPerDay).foldl
    (fun latest h => if h ≤ hourOfDay then max latest h else latest) 0
  24 * (hour / 24) + latestHourOfDay

/-! ## Hourly energy -/

/-- The forecast solar energy of the hours `fetchHour` to `fetchHour + 47` in kWh. Each value is
the energy of the estimates of the periods of its hour. An hour with no period is 0. -/
def hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float :=
  periods.foldl (init := Array.replicate horizonHours 0.0) fun energy p =>
    energy.modify (hourOfPeriod p.endMinute - fetchHour)
      (· + p.estimateKw * periodMinutes.toFloat / 60)

/-! ## Solcast JSON -/

/-- The text of a number, with zeros at the front up to the given width. -/
private def zeroPadded (width n : Nat) : String :=
  let digits := toString n
  "".pushn '0' (width - digits.length) ++ digits

/-- A power as text, rounded to four decimals. -/
private def fourDecimals (kw : Float) : String :=
  let tenThousandths := (kw * 10000).round.toUInt64.toNat
  toString (tenThousandths / 10000) ++ "." ++ zeroPadded 4 (tenThousandths % 10000)

/-- The year of the first day of the run. -/
private def startYear : Nat := 2025

/-- The days of each month. As in the scenario, each year of the run has 365 days. -/
private def monthDays : Array Nat := #[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

/-- The month and the day of the month, both from 1, for a day of the year from 0. -/
private def monthAndDay (dayOfYear : Nat) : Nat × Nat := Id.run do
  let mut month := 1
  let mut day := dayOfYear
  for length in monthDays do
    if day < length then break
    day := day - length
    month := month + 1
  return (month, day + 1)

/-- The UTC time of the end of a period, as `2025-01-01T00:30:00.0000000Z`. The UTC time is
the solar time less the longitude divided by 15 hours, rounded to the nearest 30 minutes. A tie
rounds up. -/
private def utcTime (longitude : Float) (endMinute : Nat) : String :=
  let solarMinute := endMinute.toFloat - 4 * longitude
  let utcMinute : Int := 30 * (Float.floor (solarMinute / 30 + 0.5)).toInt64.toInt
  let day := utcMinute / 1440
  let minuteOfDay := (utcMinute % 1440).toNat
  let (month, dayOfMonth) := monthAndDay (day % daysInYear).toNat
  zeroPadded 4 ((startYear + day / daysInYear : Int).toNat) ++ "-" ++ zeroPadded 2 month ++ "-" ++
    zeroPadded 2 dayOfMonth ++ "T" ++ zeroPadded 2 (minuteOfDay / 60) ++ ":" ++
    zeroPadded 2 (minuteOfDay % 60) ++ ":00.0000000Z"

/-- One period as the Solcast text. -/
private def periodJson (longitude : Float) (p : Period) : String :=
  "{\"pv_estimate\":" ++ fourDecimals p.estimateKw ++
    ",\"pv_estimate10\":" ++ fourDecimals p.p10Kw ++
    ",\"pv_estimate90\":" ++ fourDecimals p.p90Kw ++
    ",\"period_end\":\"" ++ utcTime longitude p.endMinute ++ "\",\"period\":\"PT30M\"}"

/-- The Solcast reply for the periods of a fetch, as one line of text. The longitude is in
degrees, and east is positive. -/
def forecastJson (periods : Array Period) (longitude : Float) : String :=
  "{\"forecasts\":[" ++ ",".intercalate (periods.toList.map (periodJson longitude)) ++ "]}"

end StoragePolicySim
