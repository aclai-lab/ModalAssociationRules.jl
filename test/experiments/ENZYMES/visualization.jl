using Statistics

# indexes for which you find an example of graph for each type
_eid1 = findall(x -> x == 1, labels) |> first
_eid2 = findall(x -> x == 2, labels) |> first
_eid3 = findall(x -> x == 3, labels) |> first
_eid4 = findall(x -> x == 4, labels) |> first
_eid5 = findall(x -> x == 5, labels) |> first
_eid6 = findall(x -> x == 6, labels) |> first

# one graph for each label
g1 = rawgraphs[_eid1]
g2 = rawgraphs[_eid2]
g3 = rawgraphs[_eid3]
g4 = rawgraphs[_eid4]
g5 = rawgraphs[_eid5]
g6 = rawgraphs[_eid6]

for (i,g) in zip([_eid1, _eid2, _eid3, _eid4, _eid5, _eid6], [g1,g2,g3,g4,g5,g6])
    node_colors = []
    for ithnode in 1:nv(g)
        nodetype = graph_and_ithnode_to_label[(i,ithnode)]
        if nodetype == 1
            push!(node_colors, "blue") # helix (h)
        elseif nodetype == 2
            push!(node_colors, "red") # sheet (s)
        else
            push!(node_colors, "green") # turns (t)
        end
    end

    p = gplot(g, nodefillc=node_colors)

    Compose.draw(
        Compose.PNG(joinpath(WORKING_DIRECTORY, "plots", "enzym_$i.png"), 600,  600), p)
end


##### REPL scratchpad for copy-pasting #####################################################

println((
    3 / sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(1)]) / 100)
)
println((
    3 / sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(2)]) / 100)
)
println((
    3 / sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(3)]) / 100)
)
println((
    3 / sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(4)]) / 100)
)
println((
    3 / sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(5)]) / 100)
)
println((
    3 / sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(6)]) / 100)
)


############################################################################################

# save the png for the first `nexamples` of `class`

nexamples = 20
class = 1
for ithexamp in 1:nexamples
    _eid1 = findall(x -> x == class, labels)[ithexamp]
    g1 = rawgraphs[_eid1]

    for (i,g) in zip([_eid1], [g1])
        node_colors = []
        for ithnode in 1:nv(g)
            nodetype = graph_and_ithnode_to_label[(i,ithnode)]
            if nodetype == 1
                push!(node_colors, "blue")
            elseif nodetype == 2
                push!(node_colors, "red")
            else
                push!(node_colors, "green")
            end
        end

        p = gplot(g, nodefillc=node_colors)

        Compose.draw(
            Compose.PNG(joinpath(WORKING_DIRECTORY, "plots", "CLASS$(class)_enzym_$(i)_$(ithexamp).png"), 600,  600), p)
    end
end

# variance across classes
x = [sum(x -> length(x.frame.worlds), modaldataset[_mask_indexes(i)])/100 for i in 1:6]
[(x[i] - sum(x)/6)^2 / 6 for i in 1:6] |> sum

# variance within a class
c = 1
worlds_in_class_instances = [length(x.frame.worlds) for x in modaldataset[_mask_indexes(c)]]
mean_worlds_within_instance = mean(worlds_in_class_instances)
[(i - mean_worlds_within_instance)^2 / 100 for i in worlds_in_class_instances] |> sum


##### regex for querying the results #######################################################
#^(?=.*\(◊□h\))(?=.*\(□¬s\))(?=.*\(□h\))(?=.*\(◊¬s\))(?=.*\(h\))(?=.*\(◊h\))(?=.*=>\s*□□h).*
