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
# ^(?=.*⟨B⟩)(?=.*⟨A⟩).*

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
function experiment!(miner::Miner, reportname::String)
    # check that miner provides both confidence and lift measures
    _allmeasures = first.(rulemeasures(miner))
    gconfidence in _allmeasures || throw(DomainError, "Miner does not provide gconfidence.")
    glift in _allmeasures || throw(DomainError, "Miner does not provide glift.")

    if !info(miner, :istrained)
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
        println(
            "Generation duration: $(round(generating_end - generating_start, digits=2))")
    end

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

    reportname = joinpath([@__DIR__, "results", reportname])
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

function initialize_experiment(
    ids,
    motifs,
    featurenames,
    data;
    _distance=expdistance,
    _alpha_percentile=10,
    _worldfilter::Union{Nothing,WorldFilter}=nothing,
    _itemsetmeasures = [(gsupport, 0.1, 0.1)],
    _rulemeasures = [
        (gconfidence, 0.1, 0.1),
        (glift, 0.0, 0.0), # we want to compute lift, regardless of a threshold
    ]
)
    variables = [
        VariableDistance(id, m, distance=_distance, featurename=name)
        for (id, m, name) in zip(ids, motifs, featurenames)
    ]

    propositionalatoms = [
        Atom(ScalarCondition(
            v, <=, __suggest_threshold(v, data; _percentile=_alpha_percentile)
        ))
        for v in variables
    ]

    atoms = reduce(vcat, [
        propositionalatoms,
        diamond(IA_A).(propositionalatoms),
        diamond(IA_B).(propositionalatoms),
        diamond(IA_E).(propositionalatoms),
        diamond(IA_D).(propositionalatoms),
        # diamond(IA_O).(propositionalatoms),
    ])

    _items = Vector{Item}(atoms)

    _logiset = scalarlogiset(data, variables)

    return _logiset, Miner(
        _logiset, miningalgo, _items, _itemsetmeasures, _rulemeasures;
        worldfilter=_worldfilter,
        itemset_mining_policies=Function[
            isanchored_itemset(ignoreuntillength=2),
            isdimensionally_coherent_itemset()
        ],
        arule_mining_policies=Function[
            islimited_length_arule(consequent_maxlength=3),
            isanchored_arule()
        ]
    )
end

# extract a snippet's inner Vector from the definition in MatrixProfiles.jl
_snippet(_snippets, i) = _snippets.snippets[i].seq

# fallback to _suggest_threshold for VariableDistances
function __suggest_threshold(var::VariableDistance, data; kwargs...)
    _refs = references(var)
    _i_variable = i_variable(var)

    _ans = first.(map(
        _ref -> suggest_threshold(_ref, data[:,_i_variable]; kwargs...) , _refs;)) |> minimum
    return round(_ans; digits=2)
end

# helper to label motifs and serialize the result
function label_motifs(
    data,
    varids::Vector{Int64},
    variablenames::Vector{String},
    save_filepath::String,
    save_filename_prefix::String;
    # length and numerosity of each snippet to extract (first set)
    m1::Integer=10,
    n1::Integer=4,
    # length and numerosity of each snippet to extract (first set)
    m2::Integer=20,
    n2::Integer=3,
)
    ids = []
    motifs = []
    featurenames = []

    # we only want to consider right hand and right elbow variables
    for varid in varids
        _data = reduce(vcat, data[:,varid])
        S1 = snippets(_data, n1, m1; m=m1)
        S2 = snippets(_data, n2, m2; m=m2)

        _motifs = [
            [[_snippet(S1,i)] for i in 1:n1]...,
            [[_snippet(S2,i)] for i in 1:n2]...
        ]

        for (i, _motif) in enumerate(_motifs)
            println("Plotting $(i)-th motif of class $(variablenames[varid])")
            _plot = plot()
            plot!(_motif)
            display(_plot)

            _featurename = readline()

            push!(ids, varid)
            push!(motifs, _motif)
            push!(featurenames, _featurename)
        end

    end

    serialize(joinpath(save_filepath, "$(save_filename_prefix)-ids"), ids)
    serialize(joinpath(save_filepath, "$(save_filename_prefix)-motifs"), motifs)
    serialize(joinpath(save_filepath, "$(save_filename_prefix)-featurenames"), featurenames)

    return ids, motifs, featurenames
end

function load_motifs(filepath, save_filename_prefix)
    ids = [id for id in deserialize(
        joinpath(filepath, "$(save_filename_prefix)-ids"))];
    motifs = [m for m in deserialize(
        joinpath(filepath, "$(save_filename_prefix)-motifs"))];
    featurenames = [f for f in deserialize(
        joinpath(filepath, "$(save_filename_prefix)-featurenames"))];

    return ids, motifs, featurenames
end

# algorithm use for mining;
# currently, it is set to apriori instead of fpgrowth because of issue #97
miningalgo = apriori

# we define a distance function between two time series
# you could choose between zeuclidean(x,y) or dtw(x,y) |> first
expdistance = (x, y) -> zeuclidean(x, y) |> first


# TODO - these parameters are deprecated and should be ignored

# default parameters for matrix profile generation
windowlength = 20
nmotifs = 3
_seed = 3498
r = 5    # how similar two windows must be to belong to the same motif
th = 10  # how nearby in time two motifs are allowed to be
