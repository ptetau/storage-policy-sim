# CH-0009 · Daily-profile policies

Intent: IN-0008 · Scope: CAP-policy · Status: planned · Ticket: none · Branch: none · Base: main

Tests-Locked: none

## Delivers

The library has three kinds of policy for the hot-water tank and the battery: a static profile, a day-ahead plan from the forecast, and a dynamic action that reacts to the hour.

## Requirements

### CAP-policy.R1 · Static profile
- Given the default parameters, when the profile is made, then it has 24 actions.
- Given the default parameters, when the profile is made, then hours 10, 11, 12 and 13 ask for 3.0 kWh. Hours 9 and 14 ask for 0 kWh.
- Given the default parameters, when the profile is made, then the battery may discharge in hours 17 and 23, and may not discharge in hours 0 and 16.
- Given the default parameters, when the profile is made, then the battery may charge in each hour.
- Given 0 heating hours, when the profile is made, then each hour asks for 0 kWh.
- Given a start of 22 and 2 heating hours, when the profile is made, then hours 22 and 23 ask for 3.0 kWh. Hour 21 asks for 0 kWh.
- Given a start of 23 and 5 heating hours, when the profile is made, then hour 23 asks for 3.0 kWh. Hour 0 asks for 0 kWh.
- Given an element of 1.5 kW, when the profile is made, then each heating hour asks for 1.5 kWh.
- Given discharge from 24, when the profile is made, then the battery may not discharge in any hour.

### CAP-policy.R2 · Day-ahead plan
- Given a forecast of 1.0, 2.0, 3.5, 3.0, 4.0 and 1.5 kWh in hours 9 to 14 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hours 10, 11, 12 and 13 ask for 2.0, 3.0, 3.0 and 3.0 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 9.0 kWh in the tank and an expected draw of 0.5 kWh, when the day is planned, then hour 13 asks for 0.5 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 10.0 kWh in the tank and an expected draw of 0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.4 kWh in each hour, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.5 kWh in hour 12 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hour 12 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a minimum forecast of 0.0 kWh, a forecast of 0 kWh in each hour, 9.0 kWh in the tank and an expected draw of 3.0 kWh, when the day is planned, then hour 0 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a forecast of 2.0 kWh in hours 10 to 14, 9.0 kWh in the tank and an expected draw of 4.0 kWh, when the day is planned, then hour 10 asks for 3.0 kWh and hour 11 asks for 1.0 kWh.
- Given the default parameters, when a day is planned, then the battery may charge in each hour, may discharge in hour 17, and may not discharge in hour 16.

### CAP-policy.R3 · Dynamic action
- Given a surplus of 2.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 2.0 kWh.
- Given a surplus of 5.0 kWh and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 5.0 kWh and 8.0 kWh in the tank, when the hour is decided, then the tank asks for 1.0 kWh.
- Given a surplus of 5.0 kWh and 9.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh. With 9.5 kWh in the tank, the tank asks for 0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 0.5 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given no surplus, 3.0 kWh in the tank and a forecast of 1.0 kWh for the rest of the day, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus and 5.0 kWh in the tank, when the hour is decided, then the tank asks for 0 kWh.
- Given no surplus, 0.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 3.0 kWh.
- Given a surplus of 1.0 kWh, 3.0 kWh in the tank and a forecast of 0 kWh for the rest of the day, when the hour is decided, then the tank asks for 1.0 kWh.
- Given hour 16, when the hour is decided, then the battery may charge and may not discharge. Given hour 17, the battery may charge and may discharge.

### CAP-policy.R4 · Defaults and names
- Given `defaultStatic`, when it is read, then the heating starts at 10, lasts 4 hours, discharge starts at 17, and the element is 3.0 kW.
- Given `defaultPlan`, when it is read, then the target is 10.5 kWh, the minimum forecast is 0.5 kWh, and discharge starts at 17.
- Given `defaultDynamic`, when it is read, then the low level is 5.25 kWh, the target is 10.5 kWh, and discharge starts at 17.
- Given a static, a precomputed and a dynamic policy, when the names are read, then they are `static`, `precomputed` and `dynamic`.

## Relies on

- CAP-hotwater (used, not changed)
- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `Action` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Observation` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `hour : Nat`, and `tankKwh`, `socKwh`, `surplusKwh` and `forecastRestKwh`, each a `Float`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `Policy.name (policy : Policy) : String` · function · `StoragePolicySim/Policy.lean`
  - in: a policy
  - out: `"static"`, `"precomputed"` or `"dynamic"`
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean`
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `planDay (cfg : TankConfig) (params : PlanParams) (forecastKwh : Array Float) (tankKwh expectedDrawKwh : Float) : Array Action` · function · `StoragePolicySim/Policy.lean`
  - in: a tank, the parameters of a precomputed policy, the forecast solar energy of the 24 hours of the day, the energy in the tank at the start of the day, and the hot water that the household is expected to draw in the day
  - out: 24 actions, one for each hour of the day
  - errors: none
- `dynamicAction (cfg : TankConfig) (params : DynamicParams) (obs : Observation) : Action` · function · `StoragePolicySim/Policy.lean`
  - in: a tank, the parameters of a dynamic policy, and what the policy sees in the hour
  - out: the action of the hour
  - errors: none
- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none

### Test seams
none

## Files

- `StoragePolicySim/Policy.lean`

## Check files

- `tests/CAP-policy.lean`

## Steps

### Step 1 · Static profile · [ ]

- Requirement: CAP-policy.R1
- Check: the checks named `CAP-policy.R1 …` in `tests/CAP-policy.lean`
- Done when: the checks pass

### Step 2 · Day-ahead plan · [ ]

- Requirement: CAP-policy.R2
- Check: the checks named `CAP-policy.R2 …` in `tests/CAP-policy.lean`
- Done when: the checks pass

### Step 3 · Dynamic action · [ ]

- Requirement: CAP-policy.R3
- Check: the checks named `CAP-policy.R3 …` in `tests/CAP-policy.lean`
- Done when: the checks pass

### Step 4 · Defaults and names · [ ]

- Requirement: CAP-policy.R4
- Check: the checks named `CAP-policy.R4 …` in `tests/CAP-policy.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned fourth, after CAP-hotwater (hot-water tank), because a plan and an action use the tank.
