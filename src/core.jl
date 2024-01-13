############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################

"""
    const InfoDictionary = Dict{Symbol,Tuple{Float64,String}}

This type is intended to be used to collect meta informations in a [`Itemset`](@ref)
or an [`ARule`](@ref).

Consider an [`Itemset`](@ref) or an [`ARule`](@ref), and call it `φ`.
This type maps a meaningfulness measure `f` to a pair (`n`, `description`) containing the
real value `n` and a the string `description` identifying a specific entity `obj` for which
`f(obj, φ) = n`.

See also [`Arule`](@ref), [`Itemset`](@ref).
"""
const InfoDictionary = Dict{Symbol,Tuple{Float64, NamedTuple}}

const Item = SoleLogics.Formula

"""
    struct Itemset{T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
        content::T
        info::InfoDictionary
    end

Antecedent or consequent of an association rule.
This structure wraps one or more [`Item`](@ref)s,
eventually representing them as a [`LeftmostLinearForm`](@ref).

See also [`LeftmostLinearForm`](@ref), [`ARule`](@ref), [`Item`](@ref).
"""
struct Itemset{T<:Union{Item,LeftmostConjunctiveForm{<:Item}}}
    content::T
    info::InfoDictionary

    function Itemset{T}(
        value::T,
        info::InfoDictionary
        ) where {T<:Union{Atom,LeftmostConjunctiveForm{<:Atom}}}
        new{T}(value, info)
    end
    function Itemset(value::T) where {T<:Union{Atom,LeftmostConjunctiveForm{<:Atom}}}
        Itemset{T}(value, InfoDictionary())
    end
    function Itemset(
        value::T,
        info::InfoDictionary
    ) where {T<:Union{Atom,LeftmostConjunctiveForm{<:Atom}}}
        Itemset{T}(value, info)
    end
end

"""
    struct ARule
        rule::Rule{Itemset, Atom}
        info::InfoDictionary
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
    info::InfoDictionary
end

############################################################################################
#### Meaningfulness measures ###############################################################
############################################################################################

# NOTE: SoleLogics.AbstractInterpretation could be SoleLogics.LogicalInstance
# which for example is obtained by using SoleLogics.getinstance(X,1) on a logiset X.
const doc_meaningfulness_meas = """
    const ItemLmeas = FunctionWrapper{Float64, Tuple{Itemset,AbstractInterpretation}}
    const ItemGmeas = FunctionWrapper{Float64, Tuple{Itemset,AbstractDataset}}
    const RuleLmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractInterpretation}}
    const RuleGmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractDataset}}

Function wrappers to express local and global meaningfulness measures of items and
association rules.

TODO: show how to wrap local and global support, confidence, lift and conviction.

See also [`ARule`](@ref), [`FunctionWrapper`](@ref), [`Itemset`](@ref).
"""

"""$(doc_meaningfulness_meas)"""
const ItemLmeas = FunctionWrapper{Float64,Tuple{Itemset,AbstractInterpretation}}

"""$(doc_meaningfulness_meas)"""
const ItemGmeas = FunctionWrapper{Float64,Tuple{Itemset,AbstractDataset}}

"""$(doc_meaningfulness_meas)"""
const RuleLmeas = FunctionWrapper{Float64,Tuple{ARule,AbstractInterpretation}}

"""$(doc_meaningfulness_meas)"""
const RuleGmeas = FunctionWrapper{Float64, Tuple{ARule,AbstractDataset}}

# upgrade measfn function, making a fixed dataset X visible in its scope
macro build_lmeas(X, measfn)
    quote
        function lmeas()
            X = $X
            return $measfn
        end
    end
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
