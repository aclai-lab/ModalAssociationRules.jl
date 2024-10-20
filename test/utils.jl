# Apriori and FPGrowth comparison on propositional case scenario

using Test
using ModalAssociationRules

p = ScalarCondition(VariableMin(1), >, -0.5)  |> Atom |> Item
q = ScalarCondition(VariableMin(2), <=, -2.2) |> Atom |> Item
r = ScalarCondition(VariableMin(3), >, -3.6)  |> Atom |> Item

arule = ARule(Itemset([p,q]), [r])

@test anchor_rulecheck(arule)
@test non_selfabsorbed_rulecheck(arule)
