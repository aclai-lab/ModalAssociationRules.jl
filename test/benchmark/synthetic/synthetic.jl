# we want to randomize a modal dataset (logiset) and measure the performances of MARM algorithms
# when varying the minimum threshold for local and global support.

using ModalAssociationRules
using SoleData
using SoleLogics

using Graphs
using Random

TESTFOLDER = joinpath(@__DIR__, "test", "benchmark", "synthetic")

include((TESTFOLDER, "logiset.jl") |> joinpath)
include((TESTFOLDER, "generation.jl") |> joinpath)

## Preamble

rng = Xoshiro(7)

_ninstances = 100

# structural variables, related to Kripke frames
# https://math.stackexchange.com/questions/1526372/what-is-the-definition-of-the-density-of-a-graph
graphdensity = 0.345
nworlds = 1
nedges = (graphdensity * nworlds * (nworlds-1) / 2) |> ceil |> Integer

# create a considerably big alphabet, with atoms wrapping "aa", "ab", "ac", ..., "zz"
alphrange = 97:1:(97+25)
alphabet = Iterators.product(alphrange, alphrange) |> collect |> vec .|>
    x -> x .|> Char |> join .|> Atom

## Generation

modaldataset = Vector{KripkeStructure}([
    generate(
        randframe(rng, nworlds, nedges),
        alphabet,
        SoleLogics.inittruthvalues(BooleanAlgebra());
        fulltransfer=true,
    )
    for _ in 1:_ninstances
]) |> Logiset;

items = Item.(alphabet)
_itemmeasures = [(gsupport, 0.8, 0.8)]
_rulemeasures = [(gconfidence, 0.8, 0.8)]

aprioriminer = Miner(modaldataset, apriori, items, _itemmeasures, _rulemeasures;
    itemset_policies=Function[]
)

mine!(aprioriminer)


## Benchmark
