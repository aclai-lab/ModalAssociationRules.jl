############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################

"""
    const INFO_DICTIONARY = Dict{Symbol, Tuple{Float64,String}}

This type is intended to be used to collect meta informations in a [`Itemset`](@ref)
or an [`ARule`](@ref).

Consider an [`Itemset`](@ref) or an [`ARule`](@ref), and call it `φ`.
This type maps a meaningfulness measure `f` to a pair (`n`, `description`) containing the
real value `n` and a the string `description` identifying a specific entity `obj` for which
`f(obj, φ) = n`.

See also [`Arule`](@ref), [`Itemset`](@ref).
"""
const INFO_DICTIONARY = Dict{Symbol, Tuple{Float64,String}}

"""
    struct Itemset{T<:Union{Atom,LeftmostConjunctiveForm}}
        content::T
        info::INFO_DICTIONARY
    end

Antecedent or consequent of an association rule.
This structure wraps one or more [`Atom`](@ref)s,
eventually representing them as a [`LeftmostLinearForm`](@ref).

See also [`LeftmostLinearForm`](@ref), [`ARule`](@ref), [`Atom`](@ref).
"""
struct Itemset{T<:Union{Atom,LeftmostConjunctiveForm}}
    content::T
    info::INFO_DICTIONARY

    function Itemset{T}(
        value::T,
        info::INFO_DICTIONARY
        ) where {T<:Union{Atom,LeftmostConjunctiveForm}}
        new{T}(value, info)
    end
    function Itemset(value::T) where {T<:Union{Atom,LeftmostConjunctiveForm}}
        Itemset{T}(value, INFO_DICTIONARY())
    end
    function Itemset(
        value::T,
        info::INFO_DICTIONARY
    ) where {T<:Union{Atom,LeftmostConjunctiveForm}}
        Itemset{T}(value, info)
    end
end

"""
    struct ARule
        rule::Rule{Vector{Itemset}, Atom}
        info::INFO_DICTIONARY
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
    rule::Rule{Vector{Itemset}, Atom}
    info::INFO_DICTIONARY
end

############################################################################################
#### Meaningfulness measures ###############################################################
############################################################################################

const doc_meaningfulness_meas = """
    const ITEM_LMEAS = FunctionWrapper{Float64, Tuple{Itemset, AbstractWorld}}
    const ITEM_GMEAS = FunctionWrapper{Float64, Tuple{Itemset, AbstractDataset}}
    const RULE_LMEAS = FunctionWrapper{Float64, Tuple{ARule, AbstractWorld}}
    const RULE_GMEAS = FunctionWrapper{Float64, Tuple{ARule, Float64}}

Function wrappers to express local and global meaningfulness measures of items and
association rules.

TODO: show how to wrap local and global support, confidence, lift and conviction.

See also [`ARule`](@ref), [`FunctionWrapper`](@ref), [`Itemset`](@ref).
"""

"""$(doc_meaningfulness_meas)"""
const ITEM_LMEAS = FunctionWrapper{Float64, Tuple{Itemset, AbstractWorld}}

"""$(doc_meaningfulness_meas)"""
const ITEM_GMEAS = FunctionWrapper{Float64, Tuple{Itemset, AbstractDataset}}

"""$(doc_meaningfulness_meas)"""
const RULE_LMEAS = FunctionWrapper{Float64, Tuple{ARule, AbstractWorld}}

"""$(doc_meaningfulness_meas)"""
const RULE_GMEAS = FunctionWrapper{Float64, Tuple{ARule, Float64}}

# NOTE: could this be better?
# const MEANINGFULNESS_MEASURE = FunctionWrapper{
#     Float64, Tuple{Union{ARule,Itemset}, Union{AbstractDataset,AbstractWorld}}}

############################################################################################
#### Learning algorithms ###################################################################
############################################################################################

"""
Association rule extraction configuration struct.
"""
struct Configuration
    item_lmeas_constraints  = Vector{Tuple{ITEM_LMEAS, Float64}}
    item_gmeas_constraints  = Vector{Tuple{ITEM_LMEAS, Float64}}
    arule_lmeas_constraints = Vector{Tuple{ARule, Float64}}
    arule_gmeas_constraints = Vector{Tuple{ARule, Float64}}

    # TODO: list of available literals
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
