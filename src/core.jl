############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
const Item = SoleLogics.Formula

# Dynamic programming utility structures
const LmeasMemoKey = Tuple{Symbol,Integer}
const LmeasMemo = Dict{LmeasMemoKey,Float64}

const GmeasMemoKey = Symbol
const GmeasMemo = Dict{GmeasMemoKey,Float64}

const Itemset = Vector{Item}

function Itemset(item::Item)
    Itemset([item])
end

function Itemset(itemsets::Vector{Itemset})
    Itemset(union(itemsets...))
end

value(itemset::Itemset) = LeftmostConjunctiveForm(itemset)

# Given an itemsets vector, return the pairwise combination of such itemsets such that
# the combination's length is `newlength`.
function combine(itemsets::Vector{<:Itemset}, newlength::Integer)
    return Iterators.map(
        x -> union(x[1], x[2]), # NOTE: repetition here
        Iterators.filter(
            x -> length(union(x[1],x[2])) == newlength,
            combinations(itemsets,2)
        )
    )
end

"""
    struct ARule
        rule::Rule{Itemset, Atom}

        # memoization structures
        lmemo::LmeasMemo
        gmemo::GmeasMemo
    end

[`Rule`](@ref) object, specialized to represent association rules.
An association rule is a rule expressing a statistically meaningful relation between
antecedent and consequent (e.g., if facts in the antecedent are true together on a model,
probably the facts in the consequent are true too on the same model).

Both antecedent and consequent are (vector of) [`Itemset`](@ref)s.

See also [`SoleLogics.Atom`](@ref), [`SoleModels.antecedent`](@ref),
[`SoleModels.consequent`](@ref), [`Itemset`](@ref), [`SoleModels.Rule`](@ref).
"""
struct ARule
    rule::Tuple{Itemset,Itemset}

    # memoization structures
    lmemo::LmeasMemo
    gmemo::GmeasMemo

    function ARule(ant::Itemset, cons::Itemset)
        new((ant,cons), LmeasMemo(), GmeasMemo())
    end
end

antecedent(r::ARule) = first(r.rule)
consequent(r::ARule) = last(r.rule)
value(r::ARule) = r.rule

setlocalmemo(r::ARule, key::LmeasMemoKey, val::Float64) = r.lmemo[key] = val
getlocalmemo(r::ARule, key::LmeasMemoKey) = get(r.lmemo, key, nothing)

setglobalmemo(r::ARule, key::GmeasMemoKey, val::Float64) = r.gmemo[key] = val
getglobalmemo(r::ARule, key::GmeasMemoKey) = get(r.gmemo, key, nothing)

# TODO: make this a generator
function arules_generator(itemsets::Vector{Itemset})
    for itemset in itemsets
        subsets = powerset(itemset)
        for subset in subsets
            # TODO: fill the code
            # ignore empty and full subsets
            # measure confidence
            # compare confidence with threshold
        end
    end
end

############################################################################################
#### Meaningfulness measures ###############################################################
############################################################################################

const doc_meaningfulness_meas = """
    const ItemLmeas = FunctionWrapper{Float64, Tuple{Itemset,AbstractInterpretation}}
    const ItemGmeas = FunctionWrapper{Float64, Tuple{Itemset,AbstractDataset,Threshold}}
    const RuleLmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractInterpretation}}
    const RuleGmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractDataset,Threshold}}

Function wrappers to express local and global meaningfulness measures of items and
association rules.

Local meaningfulness measures ([`ItemLmeas`](@ref), [`RuleLmeas`](@ref)) returns
how frequently a test regarding an [`Itemset`](@ref) or a [`ARule`](@ref) is
satisfied within a specific [`AbstractInterpretation`](@ref).

Global meaningfulness measures ([`ItemGmeas`](@ref), [`RuleGmeas`](@ref)) are intended to
repeatedly apply a local meaningfulness measure on all the instances of an
[`AbstractDataset`](@ref). These returns how many times the real value returned by a
local measure is higher than a threshold.

See also [`ARule`](@ref), [`FunctionWrapper`](@ref), [`Itemset`](@ref).
"""

const Threshold = Float64

"""$(doc_meaningfulness_meas)"""
const ItemLmeas = FunctionWrapper{Float64,Tuple{Itemset,AbstractInterpretation}}

"""$(doc_meaningfulness_meas)"""
const ItemGmeas = FunctionWrapper{Float64,Tuple{Itemset,AbstractDataset,Float64}}

"""$(doc_meaningfulness_meas)"""
const RuleLmeas = FunctionWrapper{Float64,Tuple{ARule,AbstractInterpretation}}

"""$(doc_meaningfulness_meas)"""
const RuleGmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractDataset,Float64}}

function _lsupport(itemset::Itemset, logi_instance::LogicalInstance)::Float64
    # retrieve logiset, and the specific instance
    X, i_instance = logi_instance.s, logi_instance.i_instance

    # compute local measure, then divide it by the instance total number of worlds
    ans = sum([check(value(itemset), X, i_instance, w) for w in allworlds(X, i_instance)])
    ans = ans / nworlds(X, i_instance)

    return ans
end

function _gsupport(itemset::Itemset, X::SupportedLogiset, threshold::Float64)::Float64
    # compute global measure, then divide it by the dataset total number of instances
    ans = sum([_lsupport(itemset, getinstance(X, i_instance)) >= threshold
        for i_instance in 1:ninstances(X)])
    ans = ans / ninstances(X)

    return ans
end

function _lconfidence(r::ARule, logi_instance::LogicalInstance)::Float64
    _antecedent = antecedent(r)
    _consequent = consequent(r)

    ans = _lsupport(SoleRules.merge(_antecedent, _consequent), logi_instance) /
        _lsupport(_antecedent, logi_instance)
    return ans
end

function _gconfidence(r::ARule, X::SupportedLogiset, threshold::Float64)::Float64
    _antecedent = antecedent(r)
    _consequent = consequent(r)

    ans = _gsupport(union(_antecedent, _consequent), X, threshold) /
        _gsupport(_antecedent, X, threshold)
    return ans
end

lsupport = ItemLmeas(_lsupport)
gsupport = ItemGmeas(_gsupport)
lconfidence = RuleLmeas(_lconfidence)
gconfidence = RuleGmeas(_gconfidence)

############################################################################################
#### Association rule miner machine ########################################################
############################################################################################

"""
Generic machine learning model interface to perform association rules extraction.
"""
struct ARuleMiner
    # target dataset
    X::AbstractDataset
    # algorithm used to perform extraction
    algo::FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

    alphabet::Vector{Item} # NOTE: cannot instanciate Item inside ExplicitAlphabet

    # meaningfulness measures
    # (global measure, local threshold, global threshold)
    item_constrained_measures::Vector{Tuple{ItemGmeas,Float64,Float64}}
    rule_constrained_measures::Vector{Tuple{RuleGmeas,Float64,Float64}}

    nonfreqitems::Vector{Itemset}   # non-frequent itemsets dump
    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    lmemo::LmeasMemo                # local memoization structure
    gmemo::GmeasMemo                # global memoization structure
    info::NamedTuple                # general informations

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item},
        item_constrained_measures::Vector{<:Tuple{ItemGmeas,Float64,Float64}},
        rule_constrained_measures::Vector{<:Tuple{RuleGmeas,Float64,Float64}}
    )
        new(X, MiningAlgo(algo), alphabet,
            item_constrained_measures,
            rule_constrained_measures,
            Vector{Itemset}([]), Vector{Itemset}([]),
            Vector{ARule}([]), (;))
    end

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item}
    )
        # ARuleMiner(X, MiningAlgo(algo), alphabet,
        new(X, MiningAlgo(algo), alphabet, [(gsupport, 0.5, 0.5)], [(gconfidence, 0.5, 0.5)],
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), (;)
        );
    end
end

const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

dataset(miner::ARuleMiner) = miner.X
algorithm(miner::ARuleMiner) = miner.algo
alphabet(miner::ARuleMiner) = miner.alphabet

item_meas(miner::ARuleMiner) = miner.item_constrained_measures
rule_meas(miner::ARuleMiner) = miner.rule_constrained_measures

freqitems(miner::ARuleMiner) = miner.freqitems
nonfreqitems(miner::ARuleMiner) = miner.nonfreqitems
arules(miner::ARuleMiner) = miner.arules

function mine(miner::ARuleMiner)
    apply(miner, dataset(miner))
end

function apply(miner::ARuleMiner, X::AbstractDataset)
    # extract frequent itemsets
    miner.algo(miner, X)
    return true
end
