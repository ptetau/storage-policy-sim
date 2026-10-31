# pdlc config

## Adapters

Each port has one adapter. The name of an adapter is a file in `pdlc/adapters/`.

- inbox: inbox-files
- checks: checks-command
- review: review-agent
- visual: visual-terminal
- delivery: delivery-github
- tracker: none

## Checks

This section gives the command that runs the checks of this project, and the command that
runs only the checks for one requirement. Init writes this section. A project with no
checks yet keeps its checks in `tests/`.

- all: `lake build && for f in tests/*.lean; do lake env lean --run "$f" || exit 1; done`
- one requirement: `lake build && for f in tests/*.lean; do lake env lean --run "$f" {req} || exit 1; done`
- check folders: `tests/`
- acceptance file: `tests/acceptance/{intent}.acceptance.lean`
- acceptance: `lake build && for f in {files}; do lake env lean --run "$f" || exit 1; done`
- ID form in check names: `dotted`

## Reviews

Each remit is a separate, independent review. The files in `pdlc/reviews/` give the
details of each remit.

- remits: tests, specification, security, quality, compliance, privacy, visual

## Visual

This section tells how to run the app for the visual review. Init writes this section.

- start: none (a command that starts the app, for web apps)
- url: none (where the app answers after it starts)

## Board columns

pdlc uses this section only when a tracker adapter is set. Each line gives a pdlc status
and its board column, for intents and changes.

- new: Backlog
- specifying: Backlog
- paused: Backlog
- ready: Ready
- planned: Ready
- testing: In progress
- building: In progress
- in review: In review
- done: Done
- merged: Done

## Tracker settings

This section is necessary only when a tracker adapter is set. The file of the adapter
tells what goes here.

- none
