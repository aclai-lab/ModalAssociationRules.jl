using Test

# using SoleLogics
# using SoleModels
using SoleRules
using StatsBase

# Association rule extraction algorithms test suite

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

# Make an association rule miner wrapping Apriori algorithm
@test_nowarn miner = ARuleMiner(X, apriori(), alphabet)
