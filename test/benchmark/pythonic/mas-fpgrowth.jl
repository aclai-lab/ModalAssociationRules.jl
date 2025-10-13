using BenchmarkTools
using Graphs
using JSON

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

for min_support in configuration["min_supports"]

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
        items,
        [(gsupport, 1.0, min_support)],
        rulemeasures;
        itemset_policies=Function[],
        arule_policies=Function[]
    );

    println("Measuring min_support=$min_support")

    _current = @benchmark mine!($miner; forcemining=true, fpeonly=true) teardown = begin
        localmemo($miner) |> empty!
        globalmemo($miner) |> empty!
    end evals=EVALS samples=SAMPLES gctrial=GCTRIAL

    push!(all_runtimes, _current.times)
    push!(mean_times, mean(_current.times))
    push!(freq_itemsets_found, length(freqitems(miner)))

    println("Time for $min_support is: $(mean(_current.times))")
end

#### julia> localmemo(miner)
#### Dict{Tuple{Symbol, ARMSubject, Integer}, Float64} with 2097320 entries:
####   (:lsupport, [n, b, c, e, d, a, l, r, q], 3)       => 1.0
####   (:lsupport, [c, o, k, d, a, l, h, r, q, m], 1)    => 1.0
####   (:lsupport, [g, j, o, k, d, a, l, h, p, m], 4)    => 1.0
####   (:lsupport, [g, b, t, i, d, l, h, p, q], 1)       => 1.0
####   (:lsupport, [n, g, b, e, a, l, r, s, m], 1)       => 1.0
####   (:lsupport, [n, j, t, c, k, d, l, h, f, m], 1)    => 1.0
####   (:lsupport, [g, b, j, t, o, k, e, d, l, r, s], 1) => 1.0
####   (:lsupport, [g, b, j, t, c, i, o, k, r, q, f], 1) => 1.0
####   (:lsupport, [b, t, i, o, d, a, h, r, q, s, f], 1) => 1.0
####   (:lsupport, [c, i, e, l, r, p, m], 3)             => 1.0
####   (:lsupport, [j, c, k, e, d, a, r, q, s, f], 2)    => 1.0
####   ⋮                                                 => ⋮
