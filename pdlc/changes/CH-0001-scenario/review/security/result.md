Result: pass

Remit: security

Problems: none

Follow-ups: none

Notes:
- This is a re-review. The earlier review listed no problems, so nothing carries over.
- The diff since the earlier review only renames two local names in `scenario`: `sky` becomes `daySkies`, and `s` becomes `sky`. The logic, the inputs and the outputs stay the same. The rename adds no input, command, query, path, secret, access check or dependency.
- The earlier follow-ups (a cap on days, and large seeds) belong to JOB-simulate.R5 (bad command line), as the progress log says. This rename does not change them.
