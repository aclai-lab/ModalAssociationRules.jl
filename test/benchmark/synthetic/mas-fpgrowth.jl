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

NITEMS = configuration["n_items"]

MIN_LOCAL_SUPPORTS = configuration["min_local_supports"]
MIN_GLOBAL_SUPPORTS = configuration["min_global_supports"]

EVALS = configuration["num_evals"]
SAMPLES = configuration["num_runs"]
GCTRIAL = configuration["gctrial"]


##### modal dataset creation ###############################################################

# alphabet of both propositional and modal literals (considering diamond operator)
facts = [i |> Atom for i in 1:NITEMS]   # exploited during the creation of modal instances
items = Item.(vcat(facts, diamond().(facts)))    # "handles" for the facts above

# create the synthetic
modaldataset = Vector{KripkeStructure}([
    generate(
        randframe(SEED, NWORLDS, NEDGES),
        facts,
        inittruthvalues(BooleanAlgebra());
        random=true,
        rng=SEED
    )
    for i in 1:NINSTANCES
]) |> Logiset

# can be ignored, as they are just a default value to be placed within Miner's constructor
rulemeasures = [(gconfidence, 0.5, 0.5)]


##### Effective benchmarking ###############################################################

# mean time for each measurement set
meantimes = []

# also keep track of the individual measurements for each set;
# this is useful for plotting whisker plots
alltimes = []

# frequent itemsets for each minimum support set
nitemsets = []

# memory consumption estimated by BenchmarkTools
memories = []


for miningalgo in [apriori, fpgrowth, eclat]

    for mingsupport in ProgressBar(MIN_GLOBAL_SUPPORTS)

        for minlsupport in MIN_LOCAL_SUPPORTS
            # The following is an early pruning strategy suitable for the fully
            # propositional mining scenario.
            #
            # # some items are trivially globally unfrequent;
            # # since we do not want to mine an exponential number of itemsets on one world,
            # # just for immediately after discovering that they are not frequent, we remove
            # # them now.
            # _pruneditems = [
            #     item
            #     for item in items
            #     if (count(
            #            x -> x == formula(item), vcat(transactions...)
            #        ) / ntransactions) > minsupport)
            # ]

            miner = Miner(
                modaldataset,
                fpgrowth,
                items,
                [(gsupport, mingsupport, minlsupport)],
                rulemeasures;
                itemset_policies=Function[],
                arule_policies=Function[]
            );

            _current = @benchmark mine!($miner; forcemining=true, fpeonly=true) teardown = begin
                localmemo($miner) |> empty!
                globalmemo($miner) |> empty!
            end evals=EVALS samples=SAMPLES gctrial=GCTRIAL

            push!(alltimes, _current.times)
            push!(meantimes, mean(_current.times))
            push!(nitemsets, length(freqitems(miner)))
            push!(memories, memory(_current))
        end

    end

    results = configuration

    # aggregate the results and write them
    results["meantimes"] = meantimes,
    results["alltimes"] = alltimes,
    results["frequent_itemsets"] = nitemsets,
    results["memories"] = memories

    open(joinpath(BENCHMARK_REPOSITORY, "results", "mas-$(miningalgo).json"), "w") do io
        JSON.print(io, results)
    end

    # reset and restart
    meantimes = []
    alltimes = []
    nitemsets = []
    memories = []
end
