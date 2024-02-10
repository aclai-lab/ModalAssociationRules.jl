# Association rule extraction algorithms test suite
using Test

using SoleRules
using SoleData
using StatsBase

# preamble

# load NATOPS dataset and convert it to a Logiset
X_df, y = SoleData.load_arff_dataset("NATOPS");
X = scalarlogiset(X_df)

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

@testset "ARuleMiner" begin
    @test_nowarn ARuleMiner(X, apriori(), manual_alphabet)
    @test_nowarn algorithm(ARuleMiner(X, apriori(), manual_alphabet)) isa MiningAlgo

    @test alphabet(ARuleMiner(X, apriori(), manual_alphabet)) == manual_alphabet

    _item_meas = [(gsupport, 0.1, 0.1)]
    _rule_meas = [(gconfidence, 0.2, 0.2)]
    miner = ARuleMiner(X, apriori(), manual_alphabet, _item_meas, _rule_meas)

    @test item_meas(miner) == _item_meas
    @test rule_meas(miner) == _rule_meas

    # mine the frequent patterns
    mine(miner)

    @test length(freqitems(miner)) == 55
    @test length(nonfreqitems(miner)) == 4
    @test arules(miner) == []

    _temp_lmemo_key = (:lsupport, freqitems(miner)[1], 1)
    _temp_lmemo_val = getlocalmemo(miner, _temp_lmemo_key)
    @test  _temp_lmemo_val >= 0.74 && _temp_lmemo_val <= 0.75
    @test getlocalmemo(miner, (:lsupport, freqitems(miner)[1], 2)) == 1.0
    @test getlocalmemo(miner, (:lsupport, freqitems(miner)[1], 4)) == 0.0

    @test_nowarn setlocalmemo(miner, _temp_lmemo_key, 0.5)
    @test getlocalmemo(miner, _temp_lmemo_key) == 0.5

    _temp_gmemo_key = (:gsupport, freqitems(miner)[3])
    @test getglobalmemo(miner, _temp_gmemo_key) == 1.0

    @test_nowarn setglobalmemo(miner, _temp_gmemo_key, 0.0)
    @test getglobalmemo(miner, _temp_gmemo_key) == 0.0

    for _temp_arule in arules_generator(freqitems(miner), miner)
        @test _temp_arule in arules(miner)
        @test _temp_arule isa ARule
    end
end

@testset "Meaningfulness measures" begin
    @test islocalof(lsupport, lsupport) == false
    @test islocalof(lsupport, gsupport) == true
    @test islocalof(lsupport, lconfidence) == false
    @test islocalof(lsupport, gconfidence) == false

    @test islocalof(gsupport, lsupport) == false
    @test islocalof(gsupport, gsupport) == false
    @test islocalof(gsupport, lconfidence) == false
    @test islocalof(gsupport, gconfidence) == false

    @test islocalof(lconfidence, lsupport) == false
    @test islocalof(lconfidence, gsupport) == false
    @test islocalof(lconfidence, lconfidence) == false
    @test islocalof(lconfidence, gconfidence) == true

    @test islocalof(gconfidence, lsupport) == false
    @test islocalof(gconfidence, gsupport) == false
    @test islocalof(gconfidence, lconfidence) == false
    @test islocalof(gconfidence, gconfidence) == false

    @test isglobalof(lsupport, lsupport) == false
    @test isglobalof(lsupport, gsupport) == false
    @test isglobalof(lsupport, lconfidence) == false
    @test isglobalof(lsupport, gconfidence) == false

    @test isglobalof(gsupport, lsupport) == true
    @test isglobalof(gsupport, gsupport) == false
    @test isglobalof(gsupport, lconfidence) == false
    @test isglobalof(gsupport, gconfidence) == false

    @test isglobalof(lconfidence, lsupport) == false
    @test isglobalof(lconfidence, gsupport) == false
    @test isglobalof(lconfidence, lconfidence) == false
    @test isglobalof(lconfidence, gconfidence) == false

    @test isglobalof(gconfidence, lsupport) == false
    @test isglobalof(gconfidence, gsupport) == false
    @test isglobalof(gconfidence, lconfidence) == true
    @test isglobalof(gconfidence, gconfidence) == false
end

@testset "FP-Growth data structures (FPTree and HeaderTable)" begin
    # mine the frequent patterns
    mine(miner)

    fitemset = freqitems(miner)[1]

    root = FPTree()
    @test root isa FPTree
    @test content(root) === nothing
    @test children(root) == FPTree[]
    @test contributors(root) = 0
    @test count(root) == 0
    @test linkage(root) === nothing

end
