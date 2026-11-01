Result: pass

Remit: privacy

Problems: none

Follow-ups: none

Notes:
- Not applicable. The change touches no personal data. `sim` takes only simulation numbers and a strategy name. No name, address, account or contact detail goes in.
- `--lat` is a latitude and `--load` is a daily household load, but the person types each value. One latitude with no longitude, name or address does not identify a person.
- The command stores nothing. It writes no file and no log, and sends nothing over a network. It prints only to stdout and stderr in the person's own terminal.
- An error line repeats the word or value that the person typed, for example `error: BAD_NUMBER: --days abc`. JOB-simulate.R5 (bad command line) asks for this, and the text goes back only to the same person.
