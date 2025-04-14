include("experiments-driver.jl")


X, y = load_NATOPS();
insertcols!(X, 25, "ΔY[Thumb r and Hand tip r]" => X[:,5]-X[:,23])

# right hand y axis
var_id = 5

# right hand in "I have command class"
IHCC_rhand_y_only = Vector{Float64}.(X[1:30, var_id])

# parameters for matrix profile generation
windowlength = 20
nmotifs = 3
_seed = 3498
r = 5    # how similar two windows must be to belong to the same motif
th = 10  # how nearby in time two motifs are allowed to be

# algorithm use for mining;
# currently, it is set to apriori instead of fpgrowth because of issue #97
miningalgo = apriori

# we isolated the only var_id 5 from the class "I have command",
# thus we now have only one column/var_id;
# for simplicity, let's consider also just one motif.

# we define a distance function between two time series
# you could choose between zeuclidean(x,y) or dtw(x,y) |> first
_mydistance = (x, y) -> zeuclidean(x, y) |> first

############################################################################################
# Experiment #1: just a small example
############################################################################################
include("test/results/NATOPS/natops0.jl")

############################################################################################
# Experiment #1: describe the right hand in "I have command class"
############################################################################################
include("test/results/NATOPS/natops1.jl")

println("Running experiment #1:")
experiment!(miner, "v1_rhand_ihavecommand.txt")

############################################################################################
# Experiment #2: describe the right hand in "All clear class"
############################################################################################
include("test/results/NATOPS/natops2.jl")

println("Running experiment #2: ")
experiment!(miner, "v2_rhand_allclear.txt")

############################################################################################
# Experiment #3: describe the right hand in "Not clear"
############################################################################################
include("test/results/NATOPS/natops3.jl")

println("Running experiment #3: ")
experiment!(miner, "v3_rhand_notclear.txt")

############################################################################################
# Experiment #4: describe wrists and elbows in "Spread wings"
############################################################################################
include("test/results/NATOPS/natops4.jl")

println("Running experiment #4: ")
experiment!(miner, "v4_wristelbow_spreadwings.txt")

############################################################################################
# Experiment #5: describe wrists and elbows in "Fold wings"
############################################################################################
include("test/results/NATOPS/natops5.jl")

println("Running experiment #5: ")
experiment!(miner, "v5_wristelbow_foldwings.txt")

############################################################################################
# Experiment #6: describe wrists and elbows in "Lock wings"
############################################################################################
include("test/results/NATOPS/natops6.jl")

println("Running experiment #6: ")
experiment!(miner, "v6_elbowhand_lockwings.txt")
