#!/usr/bin/env bash

# status of the first failing command
set -uo pipefail

# Note: we deliberately do NOT use "set -e" here — the run() function below
# checks each command's exit status explicitly and stops the whole script
# the moment one fails, which is more robust than relying on -e across a
# piped `tee` command.

# Runs all Apriori / FPGrowth / Eclat benchmark configurations, one after another,
# across thread counts 1, 2, 4, 8, 16, with local support FIXED at 0.5, dataset
# size (--ninstances) FIXED at 1000, and the number of propositions
# (--npropositions) swept across a range.
#
# Logs for each run are saved under ./logs/<algorithm>_threads_<N>_npropositions_<M>.log

LOGDIR="logs"
mkdir -p "$LOGDIR"

run() {
    local algorithm="$1"
    local threads="$2"
    local npropositions="$3"
    shift 3
    local logfile="${LOGDIR}/${algorithm}_threads_${threads}_npropositions_${npropositions}.log"

    echo "=============================================="
    echo ">>> Running ${algorithm} with ${threads} thread(s), npropositions=${npropositions}"
    echo "=============================================="

    # ${PIPESTATUS[0]} gives julia's exit code specifically, not tee's,
    # even though the command is piped.
    julia +1.11 -t"${threads}" --project=. benchmark/benchmarking.jl "$@" \
        --npropositions "${npropositions}" \
        --gctrial true --savename "threads_${threads}_npropositions_${npropositions}" \
        --algorithm "${algorithm}" --rng 9989 \
        2>&1 | tee "${logfile}"
    local status="${PIPESTATUS[0]}"

    if [ "$status" -ne 0 ]; then
        echo ">>> FAILED: ${algorithm} (${threads} threads, npropositions=${npropositions}) exited with status ${status}."
        echo ">>> Stopping — remaining runs will NOT execute. See ${logfile} for details."
        exit "$status"
    fi

    echo ">>> Finished ${algorithm} (${threads} threads, npropositions=${npropositions}) successfully. Log: ${logfile}"
    echo
}

THREADS_LIST=(16)

# Number of propositions to sweep over.
# Adjust this list to change the granularity of the sweep.
NPROPOSITIONS_LIST=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)

# ---------------------------------------------------------------------------
# Apriori
# ---------------------------------------------------------------------------
APRIORI_ARGS=(--ninstances 1000 --nworlds 100 --nedges 200
    --lsupports 0.5 --mingsupports 0.10 --nruns 1)

for t in "${THREADS_LIST[@]}"; do
    for p in "${NPROPOSITIONS_LIST[@]}"; do
        run "apriori" "$t" "$p" "${APRIORI_ARGS[@]}"
    done
done

# ---------------------------------------------------------------------------
# FPGrowth
# ---------------------------------------------------------------------------
FPGROWTH_ARGS=(--ninstances 1000 --nworlds 100 --nedges 200
    --lsupports 0.5 --mingsupports 0.10 --nruns 1)

for t in "${THREADS_LIST[@]}"; do
    for p in "${NPROPOSITIONS_LIST[@]}"; do
        run "fpgrowth" "$t" "$p" "${FPGROWTH_ARGS[@]}"
    done
done

# ---------------------------------------------------------------------------
# Eclat
# ---------------------------------------------------------------------------
ECLAT_ARGS=(--ninstances 1000 --nworlds 100 --nedges 200
    --lsupports 0.5 --mingsupports 0.10 --nruns 1)

for t in "${THREADS_LIST[@]}"; do
    for p in "${NPROPOSITIONS_LIST[@]}"; do
        run "eclat" "$t" "$p" "${ECLAT_ARGS[@]}"
    done
done

echo "All benchmark runs completed."
