# Usage examples
#
# Apriori (1 thread):
# julia +1.11 -t1 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_1 --algorithm apriori --rng 9989 --nruns 10
# Apriori (2 threads):
# julia +1.11 -t2 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_2 --algorithm apriori --rng 9989 --nruns 10
# Apriori (4 threads):
# julia +1.11 -t4 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_4 --algorithm apriori --rng 9989 --nruns 10
# Apriori (8 threads):
# julia +1.11 -t8 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_8 --algorithm apriori --rng 9989 --nruns 10
# Apriori (16 threads):
# julia +1.11 -t16 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_16 --algorithm apriori --rng 9989 --nruns 10
#
#
# FPGrowth (1 thread):
# julia +1.11 -t1 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_1 --algorithm fpgrowth --rng 9989 --nruns 1
# FPGrowth (2 threads):
# julia +1.11 -t2 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_2 --algorithm fpgrowth --rng 9989 --nruns 1
# FPGrowth (4 threads):
# julia +1.11 -t4 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_4 --algorithm fpgrowth --rng 9989 --nruns 1
# FPGrowth (8 threads):
# julia +1.11 -t8 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_8 --algorithm fpgrowth --rng 9989 --nruns 1
# FPGrowth (16 threads):
# julia +1.11 -t16 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_16 --algorithm fpgrowth --rng 9989 --nruns 1
#
#
# Eclat (1 thread):
# julia +1.11 -t1 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_1 --algorithm eclat --rng 9989 --nruns 1
# Eclat (2 threads):
# julia +1.11 -t2 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_2 --algorithm eclat --rng 9989 --nruns 1
# Eclat (4 threads):
# julia +1.11 -t4 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_4 --algorithm eclat --rng 9989 --nruns 1
# Eclat (8 threads):
# julia +1.11 -t8 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_8 --algorithm eclat --rng 9989 --nruns 1
# Eclat (16 threads):
# julia +1.11 -t16 --project=. benchmark/benchmarking.jl --ninstances 100 --nworlds 50 --nedges 100 --npropositions 10 --lsupports 0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0 --mingsupports 0.1 --gctrial true --savename threads_16 --algorithm eclat --rng 9989 --nruns 1
#

using ArgParse
using ProgressBars

using BenchmarkTools
using Graphs
using JSON
using Random

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

        "--savename"
        help = "Filename of the final report"
        arg_type = String
        default = "results.json"

        "--algorithm"
        help = "Algorithm to test (apriori, fpgrowth, eclat)"
        arg_type = String
        default = "apriori"

        "--rng"
        help = "RNG Seed."
        arg_type = Int
        default = 98999
    end

    return parse_args(settings)
end

##### configuration loading ################################################################

BENCHMARK_REPOSITORY = joinpath(@__DIR__)

configuration = parse_commandline()

# CONFIG_FILENAME = "config.json"
# configuration = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, CONFIG_FILENAME))


SEED = Xoshiro(configuration["rng"])
Random.seed!(SEED)

NINSTANCES = configuration["ninstances"]
NWORLDS = configuration["nworlds"]
NEDGES = configuration["nedges"]

NITEMS = configuration["npropositions"]

MIN_LOCAL_SUPPORTS = configuration["lsupports"]
MIN_GLOBAL_SUPPORTS = configuration["mingsupports"]

EVALS = configuration["nevals"]
SAMPLES = configuration["nruns"]
GCTRIAL = configuration["gctrial"]

savename = configuration["savename"]

algorithm = configuration["algorithm"]

miningalgo = nothing
if algorithm == "apriori"
    miningalgo = apriori
elseif algorithm == "fpgrowth"
    miningalgo = fpgrowth
elseif algorithm == "eclat"
    miningalgo = eclat
else
    @error "The provided algorithm $(algorithm) is not implemented"
end

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
        # incremental=true,
        random=true,
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
# _last_iteration_dump = nothing

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
    println("Current global support: $mingsupport")

    for minlsupport in ProgressBar(MIN_LOCAL_SUPPORTS)
        miner = Miner(
            Logiset(modaldataset),
            miningalgo,
            _items,
            [(gsupport, minlsupport, mingsupport)],
            rulemeasures;
            itemset_policies=Function[],
            arule_policies=Function[],
        )

        # we only measure the frequent pattern mining time
        _current = @benchmark mine!($miner; forcemining=true, fpeonly=true) teardown =
            begin
                empty!(localmemo($miner))
                empty!(globalmemo($miner))
                
                # if you uncomment this, the printed number of frequent itemsets
                # will be zero; instead, if you keep this uncommented, 
                # the correct value will be saved multiplied by the runs number
                # empty!(freqitems($miner))
            end evals = EVALS samples = SAMPLES gctrial = GCTRIAL

        # _last_iteration_dump = _current

        push!(alltimes, _current.times)
        push!(meantimes, mean(_current.times))
        push!(nitemsets, length(freqitems(miner)))

        push!(memories, memory(_current))

        println("Current minimum: $(minlsupport)")
    end # end of local support loop
end # end of global support loop

# aggregate the results and write them
results["meantimes"] = meantimes
results["alltimes"] = alltimes
results["frequent_itemsets"] = nitemsets 

results["memories"] = memories

SAVEPATH = joinpath(BENCHMARK_REPOSITORY, "results", "$(miningalgo)_$(savename).json")

open(SAVEPATH, "w") do io
    return JSON.print(io, results)
end
