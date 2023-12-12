# Meaningfulness measures used for association rules mining.

"""
Local meaningfulness measure, referred to a set of [`Atom`](@ref)s.
Get a (modal) dataset instance and a set of [`Atom`](@ref)s to return a real value.
TODO: An example of local measure for atoms sets is local support, which is defined as...

TODO: See also...
"""
const lsetmeas  = FunctionWrapper{Float64, Tuple{Float64, Float64}}

"""
Local meaningfulness measure, referred to a set of [`AssociationRule`](@ref)s.
Get a (modal) dataset instance and an [`AssociationRule`](@ref) to return a real value.
TODO: An example of local measure for association rules is local confidence,
    which is defined as...

TODO: See also...
"""
const lrulemeas = FunctionWrapper{Float64, Tuple{Float64, Float64}}

"""
Global meaningfulness measure, referred to a set of [`Atom`](@ref)s.
Get a (modal) dataset and a set of [`Atom`](@ref)s to return a real value.
TODO: An example of global measure for atoms sets is global support, which is defined as...

TODO: See also...
"""
const gsetmeas  = FunctionWrapper{Float64, Tuple{Float64, Float64}}

"""
Global meaningfulness measure, referred to a set of [`AssociationRule`](@ref).
Get a (modal) dataset and an [`AssociationRule`](@ref) to return a real value.
TODO: An example of global measure for association rules is global confidence,
    which is defined as...

TODO: See also...
"""
const grulemeas = FunctionWrapper{Float64, Tuple{Float64, Float64}}
