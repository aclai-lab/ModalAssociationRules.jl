include("test/experiments/experiments-driver.jl")


X, y = load_libras();
insertcols!(X, 25, "ΔY[Thumb r and Hand tip r]" => X[:,5]-X[:,23])

# default parameters for matrix profile generation
windowlength = 20
nmotifs = 3
_seed = 3498
r = 5    # how similar two windows must be to belong to the same motif
th = 10  # how nearby in time two motifs are allowed to be

# algorithm use for mining;
# currently, it is set to apriori instead of fpgrowth because of issue #97
miningalgo = apriori

# we define a distance function between two time series
# you could choose between zeuclidean(x,y) or dtw(x,y) |> first
expdistance = (x, y) -> zeuclidean(x, y) |> first

############################################################################################
# Experiment #1:
############################################################################################
include("test/experiments/Libras/libras0.jl")
