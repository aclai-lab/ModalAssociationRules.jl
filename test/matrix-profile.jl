using Distances # could be removed
using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using TSML      # could be removed

X, _ = load_NATOPS();

# right hand y axis
variable = 5 

# right hand in "I have command class"
IHCC = Vector{Float32}.(X[1:30, variable]) 

# parameters for matrix profile generation 
window_length = 10 
n_motifs = 5 
r = 4   # how similar two windows must be to belong to the same motif
th = 2  # how nearby in time two motifs are allowed to be

# consider three different samples for IHCC:
# compute each corresponding matrix profile
# and retrieve every profile's motifs list.
s1, s2, s3 = IHCC[1:3]

profile1 = matrix_profile(s1, window_length)
motifs1 = motifs(profile1, n_motifs; r=r, th=th)

profile2 = matrix_profile(s2, window_length)
motifs2 = motifs(profile2, n_motifs; r=r, th=th)

profile3 = matrix_profile(s3, window_length)
motifs3 = motifs(profile3, n_motifs; r=r, th=th)

p1 = plot(profile1, motifs1)
p2 = plot(profile2, motifs2)
p3 = plot(profile3, motifs3)
# plot(p1, p2, p3, layout=(1,3), size=(900,300))

# we focus on the first motif extracted from the first instance
# and compare them onto the other two
profile_m1s2 = matrix_profile(motifs1[1].seqs[1].seq, s2, window_length)
profile_m1s3 = matrix_profile(motifs1[1].seqs[1].seq, s3, window_length)
# plot(profile_m1s2)
# plot(profile_m1s3)


function encode_from_motifs(
    motifs::Vector{MatrixProfile.Motif}, 
    s::Vector{<:Float32}, 
    window_length::Integer;
    percentiles::Float32=0.1f0
)
    # ith motif to the locations where it is matched
    motif_locations = Dict()

    for (i, motif) in enumerate(motifs) 
        # compute matrix profile, using the motif as query on the series
        profile_ms = matrix_profile(motif.seqs[1].seq, s, window_length)
        profile = profile_ms.P

        # retrieve all the locations in which the query is also s' motif
        match_threshold = quantile(profile, percentiles) 
        locations = findall(d -> d < match_threshold, profile)

        motif_locations[i] = locations 
    end

    # extract all the segments in which a motif is matched
    segments = [
        (motif_idx, location_idx, s[location_idx:(location_idx+window_length)])
        for (motif_idx, locations) in motif_locations
        for location_idx in locations
    ]

    return segments
end


