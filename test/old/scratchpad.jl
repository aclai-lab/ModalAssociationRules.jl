using Test

using SoleLogics
using SoleData
using SoleModels
using StatsBase

# Tutorial from
# https://github.com/aclai-lab/modal-symbolic-learning-course/blob/main/Day3-gesture-recognition.ipynb


# Load an example time-series classification dataset as a tuple (DataFrame, Vector{String})
X_df, y = SoleData.load_arff_dataset("NATOPS");
fr = SoleLogics.frame(X_df, 1)

# collect(accessibles(fr, Interval(10,30), IA_L)) |> print

# allworlds(fr) |> print

# Let's consider the first variable in X_df, that is, "hand tip l"
# and compute its minimum.
feature = VariableMin(1)

# min[V1] of the 7th instance on the interval (10,30)
# Sole.featvalue(feature, X_df, 7, Interval(10,30)) |> print

# min[V1] for each interval/world in the 1th instance
# for w in allworlds(fr)
#    print("$(featvalue(feature, X_df, 1, w))\n")
# end

# Multi-modal kripke logiset
X = scalarlogiset(X_df)

# check min[V1] > -0.5 on the interval (10,30) of the first instance
p = Atom(ScalarCondition(feature, >, -0.3))
check(p, X, 1, Interval(10,30))

# check min[V1] > -0.5 ∨ min[V2] <= 10
p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
φ = p ∨ q
println(syntaxstring(φ))

check(φ, X, 1, Interval(10,30))

# check [L](min[V1] > -0.5 ∨ min[V2] ≤ 10)
boxlater = box(IA_L)
lφ = boxlater(φ)
check(lφ, X, 1, Interval(10,30))

# Let's check lφ on all instances
check_mask = check(lφ, X, Interval(10,30));
println("Check mask: $(check_mask) (holds on $(sum(check_mask)))")

# Let's ask whether the formula holds all intervals
universal_φ = globalbox(φ)
check_mask = check(universal_φ, X);
println("Check mask: $(check_mask) (holds on $(sum(check_mask)))")

# Let's ask whether there exists any interval where the formula holds
existential_φ = globaldiamond(φ)
check_mask = check(existential_φ, X);
println("Check mask: $(check_mask) (holds on $(sum(check_mask)))")

# Print in natural language
println(SoleLogics.experimentals.formula2natlang(existential_φ))
# Alternative, using feature abbreviations
# println(SoleLogics.experimentals.formula2natlang(existential_φ; use_feature_abbreviations = true))

# Show how many classes are covered by the check mask
countmap(y[check_mask .== 1])

# Show how many classes are NOT covered by the check mask
countmap(y[(!).(check_mask)])

# allw = allworlds(X, 1)
#
# items = p, dp, bp
# φ = items[1]
#
# glob = 0
# for i_instance in 1:ninstances(X)
#     acc = 0
#     for w in allw
#         acc = acc + check(φ, X, i_instance, w)
#     end
#
#     if acc > local_threshold
#         glob = glob + 1
#     end
# end
#
# if glob not abbastanza
#     remove φ from items
#
# items = [[p dp]]
