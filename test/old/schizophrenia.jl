### using Test
### using ModalAssociationRules
### using MLJ
### using Random
### using DataFrames
###
### _X, y = @load_iris
### X1 = DataFrame(hcat(values(_X)...), collect(keys(_X)))
### X = scalarlogiset(X1)
###
### manual_items = Vector{Item}(Atom.([
###     ScalarCondition(VariableMin(1), >,  5.84)
###     ScalarCondition(VariableMin(1), >,  4.0)
###     ScalarCondition(VariableMin(2), <=, 3.05)
###     ScalarCondition(VariableMin(2), <=, 2.0)
###     ScalarCondition(VariableMin(3), <=, 3.75)
###     ScalarCondition(VariableMin(3), <=, 2.0)
###     ScalarCondition(VariableMin(4), <=, 1.19)
###     ScalarCondition(VariableMin(4), <=, 0.0)
### ]))
###
### _itemsetmeasures = [(gsupport, 0.1, 0.1)]
### _rulemeasures = [(gconfidence, 0.2, 0.2)]
###
### # could not find feature VariableMin: min[V1] in memoset of type
### # SoleData.DimensionalDatasets.UniformFullDimensionalLogiset ...
### fpgrowth_miner = Miner(X, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
