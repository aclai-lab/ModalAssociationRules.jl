# Small tests about NATOPS, to help debugging modal fpgrowth implementation.
# Those tests are deprecated and will be removed,
# since now are included in natops.jl

using Test

using ModalAssociationRules
using SoleData
using StatsBase

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X1 = scalarlogiset(X_df)

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

manual_items = Vector{Item}([manual_r, manual_lq])

# set meaningfulness measures, for both mining frequent itemsets and establish which
# combinations of them are association rules.
lsupport_threshold = 0.1
gsupport_threshold = 0.1
_itemsetmeasures = [(gsupport, gsupport_threshold, lsupport_threshold)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

# make two miners: the first digs the search space using aprior, the second uses fpgrowth
apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)

mine!(apriori_miner)
mine!(fpgrowth_miner)

itap = Itemset{Item}([manual_p, manual_lp])
itfp = Itemset{Item}([manual_p, manual_lp])

for ninstance in 1:360
    try
        apriori_lsupp = apriori_miner.localmemo[(:lsupport, itap, ninstance)]
        fpgrowth_lsupp = fpgrowth_miner.localmemo[(:lsupport, itfp, ninstance)]

        if apriori_lsupp != fpgrowth_lsupp
            println("Different lsupp value for instance $(ninstance))")
            println("\tapriori:\t$(apriori_lsupp)")
            println("\tfpgrowth:\t$(fpgrowth_lsupp)")
        end
    catch e
        if isa(e, KeyError)
            apriori_lsupp_haskey =
                haskey(apriori_miner.localmemo, (:lsupport, itap, ninstance))
            fpgrowth_lsupp_haskey =
                haskey(fpgrowth_miner.localmemo, (:lsupport, itap, ninstance))

            apriori_lsupp = apriori_miner.localmemo[(:lsupport, itap, ninstance)]

            if apriori_lsupp > lsupport_threshold
                println("Missing informative lsupp entry: ")
                println("\tinstance $(ninstance);")
                println("\tapriori? $(apriori_lsupp_haskey);")
                println("\tfpgrowth? $(fpgrowth_lsupp_haskey);")
            end
        end
    end
end
