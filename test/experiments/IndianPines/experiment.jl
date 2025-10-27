using Logging

using ModalAssociationRules

import SoleData: ninstances, frame

include("data/land-cover.jl")

X, y = LandCoverDataset("IndianPines")

ninstances(X) = 200
frame(X, i) =
