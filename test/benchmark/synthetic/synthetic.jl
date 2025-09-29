# we want to randomize a modal dataset (logiset) and measure the performances of MARM algorithms
# when varying the minimum threshold for local and global support.

using ModalAssociationRules
using SoleData
using SoleLogics

using BenchmarkTools
using Graphs
using Random

TESTFOLDER = joinpath(@__DIR__, "test", "benchmark", "synthetic")

include((TESTFOLDER, "logiset.jl") |> joinpath)
include((TESTFOLDER, "generation.jl") |> joinpath)

## Preamble

rng = Xoshiro(7)

_ninstances = 40

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

# this ensures a fair benchmarking, without considering memoization
# https://juliaci.github.io/BenchmarkTools.jl/dev/manual/#Miscellaneous-tips-and-info
# "f the function you study mutates its input, it is probably a good idea to set evals=1.
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
BenchmarkTools.gctrial = true

modaldataset = Vector{KripkeStructure}([
    generate(
        randframe(rng, nworlds, nedges),
        alphabet[1:i],
        SoleLogics.inittruthvalues(BooleanAlgebra());
        fulltransfer=true,
    )
    for i in 1:_ninstances
]) |> Logiset;

items = Item.(alphabet[1:_ninstances])
_itemmeasures = [(gsupport, 0.01, 0.8)]
_rulemeasures = [(gconfidence, 0.8, 0.8)]

aprioriminer = Miner(modaldataset, apriori, items, _itemmeasures, _rulemeasures;
    itemset_policies=Function[],
    arule_policies=Function[]
)

# unfortunately, even by creating the miner at BenchmarkTools' setup phase, the miner stays
# the same during the same evaluation batch!
# https://juliaci.github.io/BenchmarkTools.jl/dev/manual/#Setup-and-teardown-phases
@benchmark mine!(
    Miner(modaldataset, apriori, items, _itemmeasures, _rulemeasures;
        itemset_policies=Function[],
        arule_policies=Function[]
    );
    fpeonly=true
)

aprioriminer = Miner(modaldataset, apriori, items, _itemmeasures, _rulemeasures;
    itemset_policies=Function[],
    arule_policies=Function[]
);
@benchmark mine!(aprioriminer)

## Benchmark
