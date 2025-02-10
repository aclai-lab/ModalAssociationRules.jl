using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures

X, _ = load_NATOPS();

# right hand y axis
variable = 5 
# right hand in "I have command class"
IHCC = X[1:30, variable] 

# window length
window_length_multiplier = 0.1
window_length = window_length_multiplier * length(IHCC[1]) |> floor |> Integer

# compute the matrix profile 
profile = matrix_profile(IHCC[1], window_length)

# number of motifs to extract
n_motifs = 2
# retrieve the profile's motifs
# r controls how similar two windows must be to belong to the same motif
# th is a threshold of how nearby in time two motifs are allowed to be
_motifs = motifs(profile, n_motifs; r=2, th=5)

# plot the matrix profile, underlining its motifs
plot(profile, _motifs)

# concatenate all the instances together and summarize the new serie
# as a concatenation of small snippets
IHCC_allidx = reduce(vcat, IHCC)
snippets_allidx = snippets(IHCC_allidx, 3, 100)
plot(profile_allidx, _motifs_allidx)

profile_allidx = matrix_profile(IHCC_allidx, window_length)
_motifs_allidx = motifs(profile_allidx, n_motifs; r=2, th=50)
plot(profile_allidx, _motifs_allidx)
