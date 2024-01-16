############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
const Item = SoleLogics.Formula

# Dynamic programming utility structures
const LmeasMemoKey = Tuple{Symbol,Integer}
const LmeasMemo = Dict{LmeasMemoKey,Float64}

const GmeasMemoKey = Symbol
const GmeasMemo = Dict{GmeasMemoKey,Float64}

"""
    struct Itemset{T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
        value::T
        lmemo::LmeasMemo
        gmemo::GmeasMemo
    end

Antecedent or consequent of an association rule.
This structure wraps one or more [`Item`](@ref)s,
eventually representing them as a [`LeftmostLinearForm`](@ref).

See also [`LeftmostLinearForm`](@ref), [`ARule`](@ref), [`Item`](@ref).
"""
struct Itemset{T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
    value::T

    # memoization structures
    lmemo::LmeasMemo
    gmemo::GmeasMemo

    function Itemset{T}(
        value::T,
        lmemo::LmeasMemo,
        gmemo::GmeasMemo
        ) where {T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
        new{T}(value, lmemo, gmemo)
    end
    function Itemset(value::T) where {T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
        Itemset{T}(value, LmeasMemo(), GmeasMemo())
    end
    function Itemset(
        value::Vector{<:T}
    ) where {T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
        cnf = LeftmostConjunctiveForm(value)
        Itemset{typeof(cnf)}(cnf, LmeasMemo(), GmeasMemo())
    end
end

value(items::Itemset) = items.value isa LeftmostConjunctiveForm ?
    items.value |> children : items.value

setlocalmemo(items::Itemset, key::LmeasMemoKey, val::Float64) = items.lmemo[key] = val
getlocalmemo(items::Itemset, key::LmeasMemoKey) = get(items.lmemo, key, nothing)

setglobalmemo(items::Itemset, key::GmeasMemoKey, val::Float64) = items.gmemo[key] = val
getglobalmemo(items::Itemset, key::GmeasMemoKey) = get(items.gmemo, key, nothing)

function merge(item::Itemset, itemsets::NTuple{N,Itemset}) where {N}
    return reduce(vcat, value.([item, itemsets...])) |> Itemset
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

function lsupport(itemset::Itemset, logi_instance::LogicalInstance)::Float64
    # retrieve logiset, and the specific instance
    # NOTE: why does X, i_instance = splat(logi_instance) does not work?
    X, i_instance = logi_instance.s, logi_instance.i_instance
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    # If possible, retrieve from memoization structure inside itemset structure
    ans = getlocalmemo(itemset, (fname, i_instance))
    if !isnothing(ans)
        return ans
    end

    ans = sum([check(value(itemset), X, i_instance, w) for w in allworlds(X, i_instance)])
    setlocalmemo(itemset, fname, ans) # Save result for optimization
    return ans
end

function gsupport(itemset::Itemset, X::SupportedLogiset, threshold::Float64)::Float64
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    # If possible, retrieve from memoization structure inside itemset structure
    ans = getglobalmemo(itemset, fname)
    if !isnothing(ans)
        return ans
    end

    ans = sum([lsupport(itemset, getinstance(X, i_instance)) >= threshold
        for i_instance in 1:ninstances(X)])
    setglobalmemo(itemset, fname, ans) # Save result for optimization
    return ans
end

function lconfidence(rule::ARule, logi_instance::LogicalInstance)::Float64
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    ans = lsupport(merge(_antecedent, (_consequent)), logi_instance) /
        lsupport(_antecedent, logi_instance)
    setlocalmemo(rule, fname, ans) # Save result for optimization
    return ans
end

function gconfidence(rule::ARule, X::SupportedLogiset, threshold::Float64)::Float64
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    ans = gsupport(merge(_antecedent, (_consequent)), X, threshold) /
        gsupport(_antecedent, X, threshold)
    setlocalmemo(rule, fname, ans) # Save result for optimization
    return ans
end

############################################################################################
#### Learning algorithms ###################################################################
############################################################################################

const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

"""
Generic machine learning model interface to perform association rules extraction.
"""
@with_kw struct ARuleMiner
    # target dataset
    X::AbstractDataset
    # algorithm used to perform extraction
    algo::MiningAlgo
    alphabet::Vector{Item} # NOTE: cannot instanciate Item inside ExplicitAlphabet

    # local meaningfulness measures
    item_lmeas_constraints ::Vector{ItemLmeas} = [lsupport]
    arule_lmeas_constraints::Vector{RuleLmeas} = [lconfidence]

    # global meaningfulness measures, paired with real thresholds
    item_gmeas_constraints ::Vector{Tuple{ItemGmeas,Float64}} = [(gsupport,0.5)]
    arule_gmeas_constraints::Vector{Tuple{RuleGmeas,Float64}} = [(gconfidence,0.5)]

    freq_itemsets::Vector{Itemset}  # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules
    info::NamedTuple                # general informations

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item}
    )
        new(X, MiningAlgo(algo), alphabet,
            [lsupport], [lconfidence], [(gsupport,0.5)], [(gconfidence,0.5)],
            Vector{Itemset}([]), Vector{ARule}([]), (;))
    end
end

dataset(miner::ARuleMiner) = miner.X
miningalgo(miner::ARuleMiner) = miner.algo
alphabet(miner::ARuleMiner) = miner.alphabet
freqitems(miner::ARuleMiner) = miner.freq_itemsets
arules(miner::ARuleMiner) = miner.arules

function mine(miner::ARuleMiner)
    apply(miner, dataset(miner))
end

function apply(miner::ARuleMiner, X::AbstractDataset)
    # extract frequent itemsets
    miner.algo(miner, X)
end

"""
    apriori(dataset; inferatoms=frequent)
    apriori(dataset, atoms)

Perform Apriori algorithm over a (modal) dataset.
"""
function apriori(miner::ARuleMiner, X::AbstractDataset)::Nothing
    print("Apriori algorithm is working properly")
end

"""
Perform FP-Growth algorithm over a (modal) dataset.
"""
function fpgrowth(miner::ARuleMiner, X::AbstractDataset)
    Base.error("Method not implemented yet.")
end

"""
Perform Eclat algorithm over a (modal) dataset.
"""
function eclat(miner::ARuleMiner, X::AbstractDataset)
    Base.error("Method not implemented yet.")
end
