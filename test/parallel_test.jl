# Apriori and FPGrowth comparison on multiple parametrizations
using Test

using ModalAssociationRules
using SoleData
using SoleData: VariableMin, VariableMax
using StatsBase

import ModalAssociationRules.children

if Threads.nthreads() == 1
    printstyled("Skipping check on parallel ModalFP-Growth." *
        "\nDid you forget to set -t?\n", color=:light_red)
end

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies,
# and deepcopies must be produced now.
X2 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# check if global support coincides for each frequent itemset
function isequal_gsupp(miner1::Miner, miner2::Miner)
    for itemset in freqitems(miner1)
        @test miner1.gmemo[(:gsupport, itemset)] == miner2.gmemo[(:gsupport, itemset)]
    end
end

# check if local support coincides for each frequent itemset
function isequal_lsupp(miner1::Miner, miner2::Miner)
    for itemset in freqitems(miner1)
        for ninstance in 1:(miner1 |> data |> ninstances)
            miner1_lsupp = get(miner1.lmemo, (:lsupport, itemset, ninstance), -1.0)
            miner2_lsupp = get(miner2.lmemo, (:lsupport, itemset, ninstance), -1.0)

            if miner1_lsupp == -1.0 || miner2_lsupp == -1.0
                # this is fine, and doesn't imply the two algorithms are different.
                # the fact is that, from an operative standpoint of view,
                # fpgrowth may avoid computing local support on certain instances.
                # Example: (:lsupport, [min[V1] > -0.5, min[V3] > -3.6], 3) is never
                # computed by fpgrowth, since it already knows that one of the two item is
                # not frequent enough on instance #3
                # (instead, apriori has to explore this path).
                continue
            elseif miner1_lsupp != miner2_lsupp
                print("Debug print: failed test for itemset $(itemset) at " *
                      " instance $(ninstance)")
            end

            @test miner1_lsupp == miner2_lsupp
        end
    end
end

function compare_freqitems(miner1::Miner, miner2::Miner)
    if !info(miner1, :istrained)
        mine!(miner1)
    end

    if !info(miner2, :istrained)
        mine!(miner2)
    end

    miner1_freqs = freqitems(miner1)
    miner2_freqs = freqitems(miner2)

    # check if generated frequent itemsets are the same
    @test length(miner1_freqs) == length(miner2_freqs)
    @test all(item -> item in miner1_freqs, miner2_freqs)

    isequal_gsupp(miner1, miner2)
    isequal_lsupp(miner1, miner2)

    isequal_gsupp(miner2, miner1)
    isequal_lsupp(miner2, miner1)
end

# utility to compare arules between miners;
# see compare_arules
function _compare_arules(miner1::Miner, miner2::Miner, rule::ARule)
    # global confidence comparison;
    # here it is implied that rules are already generated using generaterules!
    @test miner1.gmemo[(:gconfidence, rule)] == miner2.gmemo[(:gconfidence, rule)]

    # local confidence comparison;
    for ninstance in miner1 |> data |> ninstances
        lconfidence(rule, SoleLogics.getinstance(data(miner1), ninstance), miner1)
        lconfidence(rule, SoleLogics.getinstance(data(miner2), ninstance), miner2)

        @test miner1.lmemo[(:lconfidence, rule, ninstance)] ===
              miner2.lmemo[(:lconfidence, rule, ninstance)]
    end
end

# driver to compare arules between miners
function compare_arules(miner1::Miner, miner2::Miner)
    generaterules!(miner1) |> collect
    generaterules!(miner2) |> collect

    @test length(arules(miner1)) == length(arules(miner2))

    for rule in arules(miner1)
        @test rule in arules(miner2)
        _compare_arules(miner1, miner2, rule)
    end
end

# perform comparison
function compare(miner1::Miner, miner2::Miner)
    compare_freqitems(miner1, miner2)
    compare_arules(miner1, miner2)
end

# 1st comparison: FP-Growth vs its multithreaded variation
if Threads.nthreads() > 1
    _1_items = Vector{Item}([manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])
    _1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
    _1_rulemeasures = [(gconfidence, 0.2, 0.2)]

    fpgrowth_miner = Miner(X1, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)
    parallel_fpgrowth_miner = Miner(
        X2, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)
    mine!(fpgrowth_miner)
    mine!(parallel_fpgrowth_miner; parallel=true)

    compare(fpgrowth_miner, parallel_fpgrowth_miner)
end
