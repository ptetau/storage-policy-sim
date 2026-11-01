Result: pass

Remit: security

Problems: none

Follow-ups: none

Notes:
- This is a re-review. The earlier review listed no problems, so there is nothing to recheck.
- The diff changes three things. The doc comment of `CommandLine.whole` now names the reading step and the range step. The new constant `usageOptionWidth` (18) replaces `labelWidth` in `usageLine`. The README error table now names `--help`.
- None of these lines reads input, builds a command, query, path or page, holds a secret, or checks access. `usageLine` gets only fixed option strings from the code, and Nat subtraction stops at 0, so a long option cannot cause an error.
