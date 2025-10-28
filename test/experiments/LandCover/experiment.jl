using DataFrames


using ModalAssociationRules

import SoleData: ninstances, frame

WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "LandCover")
LOADER_DIRECTORY = joinpath(WORKING_DIRECTORY, "data", "land-cover.jl")

include(LOADER_DIRECTORY)

X, y = X_df, y = LandCoverDataset(
    "Pavia University";
    window_size          = 3,
    ninstances_per_class = 40,
    pad_window_size      = 5,
);
X_perm = permutedims(X, (1,2,4,3))

# the size of X_df is (103, 360)
X_df = [DataFrame(X[:, :, i, j], :auto) for i in axes(X,3), j in axes(X,4)]

# the size of X_df_perm is (360, 103), which is in line with y column vector
X_df_perm = [DataFrame(X_perm[:, :, i, j], :auto) for i in axes(X,4), j in axes(X,3)]
