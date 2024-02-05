############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
const Item = SoleLogics.Formula

# Dynamic programming utility structures
const LmeasMemoKey = Tuple{Symbol,Integer}
const LmeasMemo = Dict{LmeasMemoKey,Float64}

const GmeasMemoKey = Symbol
const GmeasMemo = Dict{GmeasMemoKey,Float64}

const ItemsetContent = Union{Item,LeftmostConjunctiveForm{<:Item}}

"""
    struct Itemset{T<:ItemsetContent}
        value::T
        lmemo::LmeasMemo
        gmemo::GmeasMemo
    end

Antecedent or consequent of an association rule.
This structure wraps one or more [`Item`](@ref)s,
eventually representing them as a [`LeftmostLinearForm`](@ref).

See also [`LeftmostLinearForm`](@ref), [`ARule`](@ref), [`Item`](@ref).
"""
struct Itemset{T<:ItemsetContent}
    value::T

    # memoization structures
    lmemo::LmeasMemo
    gmemo::GmeasMemo

    function Itemset{T}(
        val::T,
        lmemo::LmeasMemo,
        gmemo::GmeasMemo
        ) where {T<:ItemsetContent}
        new{T}(val, lmemo, gmemo)
    end
    function Itemset(val::T) where {T<:ItemsetContent}
        Itemset{T}(val, LmeasMemo(), GmeasMemo())
    end
    function Itemset(
        val::Vector{<:T}
    ) where {T<:ItemsetContent}
        cnf = LeftmostConjunctiveForm(val)
        Itemset{typeof(cnf)}(cnf, LmeasMemo(), GmeasMemo())
    end
    function Itemset(val::Vector{Itemset})
        Itemset(value.(val))
    end
end

value(items::Itemset) = items.value isa LeftmostConjunctiveForm ?
    SoleLogics.conjuncts(items.value) : items.value

setlocalmemo(items::Itemset, key::LmeasMemoKey, val::Float64) = items.lmemo[key] = val
getlocalmemo(items::Itemset, key::LmeasMemoKey) = get(items.lmemo, key, nothing)

setglobalmemo(items::Itemset, key::GmeasMemoKey, val::Float64) = items.gmemo[key] = val
getglobalmemo(items::Itemset, key::GmeasMemoKey) = get(items.gmemo, key, nothing)

Base.length(items::Itemset{<:Atom}) = 1
Base.length(items::Itemset{<:LeftmostConjunctiveForm}) = length(value(items))

# Merge two items together, keeping unique items
function merge(item1::Itemset, item2::Itemset)
    # ternary operator returning a single value between square brackets is needed to
    # generalize the splat operator inside unique. Otherwise, an error is thrown.
    v1 = item1 isa Itemset{<:LeftmostConjunctiveForm} ? value(item1) : [value(item1)]
    v2 = item2 isa Itemset{<:LeftmostConjunctiveForm} ? value(item2) : [value(item2)]
    return Itemset(unique([v1..., v2...]))
end

function combine(itemsets::Vector{<:Itemset{<:ItemsetContent}}, newlength::Integer)
    newset = Vector{Itemset{<:ItemsetContent}}([])

    for (idx1, itemset1) in enumerate(itemsets)
        for itemset2 in itemsets[(idx1+1):end]
            merged = SoleRules.merge(itemset1, itemset2)
            if length(merged) == newlength
                push!(newset, merged)
            end
        end
    end

    return Itemset.(unique(value.(newset)))
end


function contains(itemsets::Vector{<:Itemset{<:ItemsetContent}}, fragment::Itemset{<:Atom})
    for itemset in itemsets
        if value(fragment) in value(itemset)
            return true
        end
    end
    return false
end

function contains(
    itemsets::Vector{<:Itemset{<:ItemsetContent}},
    fragment::Itemset{<:LeftmostConjunctiveForm}
)
    for itemset in itemsets
        if length(intersect(value(itemset), value(fragment))) == length(fragment)
            return true
        end
    end

    return false
end

function Base.show(io::IO, items::Itemset{<:Item})
    print(io, "$(items |> value |> syntaxstring)")
end

function Base.show(io::IO, items::Itemset{<:LeftmostConjunctiveForm})
    print(io, "$(syntaxstring.(items |> value))")
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

antecedent(r::ARule) = r.rule[1]
consequent(r::ARule) = r.rule[2]
value(r::ARule) = (antecedent(r), consequent(r))

setlocalmemo(r::ARule, key::LmeasMemoKey, val::Float64) = r.lmemo[key] = val
getlocalmemo(r::ARule, key::LmeasMemoKey) = get(r.lmemo, key, nothing)

setglobalmemo(r::ARule, key::GmeasMemoKey, val::Float64) = r.gmemo[key] = val
getglobalmemo(r::ARule, key::GmeasMemoKey) = get(r.gmemo, key, nothing)

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

    # If possible, retrieve result from memoization structure inside itemset structure
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol
    ans = getlocalmemo(itemset, (fname, i_instance))
    if !isnothing(ans)
        return ans
    end

    # Compute local measure, then divide it by the instance total number of worlds
    ans = sum([check(value(itemset), X, i_instance, w) for w in allworlds(X, i_instance)])
    ans = ans / nworlds(X, i_instance)

    # Save result for optimization, using the name of this function as dict key
    setlocalmemo(itemset, (fname, i_instance), ans)
    return ans
end

function _gsupport(itemset::Itemset, X::SupportedLogiset, threshold::Float64)::Float64
    # If possible, retrieve result from memoization structure inside itemset structure
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol
    ans = getglobalmemo(itemset, fname)
    if !isnothing(ans)
        return ans
    end

    # Compute global measure, then divide it by the dataset total number of instances
    ans = sum([_lsupport(itemset, getinstance(X, i_instance)) >= threshold
        for i_instance in 1:ninstances(X)])
    ans = ans / ninstances(X)

    # Save result for optimization, using the name of this function as dict key
    setglobalmemo(itemset, fname, ans)
    return ans
end

function _lconfidence(r::ARule, logi_instance::LogicalInstance)::Float64
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    _antecedent = antecedent(r)
    _consequent = consequent(r)

    # TODO: exploit memoization here

    ans = _lsupport(SoleRules.merge(_antecedent, _consequent), logi_instance) /
        _lsupport(_antecedent, logi_instance)
    setlocalmemo(r, fname, ans) # Save result for optimization
    return ans
end

function _gconfidence(r::ARule, X::SupportedLogiset, threshold::Float64)::Float64
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    _antecedent = antecedent(r)
    _consequent = consequent(r)

    ans = _gsupport(SoleRules.merge(_antecedent, _consequent), X, threshold) /
        _gsupport(_antecedent, X, threshold)
    setlocalmemo(r, fname, ans) # Save result for optimization
    return ans
end

lsupport = ItemLmeas(_lsupport)
gsupport = ItemGmeas(_gsupport)
lconfidence = RuleLmeas(_lconfidence)
gconfidence = RuleGmeas(_gconfidence)

############################################################################################
#### Learning algorithms ###################################################################
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

    nonfreq_itemsets::Vector{Itemset}   # non-frequent itemsets dump
    freq_itemsets::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}               # collected association rules
    info::NamedTuple                    # general informations

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
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]), (;));
    end
end

const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

dataset(miner::ARuleMiner) = miner.X
algorithm(miner::ARuleMiner) = miner.algo
alphabet(miner::ARuleMiner) = miner.alphabet

item_meas(miner::ARuleMiner) = miner.item_constrained_measures
rule_meas(miner::ARuleMiner) = miner.rule_constrained_measures

freqitems(miner::ARuleMiner) = miner.freq_itemsets
nonfreqitems(miner::ARuleMiner) = miner.nonfreq_itemsets
arules(miner::ARuleMiner) = miner.arules

function mine(miner::ARuleMiner)
    apply(miner, dataset(miner))
end

function apply(miner::ARuleMiner, X::AbstractDataset)
    # extract frequent itemsets
    miner.algo(miner, X)
    return true
end
