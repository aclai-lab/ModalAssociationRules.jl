############################################################################################
# Preamble
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# In this file are organized the experiments for NATOPS dataset.
# NATOPS stands for Naval Air Training and Operating Procedures Standardization.
#
# Each class (e.g., "I Have Command") is associated with a movement, identified by
# X,Y and Z coordinates of hand tips, elbows, wrists and thumbs.
# To visualize some class labels, check out the following link:
# https://github.com/yalesong/natops.
############################################################################################

using Test

using ModalAssociationRules
using Dates
using Plots
using SoleData
using StatsBase
using SoleLogics

import ModalAssociationRules.children

RESULTS_PATH = "test/experiments/results/"

VARIABLE_NAMES = [
	"X[Hand tip l]", "Y[Hand tip l]", "Z[Hand tip l]", # 1 3
	"X[Hand tip r]", "Y[Hand tip r]", "Z[Hand tip r]", # 4 6
    "X[Elbow l]", "Y[Elbow l]", "Z[Elbow l]",          # 7 9
	"X[Elbow r]", "Y[Elbow r]", "Z[Elbow r]",          # 10 12
    "X[Wrist l]", "Y[Wrist l]", "Z[Wrist l]",          # 13 15
	"X[Wrist r]", "Y[Wrist r]", "Z[Wrist r]",          # 16 18
    "X[Thumb l]", "Y[Thumb l]", "Z[Thumb l]",          # 19 21
	"X[Thumb r]", "Y[Thumb r]", "Z[Thumb r]",          # 22 24
]

class_names = [
	"I have command",
	"All clear",
	"Not clear",
	"Spread wings",
	"Fold wings",
	"Lock wings",
]

coordinate_labels = ["X", "Y", "Z"] # just to prettier the plots below

############################################################################################
# Setup & Driver
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NATOPS dataset is loaded, and it's entirely transformed in a Logiset (see `X`).
# Then, for each class, a DataFrame window is sliced, and a now Logiset is built.
############################################################################################

X_df, y = load_NATOPS();
X = scalarlogiset(X_df)

X_df_1_have_command = X_df[1:30, :]
X_1_have_command = scalarlogiset(X_df_1_have_command)

X_df_2_all_clear = X_df[31:60, :]
X_2_all_clear = scalarlogiset(X_df_2_all_clear)

X_df_3_not_clear = X_df[61:90, :]
X_3_not_clear = scalarlogiset(X_df_3_not_clear)

X_df_4_spread_wings = X_df[91:120, :]
X_4_spread_wings = scalarlogiset(X_df_4_spread_wings)

X_df_5_fold_wings = X_df[121:150, :]
X_5_fold_wings = scalarlogiset(X_df_5_fold_wings)

X_df_6_lock_wings = X_df[151:180, :]
X_6_lock_wings = scalarlogiset(X_df_6_lock_wings)


function runexperiment(
	X::AbstractDataset,
	algorithm::Function,
	items::Vector{Item},
	itemsetmeasures::Vector{<:MeaningfulnessMeasure},
	rulemeasures::Vector{<:MeaningfulnessMeasure};
	reportname::Union{Nothing, String} = nothing,
	variable_names::Union{Nothing, Vector{String}} = nothing
)
    # avoid filling the given dataset with infos necessary to optimize future minings,
    # and don't use those metadata if already loaded up!
    # In fact, that could make experiments uncorrect (e.g., confidences over 1.0).
    _X = deepcopy(X)

	miner = Miner(_X, algorithm, items, itemsetmeasures, rulemeasures)
	mine!(miner)
	generaterules!(miner) |> collect

	if isnothing(reportname)
		reportname = now() |> string
	end
	reportname = RESULTS_PATH * reportname

	open(reportname, "w") do out
		redirect_stdout(out) do
            # For some reason, `itemsetmeasures` and `rulemeasures` getters triggers
            # a MethodError here (maybe this is caused by stdout redirection?).
            println("Parameterization:\n")
            println(miner.item_constrained_measures)
            println(miner.rule_constrained_measures)

            println("\nResults:\n")
			for r in sort(
                arules(miner), by = x -> miner.gmemo[(:gconfidence, x)], rev=true)
				ModalAssociationRules.analyze(
                    r, miner; variable_names=variable_names, itemsets_global_info=true)
			end
		end
	end
end

############################################################################################
# Data Observation
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each experiment is prepended with a comment explaining the chosen literals.
# We start by analyzing each "triplet": left hand X,Y,Z, then right hand, and so on).
# Our goal is to find a mapping between body-part and where the body part is activated.
# The right part of the body (hand, elbow, wrist, thumb) are involved in each action, while
# the left part is involved only during "Spread wings", "Fold wings", "Lock wings";
# in particular, the left elbow is also involved in "All clear" action.
#
# Please, use the following command to plot all 24 NATOPS variables, considering the first
# example for each class (1, 31, 61... are the instances associated with each new label).
#
#=
plot(
	map(i->plot(collect(X_df[i,:]), labels=nothing,title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#
############################################################################################

# Left hand (V1, V2, V3) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: "Spread wings", "Fold wings", "Lock wings".
#=
plot(
	map(i->plot(collect(X_df[i,1:3]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Right hand ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: every class.
#=
plot(
	map(i->plot(collect(X_df[i,4:6]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Left elbow ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: "All clear", "Spread wings", "Fold wings", "Lock wings".
#=
plot(
	map(i->plot(collect(X_df[i,7:9]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Right elbow ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: every class.
#=
plot(
	map(i->plot(collect(X_df[i,10:12]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Left wrist ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: "Spread wings", "Fold wings", "Lock wings".
#=
plot(
	map(i->plot(collect(X_df[i,13:15]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Right wrist ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: every class
#=
plot(
	map(i->plot(collect(X_df[i,16:18]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Left thumb ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: "Spread wings", "Fold wings", "Lock wings".
#=
plot(
	map(i->plot(collect(X_df[i,19:21]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

# Right thumb ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Involved in: "Spread wings", "Fold wings", "Lock wings".
#=
plot(
	map(i->plot(collect(X_df[i,22:24]), labels=["x" "y" "z"], title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

############################################################################################
# Experiment #1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Right hand tips without temporal relations.
# V4, V5, V6 - right hand tip
# V4:   X, the hand is below, then in front, then up (slightly below the head);
#       then the movement is reversed.
# V5:   Y, not affected; operator is not waving the hand.
# V6:   Z, tip is going up in the first phase, then goes down.
#
#=
plot(collect(X_df_1_have_command[1,4:6]),
    labels=["x" "y" "z"], title="I have command - right hand tips")
=#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remarkable results:
# (min[X[Hand tip r]] ≤ 1) ∧ (min[Z[Hand tip r]] ≥ 0) => (min[Y[Hand tip r]] ≥ -0.5)
# gconfidence: 0.9230769230769231
############################################################################################

_1_right_hand_tip_X_items = [
    Atom(ScalarCondition(UnivariateMin(4), >=, 1))
    Atom(ScalarCondition(UnivariateMax(4), <=, 1))
    Atom(ScalarCondition(UnivariateMin(4), >=, 2))
    Atom(ScalarCondition(UnivariateMax(4), <=, 2))
]

_1_right_hand_tip_Y_items = [
    Atom(ScalarCondition(UnivariateMin(5), >=, -0.5))
    Atom(ScalarCondition(UnivariateMax(5), <=, -0.5))
]

_1_right_hand_tip_Z_items = [
    Atom(ScalarCondition(UnivariateMax(6), >=, -1))
    Atom(ScalarCondition(UnivariateMin(6), <=, -1))
    Atom(ScalarCondition(UnivariateMin(6), <=, 1))
    Atom(ScalarCondition(UnivariateMax(6), >=, 1))
]

_1_right_hand_tip_propositional_items = vcat(
    _1_right_hand_tip_X_items,
    _1_right_hand_tip_Y_items,
    _1_right_hand_tip_Z_items
) |> Vector{Item}

_1_right_hand_tip_propositional_items_short = [
    Atom(ScalarCondition(UnivariateMin(4), >=, 1))
    Atom(ScalarCondition(UnivariateMin(4), >=, 1.8))
    Atom(ScalarCondition(UnivariateMin(5), >=, -0.5))
    Atom(ScalarCondition(UnivariateMax(6), >=, 0))
] |> Vector{Item}

_1_items = _1_right_hand_tip_propositional_items_short
_1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_1_rulemeasures = [(gconfidence, 0.1, 0.1)]

runexperiment(
	X_1_have_command,
	fpgrowth,
	_1_items,
	_1_itemsetmeasures,
	_1_rulemeasures;
	reportname = "01-have-command-right-hand-tip-only.exp",
	variable_names = VARIABLE_NAMES,
)

############################################################################################
# Experiment #2
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips with later temporal relation.
# V4, V5, V6 - right hand tip; X, Y, Z coordinates.
#
#=
plot(collect(X_df_1_have_command[1,4:6]),
    labels=["x" "y" "z"], title="I have command - right hand tips")
=#
############################################################################################

_2_right_hand_tip_later_items = vcat(
    _1_right_hand_tip_propositional_items_short[1:4],
    diamond(IA_L).(_1_right_hand_tip_propositional_items_short)[1:4],
    box(IA_L).(_1_right_hand_tip_propositional_items_short)[1:4],
) |> Vector{Formula}

_2_items = _2_right_hand_tip_later_items
_2_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_2_rulemeasures = [(gconfidence, 0.1, 0.1)]

runexperiment(
	X_1_have_command,
	apriori,
	_2_items,
	_2_itemsetmeasures,
	_2_rulemeasures;
	reportname = "02-have-command-hand-tip-with-later-relation.exp",
	variable_names = VARIABLE_NAMES,
)

############################################################################################
# Experiment #3
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips with during temporal relation.
# V4, V5, V6 - right hand tip.
# V10, V11, V12 - right elbow.
#
#=
plot(collect(X_df_2_all_clear[1,4:6]),
    labels=["x" "y" "z"], title="All clear - right hand tips")

plot(collect(X_df_2_all_clear[1,10:12]),
    labels=["x" "y" "z"], title="All clear - right elbow")
=#
############################################################################################

_3_right_hand_tip_propositional_items_short = [
    Atom(ScalarCondition(UnivariateMin(4), >=, 1))
    Atom(ScalarCondition(UnivariateMin(5), >=, 0.5))
    Atom(ScalarCondition(UnivariateMin(6), >=, 1))
] |> Vector{Item}

_3_right_elbow_propositional_items_short = [
    Atom(ScalarCondition(UnivariateMin(10), >=, 0.6))
    Atom(ScalarCondition(UnivariateMin(11), >=, 0.5))
    Atom(ScalarCondition(UnivariateMin(12), >=, -0.5))
]

_3_right_hand_tip_during_items = vcat(
    _3_right_hand_tip_propositional_items_short,
    _3_right_elbow_propositional_items_short,
    box(IA_D).(_3_right_hand_tip_propositional_items_short),
    box(IA_D).(_3_right_elbow_propositional_items_short),
) |> Vector{Formula}

_3_items = _3_right_hand_tip_during_items
_3_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_3_rulemeasures = [(gconfidence, 0.1, 0.1)]

runexperiment(
	X_2_all_clear,
	apriori,
	_3_items,
	_3_itemsetmeasures,
	_3_rulemeasures;
	reportname = "03-all-clear-right-hand-and-elbow-during-relation.exp",
	variable_names = VARIABLE_NAMES,
)

############################################################################################
# Experiment #4
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Wrists in Spread wings, using during, overlap and meet relations.
# V13, V14, V15 - left wrist.
# V16, V17, V18 - right wrist.
#
#=
plot(collect(X_df_4_spread_wings[1,13:15]),
    labels=["x" "y" "z"], title="Spread wings - left wrist")

plot(collect(X_df_4_spread_wings[1,16:18]),
    labels=["x" "y" "z"], title="Spread wings - right wrist")
=#
############################################################################################

_4_left_wrist_propositional_items_short = [
    Atom(ScalarCondition(UnivariateMin(13), >=, -0.5))
    Atom(ScalarCondition(UnivariateMax(13), <=, -1.0))
    Atom(ScalarCondition(UnivariateMin(14), >=, -0.5))
    Atom(ScalarCondition(UnivariateMin(14), >=, -0.5))
    # no Z here
]

_4_right_wrist_propositional_items_short = [
    Atom(ScalarCondition(UnivariateMax(16), <=, 0.6))
    Atom(ScalarCondition(UnivariateMin(16), >=, 1))
    Atom(ScalarCondition(UnivariateMin(17), >=, 1))
    # no z here
] |> Vector{Item}


_4_wrist_lambdas = vcat(
    _4_left_wrist_propositional_items_short,
    _4_right_wrist_propositional_items_short,

    diamond(IA_D).(_4_left_wrist_propositional_items_short),
    box(IA_D).(_4_right_wrist_propositional_items_short),

    diamond(IA_E).(_4_left_wrist_propositional_items_short),
    box(IA_E).(_4_right_wrist_propositional_items_short),

    diamond(SoleLogics.IA_O).(_4_left_wrist_propositional_items_short),
    box(SoleLogics.IA_O).(_4_right_wrist_propositional_items_short),
) |> Vector{Formula}

_4_items = _4_wrist_lambdas
_4_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_4_rulemeasures = [(gconfidence, 0.1, 0.1)]

runexperiment(
	X_4_spread_wings,
	apriori,
	_4_items,
	_4_itemsetmeasures,
	_4_rulemeasures;
	reportname = "04-spread-wings-wrists-during-overlap-meet-relations.exp",
	variable_names = VARIABLE_NAMES,
)
