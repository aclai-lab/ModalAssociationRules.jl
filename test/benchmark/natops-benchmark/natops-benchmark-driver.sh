#!/bin/sh

PROJECT_DIR="../../../"

julia --project="${PROJECT_DIR}" apriori-benchmark.jl
julia --project="${PROJECT_DIR}" serial-fpgrowth-benchmark.jl

for nthreads in $(seq 2 2 12); do
    julia -t"${nthreads}" --project="${PROJECT_DIR}" multi-threaded-fpgrowth-benchmark.jl
done
