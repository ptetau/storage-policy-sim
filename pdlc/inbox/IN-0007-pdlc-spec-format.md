# IN-0007 · Bring the specs to the pdlc 0.6.0 form

Status: new · Ticket: none · Branch: none · Added: 2026-11-15

The pdlc scripts read each header field. Thus, a header field holds only its bare value.
Do not add a name in brackets, and do not add backticks. For example, write
`Branch: pdlc/IN-0001-reset`, not `Branch: pdlc/IN-0001-reset (the intent branch)`.

## What and why

pdlc 0.6.0 reads parts of a spec that some specs of this project do not have. The list
below gives each spec and each missing part. Add each part, and keep the behaviour of the
app the same.

- JOB-simulate: no "Interface" section.
- CAP-forecast: no "Interface" section.
- CAP-scenario: no "Interface" section.
- CAP-simulation: no "Interface" section.
- CAP-strategies: no "Interface" section.

## Requirements

Intake writes this section. The section lists the requirements that this intent added or
changed.

- none yet

## Changes

The change stage writes this section. The section lists the changes that deliver this
intent, in order.

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

The acceptance stage writes the path of the file and the lock. The `verify` stage of the
last change writes the commit at which the checks passed. Each line holds only a bare
value: a path, a commit hash, or `none`.

## Notes

- Awaits approval: Upgrade pdlc filed this intent.

## Handoff

Each intent stage (intake, ready, change) writes this section for the next stage. Replace
this section each time. The first line is `Handoff · IN-0000 · <this stage> → <next stage>`,
and the second line is `Time: …`. Then the sections of the handoff template follow as `###`
headings.
