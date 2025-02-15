""" 
    function proposal(
        X::Vector{<:Vector{<:Real}},
        windowlength::Integer,
        nmotifs::Integer;
        kwargs...
   )

    function proposal(
        X::Vector{<:Real},
        windowlength::Integer,
        nmotifs::Integer;
        r=5,
        th=0,
        distillatemotifs=true
    )

Propose an alphabet of propositional letters, by leveraging MatrixProfile motifs identification capabilities.

# Arguments
- `X::Union{Vector{Vector{<:Real}},Vector{<:Real}}}`: a representative time series, from which extract motifs; if multiple time series are provided, they are concatenated together;
- `windowlength::Integer=10`: the length of each extracted motif;
- `nmotifs::Integer=3`: the number of motifs to extract;
- `r::Integer=2`: how similar two windows must be to belong to the same motif;
- `th::Integer=5`: how nearby in time two motifs are allowed to be;
- `distillatemotifs::Bool`: filter out the motifs which are rarely found (less than 2 times).
"""
function proposal(
    X::Vector{<:Vector{<:Real}},
    windowlength::Integer,
    nmotifs::Integer;
    kwargs...
)
    # concatenate all the samples one after the other;
    # then proceed to compute the matrix profile and extract 
    # the top k motifs.
    proposal(reduce(vcat, X), windowlength, nmotifs; kwargs...)
end

function proposal(
    X::Vector{<:Real},
    windowlength::Integer,
    nmotifs::Integer;
    r::Integer=5,
    th::Integer=0,
    distillatemotifs::Bool=true
)
    Xmprofile = matrix_profile(X, windowlength)
    Xmotifs = motifs(Xmprofile, nmotifs; r=r, th=th)

    # filter the identified motifs which are single
    distillatemotifs && filter(motif -> length(motif.seqs) >= 2, Xmotifs)

    return Xmotifs
end
