using Test

using DynamicAxisWarping
using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Random
using Statistics

using SoleData

# little utility to avoid writing an experiment
function experiment!(miner::Miner, reportname::String)
    println("Mining...")
    mining_start = time()
    mine!(miner)
    mining_end = time()
    println("Mining duration: $(round(mining_end - mining_start, digits=2))")

    println("Generating rules...")
    generating_start = time()
    generaterules!(miner) |> collect
    generating_end = time()
    println("Generation duration: $(round(generating_end - generating_start, digits=2))")


    rulecollection = [
        (
            rule,
            round(
                globalmemo(miner, (:dimensional_gconfidence, rule)), digits=2
            ),
            round(
                globalmemo(miner, (:dimensional_gsupport, antecedent(rule))), digits=2
            ),
            round(
                globalmemo(miner, (:dimensional_gsupport, Itemset(rule))), digits=2
            )
        )
        for rule in arules(miner)
    ]
    sort!(rulecollection, by=x->x[2], rev=true);

    reportname = joinpath(["test", "experiments", reportname])
    println("Writing to: $(reportname)")
    open(reportname, "w") do io
        println(io, "Columns are: rule, confidence, ant support, ant+cons support")

        padding = maximum(length.(miner |> freqitems))
        for (rule,conf,antgsupp,consgsupp) in rulecollection
            println(io,
                rpad(rule, 50 * padding) * " " * rpad(string(conf), 10) * " " *
                rpad(string(antgsupp), 10) * " " * string(consgsupp)
            )
        end
    end
end

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

# we isolated the only var_id 5 from the class "I have command",
# thus we now have only one column/var_id;
# for simplicity, let's consider also just one motif.

# we define a distance function between two time series x, y, where |x| = |y|
_mydistance = (x, y) -> size(x) == size(y) ?
    # Euclidean with normalization
    # sqrt(sum([(x - y)^2 for (x, y) in zip(x |> normalize, y)])) :

    # Euclidean without normalization
    # sqrt(sum([(x - y)^2 for (x, y) in zip(x, y)])) :

    # Dynamic Time Warping
    dtw(x,y) |> first :

    # distance function isz not well-defined
    maxintfloat()

############################################################################################
# Experiment #1: just a small example
############################################################################################
include("test/experiments/natops0.jl")
@test_nowarn mine!(apriori_miner)
@test freqitems(apriori_miner) |> length == 5

############################################################################################
# Experiment #1: describe the right hand in "I have command class"
############################################################################################
include("test/experiments/natops1.jl")

println("Running experiment #1:")
experiment!(apriori_miner, "v1_rhand_ihavecommand.txt")

############################################################################################
# Experiment #2: describe the right hand in "All clear class"
############################################################################################
include("test/experiments/natops2.jl")

println("Running experiment #2: ")
experiment!(apriori_miner, "v2_rhand_allclear.txt")

############################################################################################
# Experiment #3: describe the right hand in "Not clear"
############################################################################################
include("test/experiments/natops3.jl")

println("Running experiment #3: ")
experiment!(apriori_miner, "v3_rhand_notclear.txt")

############################################################################################
# Experiment #4: describe wrists and elbows in "Spread wings"
# TODO: add elbows
############################################################################################
include("test/experiments/natops4.jl")

println("Running experiment #4: ")
experiment!(apriori_miner, "v4_wristelbow_spreadwings.txt")

############################################################################################
# Experiment #5: describe wrists and elbows in "Fold wings"
# TODO: add elbows
############################################################################################
include("test/experiments/natops5.jl")

println("Running experiment #5: ")
experiment!(apriori_miner, "v5_wristelbow_foldwings.txt")

############################################################################################
# Experiment #6: describe wrists and elbows in "Lock wings"
############################################################################################
include("test/experiments/natops6.jl")

println("Running experiment #6: ")
experiment!(apriori_miner, "v6_elbowhand_lockwings.txt")


############################################################################################

# to help debugging
# plot([__motif__v5_l10_rhand_y_descending, IHCC[1,5][18:27] |> normalize  ])

# plot frequent items in descending order by dimensiona global support
# for frq in freqitems(miner)
#   println("$(frq) => gsupport $(apriori_miner.globalmemo[(:dimensional_gsupport, frq)])")
# end
