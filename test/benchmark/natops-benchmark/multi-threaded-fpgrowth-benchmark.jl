include("natops-benchmark-header.jl")

println("\nParallel ModalFP-Growth benchmark:")

_nthreads = Threads.nthreads()
println("threads number: $(_nthreads)")

# repeat measure to discard compilation time
fpgrowth_miner = Miner(deepcopy(X), fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_runtime_parallel_logiset_optimizations = @elapsed mine!(fpgrowth_miner)

fpgrowth_miner = Miner(deepcopy(X), fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_runtime_parallel_logiset_optimizations = @elapsed mine!(fpgrowth_miner)

# Profiling parallel code can be tricky...
# maybe look at: https://www.youtube.com/watch?v=B7ZlScN_rk8
# @profilehtml mine!(fpgrowth_miner)

println("mining on fresh logiset -\t$(fpgrowth_runtime_parallel_logiset_optimizations)s")

# Repeat to see how performance improves when leveraging dataset memoization structures
# fpgrowth_runtime_parallel_logiset_optimizations = @elapsed mine!(fpgrowth_miner)
# println("mining on fresh logiset -\t$(fpgrowth_runtime_parallel_logiset_optimizations)s")
