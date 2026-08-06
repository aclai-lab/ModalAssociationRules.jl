#!/usr/bin/env bash

# status of the first failing command
set -uo pipefail

# Note: we deliberately do NOT use "set -e" here — the run() function below
# checks each command's exit status explicitly and stops the whole script
# the moment one fails, which is more robust than relying on -e across a
# piped `tee` command.

# Runs all Apriori / FPGrowth / Eclat benchmark configurations, one after another,
# across thread counts 1, 2, 4, 8, 16. Each run only starts if the previous one
# finished successfully and, otherwise, the script stops immediately.
#
# Logs for each run are saved under ./logs/<algorithm>_threads_<N>.log

LOGDIR="logs"
mkdir -p "$LOGDIR"

run() {
    local algorithm="$1"
    local threads="$2"
    shift 2
    local logfile="${LOGDIR}/${algorithm}_threads_${threads}.log"

    echo "=============================================="
    echo ">>> Running ${algorithm} with ${threads} thread(s)"
    echo "=============================================="

    # ${PIPESTATUS[0]} gives julia's exit code specifically, not tee's,
    # even though the command is piped.
    julia +1.11 -t"${threads}" --project=. benchmark/benchmarking.jl "$@" \
        --gctrial true --savename "threads_${threads}" --algorithm "${algorithm}" --rng 9989 \
        2>&1 | tee "${logfile}"
    local status="${PIPESTATUS[0]}"

    if [ "$status" -ne 0 ]; then
        echo ">>> FAILED: ${algorithm} (${threads} threads) exited with status ${status}." echo ">>> Stopping — remaining runs will NOT execute. See ${logfile} for details."
        exit "$status"
    fi

    echo ">>> Finished ${algorithm} (${threads} threads) successfully. Log: ${logfile}"
    echo
}

THREADS_LIST=(1 2 4 8 16)

# ---------------------------------------------------------------------------
# Apriori
# ---------------------------------------------------------------------------
APRIORI_ARGS=(--ninstances 1000 --nworlds 100 --nedges 200 --npropositions 10
    --lsupports 0.2 0.25 0.3 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.7 0.75 0.80 0.85 0.90 0.95 1.0
    --mingsupports 0.10 --nruns 1)

for t in "${THREADS_LIST[@]}"; do
    run "apriori" "$t" "${APRIORI_ARGS[@]}"
done

# ---------------------------------------------------------------------------
# FPGrowth
# ---------------------------------------------------------------------------
FPGROWTH_ARGS=(--ninstances 1000 --nworlds 100 --nedges 200 --npropositions 5
    --lsupports 0.05 0.10 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0
    --mingsupports 0.10 --nruns 1)

for t in "${THREADS_LIST[@]}"; do
    run "fpgrowth" "$t" "${FPGROWTH_ARGS[@]}"
done

# ---------------------------------------------------------------------------
# Eclat
# ---------------------------------------------------------------------------
ECLAT_ARGS=(--ninstances 1000 --nworlds 100 --nedges 200 --npropositions 10
    --lsupports 0.05 0.10 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0
    --mingsupports 0.10 --nruns 1)

for t in "${THREADS_LIST[@]}"; do
    run "eclat" "$t" "${ECLAT_ARGS[@]}"
done

echo "All benchmark runs completed."
