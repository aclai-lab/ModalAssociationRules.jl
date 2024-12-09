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
using Discretizers
using Plots
using PrettyTables
using SoleData
using StatsBase
using SoleLogics

using SoleLogics: IA_B, IA_Bi, IA_E, IA_Ei, IA_D, IA_Di, IA_O
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
    "ΔY[Hand tip r and thumb r]"                       # 25
]

LEFT_BODY_VARIABLES = [1,2,3,7,8,9,13,14,15,19,20,21,25]
RIGHT_BODY_VARIABLES = [4,5,6,10,11,12,16,17,18,22,23,24,25]

CLASS_NAMES = [
	"I have command",
	"All clear",
	"Not clear",
	"Spread wings",
	"Fold wings",
	"Lock wings",
]

############################################################################################
# Setup & Driver
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NATOPS dataset is loaded, and it's entirely transformed in a Logiset (see `X`).
# Then, for each class, a DataFrame window is sliced, and a now Logiset is built.
############################################################################################

X_df, y = load_NATOPS();
insertcols!(X_df, 25, "ΔY[Thumb r and Hand tip r]" => X_df[:,5]-X_df[:,23])
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

LOGISETS = [
    X_1_have_command,
    X_2_all_clear,
    X_3_not_clear,
    X_4_spread_wings,
    X_5_fold_wings,
    X_6_lock_wings
]

# Each experiment is identified by an ID;
# put here the ids of the experiments you want to run.
EXPERIMENTS_IDS = [12]
println("You are running the following NATOPS experiments: $(EXPERIMENTS_IDS)")

"""
    function runexperiment(
        miner::Miner;
        returnminer::Bool = false,
        tracktime::Bool = true,
        reportname::String = "experiment-report.exp",
        variablenames::Union{Nothing, Vector{String}} = nothing
    )
    function runexperiment(
        X::MineableData,
        algorithm::Function,
        items::Vector{Item},
        itemsetmeasures::Vector{<:MeaningfulnessMeasure},
        rulemeasures::Vector{<:MeaningfulnessMeasure};
        kwargs...
    )

Mine frequent [`Itemset`](@ref)s and [`ARule`](@ref) from dataset `X` using `algorithm`.
Return the [`Miner`](@ref) used to perform mining.

See also [`ARule`](@ref), [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Miner`](@ref).
"""
function runexperiment(
	X::MineableData,
	algorithm::Function,
	items::Vector{Item},
	itemsetmeasures::Vector{<:MeaningfulnessMeasure},
	rulemeasures::Vector{<:MeaningfulnessMeasure};
    kwargs...
)
    runexperiment(
        Miner(deepcopy(X), algorithm, items, itemsetmeasures, rulemeasures);
        kwargs...
    )
end

function runexperiment(
    miner::Miner;
    returnminer::Bool = false,
    tracktime::Bool = true,
	reportname::String = "experiment-report.exp",
	variablenames::Union{Nothing, Vector{String}} = nothing
)
	miningtime = @elapsed mine!(miner)
	generationtime = @elapsed collect(generaterules!(miner))

	if isnothing(reportname)
		reportname = now() |> string
	end
	reportname = RESULTS_PATH * reportname

	open(reportname, "w") do out
		redirect_stdout(out) do
            # For some reason, `itemsetmeasures` and `rulemeasures` getters triggers
            # a MethodError here (maybe this is caused by stdout redirection?).
            println("Alphabet:\n")
            map(item -> println(
                syntaxstring(item, variable_names_map=VARIABLE_NAMES)) , items(miner))

            println("\n\nThresholds:")
            println(miner.itemset_constrained_measures)
            println(miner.arule_constrained_measures)

            if tracktime
                println("\nRunning time [s]:\n")
                println("Frequent itemsets extraction: $(miningtime)")
                println("Association rules generation: $(generationtime)")
                println("Total elapsed time: $(miningtime + generationtime)")
            end

            println("\nResults:\n")
			for r in sort(
                arules(miner), by = x -> miner.globalmemo[(:gconfidence, x)], rev=true)
				ModalAssociationRules.arule_analysis(
                    r, miner; variablenames=variablenames, itemset_global_info=true)
			end
		end
	end

    # free RAM if returnminer is unset
    return (returnminer) ? miner : nothing
end

"""
    function runcomparison(
        miner::Miner,
        logisets::Vector{L},
        rulebouncer::Function;
        targetclass::Int8 = 1 |> Int8,
        suppthreshold::Float64,
        sortby::Symbol=:confmean,
        reportname::String = "comparison-report.exp",
        classnames::Vector{String} =  [
            "I have command", "All clear", "Not clear",
            "Spread wings", "Fold wings", "Lock wings",
        ]
    ) where {L<:SoleData.AbstractLogiset}

# Arguments

- `miner`: the (already used) miner from which association rules are taken;
- `logisets`: vector of logisets, one for each class;
- `rulebouncer`: function taking a float value (between 0 and 1), that represents
    a confidence level: this can be tweaked to limit the size of this comparison;
- `targetclass`: the class on which miner was originally used;
- `suppthreshold`: local support threshold used by global support calls invoked inside
    this function, when measuring the meaningfulness measures of an association rule on
    the other classes (those who are not `targetclass`),
- `sortby`: either `:confmean` or `:entropy`, establishes how rows are sorted:
    in the former case, they are sorted w.r.t. lower mean confidence on classes which are
    not `targetclass`, while in the latter they are sorted in ascending order
    w.r.t `1-entropy(confidences)`;
- `reportname`: name of the file where output is stored;
- `classnames`: labels to associated with each class.

Given a consumed [`Miner`](@ref), that is, a miner which already performed mining,
print in a file (placed in `results/reportname`) a report regarding the mined
[`ARule`](@ref) whose global confidence is in a range established by `confidencebouncer`.

# Examples

```julia-repl
julia> runcomparison(
    _1_miner,
    LOGISETS,
    (conf) -> conf >= 0.3,
    0.1;
    reportname="01-comparison.exp",
    classnames=
)

# in results/01-comparison.exp
┌──────────────────────────────────────────────────────────────┬──────────────────────────┐
│                              Rule │           I have command │                All clear │
├──────────────────────────────────────────────────────────────┼──────────────────────────┤
│ (min[V5] ≥ -0.5) => (max[V6] ≥ 0) │         confidence: 0.86 │         confidence: 0.57 │
│                                   │ antecedent support: 0.97 │ antecedent support: 0.47 │
│                                   │ consequent support: 0.87 │ consequent support: 0.63 │
│                                   │      union support: 0.83 │      union support: 0.27 │
├───────────────────────────────────┼──────────────────────────┼──────────────────────────┤
│ (min[V4] ≥ 1) => (min[V5] ≥ -0.5) │         confidence: 0.36 │         confidence: 0.43 │
│                                   │ antecedent support: 0.47 │  antecedent support: 1.0 │
│                                   │ consequent support: 0.97 │ consequent support: 0.47 │
│                                   │      union support: 0.17 │      union support: 0.43 │
└───────────────────────────────────┴──────────────────────────┴──────────────────────────┘
```

See also [`ARule`](@ref), [`gconfidence`](@ref), [`Miner`](@ref).
"""
function runcomparison(
    miner::Miner,
    logisets::Vector{L},
    rulebouncer::Function;
    targetclass::Int8 = 1 |> Int8,
    suppthreshold::Float64,
    sortby::Symbol = :confmean,
    sigdigits::Int8 = 2 |> Int8,
    reportname::String = "comparison-report.exp",
    tracktime::Bool = true,
    classnames::Vector{String} = CLASS_NAMES,
    variablenames::Union{Nothing, Vector{String}} = VARIABLE_NAMES
) where {L<:SoleData.AbstractLogiset}
    if length(logisets) != length(classnames)
        throw(ArgumentError(
            "Given number of logisets and " *
            "variable names mismatch: length(logisets) = $(length(logisets)), while " *
            "length(classnames) = $(length(classnames))."
        ))
    end

    miners = [
        Miner( # random Miner, its only purpose is to leverage memoization
            LOGISETS[i],
            fpgrowth,
            Item[],
            [(gsupport, 0.0, 0.0)],
            [(gconfidence, 0.0, 0.0)]
        )
        for i in 1:length(classnames)
    ]
    miners[targetclass] = miner

    targetminer = miners[targetclass]
    if !info(targetminer, :istrained)
        throw(ArgumentError("Provided miner did not perform mine and is thus  empty."))
    end

    # report filepath preparation
    reportname = RESULTS_PATH * reportname

    MEAN_GCONF_EXCLUDING_TARGETCLASS_STRING = "◐"
    ONE_MINUS_ENTROPY_STRING = "1 - 𝑆"

    # pretty table header row
    header = vcat("Rule",
        MEAN_GCONF_EXCLUDING_TARGETCLASS_STRING,
        ONE_MINUS_ENTROPY_STRING,
        classnames
    )

    # partial data (numeric) that has to be be manipulated,
    # before being converted to string format.
    # Each element in this collection is of type
    # Tuple{ARule, Float64, Vector{Tuple{Integer, Vector{Float64}}}}
    # (A::ARule, B::Float64, C::Tuple{Integer, Vector{Flaot64}})
    # where A is association rule,
    # B is the confidence measured considering all classes apart from `targetclass`,
    # and C is a vector of associations between i-th class and meaningfulness measures.
    # Meaningfulness measures are sorted like so:
    # global confidence,
    # antecedent global support,
    # consequent global support,
    # antecedent and consequent global support.
    datavals = Tuple{ARule, Float64, Float64, Vector{Tuple{Integer, Vector{Float64}}}}[]

    # final collection taht will be passed to PrettyTables.jl
    data = Any[]

    elapsedtime = "Not tracked"
    if tracktime
        elapsedtime = time()
    end

    # for each rule accepted by `rulebouncer`
    for rule in filter(
                _rule -> rulebouncer(globalmemo(targetminer, (:gconfidence, _rule))),
                arules(targetminer)
            )

        # prepare a data value fragment, that is,
        # a vector of tuples (logiset-index, [measures])
        dataval = Tuple{Integer, Vector{Float64}}[]

        # consider each class, compute the meaningfulness measures and print them
        for (i, logiset) in Iterators.enumerate(logisets)
            _antecedent, _consequent = antecedent(rule), consequent(rule)
            _union = union(_antecedent, _consequent)

            # confidence
            _conf = round(
                gconfidence(rule, logiset, suppthreshold, miners[i]),
                sigdigits=sigdigits
            )
            # antecedent global support
            _asupp = round(
                gsupport(_antecedent, logiset, suppthreshold, miners[i]),
                sigdigits=sigdigits
            )
            # consequent global support
            _csupp = round(
                gsupport(_consequent, logiset, suppthreshold, miners[i]),
                sigdigits=sigdigits
            )
            # whole-rule global support
            _usupp = round(
                gsupport(_union, logiset, suppthreshold, miners[i]),
                sigdigits=sigdigits
            )

            push!(dataval, (i, [_conf, _asupp, _csupp, _usupp]))
        end

        # compute the mean of global confidences, excluding the `targetclass`
        # from which association rules where initially mined.
        mean_gconf_excluding_targetclass = begin
            _accumulator = 0.0
            for (i, measures) in dataval
                if i != targetclass
                    _accumulator += measures[1]
                end
            end
            round(_accumulator / (length(logisets)-1), sigdigits=sigdigits)
        end

        one_minus_entropy = begin
            # ith-confidence divided by `confidences_sum`
            # gives us the probability that must be used in entropy formula.
            confidences_sum = 0.0
            for (i, measures) in dataval
                confidences_sum += measures[1]
            end

            # compute entropy
            nofclasses = length(CLASS_NAMES)
            probabilities = fill(0.0, nofclasses)
            for (i, measures) in dataval
                probabilities[i] = measures[1] / confidences_sum
            end

            round(1 - entropy(probabilities, nofclasses), sigdigits=sigdigits)
        end

        # later, after all the insertions, we will sort `datavals` in ascending order
        # by the mean of global confidences;
        # when the mean is low, this means that the associated rule is good to uniquely
        # identify the class `targetclass`.
        push!(datavals, (
                rule,
                mean_gconf_excluding_targetclass,
                one_minus_entropy,
                dataval
            )
        )
    end

    # `datavals` is ready to be sorted
    if sortby == :confmean
        sort!(datavals, by=t -> t[2])   # sort by ◐
    elseif sortby == :entropy
        sort!(datavals, by=t -> t[3])   # sort by entropy
    end

    # digest `datavals`, converting useful information into strings and shaping them
    # in order to make a table using PrettyTables.jl
    for val in datavals
        # consider a certain row
        # val[1] is the rule associated with the row
        # val[2] is ◐ parameter
        # val[3] is a vector of pairs; in particular:
        #   val[3] |> first is an integer i, indicating that measures refers to ith-logiset
        #   val[3] |> last is a vector of length 4, containing all the measures
        _antecedent = val[1] |> antecedent |> formula
        _consequent = val[1] |> consequent |> formula
        row_cellstrings = String[
            # rule
            "$(syntaxstring(_antecedent, variable_names_map=variablenames))" *
            " => $(syntaxstring(_consequent, variable_names_map=variablenames))",
            # mean gconf without considering `targetclass`
            val[2] |> string,
            # 1 - entropy
            val[3] |> string
        ]

        # insert measures
        for (_, measures) in val[4]
            push!(row_cellstrings, "confidence: $(measures[1])\n"*
                "antecedent support: $(measures[2])\n" *
                "consequent support: $(measures[3])\n"*
                "union support: $(measures[4])")
        end

        data = isempty(data) ? row_cellstrings : hcat(data, row_cellstrings)
    end

    # print data table on file
    open(reportname, "w") do out
        redirect_stdout(out) do
            println("Metadata")
            println("Selected target class id: $(targetclass)")
            println("Selected target class name: $(classnames[targetclass])")
            println("Elapsed time to perform comparisons: $(time() - elapsedtime)")

            println("\nLegend")
            println("$(MEAN_GCONF_EXCLUDING_TARGETCLASS_STRING): " *
                "mean of global confidences, excluding current target class")
            println("$(ONE_MINUS_ENTROPY_STRING): confidences purity measures " *
                "(higher means that target class is more pure)")

            println("Parameterization:\n")
            map(item -> println(
                syntaxstring(item, variable_names_map=VARIABLE_NAMES)) , items(miner))
            println(miner.itemset_constrained_measures)
            println(miner.arule_constrained_measures)

            pretty_table(
                data |> permutedims;
                header=header,
                linebreaks=true,
                # the number of horizontal separators is equal to rows after `permutedims`
                body_hlines=collect(1:(data |> size |> last))
            )
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
#
# To further examine data, see the `Useful Plots` section at the end of the file.
############################################################################################

############################################################################################
# Experiment #1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips without temporal relations.
#
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

if 1 in EXPERIMENTS_IDS
    _1_right_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(4), >=, 1))
        Atom(ScalarCondition(VariableMax(4), <=, 1))
        Atom(ScalarCondition(VariableMin(4), >=, 1.8))
        Atom(ScalarCondition(VariableMax(4), <=, 1.8))
    ]

    _1_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, -0.5))
        Atom(ScalarCondition(VariableMax(5), <=, -0.5))
    ]

    _1_right_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMax(6), >=, 0))
        Atom(ScalarCondition(VariableMin(6), <=, 0))
        Atom(ScalarCondition(VariableMin(6), <=, 1))
        Atom(ScalarCondition(VariableMax(6), >=, 1))
    ]

    _1_right_hand_tip_propositional_items = vcat(
        _1_right_hand_tip_X_items,
        _1_right_hand_tip_Y_items,
        _1_right_hand_tip_Z_items
    ) |> Vector{Item}

    _1_right_hand_tip_propositional_items_short = [
        Atom(ScalarCondition(VariableMin(4), >=, 1))
        Atom(ScalarCondition(VariableMin(4), >=, 1.8))
        Atom(ScalarCondition(VariableMin(5), >=, -0.5))
        Atom(ScalarCondition(VariableMax(6), >=, 0))
    ] |> Vector{Item}

    _1_items = _1_right_hand_tip_propositional_items_short
    _1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
    _1_rulemeasures = [(gconfidence, 0.1, 0.1)]

    _1_miner = runexperiment(
        X_1_have_command,
        fpgrowth,
        _1_items,
        _1_itemsetmeasures,
        _1_rulemeasures;
        reportname = "e01-tc-1-have-command-rhand.exp",
        variablenames = VARIABLE_NAMES,
    )
end

############################################################################################
# Experiment #2
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips with later temporal relation in "I have command" class.
# V4, V5, V6 - right hand tip; X, Y, Z coordinates.
#
#=
plot(collect(X_df_1_have_command[1,4:6]),
    labels=["x" "y" "z"], title="I have command - right hand tips")
=#
############################################################################################

if 2 in EXPERIMENTS_IDS
    _2_right_hand_tip_later_items = vcat(
        _1_right_hand_tip_propositional_items_short[1:4],
        diamond(IA_L).(_1_right_hand_tip_propositional_items_short)[1:4],
        box(IA_L).(_1_right_hand_tip_propositional_items_short)[1:4],
    ) |> Vector{Formula}

    _2_items = _2_right_hand_tip_later_items
    _2_itemsetmeasures = [(gsupport, 0.1, 0.1)]
    _2_rulemeasures = [(gconfidence, 0.1, 0.1)]

    _2_miner = runexperiment(
        X_1_have_command,
        apriori,
        _2_items,
        _2_itemsetmeasures,
        _2_rulemeasures;
        reportname = "e02-tc-1-have-command-hand-tip-L.exp",
        variablenames = VARIABLE_NAMES,
    )
end

############################################################################################
# Experiment #3
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips with during temporal relation.
#
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

if 3 in EXPERIMENTS_IDS
    _3_right_hand_tip_propositional_items_short = [
        Atom(ScalarCondition(VariableMin(4), >=, 1))
        Atom(ScalarCondition(VariableMin(5), >=, 0.5))
        Atom(ScalarCondition(VariableMin(6), >=, 1))
    ] |> Vector{Item}

    _3_right_elbow_propositional_items_short = [
        Atom(ScalarCondition(VariableMin(10), >=, 0.6))
        Atom(ScalarCondition(VariableMin(11), >=, 0.5))
        Atom(ScalarCondition(VariableMin(12), >=, -0.5))
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

    _3_miner = runexperiment(
        X_2_all_clear,
        apriori,
        _3_items,
        _3_itemsetmeasures,
        _3_rulemeasures;
        reportname = "e03-tc-2-all-clear-rhand-elbow-D-relation.exp",
        variablenames = VARIABLE_NAMES,
    )
end

############################################################################################
# Experiment #4
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Wrists in "Spread wings" class, using during, ends-with and overlap relations.
#
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

if 4 in EXPERIMENTS_IDS
    _4_left_wrist_propositional_items_short = [
        Atom(ScalarCondition(VariableMin(13), >=, -0.5))
        Atom(ScalarCondition(VariableMax(13), <=, -1.0))
        Atom(ScalarCondition(VariableMin(14), >=, -0.5))
        Atom(ScalarCondition(VariableMin(14), >=, -0.5))
        # no Z here
    ]

    _4_right_wrist_propositional_items_short = [
        Atom(ScalarCondition(VariableMax(16), <=, 0.6))
        Atom(ScalarCondition(VariableMin(16), >=, 1))
        Atom(ScalarCondition(VariableMin(17), >=, 1))
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

    _4_miner = runexperiment(
        X_4_spread_wings,
        apriori,
        _4_items,
        _4_itemsetmeasures,
        _4_rulemeasures;
        reportname = "e04-tc-4-spread-wings-wrists-DEO-relations.exp",
        variablenames = VARIABLE_NAMES,
    )
end

############################################################################################
# Experiment #5
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips with B, E, D, O relations (and inverses) in I have command.
#
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
############################################################################################

if 5 in EXPERIMENTS_IDS
    _5_right_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(4), >=, 1))
        # Atom(ScalarCondition(VariableMax(4), <=, 1))
        Atom(ScalarCondition(VariableMin(4), >=, 1.8))
        # Atom(ScalarCondition(VariableMax(4), <=, 1.8))
    ]

    _5_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, 0))
        # Atom(ScalarCondition(VariableMax(5), <=, 0))
        Atom(ScalarCondition(VariableMin(5), >=, 1))
        # Atom(ScalarCondition(VariableMax(5), <=, 1))
    ]

    _5_right_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMin(6), >=, -0.5))
        # Atom(ScalarCondition(VariableMax(6), <=, -0.5))
    ]

    _5_propositional_items = vcat(
        _5_right_hand_tip_X_items,
        _5_right_hand_tip_Y_items,
        _5_right_hand_tip_Z_items
    )

    _5_items = vcat(
        _5_propositional_items,
        box(IA_B).(_5_propositional_items),
        # diamond(IA_Bi).(_5_propositional_items),

        diamond(IA_E).(_5_propositional_items),
        # diamond(IA_Ei).(_5_propositional_items),

        box(IA_D).(_5_propositional_items),
        # diamond(IA_Di).(_5_propositional_items),

        diamond(IA_O).(_5_propositional_items),
    ) |> Vector{Formula}

    _5_itemsetmeasures = [(gsupport, 0.1, 0.1)]
    _5_rulemeasures = [(gconfidence, 0.3, 0.3)]

    _5_miner = runexperiment(
        X_1_have_command,
        fpgrowth,
        _5_items,
        _5_itemsetmeasures,
        _5_rulemeasures;
        returnminer = true,
        reportname = "e05-tc-1-have-command-rhand-BEDO.exp",
        variablenames = VARIABLE_NAMES,
    )

    runcomparison(
        _5_miner,
        LOGISETS,
        (conf) -> conf >= 0.6;
        sigdigits=3 |> Int8,
        targetclass=1 |> Int8,
        suppthreshold=0.1,
        reportname="e05-tc-1-have-command-rhand-BEDO-comparison.exp"
    )
end

############################################################################################
# Experiment #6
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This experiment is a lighter version of Experiment #5.
# Right hand tips with B, D relations (and inverses).
#
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
############################################################################################

if 6 in EXPERIMENTS_IDS
    _6_right_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(4), >=, 1))
        # Atom(ScalarCondition(VariableMax(4), <=, 1))
        Atom(ScalarCondition(VariableMin(4), >=, 1.8))
        # Atom(ScalarCondition(VariableMax(4), <=, 1.8))
    ]

    _6_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, 0))
        # Atom(ScalarCondition(VariableMax(5), <=, 0))
        Atom(ScalarCondition(VariableMin(5), >=, 1))
        # Atom(ScalarCondition(VariableMax(5), <=, 1))
    ]

    _6_right_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMin(6), >=, -0.5))
        # Atom(ScalarCondition(VariableMax(6), <=, -0.5))
    ]

    _6_propositional_items = vcat(
        _6_right_hand_tip_X_items,
        _6_right_hand_tip_Y_items,
        _6_right_hand_tip_Z_items
    )

    _6_items = vcat(
        _6_propositional_items,
        box(IA_B).(_6_propositional_items),
        box(IA_D).(_6_propositional_items),
    ) |> Vector{Formula}

    _6_itemsetmeasures = [(gsupport, 0.4, 0.2)]
    _6_rulemeasures = [(gconfidence, 0.4, 0.4)]

    _6_miner = runexperiment(
        X_1_have_command,
        fpgrowth,
        _6_items,
        _6_itemsetmeasures,
        _6_rulemeasures;
        returnminer = true,
        reportname = "e06-tc-1-have-command-rhand-BD.exp",
        variablenames = VARIABLE_NAMES,
    )

    runcomparison(
        _6_miner,
        LOGISETS,
        (conf) -> conf >= 0.6;
        sigdigits=3 |> Int8,
        targetclass=1 |> Int8,
        suppthreshold=0.1,
        reportname="e06-tc-1-have-command-rhand-BD-comparison.exp"
    )
end

############################################################################################
# Experiment #7
# Requrements: in experiments #1 and #4, in `runexperiment`, set `returnminer = true`.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Given a list of interesting rules extracted by the previous experiments, do the following:
# for each rule R extracted from class k, compute the meaningfulness measures of R w.r.t
# each i-th class, where i != k.
#
# The goal is to generate a matrix shaped as follows:
#
#    "I have command" "All clear" "Not clear" "Spread wings" "Fold wings" "Lock wings"
# R1:
# R2:                    meaningfulness measures at intersections
# ...
# RK:
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Two more columns are added, which can be used to establish how rows in the matrix must
# be sorted:
#   ◐       : mean of global confidences, excluding current target class
#   1 - 𝑆   : confidence purity measures; higher means that target class is more pure
# See also `runcomparison` documentation.
############################################################################################

if 7 in EXPERIMENTS_IDS
    if !isnothing(_1_miner) && !isnothing(_4_miner)
        runcomparison(
            _1_miner,
            LOGISETS,
            (conf) -> conf >= 0.3;
            sigdigits=3 |> Int8,
            targetclass=1,
            suppthreshold=0.1,
            reportname="e07-from-exp01-comparison.exp"
        )

        runcomparison(
            _4_miner,
            LOGISETS,
            (conf) -> conf >= 0.89 && conf <= 0.92;
            suppthreshold=0.1,
            sigdigits=2 |> Int8,
            reportname="e07-from-exp04-comparison.exp"
        )
    else
        @warn "Requirements not satisfied for Experiment #7: Undefined miners.\n" *
            "Experiments will proceed skipping this."
    end
end


############################################################################################
# Experiment #8
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# left and right hand tips and elbows with O relation in "Lock wings" class.
#
#=
plot(collect(X_df_6_lock_wings[1,1:3]),
    labels=["x" "y" "z"], title="Lock wings - left hand tips") # left hand tips plot
plot(collect(X_df_6_lock_wings[6,4:6]),
    labels=["x" "y" "z"], title="Lock wings - right hand tips") # right hand tips plot
plot(collect(X_df_6_lock_wings[6,7:9]),
    labels=["x" "y" "z"], title="Lock wings - left elbow") # left elbow plot
plot(collect(X_df_6_lock_wings[6,10:12]),
    labels=["x" "y" "z"], title="Lock wings - right elbow") # right elbow plot


plot(collect(X_df_6_lock_wings[6,1:12]),
    labels=["x" "y" "z"], title="Lock wings - right elbow") # all variables
=#
############################################################################################

if 8 in EXPERIMENTS_IDS
    _8_left_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(1), >=, 0))
    ]
    _8_right_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(4), >=, 0.55))
        Atom(ScalarCondition(VariableMax(4), <=, 0.55))
    ]

    _8_left_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(2), >=, -1.0))
    ]
    _8_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, 0.2))
        Atom(ScalarCondition(VariableMin(5), >=, 0.5))
    ]

    _8_left_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMax(3), <=, -1))
    ]
    _8_right_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMin(6), >=, -0.5))
    ]

    _8_left_elbow_X_items = [
        Atom(ScalarCondition(VariableMax(7), <=, -0.75))
    ]
    _8_right_elbow_X_items = [
        Atom(ScalarCondition(VariableMin(10), >=, 0.7))
        Atom(ScalarCondition(VariableMax(10), <=, 0.7))
    ]

    _8_left_elbow_Y_items = [
        Atom(ScalarCondition(VariableMin(8), >=, -0.6))
    ]
    _8_right_elbow_Y_items = [
        Atom(ScalarCondition(VariableMin(11), >=, -0.5))
    ]

    _8_left_elbow_Z_items = [
        Atom(ScalarCondition(VariableMax(9), <=, -0.25))
    ]
    _8_right_elbow_Z_items = [
        Atom(ScalarCondition(VariableMax(12), >=, -0.3))
    ]

    _8_propositional_items = vcat(
        # hands
        # _8_left_hand_tip_X_items,
        # _8_right_hand_tip_X_items,

        _8_left_hand_tip_Y_items,
        _8_right_hand_tip_Y_items,

        _8_left_hand_tip_Z_items,
        # _8_right_hand_tip_Z_items,

        # elbows
        # _8_left_elbow_X_items,
        _8_right_elbow_X_items,

        # _8_left_elbow_Y_items,
        _8_right_elbow_Y_items,

        _8_left_elbow_Z_items,
        _8_right_elbow_Z_items
    )

    _8_items = vcat(
        _8_propositional_items,
        # diamond(IA_B).(_8_propositional_items),
        diamond(IA_O).(_8_propositional_items),
    ) |> Vector{Formula}

    _8_itemsetmeasures = [(gsupport, 0.2, 0.2)]
    _8_rulemeasures = [(gconfidence, 0.1, 0.1)]

    _8_miner = runexperiment(
        X_6_lock_wings,
        fpgrowth,
        _8_items,
        _8_itemsetmeasures,
        _8_rulemeasures;
        returnminer = true,
        reportname = "e08-tc-6-lock-wings-hands-elbows-BD.exp",
        variablenames = VARIABLE_NAMES,
    )

    runcomparison(
        _8_miner,
        LOGISETS,
        (conf) -> conf >= 0.6;
        sigdigits=3 |> Int8,
        targetclass=6 |> Int8,
        suppthreshold=0.1,
        reportname="e08-tc-6-lock-wings-hands-elbows-BD-comparison.exp"
    )
end


############################################################################################
# Experiment #9
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Lighter version of Experiment #8, using only during relation.
############################################################################################

if 9 in EXPERIMENTS_IDS
    _9_left_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(1), >=, 0))
    ]
    _9_right_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(4), >=, 0.55))
    ]

    _9_left_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(2), >=, -1.0))
    ]
    _9_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, -0.5))
    ]

    _9_left_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMax(3), <=, -1))
    ]
    _9_right_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMin(6), >=, -0.5))
    ]

    _9_left_elbow_X_items = [
        Atom(ScalarCondition(VariableMax(7), <=, -0.75))
    ]
    _9_right_elbow_X_items = [
        Atom(ScalarCondition(VariableMin(10), >=, 0.7))
    ]

    _9_left_elbow_Y_items = [
        Atom(ScalarCondition(VariableMin(8), >=, -0.6))
    ]
    _9_right_elbow_Y_items = [
        Atom(ScalarCondition(VariableMin(11), >=, -0.5))
    ]

    _9_left_elbow_Z_items = [
        Atom(ScalarCondition(VariableMax(9), <=, -0.25))
    ]
    _9_right_elbow_Z_items = [
        Atom(ScalarCondition(VariableMax(12), >=, -0.3))
    ]

    _9_propositional_items = vcat(
        # hands
        _9_left_hand_tip_X_items,
        _9_right_hand_tip_X_items,

        _9_left_hand_tip_Y_items,
        _9_right_hand_tip_Y_items,

        _9_left_hand_tip_Z_items,
        _9_right_hand_tip_Z_items,

        # elbows
        _9_left_elbow_X_items,
        _9_right_elbow_X_items,

        _9_left_elbow_Y_items,
        _9_right_elbow_Y_items,

        _9_left_elbow_Z_items,
        _9_right_elbow_Z_items
    )

    _9_items = vcat(
        _9_propositional_items,
        box(IA_D).(_9_propositional_items),
    ) |> Vector{Formula}

    _9_itemsetmeasures = [(gsupport, 0.2, 0.1)]
    _9_rulemeasures = [(gconfidence, 0.2, 0.1)]

    _9_miner = runexperiment(
        X_6_lock_wings,
        fpgrowth,
        _9_items,
        _9_itemsetmeasures,
        _9_rulemeasures;
        returnminer = true,
        reportname = "e09-tc-6-lock-wings-hands-elbows-D.exp",
        variablenames = VARIABLE_NAMES,
    )

    runcomparison(
        _9_miner,
        LOGISETS,
        (conf) -> conf >= 0.6;
        sigdigits=3 |> Int8,
        targetclass=6 |> Int8,
        suppthreshold=0.1,
        reportname="e09-tc-6-lock-wings-hands-elbows-D-comparison.exp"
    )
end


############################################################################################
# Experiment #10
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right hand tips and elbow with B, E, D, O relations (and inverses) in All clear.
#
#=
plot(collect(X_df_2_all_clear[30,4:6]),
    labels=["x" "y" "z"], title="All clear - right hand tips")

plot(collect(X_df_2_all_clear[30,22:24]),
    labels=["x" "y" "z"], title="All clear - right hand thumb")
=#
############################################################################################

if 10 in EXPERIMENTS_IDS
    _10_right_hand_tip_X_items = [
        Atom(ScalarCondition(VariableMin(4), >=, 1.1))
    ]

    _10_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, -1))
    ]

    _10_right_hand_tip_Z_items = [
        Atom(ScalarCondition(VariableMin(6), >=, 0.1))
    ]

    _10_right_elbow_X_items = [
        Atom(ScalarCondition(VariableMin(16), >=, 1.1))
    ]

    _10_right_elbow_Y_items = [
        Atom(ScalarCondition(VariableMin(17), >=, -1))
    ]

    _10_right_elbow_Z_items = [
        Atom(ScalarCondition(VariableMin(18), >=, 0.1))
    ]

    _10_propositional_items = vcat(
        _10_right_hand_tip_X_items,
        _10_right_hand_tip_Y_items,
        _10_right_hand_tip_Z_items,
        _10_right_elbow_X_items,
        _10_right_elbow_Y_items,
        _10_right_elbow_Z_items
    )

    _10_items = Item.(
        vcat(
            _10_propositional_items,
            box(IA_B).(_10_propositional_items),
            # diamond(IA_Bi).(_10_propositional_items),

            diamond(IA_E).(_10_propositional_items),
            # diamond(IA_Ei).(_10_propositional_items),

            box(IA_D).(_10_propositional_items),
            # diamond(IA_Di).(_10_propositional_items),

            diamond(IA_O).(_10_propositional_items),
        )
    )

    _10_itemsetmeasures = [(gsupport, 0.2, 0.2)]
    _10_rulemeasures = [(gconfidence, 0.2, 0.2)]

    _10_miner = runexperiment(
        X_1_have_command,
        fpgrowth,
        _10_items,
        _10_itemsetmeasures,
        _10_rulemeasures;
        returnminer = true,
        reportname = "e10-tc-2-all-clear-rhand-BEDO.exp",
        variablenames = VARIABLE_NAMES,
    )

    runcomparison(
        _10_miner,
        LOGISETS,
        (conf) -> conf >= 0.6;
        sigdigits=3 |> Int8,
        targetclass=1 |> Int8,
        suppthreshold=0.1,
        reportname="e10-tc-2-all-clear-rhand-BEDO-comparison.exp"
    )
end

############################################################################################
# Experiment #11
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Right thumb and wrist in Not clear
#
#=
plot(collect(X_df_3_not_clear[30,16:18]),
    labels=["x" "y" "z"], title="Not clear - right hand thumb")
plot(collect(X_df_3_not_clear[30,22:24]),
    labels=["x" "y" "z"], title="Not clear - right hand thumb")

# Δy in "All clear"
plot(collect(X_df_2_all_clear[30,22:25]),
    labels=["x" "y" "z" "Δy"], title="All clear - right hand Δy between fingers and thumb")

# Δy in "Not clear"
plot(collect(X_df_3_not_clear[30,22:25]),
    labels=["x" "y" "z" "Δy"], title="Not clear - right hand Δy between fingers and thumb")

# Right thumb visualization in each class
plot(
    map(i->plot(collect(X_df[i,22:24]), labels=nothing,title=y[i]), 1:30:180)...,
    layout = (2, 3),
    size = (1500,400)
)
=#
############################################################################################

if 11 in EXPERIMENTS_IDS
    _11_right_hand_tip_Y_items = [
        Atom(ScalarCondition(VariableMin(5), >=, -0.5))
    ]

    _11_right_hand_delta_items = [
        Atom(ScalarCondition(VariableMax(25), <=, 0.0))
    ]

    _11_propositional_items = vcat(
        _11_right_hand_tip_Y_items,
        _11_right_hand_delta_items
    )

    _11_items = vcat(
        _11_propositional_items,
        diamond(IA_B).(_11_propositional_items),
        box(IA_E).(_11_propositional_items),
        diamond(IA_D).(_11_propositional_items),
        box(IA_O).(_11_propositional_items),
    ) .|> Item

    _11_itemsetmeasures = [(gsupport, 0.01, 0.01)]
    _11_rulemeasures = [(gconfidence, 0.1, 0.1)]

    _11_miner = runexperiment(
        X_3_not_clear,
        fpgrowth,
        _11_items,
        _11_itemsetmeasures,
        _11_rulemeasures;
        returnminer = true,
        reportname = "e11-tc-3-not-clear-rhand-rthumb-BEDO.exp",
        variablenames = VARIABLE_NAMES,
    )

    runcomparison(
        _11_miner,
        LOGISETS,
        (conf) -> conf >= 0.5;
        sigdigits=3 |> Int8,
        targetclass=3 |> Int8,
        suppthreshold=0.1,
        reportname="e11-tc-3-not-clear-rhand-rthumb-BEDO-comparison.exp"
    )
end

############################################################################################
# Extra, plots to study how to parametrize binning
############################################################################################

# let's consider a metacondition, one discretizer strategy, and a world filtering policy
variable = 5 # we consider right hand Y axis
_feature = VariableMax(nvariable) # max(V5)

# we choose a discretization strategy
nbins = 3
discretizer = Discretizers.DiscretizeQuantile(nbins)

# we only consider small intervals
small_intervals_worldfilter = worldfilter=SoleLogics.FunctionalWorldFilter(
    x -> length(x) <= 10, Interval{Int})

# first of all, let's plot the right hand Y original signal
rhand_y_signal_plot = plot(X_df[1,5], labels="Right hand Y")

savefig(rhand_y_signal_plot, "test/experiments/results/rhand_y_signal_plot.png")

############################################################################################
# Experiment #12
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# General experiment levereging the alphabet selection mechanism for each variable.
# TODO - at the moment, rules are extract from X_1_have_command
#
############################################################################################

if 12 in EXPERIMENTS_IDS
    # we want to generate an "useful" alphabet of propositions;
    # given a set of metaconditions, we want to find the thresholds to plug in.

    _12_items = Item[]

    # there is no need to consider left-sided body variables
    # (left arm is not moving in class 1)
    for variable_index in RIGHT_BODY_VARIABLES
        # each proposition follows this schema;
        # it can be shown that those pairings are more informative than (max, >=), (min, <=)
        metaconditions = [
            ScalarMetaCondition(VariableMax(variable_index), <=),
            ScalarMetaCondition(VariableMin(variable_index), >=)
        ]

        # as binning strategy, we choose to cut the distribution in 5 pieces with same area
        nbins = 3
        quantilediscretizer = Discretizers.DiscretizeQuantile(nbins)

        for metacondition in metaconditions
            alphabet = __arm_select_alphabet(
                X_df_1_have_command[:,variable_index], # TODO Use FilteredFrame
                metacondition,
                quantilediscretizer;
                consider_all_subintervals=true
            ) .|> Atom .|> Item

            push!(_12_items, alphabet...)
        end
    end

    _12_itemsetmeasures = [(gsupport, 0.4, 0.4)]
    _12_rulemeasures = [(gconfidence, 0.4, 0.4)]

    # 1thread w. 30 literals:  ~381s
    # 8threads w. 30 literals: ~66s
    _12_miner = Miner(
        deepcopy(X_1_have_command),
        fpgrowth,
        _12_items[1:20],
        _12_itemsetmeasures,
        _12_rulemeasures,

        worldfilter=SoleLogics.FunctionalWorldFilter(
            x -> length(x) <= 10, Interval{Int}),

        itemset_mining_policies=[islimited_length_itemset(; maxlength=5)],

        arule_mining_policies=[
            islimited_length_arule(; antecedent_maxlength=5),
            isanchored_arule(; npropositions=1),
            isheterogeneous_arule(; antecedent_nrepetitions=1, consequent_nrepetitions=0),
        ],
    )

    runexperiment(
        _12_miner;
        reportname = "e12-tc-1-i-have-command-auto-alphabet-full-propositional.exp",
        variablenames = VARIABLE_NAMES,
    )

    # runcomparison(
    #     _12_miner,
    #     LOGISETS,
    #     (conf) -> conf >= 0.4;
    #     sigdigits=3 |> Int8,
    #     targetclass=1 |> Int8,
    #     suppthreshold=0.4,
    #     reportname="e12-tc-1-i-have-command-auto-alphabet-full-propositional-comparison.exp"
    # )
end
