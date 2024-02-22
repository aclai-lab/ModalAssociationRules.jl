using BenchmarkTools

using SoleRules
using SoleData
using StatsBase

"""
Print two runtimes.
The first one considers a new miner, with a fresh logiset.
The second one considers a new miner, but the same old logiset, and, thus,
its internal memoization.
"""
function runtimes(miner::ARuleMiner, X::D, algoname::String) where {D<:AbstractDataset}
    X2 = deepcopy(X)
    miner2 = deepcopy(miner)
    miner2.dataset = X2

    runtime_no_optimizations = @elapsed mine(miner)
    runtime_already_used_dataset = @elapsed mine(miner2)

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
_item_meas = [(gsupport, 0.1, 0.1)]
_rule_meas = [(gconfidence, 0.2, 0.2)]

############################################################################################
#### Benchmarking ##########################################################################
############################################################################################

# Apriori runtime with no optimizations and leveraging dataset memoization
apriori_miner = ARuleMiner(X1, apriori(), manual_items, _item_meas, _rule_meas)
runtimes(apriori_miner, X1, "Apriori")

############################################################################################

# FPGrowth runtime with no optimizations and leveraging dataset Memoization
fpgrowth_miner = @equip_contributors ARuleMiner(
    X2, fpgrowth(), manual_items, _item_meas, _rule_meas)
runtimes(fpgrowth_miner, X2, "FPGrowth")

############################################################################################
#### Naive strategy ########################################################################
############################################################################################

# ARuleMiner implemented with naive typization instead of using parametric types
module NaiveBenchmark
    using FunctionWrappers: FunctionWrapper
    using SoleData
    using SoleLogics
    using SoleBase

    using SoleRules: ARule, GmeasMemo, Item, Itemset, LmeasMemo, MeaningfulnessMeasure,
        MiningAlgo

    struct ARuleMiner
        # target dataset
        X::AbstractDataset
        # algorithm used to perform extraction
        algo::FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}
        items::Vector{Item}

        # meaningfulness measures
        item_constrained_measures::Vector{<:MeaningfulnessMeasure}
        rule_constrained_measures::Vector{<:MeaningfulnessMeasure}

        freqitems::Vector{Itemset}      # collected frequent itemsets
        arules::Vector{ARule}           # collected association rules

        lmemo::LmeasMemo                # local memoization structure
        gmemo::GmeasMemo                # global memoization structure
        info::NamedTuple                # general informations

        function ARuleMiner(
            X::AbstractDataset,
            algo::Function,
            items::Vector{<:Item},
            item_constrained_measures::Vector{<:MeaningfulnessMeasure},
            rule_constrained_measures::Vector{<:MeaningfulnessMeasure};
            info::NamedTuple = (;)
        )
            new(X, MiningAlgo(algo), unique(items),
                item_constrained_measures, rule_constrained_measures,
                Vector{Itemset}([]), Vector{ARule}([]),
                LmeasMemo(), GmeasMemo(), info
            )
        end

        function ARuleMiner(
            X::AbstractDataset,
            algo::Function,
            items::Vector{<:Item}
        )
            ARuleMiner(X, MiningAlgo(algo), items,
                [(gsupport, 0.1, 0.1)], [(gconfidence, 0.2, 0.2)]
            )
        end
    end
end #end of module

# renewing datasets
X1 = scalarlogiset(X_df)
X2 = deepcopy(X1)

# making new miners
apriori_miner = NaiveBenchmark.ARuleMiner(
    X1, apriori(), manual_items, _item_meas, _rule_meas)
fpgrowth_miner = @equip_contributors NaiveBenchmark.ARuleMiner(
    X2, fpgrowth(), manual_items, _item_meas, _rule_meas)

runtimes(apriori_miner, X1, "Apriori (ARuleMiner naive typization)")
runtimes(fpgrowth_miner, X2, "FPGrowth (ARuleMiner naive typization)")
