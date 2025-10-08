# fast copy-paste for REPL testing while developing

using ModalAssociationRules
using SoleData
using SoleData: VariableMin, VariableMax
using SoleData.Artifacts
using StatsBase

import ModalAssociationRules.children

############################################################################################
# Toy data to parametrize experiments

# load NATOPS dataset and convert it to a Logiset
X_df, y = load(NatopsLoader());
X_df_1_have_command = X_df[1:30, :]
X_df_short = ((x)->x[1:4]).(X_df)
X1 = scalarlogiset(X_df_short)

X_df_1_have_command = X_df[1:30, :]
X_1_have_command = scalarlogiset(X_df_1_have_command)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

manual_v2 = [
    Atom(ScalarCondition(VariableMin(4), >=, 1))
    Atom(ScalarCondition(VariableMin(4), >=, 1.8))
    Atom(ScalarCondition(VariableMin(5), >=, -0.5))
    Atom(ScalarCondition(VariableMax(6), >=, 0))
]
manual_v2_modal = vcat(
    manual_v2,
    (manual_v2)[1] |> diamond(IA_L)
) |> Vector{Item}


myitems = manual_items

N = 5
myitemcollection = ItemCollection{N,Item}(Item[
    Atom(ScalarCondition(VariableMin(i), <, 100.0)) # trivial alphabet
    for i in 1:N
])

m = Miner(
    X1,
    apriori,
    Vector(myitemcollection[]),
    UInt64,
    [(gsupport, 0.1, 0.1)],
    [(gconfidence, 0.0, 0.0)],
)
