#!/usr/bin/env bash

# status of the first failing command
set -uo pipefail

# Runs the three benchmark sweep scripts one after another:
#   1. benchmarking_ninstances_runner.sh    (dataset size sweep)
#   2. benchmarking_npropositions_runner.sh (number of propositions sweep)
#   3. benchmarking_threads_runner.sh       (thread count sweep)
#
# Each script only starts if the previous one finished successfully.
# If any script fails, this driver stops immediately and does NOT run
# the remaining ones.
#
# Logs for each script's own runs are handled by that script itself
# (under ./logs/); this driver just tracks overall pass/fail per script.

SCRIPTS=(
    "benchmarking_ninstances_runner.sh"
    "benchmarking_npropositions_runner.sh"
    "benchmarking_threads_runner.sh"
)

for script in "${SCRIPTS[@]}"; do
    echo "=============================================="
    echo ">>> Starting ${script}"
    echo "=============================================="

    if [ ! -f "$script" ]; then
        echo ">>> FAILED: ${script} not found in $(pwd)."
        exit 1
    fi

    bash "$script"
    status="$?"

    if [ "$status" -ne 0 ]; then
        echo ">>> FAILED: ${script} exited with status ${status}."
        echo ">>> Stopping — remaining scripts will NOT execute."
        exit "$status"
    fi

    echo ">>> Finished ${script} successfully."
    echo
done

echo "All benchmark scripts completed successfully."
