# this script is intended to play with SoleLogics package, leveraging `KripkeStructure`s
# to handle a more lightweight version of the standard `UniformFullDimensionalLogiset`.

using SoleLogics
using ModalAssociationRules

# considering NATOPS dataset, these are all the possible intervals we want to deal with
intervals = [
    [Interval(s, s+9) for s in 1:10:41]...,
    [Interval(s, s+19) for s in 1:10:31]...,
    [Interval(s, s+29) for s in 1:10:21]...,
    [Interval(s, s+39) for s in 1:10:11]...,
    [Interval(s, s+49) for s in 1:10:1]...,
]

# every interval is encoded by a world, wrapping an integer ID
world_ids = collect(1:length(intervals))
worlds = SoleLogics.World.(world_ids)

# let's say we want a dense, undirected graph
edges = [
    Edge((i,j))
    for i in world_ids
    for j in world_ids
]

myframe = SoleLogics.ExplicitCrispUniModalFrame(worlds, edges |> SimpleGraph)
