using Graphs

using ModalAssociationRules

using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame
using SoleLogics: TOP

DATAPATH = joinpath(@__DIR__, "test", "benchmark", "pythonic", "sample.txt")

transactions = []

# every entry in transactions is a list of unique (propositional) facts
open(DATAPATH, "r") do file
    for line in eachline(file)
        atoms = split(line) .|> string .|> Atom
        push!(transactions, atoms)
    end
end

items = [t for transaction in transactions for t in transaction] |> unique .|> Item
itemmeasures = [(gsupport, 1.0, 0.2)]
rulemeasures = [(gconfidence, 0.8, 0.8)]

# create a degenerate Kripke frame, containing only one world (i.e., a propositional model)
world = World.(1:1)
graph = Graphs.SimpleDiGraph(1, 0)
fr = SoleLogics.ExplicitCrispUniModalFrame(world, graph)

modaldataset = Vector{KripkeStructure}([
    KripkeStructure(
        fr,
        Dict([
            w => TruthDict([fact => TOP for fact in transaction])
            for w in fr.worlds
        ])
    )

    for transaction in transactions
]) |> Logiset

miner = Miner(
    modaldataset,
    fpgrowth,
    items,
    itemmeasures,
    rulemeasures;
    itemset_policies=Function[],
    arule_policies=Function[]
);

mine!(miner; fpeonly=true)
