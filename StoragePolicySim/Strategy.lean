/-
The strategies that the simulation compares. For each hour, a strategy asks the battery to
charge or to discharge. For each day, a strategy also places the flexible load.
CAP-strategies (battery and load strategies) gives the rules.
-/
namespace StoragePolicySim

/-- A named strategy for the battery and the flexible load. -/
inductive Strategy
  /-- No battery use. -/
  | none
  /-- Battery use at any hour. -/
  | greedy
  /-- Discharge only in the evening. -/
  | evening
  /-- Greedy battery use, and the flexible load in the sunniest hours. -/
  | shift
  deriving BEq, Repr, Inhabited

/-- What a strategy asks the battery to do for one hour. -/
structure Request where
  /-- The energy that the strategy asks to charge. -/
  chargeKwh : Float
  /-- The energy that the strategy asks to discharge. -/
  dischargeKwh : Float
  deriving Repr

/-- The strategies, in the order of the comparison. -/
def Strategy.all : List Strategy :=
  [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]

/-- The name of a strategy on the command line. -/
def Strategy.name : Strategy → String
  | .none => "none"
  | .greedy => "greedy"
  | .evening => "evening"
  | .shift => "shift"

/-- The strategy whose name matches `name` exactly, or `Option.none`. -/
def Strategy.ofName? (name : String) : Option Strategy :=
  Strategy.all.find? (fun s => s.name == name)

/-- The first hour of the evening. The evening is 17:00 to 23:59. -/
private def eveningStartHour : Nat := 17

/-- The number of hours that get the flexible load of the `shift` strategy. -/
private def sunniestHourCount : Nat := 3

/-- A request that charges with the full surplus and discharges for the full shortfall. -/
private def fullRequest (surplusKwh shortfallKwh : Float) : Request :=
  { chargeKwh := surplusKwh, dischargeKwh := shortfallKwh }

/-- The request of a strategy for one hour. The simulation applies the limits of the
battery. -/
def Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request :=
  match s with
  | .none => { chargeKwh := 0, dischargeKwh := 0 }
  | .greedy | .shift => fullRequest surplusKwh shortfallKwh
  | .evening =>
    let dischargeKwh := if hour ≥ eveningStartHour then shortfallKwh else 0
    { chargeKwh := surplusKwh, dischargeKwh := dischargeKwh }

/-- The hours of a day, from the most solar energy to the least. A tie goes to the earlier
hour. -/
private def hoursBySun (pvKwh : Array Float) : List Nat :=
  let comesFirst (a b : Nat) : Bool :=
    pvKwh[a]! > pvKwh[b]! || (pvKwh[a]! == pvKwh[b]! && a ≤ b)
  (List.range pvKwh.size).mergeSort comesFirst

/-- The flexible load of the `shift` strategy: equal parts in the sunniest hours. A day
with no solar energy keeps the flexible load at its default hours. -/
private def shiftIntoSun (pvKwh flexKwh : Array Float) : Array Float :=
  if pvKwh.all (· ≤ 0) then flexKwh
  else
    let totalFlexKwh := flexKwh.foldl (· + ·) 0
    let sunniestHours := (hoursBySun pvKwh).take sunniestHourCount
    let partKwh := totalFlexKwh / sunniestHourCount.toFloat
    (List.range flexKwh.size).toArray.map (fun h =>
      if sunniestHours.contains h then partKwh else 0)

/-- The flexible load of each hour of a day, after the strategy places it. `pvKwh` is the
solar energy of each hour, and `flexKwh` is the flexible load at its default hours. -/
def Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float :=
  match s with
  | .none | .greedy | .evening => flexKwh
  | .shift => shiftIntoSun pvKwh flexKwh

end StoragePolicySim
