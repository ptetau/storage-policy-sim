# CH-0007 · Hot-water tank with a comfort floor

Intent: IN-0008 · Scope: CAP-hotwater · Status: planned · Ticket: none · Branch: none · Base: main

Tests-Locked: none

## Delivers

The library models an electric hot-water tank: heating limits, standby loss, the draw, and the thermostat backstop. It also gives the hot-water draw profile that changes with the season.

## Requirements

### CAP-hotwater.R1 · Standby loss and draw
- Given 5.0 kWh stored and no draw, when the hour runs, then the loss is 0.02 kWh and the tank holds 4.98 kWh.
- Given 5.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.02 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 3.48 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.004 kWh, the served draw is 0.996 kWh and the unmet draw is 1.004 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.042 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits
- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.98 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.98 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.536 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.042 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.992 kWh and the unmet draw is 0.508 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat backstop
- Given 2.5 kWh stored and no request, when the hour runs, then the heating is 0 kWh, the backstop heating is 0.51 kWh and the tank holds 3.0 kWh.
- Given 2.5 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh, the backstop heating is 0 kWh and the tank holds 4.49 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the unmet draw is 1.004 kWh, the backstop heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a floor of 5.0 kWh, 1.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh, the backstop heating is 1.0 kWh and the tank holds 3.996 kWh.
- Given 3.0 kWh stored and no request, when the hour runs, then the backstop heating is 0.012 kWh and the tank holds 3.0 kWh.
- Given a floor of 0 kWh, 1.0 kWh stored and no request, when the hour runs, then the backstop heating is 0 kWh.

### CAP-hotwater.R4 · Hot-water draw profile
- Given latitude 45, when the draw of each hour of days 0 to 364 is added, then the sum is 2190.0 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the 24 hours of day 100 are added, then the sum is 6.0 × (1 + 0.15 × cos(2π × 85 / 365)) kWh. The tolerance is 0.000001 kWh.
- Given latitude 45, when the days 15 and 197 are compared, then the draw of day 15 is 1.34 to 1.37 times the draw of day 197.
- Given latitude -41, when the days 15 and 197 are compared, then the draw of day 197 is 1.34 to 1.37 times the draw of day 15.
- Given latitude 45, when the hours of day 100 are compared, then hour 7 draws more than hour 3, and hour 19 draws more than hour 13.
- Given a daily energy of 0.0 kWh, when each hour of day 100 is read, then each draw is 0 kWh.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour) and `floorKwh` (the comfort floor).
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.004 each hour, and a floor of 3.0 kWh
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the policy asked for), `backstopKwh` and `energyKwh` (the energy that the tank holds after the hour).
  - errors: none
- `tankStep (cfg : TankConfig) (energyKwh requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank, the energy that it holds, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none

### Test seams

none

## Files

- `StoragePolicySim/HotWater.lean`

## Check files

- `tests/CAP-hotwater.lean`

## Steps

### Step 1 · Standby loss and draw · [ ]

- Requirement: CAP-hotwater.R1
- Check: the checks named `CAP-hotwater.R1 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 2 · Heating limits · [ ]

- Requirement: CAP-hotwater.R2
- Check: the checks named `CAP-hotwater.R2 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 3 · Thermostat backstop · [ ]

- Requirement: CAP-hotwater.R3
- Check: the checks named `CAP-hotwater.R3 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 4 · Hot-water draw profile · [ ]

- Requirement: CAP-hotwater.R4
- Check: the checks named `CAP-hotwater.R4 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned second. It needs no other change of IN-0008 (hot-water policy simulation).
