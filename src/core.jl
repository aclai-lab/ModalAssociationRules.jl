"""
[`Rule`](@ref) object in which the antecedent is a conjunction of [`Atom`](@ref)s,
also said LeftmostConjunctiveForm, and the consequent is a single [`Atom`](@ref).

See also [`SoleLogics.Atom`](@ref), [`SoleModels.antecedent`](@ref),
[`SoleModels.consequent`](@ref), [`SoleModels.Rule`](@ref).
"""
struct AssociationRule
    rule::Rule{LeftmostConjunctiveForm, Atom}

    # Take a meaningfulness measure function as a string,
    # and where it has been applied (dataset/instance string representation).
    # Then, associate the pair above with a real value.
    info::Dict{Tuple{String,String} => Float64}
end

"""
Extracts frequent [`Atom`](@ref)s from a (modal) dataset.
"""
function frequent()
    print("frequent call")
end

"""
    apriori(dataset; inferatoms=frequent)
    apriori(dataset, atoms)

Perform Apriori algorithm over a dataset.
"""
function apriori()
    print("apriori call.")
end

"""
Perform FP-Growth algorithm over a dataset.
"""
function fpgrowth()
    print("fpgrowth call.")
end
