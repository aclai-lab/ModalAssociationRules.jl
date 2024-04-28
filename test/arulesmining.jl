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

# items to short test-case
# manual_items = Vector{Item}([manual_p, manual_r, manual_lr])

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
r = Itemset(manual_r)
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

@test EnhancedItemset <: Tuple{Itemset,Int64}
enhanceditemset = convert(EnhancedItemset, pq, 42)
@test length(enhanceditemset) == 2
@test first(enhanceditemset) isa Itemset
@test last(enhanceditemset) isa Int64
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
@test localmemo(apriori_miner) |> length == 11880
@test localmemo(apriori_miner)[(:lsupport, pq, 1)] == 0.0

@test info(apriori_miner) isa Info

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

@test hasinfo(_temp_miner, :istrained) == true
@test hasinfo(_temp_miner, :istraineeeeeed) == false

_temp_apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)

@test_throws ErrorException generaterules!(_temp_miner)

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
    _temp_arule, SoleLogics.getinstance(X2,7); miner=fpgrowth_miner) == 0.0
@test gconfidence(
    _temp_arule, dataset(fpgrowth_miner), 0.1; miner=fpgrowth_miner) > 0.68

# more on Miner powerups (a.k.a, "customization system")
@test SoleRules.initpowerups(apriori, dataset(apriori_miner)) == Powerup()

# "arulemining-utils.jl"
@test combine([pq, qr], 3) |> first == pqr
@test combine([manual_p, manual_q], [manual_r]) |> collect |> length == 3
@test combine([manual_p, manual_q], [manual_r]) |>
    collect |> first == Itemset([manual_p, manual_r])

@test grow_prune([pq,qr,pr], [pq,qr,pr], 3) |> collect |> unique == [pqr]
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

@test !(islist(root)) # because of children! behaviour, se above
@test islist(fpt_c1)
@test itemset_from_fplist(fpt_c1) == pqr

# structure itself is returned, since internal link is empty
@test follow(fpt_c1) == fpt_c1

fpt_linked = FPTree()
@test link!(fpt_c1, fpt_linked) == fpt_linked

@test_nowarn repr("text/plain", fpt_c1)

# manual FPTree construction and antagonist functions;
# to compute the construction, we use the previously trained miner `fpgrowth_miner`;
# since we are using it, each Itemset is inserted by following the order: r, then p, then q.
#
# resulting FPTree:
# ∅ (root)
# -r                  count: 4
# --p                 count: 1
# ---*q ≤ -2.2        count: 1
# --*q ≤ -2.2         count: 2
# -p > -0.5           count: 1
# --*q ≤ -2.2         count: 1

conditional_patternbase = EnhancedItemset[
    (pqr, 1),
    (pq, 1),
    (qr, 2),
    (r, 1)
]

manual_fptree = FPTree()
@test_nowarn grow!(manual_fptree, conditional_patternbase, fpgrowth_miner)

# 1st property - most frequent item has only a single node directly under the root
@test count(x -> x == manual_r, content.(manual_fptree |> children)) == 1

# 2nd property - the sum of counts for each item equals the total count we know manually
item_to_count = Dict{Item, Int64}(manual_p => 0, manual_q => 0, manual_r => 0)

function _count_accumulation(fptree::FPTree)
    for child in children(fptree)
        _count_accumulation(child)
    end
    item_to_count[content(fptree)] += count(fptree)
end

@test_nowarn map(child -> _count_accumulation(child), children(manual_fptree))

@test item_to_count[manual_p] == 2
@test item_to_count[manual_q] == 4
@test item_to_count[manual_r] == 4

# 3rd property - the sum of counts of the children of a node is less than or equal the count
# in the node itself.
function _parent_supremacy(fptree::FPTree)
    @test count(fptree) >= sum(count.(fptree |> children))
    _parent_supremacy.(fptree |> children)
end

@test_nowarn map(child -> _parent_supremacy(child), children(manual_fptree))

# 4th property - there are x itemsets having prefix p before y, where y is the label of a
# node in the tree, p is the prefix on the path from the root, and x the count of the node.
# Here, we check that each retrieved prefix is not duplicated.
prefix_existance = Dict{Itemset, Bool}()

function _allowed_existence(fptree::FPTree)
    function _retrieve_prefix(fptree::FPTree)
        if isroot(fptree)
            return Itemset()
        else
            return union(fptree |> content |> Itemset,
                fptree |> SoleRules.parent |> _retrieve_prefix)
        end
    end

    prefix = _retrieve_prefix(fptree)
    @test !haskey(prefix_existance, prefix)
    prefix_existance[prefix] = true
end

@test_nowarn map(child -> _allowed_existence(child), children(manual_fptree))

# "fpgrowth.jl - HeaderTable"
@test HeaderTable() isa HeaderTable

fpt = FPTree(pqr)
@test_throws AssertionError htable = HeaderTable([pqr], fpt)
@test_nowarn @eval htable = HeaderTable(fpt)

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

@test checksanity!(htable, fpgrowth_miner) == true

root = FPTree()
@test_nowarn grow!(root, pqr, fpgrowth_miner)
@test SoleRules.children(root) |> first |> count == 1

@test_nowarn grow!(root, [pqr, qr], fpgrowth_miner)

enhanceditemset = (Itemset(manual_p), 1)
enhanceditemset2 = (Itemset(manual_q), 1)
@test_nowarn grow!(root, enhanceditemset, fpgrowth_miner)

@test_nowarn grow!(root, [enhanceditemset, enhanceditemset2], fpgrowth_miner)

@test Base.reverse(htable) == htable |> items |> reverse

# "Apriori and FPGrowth comparisons"
# mine has to be repeated, since it might be invalidated previously for tests purpose
_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

apriori_miner = Miner(X2, apriori, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)

mine!(apriori_miner)
mine!(fpgrowth_miner)

apriori_freqs = freqitems(apriori_miner)
fpgrowth_freqs = freqitems(fpgrowth_miner)

# check if generated frequent itemsets are the same
@test length(apriori_freqs) == length(fpgrowth_freqs)
@test all(item -> item in freqitems(apriori_miner), freqitems(fpgrowth_miner))
@test generaterules!(fpgrowth_miner) |> first isa ARule

# check if global support coincides for each frequent itemset
for itemset in freqitems(fpgrowth_miner)
    @test apriori_miner.gmemo[(:gsupport, itemset)] ==
        fpgrowth_miner.gmemo[(:gsupport, itemset)]
end

# check if local support coincides for each frequent itemset
function _isequal_lsupp(
    miner1::Miner,
    miner2::Miner,
    itemset::Itemset,
    ninstance::Int64
)
    miner1_lsupp = get(miner1.lmemo, (:lsupport, itemset, ninstance), 0.0)
    miner2_lsupp = get(miner2.lmemo, (:lsupport, itemset, ninstance), 0.0)

    if miner1_lsupp != miner2_lsupp
        if length(itemset) == 1
            println("Instance: $(ninstance) - Testing: $(itemset)")
            println("Values: $(miner1_lsupp) vs $(miner2_lsupp)")
        end
    end

#     @test miner1_lsupp == miner2_lsupp
end

for itemset in freqitems(fpgrowth_miner)
    for ninstance in 1:(fpgrowth_miner |> dataset |> ninstances)
        _isequal_lsupp(apriori_miner, fpgrowth_miner, itemset, ninstance)
    end
end
