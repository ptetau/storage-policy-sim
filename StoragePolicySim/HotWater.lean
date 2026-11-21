/-
The hot-water tank of a household. The tank holds thermal energy in kWh. Each hour it loses a
share of its energy, serves the draw of the household, and takes the heating of a policy. A
thermostat with a cut-in level adds backstop heating, and the guard hour makes the tank heat to
full once each day, against legionella. The module also gives the draw of each hour, which
changes with the season, and the random factor of each day. CAP-hotwater (hot-water tank with a
thermostat) gives the rules.
-/
namespace StoragePolicySim

/-! ## Tank -/

/-- The limits and the levels of a tank. -/
structure TankConfig where
  /-- The most energy that the tank holds, in kWh. -/
  capacityKwh : Float
  /-- The power of the element, in kW. -/
  elementKw : Float
  /-- The share of the stored energy that the tank loses in one hour. -/
  lossPerHour : Float
  /-- The level below which the thermostat cuts in, in kWh. -/
  cutInKwh : Float
  /-- The level below which the tank counts as cold, in kWh. -/
  floorKwh : Float
  /-- The hour of the day from which the tank must heat to full, when it was not full today. -/
  guardHour : Nat
  deriving Repr, Inhabited

/-- A tank of 10.5 kWh with a 3.0 kW element, a loss of 0.6% each hour, a cut-in of half the
capacity, a floor of a fifth of the capacity, and a guard hour of 20. -/
def defaultTank : TankConfig where
  capacityKwh := 10.5
  elementKw := 3.0
  lossPerHour := 0.006
  cutInKwh := 5.25
  floorKwh := 2.1
  guardHour := 20

/-- The state of a tank at the end of an hour. -/
structure TankState where
  /-- The energy that the tank holds, in kWh. -/
  energyKwh : Float
  /-- True when the thermostat is on. -/
  heating : Bool
  /-- True when the tank has been full since hour 0 of the day. -/
  fullToday : Bool
  deriving Repr, Inhabited

/-- The state of a full tank, with the thermostat off and `fullToday` true. -/
def startState (cfg : TankConfig) : TankState :=
  { energyKwh := cfg.capacityKwh, heating := false, fullToday := true }

/-- The result of one hour. Each energy is in kWh. -/
structure TankStep where
  /-- The energy that the tank lost. -/
  lossKwh : Float
  /-- The part of the draw that the tank served. -/
  servedKwh : Float
  /-- The part of the draw that the tank could not serve. -/
  unmetKwh : Float
  /-- The heating that the tank took for the policy. -/
  heatKwh : Float
  /-- The heating that the thermostat added. -/
  backstopKwh : Float
  /-- The state after the hour. -/
  state : TankState
  deriving Repr, Inhabited

/-- A tank is full when it holds its capacity, within this many kWh. -/
private def fullTolerance : Float := 1e-9

/-- True when the tank holds its capacity, within `fullTolerance`. -/
private def isFull (cfg : TankConfig) (energyKwh : Float) : Bool :=
  (energyKwh - cfg.capacityKwh).abs ≤ fullTolerance

/-- True when the tank was already full earlier in this day, as the state of the hour before says.
Hour 0 starts a new day, so the tank is then not full before the hour. -/
private def fullEarlierToday (state : TankState) (hour : Nat) : Bool :=
  hour != 0 && state.fullToday

/-- True when the thermostat is on for the rest of the hour. It stays on from the hour before. It
cuts in when the level is less than the cut-in level. It also cuts in from the guard hour, when
the tank was not full since hour 0 of the day. -/
private def thermostatOn (cfg : TankConfig) (state : TankState) (hour : Nat) (level : Float) :
    Bool :=
  state.heating || level < cfg.cutInKwh || (cfg.guardHour ≤ hour && !fullEarlierToday state hour)

/-- The result of one hour. The order of the hour is this. The tank loses a share of its energy.
The household draws: the tank serves the smaller of the draw and its energy, and the rest is the
unmet draw. The element heats by the request, but never more than the element power for one
hour, and never more than the room that is left. Then the thermostat decides. When it is on, the
backstop heating is the element power that the request left, and never more than the room that is
left. The thermostat stays on until the tank is full. `fullToday` starts again at hour 0, and it
becomes true in the hour in which the tank is full. -/
def tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) :
    TankStep :=
  let lossKwh := cfg.lossPerHour * state.energyKwh
  let afterLoss := state.energyKwh - lossKwh
  let servedKwh := if drawKwh < afterLoss then drawKwh else afterLoss
  let unmetKwh := drawKwh - servedKwh
  let afterDraw := afterLoss - servedKwh
  let heatKwh := max 0.0 (min requestKwh (min cfg.elementKw (cfg.capacityKwh - afterDraw)))
  let level := afterDraw + heatKwh
  let on := thermostatOn cfg state hour level
  let backstopKwh :=
    if on then max 0.0 (min (cfg.elementKw - heatKwh) (cfg.capacityKwh - level)) else 0.0
  let energyKwh := level + backstopKwh
  let full := isFull cfg energyKwh
  { lossKwh, servedKwh, unmetKwh, heatKwh, backstopKwh,
    state := { energyKwh, heating := on && !full, fullToday := fullEarlierToday state hour || full } }

/-! ## Draw profile -/

/-- The share of the hot-water draw of a day in each hour, in parts of 1000. The profile has a
morning peak at 07:00 and an evening peak at 19:00. The parts add up to 1000. -/
private def profile : Array Float :=
  #[5, 3, 2, 2, 5, 20, 70, 110, 90, 50, 35, 30,
    30, 25, 25, 25, 30, 50, 80, 110, 90, 60, 35, 18]

/-- The size of the seasonal swing: the draw of the coldest day is this share more than the mean
of the year, and the draw of the warmest day is this share less. -/
private def seasonSwing : Float := 0.15

/-- The days in a year. -/
private def yearDays : Float := 365.0

/-- Two times pi. -/
private def twoPi : Float := 6.283185307179586

/-- The day of the year with the most hot-water draw. It is 15 (mid-winter) at latitude 0 or
more, and 197 at a negative latitude. -/
private def peakDay (latitude : Float) : Nat := if latitude ≥ 0.0 then 15 else 197

/-- The seasonal factor that scales the hot-water energy of a day. The cold inlet is colder in
winter. -/
private def seasonOf (latitude : Float) (dayOfYear : Nat) : Float :=
  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
  1.0 + seasonSwing * Float.cos (twoPi * offset / yearDays)

/-- The hot-water energy that the household draws in one hour, in kWh. The `dailyKwh` is the
energy of a day before the season. The hours of a day share it by a fixed profile, and a seasonal
factor scales it. -/
def drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float :=
  dailyKwh * seasonOf latitude dayOfYear * profile[hour]! / 1000.0

/-! ## Daily draw factor -/

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
  let radius := Float.sqrt (-2.0 * Float.log (unitFloat (mix key)))
  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))

/-- The number that tells the draws of the hot-water factor apart from other random draws. -/
private def drawStream : UInt64 := 0x40A7

/-- The factor that scales the hot-water draw of one day. It is `exp(cv × z - cv × cv / 2)`,
where `cv` is the spread of the draw and `z` is a number from a normal curve. The number `z`
depends only on the seed and the day, so the same arguments give the same factor. The mean of the
factor is 1, and a spread of 0 gives the factor 1. The factor is more than 0. -/
def drawFactor (seed day : Nat) (cv : Float) : Float :=
  let z := normalOfKey (mix (mix (mix seed.toUInt64 + drawStream) + day.toUInt64))
  Float.exp (cv * z - cv * cv / 2.0)

end StoragePolicySim
