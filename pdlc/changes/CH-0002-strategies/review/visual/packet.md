# Review packet · CH-0002-strategies · visual

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: f404991fc04a612236cef74b59808da513c58b7a

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
# CH-0002 · Battery and load strategies

Intent: IN-0001 · Scope: CAP-strategies · Status: in review · Ticket: none · Branch: pdlc/CH-0002-strategies · Base: pdlc/CH-0001-scenario

Tests-Locked: 91d1e6b

## Delivers

The library has four named strategies. Each strategy asks the battery to charge or to
discharge for an hour, and places the flexible load of a day.

## Requirements

### CAP-strategies.R1 · Strategy names

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Strategy.lean`. A
check imports `StoragePolicySim.Strategy` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Strategy | none | greedy | evening | shift` with `BEq`, `Repr` and `Inhabited`
  (assumed). Write each value in full, for example `Strategy.none`, so that it does not
  mean `Option.none`.
- `Strategy.all : List Strategy`: `[.none, .greedy, .evening, .shift]`.
- `Strategy.name : Strategy → String`: `"none"`, `"greedy"`, `"evening"` or `"shift"`.
- `Strategy.ofName? (name : String) : Option Strategy`: the strategy whose name matches
  exactly, or `Option.none`.
- `structure Request` with `Repr` (assumed). The fields are `chargeKwh : Float` and
  `dischargeKwh : Float`: the energy that the strategy asks to charge and to discharge.
- `Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request`.
  The hour is 0 to 23, and hour 17 is 17:00 to 18:00. The surplus is the solar energy that
  the house does not use directly. The shortfall is the load that the solar energy does not
  meet. One of the two is 0.
- `Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float`. Each array
  has 24 items, one for each hour of a day. `pvKwh` is the solar energy of each hour, and
  `flexKwh` is the flexible load at its default hours. The result is the flexible load of
  each hour after the strategy places it.

### Test seams

none

## Files

- `StoragePolicySim/Strategy.lean`

## Check files

- `tests/CAP-strategies.lean`

## Steps

### Step 1 · Strategy names · [x]

- Requirement: CAP-strategies.R1
- Check: the checks named `CAP-strategies.R1 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 2 · No battery use · [x]

- Requirement: CAP-strategies.R2
- Check: the checks named `CAP-strategies.R2 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 3 · Greedy battery use · [x]

- Requirement: CAP-strategies.R3
- Check: the checks named `CAP-strategies.R3 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 4 · Evening battery use · [x]

- Requirement: CAP-strategies.R4
- Check: the checks named `CAP-strategies.R4 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 5 · Load shift into sun · [x]

- Requirement: CAP-strategies.R5
- Check: the checks named `CAP-strategies.R5 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- The change comes after CH-0001 (scenario). CH-0003 (simulation) needs the scenario and the strategies. The strategies do not need the scenario.
- The first tests review failed, because a wrong `shift` that takes three hours in a row passed the checks of R5 (load shift into sun).
- The test writer then added a check whose three sunniest hours are not next to each other. The second tests review passed.
- Build: the 35 checks of `tests/CAP-strategies.lean` and the 34 checks of `tests/CAP-scenario.lean` pass. No check changed since the lock `91d1e6b`.
- The first verify failed on the quality review and the specification review.
- The quality review asked for DES-writing-style (writing rules). `make_packets.py` gives that spec only to the specification review. The quality remit does not judge writing, so the builder changed no code.
- Verify filed IN-0005 (guards on strategy inputs) for approval. IN-0004 (shift on a day with little sun) already covers the follow-up about days with little sun.
- The user decided that a review failure only on the words of pdlc records does not use one of the permitted verify rounds.
````

## The spec it covers: title and summary

````
# CAP-strategies · Battery and load strategies to compare

Status: active

## What it is for

CAP-strategies (battery and load strategies) holds the rules that the simulation compares.
Each strategy has a name. For each hour, a strategy asks the battery to charge or to
discharge. For each day, a strategy also places the flexible load.

The four strategies are these:

- `none`: no battery use.
- `greedy`: battery use at any hour.
- `evening`: discharge only in the evening.
- `shift`: greedy battery use, and the flexible load in the sunniest hours.

## Code map

- `StoragePolicySim/Strategy.lean`
````

## The requirements, in full

### CAP-strategies.R1 · Strategy names

Status: verified · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: verified · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: verified · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: verified · Intents: IN-0001

The `evening` strategy charges as `greedy` does. It discharges only from 17:00 to 23:59
(assumed), to keep the stored energy for the evening peak. It keeps the flexible load at its
default hours.

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

Status: verified · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

## Specs it relies on

## The script of the recording

````
{
  "kind": "terminal",
  "title": "CH-0002 \u00b7 Battery and load strategies",
  "width": 1000,
  "height": 640,
  "steps": [
    {
      "caption": "CAP-strategies \u00b7 setup: build the library",
      "run": "lake build 2>&1 | tail -1"
    },
    {
      "caption": "CAP-strategies.R1 \u00b7 the list is none, greedy, evening and shift, in this order",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r1-1"
    },
    {
      "caption": "CAP-strategies.R1 \u00b7 the name \"greedy\" finds the greedy strategy",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r1-2"
    },
    {
      "caption": "CAP-strategies.R1 \u00b7 the name \"Greedy\" finds no strategy",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r1-3"
    },
    {
      "caption": "CAP-strategies.R1 \u00b7 the name \"\" finds no strategy",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r1-4"
    },
    {
      "caption": "CAP-strategies.R2 \u00b7 none: a surplus of 2 kWh at 12:00 asks 0 and 0",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r2-1"
    },
    {
      "caption": "CAP-strategies.R2 \u00b7 none: a shortfall of 1.5 kWh at 19:00 asks 0 and 0",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r2-2"
    },
    {
      "caption": "CAP-strategies.R2 \u00b7 none: the flexible load does not change",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r2-3"
    },
    {
      "caption": "CAP-strategies.R3 \u00b7 greedy: a surplus of 2 kWh at 12:00 asks to charge 2 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r3-1"
    },
    {
      "caption": "CAP-strategies.R3 \u00b7 greedy: a shortfall of 1.5 kWh at 03:00 asks to discharge 1.5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r3-2"
    },
    {
      "caption": "CAP-strategies.R3 \u00b7 greedy: a shortfall of 1.5 kWh at 13:00 asks to discharge 1.5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r3-3"
    },
    {
      "caption": "CAP-strategies.R3 \u00b7 greedy: no surplus and no shortfall asks 0 and 0",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r3-4"
    },
    {
      "caption": "CAP-strategies.R3 \u00b7 greedy: the flexible load does not change",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r3-5"
    },
    {
      "caption": "CAP-strategies.R4 \u00b7 evening: a surplus of 2 kWh at 12:00 asks to charge 2 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r4-1"
    },
    {
      "caption": "CAP-strategies.R4 \u00b7 evening: a shortfall at 16:00 asks to discharge 0 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r4-2"
    },
    {
      "caption": "CAP-strategies.R4 \u00b7 evening: a shortfall at 17:00 asks to discharge 1.5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r4-3"
    },
    {
      "caption": "CAP-strategies.R4 \u00b7 evening: a shortfall at 23:00 asks to discharge 1.5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r4-4"
    },
    {
      "caption": "CAP-strategies.R4 \u00b7 evening: a shortfall at 00:00 asks to discharge 0 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r4-5"
    },
    {
      "caption": "CAP-strategies.R4 \u00b7 evening: the flexible load does not change",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r4-6"
    },
    {
      "caption": "CAP-strategies.R5 \u00b7 shift: a surplus of 2 kWh at 12:00 asks to charge 2 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r5-1"
    },
    {
      "caption": "CAP-strategies.R5 \u00b7 shift: a shortfall of 1.5 kWh at 03:00 asks to discharge 1.5 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r5-2"
    },
    {
      "caption": "CAP-strategies.R5 \u00b7 shift: the most sun at 13:00, 11:00 and 12:00 gives each 1 kWh",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r5-3"
    },
    {
      "caption": "CAP-strategies.R5 \u00b7 shift: equal sun from 10:00 to 14:00 gives 10:00 to 12:00 1 kWh each",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r5-4"
    },
    {
      "caption": "CAP-strategies.R5 \u00b7 shift: no sun keeps 18:00, 19:00 and 20:00",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r5-5"
    },
    {
      "caption": "CAP-strategies.R5 \u00b7 shift: 0 kWh of flexible load stays 0 kWh in each hour",
      "run": "lake env lean --run pdlc/changes/CH-0002-strategies/demo.lean r5-6"
    },
    {
      "caption": "CH-0002 \u00b7 all checks pass",
      "run": "for f in tests/*.lean; do lake env lean --run \"$f\" || exit 1; done"
    }
  ]
}
````

## The frames

Read each frame:

- pdlc/changes/CH-0002-strategies/frames/01.png
- pdlc/changes/CH-0002-strategies/frames/02.png
- pdlc/changes/CH-0002-strategies/frames/03.png
- pdlc/changes/CH-0002-strategies/frames/04.png
- pdlc/changes/CH-0002-strategies/frames/05.png
- pdlc/changes/CH-0002-strategies/frames/06.png
- pdlc/changes/CH-0002-strategies/frames/07.png
- pdlc/changes/CH-0002-strategies/frames/08.png
- pdlc/changes/CH-0002-strategies/frames/09.png
- pdlc/changes/CH-0002-strategies/frames/10.png
- pdlc/changes/CH-0002-strategies/frames/11.png
- pdlc/changes/CH-0002-strategies/frames/12.png
- pdlc/changes/CH-0002-strategies/frames/13.png
- pdlc/changes/CH-0002-strategies/frames/14.png
- pdlc/changes/CH-0002-strategies/frames/15.png
- pdlc/changes/CH-0002-strategies/frames/16.png
- pdlc/changes/CH-0002-strategies/frames/17.png
- pdlc/changes/CH-0002-strategies/frames/18.png
- pdlc/changes/CH-0002-strategies/frames/19.png
- pdlc/changes/CH-0002-strategies/frames/20.png
- pdlc/changes/CH-0002-strategies/frames/21.png
- pdlc/changes/CH-0002-strategies/frames/22.png
- pdlc/changes/CH-0002-strategies/frames/23.png
- pdlc/changes/CH-0002-strategies/frames/24.png
- pdlc/changes/CH-0002-strategies/frames/25.png
- pdlc/changes/CH-0002-strategies/frames/26.png
