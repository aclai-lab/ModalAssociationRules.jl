# Association rule extraction algorithms test suite
using Test

using SoleRules
using SoleData
using StatsBase

# load NATOPS dataset and convert it to a Logiset
X_df, y = SoleData.load_arff_dataset("NATOPS");
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies
X2 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(UnivariateMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_alphabet = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# set meaningfulness measures, for both mining frequent itemsets and establish which
# combinations of them are association rules.
_item_meas = [(gsupport, 0.1, 0.1)]
_rule_meas = [(gconfidence, 0.2, 0.2)]

# make two miners: the first digs the search space using aprior, the second uses fpgrowth
apriori_miner = ARuleMiner(X1, apriori(), manual_alphabet, _item_meas, _rule_meas)
fpgrowth_miner = @equip_contributors ARuleMiner(
    X2, fpgrowth(), manual_alphabet, _item_meas, _rule_meas)

# mine the frequent patterns with both apriori and fpgrowth
mine(apriori_miner)
mine(fpgrowth_miner)

pq = Itemset([manual_p, manual_q])
qr = Itemset([manual_q, manual_r])
pr = Itemset([manual_p, manual_r])
pqr = Itemset([manual_p, manual_q, manual_r])

@testset "core.jl - fundamental types"
    @test Item <: Formula
    @test Itemset <: Vector{<:Item}
    @test Itemset(manual_p) == [manual_p]
    @test pq == [manual_p, manual_q]

    @test convert(Item, Itemset([manual_p])) == manual_p

    @test_throws MethodError convert(Item, [manual_p])
    @test_throws MethodError convert(Item, [manual_p, manual_q])
    @test_throws AssertionError convert(Item, pq)

    @test syntaxstring(manual_p) == "min[V1] > -0.5"
    @test syntaxstring(pq) == "[min[V1] > -0.5, min[V2] ≤ -2.2]"

    @test manual_p in pq
    @test pq in pqr
    @test !(pq in [manual_p, manual_q, manual_r])
    @test pq in [pq, pqr, qr]

    @test toformula(pq) isa LeftmostConjunctiveForm
    @test toformula(pq).children |> first == manual_p

    @test Threshold <: Float64
    @test WorldMask <: Vector{Int64}

    @test EnhancedItemset <: Vector{Tuple{Item,Int64,WorldMask}}
    enhanceditemset = convert(EnhancedItemset, pq, 42, 5)
    @test length(enhanceditemset) == 2
    @test enhanceditemset[1] isa Tuple
    @test enhanceditemset[1] |> first isa Item
    @test enhanceditemset[1][2] == 42
    @test enhanceditemset[1] |> last |> length == 5
    @test convert(Itemset, enhanceditemset) isa Itemset

    @test ConditionalPatternBase <: Vector{EnhancedItemset}

    @test_nowarn ARule(pq, Itemset(manual_r))
    arule = ARule(pq, Itemset(manual_r))
    @test content(arule) |> first == antecedent(arule)
    @test content(arule) |> last == consequent(arule)
    arule2 = ARule(qr, Itemset(manual_p))
    arule3 = ARule(Itemset([manual_q, manual_p]), Itemset(manual_r))

    @test arule != arule2
    @test arule == arule3

    @test_throws AssertionError ARule(qr, Itemset(manual_q))

    @test MeaningfulnessMeasure <: Tuple{Function,Threshold,Threshold}
    # see MeaningfulnessMeasure section for tests about islocalof and isglobalof

    @test ARMSubject <: Union{ARule,Itemset}
    @test LmeasMemoKey <: Tuple{Symbol,ARMSubject,Int64}
    @test LmeasMemo <: Dict{LmeasMemoKey,Threshold}
    @test Contributors <: Dict{LmeasMemoKey, WorldMask}
    @test GmeasMemoKey <: Tuple{Symbol,ARMSubject}
    @test GmeasMemo <: Dict{GmeasMemoKey,Threshold}
    @test MiningAlgo <: FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}
@end

@testset "core.jl - ARuleMiner" begin
    @test_nowarn ARuleMiner(X1, apriori(), manual_alphabet)
    @test_nowarn algorithm(ARuleMiner(X1, apriori(), manual_alphabet)) isa MiningAlgo

    @test dataset(apriori_miner) == X1
    @test algorithm(apriori_miner) isa MiningAlgo
    @test items(ARuleMiner(X1, apriori(), manual_alphabet)) == manual_alphabet

    @test item_meas(apriori_miner) == _item_meas
    @test rule_meas(apriori_miner) == _rule_meas

    @test length(freqitems(apriori_miner)) == 27
    @test arules(apriori_miner) == []

    _temp_lmemo_key = (:lsupport, freqitems(apriori_miner)[1], 1)
    _temp_lmemo_val = localmemo(apriori_miner, _temp_lmemo_key)
    @test  _temp_lmemo_val >= 0.74 && _temp_lmemo_val <= 0.75
    @test localmemo(apriori_miner, (:lsupport, freqitems(apriori_miner)[1], 2)) == 1.0
    @test localmemo(apriori_miner, (:lsupport, freqitems(apriori_miner)[1], 4)) == 0.0

    @test_nowarn localmemo!(apriori_miner, _temp_lmemo_key, 0.5)
    @test localmemo(apriori_miner, _temp_lmemo_key) == 0.5

    _temp_gmemo_key = (:gsupport, freqitems(apriori_miner)[3])
    @test globalmemo(apriori_miner, _temp_gmemo_key) == 1.0

    @test_nowarn globalmemo!(apriori_miner, _temp_gmemo_key, 0.0)
    @test globalmemo(apriori_miner, _temp_gmemo_key) == 0.0

    countdown = 3
    for _temp_arule in arules_generator(freqitems(apriori_miner), apriori_miner)
        if countdown > 0
            @test _temp_arule in arules(apriori_miner)
            @test _temp_arule isa ARule
        end
        countdown -= 1
    end

    _temp_lmemo_key2 = (:lsupport, Itemset(manual_p), 1)
    @test localmemo(apriori_miner) |> length == 11880
    @test localmemo(apriori_miner)[(:lsupport, pq, 1)] == 0.0
    _temp_lmemo_val2 = localmemo(apriori_miner)[_temp_lmemo_key2]
    @test _temp_lmemo_val2 > 0.17 && _temp_lmemo_val2 < 0.18

    @test info(apriori_miner) isa NamedTuple
    @test !(isequipped(apriori_miner, :contributors))
    @test isequipped(fpgrowth_miner, :contributors)
    @test info(fpgrowth_miner, :contributors) |> length 2160

    @test isequipped(@equip_contributors ARuleMiner(X1, apriori(), manual_alphabet),
        :contributors)

    @test contributors(_temp_lmemo_key2, fpgrowth_miner) |> length == 1326
    @test contributors(_temp_lmemo_key2, fpgrowth_miner) ==
        contributors(:lsupport, Itemset(manual_p), 1, fpgrowth_miner)
    @test contributors(_temp_lmemo_key2, fpgrowth_miner) |> sum == 104545
    @test_throws ErrorException contributors!(
        apriori_miner, _temp_lmemo_key2, zeros(Int64, 1326))
    @test contributors!(
        fpgrowth_miner, _temp_lmemo_key2, zeros(Int64, 1326)) == zeros(Int64, 1326)

    @test_nowarn apply(fpgrowth_miner, dataset(fpgrowth_miner))
end

@testset "meaningfulness-measures.jl" begin
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

    @test lsupport(pq, SoleLogics.getinstance(X2, 1); miner=fpgrowth_miner) == 0.0

    _temp_lsupport = lsupport(pq, SoleLogics.getinstance(X2, 7); miner=fpgrowth_miner)
    @test _temp_lsupport > 0.0 && _temp_lsupport < 1.0
    @test gsupport(pq, dataset(apriori_miner), 0.1; miner=fpgrowth_miner) == 0.025

    lsupport(Itemset(manual_p), SoleLogics.getinstance(X2, 7); miner=fpgrowth_miner)
    lsupport(Itemset(manual_lr), SoleLogics.getinstance(X2, 7); miner=fpgrowth_miner)
    @test lconfidence(
        _temp_arule, SoleLogics.getinstance(X2,7); miner=fpgrowth_miner) == 1.0

    _temp_arule = arules_generator(freqitems(fpgrowth_miner), fpgrowth_miner) |> first
    @test gconfidence(
        _temp_arule, dataset(fpgrowth_miner), 0.1; miner=fpgrowth_miner) == 1.0
end

@testset "arulemining-utils.jl" begin
    @test combine([pq, qr], 3) |> first == pqr
    @test combine([manual_p, manual_q], [manual_r]) |> collect |> length == 3
    @test combine([manual_p, manual_q], [manual_r]) |>
        collect |> first == Itemset([manual_p, manual_r])

    @test grow_prune([pq,qr,pr], [pq,qr,pr], 3) |> collect |> unique == [pqr]
    @test coalesce_contributors(Itemset(manual_p), fpgrowth_miner) |> first |> sum == 214118
    @test arules_generator(freqitems(fpgrowth_miner), fpgrowth_miner) |> first ==
        ARule(Itemset(manual_r), Itemset(manual_lr))
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
