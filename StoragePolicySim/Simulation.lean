/-
The simulation: one strategy with a battery over a scenario, hour by hour. It gives the
energy flows of each hour, the totals of the run, and the totals of each month.
CAP-simulation (hourly energy flows) gives the rules.
-/
import StoragePolicySim.Scenario
import StoragePolicySim.Strategy

namespace StoragePolicySim

/-- A home battery. -/
structure Battery where
  /-- The most energy that the battery can hold. -/
  capacityKwh : Float
  /-- The most energy that can go in, or come out, in one hour. -/
  powerKw : Float
  deriving Repr, Inhabited

/-- The share that the battery keeps of the energy in, and gives of the energy out. -/
def efficiency : Float := 0.95

/-- The energy flows of one hour, each in kWh. -/
structure Flow where
  /-- The solar energy that the house uses directly. -/
  directKwh : Float
  /-- The solar energy that goes into the battery, before the loss. -/
  chargeKwh : Float
  /-- The energy that the battery gives to the house, after the loss. -/
  dischargeKwh : Float
  /-- The energy to the grid. -/
  exportKwh : Float
  /-- The energy from the grid. -/
  importKwh : Float
  /-- The battery loss of the hour. -/
  lossKwh : Float
  /-- The energy in the battery after the hour. -/
  socKwh : Float
  deriving Repr, Inhabited

/-- The smallest of three values, and 0 if that value is less than 0. -/
private def limitTo (a b c : Float) : Float :=
  max 0 (min a (min b c))

/-- The flows of one hour. `socKwh` is the energy in the battery before the hour. The
battery takes what the strategy asks, up to the surplus, the power and the free room. The
battery gives what the strategy asks, up to the shortfall, the power and the stored energy.
The power limit applies to the energy in, and to the energy out after the loss. -/
def stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat)
    (pvKwh loadKwh : Float) : Flow :=
  let directKwh := min pvKwh loadKwh
  let surplusKwh := pvKwh - directKwh
  let shortfallKwh := loadKwh - directKwh
  let request := strategy.decide hour surplusKwh shortfallKwh
  let chargeToFillKwh := (battery.capacityKwh - socKwh) / efficiency
  let chargeKwh := limitTo request.chargeKwh surplusKwh (min battery.powerKw chargeToFillKwh)
  let storedAfterChargeKwh := socKwh + chargeKwh * efficiency
  let dischargeKwh := limitTo request.dischargeKwh shortfallKwh
    (min battery.powerKw (storedAfterChargeKwh * efficiency))
  let takenOutKwh := dischargeKwh / efficiency
  { directKwh, chargeKwh, dischargeKwh,
    exportKwh := surplusKwh - chargeKwh,
    importKwh := shortfallKwh - dischargeKwh,
    lossKwh := chargeKwh - chargeKwh * efficiency + takenOutKwh - dischargeKwh,
    socKwh := storedAfterChargeKwh - takenOutKwh }

/-- One hour of a run. -/
structure HourResult where
  /-- The hour of the scenario. -/
  hour : Hour
  /-- The base load and the flexible load that the strategy placed. -/
  loadKwh : Float
  /-- The energy flows of the hour. -/
  flow : Flow
  deriving Repr, Inhabited

/-- The totals of a run, or of a month of a run. -/
structure Totals where
  pvKwh : Float
  loadKwh : Float
  importKwh : Float
  exportKwh : Float
  lossKwh : Float
  /-- The solar energy less the export. -/
  selfUsedKwh : Float
  /-- The energy in the battery at the end. -/
  finalSocKwh : Float
  /-- The self-used solar energy as a percentage of the solar energy. -/
  selfConsumption : Float
  /-- The load less the import, as a percentage of the load. -/
  selfSufficiency : Float
  deriving Repr, Inhabited

/-- The totals of one calendar month of a run. -/
structure Month where
  /-- `"Jan"` to `"Dec"`. -/
  name : String
  /-- The days of the run in this month. -/
  days : Nat
  totals : Totals
  deriving Repr, Inhabited

/-- The result of a run. -/
structure Result where
  hours : Array HourResult
  totals : Totals
  months : Array Month
  deriving Repr, Inhabited

/-- The sums of the hours that the totals need. -/
private structure HourSums where
  pvKwh : Float := 0
  loadKwh : Float := 0
  importKwh : Float := 0
  exportKwh : Float := 0
  lossKwh : Float := 0

/-- The sums with one more hour added. -/
private def HourSums.add (sums : HourSums) (hourResult : HourResult) : HourSums :=
  { pvKwh := sums.pvKwh + hourResult.hour.pvKwh,
    loadKwh := sums.loadKwh + hourResult.loadKwh,
    importKwh := sums.importKwh + hourResult.flow.importKwh,
    exportKwh := sums.exportKwh + hourResult.flow.exportKwh,
    lossKwh := sums.lossKwh + hourResult.flow.lossKwh }

/-- `part` as a percentage of `whole`. A ratio with nothing to divide by is 0%. -/
private def percent (part whole : Float) : Float :=
  if whole == 0 then 0 else 100 * part / whole

/-- The totals of the sums, with the energy in the battery at the end. -/
private def HourSums.toTotals (sums : HourSums) (finalSocKwh : Float) : Totals :=
  let selfUsedKwh := sums.pvKwh - sums.exportKwh
  { pvKwh := sums.pvKwh, loadKwh := sums.loadKwh, importKwh := sums.importKwh,
    exportKwh := sums.exportKwh, lossKwh := sums.lossKwh, selfUsedKwh, finalSocKwh,
    selfConsumption := percent selfUsedKwh sums.pvKwh,
    selfSufficiency := percent (sums.loadKwh - sums.importKwh) sums.loadKwh }

/-- The name and the length of each month of a year with no leap day. -/
private def calendar : Array (String × Nat) :=
  #[("Jan", 31), ("Feb", 28), ("Mar", 31), ("Apr", 30), ("May", 31), ("Jun", 30),
    ("Jul", 31), ("Aug", 31), ("Sep", 30), ("Oct", 31), ("Nov", 30), ("Dec", 31)]

/-- The month of a day of the year, from 0 (January) to 11 (December). -/
private def monthOfDay (dayOfYear : Nat) : Nat := Id.run do
  let mut nextFirstDay := 0
  for month in [0:calendar.size] do
    nextFirstDay := nextFirstDay + calendar[month]!.2
    if dayOfYear < nextFirstDay then return month
  return calendar.size - 1

/-- The month of the run that is in progress. -/
private structure OpenMonth where
  month : Nat
  days : Nat := 0
  sums : HourSums := {}

/-- The month with its name, its days and its totals. -/
private def OpenMonth.close (openMonth : OpenMonth) (socKwh : Float) : Month :=
  { name := calendar[openMonth.month]!.1, days := openMonth.days,
    totals := openMonth.sums.toTotals socKwh }

/-- The run of one strategy with a battery over the scenario of the site. The battery is
empty at the start. For each day, the strategy places the flexible load. -/
def simulate (site : Site) (battery : Battery) (strategy : Strategy) (seed days : Nat) :
    Result := Id.run do
  let scenarioHours := scenario site seed days
  let mut hours : Array HourResult := Array.mkEmpty scenarioHours.size
  let mut socKwh : Float := 0
  let mut runSums : HourSums := {}
  let mut months : Array Month := #[]
  let mut openMonth : OpenMonth := { month := 0 }
  for day in [0:days] do
    let dayHours := scenarioHours.extract (24 * day) (24 * day + 24)
    let flexKwh := strategy.placeFlex (dayHours.map (·.pvKwh)) (dayHours.map (·.flexKwh))
    let month := monthOfDay (day % daysInYear)
    if month != openMonth.month then
      months := months.push (openMonth.close socKwh)
      openMonth := { month }
    openMonth := { openMonth with days := openMonth.days + 1 }
    for k in [0:dayHours.size] do
      let hour := dayHours[k]!
      let loadKwh := hour.baseLoadKwh + flexKwh[k]!
      let flow := stepHour battery socKwh strategy hour.hour hour.pvKwh loadKwh
      let hourResult : HourResult := { hour, loadKwh, flow }
      socKwh := flow.socKwh
      hours := hours.push hourResult
      runSums := runSums.add hourResult
      openMonth := { openMonth with sums := openMonth.sums.add hourResult }
  if openMonth.days > 0 then
    months := months.push (openMonth.close socKwh)
  return { hours, totals := runSums.toTotals socKwh, months }

end StoragePolicySim
