#!/bin/bash
# Runs each bad command line of JOB-simulate.R5 (bad command line) and shows where the output goes.
# Run it from the project root: bash pdlc/changes/CH-0004-sim-command/errors.sh
sim=.lake/build/bin/sim
cases=(
  "fly" "run --colour red" "run --days" "run --days abc" 'run --days ""' "run --days 36.5"
  "run --pv 1e3" "run --pv .5" "run --pv 5." "run --pv 5kW" "run --days 0" "run --days 3651"
  "run --days 99999999999999999999" "run --seed -1" "run --seed 4294967296" "run --lat 90.1"
  "run --lat -90.1" "run --pv 100.1" "run --pv -1" "run --battery 200.1" "run --power 100.1"
  "run --load 0" "run --load 1000.1" "run --load 10 --flex 10.5" "run --strategy wild" "run now"
  "compare --strategy greedy"
)
for c in "${cases[@]}"; do
  eval "$sim $c" >/tmp/sim-out.txt 2>/tmp/sim-err.txt
  code=$?
  printf '%-34s exit %s, stdout %s bytes, stderr %s line\n' "$c" "$code" \
    "$(wc -c </tmp/sim-out.txt)" "$(wc -l </tmp/sim-err.txt)"
done
echo "${#cases[@]} bad command lines"
