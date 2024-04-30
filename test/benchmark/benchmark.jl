using BenchmarkTools

using SoleRules
using SoleData
using StatsBase

"""
Given a Miner, print two runtimes:
the former is the time elapsed to mine all frequent itemsets starting from a fresh Logiset
while the latter is the time elapsed to resolve the same task but leveraging the Logiset
internal memoization potential.
"""
function runtimes(miner::Miner, X::D, algoname::String) where {D<:AbstractDataset}
    X2 = deepcopy(X)
    miner2 = deepcopy(miner)
    miner2.dataset = X2

    runtime_no_optimizations = @elapsed mine!(miner)

    # X2 internal memoization structures are now filled,
    # let's see how much time is improved.
    runtime_already_used_dataset = @elapsed mine!(miner2)

    println("$(algoname) runtime:")
    println("\t no optimizations: ", runtime_no_optimizations)
    println("\t keeping previous dataset: ", runtime_already_used_dataset)
end

# load NATOPS dataset and convert it to a Logiset
X_df, y = SoleData.load_arff_dataset("NATOPS");
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies
X2 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(UnivariateMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# set meaningfulness measures, for both mining frequent itemsets and establish which
# combinations of them are association rules.
_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

############################################################################################
#### Benchmarking ##########################################################################
############################################################################################

# Apriori runtime with no optimizations and leveraging dataset memoization
apriori_miner = Miner(X1, apriori(), manual_items, _itemsetmeasures, _rulemeasures)
runtimes(apriori_miner, X1, "Apriori")

############################################################################################

# FPGrowth runtime with no optimizations and leveraging dataset Memoization
fpgrowth_miner = Miner(X2, fpgrowth(), manual_items, _itemsetmeasures, _rulemeasures)
runtimes(fpgrowth_miner, X2, "FPGrowth")
