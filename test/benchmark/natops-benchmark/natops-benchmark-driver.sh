#!/bin/sh

if [ -z "$1" ]; then
    TARGET_DIR="/home/mauro/.julia/dev/ModalAssociationRules/test/benchmark/natops-benchmark/"
else 
    TARGET_DIR="$1"
fi

cd "$TARGET_DIR" || { echo "Directory $TARGET_DIR not found"; exit -1; }

if [ -z "$2" ]; then
    PROJECT_DIR="../../../"
else
    PROJECT_DIR="$2"
fi

# julia --project="${PROJECT_DIR}" apriori-benchmark.jl
julia --project="${PROJECT_DIR}" serial-fpgrowth-benchmark.jl

for nthreads in $(seq 2 2 12); do
    julia -t"${nthreads}" --project="${PROJECT_DIR}" multi-threaded-fpgrowth-benchmark.jl
done
