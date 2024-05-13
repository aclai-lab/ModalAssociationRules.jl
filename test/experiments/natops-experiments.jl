using Test

using ModalAssociationRules
using SoleData
using StatsBase

import ModalAssociationRules.children

X_df, y = load_NATOPS();
X = scalarlogiset(X_df)
