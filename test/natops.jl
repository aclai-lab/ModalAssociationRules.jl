# Apriori and FPGrowth comparison on multiple parametrizations
using Test

using ModalAssociationRules
using SoleData
using SoleData: VariableMin, VariableMax
using StatsBase

import ModalAssociationRules.children

if Threads.nthreads() == 1
    printstyled("Skipping check on parallel ModalFP-Growth." *
        "\nDid you forget to set -t?\n", color=:light_yellow)
end

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X_df_1_have_command = X_df[1:30, :]
X_df_short = ((x)->x[1:4]).(X_df)
X1 = scalarlogiset(X_df_short)

# different tested algorithms will use different Logiset's copies,
# and deepcopies must be produced now.
X2 = deepcopy(X1)
X3 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# 1st comparison: FP-Growth vs its multithreaded variation
_1_items = Vector{Item}([manual_p, manual_q, manual_lp, manual_lq])
_1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_1_rulemeasures = [(gconfidence, 0.2, 0.2)]

apriori_miner = Miner(X1, apriori, _1_items, _1_itemsetmeasures, _1_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

# checking for re-mining block
@test apply!(apriori_miner, data(apriori_miner)) |> collect |> length == 0
@test apply!(fpgrowth_miner, data(fpgrowth_miner)) |> collect |> length == 0

# 2nd comparisons: Apriori vs its multithreaded variation
_2_items = Vector{Item}([manual_p, manual_q, manual_r])
_2_itemsetmeasures = [(gsupport, 0.5, 0.7)]
_2_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X2, apriori, _2_items, _2_itemsetmeasures, _2_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _2_items, _2_itemsetmeasures, _2_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

# 3rd comparisons: FP-Growth vs its multithreaded variation
_3_items = Vector{Item}([manual_lp, manual_lq, manual_lr])
_3_itemsetmeasures = [(gsupport, 0.8, 0.8)]
_3_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X3, apriori, _3_items, _3_itemsetmeasures, _3_rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, _3_items, _3_itemsetmeasures, _3_rulemeasures)

compare(fpgrowth_miner, apriori_miner)

# 4th comparisons: Apriori vs FP-Growth
_4_items = Vector{Item}([manual_q, manual_r, manual_lp, manual_lr])
_4_itemsetmeasures = [(gsupport, 0.4, 0.4)]
_4_rulemeasures = [(gconfidence, 0.7, 0.7)]

apriori_miner = Miner(X2,
    apriori,
    _4_items,
    _4_itemsetmeasures,
    _4_rulemeasures;
    itemset_policies=Function[]
)
fpgrowth_miner = Miner(X2,
    fpgrowth,
    _4_items,
    _4_itemsetmeasures,
    _4_rulemeasures;
    itemset_policies=Function[]
)

compare(apriori_miner, fpgrowth_miner)

# 5th comparisons: Apriori vs FP-Growth
X_df_1_have_command = X_df[1:30, :]
X_1_have_command = scalarlogiset(X_df_1_have_command)

_5_items_prop = [
    Atom(ScalarCondition(VariableMin(4), >=, 1))
    Atom(ScalarCondition(VariableMin(4), >=, 1.8))
    Atom(ScalarCondition(VariableMin(5), >=, -0.5))
    Atom(ScalarCondition(VariableMax(6), >=, 0))
]

_5_items = vcat(
    _5_items_prop,
    (_5_items_prop)[1] |> diamond(IA_L)
) |> Vector{Item}

_5_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_5_rulemeasures = [(gconfidence, 0.1, 0.1)]

apriori_miner = Miner(X_1_have_command,
    apriori, _5_items, _5_itemsetmeasures, _5_rulemeasures)
fpgrowth_miner = Miner(X_1_have_command,
    fpgrowth, _5_items, _5_itemsetmeasures, _5_rulemeasures)

compare(apriori_miner, fpgrowth_miner)

arule = fpgrowth_miner |> arules |> first
@test_nowarn arule_analysis(arule, fpgrowth_miner; io=devnull, verbose=true)
@test_nowarn convert(Itemset, arule)

@test frame(fpgrowth_miner) isa SoleLogics.FullDimensionalFrame
@test allworlds(fpgrowth_miner) |> first isa SoleLogics.Interval
@test SoleLogics.frame(fpgrowth_miner) |> nworlds == 1326

@test haskey(ModalAssociationRules._lconfidence_logic(
    arule, data(fpgrowth_miner), 1, fpgrowth_miner), :measure)
@test haskey(ModalAssociationRules._gconfidence_logic(
    arule, data(fpgrowth_miner), 0.1, fpgrowth_miner), :measure)

# to certainly trigger a specific generated by @gmeas macro
@test_nowarn gconfidence(arule, data(fpgrowth_miner), 0.1, fpgrowth_miner)
@test_nowarn gconfidence(arule, data(fpgrowth_miner), 0.1, fpgrowth_miner)

my_bulldozer = Bulldozer(fpgrowth_miner, 1)
@test_nowarn datalock(my_bulldozer)
@test_nowarn memolock(my_bulldozer)
@test_nowarn miningstatelock(my_bulldozer)

@test_nowarn miningstate!(my_bulldozer, :myfield, Dict(42 => 24))
@test miningstate(my_bulldozer, :myfield, 42) == 24

# 6th comparisons: FP-Growth using new meaningfulness measures
_6_items = _5_items
_6_itemsetmeasures = [(gsupport, 0.5, 0.5)]

# the following measure thresholds have the only purpose of trigger code coverage
_6_rulemeasures = [
    (gconfidence, 0.5, 0.5),
    (glift, 0.5, 0.5),          # [-∞,+∞]
    (gconviction, 1.0, 1.0),    # [0,+∞]
    (gleverage, -0.25, -0.25),  # [-0.25,0.25]
]

fpgrowth_miner = Miner(X_1_have_command,
    fpgrowth, _6_items, _6_itemsetmeasures, _6_rulemeasures)

@test_nowarn mine!(fpgrowth_miner)

_7_items = _1_items
_7_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_7_rulemeasures = [(gconfidence, 0.0, 0.0)]
apriori_miner = Miner(
    deepcopy(X1),
    apriori,
    _7_items,
    _7_itemsetmeasures,
    _7_rulemeasures;
    itemset_policies=Function[]
)
fpgrowth_miner = Miner(
    deepcopy(X2),
    fpgrowth,
    _7_items,
    _7_itemsetmeasures,
    _7_rulemeasures;
    itemset_policies=Function[]
)

compare(apriori_miner, fpgrowth_miner)
