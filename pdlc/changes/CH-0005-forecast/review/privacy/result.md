Result: pass

Remit: privacy

Problems:
none

Follow-ups:
none

Notes:
- Not applicable. The change touches no personal data.
- The change adds one file, `StoragePolicySim/Forecast.lean`. The file holds only pure functions. It does no input or output. It does not read a file, write a file, log, print, or call a network service.
- The inputs are a site (latitude, panel power, load, flexible load), a seed, a count of days, an error scale, hours, and a longitude. They describe a simulated site. They do not identify a person. The packet has no name, address, account, or other personal field.
- The output is numbers and Solcast-style JSON text with times and powers. The change stores nothing, so there is nothing to protect or to keep for a time.
- The spec (CAP-forecast, simulated Solcast forecasts) asks for no way for a person to see, correct, or remove data. No rule of this remit is broken.
