# IN-0006 · Polish of the sim command

Status: new · Ticket: none · Branch: none · Added: 2026-11-01

## What and why

The reviews of CH-0004 (the sim command) found five points that no acceptance line covers:

- "Escape control characters in the error lines. They show each typed word unchanged, so terminal escape codes reach the terminal."
- "Cap the length of a number value before the reader reads it. A very long digit string costs time and memory before the range check rejects it."
- "The table does not widen a column when a field is longer than its header word."
- "`sim help extra` ignores the extra words."
- "When two options are out of range, the error names the first option in a fixed list, not the first option that the person typed."

## Requirements

- none yet

## Changes

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

## Notes

- Awaits approval: found reviewing CH-0004 (security, quality, specification)

## Handoff

none
