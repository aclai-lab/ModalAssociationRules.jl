using Test

using ModalAssociationRules
using SoleData
using SoleData: VariableMin, VariableMax
using StatsBase

import ModalAssociationRules.children

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X1 = scalarlogiset(X_df)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

_1_items = Vector{Item}([manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])
_1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_1_rulemeasures = [(gconfidence, 0.2, 0.2)]

fpgrowth_miner = Miner(X1, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)

@time mine!(fpgrowth_miner; parallel=true)
