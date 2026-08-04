using ArgParse

using BenchmarkTools
using Graphs
using JSON
using Random
using ProgressBars

using ModalAssociationRules

using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame
using SoleLogics: inittruthvalues, BooleanAlgebra, TOP

function parse_commandline()
    settings = ArgParseSettings(; description="Generate a transformation base")

    ArgParse.@add_arg_table settings begin
        "--ninstances", "-N"
        help = "Number of instances"
        arg_type = Int
        default = 1

        "--nworlds", "-W"
        help = "Number of worlds in each frame"
        arg_type = Int
        default = 1

        "--nedges", "-E"
        help = "Number of edges in each frame"
        arg_type = Int
        default = 0

        "--npropositions", "-P"
        help = "Cardinality of the alphabet (total number of items)"
        arg_type = Int
        default = 0

        "--lsupports", "-s"
        help = "Cardinality of the alphabet (total number of items)"
        arg_type = Float64
        nargs = '+'
        default = [0.0, 0.0]

        "--simthresholds", "-t"
        help = "Similarity thresholds"
        arg_type = Float64
        nargs = '+'
        default = [
            0.0,
            0.05,
            0.1,
            0.15,
            0.2,
            0.25,
            0.3,
            0.35,
            0.4,
            0.45,
            0.5,
            0.55,
            0.6,
            0.65,
            0.7,
            0.75,
            0.8,
            0.85,
            0.9,
            0.95,
            1.0,
        ]

        "--mingsupports", "-m"
        help = "Minimum global supports"
        arg_type = Float64
        nargs = '+'
        default = [0.1]

        "--nruns", "-r"
        help = "Total number of runs (in Julia's @benchmark)"
        arg_type = Int 
        default = 1

        "--nevals", "-e"
        help = "Total number of evaluations (in Julia's @benchmark)"
        arg_type = Int
        default = 1

        "--gctrial", "-g"
        help = "Run gc() before running the benchmark"
        arg_type = Bool
        default = true

        "--rng", "-r"
        help = "RNG Seed."
        arg_type = Int
        default = 98999
    end

    return parse_args(settings)
end

##### configuration loading ################################################################

BENCHMARK_REPOSITORY = joinpath(@__DIR__, "benchmark")
CONFIG_FILENAME = "config.json"
configuration = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, CONFIG_FILENAME))

SEED = Xoshiro(configuration["frame_seed"])
Random.seed!(SEED)

NINSTANCES = configuration["n_instances"]
NWORLDS = configuration["n_worlds_per_frame"]
NEDGES = configuration["n_edges_per_frame"]

NITEMS = configuration["n_propositional_items"]

MIN_LOCAL_SUPPORTS = configuration["min_local_supports"]
MIN_GLOBAL_SUPPORTS = configuration["min_global_supports"]

EVALS = configuration["num_evals"]
SAMPLES = configuration["num_runs"]
GCTRIAL = configuration["gctrial"]

# these should be set higher than 0 to support eclat's execution
ModalAssociationRules.LOCAL_MEMOIZATION_POWER = 3 # (1 << 63) - 1
ModalAssociationRules.GLOBAL_MEMOIZATION_POWER = 3 # (1 << 63) - 1

##### modal dataset creation ###############################################################

# alphabet of both propositional and modal literals (considering diamond operator)
propfacts = [Atom(i) for i in 1:NITEMS] # exploited during the creation of modal instances

facts = vcat(propfacts, diamond().(propfacts))
_items = Item.(facts)    # "handles" for the facts above

# create the synthetic modal dataset (by seed)
modaldataset = Vector{KripkeStructure}([
    generate(
        randframe(SEED, NWORLDS, NEDGES),
        propfacts,
        vcat([SoleLogics.TOP for _ in 1:i], [SoleLogics.BOT for _ in i:NINSTANCES]);
        incremental=true,
        # random=true,
        # rng=SEED
    ) for i in 1:NINSTANCES
])

# can be ignored, as they are just a default value to be placed within Miner's constructor
rulemeasures = [(gconfidence, 0.5, 0.5)]

##### Effective benchmarking ###############################################################

# copy the configuration in the final report
results = configuration

# for debugging purposes
_last_iteration_dump = nothing

for miningalgo in [eclat]

    # mean time for each measurement set
    meantimes = []

    # also keep track of the individual measurements for each set;
    # this is useful for plotting whisker plots
    alltimes = []

    # frequent itemsets for each minimum support set
    nitemsets = []

    # memory consumption estimated by BenchmarkTools
    memories = []

    for mingsupport in MIN_GLOBAL_SUPPORTS
        for minlsupport in MIN_LOCAL_SUPPORTS
            miner = Miner(
                Logiset(modaldataset),
                miningalgo,
                _items,
                [(gsupport, minlsupport, mingsupport)],
                rulemeasures;
                itemset_policies=Function[],
                arule_policies=Function[],
            )

            _current = @benchmark mine!($miner; forcemining=true, fpeonly=true) teardown =
                begin
                    localmemo($miner) |> empty!
                    globalmemo($miner) |> empty!
                end evals = EVALS samples = SAMPLES gctrial = GCTRIAL

            _last_iteration_dump = _current

            push!(alltimes, _current.times)
            push!(meantimes, mean(_current.times))
            push!(nitemsets, length(freqitems(miner)))

            push!(memories, memory(_current))

            println("Current minimum $(minlsupport)")
        end # end of local support loop
    end # end of global support loop

    # aggregate the results and write them
    results["meantimes"] = meantimes
    results["alltimes"] = alltimes
    results["frequent_itemsets"] = nitemsets

    results["memories"] = memories

    open(joinpath(BENCHMARK_REPOSITORY, "results", "$(miningalgo).json"), "w") do io
        return JSON.print(io, results)
    end
end
