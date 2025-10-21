using Graphs

using ModalAssociationRules
using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame


# load ENZYMES dataset
DATA_REPOSITORY = joinpath(@__DIR__, "test", "experiments", "ENZYMES", "data")


# every label is one of the 6 types of enzymes;
# the dataset is balanced, with 100 enzymes of each type.
LABELS_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_graph_labels.txt")
labels = parse.(Int, split(read(LABELS_FILENAME, String) |> strip, "\n") .|> String)


# every node belongs to one of the 600 total graphs
GRAPH_INDICATOR_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_graph_indicator.txt")
node_to_graph = parse.(
    Int,
    split(read(GRAPH_INDICATOR_FILENAME, String) |> strip, "\n")
)


# every node encodes one of the three possible protein SSE (secondary structure element)
# 1: helix (a total of 9457 nodes)
# 2: sheet (a total of 9665 nodes)
# 3: turn (a total of 458 nodes)
NODE_LABELS_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_node_labels.txt")
node_labels = parse.(
    Int,
    split(read(NODE_LABELS_FILENAME, String) |> strip, "\n")
)
# this is needed later, since we are going to let nodes start from 1 in every new graph
# and we do not want to lose the reference to the corresponding label of the node
graph_and_ithnode_to_label = Dict{Tuple{Int,Int},Int}()


# the effective graph structure
EDGES_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_A.txt")
edges = [
    parse.(Int, strip.(split(s, ","))) |> Tuple
    for s in split(read(EDGES_FILENAME, String) |> strip, "\n")
]

# mapping from node to neighbor
from_to = Dict([
    u => v
    for (u,v) in edges
])


# compose the effective graph structure (i encodes the ith graph)
kripkeframes = ExplicitCrispUniModalFrame[]
for i in 1:600
    # retrieve all the nodes of the ith graph
    _nodes = findall(x -> x == i, node_to_graph)

    # we want the worlds to start at 1, by adding a normalization scalar (𝑁)
    𝑁 = minimum(_nodes) - 1

    # create the graph
    graph = Graphs.SimpleGraph(length(_nodes))

    for n in _nodes
        # push the edge associated with n into the graph, if it exists
        neighbor = get(from_to, n, nothing)
        if !isnothing(neighbor)
            Graphs.add_edge!(graph, n-𝑁, neighbor-𝑁)
        end

        # also, associate the (n-𝑁)-th node in the ith graph with the corresponding label
        graph_and_ithnode_to_label[(i,n-𝑁)] = node_labels[n]
    end

    # create the kripke frame
    worlds = World.(1:length(_nodes))
    push!(kripkeframes, SoleLogics.ExplicitCrispUniModalFrame(worlds, graph))
end


# alphabet definition
helix = Atom(1)
sheet = Atom(2)
turn = Atom(3)
_atoms = [helix, sheet, turn]


# every world within each frame has to be enriched with one atom encoding the
# secondary structure element of a protein
modaldataset = KripkeStructure[]

for (i,kripkeframe) in enumerate(kripkeframes)
    valuation = Dict([
        w => TruthDict([Atom(graph_and_ithnode_to_label[(i, w.name)]) => TOP])
        for w in kripkeframe.worlds
    ])

    push!(modaldataset, KripkeStructure(kripkeframe, valuation))
end


# atoms are enriched with modal operators (◊ and □), and are converted to items
_todiamond = x -> diamond().(x)
_tobox = x -> box().(x)

_items = Vector{Item}(
    Iterators.flatten([
        _atoms,

        _atoms |> _todiamond,
        _atoms |> _todiamond |> _todiamond,
        _atoms |> _todiamond |> _todiamond |> _todiamond,
        # _atoms |> _todiamond |> _todiamond |> _todiamond |> _todiamond,
        # _atoms |> _todiamond |> _todiamond |> _todiamond |> _todiamond |> _todiamond,

        # box().(_atoms),
        # diamond().(box().(_atoms)),
        # box().(box().(_atoms)),
    ]) |> collect
)


# partition the modal dataset into the six groups of enzymes
_mask_indexes = id -> findall(x -> x == id, labels)
MODAL_DATASET_1 = modaldataset[_mask_indexes(1)] |> Logiset
MODAL_DATASET_2 = modaldataset[_mask_indexes(2)] |> Logiset
MODAL_DATASET_3 = modaldataset[_mask_indexes(3)] |> Logiset
MODAL_DATASET_4 = modaldataset[_mask_indexes(4)] |> Logiset
MODAL_DATASET_5 = modaldataset[_mask_indexes(5)] |> Logiset
MODAL_DATASET_6 = modaldataset[_mask_indexes(6)] |> Logiset

# dataset synonyms
# Oxidoreductases
𝑂 = MODAL_DATASET_1
# Transferases
𝑇 = MODAL_DATASET_2
# Hydrolases
𝐻 = MODAL_DATASET_3
# Lyases
𝐿𝑦 = MODAL_DATASET_4
# Isomerases
𝐼 = MODAL_DATASET_5
# Ligases
𝐿𝑖 = MODAL_DATASET_6


rules = Vector{Vector{ARule}}()

for _dataset in [
        MODAL_DATASET_1
        MODAL_DATASET_2
        MODAL_DATASET_3
        MODAL_DATASET_4
        MODAL_DATASET_5
        MODAL_DATASET_6
    ]


    miner = Miner(
        MODAL_DATASET_1,
        eclat,
        _items,
        [(gsupport, 0.1, 0.2)],
        [(gconfidence, 0.1, 0.1)],
        itemset_policies=Function[
            isanchored_itemset()
        ],
        arule_policies=Function[
            # islimited_length_arule(consequent_maxlength=3),
            isanchored_arule()
        ]
    )

    mine!(miner)

    push!(rules, arules(miner))
end
