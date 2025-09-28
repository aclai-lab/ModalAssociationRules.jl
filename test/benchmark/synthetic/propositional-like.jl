# we want to randomize a modal dataset and measure the performances of MARM algorithms
# when varying the minimum threshold for local and global support.

using Graphs
using Iterators
using Random

rng = Xoshiro(7)

ninstances = 100

# structural variables, related to Kripke frames
# https://math.stackexchange.com/questions/1526372/what-is-the-definition-of-the-density-of-a-graph
graphdensity = 0.345
nworlds = 20
nedges = (graphdensity * nworlds * (nworlds-1) / 2) |> ceil |> Integer

# create a considerably big alphabet, with atoms wrapping "aa", "ab", "ac", ..., "zz"
alphrange = 97:1:(97+25)
alphabet = Iterators.product(alphrange, alphrange) |> collect |> vec .|>
    x -> x .|> Char |> join .|> Atom

modaldataset = Vector{KripkeStructure}([
    randmodel(rng, nworlds, nedges, alphabet, BooleanAlgebra())
    for _ in 1:ninstances
])
