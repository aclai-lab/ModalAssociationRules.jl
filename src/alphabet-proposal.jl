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
- `filterbylength::Integer=2`: filter out the motifs which are rarely found
    (less than 2 times);
- `alphabetsize::Integer=3`: cardinality of the output alphabet.

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
    x::Vector{<:Real},
    windowlength::Integer,
    nmotifs::Integer;
    rng::Union{Integer,AbstractRNG}=Random.GLOBAL_RNG,
    r::Integer=5,
    th::Integer=0,
    kwargs...
)
    xmprofile = matrix_profile(x, windowlength)
    xmotifs = motifs(xmprofile, nmotifs; r=r, th=th)

    alphabet = _processalphabet(xmotifs; rng=initrng(rng), kwargs...)

    return alphabet
end

# utility to apply a collection of filter! to an alphabet of motifs;
# see `motifsalphabet` docstring.
function _processalphabet(
    xmotifs::Vector{MatrixProfile.Motif};
    filterbylength::Integer=2,
    alphabetsize::Integer=3,
    rng::AbstractRNG
)::Vector{<:Vector{<:Real}}
    # remove unique-motifs (which are not truly meaningful)
    if filterbylength > 1
        filter!(motif -> length(motif.seqs) >= filterbylength, xmotifs)
    end

    # for each motif group after the filtering,
    # keep a number of columns equal to a window length
    processed_motifs = Matrix{Float32}(
        undef, length(xmotifs), length(xmotifs |> first |> seqs |> first))

    # for each motif group, create a representative motif (pointwise mean)
    for (row, motif_group) in enumerate(xmotifs)
        processed_motifs[row,:] = mean([m for m in seqs(motif_group)])
    end

    # apply clustering, depending on how "granular"
    # you want your alphabet to be.
    motifs_cluster = Clustering.kmeans(processed_motifs', alphabetsize; rng=rng)

    # for each cluster, compute another representative motif (pointwise mean);
    # collect all such representatives.
    clusterid_to_motifs = Dict{Int, Vector{Vector{Float32}}}()
    cluster_ids = Clustering.assignments(motifs_cluster)

    # separate by cluster id
    for (idx, _motif) in enumerate(processed_motifs |> eachrow)
        clusterid = cluster_ids[idx]
        if !haskey(clusterid_to_motifs, clusterid)
            clusterid_to_motifs[clusterid] = [_motif]
        else
            push!(clusterid_to_motifs[clusterid], _motif)
        end
    end

    # aggregate by means (we no longer care about cluster ids)
    proposal = [mean(_motifs) for _motifs in values(clusterid_to_motifs)]

    return proposal
end
