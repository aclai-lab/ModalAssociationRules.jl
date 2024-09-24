include("natops-benchmark-header.jl")

println("\nSerial FPGrowth benchmark:")

fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_runtime_no_logiset_optimizations = @elapsed mine!(fpgrowth_miner; parallel=false)
println("mining on fresh logiset -\t$(fpgrowth_runtime_no_logiset_optimizations)s")

# Repeat to see how performance improves when leveraging dataset memoization structures
# fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
# fpgrowth_runtime_with_logiset_optimizations = @elapsed mine!(fpgrowth_miner)
# println("leveraging logiset memo -\t$(fpgrowth_runtime_with_logiset_optimizations)")
