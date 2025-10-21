using Graphs

using ModalAssociationRules
using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame


# load ENZYMES dataset
DATA_REPOSITORY = joinpath(@__DIR__, "test", "experiments", "ENZYMES", "data")


# every label is one of the 6 types of enzymes;
# the dataset is balanced, with 100 enzymes of each type.
LABELS_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_graph_labels.txt")
labels = split(read(LABELS_FILENAME, String) |> strip, "\n") .|> String


# every node belongs to one of the 600 total graphs
GRAPH_INDICATOR_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_graph_indicator.txt")
node_to_class = parse.(
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


# the effective graph structure
EDGES_FILENAME = joinpath(DATA_REPOSITORY, "ENZYMES_A.txt")
edges = [
    parse.(Int, strip.(split(s, ","))) |> Tuple
    for s in split(read(EDGES_FILENAME, String) |> strip, "\n")
]
