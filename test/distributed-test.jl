# This lightweight test is designed to leverage ModalFP-Growth multi-processing implementation.
# Extracting rules from the entire NATOPS dataset on a 16GB laptop inevitably led to crash
# because of RAM saturation.

# New worker processes are NOT set within this script, hence, remember to set them while
# executing, by setting a -p flag.

using Test

using ModalAssociationRules
using SoleData
using SoleData: VariableMin, VariableMax
using StatsBase

import ModalAssociationRules.children

# load NATOPS
X_df, y = load_NATOPS();
X1 = scalarlogiset(X_df)

# parametrize the Miner
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)

items = Vector{Item}([manual_p, manual_q, manual_lp, manual_lq])
itemsetmeasures = [(gsupport, 0.1, 0.1)]
rulemeasures = [(gconfidence, 0.2, 0.2)]

fpgrowth_miner = Miner(X1, fpgrowth, items, itemsetmeasures, rulemeasures)

@time mine!(fpgrowth_miner)
