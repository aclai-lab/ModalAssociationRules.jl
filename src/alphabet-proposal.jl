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
- `aggregator::Symbol=:cluster`: can be `:cluster` or `:mean`; in the former case, the
    representative for each motif group is its centroid, while in the latter case mean is
    computed at every point.

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
    r::Integer=2,
    th::Integer=5,
    aggregator=:cluster
) where {T<:Real}
    xmprofile = matrix_profile(x, windowlength)
    xmotifs = motifs(xmprofile, nmotifs; r=r, th=th)

    _clean_xmotifs = Vector{T}[]
    for _group in xmotifs
        _all_motifs = _group |> seqs
        if aggregator == :cluster
            # reshape all the vectors in a motif group, in order to have a matrix
            _matrix_motifs = reduce(hcat, _all_motifs)

            # find the centroid
            ans = kmeans(_matrix_motifs, 1)

            # push the only center in the collection
            eps = 1e-10
            centroid = ans.centers[:]
            normalizedcentroid = (centroid .- mean(centroid)) ./ (std(centroid) + eps)
            push!(_clean_xmotifs, normalizedcentroid)

        elseif aggregator == :mean
            push!(_clean_xmotifs, sum(_all_motifs) ./ length(_all_motifs))
        else
            throw(DomainError("Invalid value for aggregator kwarg. Suitable values are " *
                ":cluster (default) or :mean"
            ))
        end
    end

    return xmprofile, xmotifs, _clean_xmotifs
end
