############################################################################################
# Preamble
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# In this file are organized the experiments for NATOPS dataset.
# NATOPS stands for Naval Air Training and Operating Procedures Standardization.
#
# Each class (e.g., "I Have Command") is associated with a movement, identified by
# X,Y and Z coordinates of hand tips, elbows, wrists and thumbs.
# To visualize some class labels, check out the following link:
# https://github.com/yalesong/natops/tree/master.
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
	"X[Hand tip l]", "Y[Hand tip l]", "Z[Hand tip l]",
	"X[Hand tip r]", "Y[Hand tip r]", "Z[Hand tip r]", "X[Elbow l]", "Y[Elbow l]", "Z[Elbow l]",
	"X[Elbow r]", "Y[Elbow r]", "Z[Elbow r]", "X[Wrist l]", "Y[Wrist l]", "Z[Wrist l]",
	"X[Wrist r]", "Y[Wrist r]", "Z[Wrist r]", "X[Thumb l]", "Y[Thumb l]", "Z[Thumb l]",
	"X[Thumb r]", "Y[Thumb r]", "Z[Thumb r]",
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
	variable_names::Union{Nothing, Vector{String}} = nothing,
)
	miner = Miner(X, algorithm, items, itemsetmeasures, rulemeasures)
	mine!(miner)
	generaterules!(miner) |> collect

	if isnothing(reportname)
		reportname = now() |> string
	end
	reportname = RESULTS_PATH * reportname

	open(reportname, "w") do out
		redirect_stdout(out) do
			for r in sort(arules(miner), by = x -> miner.gmemo[(:gconfidence, x)], rev = true)
				ModalAssociationRules.analyze(r, miner; variable_names = variable_names)
			end
		end
	end

	# report = open(reportname, "w")
	#
	# for rule in sort(
	#     arules(miner), by=x -> miner.gmemo[(:gconfidence, x)], rev=true)
	#     write(report, analyze(rule, miner))
	# end

	# close(report)
end

############################################################################################
# Data Observation
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each experiment is prepended with a comment explaining the literals chosen.
############################################################################################

#= general plot with all 24 variables for one instance of each new class
plot(
	map(i->plot(collect(X_df[i,:]), labels=nothing,title=y[i]), 1:30:180)...,
	layout = (2, 3),
	size = (1500,400)
)
=#

#= plot for V1, V2, V3 - left hand tip X, Y, Z coordinates
plot(
	map(i->plot(collect(X_df[i,1:3]), labels=nothing,title=y[i]), 1:30:180)...,
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
plot(collect(X_df_1_have_command[1,4:6]), labels=nothing, title=y[1])
=#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remarkable results:
# (min[X[Hand tip r]] ≤ 1) ∧ (min[Z[Hand tip r]] ≥ 0) => (min[Y[Hand tip r]] ≥ -0.5)
# gconfidence: 0.9230769230769231
############################################################################################

_1_right_hand_tip_X_t1 = Atom(ScalarCondition(UnivariateMin(4), >=, 1))
_1_right_hand_tip_X_t2 = Atom(ScalarCondition(UnivariateMin(4), >=, 1.5))
_1_right_hand_tip_X_t3 = Atom(ScalarCondition(UnivariateMin(4), >=, 2))
_1_right_hand_tip_X_t4 = Atom(ScalarCondition(UnivariateMin(4), <=, 1))

_1_right_hand_tip_Y_t1 = Atom(ScalarCondition(UnivariateMin(5), >=, -0.5))

_1_right_hand_tip_Z_t1 = Atom(ScalarCondition(UnivariateMin(6), <=, -1))
_1_right_hand_tip_Z_t2 = Atom(ScalarCondition(UnivariateMin(6), >=, 0))
_1_right_hand_tip_Z_t3 = Atom(ScalarCondition(UnivariateMin(6), >=, 1))

_1_items = Vector{Item}([
	_1_right_hand_tip_X_t1,
	_1_right_hand_tip_X_t2,
	_1_right_hand_tip_X_t3,
	_1_right_hand_tip_X_t4,
	_1_right_hand_tip_Y_t1,
	_1_right_hand_tip_Z_t1,
	_1_right_hand_tip_Z_t2,
	_1_right_hand_tip_Z_t3,
])
_1_itemsetmeasures = [(gsupport, 0.3, 0.3)]
_1_rulemeasures = [(gconfidence, 0.6, 0.6)]

runexperiment(
	X_1_have_command,
	fpgrowth,
	_1_items,
	_1_itemsetmeasures,
	_1_rulemeasures;
	reportname = "01-right-hand-tip-only.exp",
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
plot(
	map(i->plot(collect(X_df_1_have_command[:,4:6]), labels=nothing,title=y[i]), 1:30)...,
	layout = (2, 3),
	size = (1500,400)
)
=#
############################################################################################
