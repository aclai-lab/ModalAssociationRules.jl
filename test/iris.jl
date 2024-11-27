# Apriori and FPGrowth comparison on propositional case scenario

using Test
using ModalAssociationRules
using MLJ
using Random
using DataFrames

using SoleData: VariableMin, VariableMax

include("common.jl")

_X, y = @load_iris
X1 = DataFrame(hcat(values(_X)...), collect(keys(_X)))

X = scalarlogiset(X1;
    relations=AbstractRelation[],
    conditions=Vector{ScalarMetaCondition}(
        collect(Iterators.flatten([
            [ScalarMetaCondition(f, <=) for f in VariableMin.(1:4)],
            [ScalarMetaCondition(f, >=) for f in VariableMin.(1:4)],
            [ScalarMetaCondition(f, <=) for f in VariableMax.(1:4)],
            [ScalarMetaCondition(f, >=) for f in VariableMax.(1:4)],
        ]))
    )
)

_1_items = Vector{Item}(Atom.([
    ScalarCondition(VariableMin(1), >=,  5)
    ScalarCondition(VariableMin(2), <=,  4)
    ScalarCondition(VariableMin(3), <=,  4)
    ScalarCondition(VariableMin(4), <=,  2)
]))

# 1st comparison
_1_itemsetmeasures = [(gsupport, 0.8, 0.8)]
_1_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X, apriori, _1_items, _1_itemsetmeasures, _1_rulemeasures)
fpgrowth_miner = Miner(X, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)

compare_arules(apriori_miner, fpgrowth_miner)

# 2nd comparison
_2_itemsetmeasures = [(gsupport, 0.9, 0.4)]
_2_rulemeasures = [(gconfidence, 0.3, 0.5)]

apriori_miner = Miner(X, apriori, _1_items, _2_itemsetmeasures, _2_rulemeasures)
fpgrowth_miner = Miner(X, fpgrowth, _1_items, _2_itemsetmeasures, _2_rulemeasures)

compare_arules(apriori_miner, fpgrowth_miner)

# 3rd comparison
_3_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_3_rulemeasures = [(gconfidence, 0.1, 0.1)]

apriori_miner = Miner(X, apriori, _1_items, _3_itemsetmeasures, _3_rulemeasures)
fpgrowth_miner = Miner(X, fpgrowth, _1_items, _3_itemsetmeasures, _3_rulemeasures)

compare_arules(apriori_miner, fpgrowth_miner)


# Broken code (due to SoleData)

# X = scalarlogiset(X1)
# _1_items = Vector{Item}(Atom.([
#     ScalarCondition(VariableMin(1), >,  5.84)
#     ScalarCondition(VariableMin(1), >,  4.0)
#     ScalarCondition(VariableMin(2), <=, 3.05)
#     ScalarCondition(VariableMin(2), <=, 2.0)
#     ScalarCondition(VariableMin(3), <=, 3.75)
#     ScalarCondition(VariableMin(3), <=, 2.0)
#     ScalarCondition(VariableMin(4), <=, 1.19)
#     ScalarCondition(VariableMin(4), <=, 0.0)
# ]))

# # The following has to be fixed in SoleData
# # could not find feature VariableMin: min[V1] in memoset of type
# # SoleData.DimensionalDatasets.UniformFullDimensionalLogiset ...
# fpgrowth_miner = Miner(X, fpgrowth, _1_items, _itemsetmeasures, _rulemeasures)
# @test_broken mine!(fpgrowth_miner)

# this can't work, since previous test is broken and mining fails
# freqitems(fpgrowth_miner)
# patt = freqitems(fpgrowth_miner)[10]
# check(patt |> formula |> tree, X) |> sum
# fpgrowth_miner.globalmemo[(:gsupport, patt)]
