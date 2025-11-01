using DataFrames

using ModalAssociationRules

import SoleData: ninstances, frame

WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "LandCover")
LOADER_DIRECTORY = joinpath(WORKING_DIRECTORY, "data", "land-cover.jl")

include(LOADER_DIRECTORY)


# dataset loading

X_array, y = LandCoverDataset(
    "Pavia University";
    window_size          = 3,
    ninstances_per_class = 40,
    pad_window_size      = 5,
);

# size(X) is an Array{Int64,4} of size (3,3,103,360),
# but we want it to be (3,3,360,103) before transforming it to a DataFrame

X_array = permutedims(X_array, (1,2,4,3))

df = DataFrame([
    [X_array[:, :, j, i] for j in axes(X_array, 3)]
    for i in axes(X_array, 4)
], :auto)

X_df = scalarlogiset(df)

# alphabet generation
_medians = df .|> median |> eachcol .|> median
_atoms = [(
    Atom(ScalarCondition(VariableMin(i), >=, m)),
    Atom(ScalarCondition(VariableMax(i), <=, m))
    ) for (i,m) in enumerate(_medians)
] |> Iterators.flatten |> collect

DC, EC, PO, TPP, TPPi, NTPP, NTPPi = SoleLogics.RCC8Relations
_modal_atoms = Iterators.flatten((
    diamond(DC).(_atoms),
    diamond(PO).(_atoms)
)) |> collect

_items = Item.((_atoms, _modal_atoms) |> Iterators.flatten)



# alphabet definition
### DC, EC, PO, TPP, TPPi, NTPP, NTPPi = SoleLogics.RCC8Relations
### _interval = Interval2D((1,2), (1,2))
### _atom = ScalarCondition(VariableMin(1), >, 10) |> Atom
### check(_atom, getinstance(X_df, 1), _interval)
