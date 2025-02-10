using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures

X, _ = load_NATOPS();

# right hand y axis
variable = 5 

# right hand in "I have command class"
IHCC = X[1:30, variable] 

# parameters for matrix profile generation 
window_length = 10 
n_motifs = 5 
r = 2   # how similar two windows must be to belong to the same motif
th = 5  # how nearby in time two motifs are allowed to be

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
plot(p1, p2, p3, layout=(1,3), size=(900,300))

# we focus on the motifs extracted from the first instance
# and compare them onto the other two
profile_m1s2 = matrix_profile(m1.seqs[1].seq, s2, 5)
profile_m1s3 = matrix_profile(m1.seqs[1].seq, s3, 5)
# plot(profile_m1s2)
# plot(profile_m1s3)
