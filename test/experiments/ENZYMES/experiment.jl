using Graphs
import Serialization

using ModalAssociationRules
using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame

# dependencies for graph plotting
using Plots
using GraphPlot
using Compose
import Cairo, Fontconfig


# to fix the directory in which this file lives
WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "ENZYMES")

# the association rules are serialized in this repository
RULES_REPOSITORY = joinpath(WORKING_DIRECTORY, "rules")
# the miners are serialized in this repository
MINERS_REPOSITORY = joinpath(WORKING_DIRECTORY, "miners")
# the final analysis is saved in this repository
RESULTS_REPOSITORY = joinpath(WORKING_DIRECTORY, "results")


# load ENZYMES dataset
DATA_REPOSITORY = joinpath(WORKING_DIRECTORY, "data")


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


# convert the id of a node (1,2 or 3) to the corresponding secondary structure element;
# 1 is helix, 2 is sheet, 3 is turn
function id_to_sse(id::Int)
    return id == 1 ? "h" : (id == 2 ? "s" : "t")
end


# compose the effective graph structure (i encodes the ith graph)
kripkeframes = ExplicitCrispUniModalFrame[]
rawgraphs = SimpleGraph[]

for i in 1:600
    # retrieve all the nodes of the ith graph
    _nodes = findall(x -> x == i, node_to_graph)

    # we want the worlds to start at 1, by adding a normalization scalar (scalar)
    scalar = minimum(_nodes) - 1

    # create the graph
    graph = Graphs.SimpleGraph(length(_nodes))

    for n in _nodes
        # push the edge associated with n into the graph, if it exists
        neighbor = get(from_to, n, nothing)
        if !isnothing(neighbor)
            Graphs.add_edge!(graph, n-scalar, neighbor-scalar)
        end

        # also, associate the (n-scalar)-th node in the ith graph with the corresponding label
        graph_and_ithnode_to_label[(i,n-scalar)] = node_labels[n]
    end

    # collect raw graphs for possible visualization purposes
    push!(rawgraphs, graph)

    # create the kripke frame
    worlds = World.(1:length(_nodes))
    push!(kripkeframes, SoleLogics.ExplicitCrispUniModalFrame(worlds, graph))
end


# alphabet definition

# fundamental propositions
helix, nothelix = Atom("h"), NEGATION(Atom("h"))
sheet, notsheet = Atom("s"), NEGATION(Atom("s"))
turn, notturn = Atom("t"), NEGATION(Atom("t"))

# base alphabet that is enriched in various manners
seed_alphabet = SyntaxTree[helix, sheet, turn]

# you can choose wheter to also consider relaxed propositions
push!(seed_alphabet, DISJUNCTION(helix, sheet))
push!(seed_alphabet, DISJUNCTION(helix, turn))
push!(seed_alphabet, DISJUNCTION(sheet, turn))

propositional_alphabet = convert(Vector{SyntaxTree}, deepcopy(seed_alphabet))

# box and diamond up to modal depth 1
for op in [DIAMOND, BOX]
    for p in seed_alphabet
        push!(propositional_alphabet, op(p))
    end
end

# all the combinations of box and diamond up to modal depth 2
for ((op1, op2)) in Iterators.product([DIAMOND, BOX], [DIAMOND, BOX])
    for p in Iterators.flatten([seed_alphabet, NEGATION.(seed_alphabet)])
        push!(propositional_alphabet, op1(op2(p)))
    end
end


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


# materialize the items for mining
_items = Item.(propositional_alphabet)

### deprecated
### # atoms are enriched with modal operators (◊ and □), and are converted to items
### _todiamond = x -> diamond().(x)
### _tobox = x -> box().(x)
###
### _items = Vector{Item}(
###     Iterators.flatten([
###         _atoms,
###
###         _atoms |> _todiamond,
###         _atoms |> _todiamond |> _todiamond,
###         _atoms |> _todiamond |> _todiamond |> _todiamond,
###         # _atoms |> _todiamond |> _todiamond |> _todiamond |> _todiamond,
###         # _atoms |> _todiamond |> _todiamond |> _todiamond |> _todiamond |> _todiamond,
###
###         _atoms |> _tobox,
###         _atoms |> _tobox |> _tobox,
###         _atoms |> _tobox |> _tobox |> _tobox
###     ]) |> collect
### )


# partition the modal dataset into the six groups of enzymes
_mask_indexes = id -> findall(x -> x == id, labels)
# Oxidoreductases
MODAL_DATASET_1 = modaldataset[_mask_indexes(1)] |> Logiset
# Transferases
MODAL_DATASET_2 = modaldataset[_mask_indexes(2)] |> Logiset
# Hydrolases
MODAL_DATASET_3 = modaldataset[_mask_indexes(3)] |> Logiset
# Lyases
MODAL_DATASET_4 = modaldataset[_mask_indexes(4)] |> Logiset
# Isomerases
MODAL_DATASET_5 = modaldataset[_mask_indexes(5)] |> Logiset
# Ligases
MODAL_DATASET_6 = modaldataset[_mask_indexes(6)] |> Logiset


# full dataset
MODAL_DATASET_FULL = vcat(
    modaldataset[_mask_indexes(1)]...,
    modaldataset[_mask_indexes(2)]...,
    modaldataset[_mask_indexes(3)]...,
    modaldataset[_mask_indexes(4)]...,
    modaldataset[_mask_indexes(5)]...,
    modaldataset[_mask_indexes(6)]...,
) |> Logiset


datasets = [
    MODAL_DATASET_1,
    MODAL_DATASET_2,
    MODAL_DATASET_3,
    MODAL_DATASET_4,
    MODAL_DATASET_5,
    MODAL_DATASET_6,
]

datasetnames = [
    "Oxidoreductases",
    "Transferases",
    "Hydrolases",
    "Lyases",
    "Isomerases",
    "Ligases",
]

rules = Vector{Vector{ARule}}()

# estimated number of match to consider a pattern to be frequent within a modal instance
ADAPTIVE_LSUPP_THRESHOLD_FACTOR = 3

for (i,_dataset) in enumerate([
        MODAL_DATASET_1
        MODAL_DATASET_2
        MODAL_DATASET_3
        MODAL_DATASET_4
        MODAL_DATASET_5
        MODAL_DATASET_6
    ])

    println("Mining $i-th enzyme")

    _instances = _dataset |> instances
    _lsupp_threshold = ADAPTIVE_LSUPP_THRESHOLD_FACTOR / (
        sum(x -> length(x.frame.worlds), _instances) / (length(_instances))
    )

    miner = Miner(
        _dataset,
        eclat,
        _items,
        [(gsupport, _lsupp_threshold*0.85, 0.05)],
        [(gconfidence, 0.1, 0.5), (glift, 0.5, 2.0)],
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

    serialize(
        joinpath(MINERS_REPOSITORY, "miner_$i"),
        miner
    )
end


# we serialize each group of rules
for (i,rulegroup) in enumerate(rules)
    serialize(
        joinpath(RULES_REPOSITORY, "enzymes_$i"),
        rulegroup
    )
end


# overwrite rules with the serialized ones, and interpret them as sets;
_nclasses = 6
rulesets = [Set{ARule}() for _ in 1:_nclasses]
for i in 1:length(rules)
    rules[i] = deserialize(joinpath(RULES_REPOSITORY, "enzymes_$i"))
    rulesets[i] = rules[i] |> Set
end


# rules that are unique to each group
isolated_rulesets = deepcopy(rulesets)

for i in 1:_nclasses
    # given a set of rules, we want to setdiff with all the other
    for j in 1:_nclasses
        println("$i - $j")

        # of course, we avoid applying setdiff to the same ith set
        if i == j
            continue
        end

        setdiff!(isolated_rulesets[i], rulesets[j])
    end
end


##### results printing #####################################################################

# for each previously trained miner, we want to print the resulting rules in the
# results folder, also reporting the meaningfulness measures
function printreport(
    _miner::Miner,
    i::Int,
    rules::Vector{ARule};
    reportprefix::String="results_"
)
    # we expect the experiment to consider global confidence and global lift
    rulecollection = [
        (
            rule,
            round(
                globalmemo(_miner, (:gsupport, antecedent(rule))), digits=2
                ),
            round(
                globalmemo(_miner, (:gsupport, Itemset(rule))), digits=2
            ),
            round(
                globalmemo(_miner, (:gconfidence, rule)), digits=2
            ),
            round(
                globalmemo(_miner, (:glift, rule)), digits=2
            ),
        )
        for rule in rules
    ]

    # rules are ordered decreasingly by global lift
    sort!(rulecollection, by=x->x[5], rev=true);

    reportname = joinpath(RESULTS_REPOSITORY, "$(reportprefix)$(i)")

    println("Writing to: $(reportname)")

    open(reportname, "w") do io
        println(io, "Columns are: rule, ant support, ant+cons support,  confidence, lift")

        padding = maximum(length.(_miner |> freqitems))
        for (rule, antgsupp, consgsupp, conf, lift) in rulecollection
            println(io,
                rpad(rule, 8 * padding) * " " * rpad(string(antgsupp), 10) * " " *
                rpad(string(consgsupp), 10) * " " * rpad(string(conf), 10) * " " *
                string(lift)
            )
        end
    end
end


# we print all the rules for each miner
for i in 1:_nclasses
    _miner = deserialize(joinpath(MINERS_REPOSITORY, "miner_$i"))
    printreport(_miner, i, arules(_miner))
end


# we also print the very unique sets of rules for each miner
for i in 1:_nclasses
    _miner = deserialize(joinpath(MINERS_REPOSITORY, "miner_$i"))

    printreport(_miner, i, isolated_rulesets[i] |> collect;
        reportprefix="isolated_results_")
end


##### visualization ########################################################################

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
