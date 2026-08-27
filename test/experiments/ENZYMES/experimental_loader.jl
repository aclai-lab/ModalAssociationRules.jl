using Graphs
using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame

"""
Function to load raw, non-euclidean (i.e., relational) data into a logiset.

# Example

The following example is based on the ENZYMES dataset, available at
https://networkrepository.com/ENZYMES.php

A pair is returned. First, a collection of Kripke models and, second, a list of 
integers/labels for each model.

Each world within a model is labeled with a proposition, via the valuation 
function of the model.

```julia
julia> load_noneuclidean_data(
    joinpath("data", "ENZYMES.edges"),
    joinpath("data", "ENZYMES.graph_idx"),
    joinpath("data", "ENZYMES.graph_labels"),
    joinpath("data", "ENZYMES.node_labels"),
)
    (SimpleModalFrame[SimpleModalFrame{World{Int64}, SimpleGraph{Int64}} with 37 worlds and 34 edges:
```
"""
function load_noneuclidean_data(
    edges_fpath::String,
    graph_indexes_fpath::String,
    graph_labels_fpath::String,
    node_labels_fpath::String,
)
    # load the edges, following the format:
    # 2,1
    # 3,1
    # 4,1
    _edges = [
        Tuple(parse.(Int, split(s, ","))) for
        s in split(read(edges_fpath, String))
    ]
    edges = Dict([u => v for (u, v) in _edges])

    # load the graph indexes (e.g., the first node belongs to the i-th graph)
    # then, load the label of each graph (its class)
    # finally, load each node's label; should be generalized to any raw data
    other_args = [
        parse.(Int, split(read(fpath, String))) for
        fpath in (graph_indexes_fpath, graph_labels_fpath, node_labels_fpath)
    ]

    return _load_noneuclidean_data(edges, other_args...)
end

function _load_noneuclidean_data(
    edges::Dict{Int,Int},
    graph_indexes::Vector{Int},
    graph_labels::Vector{Int},
    node_labels::Vector{Int},
)
    kripkeframes = ExplicitCrispUniModalFrame[]
    rawgraphs = SimpleGraph[]
    graph_and_ithnode_to_label = Dict{Tuple{Int,Int},Int}()

    _unique_graph_indexes = unique(graph_indexes)

    # find all the nodes corresponding to a certain graph
    groups = [findall(==(g), graph_indexes) for g in _unique_graph_indexes]

    for (graph_id, node_ids) in zip(_unique_graph_indexes, groups)
        _length_node_ids = length(node_ids)
        graph = Graphs.SimpleGraph(_length_node_ids)

        # subtract this number to a node's id to obtain a 0-based representation
        reminder = minimum(node_ids)

        for n in node_ids
            # push the edge associated with n into the graph, if it exists
            neighbor = get(edges, n, nothing)
            if !isnothing(neighbor)
                Graphs.add_edge!(graph, n - reminder, neighbor - reminder)
            end

            # associate the n-th node in the ith graph with its label
            graph_and_ithnode_to_label[(graph_id, n - reminder)] = node_labels[n]
        end

        push!(rawgraphs, graph)
        worlds = World.(1:_length_node_ids)
        push!(
            kripkeframes, SoleLogics.ExplicitCrispUniModalFrame(worlds, graph)
        )
    end

    # TODO: leverage graph_and_ithnode_to_label to create the valuation function
    # of each model in the Kripke frame
    return kripkeframes, graph_labels
end

