include("natops-benchmark-header.jl")

println("Apriori elapsed benchmark:")

# repeat measure to discard compilation time
apriori_miner = Miner(deepcopy(X), apriori, manual_items, _itemsetmeasures, _rulemeasures)
apriori_runtime_no_logiset_optimizations = @elapsed mine!(apriori_miner)

apriori_miner = Miner(deepcopy(X), apriori, manual_items, _itemsetmeasures, _rulemeasures)
apriori_runtime_no_logiset_optimizations = @elapsed mine!(apriori_miner)

println("mining on fresh logiset -\t$(apriori_runtime_no_logiset_optimizations)s")

# repeat to see how performance improves when leveraging dataset memoization structures
# apriori_miner = Miner(X, apriori, manual_items, _itemsetmeasures, _rulemeasures)
# apriori_runtime_with_logiset_optimizations = @elapsed mine!(apriori_miner)
# println("leveraging logiset memo -\t$(apriori_runtime_with_logiset_optimizations)")
