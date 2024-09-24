include("natops-benchmark-header.jl")

println("Apriori elapsed benchmark:")

apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
apriori_runtime_no_logiset_optimizations = @elapsed mine!(apriori_miner)
println("mining on fresh logiset -\t$(apriori_runtime_no_logiset_optimizations)s")

# Repeat to see how performance improves when leveraging dataset memoization structures
# apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
# apriori_runtime_with_logiset_optimizations = @elapsed mine!(apriori_miner)
# println("leveraging logiset memo -\t$(apriori_runtime_with_logiset_optimizations)")
