using BenchmarkTools
using Graphs
using JSON
using Random
using ProgressBars

using ModalAssociationRules

using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame
using SoleLogics: inittruthvalues, BooleanAlgebra, TOP


##### configuration loading ################################################################

BENCHMARK_REPOSITORY = joinpath(@__DIR__, "test", "benchmark", "synthetic")
CONFIG_FILENAME = "config.json"
configuration = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, CONFIG_FILENAME))

SEED = configuration["frame_seed"] |> Xoshiro

NINSTANCES = configuration["n_instances"]
NWORLDS = configuration["n_worlds_per_frame"]
NEDGES = configuration["n_edges_per_frame"]

NITEMS = configuration["n_propositional_items"]

MIN_LOCAL_SUPPORTS = configuration["min_local_supports"]
MIN_GLOBAL_SUPPORTS = configuration["min_global_supports"]

EVALS = configuration["num_evals"]
SAMPLES = configuration["num_runs"]
GCTRIAL = configuration["gctrial"]

ModalAssociationRules.LOCAL_MEMOIZATION_POWER = (1<<63)-1
ModalAssociationRules.GLOBAL_MEMOIZATION_POWER = (1<<63)-1


##### modal dataset creation ###############################################################

# alphabet of both propositional and modal literals (considering diamond operator)
propfacts = [i |> Atom for i in 1:NITEMS] # exploited during the creation of modal instances

facts = vcat(propfacts, diamond().(propfacts))
_items = Item.(facts)    # "handles" for the facts above

# create the synthetic modal dataset (by seed)
modaldataset = Vector{KripkeStructure}([
    generate(
        randframe(SEED, NWORLDS, NEDGES),
        propfacts,
        vcat([SoleLogics.TOP for _ in 1:i], [SoleLogics.BOT for _ in i:NINSTANCES]),
        incremental=true;
        # random=true,
        # rng=SEED
    )
    for i in 1:NINSTANCES
])

# can be ignored, as they are just a default value to be placed within Miner's constructor
rulemeasures = [(gconfidence, 0.5, 0.5)]


##### Effective benchmarking ###############################################################

# copy the configuration in the final report
results = configuration

for miningalgo in [fpgrowth, eclat, apriori]

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
                modaldataset |> Logiset,
                miningalgo,
                _items,
                [(gsupport, minlsupport, mingsupport)],
                rulemeasures;
                itemset_policies=Function[],
                arule_policies=Function[]
            );

            _current = @benchmark mine!(
                $miner;
                forcemining=true,
                fpeonly=true
            ) teardown = begin
                localmemo($miner) |> empty!
                globalmemo($miner) |> empty!
            end evals=EVALS samples=SAMPLES gctrial=GCTRIAL

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

    open(joinpath(BENCHMARK_REPOSITORY, "results", "v2-$(miningalgo).json"), "w") do io
        JSON.print(io, results)
    end
end


##### plotting #############################################################################

# results = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, "results", "v2-fpgrowth.json"))
#
# X = Float64.(results["min_global_supports"])
# Y = Float64.(results["min_local_supports"])
#
# XGRID = repeat(X', length(Y))
# YGRID = repeat(Y', length(X))
#
# Z = Float64.(reshape(results["meantimes"], 20, 20))

# surface(
#     XGRID, YGRID, Z,
#     xlabel = "Min gsupp",
#     ylabel = "Min lsupp",
#     zlabel = "Time",
#     zlims = (0, 1e7),
#     contour = :projection
# )
