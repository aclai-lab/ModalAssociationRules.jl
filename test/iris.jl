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

_itemsetmeasures = [(gsupport, 0.8, 0.8)]
_rulemeasures = [(gconfidence, 0.7, 0.7)]

# could not find feature UnivariateMin: min[V1] in memoset of type
# SoleData.DimensionalDatasets.UniformFullDimensionalLogiset ...
fpgrowth_miner = Miner(X, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
@test_broken mine!(fpgrowth_miner)

X = scalarlogiset(X1; relations = AbstractRelation[], conditions =
    Vector{ScalarMetaCondition}(
        collect(Iterators.flatten([
            [ScalarMetaCondition(f, <=) for f in UnivariateMin.(1:4)],
            [ScalarMetaCondition(f, >=) for f in UnivariateMin.(1:4)],
            [ScalarMetaCondition(f, <=) for f in UnivariateMax.(1:4)],
            [ScalarMetaCondition(f, >=) for f in UnivariateMax.(1:4)],
        ]))
    )
)

# this can't work, since previous test is broken and mining fails
# freqitems(fpgrowth_miner)
# patt = freqitems(fpgrowth_miner)[10]
# check(patt |> toformula |> tree, X) |> sum
# fpgrowth_miner.gmemo[(:gsupport, patt)]

manual_items = Vector{Item}(Atom.([
    ScalarCondition(UnivariateMin(1), >=,  5.5)
    ScalarCondition(UnivariateMin(1), >=,  6.0)
    ScalarCondition(UnivariateMin(1), >=,  6.5)

    ScalarCondition(UnivariateMax(1), <=,  5.5)
    ScalarCondition(UnivariateMax(1), <=,  6.0)
    ScalarCondition(UnivariateMax(1), <=,  6.5)

    ScalarCondition(UnivariateMin(2), >=,  2.0)
    ScalarCondition(UnivariateMin(2), >=,  3.0)
    ScalarCondition(UnivariateMin(2), >=,  4.0)

    ScalarCondition(UnivariateMax(2), <=,  2.0)
    ScalarCondition(UnivariateMax(2), <=,  3.0)
    ScalarCondition(UnivariateMax(2), <=,  4.0)

    ScalarCondition(UnivariateMin(3), >=,  3.75)
    ScalarCondition(UnivariateMin(3), >=,  4.0)
    ScalarCondition(UnivariateMin(3), >=,  4.25)

    ScalarCondition(UnivariateMax(3), <=,  3.75)
    ScalarCondition(UnivariateMax(3), <=,  4.0)
    ScalarCondition(UnivariateMax(3), <=,  4.25)

    ScalarCondition(UnivariateMin(4), >=,  1.75)
    ScalarCondition(UnivariateMin(4), >=,  2.0)
    ScalarCondition(UnivariateMin(4), >=,  2.25)

    ScalarCondition(UnivariateMax(4), <=,  1.75)
    ScalarCondition(UnivariateMax(4), <=,  2.0)
    ScalarCondition(UnivariateMax(4), <=,  2.25)
]))

fpgrowth_miner = Miner(X, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
mine!(fpgrowth_miner)

@test freqitems(fpgrowth_miner) |> length == 21

sort!(freqitems(fpgrowth_miner),
    by=t -> globalmemo(fpgrowth_miner, (:gsupport,t)), rev=true)

sort!(arules(fpgrowth_miner),
    by=t -> globalmemo(fpgrowth_miner, (:gconfidence,t)), rev=true)

    for rule in arules(fpgrowth_miner)
    SoleRules.analyze(rule, fpgrowth_miner)
end
