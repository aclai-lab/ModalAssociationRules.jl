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
        info::InfoDictionary # TODO: change this
    end

Antecedent or consequent of an association rule.
This structure wraps one or more [`Item`](@ref)s,
eventually representing them as a [`LeftmostLinearForm`](@ref).

See also [`LeftmostLinearForm`](@ref), [`ARule`](@ref), [`Item`](@ref).
"""
struct Itemset{T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
    value::T

    lmemo::LmeasMemo
    gmemo::GmeasMemo

    function Itemset{T}(
        value::T,
        lmemo::LmeasMemo,
        gmemo::GmeasMemo
        ) where {T<:Union{Atom,LeftmostConjunctiveForm{<:Atom}}}
        new{T}(value, lmemo, gmemo)
    end
    function Itemset(value::T) where {T<:Union{Atom,LeftmostConjunctiveForm{<:Atom}}}
        Itemset{T}(value, LmeasMemo(), GmeasMemo())
    end
end

value(items::Itemset) = items.value

setlocalmemo(items::Itemset, key::LmeasMemoKey, val::Float64) = items.lmemo[key] = val
getlocalmemo(items::Itemset, key::LmeasMemoKey) = get(items.lmemo, key, nothing)

setglobalmemo(items::Itemset, key::GmeasMemoKey, val::Float64) = items.gmemo[key] = val
getglobalmemo(items::Itemset, key::GmeasMemoKey) = get(items.gmemo, key, nothing)

"""
    struct ARule
        rule::Rule{Itemset, Atom}
        info::InfoDictionary TODO: change this
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
    # Currently, consequent is composed of just a single Atom.
    rule::Rule{Itemset,Item}
end

############################################################################################
#### Meaningfulness measures ###############################################################
############################################################################################

# NOTE: SoleLogics.AbstractInterpretation could be SoleLogics.LogicalInstance
# which for example is obtained by using SoleLogics.getinstance(X,1) on a logiset X.
const doc_meaningfulness_meas = """
    const ItemLmeas = FunctionWrapper{Float64, Tuple{Itemset,AbstractInterpretation}}
    const ItemGmeas = FunctionWrapper{Float64, Tuple{Itemset,AbstractDataset,Threshold}}
    const RuleLmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractInterpretation}}
    const RuleGmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractDataset,Threshold}}

Function wrappers to express local and global meaningfulness measures of items and
association rules.

TODO: show how to wrap local and global support, confidence, lift and conviction.

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
    return !isnothing(ans) ? ans :
        sum([check(value(itemset), X, i_instance, w) for w in allworlds(X, i_instance)])
    end

function gsupport(itemset::Itemset, X::SupportedLogiset, threshold::Float64)
    fname = Symbol(StackTraces.stacktrace()[1].func) # this function name, as Symbol

    # If possible, retrieve from memoization structure inside itemset structure
    ans = getglobalmemo(itemset, fname)
    return !isnothing(ans) ? ans :
        sum([
            lsupport(itemset, getinstance(X, i_instance)) >= threshold
            for i_instance in 1:ninstances(X)])
end

############################################################################################
#### Learning algorithms ###################################################################
############################################################################################

"""
Association rule extraction configuration struct.
"""
struct Configuration
    # list of available literals
    alphabet::Vector{Item} # NOTE: cannot instanciate Item inside ExplicitAlphabet

    # meaningfulness measures
    item_lmeas_constraints ::Vector{Tuple{ItemLmeas,Float64}}
    item_gmeas_constraints ::Vector{Tuple{ItemGmeas,Float64}}
    arule_lmeas_constraints::Vector{Tuple{RuleLmeas,Float64}}
    arule_gmeas_constraints::Vector{Tuple{RuleGmeas,Float64}}
end

"""
Extracts frequent [`Atom`](@ref)s from a (modal) dataset.
"""
function frequent(::AbstractDataset)
    print("frequent call")
end

"""
    apriori(dataset; inferatoms=frequent)
    apriori(dataset, atoms)

Perform Apriori algorithm over a (modal) dataset.
"""
function apriori()
    Base.error("Method not implemented yet.")
end

"""
Perform FP-Growth algorithm over a (modal) dataset.
"""
function fpgrowth()
    Base.error("Method not implemented yet.")
end

"""
Perform Eclat algorithm over a (modal) dataset.
"""
function eclat()
    Base.error("Method not implemented yet.")
end
