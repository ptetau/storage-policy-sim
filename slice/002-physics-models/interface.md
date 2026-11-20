# Interface

Status: draft

Stack: a Lean 4 library (`StoragePolicySim`, namespace `StoragePolicySim`) and the `sim` command, as in spec 001. A test calls the library functions, or runs `sim` as a process.

## Surface

The test writer sees only this file, not the code. Each structure derives `Repr` and `Inhabited`. A step is a quarter of an hour of a day, from 0 to 95. An energy is in kWh in a step, a power in kW, light in W/m², a temperature in °C. The surface of spec 001 stays (`Site`, `PanelArray`, `Battery`, `Limits`, `LimitedFlow`, `Flow`, `Home`, `homeNamed`, `defaultHome`, `Policy`, `defaultStatic`, `defaultPlan`, `defaultDynamic`, `TankConfig`, `TankHour`, `HomeHour`, `HomeTotals`, `HomeResult`, `runHome`): see `slice/001-hot-water-policies/interface.md`.

- `import StoragePolicySim.PhysWeather`:
  - `stepsPerDay : Nat` (96).
  - `haurwitzWm2 (cosZ : Float) : Float`: the clear-sky rule of D3 for a cosine.
  - `clearSkyWm2 (latitude : Float) (dayOfYear step : Nat) : Float`.
  - `dayClearness (latitude : Float) (seed days : Nat) : Array Float`: one value for each day. `clearness (latitude : Float) (seed days : Nat) : Array Float`: one value for each step, `96 × days` values, in order.
  - `diffuseShare (clearness : Float) : Float`.
  - `panelWm2 (latitude : Float) (array : PanelArray) (dayOfYear step : Nat) (clearness : Float) : Float`: the light on the panels of the array. A flat array is one with a tilt of 0.
  - `cellTempC (airC lightWm2 : Float) : Float`, `arrayKw (array : PanelArray) (lightWm2 airC : Float) : Float`.
  - `airTempC (latitude : Float) (dayOfYear step : Nat) (clearnessOfDay : Float) : Float`, `inletTempC (latitude : Float) (dayOfYear : Nat) : Float`.
  - Errors: none. Exposes: Sky, Step.
- `import StoragePolicySim.PhysTank`:
  - `kwhPerLitreK : Float` (0.001163).
  - `PhysTank {litres elementKw uaKwPerK cutInShare floorShare : Float, guardHour : Nat}`, `physTankOf (cfg : TankConfig) : PhysTank` (the litres and the loss from the capacity and the loss share of the config; the cut-in share and the floor share are its cut-in and floor divided by its capacity).
  - `PhysTankState {hotLitres : Float, heating fullToday : Bool}`, `physStart (t : PhysTank) : PhysTankState` (all hot, thermostat off, full today).
  - `tankEnergyKwh (state : PhysTankState) (inletC : Float) : Float`: the energy of the hot litres above the inlet temperature.
  - `PhysTankStep {lossKwh servedKwh unmetKwh heatKwh backstopKwh : Float, state : PhysTankState}`, `physTankStep (t : PhysTank) (state : PhysTankState) (step : Nat) (requestKwh tapLitres inletC : Float) : PhysTankStep`. The order in a step: the loss, the use, the policy heating (at most the element power for a quarter of an hour, and the room left), then the thermostat. The room temperature is 18 °C and the set point 60 °C.
  - Errors: none. Exposes: PhysTank, PhysTankState, PhysThermostat.
- `import StoragePolicySim.PhysAppliances`:
  - `physBatteryStep (limits : Limits) (battery : Battery) (socKwh : Float) (allowCharge allowDischarge : Bool) (pvKwh loadKwh : Float) : LimitedFlow`: one step of a quarter of an hour. `flow.lossKwh` holds the three losses of the step, and `flow.socKwh` the store after it. A limit in kW allows a quarter of it in kWh.
  - `Cycle {name : String, stepKwh : Array Float}`, `dishwasher`, `washingMachine`, `dryer : Cycle`, `applianceCycles (seed day : Nat) : Array Cycle` (the cycles that run on that day; names `dishwasher`, `washing-machine`, `dryer`).
  - `baseLoadKw (dailyKwh latitude : Float) (dayOfYear step : Nat) : Float`.
  - Errors: none. Exposes: Battery, Cycle.
- `import StoragePolicySim.PhysRun`:
  - `runPhysics (home : Home) (policy : Policy) (seed days : Nat) : HomeResult`: 96 records for each day. In a record, `hour` holds the step (0 to 95), `flexKwh` the appliance energy of the step, and each `TankHour` the tank in that step, with `energyKwh` the energy above the inlet temperature. The totals have the meaning of spec 001.
  - Errors: none. Exposes: PhysicsRun.
- `sim` (process `.lake/build/bin/sim`): each `sim policy` command takes `--model simple|physics` (default `simple`). Errors: `error: UNKNOWN_MODEL: <name> (simple, physics)` on stderr, empty stdout, exit code 2.

The stubs fail with the not-implemented error of the stack: a panic whose message holds "not implemented". With `--model physics`, a stubbed command prints `error: not implemented` on stderr and exits with 3.

### How a test is written

- The tests of slice `Sn` are in `tests/slice2/Sn.lean`. The file imports `tests.slice.Harness` and the library modules, and ends with `def main (args : List String) : IO UInt32 := Harness.run tests args`, where `tests : List Harness.Test`.
- A test name is `test_002_Sn_Rn_<what>`, with letters, digits and `_` only. `Harness.Test`, `Harness.near`, `Harness.sim` and `Harness.firstFail` are those of spec 001 (read `tests/slice/Harness.lean`).

`Status: draft` becomes `Status: approved` only after the user approves the surface, before the test writer runs.

## Security

The app reads only its command line, and writes only stdout and stderr. `--model` takes a name from a fixed list, and an error line repeats the name as typed. The ranges of spec 001 cap the days and the seeds, so a physics run cannot use unbounded memory (96 records for each day, at most 3650 days).

## S1

- Uses: `haurwitzWm2`, `clearSkyWm2`, `dayClearness`, `clearness`, `diffuseShare`, `panelWm2`, `cellTempC`, `arrayKw`, `airTempC`, `inletTempC`
- Stubs: `StoragePolicySim/PhysWeather.lean`
- Changed: none

## S2

- Uses: `physTankOf`, `physStart`, `tankEnergyKwh`, `physTankStep`
- Stubs: `StoragePolicySim/PhysTank.lean`
- Changed: none

## S3

- Uses: `physBatteryStep`, `applianceCycles`, `dishwasher`, `washingMachine`, `dryer`, `baseLoadKw`
- Stubs: `StoragePolicySim/PhysAppliances.lean`
- Changed: R9

## S4

- Uses: `runPhysics`, `sim policy run`, `sim policy compare`, `sim policy robust`, `sim policy tune`, `sim policy plan`
- Stubs: `StoragePolicySim/PhysRun.lean`, `StoragePolicySim/PolicyCommands.lean`
- Changed: R12
