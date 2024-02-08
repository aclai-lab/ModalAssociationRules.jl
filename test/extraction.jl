using Test

using SoleRules
using SoleData
using StatsBase

# Association rule extraction algorithms test suite
# Preamble

# Load NATOPS dataset and convert it to a Logiset
X_df, y = load_arff_dataset("NATOPS");
X = scalarlogiset(X_df)

# Make an alphabet manually
manual_p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(UnivariateMin(3), >, -3.6))

boxlater = box(IA_L)
diamondlater = diamond(IA_L)

manual_lp = boxlater(manual_p)
manual_lq = diamondlater(manual_q)
manual_lr = boxlater(manual_r)

manual_alphabet = Vector{Item}([manual_p, manual_q, manual_r,
    manual_lp, manual_lq, manual_lr])

# Make an association rule miner wrapping Apriori algorithm
# Testing different ARuleMiner constructors
@test_nowarn miner = ARuleMiner(X, apriori(), manual_alphabet)

@test_nowarn miner = ARuleMiner(X, apriori(), manual_alphabet,
    [(gsupport, 0.14, 0.14)], [(gconfidence, 0.14, 0.14)])
# Mining using manually defined alphabet
miner = ARuleMiner(X, apriori(), manual_alphabet,
    [(gsupport, 0.14, 0.14)], [(gconfidence, 0.14, 0.14)])

@test dataset(miner) == X
@test algorithm(miner) == miner.algo
@test alphabet(miner) == manual_alphabet
@test freqitems(miner) == Itemset[]
@test nonfreqitems(miner) == Itemset[]
@test arules(miner) == ARule[]

@test_nowarn SoleRules.mine(miner)

# a = SoleRules.merge(miner.freq_itemsets[1], miner.freq_itemsets[2])
# @test combine()
# @test in between different types

# simple_p, simple_q, simple_r = Itemset.(Atom.(["p", "q", "r"]))

# @test powerset
