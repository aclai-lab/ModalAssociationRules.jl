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

# meaningfulness measures, for both itemsets and rules
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

# define starting items
manual_items = Vector{Item}(Atom.([
    ScalarCondition(UnivariateMin(1), >=,  5)
    ScalarCondition(UnivariateMin(2), <=,  4)
    ScalarCondition(UnivariateMin(3), <=,  4)
    ScalarCondition(UnivariateMin(4), <=,  2)
]))

# initialize miner + extract frequent itemsets
fpgrowth_miner = Miner(X, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
mine!(fpgrowth_miner)

# sort frequent itemsets decreasingly by global support
sort!(freqitems(fpgrowth_miner),
    by=t -> globalmemo(fpgrowth_miner, (:gsupport,t)), rev=true)

# generate all the association rules
SoleRules.generaterules!(fpgrowth_miner) |> collect

# sort the association rules by global confidence
sort!(arules(fpgrowth_miner),
    by=t -> globalmemo(fpgrowth_miner, (:gconfidence,t)), rev=true)

for i in 1:4
    println("$(i) ->  minimum: $(X1[!,i] |> minimum) | mean: $(X1[!,i] |> mean) " *
        "| maximum: $(X1[!,i] |> maximum)")
end

# list and analyze each association rule
for rule in arules(fpgrowth_miner)
    println("")
    SoleRules.analyze(rule, fpgrowth_miner)
end
