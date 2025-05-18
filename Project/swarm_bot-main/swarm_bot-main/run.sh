#!/usr/bin/env bash
# ---------------------------------------------
# Resumable batch script for all scenarios.
# Resumes at foraging_s1,44,5 after crash.
# Results go to scores2.txt in results_flexibility_scalability.
# ---------------------------------------------

set -e
set -u

OUTDIR="results_flexibility_scalability"
mkdir -p "$OUTDIR"
OUTTXT="$OUTDIR/scores.csv"

# Initialize header only if the file doesn't exist
if [ ! -f "$OUTTXT" ]; then
  echo "scenario,robots,rep,seed,score" > "$OUTTXT"
fi

# --------- helper to check if run already exists ----------
run_exists () {
  grep -q "^$1,$2,$3," "$OUTTXT"
}

# --------- helper to run one (scenario,n,rep) ----------
run_one () {
  local scenario="$1"
  local robots="$2"
  local rep="$3"
  local seed=$(( 1000 + RANDOM % 9000 ))

  # Skip if already done
  if run_exists "${scenario%.*}" "$robots" "$rep"; then
    echo "    [SKIP] Already done: $scenario (robots=$robots, rep=$rep)"
    return
  fi

  # Build temporary file
  if grep -q "__ROBOT_COUNT__" "$scenario"; then
    sed -e "s/__ROBOT_COUNT__/$robots/" \
        -e "s/__RANDOM_SEED__/$seed/" "$scenario" > temp.argos
  else
    sed -e "s/__RANDOM_SEED__/$seed/" "$scenario" > temp.argos
  fi

  # Run ARGoS
  local LOG="$OUTDIR/$(basename "${scenario%.*}")_${robots}_${rep}.log"
  argos3 -c temp.argos > "$LOG"

  # Extract score
  local score
  score=$(grep "Objects:" "$LOG" | awk '{print $2}')

  # Append to results
  echo "${scenario%.*},$robots,$rep,$seed,$score" >> "$OUTTXT"
}

# --------- helper to run a range of robot counts ----------
run_range () {
  local scenario="$1"
  local first="$2"
  local last="$3"
  local step="$4"

  for n in $(seq "$first" "$step" "$last"); do
    echo "=== $scenario   robots=$n ==="
    for rep in {1..10}; do
      echo "  → run $rep"
      run_one "$scenario" "$n" "$rep"
    done
  done
}

# ---------------- RUN SECTION ----------------

# 1) Resume foraging_s1.argos (all runs from 2 to 50, 10 reps each)
run_range foraging_s1.argos 2 50 2

# 2) Full run for i_foraging_s1.argos
run_range i_foraging_s1.argos 2 50 2

# 3) foraging_s2/3/4.argos, fixed robot count = 10
for scen in foraging_s2.argos foraging_s3.argos foraging_s4.argos; do
  echo "=== $scen   robots=10 ==="
  for rep in {1..10}; do
    echo "  → run $rep"
    run_one "$scen" 10 "$rep"
  done
done

rm -f temp.argos
echo "All simulations completed. Results stored in $OUTTXT"

