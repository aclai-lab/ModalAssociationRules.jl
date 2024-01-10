# Take a meaningfulness measure function as a string,
# and where it has been applied (label to indicate the specific dataset/instance).
# Then, associate the pair above with a real value.
const INFO_DICTIONARY = Dict{Tuple{String,String}, Float64}

"""
Antecedent or consequent of an association rule.
This structure wraps an [`Atom`](@ref) or more,
representing them as a [`LeftmostLinearForm`](@ref).

See also [`LeftmostLinearForm`](@ref), [`ARule`](@ref), [`Atom`](@ref).
"""
struct Item{T<:Union{Atom,LeftmostConjunctiveForm}}
    content::T
    info::INFO_DICTIONARY

    function Item{T}(
        value::T,
        info::INFO_DICTIONARY
        ) where {T<:Union{Atom,LeftmostConjunctiveForm}}
        new{T}(value, info)
    end
    function Item(value::T) where {T<:Union{Atom,LeftmostConjunctiveForm}}
        Item{T}(value, INFO_DICTIONARY())
    end
    function Item(
        value::T,
        info::INFO_DICTIONARY
    ) where {T<:Union{Atom,LeftmostConjunctiveForm}}
        Item{T}(value, info)
    end
end

"""
[`Rule`](@ref) object, specialized to represent association rules.
An association rule is a rule expressing a statistically meaningful relation between
antecedent and consequent (e.g., if facts in the antecedent are true together on a model,
probably the facts in the consequent are true too on the same model).

Both antecedent and consequent are (vector of) [`Item`](@ref)s.

See also [`SoleLogics.Atom`](@ref), [`SoleModels.antecedent`](@ref),
[`SoleModels.consequent`](@ref), [`Item`](@ref), [`SoleModels.Rule`](@ref).
"""
struct ARule
    # Currently, consequent is composed of just a single Atom.
    rule::Rule{Vector{Item}, Atom}
    info::INFO_DICTIONARY
end

"""
Configuration of an association rule extraction algorithm.

See also [`apriori`](@ref), [`fpgrowth`](@ref), [`eclat`](@ref).
"""
struct Configuration
    # Pass this configuration to a AR algorithm
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
