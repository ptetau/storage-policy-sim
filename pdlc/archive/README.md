# pdlc archive

The project moved from the pdlc harness to the slice harness on 2026-11-18. The pdlc records
stay as history. No pdlc stage runs any more.

## Where pdlc stopped

- IN-0001 (simulator) and IN-0002 (Solcast forecast) are built and proposed.
- IN-0008 (hot-water policy simulation) is paused:
  - CH-0006 (forecast from built hours, shared error of a day) is built, verified and proposed.
  - CH-0007 (hot-water tank) is built, and its 73 checks pass. Its second verify round is not
    finished: only the privacy review ran.
  - CH-0008 to CH-0011 are not built.

## Checks in `checks/`

These check files were written for IN-0008 and are not run. The slice work can read them.

- `IN-0008.acceptance.lean`: the 216 acceptance checks of IN-0008, locked and reviewed.
- `CAP-policy.lean` and `CAP-homesim.lean`: the component checks of CH-0009 and CH-0010.
- `CAP-simulation.with-R6.lean`: `tests/CAP-simulation.lean` with the checks of the gated battery.
- `JOB-simulate.with-R6-R11.lean`: `tests/JOB-simulate.lean` with the checks of the new commands.

The files import modules that do not exist yet (`Policy`, `HomeSim`), so they do not compile now.
