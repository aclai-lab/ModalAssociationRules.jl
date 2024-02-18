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

_item_meas = [(gsupport, 0.1, 0.1)]
_rule_meas = [(gconfidence, 0.2, 0.2)]

apriori_miner = ARuleMiner(X, apriori(), manual_alphabet, _item_meas, _rule_meas)
fpgrowth_miner = @equip_contributors ARuleMiner(
    X, fpgrowth(), manual_alphabet, _item_meas, _rule_meas)

# mine the frequent patterns with both apriori and fpgrowth
mine(apriori_miner)
mine(fpgrowth_miner)

@testset "ARuleMiner general checks" begin
    @test_nowarn ARuleMiner(X, apriori(), manual_alphabet)
    @test_nowarn algorithm(ARuleMiner(X, apriori(), manual_alphabet)) isa MiningAlgo

    @test items(ARuleMiner(X, apriori(), manual_alphabet)) == manual_alphabet

    @test item_meas(miner) == _item_meas
    @test rule_meas(miner) == _rule_meas

    @test length(freqitems(miner)) == 55
    @test length(nonfreqitems(miner)) == 0
    @test arules(miner) == []

    _temp_lmemo_key = (:lsupport, freqitems(miner)[1], 1)
    _temp_lmemo_val = localmemo(miner, _temp_lmemo_key)
    @test  _temp_lmemo_val >= 0.74 && _temp_lmemo_val <= 0.75
    @test localmemo(miner, (:lsupport, freqitems(miner)[1], 2)) == 1.0
    @test localmemo(miner, (:lsupport, freqitems(miner)[1], 4)) == 0.0

    @test_nowarn localmemo!(miner, _temp_lmemo_key, 0.5)
    @test localmemo(miner, _temp_lmemo_key) == 0.5

    _temp_gmemo_key = (:gsupport, freqitems(miner)[3])
    @test globalmemo(miner, _temp_gmemo_key) == 1.0

    @test_nowarn globalmemo!(miner, _temp_gmemo_key, 0.0)
    @test globalmemo(miner, _temp_gmemo_key) == 0.0

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

@testset "FP-Growth general checks (FPTree and HeaderTable)" begin
    root = FPTree()
    @test root isa FPTree
    @test content(root) === nothing
    @test children(root) == FPTree[]
    @test contributors(root) == Int64[]
    @test count(root) == 0
    @test link(root) === nothing
end

@testset "Apriori and FPGrowth comparisons"
    apriori_freqs = freqitems(apriori_miner)
    fpgrowth_freqs = freqitems(fpgrowth_miner)

    @test length(apriori_freqs) == length(fpgrowth_freqs)
    @test all(t -> t==1, [freqitemset in fpgrowth_freqs for freqitemset in apriori_freqs])
@end
