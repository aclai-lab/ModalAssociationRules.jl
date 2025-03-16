using Random # see `motifsalphabet warning docstring`
using SoleBase: initrng

"""
    function motifsalphabet(
        x::Vector{<:Vector{<:Real}},
        windowlength::Integer,
        nmotifs::Integer;
        kwargs...
   )

    function motifsalphabet(
        x::Vector{<:Real},
        windowlength::Integer,
        nmotifs::Integer;
        r=5,
        th=0,
    )

Propose an alphabet of propositional letters, by leveraging `MatrixProfile` motifs
identification capabilities.

# Arguments
- `x::Union{Vector{Vector{<:Real}},Vector{<:Real}}}`: a representative time series, from
    which extract motifs; if multiple time series are provided, they are concatenated
    together;
- `windowlength::Integer=10`: the length of each extracted motif;
- `nmotifs::Integer=3`: the number of motifs to extract;

# Keyword Arguments
- `rng::Union{Integer,AbstractRNG}=Random.GLOBAL_RNG`: custom RNG, used internally by KNN;
- `r::Integer=2`: how similar two windows must be to belong to the same motif;
- `th::Integer=5`: how nearby in time two motifs are allowed to be;

See also `MatrixProfile.jl`.
"""
function motifsalphabet(
    x::Vector{<:Vector{<:Real}},
    windowlength::Integer,
    nmotifs::Integer;
    kwargs...
)
    # concatenate all the samples one after the other;
    # then proceed to compute the matrix profile and extract
    # the top k motifs.

    # when concatenating, apply a little correction to avoid clippings
    for i in 2:length(x)
        x[i] = x[i] .- (x[i][1] - x[i-1][1])
    end

    motifsalphabet(reduce(vcat, x), windowlength, nmotifs; kwargs...)
end

function motifsalphabet(
    x::Vector{T},
    windowlength::Integer,
    nmotifs::Integer;
    r::Integer=5,
    th::Integer=0
) where {T<:Real}
    xmprofile = matrix_profile(x, windowlength)
    xmotifs = motifs(xmprofile, nmotifs; r=r, th=th)

    _clean_xmotifs = Vector{T}[]
    for _group in xmotifs
        _all_motifs = _group |> seqs
        push!(_clean_xmotifs, sum(_all_motifs) ./ length(_all_motifs))
    end

    return xmprofile, xmotifs, _clean_xmotifs
end
