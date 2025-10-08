# utility file for generating a synthetic modal dataset (logiset);
# these dispatches may already exist in SoleLogics or SoleData, but I need an experimental
# version of them.

"""
    function generate(
        fr::SoleLogics.AbstractFrame{W},
        facts::Vector{S},
        truthvalues::Union{A,T};
        fulltransfer::Bool=true,
        incremental::Bool=false,
        random::Bool=false,
        rng::Bool=true,
    ) where {
        W<:AbstractWorld,
        S<:SyntaxLeaf,
        A<:SoleLogics.AbstractAlgebra,
        T<:Truth
    }::KripkeStructure

Generate a `SoleLogics.KripkeStructure`, starting from an `AbstractFrame`;
you can generate the latter using `randframe(rng, nworlds, nedges)`.

# Arguments
- `fr::SoleLogics.AbstractFrame{W}`: frame containing only worlds (nodes) and relations
(edges);
- `facts::Vector{S}`: facts whose truth value can be evaluated on each world;
- `truthvalues::Union{A,T}`: legal truth values, such as
SoleLogics.BooleanAlgebra() |> inittruthvalues).

# Keyword Arguments
`fulltransfer::Bool=true`: set all the `facts` to be `truthvalues[1]` on every world;
this is useful if you are generating a degenerate, propositional dataset.
`incremental::Bool=false`: set the `facts[1]` to be true on the first world,
`facts[1:2]` to be true on the second world, ..., `facts[1:nworlds]` to be true on the last
world;
`random::Bool=false`: set a truth value for each fact on every world, and choose its value
randomly;
`rng::AbstractRNG=false`: required by `random=true`.
"""
function generate(
    fr::SoleLogics.AbstractFrame{W},
    facts::Vector{S},
    truthvalues::Vector{T};
    fulltransfer::Bool=true,
    incremental::Bool=false,
    random::Bool=false,
    rng::Union{AbstractRNG,Nothing}=nothing,
)::KripkeStructure where {
    W<:AbstractWorld,
    S<:SyntaxLeaf,
    T<:Truth
}
    defaulttruth = truthvalues |> first    # default truth value for later assignments

    if fulltransfer
        # everything is true on every world
        valuation = Dict([
            w => TruthDict([f => defaulttruth for f in facts]) for w in fr.worlds
        ])
    elseif incremental
        # facts[1:i] are all true on the worlds from the first to the ith.
        valuation = Dict([
            w => TruthDict([f => defaulttruth for f in facts[1:i]])
            for (i,w) in enumerate(fr.worlds)
        ])
    elseif random
        try
            valuation = Dict([
                w => TruthDict([f => rand(rng, truthvalues) for f in facts])
                for w in fr.worlds
            ])
        catch e
            if isa(e, UndefKeywordError)
                throw(UndefKeywordError("Please provide a rng::AbstractRNG."))
            end
        end
    else
        throw(ArgumentError("The requested functionality is still not implemented."))
    end

    return KripkeStructure(fr, valuation)
end
