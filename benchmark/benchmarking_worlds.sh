#!/usr/bin/env bash
# status of the first failing command
set -uo pipefail
# Note: we deliberately do NOT use "set -e" here — the run() function below
# checks each command's exit status explicitly and stops the whole script
# the moment one fails, which is more robust than relying on -e across a
# piped `tee` command.
# Runs all Apriori / FPGrowth / Eclat benchmark configurations, one after another,
# with threads fixed at 16, across several (nworlds, nedges) pairs. Each run
# only starts if the previous one finished successfully and, otherwise, the
# script stops immediately.
#
# Logs for each run are saved under ./logs/<algorithm>_worlds_<W>_edges_<E>.log
LOGDIR="logs"
mkdir -p "$LOGDIR"

THREADS=16

run() {
    local algorithm="$1"
    local worlds="$2"
    local edges="$3"
    shift 3
    local logfile="${LOGDIR}/${algorithm}_worlds_${worlds}_edges_${edges}.log"
    echo "=============================================="
    echo ">>> Running ${algorithm} with nworlds=${worlds}, nedges=${edges} (${THREADS} threads)"
    echo "=============================================="
    # ${PIPESTATUS[0]} gives julia's exit code specifically, not tee's,
    # even though the command is piped.
    julia +1.11 -t"${THREADS}" --project=. benchmark/benchmarking.jl "$@" \
        --nworlds "${worlds}" --nedges "${edges}" \
        --gctrial true --savename "worlds_${worlds}_edges_${edges}" --algorithm "${algorithm}" --rng 9989 \
        2>&1 | tee "${logfile}"
    local status="${PIPESTATUS[0]}"
    if [ "$status" -ne 0 ]; then
        echo ">>> FAILED: ${algorithm} (nworlds=${worlds}, nedges=${edges}) exited with status ${status}."
        echo ">>> Stopping — remaining runs will NOT execute. See ${logfile} for details."
        exit "$status"
    fi
    echo ">>> Finished ${algorithm} (nworlds=${worlds}, nedges=${edges}) successfully. Log: ${logfile}"
    echo
}

# (nworlds, nedges) pairs to iterate over
WORLD_EDGE_PAIRS=(
    "50 100"
    "100 200"
    "200 400"
    "300 600"
    "400 800"
    "500 1000"
)

# ---------------------------------------------------------------------------
# Apriori
# ---------------------------------------------------------------------------
APRIORI_ARGS=(--ninstances 1000 --npropositions 5
    --lsupports 0.2 0.25 0.3 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.7 0.75 0.80 0.85 0.90 0.95 1.0
    --mingsupports 0.10 --nruns 1)
for pair in "${WORLD_EDGE_PAIRS[@]}"; do
    read -r w e <<< "$pair"
    run "apriori" "$w" "$e" "${APRIORI_ARGS[@]}"
done

# ---------------------------------------------------------------------------
# FPGrowth
# ---------------------------------------------------------------------------
FPGROWTH_ARGS=(--ninstances 1000 --npropositions 5
    --lsupports 0.05 0.10 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0
    --mingsupports 0.10 --nruns 1)
for pair in "${WORLD_EDGE_PAIRS[@]}"; do
    read -r w e <<< "$pair"
    run "fpgrowth" "$w" "$e" "${FPGROWTH_ARGS[@]}"
done

# ---------------------------------------------------------------------------
# Eclat
# ---------------------------------------------------------------------------
ECLAT_ARGS=(--ninstances 1000 --npropositions 5
    --lsupports 0.05 0.10 0.15 0.20 0.25 0.3 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0
    --mingsupports 0.10 --nruns 1)
for pair in "${WORLD_EDGE_PAIRS[@]}"; do
    read -r w e <<< "$pair"
    run "eclat" "$w" "$e" "${ECLAT_ARGS[@]}"
done

echo "All benchmark runs completed."


