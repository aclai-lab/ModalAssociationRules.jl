using Test

using DynamicAxisWarping
using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Random
using Statistics

using SoleData

# little utility to avoid writing an experiment
function experiment!(miner::Miner, reportname::String)
    mine!(miner)

    generaterules!(miner) |> collect

    rulecollection = [
        (
            rule,
            round(
                globalmemo(miner, (:dimensional_gconfidence, rule)), digits=2
            ),
            round(
                globalmemo(miner, (:dimensional_gsupport, antecedent(rule))), digits=2
            ),
            round(
                globalmemo(miner, (:dimensional_gsupport, Itemset(rule))), digits=2
            )
        )
        for rule in arules(miner)
    ]
    sort!(rulecollection, by=x->x[2], rev=true);

    reportname = joinpath(["test", "experiments", reportname])
    open(reportname, "w") do io
        println(io, "Columns are: rule, confidence, ant support, ant+cons support")

        for (rule,conf,antgsupp,consgsupp) in rulecollection
            println(io,
                rpad(rule, 130) * " " * rpad(string(conf), 10) * " " *
                rpad(string(antgsupp), 10) * " " * string(consgsupp)
            )
        end
    end
end

X, y = load_NATOPS();
insertcols!(X, 25, "ΔY[Thumb r and Hand tip r]" => X[:,5]-X[:,23])

# right hand y axis
var_id = 5

# right hand in "I have command class"
IHCC_rhand_y_only = Vector{Float64}.(X[1:30, var_id])

# parameters for matrix profile generation
windowlength = 20
nmotifs = 3
_seed = 3498
r = 5   # how similar two windows must be to belong to the same motif
th = 10  # how nearby in time two motifs are allowed to be

mp, _raw_motifs, _motifs = motifsalphabet(
    IHCC_rhand_y_only, windowlength, nmotifs; r=r, th=th);
@test length(_motifs) == 3

# we isolated the only var_id 5 from the class "I have command",
# thus we now have only one column/var_id;
# for simplicity, let's consider also just one motif.

# we define a distance function between two time series x, y, where |x| = |y|
_mydistance = (x, y) -> size(x) == size(y) ?
    # Euclidean with normalization
    # sqrt(sum([(x - y)^2 for (x, y) in zip(x |> normalize, y)])) :

    # Euclidean without normalization
    # sqrt(sum([(x - y)^2 for (x, y) in zip(x, y)])) :

    # Dynamic Time Warping
    dtw(x,y) |> first :

    # distance function isz not well-defined
    maxintfloat()

vd1 = VariableDistance(
    var_id,
    _motifs[1],
    distance=x -> _mydistance(x, _motifs[1]),
    featurename="DescendingYArm"
)

vd2 = VariableDistance(
    var_id,
    _motifs[3],
    distance=x -> _mydistance(x, _motifs[2]),
    featurename="AscendingYArm"
)

# make proposition (we consider this as we entire alphabet, at the moment)
proposition1 = Atom(ScalarCondition(vd1, <, 5.0))
proposition2 = Atom(ScalarCondition(vd2, <, 5.0))

# those _atoms will label possibly every world (they are agnostic of their size);
# we introduce those to test whether `isdimensionally_coherent_itemset` filter policy
# is working later.
vm1, vm2 = VariableMin(1), VariableMin(2)
p = Atom(ScalarCondition(vm1, <, 999.0))
q = Atom(ScalarCondition(vm2, <, 999.0))

_items = Vector{Item}([proposition1, proposition2, p, q])

# define meaningfulness measures
_itemsetmeasures = [(dimensional_gsupport, 0.001, 0.001)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

# build the logiset we will mine
logiset = scalarlogiset(X[1:30,:], [vd1, vd2, vm1, vm2])

# build the miner, and mine!
apriori_miner = Miner(
    logiset,
    apriori,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=[isdimensionally_coherent_itemset()]
)

@test_nowarn mine!(apriori_miner)
@test freqitems(apriori_miner) |> length == 5

############################################################################################
# Experiment #1: describe the right hand in "I have command class"
############################################################################################

# now we want to test a more general setting, in which multiple variables are considered
# as well as multiple motif lengths.

# isolate "I have command class"
IHCC = X[1:30, :]

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(IHCC[:,4], 10, 5; r=5, th=2);
__motif__v4_l10_rhand_x_right = _motifs_v4_l10[3]
__motif__v4_l10_rhand_x_align = _motifs_v4_l10[5]

__var__v4_l10_rhand_x_right = VariableDistance(4,
    __motif__v4_l10_rhand_x_right,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_right),
    featurename="Right"
)
__var__v4_l10_rhand_x_align = VariableDistance(4,
    __motif__v4_l10_rhand_x_align,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_align),
    featurename="Align"
)


_mp, _raw_motifs, _motifs_v4_l40 = motifsalphabet(IHCC[:,4], 30, 10; r=5, th=0);
__motif__v4_l40_rhand_x_align_inverting_right = _motifs_v4_l40[8]

__var__v4_l40_rhand_x_align_inverting_right = VariableDistance(4,
    __motif__v4_l40_rhand_x_align_inverting_right,
    distance=x -> _mydistance(x, __motif__v4_l40_rhand_x_align_inverting_right),
    featurename="Align⋅Right"
)


# right hand Y variable generations

_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(IHCC[:,5], 10, 10; r=5, th=2);
__motif__v5_l10_rhand_y_ascending = _motifs_v5_l10[5]
__motif__v5_l10_rhand_y_descending = _motifs_v5_l10[2]

__var__v5_l10_rhand_y_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_y_ascending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_ascending),
    featurename="Ascending"
)
__var__v5_l10_rhand_y_descending = VariableDistance(5,
    __motif__v5_l10_rhand_y_descending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_descending),
    featurename="Descending"
)


_mp, _raw_motifs, _motifs_v5_l40 = motifsalphabet(IHCC[:,5], 40, 10; r=5, th=5);
__motif__v5_l40_rhand_y_ascdesc = _motifs_v5_l40[7]

__var__v5_l40_rhand_y_ascdesc = VariableDistance(5,
    __motif__v5_l40_rhand_y_ascdesc,
    distance=x -> _mydistance(x, __motif__v5_l40_rhand_y_ascdesc),
    featurename="Ascending⋅Descending"
)

# right hand Z variable generation

_mp, _raw_motifs, _motifs_v6_l10 = motifsalphabet(IHCC[:,6], 10, 10; r=5, th=2);
__motif__v6_l10_rhand_z_away_front = _motifs_v6_l10[2]
__motif__v6_l10_rhand_z_closer_front = _motifs_v5_l10[6]


__var__v6_l10_rhand_z_away_front = VariableDistance(6,
    __motif__v6_l10_rhand_z_away_front,
    distance=x -> _mydistance(x, __motif__v6_l10_rhand_z_away_front),
    featurename="AwayFront"
)

__var__v6_l10_rhand_z_closer_front = VariableDistance(6,
    __motif__v6_l10_rhand_z_closer_front,
    distance=x -> _mydistance(x, __motif__v6_l10_rhand_z_closer_front),
    featurename="NeutralFront"
)

# variables assembly;
# insert your variables in variabledistances array,
# then adjust the _distance_threshold (which is equal for each ScalarCondition)
# and the meaningfulness measures thresholds.

allmotifs = [
    __motif__v4_l10_rhand_x_right,
    __motif__v4_l10_rhand_x_align,
    __motif__v4_l40_rhand_x_align_inverting_right,

    __motif__v5_l10_rhand_y_ascending,
    __motif__v5_l10_rhand_y_descending,
    __motif__v5_l40_rhand_y_ascdesc,

    __motif__v6_l10_rhand_z_away_front,
    __motif__v6_l10_rhand_z_closer_front,
]

variabledistances = [
    __var__v4_l10_rhand_x_right,
    __var__v4_l10_rhand_x_align,
    __var__v4_l40_rhand_x_align_inverting_right,

    __var__v5_l10_rhand_y_ascending,
    __var__v5_l10_rhand_y_descending,
    __var__v5_l40_rhand_y_ascdesc,

    __var__v6_l10_rhand_z_away_front,
    __var__v6_l10_rhand_z_closer_front,
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v4_l10_rhand_x_right, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l10_rhand_x_align, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l40_rhand_x_align_inverting_right, <, 4.0)),

    Atom(ScalarCondition(__var__v5_l10_rhand_y_ascending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_y_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l40_rhand_y_ascdesc, <, 4.0)),

    Atom(ScalarCondition(__var__v6_l10_rhand_z_away_front, <, 2.0)),
    Atom(ScalarCondition(__var__v6_l10_rhand_z_closer_front, <, 2.0)),
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
        diamond(IA_L).(propositional_atoms),
        diamond(IA_B).(propositional_atoms),
        diamond(IA_E).(propositional_atoms),
        diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)

_itemsetmeasures = [(dimensional_gsupport, 0.1, 0.1)]
_rulemeasures = [(dimensional_gconfidence, 0.1, 0.1)]

logiset = scalarlogiset(IHCC, variabledistances)

apriori_miner = Miner(
    logiset,
    apriori,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=Function[
        isanchored_itemset(),
        isdimensionally_coherent_itemset()
    ],
    arule_mining_policies=Function[
        islimited_length_arule(),
        isanchored_arule(),
        # isheterogeneous_arule(),
    ]
)

println("Running experiment #1:")
experiment!(apriori_miner, "rhand_ihavecommand.txt")

############################################################################################
# Experiment #2: describe the right hand in "All clear class"
############################################################################################

ACC = X[31:60, :]

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(ACC[:,4], 10, 5; r=5, th=2);
__motif__v4_l10_rhand_x_right = _motifs_v4_l10[5]
__motif__v4_l10_rhand_x_align = _motifs_v4_l10[3]

__var__v4_l10_rhand_x_right = VariableDistance(4,
    __motif__v4_l10_rhand_x_right,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_right),
    featurename="Right"
)
__var__v4_l10_rhand_x_align = VariableDistance(4,
    __motif__v4_l10_rhand_x_align,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_align),
    featurename="Align"
)


_mp, _raw_motifs, _motifs_v4_l40 = motifsalphabet(ACC[:,4], 30, 1; r=5, th=0);
__motif__v4_l40_rhand_x_right_align_still = _motifs_v4_l40[]

__var__v4_l40_rhand_x_right_align_still = VariableDistance(4,
    __motif__v4_l40_rhand_x_right_align_still,
    distance=x -> _mydistance(x, __motif__v4_l40_rhand_x_right_align_still),
    featurename="Right⋅Align⋅Still"
)


# right hand Y variable generations

_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(ACC[:,5], 10, 10; r=5, th=2);
__motif__v5_l10_rhand_y_ascending = _motifs_v5_l10[1]
__motif__v5_l10_rhand_y_descending = _motifs_v5_l10[2]

__var__v5_l10_rhand_y_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_y_ascending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_ascending),
    featurename="Ascending"
)
__var__v5_l10_rhand_y_descending = VariableDistance(5,
    __motif__v5_l10_rhand_y_descending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_descending),
    featurename="Descending"
)


_mp, _raw_motifs, _motifs_v5_l30 = motifsalphabet(ACC[:,5], 30, 10; r=5, th=2);
__motif__v5_l30_rhand_y_ascending_inverting = _motifs_v5_l30[7]
__motif__v5_l30_rhand_y_inverting_descending = _motifs_v5_l30[6]

__var__v5_l30_rhand_y_ascinvert = VariableDistance(5,
    __motif__v5_l30_rhand_y_ascending_inverting,
    distance=x -> _mydistance(x, __motif__v5_l40_rhand_y_ascdesc),
    featurename="Ascending⋅Inverting"
)

__var__v5_l30_rhand_y_invertdesc = VariableDistance(5,
    __motif__v5_l30_rhand_y_inverting_descending,
    distance=x -> _mydistance(x, __motif__v5_l40_rhand_y_ascdesc),
    featurename="Inverting⋅Descending"
)


# right thumb Y (actually, r-finger-tips-Y minus r-thumb-Y to consider thumb orientation)

_mp, _raw_motifs, _motifs_v25_l10 = motifsalphabet(ACC[:,25], 10, 10; r=5, th=2);
__motif__v25_l10_rhand_thumb_up = _motifs_v25_l10[1]
__motif__v25_l10_rhand_thumb_down = _motifs_v25_l10[3]

__var__v25_l10_rhand_thumb_up = VariableDistance(25,
    __motif__v25_l10_rhand_thumb_up,
    distance=x -> _mydistance(x, __motif__v25_l10_rhand_thumb_up),
    featurename="Up"
)
__var__v25_l10_rhand_thumb_down = VariableDistance(25,
    __motif__v25_l10_rhand_thumb_down,
    distance=x -> _mydistance(x, __motif__v25_l10_rhand_thumb_down),
    featurename="Down"
)

_mp, _raw_motifs, _motifs_v25_l20 = motifsalphabet(ACC[:,25], 20, 10; r=5, th=2);
__motif__v25_l20_rhand_thumb_inversion = _motifs_v25_l20[5]

__var__v25_l20_rhand_thumb_inversion = VariableDistance(25,
    __motif__v25_l20_rhand_thumb_inversion,
    distance=x -> _mydistance(x, __motif__v25_l20_rhand_thumb_inversion),
    featurename="Inversion"
)

allmotifs = [
    __motif__v4_l10_rhand_x_right,
    __motif__v4_l10_rhand_x_align,
    __motif__v4_l40_rhand_x_right_align_still,

    __motif__v5_l10_rhand_y_ascending,
    __motif__v5_l10_rhand_y_descending,
    __motif__v5_l30_rhand_y_ascending_inverting,
    __motif__v5_l30_rhand_y_inverting_descending,

    __motif__v25_l10_rhand_thumb_up,
    __motif__v25_l10_rhand_thumb_down,
    __motif__v25_l20_rhand_thumb_inversion
]

variabledistances = [
    __var__v4_l10_rhand_x_right,
    __var__v4_l10_rhand_x_align,
    __var__v4_l40_rhand_x_right_align_still,

    __var__v5_l10_rhand_y_ascending,
    __var__v5_l10_rhand_y_descending,
    __var__v5_l30_rhand_y_ascinvert,
    __var__v5_l30_rhand_y_invertdesc,

    __var__v25_l10_rhand_thumb_up,
    __var__v25_l10_rhand_thumb_down,
    __var__v25_l20_rhand_thumb_inversion
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v4_l10_rhand_x_right, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l10_rhand_x_align, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l40_rhand_x_right_align_still, <, 4.0)),

    Atom(ScalarCondition(__var__v5_l10_rhand_y_ascending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_y_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l30_rhand_y_ascinvert, <, 4.0)),
    Atom(ScalarCondition(__var__v5_l30_rhand_y_invertdesc, <, 4.0)),

    Atom(ScalarCondition(__var__v25_l10_rhand_thumb_up, <, 2.0)),
    Atom(ScalarCondition(__var__v25_l10_rhand_thumb_down, <, 2.0)),
    Atom(ScalarCondition(__var__v25_l20_rhand_thumb_inversion, <, 4.0))
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
        diamond(IA_L).(propositional_atoms),
        diamond(IA_B).(propositional_atoms),
        diamond(IA_E).(propositional_atoms),
        diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)

_itemsetmeasures = [(dimensional_gsupport, 0.1, 0.1)]
_rulemeasures = [(dimensional_gconfidence, 0.1, 0.1)]

logiset = scalarlogiset(ACC, variabledistances)

apriori_miner = Miner(
    logiset,
    apriori,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=Function[
        isanchored_itemset(),
        isdimensionally_coherent_itemset()
    ],
    arule_mining_policies=Function[
        islimited_length_arule(),
        isanchored_arule(),
        # isheterogeneous_arule(),
    ]
)

println("Running experiment #2: ")
experiment!(apriori_miner, "rhand_allclear.txt")


# to help debugging
# plot([__motif__v5_l10_rhand_y_descending, IHCC[1,5][18:27] |> normalize  ])

# plot frequent items in descending order by dimensiona global support
# for frq in freqitems(miner)
#   println("$(frq) => gsupport $(apriori_miner.globalmemo[(:dimensional_gsupport, frq)])")
# end
