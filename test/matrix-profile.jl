using Test

using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Random
using Statistics

using SoleData

X, _ = load_NATOPS();

# right hand y axis
var_id = 5

# right hand in "I have command class"
IHCC_rhand_y_only = Vector{Float32}.(X[1:30, var_id])

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
normalize(x) = (x .- mean(x)) ./ std(x)
_mydistance = (x, y) -> size(x) == size(y) ?
    # normalization on (naive, just for test)
    # sqrt(sum([(x - y)^2 for (x, y) in zip(x |> normalize, y)])) :
    # normalization off
    sqrt(sum([(x - y)^2 for (x, y) in zip(x, y)])) :
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

# those atoms will label possibly every world; they are agnostic of their size;
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

# now we want to test a more general setting, in which multiple variables are considered
# as well as multiple motif lengths.

# isolate "I have command class"
IHCC = X[1:30, :]

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(IHCC[:,4], 10, 5; r=5, th=2);
__motif__v4_l10_rhand_x_protracting = _motifs_v4_l10[3]
__motif__v4_l10_rhand_x_retracting = _motifs_v4_l10[5]

__var__v4_l10_rhand_x_protracting = VariableDistance(4,
    __motif__v4_l10_rhand_x_protracting,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_protracting),
    featurename="Protracting"
)
__var__v4_l10_rhand_x_retracting = VariableDistance(4,
    __motif__v4_l10_rhand_x_retracting,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_retracting),
    featurename="Retracting"
)


_mp, _raw_motifs, _motifs_v4_l40 = motifsalphabet(IHCC[:,4], 30, 10; r=5, th=0);
__motif__v4_l40_rhand_x_retracting_inverting_protracting = _motifs_v4_l40[8]

__var__v4_l40_rhand_x_retracting_inverting_protracting = VariableDistance(4,
    __motif__v4_l40_rhand_x_retracting_inverting_protracting,
    distance=x -> _mydistance(x, __motif__v4_l40_rhand_x_retracting_inverting_protracting),
    featurename="Retracting⋅InvertingDirection⋅Protracting"
)


# right hand Y variable generations

_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(IHCC[:,5], 10, 10; r=5, th=2)
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


_mp, _raw_motifs, _motifs_v5_l40 = motifsalphabet(IHCC[:,5], 40, 10; r=5, th=5)
__motif__v5_l40_rhand_y_ascdesc = _motifs_v5_l40[7]

__var__v5_l40_rhand_y_ascdesc = VariableDistance(5,
    __motif__v5_l40_rhand_y_ascdesc,
    distance=x -> _mydistance(x, __motif__v5_l40_rhand_y_ascdesc),
    featurename="Ascending⋅Descending"
)

# right hand Z variable generation

_mp, _raw_motifs, _motifs_v6_l10 = motifsalphabet(IHCC[:,6], 10, 10; r=5, th=2);
__motif__v6_l10_rhand_z_away_hip = _motifs_v6_l10[2]
__motif__v6_l10_rhand_z_closer_hip = _motifs_v5_l10[6]


__var__v6_l10_rhand_z_away_hip = VariableDistance(6,
    __motif__v6_l10_rhand_z_away_hip,
    distance=x -> _mydistance(x, __motif__v6_l10_rhand_z_away_hip),
    featurename="MovingAwayHip"
)

__var__v6_l10_rhand_z_closer_hip = VariableDistance(6,
    __motif__v6_l10_rhand_z_closer_hip,
    distance=x -> _mydistance(x, __motif__v6_l10_rhand_z_closer_hip),
    featurename="ApproachingHip"
)

# variables assembly;
# insert your variables in variabledistances array,
# then adjust the _distance_threshold (which is equal for each ScalarCondition)
# and the meaningfulness measures thresholds.

allmotifs = [
    __motif__v4_l10_rhand_x_protracting,
    __motif__v4_l10_rhand_x_retracting,
    __motif__v4_l40_rhand_x_retracting_inverting_protracting,

    __motif__v5_l10_rhand_y_ascending,
    __motif__v5_l10_rhand_y_descending,
    __motif__v5_l40_rhand_y_ascdesc,

    __motif__v6_l10_rhand_z_away_hip,
    __motif__v6_l10_rhand_z_closer_hip,
]

variabledistances = [
    __var__v4_l10_rhand_x_protracting,
    __var__v4_l10_rhand_x_retracting,
    __var__v4_l40_rhand_x_retracting_inverting_protracting,

    __var__v5_l10_rhand_y_ascending,
    __var__v5_l10_rhand_y_descending,
    __var__v5_l40_rhand_y_ascdesc,

    __var__v5_l40_rhand_z_away_hip,
    __var__v5_l40_rhand_z_closer_hip,
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v4_l10_rhand_x_protracting, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l10_rhand_x_retracting, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l40_rhand_x_retracting_inverting_protracting, <, 5.0)),

    Atom(ScalarCondition(__var__v5_l10_rhand_y_ascending, <, 3.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_y_descending, <, 3.0)),
    Atom(ScalarCondition(__var__v5_l40_rhand_y_ascdesc, <, 5.0)),

    Atom(ScalarCondition(__var__v5_l40_rhand_z_away_hip, <, 3.0)),
    Atom(ScalarCondition(__var__v5_l40_rhand_z_closer_hip, <, 3.0)),
];

atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_D).(propositional_atoms),
        diamond(IA_A).(propositional_atoms)
    ]
)
_items = Vector{Item}(atoms)

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

mine!(apriori_miner)

for frq in freqitems(apriori_miner)
    println("$(frq) => gsupport $(apriori_miner.globalmemo[(:dimensional_gsupport, frq)])")
end

generaterules!(apriori_miner) |> collect

rulecollection = [
    (rule, apriori_miner.globalmemo[(:dimensional_gconfidence, rule)])
    for rule in arules(apriori_miner)
]
sort!(rulecollection, by=x->x|>last, rev=true);

open("results.txt", "w") do io
    for (rule,conf) in rulecollection
        println(io, rpad(rule, 130) * " " * string(conf))
    end
end

# to help debugging
# plot([__motif__v5_l10_rhand_y_descending, IHCC[1,5][18:27] |> normalize  ])
