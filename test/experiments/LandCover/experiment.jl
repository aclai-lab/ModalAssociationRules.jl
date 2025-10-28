using DataFrames

using ModalAssociationRules

import SoleData: ninstances, frame

WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "LandCover")
LOADER_DIRECTORY = joinpath(WORKING_DIRECTORY, "data", "land-cover.jl")

include(LOADER_DIRECTORY)

X_array, y = LandCoverDataset(
    "Pavia University";
    window_size          = 3,
    ninstances_per_class = 40,
    pad_window_size      = 5,
);

# size(X) is an Array{Int64,4} of size (3,3,103,360),
# but we want it to be (3,3,360,103) before transforming it to a DataFrame

X_array = permutedims(X, (1,2,4,3))

df = DataFrame([
    [X_array[:, :, j, i] for j in axes(X_array, 3)]
    for i in axes(X_array, 4)
], :auto)

X_df = scalarlogiset(df)
