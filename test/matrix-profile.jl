# This experiment suite is organized as follows:
# 1. each experiment is organized in a file, ranging from natops0.jl to natops6.jl
#   1.1 natops0.jl is just a little sketch with a few simple tests to ensure correctness
#   1.2 natops1.jl to natops6.jl contains one experiment for each NATOPS dataset class
# 2. for each experiment, a few variables are chosen
# 3. multiple motifs are extracted for each variable, using `motifsalphabet` and
#   checking the results manually
# 4. each motif is wrapped within a `VariableDistance` variable
#   4.1 each VariableDistance also wraps a distance function (dtw by default);
#       note that the distance's decision should be justified depending on your data domain
# 5. an alphabet of `Atom` is created by incorporating an operator and a threshold
#   together with each `VariableDistance`
#   5.1 the operator is always "<"
#   5.2 the threshold is computed by a rule of thumb... actually, this has to be more robust
# 6. the mining starts, keeping track of the time needed to generate freq. items and rules
#   6.1 each experiment has its policies to limit the number of results
#   6.2 this part is managed by the `experiment!` function
#   6.3 also, association rules are printed, sorted decreasingly by global confidence
#
# Note: you can use the following regex to look for rows in a report having both the
# variable numbers specified:
# ^(?=.*4)(?=.*5)(?=.*6).*

using Test

using DynamicAxisWarping
using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Random
using Statistics
using StatsBase
using SoleData

# euclidean distance between normalized(x) and normalized(y)
function zeuclidean(x::Vector{<:Real}, y::Vector{<:Real})
    if length(x) != length(y)
        # TODO - instead of returning a big number, throw an error and catch it while mining
        return maxintfloat()
    end

    # normalize x and y
    meanx = mean(x)
    meany = mean(y)

    # avoid division by zero
    eps = 1e-10

    x_z = (x .- mean(x)) ./ (std(x) + eps)
    y_z = (y .- mean(y)) ./ (std(y) + eps)

    # z-normalized euclidean distance formula
    return sqrt(sum((x_z .- y_z).^2))
end

function _dtw(x::Vector{<:Real}, y::Vector{<:Real})
    if length(x) != length(y)
        # TODO - instead of returning a big number, throw an error and catch it while mining
        return maxintfloat()
    end

    return dtw(x, y) |> first
end


# suggest a threshold to associate with a given motif, to create a literal;
# compute all the distances (for a given distance) and return the ith percentile
# (also, as 2nd value, return the distances itself).
function suggest_threshold(
    motif::Vector{<:Real},
    data;
    distance::Function=zeuclidean,
    _percentile::Integer=25
)
    distances = [
        distance(motif, data[instance][start:(start + length(motif) - 1)])
        for instance in 1:first(size(data))
        for start in 1:(length(data[instance]) - length(motif))
    ]

    return percentile(distances, _percentile), distances
end


# general experiment logic
function experiment!(miner::Miner, reportname::String)
    # check that miner provides both confidence and lift measures
    _allmeasures = first.(rulemeasures(miner))
    gconfidence in _allmeasures || throw(DomainError, "Miner does not provide gconfidence.")
    glift in _allmeasures || throw(DomainError, "Miner does not provide glift.")

    # mine
    println("Mining...")
    mining_start = time()
    mine!(miner)
    mining_end = time()
    println("Mining duration: $(round(mining_end - mining_start, digits=2))")

    # generate association rules
    println("Generating rules...")
    generating_start = time()
    generaterules!(miner) |> collect
    generating_end = time()
    println("Generation duration: $(round(generating_end - generating_start, digits=2))")

    # collect all the results
    rulecollection = [
        (
            rule,
            round(
                globalmemo(miner, (:gsupport, antecedent(rule))), digits=2
                ),
            round(
                globalmemo(miner, (:gsupport, Itemset(rule))), digits=2
            ),
            round(
                globalmemo(miner, (:gconfidence, rule)), digits=2
            ),
            round(
                globalmemo(miner, (:glift, rule)), digits=2
            )
        )
        for rule in arules(miner)
    ]

    # sort by lift (the 5th position in rulecollection)
    sort!(rulecollection, by=x->x[5], rev=true);

    reportname = joinpath(["test", "experiments", reportname])
    println("Writing to: $(reportname)")
    open(reportname, "w") do io
        println(io, "Columns are: rule, ant support, ant+cons support,  confidence, lift")

        padding = maximum(length.(miner |> freqitems))
        for (rule, antgsupp, consgsupp, conf, lift) in rulecollection
            println(io,
                rpad(rule, 30 * padding) * " " * rpad(string(antgsupp), 10) * " " *
                rpad(string(consgsupp), 10) * " " * rpad(string(conf), 10) * " " *
                string(lift)
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

# algorithm use for mining;
# currently, it is set to apriori instead of fpgrowth because of issue #97
miningalgo = apriori

# we isolated the only var_id 5 from the class "I have command",
# thus we now have only one column/var_id;
# for simplicity, let's consider also just one motif.

# we define a distance function between two time series
# you could choose between zeuclidean(x,y) or dtw(x,y) |> first
_mydistance = (x, y) -> dtw(x, y) |> first

############################################################################################
# Experiment #1: just a small example
############################################################################################
include("test/experiments/natops0.jl")

############################################################################################
# Experiment #1: describe the right hand in "I have command class"
############################################################################################
include("test/experiments/natops1.jl")

println("Running experiment #1:")
experiment!(miner, "v1_rhand_ihavecommand.txt")

############################################################################################
# Experiment #2: describe the right hand in "All clear class"
############################################################################################
include("test/experiments/natops2.jl")

println("Running experiment #2: ")
experiment!(miner, "v2_rhand_allclear.txt")

############################################################################################
# Experiment #3: describe the right hand in "Not clear"
############################################################################################
include("test/experiments/natops3.jl")

println("Running experiment #3: ")
experiment!(miner, "v3_rhand_notclear.txt")

############################################################################################
# Experiment #4: describe wrists and elbows in "Spread wings"
# TODO: add elbows
############################################################################################
include("test/experiments/natops4.jl")

println("Running experiment #4: ")
experiment!(miner, "v4_wristelbow_spreadwings.txt")

############################################################################################
# Experiment #5: describe wrists and elbows in "Fold wings"
# TODO: add elbows
############################################################################################
include("test/experiments/natops5.jl")

println("Running experiment #5: ")
experiment!(miner, "v5_wristelbow_foldwings.txt")

############################################################################################
# Experiment #6: describe wrists and elbows in "Lock wings"
############################################################################################
include("test/experiments/natops6.jl")

println("Running experiment #6: ")
experiment!(miner, "v6_elbowhand_lockwings.txt")


############################################################################################

# to help debugging
# plot([__motif__v5_l10_rhand_y_descending, IHCC[1,5][18:27] |> normalize  ])

# plot frequent items in descending order by dimensiona global support
# for frq in freqitems(miner)
#   println("$(frq) => gsupport $(miner.globalmemo[(:gsupport, frq)])")
# end
