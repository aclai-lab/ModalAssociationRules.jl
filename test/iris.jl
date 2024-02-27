using Test
using SoleRules
using MLJ
using Random
using DataFrames

_X, y = @load_iris
X1 = DataFrame(hcat(values(_X)...), collect(keys(_X)))
X = scalarlogiset(X1)

manual_items = Vector{Item}(Atom.([
    ScalarCondition(UnivariateMin(1), >,  5.84)
    ScalarCondition(UnivariateMin(1), >,  4.0)
    ScalarCondition(UnivariateMin(2), <=, 3.05)
    ScalarCondition(UnivariateMin(2), <=, 2.0)
    ScalarCondition(UnivariateMin(3), <=, 3.75)
    ScalarCondition(UnivariateMin(3), <=, 2.0)
    ScalarCondition(UnivariateMin(4), <=, 1.19)
    ScalarCondition(UnivariateMin(4), <=, 0.0)
]))

_item_meas = [(gsupport, 0.1, 0.1)]
_rule_meas = [(gconfidence, 0.2, 0.2)]

# could not find feature UnivariateMin: min[V1] in memoset of type
# SoleData.DimensionalDatasets.UniformFullDimensionalLogiset ...
fpgrowth_miner = Miner(X, fpgrowth, manual_items, _item_meas, _rule_meas)
@test_broken mine(fpgrowth_miner)

X = scalarlogiset(X1; relations = AbstractRelation[], conditions =
    Vector{ScalarMetaCondition}(
        collect(Iterators.flatten([
            [ScalarMetaCondition(f, >) for f in UnivariateMin.(1:4)],
            [ScalarMetaCondition(f, <=) for f in UnivariateMin.(1:4)],
        ]))
    )
)

# this can't work, since previous test is broken and mining fails
# freqitems(fpgrowth_miner)
# patt = freqitems(fpgrowth_miner)[10]
# check(patt |> toformula |> tree, X) |> sum
# fpgrowth_miner.gmemo[(:gsupport, patt)]

manual_items = Vector{Item}(Atom.([
    ScalarCondition(UnivariateMin(1), >,  5.84)
    ScalarCondition(UnivariateMin(1), >,  5.84)
]))

fpgrowth_miner = Miner(X, fpgrowth, manual_items, _item_meas, _rule_meas)
mine(fpgrowth_miner)

@test freqitems(fpgrowth_miner) |> length == 1
