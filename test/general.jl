# Association rule extraction algorithms test suite
using Test

using ModalAssociationRules
using SoleData
using StatsBase

import ModalAssociationRules.children, ModalAssociationRules.info

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS()
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies,
# and deepcopies must be produced now.
X2 = deepcopy(X1)
X3 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5)) |> Item
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2)) |> Item
manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6)) |> Item

manual_lp = box(IA_L)(manual_p |> formula) |> Item
manual_lq = diamond(IA_L)(manual_q |> formula) |> Item
manual_lr = box(IA_L)(manual_r |> formula) |> Item

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# set meaningfulness measures, for both mining frequent itemsets and establish which
# combinations of them are association rules.
_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

@test_throws ArgumentError Miner(
    X1, apriori, manual_items, [(gconfidence, 0.1, 0.1)], _rulemeasures)

apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)

@test itemtype(apriori_miner) == Item

pq = Itemset{Item}([manual_p, manual_q])
qr = Itemset{Item}([manual_q, manual_r])
pr = Itemset{Item}([manual_p, manual_r])
pqr = Itemset{Item}([manual_p, manual_q, manual_r])
r = Itemset{Item}(manual_r)

@test pq in pq
@test qr in pqr
@test (pqr in [pq,qr]) == false

@test Itemset{Item} <: Itemset{<:Item}
@test Itemset{Item}(Item[manual_p]) == Item[manual_p]
@test all(item -> item in [manual_p, manual_q], pq)

@test_throws MethodError convert(Item, [manual_p])
@test_throws MethodError convert(Item, [manual_p, manual_q])
@test_throws MethodError convert(Item, pq)

@test syntaxstring(manual_p) == "min[V1] > -0.5"

@test manual_p in pq
@test pq in pqr
@test (pq in [manual_p, manual_q, manual_r])
@test pq in [pq, pqr, qr]

@test formula(pq) isa LeftmostConjunctiveForm
@test formula(pq) |> SoleLogics.grandchildren |> first |> Item in [manual_p, manual_q]

@test Threshold <: Float64
@test WorldMask <: BitVector

@test EnhancedItemset <: Tuple{Itemset,Integer}
enhanceditemset = convert(EnhancedItemset, pq, 42)
@test length(enhanceditemset) == 2
@test first(enhanceditemset) isa Itemset
@test last(enhanceditemset) isa Integer
@test convert(Itemset, enhanceditemset) isa Itemset

@test ConditionalPatternBase <: Vector{EnhancedItemset}

@test_nowarn ARule(pq, Itemset([manual_r]))
arule = ARule(pq, Itemset([manual_r]))
@test content(arule) |> first == antecedent(arule)
@test content(arule) |> last == consequent(arule)
arule2 = ARule(qr, Itemset([manual_p]))
arule3 = ARule(Itemset([manual_q, manual_p]), Itemset([manual_r]))

@test arule != arule2
@test arule == arule3

@test_throws ArgumentError ARule(qr, Itemset([manual_q]))

@test MeaningfulnessMeasure <: Tuple{Function,Threshold,Threshold}

@test ARMSubject <: Union{ARule,Itemset}
@test LmeasMemoKey <: Tuple{Symbol,ARMSubject,Integer}
@test LmeasMemo <: Dict{LmeasMemoKey,Threshold}
@test GmeasMemoKey <: Tuple{Symbol,ARMSubject}
@test GmeasMemo <: Dict{GmeasMemoKey,Threshold}

# "core.jl - Miner"
mine!(fpgrowth_miner)

@test_nowarn Miner(X1, apriori, manual_items)
@test_nowarn algorithm(Miner(X1, apriori, manual_items)) isa Function

@test data(fpgrowth_miner) == X2
@test algorithm(fpgrowth_miner) isa Function
@test items(Miner(X1, apriori, manual_items)) == manual_items

@test itemsetmeasures(fpgrowth_miner) == _itemsetmeasures
@test arulemeasures(fpgrowth_miner) == _rulemeasures

function _association_rules_test1(miner::Miner)
    countdown = 3
    for _temp_arule in generaterules(freqitems(miner), miner)
        if countdown > 0
            @test _temp_arule in arules(miner)
            @test _temp_arule isa ARule
        else
            break
        end
        countdown -= 1
    end
end
_association_rules_test1(fpgrowth_miner)



@test info(fpgrowth_miner) isa Info

function _dummy_gsupport(
    ::Itemset,
    ::SupportedLogiset,
    ::Threshold,
    ::Union{Nothing,Miner}
)::Float64
    return 1.0
end

_temp_miner = Miner(X2, fpgrowth, manual_items, [(gsupport, 0.1, 0.1)], _rulemeasures)
@test_throws ErrorException getlocalthreshold(_temp_miner, _dummy_gsupport)
@test_throws ErrorException getglobalthreshold(_temp_miner, _dummy_gsupport)
@test _temp_miner.globalmemo == GmeasMemo()

@test length(itemsetmeasures(_temp_miner)) == 1
@test length(arulemeasures(_temp_miner)) == 1
@test length(ModalAssociationRules.measures(_temp_miner)) == 2

@test_nowarn findmeasure(_temp_miner, lsupport, recognizer=islocalof)

@test hasinfo(_temp_miner, :istrained) == true
@test hasinfo(_temp_miner, :istraineeeeeed) == false

_temp_apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)

@test_throws ErrorException generaterules!(_temp_miner)

@test_nowarn repr("text/plain", _temp_miner)



# meaningfulness measures
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

@test localof(lsupport) |> isnothing
@test localof(gsupport) == lsupport
@test localof(lconfidence) |> isnothing
@test localof(gconfidence) == lconfidence
@test localof(llift) |> isnothing
@test localof(glift) == llift
@test localof(lconviction) |> isnothing
@test localof(gconviction) == lconviction
@test localof(lleverage) |> isnothing
@test localof(gleverage) == lleverage

@test globalof(lsupport) == gsupport
@test globalof(gsupport) |> isnothing
@test globalof(lconfidence) == gconfidence
@test globalof(gconfidence) |> isnothing
@test globalof(llift) == glift
@test globalof(glift) |> isnothing
@test globalof(lconviction) == gconviction
@test globalof(gconviction) |> isnothing
@test globalof(lleverage) == gleverage
@test globalof(gleverage) |> isnothing

@test lsupport(pq, SoleLogics.getinstance(X2, 1), fpgrowth_miner) == 0.0

_temp_lsupport = lsupport(pq, SoleLogics.getinstance(X2, 7), fpgrowth_miner)
@test _temp_lsupport >= 0.0 && _temp_lsupport <= 1.0

lsupport(Itemset(manual_p), SoleLogics.getinstance(X2, 7), fpgrowth_miner)
lsupport(Itemset(manual_lr), SoleLogics.getinstance(X2, 7), fpgrowth_miner)

# more on Miner miningstate (a.k.a, "customization system")
@test ModalAssociationRules.initminingstate(apriori, data(apriori_miner)) == MiningState()

# "rulemining-utils.jl"
@test combine_items([pq, qr], 3) |> first == pqr
@test combine_items([manual_p, manual_q], [manual_r]) |> collect |> length == 3
@test combine_items([manual_p, manual_q], [manual_r]) |>
    collect |> first == Itemset([manual_p, manual_r])

# Deprecated test
# @test grow_prune([pq,qr,pr], [pq,qr,pr], 3) |> collect |> unique == pqr
# @test generaterules(freqitems(fpgrowth_miner), fpgrowth_miner) |> first isa ARule

_rulemeasures_just_for_test = [(ModalAssociationRules.gconfidence, 1.1, 1.1)]
_temp_fpgrowth_miner = Miner(
    X3, fpgrowth, [manual_p, manual_lp], _itemsetmeasures, _rulemeasures_just_for_test)
@test mine!(_temp_fpgrowth_miner) |> collect == ARule[]
@test_nowarn globalmemo(_temp_fpgrowth_miner)

# "fpgrowth.jl - FPTree"
root = FPTree()
@test root isa FPTree
@test content(root) === nothing
@test ModalAssociationRules.parent(root) === nothing
@test ModalAssociationRules.children(root) == FPTree[]
@test count(root) == 0
@test link(root) === nothing

@test content!(root, manual_p) == manual_p
newroot = FPTree()
@test_nowarn ModalAssociationRules.parent!(root, newroot) === newroot
@test content(ModalAssociationRules.parent(root)) === nothing

@test_nowarn @eval fpt = FPTree(pqr)
fpt_c1 = ModalAssociationRules.children(fpt) |> first
@test count(fpt_c1) == 1
@test ModalAssociationRules.count!(fpt_c1, 5) == 5
@test addcount!(fpt_c1, 2) == 7
@test link(fpt) === nothing
@test_nowarn @eval content!(fpt, manual_lp)

# children! does not perform any check!
map(_ -> children!(root, fpt), 1:3)
@test ModalAssociationRules.children(root) |> length == 3

@test !(islist(root)) # because of children! behaviour, se above
@test islist(fpt_c1)
@test pqr in itemset_from_fplist(fpt_c1)

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
@test_nowarn grow!(manual_fptree, conditional_patternbase; miner=fpgrowth_miner)

# 1st property - most frequent item has only a single node directly under the root
@test count(x -> x == manual_r, content.(manual_fptree |> ModalAssociationRules.children)) == 1

# 2nd property - the sum of counts for each item equals the total count we know manually
item_to_count = Dict{Item, Integer}(
    manual_p => 0,
    manual_q => 0,
    manual_r => 0
)

function _count_accumulation(fptree::FPTree)
    for child in ModalAssociationRules.children(fptree)
        _count_accumulation(child)
    end
    item_to_count[content(fptree)] += count(fptree)
end

@test_nowarn map(
    child -> _count_accumulation(child), ModalAssociationRules.children(manual_fptree))

@test item_to_count[manual_p] == 2
@test item_to_count[manual_q] == 4
@test item_to_count[manual_r] == 4

# 3rd property - the sum of counts of the children of a node is less than or equal the count
# in the node itself.
function _parent_supremacy(fptree::FPTree)
    @test count(fptree) >= sum(count.(fptree |> children))
    _parent_supremacy.(fptree |> children)
end

@test_nowarn map(
    child -> _parent_supremacy(child), ModalAssociationRules.children(manual_fptree))

# 4th property - there are x itemsets having prefix p before y, where y is the label of a
# node in the tree, p is the prefix on the path from the root, and x the count of the node.
# Here, we check that each retrieved prefix is not duplicated.
prefix_existance = Dict{Itemset, Bool}()

function _allowed_existence(fptree::FPTree)
    function _retrieve_prefix(fptree::FPTree)
        if isroot(fptree)
            return Itemset{Item}()
        else
            return union(fptree |> content |> Itemset,
                fptree |> ModalAssociationRules.parent |> _retrieve_prefix)
        end
    end

    prefix = _retrieve_prefix(fptree)
    @test !haskey(prefix_existance, prefix)
    prefix_existance[prefix] = true
end

@test_nowarn map(child -> _allowed_existence(child), children(manual_fptree))



fpt = FPTree(pqr)
@test_throws MethodError htable = HeaderTable([pqr], fpt)
@test_nowarn @eval htable = HeaderTable(fpt)

@test all(item -> item in pqr, items(htable))

fpt_c1 = ModalAssociationRules.children(fpt)[1]
@test link(htable)[manual_p] isa FPTree

@test follow(htable, manual_p) == link(htable)[manual_p]
@test follow(htable, manual_q) == link(htable)[manual_q]
@test follow(htable, manual_r) == link(htable)[manual_r]

fpt2 = FPTree(pqr)
fpt2_c1 = ModalAssociationRules.children(fpt2)[1]
@test_nowarn link!(htable, fpt2_c1)
@test link(htable)[manual_p] isa FPTree

@test checksanity!(htable, fpgrowth_miner) == true

root = FPTree()
@test_nowarn grow!(root, pqr; miner=fpgrowth_miner)
@test ModalAssociationRules.children(root) |> first |> count == 1

@test_nowarn grow!(root, [pqr, qr]; miner=fpgrowth_miner)

enhanceditemset = (Itemset(manual_p), 1)
enhanceditemset2 = (Itemset(manual_q), 1)
@test_nowarn grow!(root, enhanceditemset; miner=fpgrowth_miner)
@test_nowarn grow!(
    root, ConditionalPatternBase([enhanceditemset, enhanceditemset2]); miner=fpgrowth_miner)

@test Base.reverse(htable) == items(htable) |> reverse

# Additional tests not covered before
item_from_formula = Item(CONJUNCTION(Atom("p"), Atom("q")))
itemset_from_formula = Itemset(CONJUNCTION(Atom("p"), Atom("q")))
@test convert(Itemset, item_from_formula) == itemset_from_formula

@test_nowarn syntaxstring(EnhancedItemset((itemset_from_formula, 1)))

itemset_1 = Itemset(Atom("p"))
itemset_2 = Itemset(Atom("q"))
arule1 = ARule((itemset_1, itemset_2))
@test convert(Itemset, arule1) == Itemset([itemset_1..., itemset_2...])

@test_nowarn Base.hash(arule1, UInt(42))

@test_nowarn syntaxstring(arule1)

struct genericMiner <: AbstractMiner
end

_genericMiner = genericMiner()

@test_throws ErrorException data(_genericMiner)
@test_throws ErrorException items(_genericMiner)
@test_throws ErrorException algorithm(_genericMiner)
@test_throws ErrorException freqitems(_genericMiner)
@test_throws ErrorException arules(_genericMiner)
@test_throws ErrorException itemsetmeasures(_genericMiner)
@test_throws ErrorException arulemeasures(_genericMiner)
@test_throws ErrorException localmemo(_genericMiner)
@test_throws ErrorException globalmemo(_genericMiner)
@test_throws ErrorException worldfilter(_genericMiner)
@test_throws ErrorException itemset_policies(_genericMiner)
@test_throws ErrorException arule_policies(_genericMiner)
@test_throws ErrorException miningstate(_genericMiner)
@test_throws ErrorException info(_genericMiner)
@test_throws ErrorException itemtype(_genericMiner)

struct statefulMiner <: AbstractMiner
    miningstate::MiningState
end
_statefulMiner = statefulMiner(MiningState())

@test_nowarn miningstate!(_statefulMiner, :field, 2)
@test_nowarn miningstate!(_statefulMiner, :field, Dict(:inner_field => 3))
@test_throws ErrorException miningstate(_statefulMiner)
@test_throws ErrorException miningstate(_statefulMiner, :field, :inner_field)

@test_nowarn datatype(apriori_miner)

_my_lsupport_logic = (itemset, X, ith_instance, miner) -> begin
    wmask = [
        check(formula(itemset), X, ith_instance, w) for w in allworlds(X, ith_instance)]

        return Dict(
        :measure => count(wmask) / nworlds(X, ith_instance),
        :instance_item_toworlds => wmask,
    )
end

_my_gsupport_logic = (itemset, X, threshold, miner) -> begin
    _measure = sum([
        lsupport(itemset, getinstance(X, ith_instance), miner) >= threshold
        for ith_instance in 1:ninstances(X)
    ]) / ninstances(X)

    return Dict(:measure => _measure)
end

@localmeasure my_lsupport _my_lsupport_logic
@localmeasure my_gsupport _my_gsupport_logic
