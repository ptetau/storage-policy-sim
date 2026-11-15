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
