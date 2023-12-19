"""
[`Rule`](@ref) object in which the antecedent is a single [`Atom`](@ref)
or a conjunction of [`Atom`](@ref)s, also said LeftmostConjunctiveForm,
and the consequent is a single [`Atom`](@ref).

See also [`SoleLogics.Atom`](@ref), [`SoleModels.antecedent`](@ref),
[`SoleModels.consequent`](@ref), [`SoleModels.Rule`](@ref).
"""
struct ARule
    rule::Rule{Union{Atom,LeftmostConjunctiveForm}, Atom}

    # Take a meaningfulness measure function as a string,
    # and where it has been applied (dataset/instance string representation).
    # Then, associate the pair above with a real value.
    info::Dict{Tuple{String,String}, Float64}
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
