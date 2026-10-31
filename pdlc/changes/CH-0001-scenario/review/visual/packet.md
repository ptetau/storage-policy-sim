# Review packet · CH-0001-scenario · visual

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 1fac2c40adba5bee2783b85f321ba86da9c15706

# Remit: visual

Default: yes

You judge the recording of the change: the frames of `review.gif`. The change passed its
checks and its code reviews already. You do not see the code or the checks.

The packet holds the acceptance lines of the change, the script of the recording
(`visual.json`), and the list of the frames. Read each frame.

- Each acceptance line of the change has one or more frames. The caption of its first
  frame starts with the requirement ID.
- Each frame shows what its caption claims, after its step. A blank frame, or a frame with
  the screen from before the step, is a problem.
- A caption with `setup:` after the ID only prepares a state. Its frame shows that state,
  and nothing more is necessary.
- When several frames share one caption, the last of them shows the claim. The frames
  before it show the steps toward it.
- Each part of a caption is visible on screen. A frame that shows less than its caption
  claims is a problem, also when the claim is probably true. Examples:
  - An exit code on screen comes from a different command, for example `wc` after a pipe.
  - The input is too small to show the effect, for example a limit of 7 on a file with 3
    words.
- The frames show the behaviour as a user meets it:
  - A web app: pages and clicks. A page cannot show a status code, a header, a redirect,
    or the target of a form. These show in a terminal frame of `curl -si`.
  - In a web app, a terminal frame that shows or searches the HTML of a page, in place of
    the page, is a `script` problem.
  - A CLI: commands and their output.
  - A library: a short script that calls the interface.
- An error on screen is a problem, unless its acceptance line asks for that error.
- Each recording ends with a frame that shows all checks pass.

Write each problem as `<frame> · <what is wrong> · <the acceptance line or rule> · <kind>`.
The kind is one of these:

- `script`: the recording is wrong. Examples are a wrong selector, a missing step, and a
  step that shows the screen from before the change. A frame that shows less than its
  caption claims is also a `script` problem.
- `app`: the step does what its acceptance line says, but the app does not meet the line.

Do not write follow-ups. Put a wish for new behaviour of the app under "Notes". A frame
that shows less than its caption claims is not a wish. It is a `script` problem.

On a re-review, judge only the frames that do not have the mark "unchanged since the
earlier review".

## The change spec

````
# CH-0001 · Seasonal sun, daily weather and household load

Intent: IN-0001 · Scope: CAP-scenario · Status: in review · Ticket: none · Branch: pdlc/CH-0001-scenario · Base: main

Tests-Locked: 5de000a

## Delivers

The library gives the hours of a scenario. Each hour has a solar output from the season,
the sun height and a seeded daily sky. Each hour also has a base load and a flexible load.

## Requirements

### CAP-scenario.R1 · Seasonal sun

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Scenario.lean`. A
check imports `StoragePolicySim.Scenario` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Sky | sunny | cloudy | overcast` with `BEq`, `Repr` and `Inhabited` (assumed).
- `Sky.factor : Sky → Float`: 1.0 for `sunny`, 0.5 for `cloudy`, and 0.15 for `overcast`.
- `structure Site` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `latitude : Float`: degrees, south is negative.
  - `pvKw : Float`: the kW of the panels.
  - `dailyLoadKwh : Float`: the load of a day, with the flexible load included.
  - `flexKwh : Float`: the part of the daily load that a strategy can move.
- `structure Hour` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `day : Nat`: the day of the run, from 0.
  - `dayOfYear : Nat`: `day % 365`, from 0 (1 January) to 364.
  - `hour : Nat`: the hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00.
  - `sky : Sky`: the sky of the day.
  - `pvKwh : Float`: the solar energy of the hour.
  - `baseLoadKwh : Float`: the base load of the hour.
  - `flexKwh : Float`: the flexible load of the hour, at its default hours.
- `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float` gives the solar energy
  of one hour in kWh. It reads only `latitude` and `pvKw` of the site.
- `scenario (site : Site) (seed days : Nat) : Array Hour` gives `24 × days` hours, in order of
  day, then hour. The same arguments give the same array.

### Test seams

- randomness: the `seed` argument of `scenario`. The same seed gives the same skies.
- clock: none, because no line depends on the real date or time.

## Files

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`

## Check files

- `tests/CAP-scenario.lean`

## Steps

### Step 1 · Seasonal sun · [x]

- Requirement: CAP-scenario.R1
- Check: the checks named `CAP-scenario.R1 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 2 · Daily weather · [x]

- Requirement: CAP-scenario.R2
- Check: the checks named `CAP-scenario.R2 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 3 · Household load · [x]

- Requirement: CAP-scenario.R3
- Check: the checks named `CAP-scenario.R3 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned as the first change of IN-0001 (solar self-consumption simulator), because each other change uses its hours.
- The builder found that `tests/CAP-scenario.lean` does not compile. `fun c => c.name` needs the type `Check` in Lean 4.35.0. The check goes back to the test writer, round 1 of 2.
- `lake build` writes `lake-manifest.json`. The file goes into "Files" (assumed), so that the build is the same each time.
- After the fix, the 34 checks of `tests/CAP-scenario.lean` pass on the code of the builder. App code exists after a send-back, so a pass is permitted.
- Build: the 34 checks of `tests/CAP-scenario.lean` pass. No check changed since the lock `5de000a`.
- Verify round 1: quality and specification failed. The follow-ups of security (a cap on days, and large seeds) need no intent, because JOB-simulate.R5 (bad command line) limits `--days` and `--seed`.
- Verify returned the change to build, because two local names in `scenario` were not clear.
- The builder renamed the array of the day skies to `daySkies`, and the sky of one day to `sky`. The 34 checks pass.
- Verify round 2: specification failed on the words of three log lines. Verify corrected the words, and no code changed.
- Verify round 3: specification failed, because two log lines did not agree on the count of names. The user chose to correct the words and review again.
- Verify round 4: each remit passed. The change is `in review`.
````

## The spec it covers: title and summary

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the conditions that a strategy must handle, one hour at a time. It gives
the solar output of each hour from the season and the sun height, and a daily sky from a
seeded weather model. It also gives the household load of each hour, with a seasonal base
load and a flexible load that a strategy can move.

## Code map

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`
````

## The requirements, in full

### CAP-scenario.R1 · Seasonal sun

Status: verified · Intents: IN-0001

The output of an hour is the panel power, times the sine of the sun height, times the sky
factor (assumed). The sun height uses the latitude, the day of the year, and the middle of
the hour in solar time (assumed).

The declination is 23.44 degrees times sin(2π × (285 + day) / 365), where day 0 is 1 January
(assumed). The sky factor is 1.0 for sunny, 0.5 for cloudy, and 0.15 for overcast (assumed).
When the sun is below the horizon, the output is 0. In these lines, the site has 5 kW of panels,
unless the line says otherwise.

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

Status: verified · Intents: IN-0001

A seed and a number of days give one sky for each day, and the same hours each time. The
scenario starts on 1 January and gives the hours in order of day, then hour.

Each day keeps the sky of the day before with a chance of 0.6 (assumed). Else, the day takes
a new sky from the chances of its half of the year (assumed):

- Summer half: sunny 0.55, cloudy 0.30, overcast 0.15 (assumed).
- Winter half: sunny 0.20, cloudy 0.35, overcast 0.45 (assumed).

The summer half is days 90 to 272 of each year at latitude 0 or more, and the other days at
a negative latitude (assumed). After day 364, the day of the year starts again at 0.

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

Status: verified · Intents: IN-0001

The daily load includes the flexible load. The base load is the daily load less the flexible
load, spread over the hours by a fixed profile (assumed).

The profile has a morning peak and an evening peak (assumed). A seasonal factor of
1 + 0.2 × cos(2π × (day - peak) / 365) scales the base load (assumed). The peak is day 15 at
latitude 0 or more, and day 197 at a negative latitude (assumed).

By default, the flexible load uses equal parts at 18:00, 19:00 and 20:00 (assumed). The load
does not depend on the seed. In these lines, the daily load is 20 kWh with 3 kWh flexible,
unless the line says otherwise.

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.

## Specs it relies on

## The script of the recording

````
{
  "kind": "terminal",
  "title": "CH-0001 \u00b7 Seasonal sun, daily weather and household load",
  "width": 1000,
  "height": 640,
  "steps": [
    {
      "caption": "CAP-scenario \u00b7 setup: build the library",
      "run": "lake build 2>&1 | tail -1"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 latitude 45: day 171 gives more than twice day 354",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-1"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 latitude -41: day 354 gives more than twice day 171",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-2"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 latitude 0: days 171 and 354 differ by less than 1%",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-3"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 latitude 45: 00:00 on day 171 gives 0 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-4"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 each sunny hour of a year gives 0 to 5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-5"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 cloudy gives 0.5 times the sunny output",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-6"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 overcast gives 0.15 times the sunny output",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-7"
    },
    {
      "caption": "CAP-scenario.R1 \u00b7 0 kW of panels gives 0 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r1-8"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 seed 7 gives the same hours two times",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-1"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 seeds 7 and 8 differ on at least 50 days",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-2"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 365 days give 8760 hours in order",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-3"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 0 days give no hours",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-4"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 the 24 hours of each day have one sky",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-5"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 each solar output equals R1 (seasonal sun)",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-6"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 latitude 45: winter has over twice the overcast days",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-7"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 latitude -41: June to August has over twice the overcast days",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-8"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 60% or more of days keep the previous sky",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-9"
    },
    {
      "caption": "CAP-scenario.R2 \u00b7 after day 364, the day of the year starts at 0",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r2-10"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 365 days have 7300 kWh of load",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-1"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 latitude 45: day 15 has 1.45 to 1.55 times the base load of day 197",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-2"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 latitude -41: day 197 has 1.45 to 1.55 times the base load of day 15",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-3"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 day 100: more base load at 19:00 than at 13:00",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-4"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 day 100: more base load at 07:00 than at 03:00",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-5"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 3 kWh of flexible load: 1 kWh at 18:00, 19:00 and 20:00",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-6"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 0 kWh of flexible load: 0 kWh in each hour",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-7"
    },
    {
      "caption": "CAP-scenario.R3 \u00b7 seeds 7 and 8 have the same base and flexible load",
      "run": "lake env lean --run pdlc/changes/CH-0001-scenario/demo.lean r3-8"
    },
    {
      "caption": "CH-0001 \u00b7 all checks pass",
      "run": "for f in tests/*.lean; do lake env lean --run \"$f\" || exit 1; done"
    }
  ]
}
````

## The frames

Read each frame:

- pdlc/changes/CH-0001-scenario/frames/01.png
- pdlc/changes/CH-0001-scenario/frames/02.png
- pdlc/changes/CH-0001-scenario/frames/03.png
- pdlc/changes/CH-0001-scenario/frames/04.png
- pdlc/changes/CH-0001-scenario/frames/05.png
- pdlc/changes/CH-0001-scenario/frames/06.png
- pdlc/changes/CH-0001-scenario/frames/07.png
- pdlc/changes/CH-0001-scenario/frames/08.png
- pdlc/changes/CH-0001-scenario/frames/09.png
- pdlc/changes/CH-0001-scenario/frames/10.png
- pdlc/changes/CH-0001-scenario/frames/11.png
- pdlc/changes/CH-0001-scenario/frames/12.png
- pdlc/changes/CH-0001-scenario/frames/13.png
- pdlc/changes/CH-0001-scenario/frames/14.png
- pdlc/changes/CH-0001-scenario/frames/15.png
- pdlc/changes/CH-0001-scenario/frames/16.png
- pdlc/changes/CH-0001-scenario/frames/17.png
- pdlc/changes/CH-0001-scenario/frames/18.png
- pdlc/changes/CH-0001-scenario/frames/19.png
- pdlc/changes/CH-0001-scenario/frames/20.png
- pdlc/changes/CH-0001-scenario/frames/21.png
- pdlc/changes/CH-0001-scenario/frames/22.png
- pdlc/changes/CH-0001-scenario/frames/23.png
- pdlc/changes/CH-0001-scenario/frames/24.png
- pdlc/changes/CH-0001-scenario/frames/25.png
- pdlc/changes/CH-0001-scenario/frames/26.png
- pdlc/changes/CH-0001-scenario/frames/27.png
- pdlc/changes/CH-0001-scenario/frames/28.png
