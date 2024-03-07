# Association rule extraction algorithms test suite
using Test

using SoleRules
using SoleData
using StatsBase

# load NATOPS dataset and convert it to a Logiset
X_df, y = SoleData.load_arff_dataset("NATOPS");
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies,
# and deepcopies must be produced now.
X2 = deepcopy(X1)
X3 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(UnivariateMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# set meaningfulness measures, for both mining frequent itemsets and establish which
# combinations of them are association rules.
_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

# make two miners: the first digs the search space using aprior, the second uses fpgrowth
apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)

# mine the frequent patterns with both apriori and fpgrowth
@test_nowarn mine!(apriori_miner)
@test_nowarn mine!(fpgrowth_miner)

pq = Itemset([manual_p, manual_q])
qr = Itemset([manual_q, manual_r])
pr = Itemset([manual_p, manual_r])
pqr = Itemset([manual_p, manual_q, manual_r])
@test pq in pq
@test qr in pqr
@test (pqr in [pq,qr]) == false

# "core.jl - fundamental types"
@test Item <: Formula
@test Itemset(manual_p) |> items == [manual_p]
@test all(item -> item in [manual_p, manual_q], pq |> items)

@test convert(Item, Itemset([manual_p])) == manual_p

@test_throws MethodError convert(Item, [manual_p])
@test_throws MethodError convert(Item, [manual_p, manual_q])
@test_throws AssertionError convert(Item, pq)

@test syntaxstring(manual_p) == "min[V1] > -0.5"

@test manual_p in pq
@test pq in pqr
@test !(pq in [manual_p, manual_q, manual_r])
@test pq in [pq, pqr, qr]

@test toformula(pq) isa LeftmostConjunctiveForm
@test toformula(pq).children |> first in [manual_p, manual_q]

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

# "core.jl - Miner"
@test_nowarn Miner(X1, apriori, manual_items)
@test_nowarn algorithm(Miner(X1, apriori, manual_items)) isa Function

@test dataset(apriori_miner) == X1
@test algorithm(apriori_miner) isa Function
@test items(Miner(X1, apriori, manual_items)) == manual_items

@test itemsetmeasures(apriori_miner) == _itemsetmeasures
@test rulemeasures(apriori_miner) == _rulemeasures

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

function _association_rules_test1(miner::Miner)
    countdown = 3
    for _temp_arule in arules_generator(freqitems(miner), miner)
        if countdown > 0
            @test _temp_arule in arules(miner)
            @test _temp_arule isa ARule
        else
            break
        end
        countdown -= 1
    end
end
_association_rules_test1(apriori_miner)

_temp_lmemo_key2 = (:lsupport, Itemset(manual_p), 1)
@test localmemo(apriori_miner) |> length == 13320
@test localmemo(apriori_miner)[(:lsupport, pq, 1)] == 0.0

@test info(apriori_miner) isa Info
@test !(haspowerup(apriori_miner, :contributors))
@test haspowerup(fpgrowth_miner, :contributors)
@test powerups(fpgrowth_miner, :contributors) |> length == 2160

@test haspowerup(Miner(X1, fpgrowth, manual_items), :contributors)

@test contributors(_temp_lmemo_key2, fpgrowth_miner) |> length == 1326
@test contributors(_temp_lmemo_key2, fpgrowth_miner) ==
    contributors(:lsupport, Itemset(manual_p), 1, fpgrowth_miner)
@test contributors(_temp_lmemo_key2, fpgrowth_miner) |> sum == 104545
@test_throws ErrorException contributors!(
    apriori_miner, _temp_lmemo_key2, zeros(Int64, 1326))
@test contributors!(
    fpgrowth_miner, _temp_lmemo_key2, zeros(Int64, 1326)) == zeros(Int64, 1326)

# checking for re-mining block
@test apply!(fpgrowth_miner, dataset(fpgrowth_miner)) == Nothing

function _dummy_gsupport(
    itemset::Itemset,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,Miner} = nothing
)::Float64
    return 1.0
end

_temp_miner = Miner(X2, fpgrowth, manual_items, [(gsupport, 0.1, 0.1)], _rulemeasures)
@test_throws ErrorException getlocalthreshold(_temp_miner, _dummy_gsupport)
@test_throws ErrorException getglobalthreshold(_temp_miner, _dummy_gsupport)
@test _temp_miner.gmemo == GmeasMemo()

@test_throws AssertionError additemmeas(_temp_miner, (gsupport, 0.1, 0.1))
@test length(itemsetmeasures(_temp_miner)) == 1
@test_throws AssertionError addrulemeas(_temp_miner, (gconfidence, 0.1, 0.1))
@test length(rulemeasures(_temp_miner)) == 1
@test length(SoleRules.measures(_temp_miner)) == 2

@test_nowarn findmeasure(_temp_miner, lsupport, recognizer=islocalof)

_temp_contributors = Contributors([(:lsupport, pq, 1) => zeros(Int64,42)])
@test powerups!(_temp_miner, :contributors, _temp_contributors) == _temp_contributors
@test hasinfo(_temp_miner, :istrained) == true
@test hasinfo(_temp_miner, :istraineeeeeed) == false

_temp_apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
@test_throws ErrorException contributors((:lsupport, pqr, 1), _temp_apriori_miner)

@test_throws ErrorException generaterules(_temp_miner)

@test_nowarn repr("text/plain", _temp_miner)


# "meaningfulness-measures.jl"
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

# this is slow since fpgrowth-based miners only keep track of statistics about
# frequent itemsets, and `pq` is not (in fact, its value for gsupport is < 0.1)
@test gsupport(pq, dataset(apriori_miner), 0.1; miner=fpgrowth_miner) == 0.025

_temp_arule = arules_generator(freqitems(fpgrowth_miner), fpgrowth_miner) |> first

lsupport(Itemset(manual_p), SoleLogics.getinstance(X2, 7); miner=fpgrowth_miner)
lsupport(Itemset(manual_lr), SoleLogics.getinstance(X2, 7); miner=fpgrowth_miner)
@test lconfidence(
    _temp_arule, SoleLogics.getinstance(X2,7); miner=fpgrowth_miner) > 0.08
@test gconfidence(
    _temp_arule, dataset(fpgrowth_miner), 0.1; miner=fpgrowth_miner) > 0.85


# more on Miner structure
@test SoleRules.initpowerups(apriori, dataset(apriori_miner)) == Powerup()
@test SoleRules.initpowerups(fpgrowth, dataset(fpgrowth_miner)) == Powerup(
    [:contributors => Contributors([])])

# "arulemining-utils.jl"
@test combine([pq, qr], 3) |> first == pqr
@test combine([manual_p, manual_q], [manual_r]) |> collect |> length == 3
@test combine([manual_p, manual_q], [manual_r]) |>
    collect |> first == Itemset([manual_p, manual_r])

@test grow_prune([pq,qr,pr], [pq,qr,pr], 3) |> collect |> unique == [pqr]
@test coalesce_contributors(Itemset(manual_p), fpgrowth_miner) |> first |> sum == 109573
@test arules_generator(freqitems(fpgrowth_miner), fpgrowth_miner) |> first isa ARule

_rulemeasures_just_for_test = [(SoleRules.gconfidence, 1.1, 1.1)]
_temp_fpgrowth_miner = Miner(
    X3, fpgrowth, [manual_p, manual_lp], _itemsetmeasures, _rulemeasures_just_for_test)
@test mine!(_temp_fpgrowth_miner) |> collect == ARule[]
@test_nowarn globalmemo(_temp_fpgrowth_miner)

# "fpgrowth.jl - FPTree"
root = FPTree()
@test root isa FPTree
@test content(root) === nothing
@test SoleRules.parent(root) === nothing
@test SoleRules.children(root) == FPTree[]
@test contributors(root) == Int64[]
@test count(root) == 0
@test link(root) === nothing

@test content!(root, manual_p) == manual_p
newroot = FPTree()
@test_nowarn SoleRules.parent!(root, newroot) === newroot
@test content(SoleRules.parent(root)) === nothing

@test_nowarn @eval fpt = FPTree(pqr)
fpt_c1 = SoleRules.children(fpt) |> first
@test count(fpt_c1) == 1
@test SoleRules.count!(fpt_c1, 5) == 5
@test addcount!(fpt_c1, 2) == 7
@test link(fpt) === nothing
@test_nowarn @eval content!(fpt, manual_lp)

# children! does not perform any check!
map(_ -> children!(root, fpt), 1:3)
@test SoleRules.children(root) |> length == 3

@test addcontributors!(fpt_c1, [12]) == [12]
@test_throws DimensionMismatch addcontributors!(fpt_c1, [4,2,0])

@test contributors!(fpt_c1, [42]) == [42]

@test !(islist(root)) # because of children! behaviour, se above
@test islist(fpt_c1)
@test retrieveall(fpt_c1) == pqr

# structure itself is returned, since internal link is empty
@test follow(fpt_c1) == fpt_c1

fpt_linked = FPTree()
@test link!(fpt_c1, fpt_linked) == fpt_linked

@test_nowarn repr("text/plain", fpt_c1)

# "fpgrowth.jl - HeaderTable"
@test HeaderTable() isa HeaderTable

fpt = FPTree(pqr)
@test_throws AssertionError htable = HeaderTable([pqr], fpt)
@test HeaderTable([Itemset(manual_p),
    Itemset(manual_q), Itemset(manual_r)], fpt) isa HeaderTable
@test_nowarn @eval htable = HeaderTable([manual_p, manual_q, manual_r], fpt)

@test all(item -> item in pqr, items(htable))

fpt_c1 = SoleRules.children(fpt)[1]
@test link(htable)[manual_p] isa FPTree

@test follow(htable, manual_p) == link(htable)[manual_p]
@test follow(htable, manual_q) == link(htable)[manual_q]
@test follow(htable, manual_r) == link(htable)[manual_r]

fpt2 = FPTree(pqr)
fpt2_c1 = SoleRules.children(fpt2)[1]
@test_nowarn link!(htable, fpt2_c1)
@test link(htable)[manual_p] isa FPTree

# initially, items in htable are not ordered since it
# is not created considering fpgrowth_miner.
@test checksanity!(htable, fpgrowth_miner) == false
@test checksanity!(htable, fpgrowth_miner) == true

root = FPTree()
@test_nowarn push!(root, pqr, 1, fpgrowth_miner; htable=htable)
@test SoleRules.children(root) |> first |> count == 2 # not 1, htable was already loaded

@test_nowarn push!(root, [pqr, qr], 2, fpgrowth_miner; htable=htable)

enhanceditemset = EnhancedItemset([(manual_p, 1, [1])])
enhanceditemset2 = EnhancedItemset([(manual_q, 1, [1])])
@test_nowarn push!(root, enhanceditemset, fpgrowth_miner; htable=htable)

@test_nowarn push!(root, [enhanceditemset, enhanceditemset2], fpgrowth_miner;
    htable=htable)

@test Base.reverse(htable) == htable |> items |> reverse


# "fpgrowth.jl - patternbase and projection"
# @test_nowarn mine!(fpgrowth_miner) # just to let @test see also internal calls


# "Apriori and FPGrowth comparisons"
apriori_freqs = freqitems(apriori_miner)
fpgrowth_freqs = freqitems(fpgrowth_miner)

@test length(apriori_freqs) == length(fpgrowth_freqs)
@test all(item -> item in freqitems(apriori_miner), freqitems(fpgrowth_miner))
@test generaterules(fpgrowth_miner) |> first isa ARule
