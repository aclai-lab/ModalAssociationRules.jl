using DataFrames
using Serialization

using ModalAssociationRules

import SoleData: ninstances, frame

WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "LandCover")

# the association rules are serialized in this repository
RULES_REPOSITORY = joinpath(WORKING_DIRECTORY, "rules")

# the miners are serialized in this repository
MINERS_REPOSITORY = joinpath(WORKING_DIRECTORY, "miners")

# the final analysis is saved in this repository
RESULTS_REPOSITORY = joinpath(WORKING_DIRECTORY, "results")

# where the loading data is located
LOADER_DIRECTORY = joinpath(WORKING_DIRECTORY, "data", "land-cover.jl")
include(LOADER_DIRECTORY)


# RCC8 relations; actually, we will not consider all of them
DC, EC, PO, TPP, TPPi, NTPP, NTPPi = SoleLogics.RCC8Relations


# dataset loading
X_array, y = LandCoverDataset(
    "Pavia University";
    window_size          = 5, # this was 3 originally
    ninstances_per_class = 40,
    pad_window_size      = 5,
);

# size(X) is an Array{Int64,4} of size (3,3,103,360),
# but we want it to be (3,3,360,103) before transforming it to a DataFrame
X_array = permutedims(X_array, (1,2,4,3))

# we consider three classes
X_asphalt, _asphalt = X_array[:,:,1:40,:], "asphalt"
X_meadows, _meadows = X_array[:,:,41:80,:], "meadows"
X_gravel, _gravel = X_array[:,:,81:120,:], "gravel"


# logic for printing rules
include(joinpath(WORKING_DIRECTORY, "printreport.jl"))


# hook for inspecting things in the REPL
debug_logiset = nothing
debug_miner = nothing
debug_current_items = nothing

nitems_per_batch_propositional = 5
nitems_per_batch_modal = 5

# for each class, consider a different alphabet
for (_current_X, classname) in zip((X_water, X_trees, X_asphalt), (_asphalt,_trees,_gravel))

    # convert the Array{Int64, 4} into a DataFrame
    df = DataFrame([
        [_current_X[:, :, j, i] for j in axes(_current_X, 3)]
        for i in axes(_current_X, 4)
    ], :auto)

    _logiset = scalarlogiset(df)
    debug_logiset = _logiset

    # alphabet generation
    _medians = df .|> median |> eachcol .|> median
    _atoms = [(
        Atom(ScalarCondition(VariableMin(i), >=, m)),
        Atom(ScalarCondition(VariableMax(i), <=, m))
        ) for (i,m) in enumerate(_medians)
    ] |> Iterators.flatten |> collect

    _modal_atoms = Iterators.flatten((
        diamond(DC).(_atoms),
        diamond(PO).(_atoms)
        )) |> collect

    _propositional_items = Item.(_atoms)
    _modal_items = Item.(_modal_atoms)

    # we repeat the experiment with 10 batches of items, of size 20
    for i in 1:10
        printstyled(
            "Executing experiment number $i for the class $classname\n", color=:green)

        _current_items = vcat(
            sample(_propositional_items, nitems_per_batch_propositional; replace=false),
            sample(_modal_items, nitems_per_batch_modal; replace=false)
        )

        debug_current_items = _current_items

        # println("The current items are $(_current_items)")

        miner = Miner(
            _logiset,
            eclat,
            _propositional_items[1:10], # _current_items,
            # measure, local threshold, global threshold
            [(gsupport, 0.2, 0.1)],
            [(gconfidence, 0.1, 0.6), (glift, 0.5, 1.5)],
            itemset_policies=Function[
                isanchored_itemset(ignoreuntillength=1)
            ],
            arule_policies=Function[
                # islimited_length_arule(consequent_maxlength=3),
                isanchored_arule()
            ],

            # we only consider 5x5 patches
            worldfilter=SoleLogics.FunctionalWorldFilter(
                i -> (i.x.y - i.x.x == 5) && (i.y.y - i.y.x == 5), Interval2D{Int64}
            ),
        )
        debug_miner = miner

        mine!(miner)

        serialize(
            joinpath(MINERS_REPOSITORY, "miner_$(classname)_$i"),
            miner
        )

        for (i,rulegroup) in enumerate(arules(miner))
            serialize(
                joinpath(RULES_REPOSITORY, "rules_$(classname)_$(i)"),
                rulegroup
            )
        end

        try
            printreport(miner, i, arules(miner); reportprefix="rules_$(classname)_")
        catch e
            if e isa ArgumentError
                printstyled("Empty collection: $(classname)_$(i)\n", color=:red)
            end
        end
    end

end


# scratchpad
### DC, EC, PO, TPP, TPPi, NTPP, NTPPi = SoleLogics.RCC8Relations
### _interval = Interval2D((1,2), (1,2))
### _atom = ScalarCondition(VariableMin(1), >, 10) |> Atom
### check(_atom, getinstance(X_df, 1), _interval)
