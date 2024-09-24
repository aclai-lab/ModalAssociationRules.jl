include("natops-benchmark-header.jl")

println("\nParallel ModalFP-Growth benchmark:")

_nthreads = Threads.nthreads()
println("threads number: $(_nthreads)")

fpgrowth_miner = Miner(X3, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_runtime_parallel_logiset_optimizations = @elapsed mine!(fpgrowth_miner)
println("mining on fresh logiset -\t$(fpgrowth_runtime_parallel_logiset_optimizations)s")

# Repeat to see how performance improves when leveraging dataset memoization structures
# fpgrowth_runtime_parallel_logiset_optimizations = @elapsed mine!(fpgrowth_miner)
# println("mining on fresh logiset -\t$(fpgrowth_runtime_parallel_logiset_optimizations)s")
