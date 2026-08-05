#!/usr/bin/env bash

# status of the first failing command
set -uo pipefail

# Fixes threads=16 and lsupport=0.5, and varies --ninstances across, say,
# 10, 50, 100, 500, 1000 for Apriori, FPGrowth, and Eclat.
# Each run only starts if the previous one finished successfully.
#
# Usage: ./run_benchmarks_ninstances.sh
#
# Logs for each run are saved under ./logs/<algorithm>_ninstances_<N>.log

LOGDIR="logs"
mkdir -p "$LOGDIR"

THREADS=16
LSUPPORT=0.5
NINSTANCES_LIST=(10 50 100 200 400 600 800 1000)

run() {
    local algorithm="$1"
    local ninstances="$2"
    shift 2
    local logfile="${LOGDIR}/${algorithm}_ninstances_${ninstances}.log"

    echo "=============================================="
    echo ">>> Running ${algorithm} with ninstances=${ninstances} (threads=${THREADS}, lsupport=${LSUPPORT})"
    echo "=============================================="

    # ${PIPESTATUS[0]} gives julia's exit code specifically, not tee's,
    # even though the command is piped.
    julia +1.11 -t"${THREADS}" --project=. benchmark/benchmarking.jl "$@" \
        --ninstances "${ninstances}" --lsupports "${LSUPPORT}" \
        --gctrial true --savename "ninstances_${ninstances}" --algorithm "${algorithm}" --rng 9989 \
        2>&1 | tee "${logfile}"
    local status="${PIPESTATUS[0]}"

    if [ "$status" -ne 0 ]; then
        echo ">>> FAILED: ${algorithm} (ninstances=${ninstances}) exited with status ${status}."
        echo ">>> Stopping — remaining runs will NOT execute. See ${logfile} for details."
        exit "$status"
    fi

    echo ">>> Finished ${algorithm} (ninstances=${ninstances}) successfully. Log: ${logfile}"
    echo
}

# Common args shared by every run (everything except --ninstances and --lsupports,
# which are fixed/varied above).
COMMON_ARGS=(--nworlds 50 --nedges 100 --npropositions 10 --mingsupports 0.1)

# ---------------------------------------------------------------------------
# Apriori
# ---------------------------------------------------------------------------
for n in "${NINSTANCES_LIST[@]}"; do
    run "apriori" "$n" "${COMMON_ARGS[@]}" --nruns 10
done

# ---------------------------------------------------------------------------
# FPGrowth
# ---------------------------------------------------------------------------
for n in "${NINSTANCES_LIST[@]}"; do
    run "fpgrowth" "$n" "${COMMON_ARGS[@]}" --nruns 1
done

# ---------------------------------------------------------------------------
# Eclat
# ---------------------------------------------------------------------------
for n in "${NINSTANCES_LIST[@]}"; do
    run "eclat" "$n" "${COMMON_ARGS[@]}" --nruns 1
done

echo "All benchmark runs completed."
