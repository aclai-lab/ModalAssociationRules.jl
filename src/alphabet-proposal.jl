""" 
    function proposealphabet(
        x::Vector{<:Vector{<:Real}},
        windowlength::Integer,
        nmotifs::Integer;
        kwargs...
   )

    function proposealphabet(
        x::Vector{<:Real},
        windowlength::Integer,
        nmotifs::Integer;
        r=5,
        th=0,
    )

Propose an alphabet of propositional letters, by leveraging `MatrixProfile` motifs identification capabilities.

# Arguments
- `x::Union{Vector{Vector{<:Real}},Vector{<:Real}}}`: a representative time series, from which extract motifs; 
    if multiple time series are provided, they are concatenated together;
- `windowlength::Integer=10`: the length of each extracted motif;
- `nmotifs::Integer=3`: the number of motifs to extract;

# Keyword Arguments
- `r::Integer=2`: how similar two windows must be to belong to the same motif;
- `th::Integer=5`: how nearby in time two motifs are allowed to be;
- `filterbylength::Integer=2`: filter out the motifs which are rarely found (less than 2 times);
- `clusterbysim::Real=1.0`: aggregate multiple motifs if they are equally informative, that is,
    their (normalized) euclidean distance is under this threshold.
"""
function proposealphabet(
    x::Vector{<:Vector{<:Real}},
    windowlength::Integer,
    nmotifs::Integer;
    kwargs...
)
    # concatenate all the samples one after the other;
    # then proceed to compute the matrix profile and extract 
    # the top k motifs.
    proposealphabet(reduce(vcat, x), windowlength, nmotifs; kwargs...)
end

function proposealphabet(
    x::Vector{<:Real},
    windowlength::Integer,
    nmotifs::Integer;
    r::Integer=5,
    th::Integer=0,
    kwargs...
)
    xmprofile = matrix_profile(x, windowlength)
    xmotifs = motifs(xmprofile, nmotifs; r=r, th=th)

    _processalphabet!(xmotifs; kwargs...)

    return xmotifs
end

# utility to apply a collection of filter! to an alphabet of motifs;
# see `proposealphabet` docstring. 
function _processalphabet!(
    xmotifs::Vector{MatrixProfile.Motif};
    filterbylength::Integer=2,
    clusterbysim::Real=1.0f0
)
    processed_motifs = Vector{Float32}[] 

    if filterbylength > 1
        filter!(motif -> length(motif.seqs) >= filterbylength, xmotifs)
    end
     
    for motif_group in xmotifs
        push!(processed_motifs, mean([m for m in seqs(motif_group)]))
    end
    
    # TODO: see how to perform Motif clustering
            
    if clusterbysim > 0.0
        
    end

    return processed_motifs 
end

