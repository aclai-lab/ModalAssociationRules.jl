# we want to randomize a modal dataset (logiset) and measure the performances of MARM algorithms
# when varying the minimum threshold for local and global support.

using ModalAssociationRules
using SoleData
using SoleLogics

using BenchmarkTools
using Graphs
using Plots
using ProgressBars
using Random

TESTFOLDER = joinpath(@__DIR__, "test", "benchmark", "synthetic")

include((TESTFOLDER, "logiset.jl") |> joinpath)
include((TESTFOLDER, "generation.jl") |> joinpath)

rng = Xoshiro(7)

# this BenchmarkTools' parameterization ensures a fair benchmarking, with no memoization
# https://juliaci.github.io/BenchmarkTools.jl/dev/manual/#Miscellaneous-tips-and-info
# "f the function you study mutates its input, it is probably a good idea to set evals=1.
EVALS = 1
SAMPLES = 10
GCTRIAL = true

# structural variables, related to Kripke frames
# https://math.stackexchange.com/questions/1526372/what-is-the-definition-of-the-density-of-a-graph
graphdensity = 0.345
nworlds = 1
nedges = (graphdensity * nworlds * (nworlds-1) / 2) |> ceil |> Integer

# create a considerably big alphabet, with atoms wrapping "aa", "ab", "ac", ..., "zz"
alphrange = 97:1:(97+25)
alphabet = Iterators.product(alphrange, alphrange) |> collect |> vec .|>
    x -> x .|> Char |> join .|> Atom

## CASE 1 - Every instance only has 1 world (it is a propositional instance), and the
##  number of facts being true within each instance increase incrementally (of 1).

times = []
memory = []

# for each algorithm
for algorithm in [apriori, fpgrowth, eclat]

    _times = []
    _memory = []

    # measure time and memory across different instance and alphabet cardinalities
    for _ninstances in ProgressBar(10:1:10)
        items = Item.(alphabet[1:_ninstances])
        _itemmeasures = [(gsupport, 0.01, 0.9)]
        _rulemeasures = [(gconfidence, 0.8, 0.8)]

        modaldataset = Vector{KripkeStructure}([
            generate(
                randframe(rng, nworlds, nedges),
                alphabet[1:i],
                SoleLogics.inittruthvalues(BooleanAlgebra());
                fulltransfer=true,
            )
            for i in 1:_ninstances
        ]) |> Logiset;

        miner = Miner(modaldataset, algorithm, items, _itemmeasures, _rulemeasures;
            itemset_policies=Function[],
            arule_policies=Function[]
        );

        newtrial = @benchmark mine!($miner; forcemining=true, fpeonly=true) teardown = begin
            localmemo($miner) |> empty!
            globalmemo($miner) |> empty!
        end evals=EVALS samples=SAMPLES gctrial=GCTRIAL

        push!(_times, newtrial |> time)
        push!(_memory, newtrial.memory)
    end

    push!(times, _times)
    push!(memory, _memory)
end


### example of driver code, detached from the benchmarking loop
### _ninstances = 12
### _items = Item.(alphabet[1:_ninstances])
### _itemmeasures = [(gsupport, 0.01, 0.9)]
### _rulemeasures = [(gconfidence, 0.8, 0.8)]
###
### modaldataset = Vector{KripkeStructure}([
###     generate(
###         randframe(rng, _ninstances, 0),
###         alphabet[1:_ninstances],
###         SoleLogics.inittruthvalues(BooleanAlgebra());
###         fulltransfer=true
###     )
###     for i in 1:_ninstances
### ]) |> Logiset
###
### miner = Miner(modaldataset, eclat, _items, _itemmeasures, _rulemeasures;
###     itemset_policies=Function[],
###     arule_policies=Function[]
### );
###
### mine!(miner; fpeonly=true)
