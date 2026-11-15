# IN-0009 · Re-planning and finer time steps

Status: new · Ticket: none · Branch: none · Added: 2026-11-15

## What and why

"do research on this very problem and control systems so that we can be sure to model the problem correctly"

The research of IN-0008 (hot-water policy simulation) found two limits that it does not remove. First, the home simulation steps one hour at a time. Solar and load vary within an hour, so an hourly step flatters every policy a little. Second, the precomputed policy plans once at 00:00. A policy that plans again at each forecast fetch (receding-horizon control) can use the later and better forecasts.

## Requirements

- none yet

## Changes

- none yet

## Acceptance checks

Acceptance-File: none
Acceptance-Locked: none
Acceptance-Passed: none

## Notes

- Awaits approval: found by the research of IN-0008 (hot-water policy simulation). The prototype showed that a perfect forecast adds under 1 point of self-consumption, so the gain of re-planning may be small. The intent should first measure that gain.

## Handoff

none
