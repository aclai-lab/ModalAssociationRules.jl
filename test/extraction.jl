using Test

# using SoleLogics
# using SoleModels
using SoleRules
using StatsBase

# Association rule extraction algorithms test suite
# Preamble

# Load NATOPS dataset and convert it to a Logiset
X_df, y = SoleModels.load_arff_dataset("NATOPS");
X = scalarlogiset(X_df)

# Make an alphabet manually
p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))

boxlater = box(IA_L)
diamondlater = diamond(IA_L)

lp = boxlater(p)
lq = diamondlater(q)

alphabet = Vector{Item}([p,q,lp,lq])

# Testing meaningfulness measures types
@test lsupport isa ItemLmeas
@test !(lsupport isa ItemGmeas)
@test !(lsupport isa RuleLmeas)
@test !(lsupport isa RuleGmeas)

@test gsupport isa ItemGmeas
@test !(gsupport isa ItemLmeas)
@test !(gsupport isa RuleLmeas)
@test !(gsupport isa RuleGmeas)

@test lconfidence isa RuleLmeas
@test !(lconfidence isa ItemLmeas)
@test !(lconfidence isa ItemGmeas)
@test !(lconfidence isa RuleGmeas)

@test gconfidence isa RuleGmeas
@test !(gconfidence isa ItemLmeas)
@test !(gconfidence isa ItemGmeas)
@test !(gconfidence isa RuleLmeas)

# Make an association rule miner wrapping Apriori algorithm
# Testing different ARuleMiner constructors
@test_nowarn miner = ARuleMiner(X, apriori(), alphabet)
@test_nowarn miner = ARuleMiner(X, apriori(), alphabet,
    [(gsupport, 0.14, 0.14)], [(gconfidence, 0.14, 0.14)])
