using BenchmarkTools
using Graphs
using JSON
using ProgressBars

using ModalAssociationRules

using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame
using SoleLogics: TOP

##### configuration loading ################################################################

BENCHMARK_REPOSITORY = joinpath(@__DIR__, "test", "benchmark", "pythonic")
CONFIG_FILENAME = "config.json"
configuration = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, CONFIG_FILENAME))


DATAPATH = joinpath(@__DIR__, "test", "benchmark", "pythonic", configuration["data_file"])

EVALS = configuration["num_evals"]
SAMPLES = configuration["num_runs"]
GCTRIAL = configuration["gctrial"]

##### modal dataset creation ###############################################################

transactions = []

# every entry in transactions is a list of unique (propositional) facts
open(DATAPATH, "r") do file
    for line in eachline(file)
        atoms = split(line) .|> string .|> Atom
        push!(transactions, atoms)
    end
end

ntransactions = length(transactions)
min_supports = configuration["min_supports"]

# create a degenerate Kripke frame, containing only one world (i.e., a propositional model)
world = World.(1:1)

graph = Graphs.SimpleDiGraph(1, 0)
fr = SoleLogics.ExplicitCrispUniModalFrame(world, graph)

modaldataset = Vector{KripkeStructure}([
    KripkeStructure(
        fr,
        Dict([
            w => TruthDict([fact => TOP for fact in transaction])
            for w in fr.worlds
        ])
    )

    for transaction in transactions
]) |> Logiset

items = [t for transaction in transactions for t in transaction] |> unique .|> Item
itemmeasures = [(gsupport, 1.0, 0.5)] # local support will be changed while measuring time
rulemeasures = [(gconfidence, 0.8, 0.8)]

##### Effective benchmarking ###############################################################

# copypaste from mlxtend-fpgrowth

# mean time for each measurement set
mean_times = []

# also keep track of the individual measurements for each set;
# this is useful for plotting a whiskers plot
all_runtimes = []

# frequent itemsets for each minimum support set
freq_itemsets_found = []

# memory consumption estimated by BenchmarkTools
mean_memories = []


for miningalgo in [apriori, fpgrowth, eclat]

    for min_support in ProgressBar(min_supports)
        # some items are trivially globally unfrequent;
        # since we do not want to mine an exponential number of itemsets on one world,
        # just for immediately after discovering that they are not frequent, we remove them now.
        _pruneditems = [
            item
            for item in items
            if (count(x -> x == formula(item), vcat(transactions...)) / ntransactions) > min_support
        ]

        miner = Miner(
            modaldataset,
            fpgrowth,
            _pruneditems,
            [(gsupport, 1.0, min_support)],
            rulemeasures;
            itemset_policies=Function[],
            arule_policies=Function[]
        );

        _current = @benchmark mine!($miner; forcemining=true, fpeonly=true) teardown = begin
            localmemo($miner) |> empty!
            globalmemo($miner) |> empty!
        end evals=EVALS samples=SAMPLES gctrial=GCTRIAL

        push!(all_runtimes, _current.times)
        push!(mean_times, mean(_current.times))
        push!(freq_itemsets_found, length(freqitems(miner)))
        push!(mean_memories, memory(_current))
    end

    # aggregate the results and write them
    results = Dict(
        "mean_times" => mean_times,
        "all_runtimes" => all_runtimes,
        "frequent_itemsets" => freq_itemsets_found,
        "mean_memories" => mean_memories
    )

    open(joinpath(BENCHMARK_REPOSITORY, "results", "mas-$(miningalgo).json"), "w") do io
        JSON.print(io, results)
    end

    # reset and restart
    mean_times = []
    all_runtimes = []
    freq_itemsets_found = []
    mean_memories = []
end
