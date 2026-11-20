/-
The physics model of the battery, the flexible appliances and the base load (spec 002, D2, D10 to
D12 and D15).
-/
import StoragePolicySim.Simulation

namespace StoragePolicySim

/-- The length of a step in hours. -/
private def stepHours : Float := 0.25

/-- The standby energy of the battery in a step: 0.01 kW. -/
private def standbyKwh : Float := 0.01 * stepHours

/-- The efficiency of a charge, and of a discharge. -/
private def batteryEfficiency : Float := 0.97

/-- The fixed energy that the inverter loses in a step while it runs: 0.02 kW. -/
private def inverterFixedKwh : Float := 0.02 * stepHours

/-- The share of the power that the inverter loses while it runs. -/
private def inverterShare : Float := 0.015

/-- A limit in kW as a cap on the energy of a step. A limit of 0 is no cap. -/
private def stepCap (limitKw : Float) : Float :=
  if limitKw == 0 then 1.0e18 else limitKw * stepHours

/-- The inverter energy that a gross energy covers, when the fixed loss is paid already
(`fixedPaid`) or not yet. The gross energy is the energy plus its loss. -/
private def inverterNet (gross : Float) (fixedPaid : Bool) : Float :=
  max 0 ((gross - (if fixedPaid then 0 else inverterFixedKwh)) / (1 + inverterShare))

/-- The inverter loss of an energy that it passes, with the fixed part when it is not paid yet. -/
private def inverterLoss (kwh : Float) (fixedPaid : Bool) : Float :=
  if kwh > 0 then inverterShare * kwh + (if fixedPaid then 0 else inverterFixedKwh) else 0

/-- One step of the battery and the inverter. The order is the one of `stepHourLimited`: the solar
energy goes direct to the house, then to the battery (when it may charge), then to the grid, and
the rest is curtailed. The battery covers the shortfall when it may discharge, and the grid the
rest. The inverter loss of the energy that it passes is paid by the solar energy first, and by the
battery for the energy that it gives. `chargeKwh` is the solar energy into the battery before the
charge loss. `dischargeKwh` is the energy out of the battery after the discharge loss, which is the
load that it covers plus the inverter loss of that energy. `lossKwh` is the inverter loss, the
charge loss, the discharge loss and the standby energy. -/
def physBatteryStep (limits : Limits) (battery : Battery) (socKwh : Float)
    (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : LimitedFlow :=
  let inverterCap := stepCap limits.inverterKw
  let powerCap := battery.powerKw * stepHours
  -- The direct energy: the solar energy has to pay the inverter loss of it.
  let directKwh := max 0 (min (min loadKwh inverterCap) (inverterNet pvKwh false))
  let directLoss := inverterLoss directKwh false
  -- The charge.
  let pvLeftKwh := max 0 (pvKwh - directKwh - directLoss)
  let roomKwh := max 0 ((battery.capacityKwh - socKwh) / batteryEfficiency)
  let chargeKwh := if allowCharge then min pvLeftKwh (min powerCap roomKwh) else 0
  -- The export.
  let afterChargeKwh := pvLeftKwh - chargeKwh
  let solarFixedPaid := directKwh > 0
  let exportCap := max 0 (min (inverterCap - directKwh) (stepCap limits.exportKw))
  let exportKwh := min exportCap (inverterNet afterChargeKwh solarFixedPaid)
  let exportLoss := inverterLoss exportKwh solarFixedPaid
  let curtailedKwh := max 0 (afterChargeKwh - exportKwh - exportLoss)
  let inverterLossSolar := directLoss + exportLoss
  -- The discharge.
  let storedAfterChargeKwh := socKwh + chargeKwh * batteryEfficiency
  let shortfallKwh := loadKwh - directKwh
  let batteryFixedPaid := directKwh > 0 || exportKwh > 0
  let grossCap := min (min (inverterCap - directKwh - exportKwh) powerCap)
    (storedAfterChargeKwh * batteryEfficiency)
  let coveredKwh := if allowDischarge then
      max 0 (min shortfallKwh (inverterNet grossCap batteryFixedPaid)) else 0
  let dischargeKwh :=
    if coveredKwh > 0 then coveredKwh + inverterLoss coveredKwh batteryFixedPaid else 0
  let takenOutKwh := dischargeKwh / batteryEfficiency
  -- The store and the standby energy.
  let storedKwh := max 0 (storedAfterChargeKwh - takenOutKwh)
  let standby := min standbyKwh storedKwh
  { flow :=
      { directKwh, chargeKwh, dischargeKwh, exportKwh,
        importKwh := shortfallKwh - coveredKwh,
        lossKwh := inverterLossSolar + (dischargeKwh - coveredKwh)
          + (chargeKwh - chargeKwh * batteryEfficiency)
          + (takenOutKwh - dischargeKwh) + standby,
        socKwh := min battery.capacityKwh (storedKwh - standby) },
    curtailedKwh }

/-- One run of an appliance: its energy in each step. -/
structure Cycle where
  name : String
  stepKwh : Array Float
  deriving Repr, Inhabited

/-- A cycle of `kwh` kWh with the given weights for its steps. The heating steps have more weight. -/
private def cycleOf (name : String) (kwh : Float) (weights : Array Float) : Cycle :=
  let total := weights.foldl (· + ·) 0
  { name, stepKwh := weights.map (fun w => kwh * w / total) }

/-- The dishwasher: 1.2 kWh in 8 steps (2 hours), with the heating in the middle of each half. -/
def dishwasher : Cycle := cycleOf "dishwasher" 1.2 #[1, 4, 4, 1, 1, 4, 4, 1]
/-- The washing machine: 0.8 kWh in 6 steps (1.5 hours), with the heating at the start. -/
def washingMachine : Cycle := cycleOf "washing-machine" 0.8 #[4, 4, 1, 1, 1, 1]
/-- The dryer: 2.5 kWh in 6 steps (1.5 hours), with the most heat at the start. -/
def dryer : Cycle := cycleOf "dryer" 2.5 #[4, 4, 3, 3, 2, 2]

/-- The SplitMix64 steps: a well-mixed number from a number. -/
private def appMix (x : UInt64) : UInt64 :=
  let s := x + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  z ^^^ (z >>> 31)

/-- A number from 0 up to 1 from the top 53 bits of a number. -/
private def appUnit (x : UInt64) : Float :=
  (x >>> 11).toFloat / 9007199254740992.0

/-- The cycles that run on a day: each appliance runs on a share of the days (5 of 7, 4 of 7 and
2 of 7), drawn from the seed and the day. -/
def applianceCycles (seed day : Nat) : Array Cycle :=
  let draw (index : UInt64) : Float :=
    appUnit (appMix (appMix (appMix (seed.toUInt64 + 0xA99) + day.toUInt64) + index))
  let all : Array (Float × Cycle) :=
    #[(5.0 / 7.0, dishwasher), (4.0 / 7.0, washingMachine), (2.0 / 7.0, dryer)]
  Id.run do
    let mut out : Array Cycle := #[]
    for i in [0:3] do
      let (share, cycle) := all[i]!
      if draw i.toUInt64 < share then out := out.push cycle
    return out

private def basePi : Float := 3.141592653589793

private def baseRadians (deg : Float) : Float := deg * basePi / 180

/-- The declination of the sun in degrees. -/
private def baseDeclination (dayOfYear : Nat) : Float :=
  23.44 * Float.sin (2 * basePi * (285 + dayOfYear.toFloat) / 365)

/-- The sine of the sun height at the middle of a step, in solar time. -/
private def baseSinHeight (latitude : Float) (dayOfYear step : Nat) : Float :=
  let lat := baseRadians latitude
  let dec := baseRadians (baseDeclination dayOfYear)
  let hourAngle := baseRadians (15 * ((step.toFloat + 0.5) / 4 - 12))
  Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle

/-- The first step of the awake time (06:00). -/
private def awakeFirst : Nat := 24
/-- The last step of the awake time (the step before 23:00). -/
private def awakeLast : Nat := 91

/-- The number of awake steps in the dark on a day, from the half day length. -/
private def darkAwakeSteps (latitude : Float) (dayOfYear : Nat) : Float :=
  let c := -(Float.tan (baseRadians latitude) * Float.tan (baseRadians (baseDeclination dayOfYear)))
  let halfDay := if c >= 1 then 0 else if c <= -1 then 12 else Float.acos c * 12 / basePi
  let low := max awakeFirst.toFloat (Float.floor ((12 - halfDay) * 4 - 0.5) + 1)
  let high := min awakeLast.toFloat (Float.ceil ((12 + halfDay) * 4 - 0.5) - 1)
  let lit := max 0 (high - low + 1)
  (awakeLast - awakeFirst + 1).toFloat - lit

/-- The mean of the dark awake steps of a day over a year. It samples every fifth day. -/
private def meanDarkAwakeSteps (latitude : Float) : Float := Id.run do
  let mut sum := 0.0
  for k in [0:73] do
    sum := sum + darkAwakeSteps latitude (5 * k + 2)
  return sum / 73

/-- The day of the year with the warmest rooms. -/
private def warmDay (latitude : Float) : Nat := if latitude >= 0 then 197 else 15

/-- The mean power of the fridge and freezer: 0.12 kW times a duty that rises with the room
temperature. -/
private def fridgeKw (latitude : Float) (dayOfYear : Nat) : Float :=
  let offset := dayOfYear.toFloat - (warmDay latitude).toFloat
  let roomC := 20 + 3 * Float.cos (2 * basePi * offset / 365)
  0.12 * (0.35 + 0.02 * (roomC - 20))

/-- The power of the cooking: 0.4 kWh from 07:00 to 08:00 and 0.8 kWh from 18:00 to 19:30. -/
private def cookingKw (step : Nat) : Float :=
  if 28 <= step && step < 32 then 0.4 / 4 / stepHours
  else if 72 <= step && step < 78 then 0.8 / 6 / stepHours
  else 0

/-- The standby power of the home. -/
private def homeStandbyKw : Float := 0.15

/-- The power of the lighting when it is dark and someone is awake. -/
private def lightingKw : Float := 0.3

/-- The base load of a step in kW (D12): the fridge and freezer, the lighting, the cooking and the
standby, scaled so that a mean day equals `dailyKwh`. -/
def baseLoadKw (dailyKwh latitude : Float) (dayOfYear step : Nat) : Float :=
  let day := dayOfYear % 365
  let step := step % 96
  let lights :=
    if awakeFirst <= step && step <= awakeLast && baseSinHeight latitude day step < 0
    then lightingKw else 0
  let raw := fridgeKw latitude day + lights + cookingKw step + homeStandbyKw
  let meanDayKwh := 24 * 0.12 * 0.35 + 1.2 + 24 * homeStandbyKw
    + lightingKw * stepHours * meanDarkAwakeSteps latitude
  raw * dailyKwh / meanDayKwh

end StoragePolicySim
