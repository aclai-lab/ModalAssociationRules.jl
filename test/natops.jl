# Apriori and FPGrowth comparison on multiple parametrizations
using Test

using ModalAssociationRules
using SoleData
using StatsBase

import ModalAssociationRules.children

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies,
# and deepcopies must be produced now.
X2 = deepcopy(X1)
X3 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(UnivariateMin(3), >, -3.6))

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
        for ninstance in 1:(miner1 |> dataset |> ninstances)
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
    mine!(miner1)
    mine!(miner2)

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
    for ninstance in miner1 |> dataset |> ninstances
        lconfidence(rule, SoleLogics.getinstance(dataset(miner1), ninstance), miner1)
        lconfidence(rule, SoleLogics.getinstance(dataset(miner2), ninstance), miner2)

        @test miner1.lmemo[(:lconfidence, rule, ninstance)] ==
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

# 1st comparison
# print("Debug print: comparison #1\n")

_1_items = Vector{Item}([manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])
_1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_1_rulemeasures = [(gconfidence, 0.2, 0.2)]

apriori_miner = Miner(X2, apriori, _1_items, _1_itemsetmeasures, _1_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

# checking for re-mining block
@test apply!(apriori_miner, dataset(apriori_miner)) == Nothing
@test apply!(fpgrowth_miner, dataset(fpgrowth_miner)) == Nothing

# 2nd comparison
# print("Debug print: comparison #2\n")

_2_items = Vector{Item}([manual_p, manual_q, manual_r])
_2_itemsetmeasures = [(gsupport, 0.5, 0.7)]
_2_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X2, apriori, _2_items, _2_itemsetmeasures, _2_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _2_items, _2_itemsetmeasures, _2_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

# 3rd comparisons
# print("Debug print: comparison #3\n")

_3_items = Vector{Item}([manual_lp, manual_lq, manual_lr])
_3_itemsetmeasures = [(gsupport, 0.8, 0.8)]
_3_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X2, apriori, _3_items, _3_itemsetmeasures, _3_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _3_items, _3_itemsetmeasures, _3_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

# 4th comparisons
# print("Debug print: comparison #4\n")

_4_items = Vector{Item}([manual_q, manual_r, manual_lp, manual_lr])
_4_itemsetmeasures = [(gsupport, 0.4, 0.4)]
_4_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X2, apriori, _4_items, _4_itemsetmeasures, _4_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _4_items, _4_itemsetmeasures, _4_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

# 5th comparisons
# print("Debug print: comparison #5\n)

X_df_1_have_command = X_df[1:30, :]
X_1_have_command = scalarlogiset(X_df_1_have_command)

_5_items_prop = [
    Atom(ScalarCondition(UnivariateMin(4), >=, 1))
    Atom(ScalarCondition(UnivariateMin(4), >=, 1.8))
    Atom(ScalarCondition(UnivariateMin(5), >=, -0.5))
    Atom(ScalarCondition(UnivariateMax(6), >=, 0))
] |> Vector{Item}
_5_items = vcat(
    _5_items_prop,
    diamond(IA_L).(_5_items_prop)[1]
) |> Vector{Formula}

_5_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_5_rulemeasures = [(gconfidence, 0.1, 0.1)]

apriori_miner = Miner(X_1_have_command,
    apriori, _5_items, _5_itemsetmeasures, _5_rulemeasures)
fpgrowth_miner = Miner(X_1_have_command,
    fpgrowth, _5_items, _5_itemsetmeasures, _5_rulemeasures)

compare(apriori_miner, fpgrowth_miner)
