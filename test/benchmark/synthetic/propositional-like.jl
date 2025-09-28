# we want to randomize a modal dataset (logiset) and measure the performances of MARM algorithms
# when varying the minimum threshold for local and global support.

using ModalAssociationRules

using Graphs
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

# SoleLogics does not provide a simple Logiset structure;
# we create this little wrapper, treating a vector as if it were an AbstractDataset (which is a MineableData type)
struct Logiset <: AbstractDataset
    instances::Vector{KripkeStructure}
end

function instances(logiset::Logiset)
    return logiset.instances
end

function ModalAssociationRules.ninstances(logiset::Logiset)
    return logiset |> instances |> length
end

function ModalAssociationRules.getinstance(logiset::Logiset, i::Int64)::SoleLogics.LogicalInstance
    return SoleLogics.LogicalInstance(
        SoleLogics.InterpretationVector(logiset |> instances), i)
end

function ModalAssociationRules.frame(logiset::Logiset, i::Int64)
    instances(logiset)[i] |> frame
end

function Base.show(io::IO, logiset::Logiset)
    print(io, "Logiset with $(logiset.instances |> length) instances.")
end

modaldataset = Vector{KripkeStructure}([
    randmodel(rng, nworlds, nedges, alphabet, BooleanAlgebra())
    for _ in 1:ninstances
]) |> Logiset;

function getinstance(logiset::Logiset, i::Integer)
    return logiset.instances[i]
end

items = Item.(alphabet)
_itemmeasures = [(gsupport, 0.8, 0.8)]
_rulemeasures = [(gconfidence, 0.8, 0.8)]

aprioriminer = Miner(modaldataset, apriori, items, _itemmeasures, _rulemeasures;
    itemset_policies=Function[]
)

mine!(aprioriminer)
