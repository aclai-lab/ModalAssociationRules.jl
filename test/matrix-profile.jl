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
windowlength = 20 
nmotifs = 10 
r = 5   # how similar two windows must be to belong to the same motif
th = 0  # how nearby in time two motifs are allowed to be

# consider all the samples in IHCC:
# concatenate them and compute the matrix profile;
# then, extract the top k motifs.
T = reduce(vcat, IHCC[1:5])

Tmprofile = matrix_profile(T, windowlength)
Tmotifs = motifs(Tmprofile, nmotifs; r=r, th=th)

# filter the identified motifs which are single
Tmotifs = filter(motif -> length(motif.seqs) >= 2, Tmotifs)
plot(Tmotifs)
