
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
            push!(node_colors, "blue")
        elseif nodetype == 2
            push!(node_colors, "red")
        else
            push!(node_colors, "green")
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

class = 1
for ithexamp in 1:20
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
