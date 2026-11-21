Result: pass

Remit: privacy

Problems: none

Follow-ups: none

Notes:
- Not applicable. This change touches no personal data.
- This review is a re-review. The earlier review listed no problems.
- The diff since the earlier review changes three things: a doc comment of `CommandLine.whole`, a new `usageOptionWidth` constant for the usage lines, and one README row for `UNKNOWN_COMMAND`. None of these changes collects, stores, logs or sends personal data.
- The command reads only numbers and a strategy name from its own command line. It writes only to stdout and stderr. It stores nothing and sends nothing over a network. The `--lat` value is a site setting that the person types, and it is not tied to a person.
