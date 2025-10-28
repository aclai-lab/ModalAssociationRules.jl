using ModalAssociationRules

import SoleData: ninstances, frame

WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "LandCover")
LOADER_DIRECTORY = joinpath(WORKING_DIRECTORY, "data", "land-cover.jl")

include(LOADER_DIRECTORY)

X_df, y = X_df, y = LandCoverDataset(
    "Pavia University";
    window_size          = 3,
    ninstances_per_class = 40,
    pad_window_size      = 5,
);
