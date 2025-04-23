#
# README
#
# Experiment suite general driver; include this file in any of your experiments.
#
#
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
# Note; you can use the following regex to look for rows in a results report having both the
# variable numbers specified:
# ^(?=.*4)(?=.*5)(?=.*6).*
# ^(?=.*V1)(?=.*V2).*

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

function _normalize(x::Vector{<:Real})
    eps = 1e-10
    return (x .- mean(x)) ./ (std(x) + eps)
end

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

    x_z = _normalize(x)
    y_z = _normalize(y)

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
    distance::Function=expdistance,
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
function experiment!(miner::Miner, foldername::String, reportname::String)
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
            ),
        )
        for rule in arules(miner)
    ]

    # sort by lift (the 5th position in rulecollection)
    sort!(rulecollection, by=x->x[5], rev=true);

    reportname = joinpath([
        @__DIR__, foldername, "results", reportname
    ])
    println("Writing to: $(reportname)")
    open(reportname, "w") do io
        println(io, "Columns are: rule, ant support, ant+cons support,  confidence, lift, dimlift")

        padding = maximum(length.(miner |> freqitems))
        for (rule, antgsupp, consgsupp, conf, lift, dimlift) in rulecollection
            println(io,
                rpad(rule, 30 * padding) * " " * rpad(string(antgsupp), 10) * " " *
                rpad(string(consgsupp), 10) * " " * rpad(string(conf), 10) * " " *
                rpad(string(lift), 10) * " " * string(dimlift)
            )
        end
    end
end

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
