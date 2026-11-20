# Interface

Status: draft

Stack: a Lean 4 library (`StoragePolicySim`, namespace `StoragePolicySim`) and the `sim` command (`.lake/build/bin/sim`). A test calls the library functions, or runs `sim` as a process and reads stdout, stderr and the exit code.

## Surface

The test writer sees only this file, not the code. Each structure derives `Repr` and `Inhabited`. A `Float` is in kWh unless its name ends in `Kw`. A test compares a `Float` with a tolerance.

### Existing surface (built, unchanged)

- `import StoragePolicySim.Scenario`: `Sky` (`sunny`, `cloudy`, `overcast`, with `Sky.factor`), `Site {latitude pvKw dailyLoadKwh flexKwh : Float}`, `Hour {day dayOfYear hour : Nat, sky : Sky, pvKwh baseLoadKwh flexKwh : Float}`, `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float`, `scenario (site : Site) (seed days : Nat) : Array Hour`. Exposes: the old flat solar model and the house load.
- `import StoragePolicySim.Strategy`: `Strategy` (`none`, `greedy`, `evening`, `shift`).
- `import StoragePolicySim.Simulation`: `Battery {capacityKwh powerKw : Float}`, `Flow {directKwh chargeKwh dischargeKwh exportKwh importKwh lossKwh socKwh : Float}`, `stepHour (battery : Battery) (socKwh : Float) (strategy : Strategy) (hour : Nat) (pvKwh loadKwh : Float) : Flow`. The battery keeps 0.95 of the energy in and gives 0.95 of the energy out.
- `import StoragePolicySim.HotWater`: `TankConfig {capacityKwh elementKw lossPerHour cutInKwh floorKwh : Float, guardHour : Nat}`, `defaultTank` (10.5, 3.0, 0.006, 5.25, 2.1, 20), `TankState {energyKwh : Float, heating fullToday : Bool}`, `startState (cfg : TankConfig) : TankState`, `TankStep {lossKwh servedKwh unmetKwh heatKwh backstopKwh : Float, state : TankState}`, `tankStep (cfg : TankConfig) (state : TankState) (hour : Nat) (requestKwh drawKwh : Float) : TankStep`, `drawKwh (dailyKwh latitude : Float) (dayOfYear hour : Nat) : Float`, `drawFactor (seed day : Nat) (cv : Float) : Float`. Exposes: Tank, TankState, Thermostat.
- `import StoragePolicySim.Forecast`: `Period {endMinute : Nat, estimateKw p10Kw p90Kw : Float}`, `forecastOf (hours : Array Hour) (site : Site) (seed : Nat) (errorScale : Float) (fetchHour : Nat) : Array Period`, `hourlyEnergy (periods : Array Period) (fetchHour : Nat) : Array Float` (48 values), `latestFetch (fetchesPerDay hour : Nat) : Nat`, `forecastJson`.

### New surface

- `import StoragePolicySim.Scenario`: `PanelArray {kw direction tilt : Float}` (direction in compass degrees that the array faces, 0 north, 90 east; tilt in degrees from flat). `arrayOutput (latitude : Float) (array : PanelArray) (dayOfYear hour : Nat) (sky : Sky) : Float`. Errors: none. Exposes: PanelArray. A flat array (tilt 0) gives `pvOutput` of a site with the same power.
- `import StoragePolicySim.Simulation`: `stepHourGated (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : Flow`. `Limits {inverterKw exportKw : Float}` (0 means no limit), `noLimits : Limits`, `LimitedFlow {flow : Flow, curtailedKwh : Float}`, `stepHourLimited (limits : Limits) (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : LimitedFlow`. Errors: none. Exposes: Battery, Limits, I3, I4. In a `LimitedFlow`, `chargeKwh` is the solar energy into the battery, outside the inverter limit, and `directKwh + dischargeKwh + exportKwh` is at most the inverter limit.
- `import StoragePolicySim.Policy`:
  - `Action {heatKwh : Array Float, allowCharge allowDischarge : Bool, flexKwh : Float}`: one heating request for each tank, the battery gate, and the flexible load to run in the hour.
  - `TankWindow {heatStart heatHours : Nat}`, `StaticParams {windows : Array TankWindow, dischargeFrom flexStart : Nat}`. Tank `i` uses window `i`, or the last window when there are fewer.
  - `PlanParams {targetKwh : Array Float, minSolarKwh : Float, dischargeFrom : Nat}`, `DynamicParams {lowKwh targetKwh : Array Float, dischargeFrom : Nat}`. Tank `i` uses value `i`. A missing target is the capacity of the tank, and a missing low level is half of it.
  - `Policy` with `static (p : StaticParams)`, `precomputed (p : PlanParams)`, `dynamic (p : DynamicParams)`, and `Policy.name : Policy → String`.
  - `defaultStatic` (one window from 10 for 4 hours, discharge from 17, flexible load from 18), `defaultPlan` (targets `#[10.5]`, minimum 0.5, discharge 17), `defaultDynamic` (low `#[5.25]`, targets `#[10.5]`, discharge 17).
  - `staticProfile (tanks : Array TankConfig) (params : StaticParams) (flexDayKwh : Float) : Array Action`: 24 actions. A tank asks for its own element power in its window. The flexible load runs in 3 equal parts from `flexStart`, in fewer and larger parts when the day ends first.
  - `planDay (tanks : Array TankConfig) (params : PlanParams) (forecastKwh tankKwh expectedDrawKwh : Array Float) (flexDayKwh : Float) : Array Action`: 24 actions, from the 24 forecast values of the day, and the energy and the expected draw of each tank.
  - `Observation {hour : Nat, tankKwh : Array Float, socKwh surplusKwh forecastRestKwh flexLeftKwh : Float, startsToday : Array Nat, askedLastHour : Array Bool}`, `dynamicAction (tanks : Array TankConfig) (params : DynamicParams) (obs : Observation) : Action`.
  - Errors: none. Exposes: Policy, Action, Observation, ElementSchedule.
- `import StoragePolicySim.HomeSim`:
  - `Home {site : Site, arrays : Array PanelArray, battery : Battery, limits : Limits, tanks : Array TankConfig, drawShares : Array Float, drawKwhPerDay drawCv : Float, fetchesPerDay : Nat, errorScale : Float}`. `site.pvKw` holds the sum of the array powers.
  - `homeNames : List String` (`generic`, `small`, `family`, `no-battery`, `mine`), `homeNamed (name : String) : Option Home`, `defaultHome : Home` (the home `generic`).
  - `TankHour {drawKwh askKwh heatKwh backstopKwh unmetKwh energyKwh : Float}`, `HomeHour {day hour : Nat, pvKwh houseLoadKwh flexKwh : Float, tanks : Array TankHour, allowCharge allowDischarge : Bool, flow : Flow, curtailedKwh : Float}`. `houseLoadKwh` is the base load plus the flexible load of the hour. The load of the battery step is `houseLoadKwh` plus the heating and the backstop of each tank.
  - `HomeTotals {pvKwh loadKwh importKwh exportKwh curtailedKwh batteryLossKwh tankLossKwh heatKwh backstopKwh drawKwh unmetKwh selfConsumption selfSufficiency : Float, minTankKwh finalTankKwh : Array Float, coldHours policyStarts : Nat}`, `HomeResult {hours : Array HomeHour, totals : HomeTotals}`.
  - `runHome (home : Home) (policy : Policy) (seed days : Nat) : HomeResult`.
  - `Evaluation {meanSelfConsumption worstSelfConsumption meanSelfSufficiency meanImportKwh meanExportKwh meanCurtailedKwh meanBackstopKwh totalUnmetKwh meanStartsPerDay : Float, seeds unmetSeeds coldHours : Nat}`, `evaluate (home : Home) (policy : Policy) (seed seeds days : Nat) : Evaluation`.
  - `Goal` with `selfConsumption` and `gridImport`, `TuneResult {best : StaticParams, evaluation : Evaluation, candidates safe : Nat}`, `tuneStatic (home : Home) (goal : Goal) (seed seeds days : Nat) : TuneResult`.
  - Errors: none. Exposes: Home, Run, HomeHour, Totals, Evaluation, TuneResult.
- `sim` (process `.lake/build/bin/sim`, run through `timeout 120`): `sim`, `sim help`, `sim --help`, `sim forecast [options]`, `sim policy`, `sim policy help`, `sim policy run|compare|robust|tune|plan [options]`. Output and options: R12 to R18, R19 to R21, R23 to R25 of the spec, and D13 to D15. Errors: one line `error: <CODE>: <detail>` on stderr, empty stdout, exit code 2.
  - Home options: `--home NAME`, `--lat`, `--pv` (replaces the arrays with one flat array), `--array KW:DIRECTION:TILT`, `--battery`, `--power`, `--load`, `--flex`, `--inverter`, `--export-limit`, `--tank` (the capacity of the first tank), `--element`, `--cut-in`, `--floor`, `--tank2 KWH:ELEMENT:SHARE`, `--draw`, `--draw-cv`, `--fetches`, `--forecast-error`, `--days`, `--seed`.
  - Policy options: `--policy`, `--heat-start`, `--heat-hours` (the window of each tank), `--discharge-from`, `--flex-start`, `--target`, `--min-solar`, `--low`. Other options: `--seeds`, `--goal`, `--day`, `--hour`, `--lon`.

The stubs fail with the not-implemented error of the stack: `panic! "not implemented"`. The message holds "not implemented". A stubbed command prints `error: not implemented` on stderr and exits with 3.

### How a test is written

- The tests of slice `Sn` are in `tests/slice/Sn.lean`. The file imports `tests.slice.Harness` and the library modules, and ends with `def main (args : List String) : IO UInt32 := Harness.run tests args`, where `tests : List Harness.Test`.
- `Harness.Test {name : String, run : IO (Option String)}`: `none` passes, and `some message` fails. A name is `test_001_Sn_Rn_<what>`, with letters, digits and `_` only.
- `Harness.near (a b tol : Float) : Bool`, `Harness.sim (args : List String) : IO Harness.Out` with `Out {code : UInt32, out err : String}`, `Harness.firstFail (checks : List (Bool × String)) : Option String`.
- A test of a changed requirement can also replace an older check: the older check files are `tests/*.lean` and `tests/acceptance/*.lean`.

`Status: draft` becomes `Status: approved` only after the user approves the surface, before the test writer runs.

## Security

The app reads only its command line, and writes only stdout and stderr. It opens no file and no network connection, and runs no other program. Input validation is the floor: each option value is parsed as a number in a fixed range (D15), or as a name from a fixed list, before use. An error line repeats the option and the value as typed, and nothing else. A large `--days` or `--seeds` is capped by its range, so a run cannot use unbounded memory.

## S1

- Uses: `stepHourGated`, `staticProfile`, `defaultStatic`, `runHome`, `defaultHome`, `sim`, `sim help`, `sim policy`, `sim policy run`
- Stubs: `StoragePolicySim/Simulation.lean`, `StoragePolicySim/Scenario.lean`, `StoragePolicySim/Policy.lean`, `StoragePolicySim/HomeSim.lean`, `StoragePolicySim/PolicyCommands.lean`, `Main.lean`
- Changed: R12

## S2

- Uses: `planDay`, `dynamicAction`, `defaultPlan`, `defaultDynamic`, `Policy.name`, `runHome`, `sim policy run`, `sim forecast`
- Stubs: `StoragePolicySim/Policy.lean`, `StoragePolicySim/PolicyCommands.lean`
- Changed: none

## S3

- Uses: `runHome`, `sim policy compare`
- Stubs: `StoragePolicySim/PolicyCommands.lean`
- Changed: none

## S4

- Uses: `evaluate`, `tuneStatic`, `sim policy robust`, `sim policy tune`
- Stubs: `StoragePolicySim/HomeSim.lean`, `StoragePolicySim/PolicyCommands.lean`
- Changed: none

## S5

- Uses: `sim policy run`, `sim policy compare`, `sim policy robust`, `sim policy tune`, `sim forecast`
- Stubs: `StoragePolicySim/PolicyCommands.lean`
- Changed: none

## S6

- Uses: `arrayOutput`, `stepHourLimited`, `runHome`, `sim policy run`
- Stubs: `StoragePolicySim/Scenario.lean`, `StoragePolicySim/Simulation.lean`
- Changed: none

## S7

- Uses: `homeNamed`, `homeNames`, `runHome`, `dynamicAction`, `sim policy run`
- Stubs: `StoragePolicySim/HomeSim.lean`
- Changed: none

## S8

- Uses: `runHome`, `staticProfile`, `planDay`, `dynamicAction`, `sim policy run`
- Stubs: `StoragePolicySim/Policy.lean`, `StoragePolicySim/HomeSim.lean`
- Changed: none

## S9

- Uses: `runHome`, `sim policy plan`
- Stubs: `StoragePolicySim/PolicyCommands.lean`
- Changed: none
