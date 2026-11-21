# Review packet · CH-0007-hotwater · specification

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 1ce86b3c8d9bc54b114a1be9bf99588f1594b402

## Re-review

Earlier review: b5f15f4dce7f4a402946a2305146a5bfb7a92b2e

An earlier review of this remit judged this change at b5f15f4dce7f. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.

### Earlier problems

none

### Changes since the earlier review

````
diff --git a/StoragePolicySim/HotWater.lean b/StoragePolicySim/HotWater.lean
index 77c655f..e808ee8 100644
--- a/StoragePolicySim/HotWater.lean
+++ b/StoragePolicySim/HotWater.lean
@@ -73,14 +73,17 @@ private def fullTolerance : Float := 1e-9
 private def isFull (cfg : TankConfig) (energyKwh : Float) : Bool :=
   (energyKwh - cfg.capacityKwh).abs ≤ fullTolerance
 
+/-- True when the tank was already full earlier in this day, as the state of the hour before says.
+Hour 0 starts a new day, so the tank is then not full before the hour. -/
+private def fullEarlierToday (state : TankState) (hour : Nat) : Bool :=
+  hour != 0 && state.fullToday
+
 /-- True when the thermostat is on for the rest of the hour. It stays on from the hour before. It
 cuts in when the level is less than the cut-in level. It also cuts in from the guard hour, when
-the tank was not full since hour 0 of the day. Hour 0 starts a new day, so the tank is then not
-full before the hour. -/
+the tank was not full since hour 0 of the day. -/
 private def thermostatOn (cfg : TankConfig) (state : TankState) (hour : Nat) (level : Float) :
     Bool :=
-  let fullBefore := hour != 0 && state.fullToday
-  state.heating || level < cfg.cutInKwh || (cfg.guardHour ≤ hour && !fullBefore)
+  state.heating || level < cfg.cutInKwh || (cfg.guardHour ≤ hour && !fullEarlierToday state hour)
 
 /-- The result of one hour. The order of the hour is this. The tank loses a share of its energy.
 The household draws: the tank serves the smaller of the draw and its energy, and the rest is the
@@ -104,7 +107,7 @@ def tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh dra
   let energyKwh := level + backstopKwh
   let full := isFull cfg energyKwh
   { lossKwh, servedKwh, unmetKwh, heatKwh, backstopKwh,
-    state := { energyKwh, heating := on && !full, fullToday := (hour != 0 && state.fullToday) || full } }
+    state := { energyKwh, heating := on && !full, fullToday := fullEarlierToday state hour || full } }
 
 /-! ## Draw profile -/
````

# Remit: specification

Default: no

You judge if the code does what the spec says. You do not see the checks.

- The code meets the acceptance lines of each requirement. For a requirement marked
  `(retire)`, the change removes the code that served the requirement instead.
- The code does nothing that the spec did not ask for.
- Only the files in "Files" changed. In a file that "Files" lists with parts, only those
  parts changed. The change stays in its one scope. A job change must not edit the code of
  a capability.
- No old wording survives. The title and the summary of the spec, the cross-references in
  its requirements, and a README in "Files" show the behaviour as it is now. They include
  what the change adds. Nothing that the change removes or changes still shows the old
  way. The README says how to run the checks, and names any seam that a user can set.
- In this project, the writing rules (`DES-writing-style`, in the packet) are a guideline,
  not a hard rule. A break of a writing rule, or a finding under "Writing check", goes under
  "Notes" with its line and rule. It is not a problem, and it does not fail the review.
- A text that is wrong or unclear about what the code does is still a problem. Examples are
  a wrong fact, a wrong number, and a sentence with two possible meanings.
- On a re-review, the writing check covers only the lines that changed since the earlier
  review.

## The change spec

````
# CH-0007 · Hot-water tank with a thermostat

Intent: IN-0008 · Scope: CAP-hotwater · Status: building · Ticket: none · Branch: pdlc/CH-0007-hotwater · Base: pdlc/CH-0006-forecast-fast

Tests-Locked: ae785cd

## Delivers

The library models an electric hot-water tank: heating limits, standby loss, the draw, a thermostat with a cut-in level, and the daily full heating against legionella. It also gives the hot-water draw profile that changes with the season, and the random factor of each day.

## Requirements

### CAP-hotwater.R1 · Standby loss and draw
- Given 8.0 kWh stored and no draw, when the hour runs, then the loss is 0.048 kWh and the tank holds 7.952 kWh.
- Given 8.0 kWh stored and a draw of 1.5 kWh, when the hour runs, then the loss is 0.048 kWh, the served draw is 1.5 kWh and the unmet draw is 0 kWh. The tank holds 6.452 kWh.
- Given 1.0 kWh stored and a draw of 2.0 kWh, when the hour runs, then the loss is 0.006 kWh, the served draw is 0.994 kWh and the unmet draw is 1.006 kWh.
- Given 0.0 kWh stored and a draw of 1.0 kWh, when the hour runs, then the loss is 0 kWh, the served draw is 0 kWh and the unmet draw is 1.0 kWh.
- Given 10.5 kWh stored and no draw, when the hour runs, then the loss is 0.063 kWh.
- Given a tank with no loss and 5.0 kWh stored, when an hour with no draw runs, then the tank holds 5.0 kWh.

### CAP-hotwater.R2 · Heating limits
- Given 5.0 kWh stored and a request of 2.0 kWh, when the hour runs, then the heating is 2.0 kWh and the tank holds 6.97 kWh.
- Given 5.0 kWh stored and a request of 5.0 kWh, when the hour runs, then the heating is 3.0 kWh and the tank holds 7.97 kWh.
- Given 9.0 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 1.554 kWh and the tank holds 10.5 kWh.
- Given 10.5 kWh stored and a request of 3.0 kWh, when the hour runs, then the heating is 0.063 kWh and the tank holds 10.5 kWh.
- Given 5.0 kWh stored and a request of 0 kWh, when the hour runs, then the heating is 0 kWh.
- Given 2.0 kWh stored, a draw of 2.5 kWh and a request of 3.0 kWh, when the hour runs, then the served draw is 1.988 kWh and the unmet draw is 0.512 kWh. The heating is 3.0 kWh and the tank holds 3.0 kWh.
- Given a tank with a capacity of 0 kWh, a draw of 1.0 kWh and a request of 3.0 kWh, when the hour runs, then the unmet draw is 1.0 kWh, the heating is 0 kWh and the tank holds 0 kWh.

### CAP-hotwater.R3 · Thermostat
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
- Given latitude 45, when the draw of each hour of days 0 to 364 is added, then the sum is 2190.0 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the 24 hours of day 100 are added, then the sum is 6.0 × (1 + 0.15 × cos(2π × 85 / 365)) kWh. The tolerance is 0.000001 kWh.
- Given latitude 45, when the days 15 and 197 are compared, then the draw of day 15 is 1.34 to 1.37 times the draw of day 197.
- Given latitude -41, when the days 15 and 197 are compared, then the draw of day 197 is 1.34 to 1.37 times the draw of day 15.
- Given latitude 45, when the hours of day 100 are compared, then hour 7 draws more than hour 3, and hour 19 draws more than hour 13.
- Given a daily energy of 0.0 kWh, when each hour of day 100 is read, then each draw is 0 kWh.

### CAP-hotwater.R5 · Daily full heating
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
- Given a spread of 0, when the factors of days 0 to 364 are read, then each is 1.0. The tolerance is 0.000000000001.
- Given seed 7 and a spread of 0.25, when the factors of days 0 to 4999 are read, then each is more than 0. Their mean is from 0.98 to 1.02, and their standard deviation is from 0.23 to 0.27.
- Given seed 7 and a spread of 0.5, when the factors of days 0 to 4999 are read, then their mean is from 0.97 to 1.03, and their standard deviation is from 0.48 to 0.58.
- Given seed 7 and a spread of 0.25, when the factor of the same day is read two times, then the two factors are the same.
- Given the seeds 7 and 8 and a spread of 0.25, when the factors of days 0 to 364 are compared, then at least 300 days have a different factor.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

- `TankConfig` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `capacityKwh`, `elementKw`, `lossPerHour` (the share of the stored energy that the tank loses in one hour), `cutInKwh` (the level below which the thermostat cuts in) and `floorKwh` (the level below which the tank counts as cold) are each a `Float`. The field `guardHour : Nat` is the hour from which the tank must heat to full.
  - errors: none
- `defaultTank : TankConfig` · constant · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a tank of 10.5 kWh with a 3.0 kW element, a loss of 0.006 each hour, a cut-in of 5.25 kWh, a floor of 2.1 kWh, and a guard hour of 20
  - errors: none
- `TankState` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields are `energyKwh : Float` (the energy that the tank holds), `heating : Bool` (the thermostat is on), and `fullToday : Bool` (the tank has been full since hour 0 of the day).
  - errors: none
- `startState (cfg : TankConfig) : TankState` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank
  - out: the state of a full tank, with the thermostat off and `fullToday` true
  - errors: none
- `TankStep` · type · `StoragePolicySim/HotWater.lean`
  - in: not applicable
  - out: a structure with `Repr` and `Inhabited`. The fields `lossKwh`, `servedKwh`, `unmetKwh`, `heatKwh` (the heating that the tank took for the policy) and `backstopKwh` are each a `Float` in kWh. The field `state : TankState` is the state after the hour.
  - errors: none
- `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep` · function · `StoragePolicySim/HotWater.lean`
  - in: a tank, its state, the hour of the day from 0 to 23, the heating that a policy asks for, and the hot water that the household draws in the hour
  - out: the result of the hour
  - errors: none
- `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: the hot-water energy of a day before the season, the latitude in degrees, the day of the year from 0, and the hour of the day from 0 to 23
  - out: the hot-water energy that the household draws in the hour, in kWh
  - errors: none
- `drawFactor (seed day : Nat) (cv : Float) : Float` · function · `StoragePolicySim/HotWater.lean`
  - in: a seed, the day of the run from 0, and the spread of the draw (the coefficient of variation)
  - out: the factor that scales the draw of that day. It is more than 0.
  - errors: none

### Test seams
- `drawSeed` · seam: randomness · `StoragePolicySim/HotWater.lean`
  - in: the `seed` argument of `drawFactor`. The same seed gives the same factors.
  - errors: none

## Files

- `StoragePolicySim/HotWater.lean`

## Check files

- `tests/CAP-hotwater.lean`

## Steps

### Step 1 · Standby loss and draw · [x]

- Requirement: CAP-hotwater.R1
- Check: the checks named `CAP-hotwater.R1 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 2 · Heating limits · [x]

- Requirement: CAP-hotwater.R2
- Check: the checks named `CAP-hotwater.R2 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 3 · Thermostat · [x]

- Requirement: CAP-hotwater.R3
- Check: the checks named `CAP-hotwater.R3 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 4 · Hot-water draw profile · [x]

- Requirement: CAP-hotwater.R4
- Check: the checks named `CAP-hotwater.R4 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 5 · Daily full heating · [x]

- Requirement: CAP-hotwater.R5
- Check: the checks named `CAP-hotwater.R5 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

### Step 6 · Daily draw factor · [x]

- Requirement: CAP-hotwater.R6
- Check: the checks named `CAP-hotwater.R6 …` in `tests/CAP-hotwater.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned second. It needs no other change of IN-0008 (hot-water policy simulation).
- Build: the 73 checks of `tests/CAP-hotwater.lean` pass, with the earlier component checks and the acceptance files of IN-0001 and IN-0002. The three usage checks of IN-0001 fail until CH-0011, as expected. No check changed since the lock.
````

## The spec it covers: title and summary

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
````

## The requirements, in full

### CAP-hotwater.R1 · Standby loss and draw

Status: built · Intents: IN-0008

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

Status: built · Intents: IN-0008

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

Status: built · Intents: IN-0008

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

Status: built · Intents: IN-0008

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

Status: built · Intents: IN-0008

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

Status: built · Intents: IN-0008

A household draws more hot water on some days, and less on others. The factor of a day is
`exp(cv × z - cv × cv / 2)`, where `cv` is the spread of the draw and `z` is a random number
from a normal curve (assumed). The number `z` depends only on the seed and the day. Thus, the
mean of the factor is 1, and a spread of 0 gives the factor 1.

- Given a spread of 0, when the factors of days 0 to 364 are read, then each is 1.0. The tolerance is 0.000000000001.
- Given seed 7 and a spread of 0.25, when the factors of days 0 to 4999 are read, then each is more than 0. Their mean is from 0.98 to 1.02, and their standard deviation is from 0.23 to 0.27.
- Given seed 7 and a spread of 0.5, when the factors of days 0 to 4999 are read, then their mean is from 0.97 to 1.03, and their standard deviation is from 0.48 to 0.58.
- Given seed 7 and a spread of 0.25, when the factor of the same day is read two times, then the two factors are the same.
- Given the seeds 7 and 8 and a spread of 0.25, when the factors of days 0 to 364 are compared, then at least 300 days have a different factor.

## Specs it relies on

### DES-errors

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

### DES-writing-style

````
# DES-writing-style · How pdlc writes

Status: agreed · Default: no · Ask at init: yes

In this project, these rules are a guideline, not a hard rule, for now. A review notes a
break of a rule, but the break does not fail the review. The user decided this on
2026-11-01, and https://github.com/ptetau/pskills/issues/24 tracks the rules in pdlc.

## Rule

This rule is a copy of `WRITING-GUIDELINES.md` from the pskills repository.

These guidelines apply to all writing in this repository. They also apply to all text that
an agent writes when it uses the skills in this repository. They have four parts:

1. Part 1 gives the rules of ASD-STE100 Simplified Technical English (STE) in short form.
2. Part 2 gives two more rules: the local-references rule and the described-IDs rule.
3. Part 3 tells you how to apply the rules to each type of text.
4. Part 4 tells you how to examine your text against the rules.

### Where these guidelines apply

Use these guidelines for all of these types of text:

- The replies that an agent writes to the user in a conversation.
- Skills: the `SKILL.md` file, its reference files, and its templates.
- Agent definitions, system prompts, and the prompts that an agent writes for other agents.
- The documents that a skill or an agent writes: specs, designs, plans, reports, and web
  pages.
- Commit messages, pull request text, and code comments.

These items are not prose. Do not change them to obey the rules:

- Code, commands, file paths, and identifiers.
- Error codes, field names, and values.
- Header fields, for example `Intent:`, `Scope:`, `Status:`, `Branch:`, and `Base:`. A
  script reads each value. Thus, a header field holds only the bare value, with no name
  and no backticks. Write `Intent: IN-0001`, not `Intent: IN-0001 (poll-input-errors)`.
- Quoted text. For example, the words of a user, or the trigger phrases in the description
  of a skill.
- The names of products, organisations, and published works.

### Part 1: STE rules

STE is a controlled language for technical text. The standard has 53 rules in nine
sections, and a dictionary of approved words. This part gives the rules in short form,
with the rule numbers of the standard. This repository does not contain the dictionary.
Part 4 tells you how to get the dictionary and how to use it.

#### Words (STE section 1)

- **1.1** Use approved words, technical nouns, and technical verbs.
- **1.2 to 1.4** Use an approved word only as its approved part of speech. Use the word
  only with its approved meaning and in its approved forms. For example, "check" is
  approved as a noun. As a verb, write "make sure that".
- **1.5, 1.6, 1.8 to 1.10** Technical nouns are the names of items in your subject.
  Examples in software are "commit", "branch", "file", "schema", and "pull request". Use
  the terms that your project uses. Select short terms. Do not use slang or jargon.
- **1.7** Do not use a technical noun as a verb. For example, do not write "action the
  ticket". Write "close the ticket".
- **1.11** Use one technical noun for one item. Do not use a different noun for the same
  item in a different part of the text.
- **1.12, 1.13** Technical verbs are the actions in your subject. In software, "commit",
  "merge", "deploy", "parse", and "click" are technical verbs. Do not use a technical verb
  as a noun. Write "merge the branch", not "do a merge of the branch".
- **1.14** Use New Zealand English spelling, for example "behaviour", "colour", and
  "organise". STE uses American English unless your own rules give a different standard.
  These guidelines give New Zealand English. Do not change the spelling of code, field
  names, or quoted text.

#### Multi-word nouns (STE section 2)

- **2.1** Do not write a multi-word noun of more than three words. For example, do not
  write "test result cache file path". Write "the path of the cache file for test
  results".
- **2.2** If a technical noun has more than three words, write it in full one time. Then
  use a shorter form, or join the words with hyphens.

#### Verbs (STE section 3)

- **3.1, 3.2** Use only these verb forms:
  - The infinitive: "to run".
  - The imperative: "Run the tests."
  - The simple present, the simple past, and the simple future: "runs", "ran", "will run".
  - The past participle as an adjective: "the merged branch".
- **3.3** Use the past participle as an adjective, for example "the merged branch".
- **3.4** Do not use auxiliary verbs to make complex verb constructions. For example, do
  not write "the file should have been updated". Write "update the file".
- **3.5** Use the "-ing" form of a verb only in a technical noun, for example "load
  balancing". Do not write "When running the tests, read the log". Write "When you run
  the tests, read the log".
- **3.6** Use the active voice. In descriptive text, you can use the passive voice only
  when you do not know who or what does the action.
- **Modal verbs (3.2, 3.4).** STE has "must" and "can". It does not have "should" or "may".
  Keep the strength of the original text:
  - A rule that always holds: write "must" or "must not".
  - Advice or a default: write "Try to …" or "Usually, …". Do not write "must".
  - A permission: write "is permitted to …". Write "can" for an ability.
  - The word "never": write "Do not …".
- **3.7** Use a verb to show an action, not a noun. Write "install the package", not "do
  the installation of the package".

#### Sentences (STE section 4)

- **4.1** Write short and clear sentences. Give one topic in each sentence. Give accurate
  facts, not abstract statements. For example, do not write "Large inputs change the run
  time". Write "When the input has more than 1,000 rows, the run time increases".
- **4.2** Do not omit words to make a sentence shorter. Do not omit articles, verbs, or
  subjects. Do not use contractions. Write "do not", not "don't".
- **4.3** Use a vertical list for complex text.
- **4.4** Use connecting words to connect related sentences, for example "and", "but",
  "then", "thus", and "as a result".
- **4.5** When applicable, put "the", "a", "an", "this", or "these" before a noun.

#### Instructions (STE section 5)

STE calls this type of text a procedure.

- **5.1** Write a maximum of 20 words in each instruction.
- **5.2** Write only one instruction in each sentence, unless the actions occur at the
  same time.
- **5.3** Write instructions in the imperative: "Run the tests."
- **5.4** If the reader must know a condition first, start with the condition. Put a comma
  after the condition: "If the tests fail, stop."
- **5.5** Use a note only to give information, not to give an instruction.

#### Descriptive text (STE section 6)

Descriptive text gives information, not instructions. Do not use the imperative in
descriptive text.

- **6.1** Give information gradually. Give the primary point first, then the details.
- **6.2** Use key words and headings to show the structure of the text.
- **6.3** Write a maximum of 25 words in each descriptive sentence.
- **6.4 to 6.6** Use paragraphs to show related information. Give each paragraph only one
  topic. Write a maximum of six sentences in each paragraph.

#### Safety instructions (STE section 7)

In software, a safety instruction tells the reader about an action that can cause loss of
data or other damage. Examples are a force push, a deleted table, and a message to other
persons.

- **7.1** Start with a word that shows the level of risk. Write "Warning" for a risk to
  persons. Write "Caution" for a risk to data or equipment.
- **7.2** Then give a clear command or condition.
- **7.3** Then give the risk or the possible result.

For example: "Caution: Do not force push to a shared branch. A force push can erase the
commits of other persons."

#### Punctuation and word count (STE section 8)

- **8.1** Do not use the semicolon. Write two sentences.
- **8.2** Use a hyphen to join words that are directly related, for example "read-only".
- **8.3** Use parentheses for references, identifiers, abbreviations, short explanations,
  and alternatives.
- **8.4** In a vertical list, a colon ends a sentence for the word count.
- **8.5 to 8.7** For the word count, count each of these items as one word:
  - Text in parentheses.
  - A number, or a number with its unit.
  - An abbreviation or an identifier.
  - Quoted text.
  - A title or a heading.
  - A proper noun.
  - A hyphenated word.

#### Writing practices (STE section 9)

- **9.1** If you cannot replace a word with an approved word, write the sentence again
  with a different structure.
- **9.2** Use each word correctly.
- **9.3** Do not use phrasal verbs. For example, write "prepare" or "configure", not "set
  up". Write "find", not "find out".
- **9.4** Use the same terms and the same style in all of the text.

#### General recommendations (STE)

- **GR-1** Write "that" after verbs such as "make sure", "show", and "recommend". For
  example: "Make sure that the tests pass."
- **GR-2** When you use "with", read the sentence again. Make sure that the sentence has
  only one meaning.
- **GR-3, GR-4** If a pronoun can refer to more than one noun, write the noun. The
  local-references rule in Part 2 makes this rule stricter.
- **GR-6** Do not use Latin abbreviations. Write "for example", not "e.g.". Write "that
  is", not "i.e.". Do not write "etc.".
- **GR-7** Use gender-neutral language. Use "they" for a person whose pronouns you do not
  know.
- **GR-8** Use the possessive form, for example "the user's file", only when you are sure
  that it is correct.

### Part 2: Two more rules

These two rules apply together with the STE rules.

#### The local-references rule

The reader must not look back far to find what a word refers to.

- A pronoun ("it", "they", "this", "that", "these", "those") must refer to a noun in the
  same paragraph. A short noun, for example "the file" or "the change", must also refer
  to a noun in the same paragraph.
- Only one noun in that paragraph can match the reference. If two nouns can match, write
  the full noun.
- At the start of a paragraph, a list item, a table cell, or a reply, write the full noun.
  Do not use "It", "This", or "They" to refer to an earlier paragraph.
- A heading does not give a noun to the text below the heading. Under the heading
  "OutboxAccess", do not start with "It stores". Write "OutboxAccess stores".
- In a conversation, each reply must make sense alone. Do not write "the PR" or "the
  second option" to refer to an earlier reply. Write the name or the full description.

For example, do not write: "The run found a problem in the template and in the checker.
It is now correct." Write: "The run found a problem in the template and in the checker. I
corrected the template."

#### The described-IDs rule

An ID is a short code that names an item, for example "B2", "R3", "V1", "UC2", "PR #6",
"task #4", or a commit hash. An ID without a description makes the reader look back.

- Each time that you write an ID, write a short description of the item in the same
  sentence. For example: "B2 (cache the results)".
- When the reader must select an alternative, give each alternative its ID and its
  description in the question. Do not ask "B1, B2, or B3?".
- In a table, a row that gives the ID and the description is sufficient for that row.
- A header field, for example `Intent: IN-0001`, holds only the ID. Do not add a
  description to the ID there.
- Make each description short and simple: two to eight words.
- If the ID is not necessary for the reader, do not use the ID. Use the description only.

For example, do not write: "Do you want B1 or B3?" Write: "Do you want B1 (keep the
cache) or B3 (remove the cache)?"

### Part 3: How to apply the rules

#### Replies to the user

- Give the answer or the result first. Then give the details.
- Use plain words, and give the context that the reader must have.
- Use short sentences. Use a list for three or more items. Do not write a paragraph when
  sentences in a list are sufficient.
- Write only about the topic. Do not add text that does not relate to the topic.
- Make each reply clear alone. Obey the local-references rule.
- When you ask a question with alternatives, obey the described-IDs rule.

#### Skills, agent definitions, and prompts

- If a skill gives an exact output format, the format has priority over these
  guidelines. For example, a skill can tell an agent to write one sentence for each
  option. Then the agent writes one sentence, also when the sentence has two topics.
- Write each step in the imperative. Write one instruction in each sentence.
- Put the condition first: "If the suite exists, load the suite."
- Give numbers to the steps of a procedure.
- Write the purpose of a skill, and other descriptive text, with the descriptive rules.
- In the `description` of a skill, keep the name and the trigger phrases of the skill.
  Do not change these quoted phrases. Write the other text of the description with the
  rules.
- A prompt for a different agent must make sense alone, because that agent does not see
  your conversation.

#### Documents and artifacts

- Start each section with its primary point.
- Use headings as key words.
- Give each technical noun that a reader possibly does not know in a "Words used here"
  list. Use one line for each word.
- Use a table to compare items. Use a list for steps and alternatives.

#### Commit messages and pull requests

- Write the subject line of a commit in the imperative, for example "Add the linter".
- Write the body as descriptive text.

### Part 4: Examine your text

1. Run the linter: `python check_writing.py FILE`. The linter is in the `scripts` folder of
   the `improve-writing` skill. The linter finds the problems that a script can measure.
2. To examine words against the STE dictionary, get the standard. The standard is free
   from <https://www.asd-ste100.org>. Then give the linter your copy:
   `--dictionary PATH`. The path can be the PDF file or a text file of the PDF.
3. Read the text again for the rules that a script cannot measure. Examples are one topic
   in each sentence, the local-references rule, and accurate facts.

The `/improve-writing` skill does these three steps and writes the text again.

### Source

- ASD-STE100 Simplified Technical English, Issue 9, 2025-01-15, by ASD (the Aerospace,
  Security and Defence Industries Association of Europe). Part 1 gives the rules of the
  standard in short form, with the rule numbers of the standard.
- The standard is free from <https://www.asd-ste100.org>. ASD does not let other persons
  distribute the standard. Thus, this file does not contain the text of the standard or
  its dictionary.
- ASD-STE100 is a registered trademark of ASD.
````

### DES-pdlc-check-tagging

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

### DES-lean-checks

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

## The code

### Diff against pdlc/CH-0006-forecast-fast

````
diff --git a/StoragePolicySim/HotWater.lean b/StoragePolicySim/HotWater.lean
new file mode 100644
index 0000000..e808ee8
--- /dev/null
+++ b/StoragePolicySim/HotWater.lean
@@ -0,0 +1,175 @@
+/-
+The hot-water tank of a household. The tank holds thermal energy in kWh. Each hour it loses a
+share of its energy, serves the draw of the household, and takes the heating of a policy. A
+thermostat with a cut-in level adds backstop heating, and the guard hour makes the tank heat to
+full once each day, against legionella. The module also gives the draw of each hour, which
+changes with the season, and the random factor of each day. CAP-hotwater (hot-water tank with a
+thermostat) gives the rules.
+-/
+namespace StoragePolicySim
+
+/-! ## Tank -/
+
+/-- The limits and the levels of a tank. -/
+structure TankConfig where
+  /-- The most energy that the tank holds, in kWh. -/
+  capacityKwh : Float
+  /-- The power of the element, in kW. -/
+  elementKw : Float
+  /-- The share of the stored energy that the tank loses in one hour. -/
+  lossPerHour : Float
+  /-- The level below which the thermostat cuts in, in kWh. -/
+  cutInKwh : Float
+  /-- The level below which the tank counts as cold, in kWh. -/
+  floorKwh : Float
+  /-- The hour of the day from which the tank must heat to full, when it was not full today. -/
+  guardHour : Nat
+  deriving Repr, Inhabited
+
+/-- A tank of 10.5 kWh with a 3.0 kW element, a loss of 0.6% each hour, a cut-in of half the
+capacity, a floor of a fifth of the capacity, and a guard hour of 20. -/
+def defaultTank : TankConfig where
+  capacityKwh := 10.5
+  elementKw := 3.0
+  lossPerHour := 0.006
+  cutInKwh := 5.25
+  floorKwh := 2.1
+  guardHour := 20
+
+/-- The state of a tank at the end of an hour. -/
+structure TankState where
+  /-- The energy that the tank holds, in kWh. -/
+  energyKwh : Float
+  /-- True when the thermostat is on. -/
+  heating : Bool
+  /-- True when the tank has been full since hour 0 of the day. -/
+  fullToday : Bool
+  deriving Repr, Inhabited
+
+/-- The state of a full tank, with the thermostat off and `fullToday` true. -/
+def startState (cfg : TankConfig) : TankState :=
+  { energyKwh := cfg.capacityKwh, heating := false, fullToday := true }
+
+/-- The result of one hour. Each energy is in kWh. -/
+structure TankStep where
+  /-- The energy that the tank lost. -/
+  lossKwh : Float
+  /-- The part of the draw that the tank served. -/
+  servedKwh : Float
+  /-- The part of the draw that the tank could not serve. -/
+  unmetKwh : Float
+  /-- The heating that the tank took for the policy. -/
+  heatKwh : Float
+  /-- The heating that the thermostat added. -/
+  backstopKwh : Float
+  /-- The state after the hour. -/
+  state : TankState
+  deriving Repr, Inhabited
+
+/-- A tank is full when it holds its capacity, within this many kWh. -/
+private def fullTolerance : Float := 1e-9
+
+/-- True when the tank holds its capacity, within `fullTolerance`. -/
+private def isFull (cfg : TankConfig) (energyKwh : Float) : Bool :=
+  (energyKwh - cfg.capacityKwh).abs ≤ fullTolerance
+
+/-- True when the tank was already full earlier in this day, as the state of the hour before says.
+Hour 0 starts a new day, so the tank is then not full before the hour. -/
+private def fullEarlierToday (state : TankState) (hour : Nat) : Bool :=
+  hour != 0 && state.fullToday
+
+/-- True when the thermostat is on for the rest of the hour. It stays on from the hour before. It
+cuts in when the level is less than the cut-in level. It also cuts in from the guard hour, when
+the tank was not full since hour 0 of the day. -/
+private def thermostatOn (cfg : TankConfig) (state : TankState) (hour : Nat) (level : Float) :
+    Bool :=
+  state.heating || level < cfg.cutInKwh || (cfg.guardHour ≤ hour && !fullEarlierToday state hour)
+
+/-- The result of one hour. The order of the hour is this. The tank loses a share of its energy.
+The household draws: the tank serves the smaller of the draw and its energy, and the rest is the
+unmet draw. The element heats by the request, but never more than the element power for one
+hour, and never more than the room that is left. Then the thermostat decides. When it is on, the
+backstop heating is the element power that the request left, and never more than the room that is
+left. The thermostat stays on until the tank is full. `fullToday` starts again at hour 0, and it
+becomes true in the hour in which the tank is full. -/
+def tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) :
+    TankStep :=
+  let lossKwh := cfg.lossPerHour * state.energyKwh
+  let afterLoss := state.energyKwh - lossKwh
+  let servedKwh := if drawKwh < afterLoss then drawKwh else afterLoss
+  let unmetKwh := drawKwh - servedKwh
+  let afterDraw := afterLoss - servedKwh
+  let heatKwh := max 0.0 (min requestKwh (min cfg.elementKw (cfg.capacityKwh - afterDraw)))
+  let level := afterDraw + heatKwh
+  let on := thermostatOn cfg state hour level
+  let backstopKwh :=
+    if on then max 0.0 (min (cfg.elementKw - heatKwh) (cfg.capacityKwh - level)) else 0.0
+  let energyKwh := level + backstopKwh
+  let full := isFull cfg energyKwh
+  { lossKwh, servedKwh, unmetKwh, heatKwh, backstopKwh,
+    state := { energyKwh, heating := on && !full, fullToday := fullEarlierToday state hour || full } }
+
+/-! ## Draw profile -/
+
+/-- The share of the hot-water draw of a day in each hour, in parts of 1000. The profile has a
+morning peak at 07:00 and an evening peak at 19:00. The parts add up to 1000. -/
+private def profile : Array Float :=
+  #[5, 3, 2, 2, 5, 20, 70, 110, 90, 50, 35, 30,
+    30, 25, 25, 25, 30, 50, 80, 110, 90, 60, 35, 18]
+
+/-- The size of the seasonal swing: the draw of the coldest day is this share more than the mean
+of the year, and the draw of the warmest day is this share less. -/
+private def seasonSwing : Float := 0.15
+
+/-- The days in a year. -/
+private def yearDays : Float := 365.0
+
+/-- Two times pi. -/
+private def twoPi : Float := 6.283185307179586
+
+/-- The day of the year with the most hot-water draw. It is 15 (mid-winter) at latitude 0 or
+more, and 197 at a negative latitude. -/
+private def peakDay (latitude : Float) : Nat := if latitude ≥ 0.0 then 15 else 197
+
+/-- The seasonal factor that scales the hot-water energy of a day. The cold inlet is colder in
+winter. -/
+private def seasonOf (latitude : Float) (dayOfYear : Nat) : Float :=
+  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
+  1.0 + seasonSwing * Float.cos (twoPi * offset / yearDays)
+
+/-- The hot-water energy that the household draws in one hour, in kWh. The `dailyKwh` is the
+energy of a day before the season. The hours of a day share it by a fixed profile, and a seasonal
+factor scales it. -/
+def drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float :=
+  dailyKwh * seasonOf latitude dayOfYear * profile[hour]! / 1000.0
+
+/-! ## Daily draw factor -/
+
+/-- The SplitMix64 steps: a well-mixed number from a number. -/
+private def mix (x : UInt64) : UInt64 :=
+  let s := x + 0x9E3779B97F4A7C15
+  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
+  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
+  z ^^^ (z >>> 31)
+
+/-- A number above 0 and up to 1 from the top 53 bits of a number. -/
+private def unitFloat (x : UInt64) : Float :=
+  ((x >>> 11).toFloat + 1) / 9007199254740992.0
+
+/-- A number from a normal curve (Box-Muller). It depends only on the key. -/
+private def normalOfKey (key : UInt64) : Float :=
+  let radius := Float.sqrt (-2.0 * Float.log (unitFloat (mix key)))
+  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))
+
+/-- The number that tells the draws of the hot-water factor apart from other random draws. -/
+private def drawStream : UInt64 := 0x40A7
+
+/-- The factor that scales the hot-water draw of one day. It is `exp(cv × z - cv × cv / 2)`,
+where `cv` is the spread of the draw and `z` is a number from a normal curve. The number `z`
+depends only on the seed and the day, so the same arguments give the same factor. The mean of the
+factor is 1, and a spread of 0 gives the factor 1. The factor is more than 0. -/
+def drawFactor (seed day : Nat) (cv : Float) : Float :=
+  let z := normalOfKey (mix (mix (mix seed.toUInt64 + drawStream) + day.toUInt64))
+  Float.exp (cv * z - cv * cv / 2.0)
+
+end StoragePolicySim
````

### StoragePolicySim/HotWater.lean

````
/-
The hot-water tank of a household. The tank holds thermal energy in kWh. Each hour it loses a
share of its energy, serves the draw of the household, and takes the heating of a policy. A
thermostat with a cut-in level adds backstop heating, and the guard hour makes the tank heat to
full once each day, against legionella. The module also gives the draw of each hour, which
changes with the season, and the random factor of each day. CAP-hotwater (hot-water tank with a
thermostat) gives the rules.
-/
namespace StoragePolicySim

/-! ## Tank -/

/-- The limits and the levels of a tank. -/
structure TankConfig where
  /-- The most energy that the tank holds, in kWh. -/
  capacityKwh : Float
  /-- The power of the element, in kW. -/
  elementKw : Float
  /-- The share of the stored energy that the tank loses in one hour. -/
  lossPerHour : Float
  /-- The level below which the thermostat cuts in, in kWh. -/
  cutInKwh : Float
  /-- The level below which the tank counts as cold, in kWh. -/
  floorKwh : Float
  /-- The hour of the day from which the tank must heat to full, when it was not full today. -/
  guardHour : Nat
  deriving Repr, Inhabited

/-- A tank of 10.5 kWh with a 3.0 kW element, a loss of 0.6% each hour, a cut-in of half the
capacity, a floor of a fifth of the capacity, and a guard hour of 20. -/
def defaultTank : TankConfig where
  capacityKwh := 10.5
  elementKw := 3.0
  lossPerHour := 0.006
  cutInKwh := 5.25
  floorKwh := 2.1
  guardHour := 20

/-- The state of a tank at the end of an hour. -/
structure TankState where
  /-- The energy that the tank holds, in kWh. -/
  energyKwh : Float
  /-- True when the thermostat is on. -/
  heating : Bool
  /-- True when the tank has been full since hour 0 of the day. -/
  fullToday : Bool
  deriving Repr, Inhabited

/-- The state of a full tank, with the thermostat off and `fullToday` true. -/
def startState (cfg : TankConfig) : TankState :=
  { energyKwh := cfg.capacityKwh, heating := false, fullToday := true }

/-- The result of one hour. Each energy is in kWh. -/
structure TankStep where
  /-- The energy that the tank lost. -/
  lossKwh : Float
  /-- The part of the draw that the tank served. -/
  servedKwh : Float
  /-- The part of the draw that the tank could not serve. -/
  unmetKwh : Float
  /-- The heating that the tank took for the policy. -/
  heatKwh : Float
  /-- The heating that the thermostat added. -/
  backstopKwh : Float
  /-- The state after the hour. -/
  state : TankState
  deriving Repr, Inhabited

/-- A tank is full when it holds its capacity, within this many kWh. -/
private def fullTolerance : Float := 1e-9

/-- True when the tank holds its capacity, within `fullTolerance`. -/
private def isFull (cfg : TankConfig) (energyKwh : Float) : Bool :=
  (energyKwh - cfg.capacityKwh).abs ≤ fullTolerance

/-- True when the tank was already full earlier in this day, as the state of the hour before says.
Hour 0 starts a new day, so the tank is then not full before the hour. -/
private def fullEarlierToday (state : TankState) (hour : Nat) : Bool :=
  hour != 0 && state.fullToday

/-- True when the thermostat is on for the rest of the hour. It stays on from the hour before. It
cuts in when the level is less than the cut-in level. It also cuts in from the guard hour, when
the tank was not full since hour 0 of the day. -/
private def thermostatOn (cfg : TankConfig) (state : TankState) (hour : Nat) (level : Float) :
    Bool :=
  state.heating || level < cfg.cutInKwh || (cfg.guardHour ≤ hour && !fullEarlierToday state hour)

/-- The result of one hour. The order of the hour is this. The tank loses a share of its energy.
The household draws: the tank serves the smaller of the draw and its energy, and the rest is the
unmet draw. The element heats by the request, but never more than the element power for one
hour, and never more than the room that is left. Then the thermostat decides. When it is on, the
backstop heating is the element power that the request left, and never more than the room that is
left. The thermostat stays on until the tank is full. `fullToday` starts again at hour 0, and it
becomes true in the hour in which the tank is full. -/
def tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) :
    TankStep :=
  let lossKwh := cfg.lossPerHour * state.energyKwh
  let afterLoss := state.energyKwh - lossKwh
  let servedKwh := if drawKwh < afterLoss then drawKwh else afterLoss
  let unmetKwh := drawKwh - servedKwh
  let afterDraw := afterLoss - servedKwh
  let heatKwh := max 0.0 (min requestKwh (min cfg.elementKw (cfg.capacityKwh - afterDraw)))
  let level := afterDraw + heatKwh
  let on := thermostatOn cfg state hour level
  let backstopKwh :=
    if on then max 0.0 (min (cfg.elementKw - heatKwh) (cfg.capacityKwh - level)) else 0.0
  let energyKwh := level + backstopKwh
  let full := isFull cfg energyKwh
  { lossKwh, servedKwh, unmetKwh, heatKwh, backstopKwh,
    state := { energyKwh, heating := on && !full, fullToday := fullEarlierToday state hour || full } }

/-! ## Draw profile -/

/-- The share of the hot-water draw of a day in each hour, in parts of 1000. The profile has a
morning peak at 07:00 and an evening peak at 19:00. The parts add up to 1000. -/
private def profile : Array Float :=
  #[5, 3, 2, 2, 5, 20, 70, 110, 90, 50, 35, 30,
    30, 25, 25, 25, 30, 50, 80, 110, 90, 60, 35, 18]

/-- The size of the seasonal swing: the draw of the coldest day is this share more than the mean
of the year, and the draw of the warmest day is this share less. -/
private def seasonSwing : Float := 0.15

/-- The days in a year. -/
private def yearDays : Float := 365.0

/-- Two times pi. -/
private def twoPi : Float := 6.283185307179586

/-- The day of the year with the most hot-water draw. It is 15 (mid-winter) at latitude 0 or
more, and 197 at a negative latitude. -/
private def peakDay (latitude : Float) : Nat := if latitude ≥ 0.0 then 15 else 197

/-- The seasonal factor that scales the hot-water energy of a day. The cold inlet is colder in
winter. -/
private def seasonOf (latitude : Float) (dayOfYear : Nat) : Float :=
  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
  1.0 + seasonSwing * Float.cos (twoPi * offset / yearDays)

/-- The hot-water energy that the household draws in one hour, in kWh. The `dailyKwh` is the
energy of a day before the season. The hours of a day share it by a fixed profile, and a seasonal
factor scales it. -/
def drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float :=
  dailyKwh * seasonOf latitude dayOfYear * profile[hour]! / 1000.0

/-! ## Daily draw factor -/

/-- The SplitMix64 steps: a well-mixed number from a number. -/
private def mix (x : UInt64) : UInt64 :=
  let s := x + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  z ^^^ (z >>> 31)

/-- A number above 0 and up to 1 from the top 53 bits of a number. -/
private def unitFloat (x : UInt64) : Float :=
  ((x >>> 11).toFloat + 1) / 9007199254740992.0

/-- A number from a normal curve (Box-Muller). It depends only on the key. -/
private def normalOfKey (key : UInt64) : Float :=
  let radius := Float.sqrt (-2.0 * Float.log (unitFloat (mix key)))
  radius * Float.cos (twoPi * unitFloat (mix (key + 1)))

/-- The number that tells the draws of the hot-water factor apart from other random draws. -/
private def drawStream : UInt64 := 0x40A7

/-- The factor that scales the hot-water draw of one day. It is `exp(cv × z - cv × cv / 2)`,
where `cv` is the spread of the draw and `z` is a number from a normal curve. The number `z`
depends only on the seed and the day, so the same arguments give the same factor. The mean of the
factor is 1, and a spread of 0 gives the factor 1. The factor is more than 0. -/
def drawFactor (seed day : Nat) (cv : Float) : Float :=
  let z := normalOfKey (mix (mix (mix seed.toUInt64 + drawStream) + day.toUInt64))
  Float.exp (cv * z - cv * cv / 2.0)

end StoragePolicySim
````

## Writing check

`pdlc/bin/check_writing.py --since b5f15f4dce7f4a402946a2305146a5bfb7a92b2e` on pdlc/changes/CH-0007-hotwater/change.md, pdlc/specs/capabilities/CAP-hotwater.md:

````
No findings.
````

