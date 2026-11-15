# Brief for the test writer · CH-0009-policy

Write the component checks of this change, only in the files under its "Check files".

This brief holds each input of the checks. Read another file only when this brief names
it, for example an existing check file to match its style.

Made at: be5c0a5a16ff608f1e8c9ae6110a4382cf95aff5

## The change spec

Path: pdlc/changes/CH-0009-policy/change.md

````
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
````

## The specs

### pdlc/specs/capabilities/CAP-policy.md

````
# CAP-policy · Daily-profile policies for the hot-water tank and the battery

Status: active

## What it is for

CAP-policy (daily-profile policies) decides, for each hour, how much heating the hot-water
tank asks for, and whether the battery may charge and may discharge. It has three kinds of
policy. A static policy repeats one fixed profile each day. A precomputed policy makes a
day-ahead plan from the solar forecast. A dynamic policy decides each hour from the state of
the tank and the surplus of that hour.

## Code map

- `StoragePolicySim/Policy.lean`

## Interface

- `Action` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatKwh : Float` (the heating that the tank asks for), and `allowCharge` and `allowDischarge`, each a `Bool`.
  - errors: none
- `StaticParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `heatStart`, `heatHours` and `dischargeFrom`, each a `Nat`, and `elementKw : Float`.
  - errors: none
- `PlanParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `targetKwh` and `minSolarKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `DynamicParams` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `lowKwh` and `targetKwh`, each a `Float`, and `dischargeFrom : Nat`.
  - errors: none
- `Observation` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `hour : Nat`, and `tankKwh`, `socKwh`, `surplusKwh` and `forecastRestKwh`, each a `Float`.
  - errors: none
- `Policy` · type · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: `static` with `StaticParams`, `precomputed` with `PlanParams`, or `dynamic` with `DynamicParams`. The type has `Repr` and `Inhabited`.
  - errors: none
- `Policy.name (policy : Policy) : String` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a policy
  - out: `"static"`, `"precomputed"` or `"dynamic"`
  - errors: none
- `defaultStatic : StaticParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: heating from 10:00 for 4 hours, discharge from 17:00, and an element of 3.0 kW
  - errors: none
- `defaultPlan : PlanParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a target of 10.5 kWh (a full tank), a minimum forecast of 0.5 kWh, and discharge from 17:00
  - errors: none
- `defaultDynamic : DynamicParams` · constant · `StoragePolicySim/Policy.lean` · proposed
  - in: not applicable
  - out: a low level of 5.25 kWh, a target of 10.5 kWh (a full tank), and discharge from 17:00
  - errors: none
- `staticProfile (params : StaticParams) : Array Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: the parameters of a static policy
  - out: 24 actions, one for each hour of the day
  - errors: none
- `planDay (cfg : TankConfig) (params : PlanParams) (forecastKwh : Array Float) (tankKwh expectedDrawKwh : Float) : Array Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a tank, the parameters of a precomputed policy, the forecast solar energy of the 24 hours of the day, the energy in the tank at the start of the day, and the hot water that the household is expected to draw in the day
  - out: 24 actions, one for each hour of the day
  - errors: none
- `dynamicAction (cfg : TankConfig) (params : DynamicParams) (obs : Observation) : Action` · function · `StoragePolicySim/Policy.lean` · proposed
  - in: a tank, the parameters of a dynamic policy, and what the policy sees in the hour
  - out: the action of the hour
  - errors: none

### Test seams

none

## Requirements

### CAP-policy.R1 · Static profile

Status: ready · Intents: IN-0008

A static policy repeats one profile each day. The tank asks for the element power in each hour
from `heatStart` for `heatHours` hours, and for nothing in the other hours. The window stops at
the end of the day (assumed). The battery may always charge. It may discharge from the hour
`dischargeFrom` to the end of the day, and a value of 24 never lets it discharge (assumed).

In these lines, the parameters are `defaultStatic`, unless the line says otherwise.

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

Status: ready · Intents: IN-0008

A precomputed policy makes one plan at the start of the day. The need is the target less the
energy in the tank, plus the hot water that the household is expected to draw, and never
less than 0 (assumed). Only an hour with a forecast of at least `minSolarKwh` can heat.
The plan gives the element power to these hours, from the highest forecast to the lowest,
until the need is met. A tie goes to the earlier hour (assumed). If the hours cannot meet
the need, the rest of the need stays unplanned. The battery rules are those of R1, with
`dischargeFrom` of the plan.

In these lines, the tank is the default tank and the parameters are `defaultPlan` with a target
of 9.0 kWh, unless the line says otherwise.

- Given a forecast of 1.0, 2.0, 3.5, 3.0, 4.0 and 1.5 kWh in hours 9 to 14 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hours 10, 11, 12 and 13 ask for 2.0, 3.0, 3.0 and 3.0 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 9.0 kWh in the tank and an expected draw of 0.5 kWh, when the day is planned, then hour 13 asks for 0.5 kWh. The other hours ask for 0 kWh.
- Given the same forecast, 10.0 kWh in the tank and an expected draw of 0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.4 kWh in each hour, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then each hour asks for 0 kWh.
- Given a forecast of 0.5 kWh in hour 12 and 0 kWh in the other hours, 4.0 kWh in the tank and an expected draw of 6.0 kWh, when the day is planned, then hour 12 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a minimum forecast of 0.0 kWh, a forecast of 0 kWh in each hour, 9.0 kWh in the tank and an expected draw of 3.0 kWh, when the day is planned, then hour 0 asks for 3.0 kWh and the other hours ask for 0 kWh.
- Given a forecast of 2.0 kWh in hours 10 to 14, 9.0 kWh in the tank and an expected draw of 4.0 kWh, when the day is planned, then hour 10 asks for 3.0 kWh and hour 11 asks for 1.0 kWh.
- Given the default parameters, when a day is planned, then the battery may charge in each hour, may discharge in hour 17, and may not discharge in hour 16.

### CAP-policy.R3 · Dynamic action

Status: ready · Intents: IN-0008

A dynamic policy decides each hour from what it sees. First it soaks up surplus: when the
hour has a solar surplus and the tank holds less than the target, the tank asks for the
smallest of the element power, the surplus and the room to the target. If not, and the tank
holds less than the low level, and the forecast for the rest of the day is less than the
lack, the tank asks for the smaller of the element power and the lack. The lack is the low
level less the energy in the tank. In every other case the tank asks for 0 kWh. The battery rules are those of R1, with
`dischargeFrom` of the policy. The surplus is 0 or more (assumed).

In these lines, the tank is the default tank and the parameters are `defaultDynamic` with a low
level of 4.0 kWh and a target of 9.0 kWh, unless the line says otherwise.

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

Status: ready · Intents: IN-0008

The defaults give a sensible start for a home with the default tank (assumed). The target is a
full tank, because the tank must be full once a day for the legionella guard, and the sun is
cheaper than the grid for that heating (assumed). A policy has a name that a command can print.

- Given `defaultStatic`, when it is read, then the heating starts at 10, lasts 4 hours, discharge starts at 17, and the element is 3.0 kW.
- Given `defaultPlan`, when it is read, then the target is 10.5 kWh, the minimum forecast is 0.5 kWh, and discharge starts at 17.
- Given `defaultDynamic`, when it is read, then the low level is 5.25 kWh, the target is 10.5 kWh, and discharge starts at 17.
- Given a static, a precomputed and a dynamic policy, when the names are read, then they are `static`, `precomputed` and `dynamic`.
````

### pdlc/specs/capabilities/CAP-hotwater.md

````
# CAP-hotwater · Hot-water tank with a thermostat

Status: active

## What it is for

CAP-hotwater (hot-water tank) models an electric hot-water tank, one hour at a time. The
tank holds thermal energy in kWh above the cold inlet. The element heats the tank by the
energy that a policy asks for. A thermostat with a cut-in level adds backstop heating, so that
the tank is never cold. The tank also heats to full once each day, because water that stays
below 60 °C can grow legionella bacteria. The household draws hot water by a daily profile
that changes with the season, and with a random factor for each day.

## Code map

- `StoragePolicySim/HotWater.lean`

## Interface

- `TankConfig` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams

- `drawSeed` · seam: randomness · `StoragePolicySim/HotWater.lean` · proposed
  - in: the `seed` argument of `drawFactor`. The same seed gives the same factors.
  - errors: none

## Requirements

### CAP-hotwater.R1 · Standby loss and draw

Status: ready · Intents: IN-0008

In each hour, the tank first loses a share of its energy, 0.6% in the default tank (assumed).
That is 1.5 kWh in a day for a full tank, near the average of the New Zealand tanks. Then the
household draws hot water. The tank serves the smaller of the draw and the energy that it
holds. The rest of the draw is the unmet draw.

In these lines, the tank is the default tank with a cut-in of 0 kWh, so that the thermostat
stays out of the line. The hour is 12, the thermostat is off, and the tank was full today.
The request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given 8.0 kWh stored and no draw, when the hour runs, then the loss is 0.048 kWh and the tank holds 7.952 kWh.
- Given 8.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.048 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 6.452 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.006 kWh, the served draw is 0.994 kWh and the unmet draw is 1.006 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.063 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits

Status: ready · Intents: IN-0008

The element heats the tank by the energy that the policy asks for. The heating is never more
than the element power for one hour, and never more than the room that the tank has left.
The draw of the hour comes before the heating (assumed). Thus, a tank that holds too little
energy has an unmet draw, also when the policy asks for heating in the same hour.

In these lines, the tank is the default tank with a cut-in of 0 kWh, the hour is 12, the
thermostat is off, and the tank was full today. The draw is 0 kWh, unless the line says
otherwise. The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.97 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.97 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.554 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.988 kWh and the unmet draw is 0.512 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat

Status: ready · Intents: IN-0008

After the heating of the policy, the thermostat decides. It cuts in when the tank holds less
than the cut-in level, 5.25 kWh in the default tank, which is half of the capacity (assumed).
Once in, it stays on from hour to hour, until the tank is full. That is the dead band of a
real thermostat. A tank is full when it holds its capacity, within 0.000000001 kWh.

While the thermostat is on, the backstop heating is the element power that the policy left in
the hour, and never more than the room that the tank has left. The backstop heating counts
apart from the heating that the policy asked for. When the thermostat is off, the backstop
heating is 0 kWh.

In these lines, the tank is the default tank, the hour is 12, the thermostat is off, the tank
was full today, the draw is 0 kWh and the request is 0 kWh, unless the line says otherwise.
The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 7.97 kWh and the thermostat is on.
- Given 6.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh, the tank holds 5.964 kWh and the thermostat is off.
- Given 6.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 8.964 kWh and the thermostat is on.
- Given 9.0 kWh stored and the thermostat on, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and the thermostat is off.
- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the backstop heating is 0 kWh. The tank holds 6.97 kWh and the thermostat is off.
- Given 4.0 kWh stored and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 2.0 kWh. The tank holds 6.976 kWh and the thermostat is on.
- Given 9.0 kWh stored, the thermostat on and a request of 1.0 kWh, when the hour runs, then the heating is 1.0 kWh and the backstop heating is 0.554 kWh. The tank holds 10.5 kWh and the thermostat is off.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the unmet draw is 1.006 kWh, the backstop heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a cut-in of 0 kWh and 1.0 kWh stored, when the hour runs, then the backstop heating is 0 kWh.

### CAP-hotwater.R4 · Hot-water draw profile

Status: ready · Intents: IN-0008

The household draws more hot water in the morning and in the evening. The hours of a day share
the daily energy by a fixed profile with a peak at 07:00 and a peak at 19:00 (assumed). A
seasonal factor of 1 + 0.15 × cos(2π × (day - peak) / 365) scales the daily energy, because
the cold inlet is colder in winter (assumed). The peak is day 15 at latitude 0 or more, and
day 197 at a negative latitude (assumed).

In these lines, the daily energy is 6.0 kWh, unless the line says otherwise.

- Given latitude 45, when the draw of each hour of days 0 to 364 is added, then the sum is 2190.0 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the 24 hours of day 100 are added, then the sum is 6.0 × (1 + 0.15 × cos(2π × 85 / 365)) kWh. The tolerance is 0.000001 kWh.
- Given latitude 45, when the days 15 and 197 are compared, then the draw of day 15 is 1.34 to 1.37 times the draw of day 197.
- Given latitude -41, when the days 15 and 197 are compared, then the draw of day 197 is 1.34 to 1.37 times the draw of day 15.
- Given latitude 45, when the hours of day 100 are compared, then hour 7 draws more than hour 3, and hour 19 draws more than hour 13.
- Given a daily energy of 0.0 kWh, when each hour of day 100 is read, then each draw is 0 kWh.

### CAP-hotwater.R5 · Daily full heating

Status: ready · Intents: IN-0008

The tank is full at least once each day, so that the stored water stays hot enough against
legionella bacteria (assumed). From the guard hour, 20 in the default tank (assumed), the
thermostat cuts in when the tank has not been full since hour 0 of the day. It stays on until
the tank is full, as in R3. The state `fullToday` is false at the end of hour 0, unless the
tank is full after that hour. It becomes true in the hour in which the tank is full, and it
stays true to the end of the day.

In these lines, the tank is the default tank, the thermostat is off, the draw is 0 kWh and
the request is 0 kWh, unless the line says otherwise. The tolerance is 0.000000001 kWh.

- Given hour 20, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 1.554 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 19, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh, the tank holds 8.946 kWh and `fullToday` is false.
- Given hour 20, 9.0 kWh stored and a tank that was full today, when the hour runs, then the backstop heating is 0 kWh and the tank holds 8.946 kWh.
- Given hour 22, 4.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 3.0 kWh, the tank holds 6.976 kWh and the thermostat is on.
- Given hour 0, 10.5 kWh stored and a tank that was full the day before, when the hour runs, then the tank holds 10.437 kWh and `fullToday` is false.
- Given hour 0, 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh, the tank holds 10.5 kWh and `fullToday` is true.
- Given hour 12, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given a guard hour of 24, hour 23, 9.0 kWh stored and a tank that was not full today, when the hour runs, then the backstop heating is 0 kWh.
- Given the start state of the default tank, when `startState` is read, then the tank holds 10.5 kWh, the thermostat is off and `fullToday` is true.

### CAP-hotwater.R6 · Daily draw factor

Status: ready · Intents: IN-0008

A household draws more hot water on some days, and less on others. The factor of a day is
`exp(cv × z - cv × cv / 2)`, where `cv` is the spread of the draw and `z` is a random number
from a normal curve (assumed). The number `z` depends only on the seed and the day. Thus, the
mean of the factor is 1, and a spread of 0 gives the factor 1.

- Given a spread of 0, when the factors of days 0 to 364 are read, then each is 1.0. The tolerance is 0.000000000001.
- Given seed 7 and a spread of 0.25, when the factors of days 0 to 4999 are read, then each is more than 0. Their mean is from 0.98 to 1.02, and their standard deviation is from 0.23 to 0.27.
- Given seed 7 and a spread of 0.5, when the factors of days 0 to 4999 are read, then their mean is from 0.97 to 1.03, and their standard deviation is from 0.48 to 0.58.
- Given seed 7 and a spread of 0.25, when the factor of the same day is read two times, then the two factors are the same.
- Given the seeds 7 and 8 and a spread of 0.25, when the factors of days 0 to 364 are compared, then at least 300 days have a different factor.
````

### pdlc/specs/design/DES-errors.md

````
# DES-errors · The project's error codes

Status: agreed · Default: yes · Ask at init: no

## Rule

Each error that the system can give has a code here, in `UPPER_SNAKE_CASE`. Acceptance
lines, Interface entries, and checks all use these codes. Thus, a check can expect the
exact error.

| Code | Meaning | Whose fault | Retry helps? |
|---|---|---|---|
| `UNKNOWN_COMMAND` | The first word of the command line is not a command | caller | no |
| `UNKNOWN_OPTION` | An option or a word that the command does not take | caller | no |
| `MISSING_VALUE` | An option that needs a value comes last, with no value | caller | no |
| `BAD_NUMBER` | The value of a number option is not a number of the right form | caller | no |
| `OUT_OF_RANGE` | A number is outside the range of its option | caller | no |
| `UNKNOWN_STRATEGY` | The name of the strategy is not in the list of strategies | caller | no |
| `UNKNOWN_POLICY` | The name of the policy is not in the list of policies | caller | no |

When a requirement needs a new error, add a row. When the meaning is the same, use the
existing code again.

Add rows at intake and ready. Do not add a row while a change is in tests, build, or
verify. When you add a row, leave `Default:` as it is. Write each row the same way:

- The code in backticks.
- "Whose fault": `caller`, `system`, or `outside service`.
- "Retry helps?": `yes` or `no`.

Checks and the code of the app match on the error code. Each requirement decides what a
person sees, for example a message or a status. The message or the status can omit the
error code. If the caller cannot see the error code, a check expects the exact message and
status instead.

## Why

A check that expects "an error" passes for any error, also for a typo. A named code makes
the check exact. A named code also gives callers a stable value to handle.
````

### pdlc/specs/design/DES-pdlc-check-tagging.md

````
# DES-pdlc-check-tagging · How checks name their requirement

Status: agreed · Default: yes · Ask at init: yes

## Rule

The requirement ID starts the name of the check, for example `CAP-email.R3 sends from a
template`. A check that proves two requirements names the two requirements.

If the check runner does not accept `.` or `-` in names (Python's `unittest`, for
example), write the ID with underscores instead: `test_CAP_email_R3_sends_from_a_template`.
The two forms count as the same ID. Use only one form in each project.

Lay checks out the same way everywhere:

- Put new check files in the check folder (`tests/` in a project that had none). Name
  each file after the spec it proves, in a form the runner finds: `test_CAP_email.py`,
  `CAP-email.test.js`.
- Inside a file, make one group per requirement (a test class or a `describe` block).
  Name the group with the requirement ID: `class CAP_email_R3(unittest.TestCase)`,
  `describe("CAP-email.R3", ...)`.
- Each check's name still starts with the ID, then says what it proves.

The acceptance checks of an intent go in one file for each intent, at the path of
"acceptance file" in `pdlc/config.md`. The name of the file holds the word "acceptance"
and the intent ID, for example `tests/acceptance_IN_0012.py` or
`acceptance/IN-0012.acceptance.js`. The "all" command does not run such a file. Inside the
file, make one group for each requirement, and start each check name with the requirement
ID.

## Why

The trace from a requirement to its checks is only as good as this naming. Thus, the
naming must be simple and the same everywhere.
````

### pdlc/specs/design/DES-lean-checks.md

````
# DES-lean-checks · How a Lean check file runs and reports

Status: agreed · Default: no

## Rule

Each check file is a Lean script that `lake env lean --run <file> [filter]` runs. The file
has these parts:

- One file for each spec, named after the spec: `tests/CAP-scenario.lean`. The acceptance
  file of an intent is `tests/acceptance/IN-0001.acceptance.lean`.
- The imports of the library modules that the file calls, for example
  `import StoragePolicySim.Scenario`. A check file does not import another check file.
  Thus, each file holds its own small helpers.
- `def main (args : List String) : IO UInt32`.
- Each check has a name that starts with its requirement ID and a space, for example
  `"CAP-scenario.R1 day 171 gives more than twice day 354"`.
- The checks of one requirement are together, under the comment `-- CAP-scenario.R1`.

When `main` gets a first argument, it runs only the checks whose names start with that
argument and a space. Thus, the filter `CAP-scenario.R1` does not run `CAP-scenario.R10`.

The file prints `FAIL <name>: <what went wrong>` for each failed check. Its last line is
`<n> checks, <k> failed`. It exits with 1 when `k` is more than 0, and else with 0. A
filter that matches no check gives `0 checks, 0 failed`. The checks port reads that line
as "no checks found".

A check that runs the `sim` command uses `IO.Process.output` with the command `timeout`
and the arguments `60`, `.lake/build/bin/sim`, and then the arguments of `sim`. The check
reads the exit code, stdout and stderr. A `Float` comparison uses a tolerance.

## Example

```lean
import StoragePolicySim.Scenario
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 night gives no output",
    run := do
      let v := pvOutput site45 171 0 .sunny
      return if v == 0 then none else some s!"got {v}" }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    match ← c.run with
    | none => pure ()
    | some msg => failed := failed + 1; IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
```

The toolchain is Lean 4.35.0. In this version, `String.trim` does not exist. Use
`String.trimAscii` and then `.toString`, or split with `String.splitOn`.

## Why

Lean has no standard check runner. One small form for every file gives each check a name
with its requirement ID. It also gives a filter for one requirement, and one count line for the checks
port.
````

## How the checks run (pdlc/config.md)

````
This section gives the command that runs the checks of this project, and the command that
runs only the checks for one requirement. Init writes this section. A project with no
checks yet keeps its checks in `tests/`.

- all: `lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done`
- one requirement: `lake build && for f in tests/*.lean; do lake env lean --run "$f" {req} || exit 1; done`
- check folders: `tests/`
- acceptance file: `tests/acceptance/{intent}.acceptance.lean`
- acceptance: `lake build && for f in {files}; do lake env lean --run "$f" || exit 1; done`
- ID form in check names: `dotted`
````

## The check files that exist now

- tests/CAP-scenario.lean
- tests/CAP-simulation.lean
- tests/CAP-strategies.lean
- tests/JOB-simulate.lean
- tests/acceptance/IN-0001.acceptance.lean
- tests/acceptance/IN-0002.acceptance.lean
- tests/acceptance/IN-0008.acceptance.lean
