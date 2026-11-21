# slice config

- stack: Lean 4.35.0 with Lake. The app is a library (`StoragePolicySim`) and the `sim` command. The tests are Lean programs that Lake compiles, one for each slice, and a Python runner reports them.
- test command: `python3 tests/run.py --junit {junit}`
- result format: junit
- tests folder: `tests`
- source folders: `StoragePolicySim`
- source files: `Main.lean`, `lakefile.toml`, `README.md`
- security scan: none

The runner builds the project with `lake build`, runs the test program of each slice, runs the
older check files with `lake env lean --run`, and writes one junit report to `{junit}`.
Each test name holds the spec number, the ID of its slice, and the requirement: `test_NNN_Sn_Rn_<what>`, for example `test_001_S1_R6_run_has_8760_hours`.
A stub fails with `panic! "not implemented"`. The runner reports each test of a slice whose program panics with "not implemented" as an error with that message.
`security scan` is `none`, because no common scanner covers Lean.
