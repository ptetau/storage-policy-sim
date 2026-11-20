# Spec: physics models

Status: ratified

## Purpose

The simulator gets physics-based models of the weather and of each appliance, in steps of 15 minutes. The owner of a home uses them to test the same policies with a solar curve, tank behaviour and loads that follow physical rules, so that a policy that works in the simulator also works in the house.

## Decisions

- D1 (two models): The physics model runs beside the simple model of spec 001. `--model physics` picks it on each `sim policy` command, and `--model simple` (the default) keeps every result of spec 001 (assumed: the default changes to `physics` only when the user says so).
- D2 (step): The physics model steps by 15 minutes, 96 steps in a day. A policy still decides once an hour, and its hourly request spreads evenly over the 4 steps. An energy is in kWh in a step, and a power is in kW.
- D3 (sun): The sun position comes from the latitude, the day and the solar time of the middle of the step, with the declination of spec 001. The clear-sky sunlight on flat ground is `1098 × cosZ × exp(-0.059 / cosZ)` W/m² (the Haurwitz model), where `cosZ` is the cosine of the angle of the sun from straight up, and 0 when the sun is down.
- D4 (cloud): Each day has a clearness from 0.15 to 1.0 of the clear sky. The clearness of a day follows the day before (a share of 0.6) plus a random part, with a lower mean in the winter half (assumed: means of 0.65 in summer and 0.45 in winter). Inside a day, each step has the clearness of the day times a random factor that follows the step before, so that cloud passes in runs and not in single steps (assumed). The seed gives the random numbers.
- D5 (direct and diffuse light): The sunlight on flat ground splits into diffuse and direct light by the clearness (the Erbs rule: a low clearness is mostly diffuse). The light on a panel is the direct light times the cosine of its angle to the panel, plus the diffuse light times `(1 + cos tilt) / 2`, plus ground light of 0.2 of the flat sunlight times `(1 - cos tilt) / 2`. Thus cloud dims a north panel more than a south panel.
- D6 (panel output): The output of an array in kW is its power, times the light on it divided by 1000 W/m², times `1 - 0.004 × (cell temperature - 25)`, times 0.9 for wiring and dirt (assumed). The cell temperature is the air temperature plus the light times `(45 - 20) / 800`.
- D7 (temperatures): The air temperature is a mean of the year (13 °C for the default latitude), plus a seasonal swing of 4.5 °C that peaks in midsummer, plus a daily swing of 3.5 °C that peaks at 15:00, less up to 2 °C on a dull day (assumed). The cold water that enters a tank is 14 °C plus a seasonal swing of 3 °C that lags the air by 30 days (assumed). The room around a tank is 18 °C (assumed).
- D8 (tank): A tank is a volume of water in litres with a set point of 60 °C. It holds a hot layer at the set point above a cold layer at the inlet temperature, with no mixing (assumed). A draw takes hot water from the top, and cold water enters at the bottom. The element heats the cold layer to the set point. The tank loses heat to the room by `UA × (set point - room)` for its hot share, where `UA` is the loss share of the tank each hour (0.006 in each home) times its full energy, divided by 42 °C. That gives about 1.8 kWh a day for 250 L and 1.3 for 180 L at a difference of 40 °C (assumed). The litres of a tank are its capacity in kWh divided by 0.001163 kWh for a litre and a degree, and by 45 °C. The thermostat cuts in when the hot share falls below its cut-in share, and stops when the tank is all hot. The tank sterilises when it is all hot, and D16 of spec 001 holds.
- D9 (hot-water use): The household uses hot water in litres at 40 °C at the tap, mixed from the hot layer and cold water. The litres of a day have the daily profile and the random day factor of spec 001. Thus the same shower needs more tank energy in winter, because the cold water is colder. The use is unmet when the hot layer is empty.
- D10 (battery and inverter): The battery loses energy in three ways (assumed): a standby draw of 0.01 kW at all times, a charge efficiency and a discharge efficiency of 0.97 each at any power, and an inverter that turns battery or solar energy into house energy with a loss of `0.02 kW + 0.015 × power` while it runs. The limits of D19 of spec 001 hold.
- D11 (flexible appliances): The flexible load is three appliances with a cycle each (assumed): a dishwasher of 1.2 kWh in 2 hours on 5 days of 7, a washing machine of 0.8 kWh in 1.5 hours on 4 days of 7, and a dryer of 2.5 kWh in 1.5 hours on 2 days of 7. Each cycle has a power for each step, with more power in its heating steps. A policy picks the start step of each cycle of the day. A cycle that started runs to its end, and ends inside its day.
- D12 (base load): The base load is the sum of four parts (assumed): a fridge and freezer of 0.12 kW while the compressor runs, with a duty that rises with the room temperature; lighting of up to 0.3 kW when it is dark and someone is awake (06:00 to 23:00); cooking of 1.2 kWh a day in a morning and an evening block; and a standby of 0.15 kW at all times. A factor scales the sum so that the mean day equals the base load of the home.
- D13 (policies): The three policies of spec 001 run on the physics model with the same rules. A policy sees the tank as its hot share and its energy above the inlet temperature. A heating request is energy for the hour. The start limit and the daily sterilising of spec 001 hold.
- D14 (homes): Each home of spec 001 gets its tank volumes (200 L for `generic`, 135 L for `small`, 300 L for `family`, 250 L and 180 L for `mine`) and the appliances of D11. The other values stay.
- D15 (details for the tests): One litre of water takes 0.001163 kWh for one degree. The diffuse share of the flat sunlight is the Erbs rule at `kt = 0.75 × clearness`: `1 - 0.09 × kt` up to `kt` 0.22, then `0.9511 - 0.1604 kt + 4.388 kt² - 16.638 kt³ + 12.336 kt⁴` up to 0.8, then 0.165. The dull-day drop of the air temperature is `2 × (1 - clearness of the day)`. The seasonal peak is day 15 at a negative latitude and day 197 at latitude 0 or more. The litres at the tap of a day are the draw of the home in kWh divided by `0.001163 × 26`. The forecast of a policy is the forecast of spec 001 over the hourly solar energy of the physics run. Step 0 of a day starts at 00:00, and the hour of a step is the step divided by 4.

## Requirements

- R1 (clear sky): `clearSkyWm2 latitude dayOfYear step` gives the clear-sky sunlight on flat ground by D3. It is 0 at night, it peaks at solar noon, and midsummer noon gives more than midwinter noon.
- R2 (cloud): `clearness seed days` gives one clearness for each step of each day by D4, from 0.15 to 1.0. The same seed gives the same values. A dull day follows a dull day more often than chance. Winter has a lower mean than summer.
- R3 (panel light): `panelWm2` gives the light on a panel by D5 from the flat sunlight, the clearness, the sun position, the direction and the tilt. A flat panel gets the flat sunlight. On a clear day at a southern latitude a north panel gets more than a south panel, and on a fully dull day the two get almost the same.
- R4 (panel output): `arrayKw` gives the output of an array by D6. A hotter cell gives less for the same light. No light gives 0 kW.
- R5 (temperatures): `airTempC` and `inletTempC` give the temperatures by D7. Midsummer is warmer than midwinter, 15:00 is warmer than 05:00, and the inlet water lags the air.
- R6 (tank physics): `physTankStep` runs one step of a tank by D8 and D9. The heat in the tank balances: the start energy plus the heating equals the served energy plus the loss plus the end energy. The loss of a full tank over a day equals its standby loss at a difference of 40 °C, scaled to its real difference. The same litres at 40 °C take more tank energy with colder inlet water.
- R7 (thermostat and sterilising): The thermostat of `physTankStep` cuts in below the cut-in share and stops when the tank is all hot. From the guard hour it heats a tank that was not all hot that day.
- R8 (battery and inverter): `physBatteryStep` runs one step by D10 and the limits of spec 001. The energy balances with the three losses. A battery that sits idle for a day loses its standby energy.
- R9 (flexible appliances): `applianceCycles` gives the cycles of a day by D11 from the seed and the day. Each cycle uses its energy, runs without a gap from its start step, and ends inside its day.
- R10 (base load): `baseLoadKw` gives the base load of a step by D12. A year of it equals the base load of the home, within 1%. It is higher in the evening than at 03:00.
- R11 (physics run): `runPhysics home policy seed days` gives one record for each step and the totals of spec 001 R8, with the same meaning. The energy of the home balances. The same arguments give the same run. For each home and each default policy, no tank has an unmet use over the seeds 1 to 3, and each tank sterilises each day.
- R12 (commands): `--model physics` on `sim policy run`, `compare`, `robust`, `tune` and `plan` uses `runPhysics`. `--model simple` and no `--model` give the output of spec 001. Another name gives `error: UNKNOWN_MODEL: <name> (simple, physics)`.

## Out of scope

- Real weather records, and a live feed.
- Wind, rain and humidity.
- Mixing inside a tank, and scale or ageing of a tank or a battery.
- Room heating and cooling, and an electric vehicle.
- Calibration from the historical data of the house (a later spec).
