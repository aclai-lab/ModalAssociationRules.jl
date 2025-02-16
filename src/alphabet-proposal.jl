""" 
    function proposealphabet(
        X::Vector{<:Vector{<:Real}},
        windowlength::Integer,
        nmotifs::Integer;
        kwargs...
   )

    function proposealphabet(
        X::Vector{<:Real},
        windowlength::Integer,
        nmotifs::Integer;
        r=5,
        th=0,
        applyfilters=true
    )

Propose an alphabet of propositional letters, by leveraging MatrixProfile motifs identification capabilities.

# Arguments
- `X::Union{Vector{Vector{<:Real}},Vector{<:Real}}}`: a representative time series, from which extract motifs; if multiple time series are provided, they are concatenated together;
- `windowlength::Integer=10`: the length of each extracted motif;
- `nmotifs::Integer=3`: the number of motifs to extract;

# Keyword Arguments
- `r::Integer=2`: how similar two windows must be to belong to the same motif;
- `th::Integer=5`: how nearby in time two motifs are allowed to be;
- `applyfilters::Bool=true`: decide whether to apply the filters (see the following kwargs) or not;
- `filterbylength::Integer`: filter out the motifs which are rarely found (less than 2 times);
- `filterbysim::Real`: TODO.
"""
function proposealphabet(
    X::Vector{<:Vector{<:Real}},
    windowlength::Integer,
    nmotifs::Integer;
    kwargs...
)
    # concatenate all the samples one after the other;
    # then proceed to compute the matrix profile and extract 
    # the top k motifs.
    proposealphabet(reduce(vcat, X), windowlength, nmotifs; kwargs...)
end

function proposealphabet(
    X::Vector{<:Real},
    windowlength::Integer,
    nmotifs::Integer;
    r::Integer=5,
    th::Integer=0,
    applyfilters::Bool=true,
    kwargs...
)
    Xmprofile = matrix_profile(X, windowlength)
    Xmotifs = motifs(Xmprofile, nmotifs; r=r, th=th)

    applyfilters && _filteralphabet!(Xmotifs; kwargs...)

    return Xmotifs
end

# utility to apply a collection of filter! to an alphabet of motifs
function _filteralphabet!(
    Xmotifs::Vector{MatrixProfile.Motif};
    filterbylength::Integer=2,
    filterbysim::Real=1.0f0
)
    if filterbylength > 1
        filter!(motif -> length(motif.seqs) >= filterbylength, Xmotifs)
    end
 
    if filterbysim
        # TODO 
    end

    return Xmotifs
end

