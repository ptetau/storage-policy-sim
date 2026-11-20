/-
The policies of the hot-water tanks, the battery and the flexible load. Built: the structures,
`defaultStatic` and `staticProfile`. Not built yet: `Policy.name`, `planDay` and `dynamicAction`
(stubs), and `defaultPlan` and `defaultDynamic` (placeholders).
-/
import StoragePolicySim.HotWater
import StoragePolicySim.Stub

namespace StoragePolicySim

/-- What a policy asks for in one hour. -/
structure Action where
  heatKwh : Array Float
  allowCharge : Bool
  allowDischarge : Bool
  flexKwh : Float
  deriving Repr, Inhabited

/-- The heating window of one tank. -/
structure TankWindow where
  heatStart : Nat
  heatHours : Nat
  deriving Repr, Inhabited

/-- The parameters of a static policy. -/
structure StaticParams where
  windows : Array TankWindow
  dischargeFrom : Nat
  flexStart : Nat
  deriving Repr, Inhabited

/-- The parameters of a precomputed policy. -/
structure PlanParams where
  targetKwh : Array Float
  minSolarKwh : Float
  dischargeFrom : Nat
  deriving Repr, Inhabited

/-- The parameters of a dynamic policy. -/
structure DynamicParams where
  lowKwh : Array Float
  targetKwh : Array Float
  dischargeFrom : Nat
  deriving Repr, Inhabited

/-- A policy. -/
inductive Policy where
  | static (p : StaticParams)
  | precomputed (p : PlanParams)
  | dynamic (p : DynamicParams)
  deriving Repr, Inhabited

/-- The name of a policy. Not built yet. -/
def Policy.name (policy : Policy) : String :=
  let _ := policy
  todo "Policy.name" 0

/-- The default static policy: heat from 10:00 for 4 hours, discharge from 17:00, and run the
flexible load from 18:00. -/
def defaultStatic : StaticParams :=
  { windows := #[{ heatStart := 10, heatHours := 4 }], dischargeFrom := 17, flexStart := 18 }

/-- A placeholder. Not built yet. -/
def defaultPlan : PlanParams := default

/-- A placeholder. Not built yet. -/
def defaultDynamic : DynamicParams := default

/-- The hours in a day. -/
def hoursInDay : Nat := 24

/-- The parts that the flexible load of a day runs in. -/
def flexParts : Nat := 3

/-- The window of a tank: window `i`, or the last window when there are fewer. -/
def StaticParams.windowOf (params : StaticParams) (tank : Nat) : Option TankWindow :=
  params.windows[tank]? <|> params.windows.back?

/-- The 24 actions of a static policy. Tank `i` asks for its element power in its window, and
the window stops at the end of the day. The battery may always charge, and may discharge from
`dischargeFrom`. The flexible load runs in 3 equal parts from `flexStart`, in fewer and larger
parts when the day ends first. -/
def staticProfile (tanks : Array TankConfig) (params : StaticParams) (flexDayKwh : Float) :
    Array Action :=
  let parts := min flexParts (hoursInDay - params.flexStart)
  let partKwh := if parts == 0 then 0.0 else flexDayKwh / parts.toFloat
  (Array.range hoursInDay).map fun hour =>
    let heatKwh := tanks.mapIdx fun i tank =>
      match params.windowOf i with
      | some window =>
        if window.heatStart ≤ hour && hour < window.heatStart + window.heatHours
        then tank.elementKw else 0.0
      | none => 0.0
    { heatKwh, allowCharge := true, allowDischarge := params.dischargeFrom ≤ hour,
      flexKwh := if params.flexStart ≤ hour && hour < params.flexStart + parts then partKwh
        else 0.0 }

/-- The 24 actions of a precomputed policy for one day. Not built yet. -/
def planDay (tanks : Array TankConfig) (params : PlanParams)
    (forecastKwh tankKwh expectedDrawKwh : Array Float) (flexDayKwh : Float) : Array Action :=
  let _ := (tanks, params, forecastKwh, tankKwh, expectedDrawKwh, flexDayKwh)
  todo "planDay" 0

/-- What a dynamic policy sees in one hour. -/
structure Observation where
  hour : Nat
  tankKwh : Array Float
  socKwh : Float
  surplusKwh : Float
  forecastRestKwh : Float
  flexLeftKwh : Float
  startsToday : Array Nat
  askedLastHour : Array Bool
  deriving Repr, Inhabited

/-- The action of a dynamic policy for one hour. Not built yet. -/
def dynamicAction (tanks : Array TankConfig) (params : DynamicParams) (obs : Observation) : Action :=
  let _ := (tanks, params, obs)
  todo "dynamicAction" 0

end StoragePolicySim
