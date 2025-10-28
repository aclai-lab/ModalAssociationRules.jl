using ModalAssociationRules

import SoleData: ninstances, frame

WORKING_DIRECTORY = joinpath(@__DIR__, "test", "experiments", "LandCover")

include("data/land-cover.jl")

X_df, y = LandCoverDataset("Pavia University")
