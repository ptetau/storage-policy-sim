/-
The policies of the hot-water tanks, the battery and the flexible load. Not built yet: each
function is a stub, and each default is a placeholder.
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

/-- A placeholder. Not built yet. -/
def defaultStatic : StaticParams := default

/-- A placeholder. Not built yet. -/
def defaultPlan : PlanParams := default

/-- A placeholder. Not built yet. -/
def defaultDynamic : DynamicParams := default

/-- The 24 actions of a static policy. Not built yet. -/
def staticProfile (tanks : Array TankConfig) (params : StaticParams) (flexDayKwh : Float) :
    Array Action :=
  let _ := (tanks, params, flexDayKwh)
  todo "staticProfile" 0

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
