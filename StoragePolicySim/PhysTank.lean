/-
The physics model of a hot-water tank in litres and degrees: a hot layer at the set point above
cold water at the inlet temperature.
-/
import StoragePolicySim.HotWater

namespace StoragePolicySim

/-- The energy that one litre of water takes for one degree, in kWh. -/
def kwhPerLitreK : Float := 0.001163

/-- A tank in litres. -/
structure PhysTank where
  litres : Float
  elementKw : Float
  uaKwPerK : Float
  cutInShare : Float
  floorShare : Float
  guardHour : Nat
  deriving Repr, Inhabited

/-- The set point of a tank, in degrees Celsius. -/
private def setPointC : Float := 60.0

/-- The temperature of the room around a tank, in degrees Celsius. -/
private def roomC : Float := 18.0

/-- The temperature of the water at the tap, in degrees Celsius. -/
private def tapC : Float := 40.0

/-- The hours in a step: a step is a quarter of an hour. -/
private def stepHours : Float := 0.25

/-- The steps in a day. -/
private def stepsPerDay : Nat := 96

/-- A tank is full when its hot litres are within this many litres of its volume. -/
private def fullToleranceLitres : Float := 1e-9

/-- The tank of a config. Its litres are the capacity over the energy of a litre from 15 degrees
to the set point. Its `uaKwPerK` is the loss share times the capacity over the 42 degrees of the
loss rule. Its levels are shares of the capacity. -/
def physTankOf (cfg : TankConfig) : PhysTank where
  litres := cfg.capacityKwh / (kwhPerLitreK * 45.0)
  elementKw := cfg.elementKw
  uaKwPerK := cfg.lossPerHour * cfg.capacityKwh / 42.0
  cutInShare := cfg.cutInKwh / cfg.capacityKwh
  floorShare := cfg.floorKwh / cfg.capacityKwh
  guardHour := cfg.guardHour

/-- The state of a tank. -/
structure PhysTankState where
  hotLitres : Float
  heating : Bool
  fullToday : Bool
  deriving Repr, Inhabited

/-- The energy of one hot litre above the inlet water, in kWh. The difference to the set point
is at least 0.001 degrees, so that a division by this energy is safe. -/
private def litreKwh (inletC : Float) : Float :=
  kwhPerLitreK * max 0.001 (setPointC - inletC)

/-- A full tank: all hot, thermostat off, full today. -/
def physStart (t : PhysTank) : PhysTankState :=
  { hotLitres := t.litres, heating := false, fullToday := true }

/-- The energy of the hot litres above the inlet temperature, in kWh. -/
def tankEnergyKwh (state : PhysTankState) (inletC : Float) : Float :=
  state.hotLitres * litreKwh inletC

/-- The result of one step of a tank. -/
structure PhysTankStep where
  lossKwh : Float
  servedKwh : Float
  unmetKwh : Float
  heatKwh : Float
  backstopKwh : Float
  state : PhysTankState
  deriving Repr, Inhabited

/-- True when the tank was already all hot earlier in this day. Step 0 of a day starts a new day. -/
private def fullEarlierToday (state : PhysTankState) (dayStep : Nat) : Bool :=
  dayStep != 0 && state.fullToday

/-- One step of a quarter of an hour. The order is this. The tank loses heat to the room by
`uaKwPerK × (60 - 18) × hot share × 0.25`. The household uses `tapLitres` at 40 degrees, which
needs `tapLitres × (40 - inlet) / (60 - inlet)` hot litres: the tank serves the smaller of that
and its hot litres, and the rest is unmet. The element heats by the request, never more than its
power for a quarter of an hour and never more than the room that is left. Then the thermostat
decides: it stays on from the step before, cuts in below the cut-in share, and cuts in from the
guard hour when the tank was not all hot today. When it is on, the backstop is the element energy
that the request left, never more than the room. The thermostat stays on until the tank is all
hot. Each loss, use and heating changes the hot litres by its energy over the energy of a hot
litre. -/
def physTankStep (t : PhysTank) (state : PhysTankState) (step : Nat) (requestKwh tapLitres inletC : Float) :
    PhysTankStep :=
  let dayStep := step % stepsPerDay
  let perLitre := litreKwh inletC
  let share := if t.litres > 0.0 then state.hotLitres / t.litres else 0.0
  let lossKwh := min (t.uaKwPerK * (setPointC - roomC) * share * stepHours) (state.hotLitres * perLitre)
  let afterLoss := state.hotLitres - lossKwh / perLitre
  let neededLitres := max 0.0 (tapLitres * (tapC - inletC) / max 0.001 (setPointC - inletC))
  let servedLitres := min neededLitres afterLoss
  let servedKwh := servedLitres * perLitre
  let unmetKwh := (neededLitres - servedLitres) * perLitre
  let afterUse := afterLoss - servedLitres
  let roomKwh := max 0.0 ((t.litres - afterUse) * perLitre)
  let elementKwh := t.elementKw * stepHours
  let heatKwh := max 0.0 (min requestKwh (min elementKwh roomKwh))
  let level := afterUse + heatKwh / perLitre
  let on := state.heating || level / t.litres < t.cutInShare ||
    (t.guardHour * 4 ≤ dayStep && !fullEarlierToday state dayStep)
  let backstopKwh :=
    if on then max 0.0 (min (elementKwh - heatKwh) (roomKwh - heatKwh)) else 0.0
  let hot := min t.litres (level + backstopKwh / perLitre)
  let full := hot ≥ t.litres - fullToleranceLitres
  { lossKwh, servedKwh, unmetKwh, heatKwh, backstopKwh,
    state := { hotLitres := hot, heating := on && !full,
               fullToday := fullEarlierToday state dayStep || full } }

end StoragePolicySim
