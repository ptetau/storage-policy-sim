# CAP-hotwater · Hot-water tank with a comfort floor

Status: active

## What it is for

CAP-hotwater (hot-water tank) models an electric hot-water tank, one hour at a time. The
tank holds thermal energy in kWh above the cold inlet. The element heats the tank by the
energy that a policy asks for. A thermostat adds backstop heating when the tank falls below
a comfort floor, so that the tank is never cold. The household draws hot water by a daily
profile that changes with the season.

## Code map

- `StoragePolicySim/HotWater.lean`

## Interface

- `TankConfig` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float`: `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour) and `floorKwh` (the comfort floor).
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.004 each hour, and a floor of 3.0 kWh
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean` · proposed
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. Each field is a `Float` in kWh: `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the policy asked for), `backstopKwh` and `energyKwh` (the energy that the tank holds after the hour).
  - errors: none
- `tankStep (cfg : TankConfig) (energyKwh requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: a tank, the energy that it holds, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean` · proposed
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none

### Test seams

none

## Requirements

### CAP-hotwater.R1 · Standby loss and draw

Status: ready · Intents: IN-0008

In each hour, the tank first loses a share of its energy, 0.4% in the default tank (assumed).
Then the household draws hot water. The tank serves the smaller of the draw and the energy
that it holds. The rest of the draw is the unmet draw.

In these lines, the tank is the default tank, and the request is 0 kWh, unless the line says
otherwise. The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored and no draw, when the hour runs, then the loss is 0.02 kWh and the tank holds 4.98 kWh.
- Given 5.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.02 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 3.48 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.004 kWh, the served draw is 0.996 kWh and the unmet draw is 1.004 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.042 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits

Status: ready · Intents: IN-0008

The element heats the tank by the energy that the policy asks for. The heating is never more
than the element power for one hour, and never more than the room that the tank has left.
The draw of the hour comes before the heating (assumed). Thus, a tank that holds too little
energy has an unmet draw, also when the policy asks for heating in the same hour.

In these lines, the tank is the default tank, and the draw is 0 kWh, unless the line says
otherwise. The tolerance is 0.000000001 kWh.

- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.98 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.98 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.536 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.042 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.992 kWh and the unmet draw is 0.508 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat backstop

Status: ready · Intents: IN-0008

After the heating of the policy, the thermostat heats the tank up to the comfort floor, 3.0
kWh in the default tank (assumed). The backstop heating is never more than the element power
that the policy left in the hour, and never more than the room that the tank has left. The
backstop heating counts apart from the heating that the policy asked for.

In these lines, the tank is the default tank, unless the line says otherwise. The tolerance
is 0.000000001 kWh.

- Given 2.5 kWh stored and no request, when the hour runs, then the heating is 0 kWh, the backstop heating is 0.51 kWh and the tank holds 3.0 kWh.
- Given 2.5 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh, the backstop heating is 0 kWh and the tank holds 4.49 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the unmet draw is 1.004 kWh, the backstop heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a floor of 5.0 kWh, 1.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh, the backstop heating is 1.0 kWh and the tank holds 3.996 kWh.
- Given 3.0 kWh stored and no request, when the hour runs, then the backstop heating is 0.012 kWh and the tank holds 3.0 kWh.
- Given a floor of 0 kWh, 1.0 kWh stored and no request, when the hour runs, then the backstop heating is 0 kWh.

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
