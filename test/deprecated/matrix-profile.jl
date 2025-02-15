using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Statistics

X, _ = load_NATOPS();

# right hand y axis
variable = 5 

# right hand in "I have command class"
IHCC = Vector{Float32}.(X[1:30, variable]) 

# parameters for matrix profile generation 
windowlength = 10 
nmotifs = 3
r = 2   # how similar two windows must be to belong to the same motif
th = 5  # how nearby in time two motifs are allowed to be

# consider three different samples for IHCC:
# compute each corresponding matrix profile
# and retrieve every profile's motifs list.
s1, s2, s3, s4, s5 = IHCC[1:5]

profile1 = matrix_profile(s1, windowlength)
motifs1 = motifs(profile1, nmotifs; r=r, th=th)

profile2 = matrix_profile(s2, windowlength)
motifs2 = motifs(profile2, nmotifs; r=r, th=th)

profile3 = matrix_profile(s3, windowlength)
motifs3 = motifs(profile3, nmotifs; r=r, th=th)

p1 = plot(profile1, motifs1)
p2 = plot(profile2, motifs2)
p3 = plot(profile3, motifs3)
# plot(p1, p2, p3, layout=(1,3), size=(900,300))

# we focus on the first motif extracted from the first instance
# and compare them onto the other two
profile_m1s2 = matrix_profile(motifs1[1].seqs[1].seq, s2, windowlength)
profile_m1s3 = matrix_profile(motifs1[1].seqs[1].seq, s3, windowlength)
# plot(profile_m1s2)
# plot(profile_m1s3)


"""
Given a representative time series s1, and a list of time series s2...sN,
extract the motifs in s1 and try to find them in s2...sN.

Return the comparison as a plot.

# Arguments
- `s1::Vector{Float32}`: a representative time series, from which extract motifs;
- `ss::Vector{Vector{Float32}}`: other time series, in which `s1` are matched;
- `windowlength::Integer=10`: the length of each extracted motif;
- `nmotifs::Integer=3`: the number of motifs to extract;
- `r::Float32=2.0f0`: how similar two windows must be to belong to the same motif;
- `th::Float32=5.0f0`: how nearby in time two motifs are allowed to be;
- `motif_plotoffset::Float32=0.1f0`: noise to slightly move the motifs in the resulting plot.

"""
function motifs_comparison(
    s1::Vector{Float32}, 
    ss::Vector{Vector{Float32}};
    windowlength::Integer=10,
    nmotifs::Integer=3,
    r::Integer=2,
    th::Integer=5,
    motif_plotoffset::Float32=0.1f0
)
    profile1 = matrix_profile(s1, windowlength)
    motifs1 = motifs(profile1, nmotifs; r=r, th=th)

    # try to match the motifs just extracted, in each timeseries in ss;
    # sort the matches: later, the colors will coincide with the ones
    # in s1 plot.
    patterns = [
        sort!(
            encode_from_motifs(motifs1, s, windowlength),
            by=x -> x[1],
        )
        for s in ss
    ]

    # plots collections; each plot has the matching motifs highlighted
    poms = [plot_overlaying_motifs(s1, motifs1; title="Reference ts")]

    for (i,s) in enumerate(ss)
        new_pom = plot(s)::Plots.Plot
        for (id, startx, values) in patterns[i] 
            x = startx:(startx+length(values)-1)
            plot!(x, values .+ motif_plotoffset * id)
        end

        # if doesn't work, substitute push with append
        push!(poms, new_pom)
    end
 
    return plot(poms..., layout=(1+length(ss),1))
end

function encode_from_motifs(
    motifs::AbstractVector, 
    s::Vector{<:Float32}, 
    windowlength::Integer;
    match_threshold::Float32=0.5f0,
    samemotif_position_treshold::Integer=windowlength
)
    # ith motif to the locations where it is matched
    motif_locations = Dict()

    for (i, motif) in enumerate(motifs) 
        # compute matrix profile, using the motif as query on the series
        profile_ms = matrix_profile(motif.seqs[1].seq, s, windowlength)
        profile = profile_ms.P

        # retrieve all the locations in which the query is also s' motif
        locations = findall(d -> d < match_threshold, profile)
        
        # save the occurrences, but remove redundancies
        motif_locations[i] = [
            locations[1]; [
                locations[i] 
                for i in 2:length(locations) 
                if locations[i] > locations[i-1] + samemotif_position_treshold
            ]
        ]
    end

    # extract all the segments in which a motif is matched
    segments = [
        (motif_idx, location_idx, s[location_idx:(location_idx+windowlength)])
        for (motif_idx, locations) in motif_locations
        for location_idx in locations
    ]

    return segments
end


function plot_overlaying_motifs(s::Vector{Float32}, motifs::Vector{MatrixProfile.Motif}; kwargs...)
    seq_onset_pairs = [(motif.seqs[1].seq, motif.seqs[1].onset) for motif in motifs]
    plot_overlaying_motifs(s, seq_onset_pairs; kwargs...)
end

function plot_overlaying_motifs(
    s::Vector{Float32}, 
    motifs::Vector{Tuple{Vector{Float32}, Int64}};
    title::String=""
)
    p = plot(s, title=title)

    id=1 # just to add an incremental offset, to better show the motifs
    for (seq, onset) in motifs
        x = onset:(onset+length(seq)-1)
        plot!(x, seq.+0.1*id)
        id+=1
    end

    return p
end

patterns2 = encode_from_motifs(motifs1, s2, windowlength)
patterns3 = encode_from_motifs(motifs1, s3, windowlength)

l = @layout [a; b; c]

pom1 = plot_overlaying_motifs(s1, motifs1; title="Reference ts")

pom2 = plot(s2)
# patterns2 must be sorted by id, 
# to eventually keep the colors matched w.r.t. previous plot
sort!(patterns2, by=x -> x[1])
for (id, startx, values) in patterns2
    x = startx:(startx+length(values)-1)
    plot!(x, values.+0.1*id) 
end

pom3 = plot(s3)
# patterns2 must be sorted by id, 
# to eventually keep the colors matched w.r.t. previous plot
sort!(patterns3, by=x -> x[1])
for (id, startx, values) in patterns3
    x = startx:(startx+length(values)-1)
    plot!(x, values.+0.1*id) 
end

plot(pom1, pom2, pom3, layout=l)

