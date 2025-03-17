
SWC = X[91:120, :]

############################################################################################
# elbow x: left (7) and right (9)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v7_l10 = motifsalphabet(SWC[:,7], 10, 5; r=20, th=5);
__motif__v7_l10_lelbow_reentrant = _motifs_v7_l10[4]
__motif__v7_l10_lelbow_left = _motifs_v7_l10[5]

__var__v7_l10_lelbow_reentrant = VariableDistance(7,
    __motif__v7_l10_lelbow_reentrant,
    distance=x -> _mydistance(x, __motif__v7_l10_lelbow_reentrant),
    featurename="Reentrant"
)
__var__v7_l10_lelbow_left = VariableDistance(7,
    __motif__v7_l10_lelbow_left,
    distance=x -> _mydistance(x, __motif__v7_l10_lelbow_left),
    featurename="Left"
)

_mp, _raw_motifs, _motifs_v7_l30 = motifsalphabet(SWC[:,7], 30, 2; r=20, th=5);
__motif__v7_l30_lelbow_left_reen_left = _motifs_v7_l30[1]
__motif__v7_l30_lelbow_reen_left_reen = _motifs_v7_l30[2]

__var__v7_l30_lelbow_left_reen_left = VariableDistance(7,
    __motif__v7_l30_lelbow_left_reen_left,
    distance=x -> _mydistance(x, __motif__v7_l30_lelbow_left_reen_left),
    featurename="Left⋅Reentering⋅Left"
)

__var__v7_l30_lelbow_reen_left_reen = VariableDistance(7,
    __motif__v7_l30_lelbow_reen_left_reen,
    distance=x -> _mydistance(x, __motif__v7_l30_lelbow_reen_left_reen),
    featurename="Reentering⋅Left⋅Reentering"
)


## Right
_mp, _raw_motifs, _motifs_v10_l10 = motifsalphabet(SWC[:,10], 10, 5; r=20, th=5);
__motif__v10_l10_relbow_reentrant = _motifs_v10_l10[2]
__motif__v10_l10_relbow_right = _motifs_v10_l10[3]

__var__v10_l10_relbow_reentrant = VariableDistance(10,
    __motif__v10_l10_relbow_reentrant,
    distance=x -> _mydistance(x, __motif__v10_l10_relbow_reentrant),
    featurename="Reentrant"
)
__var__v10_l10_relbow_left = VariableDistance(10,
    __motif__v10_l10_relbow_right,
    distance=x -> _mydistance(x, __motif__v10_l10_relbow_right),
    featurename="Right"
)

_mp, _raw_motifs, _motifs_v10_l30 = motifsalphabet(SWC[:,10], 30, 2; r=20, th=5);
__motif__v10_l30_relbow_right_reen_right = _motifs_v10_l30[1]
__motif__v10_l30_relbow_reen_right_reen = _motifs_v10_l30[2]

__var__v10_l30_relbow_right_reen_right = VariableDistance(10,
    __motif__v10_l30_relbow_right_reen_right,
    distance=x -> _mydistance(x, __motif__v10_l30_relbow_right_reen_right),
    featurename="Right⋅Reentering⋅Right"
)

__var__v10_l30_relbow_reen_right_reen = VariableDistance(10,
__motif__v10_l30_relbow_reen_right_reen,
    distance=x -> _mydistance(x, __motif__v10_l30_relbow_reen_right_reen),
    featurename="Reentering⋅Right⋅Reentering"
)

############################################################################################
# elbow y: left (8) and right (11)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v8_l10 = motifsalphabet(SWC[:,8], 10, 5; r=20, th=5);
__motif__v8_l10_lelbow_ascend = _motifs_v8_l10[5]
__motif__v8_l10_lelbow_descending = _motifs_v8_l10[3]

__var__v8_l10_lelbow_ascend = VariableDistance(8,
    __motif__v8_l10_lelbow_ascend,
    distance=x -> _mydistance(x, __motif__v8_l10_lelbow_ascend),
    featurename="Ascending"
)
__var__v8_l10_lelbow_descending = VariableDistance(8,
    __motif__v8_l10_lelbow_descending,
    distance=x -> _mydistance(x, __motif__v8_l10_lelbow_descending),
    featurename="Descending"
)


_mp, _raw_motifs, _motifs_v8_l30 = motifsalphabet(SWC[:,8], 30, 2; r=20, th=5);
__motif__v8_l30_lelbow_ascending = _motifs_v8_l30[2]
__motif__v8_l30_lelbow_descending = _motifs_v8_l30[1]

__var__v8_l30_lelbow_ascending = VariableDistance(8,
    __motif__v8_l30_lelbow_ascending,
    distance=x -> _mydistance(x, __motif__v8_l30_lelbow_ascending),
    featurename="Long⋅Ascending"
)

__var__v8_l30_lelbow_descending = VariableDistance(8,
    __motif__v8_l30_lelbow_descending,
    distance=x -> _mydistance(x, __motif__v8_l30_lelbow_descending),
    featurename="Long⋅Descending"
)

## Right
_mp, _raw_motifs, _motifs_v11_l10 = motifsalphabet(SWC[:,11], 10, 5; r=10, th=5);
__motif__v11_l10_relbow_descend = _motifs_v11_l10[1]
__motif__v11_l10_relbow_ascend = _motifs_v11_l10[4]

__var__v11_l10_relbow_descend = VariableDistance(11,
    __motif__v11_l10_relbow_descend,
    distance=x -> _mydistance(x, __motif__v11_l10_relbow_descend),
    featurename="Descending"
)
__var__v11_l10_relbow_ascend = VariableDistance(11,
    __motif__v11_l10_relbow_ascend,
    distance=x -> _mydistance(x, __motif__v11_l10_relbow_ascend),
    featurename="Ascending"
)


_mp, _raw_motifs, _motifs_v11_l30 = motifsalphabet(SWC[:,11], 30, 2; r=20, th=5);
__motif__v11_l30_relbow_longdescend = _motifs_v11_l30[1]
__motif__v11_l30_relbow_longascend = _motifs_v11_l30[2]

__var__v11_l30_relbow_longdescend = VariableDistance(11,
    __motif__v11_l30_relbow_longdescend,
    distance=x -> _mydistance(x, __motif__v11_l30_relbow_longdescend),
    featurename="Long⋅Descending"
)

__var__v11_l30_relbow_longascend = VariableDistance(11,
__motif__v11_l30_relbow_longascend,
    distance=x -> _mydistance(x, __motif__v11_l30_relbow_longascend),
    featurename="Long⋅Ascending"
)

############################################################################################
# elbow z: left (9) and right (12)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v9_l10 = motifsalphabet(SWC[:,9], 10, 5; r=20, th=5);
__motif__v9_l10_lelbow_left = _motifs_v9_l10[4]
__motif__v9_l10_lelbow_neutral = _motifs_v9_l10[2]

__var__v9_l10_lelbow_left = VariableDistance(9,
    __motif__v9_l10_lelbow_left,
    distance=x -> _mydistance(x, __motif__v9_l10_lelbow_left),
    featurename="Left"
)
__var__v9_l10_lelbow_neutral = VariableDistance(9,
    __motif__v9_l10_lelbow_neutral,
    distance=x -> _mydistance(x, __motif__v9_l10_lelbow_neutral),
    featurename="Neutral"
)


_mp, _raw_motifs, _motifs_v9_l30 = motifsalphabet(SWC[:,9], 30, 1; r=10, th=10);
__motif__v9_l30_lelbow_left_neutral = _motifs_v9_l30[1]

__var__v9_l30_lelbow_left_neutral = VariableDistance(9,
    __motif__v9_l30_lelbow_left_neutral,
    distance=x -> _mydistance(x, __motif__v9_l30_lelbow_left_neutral),
    featurename="Left⋅Neutral"
)

## Right
_mp, _raw_motifs, _motifs_v12_l10 = motifsalphabet(SWC[:,12], 10, 5; r=20, th=5);
__motif__v12_l10_relbow_right = _motifs_v12_l10[5]
__motif__v12_l10_relbow_neutral = _motifs_v12_l10[4]

__var__v12_l10_relbow_right = VariableDistance(12,
    __motif__v12_l10_relbow_right,
    distance=x -> _mydistance(x, __motif__v12_l10_relbow_right),
    featurename="Right"
)
__var__v12_l10_relbow_neutral = VariableDistance(12,
    __motif__v12_l10_relbow_neutral,
    distance=x -> _mydistance(x, __motif__v12_l10_relbow_neutral),
    featurename="Neutral"
)


_mp, _raw_motifs, _motifs_v12_l30 = motifsalphabet(SWC[:,12], 30, 1; r=10, th=10);
__motif__v12_l30_relbow_right_reentering = _motifs_v12_l30[1]

__var__v12_l30_relbow_right_reentering = VariableDistance(12,
    __motif__v12_l30_relbow_right_reentering,
    distance=x -> _mydistance(x, __motif__v12_l30_relbow_right_reentering),
    featurename="Right⋅Neutral"
)

############################################################################################
# assembly
############################################################################################

allmotifs = [
    __motif__v7_l10_lelbow_reentrant,
    __motif__v7_l10_lelbow_left,
    __motif__v7_l30_lelbow_left_reen_left,
    __motif__v7_l30_lelbow_reen_left_reen,

    __motif__v10_l10_relbow_reentrant,
    __motif__v10_l10_relbow_right,
    __motif__v10_l30_relbow_right_reen_right,
    __motif__v10_l30_relbow_reen_right_reen,

    __motif__v8_l10_lelbow_ascend,
    __motif__v8_l10_lelbow_descending,
    __motif__v8_l30_lelbow_ascending,
    __motif__v8_l30_lelbow_descending,

    __motif__v11_l10_relbow_descend,
    __motif__v11_l10_relbow_ascend,
    __motif__v11_l30_relbow_longdescend,
    __motif__v11_l30_relbow_longascend,

    __motif__v9_l10_lelbow_neutral,
    __motif__v9_l10_lelbow_left,
    __motif__v9_l30_lelbow_left_neutral,

    __motif__v12_l10_relbow_right,
    __motif__v12_l10_relbow_neutral,
    __motif__v12_l30_relbow_right_reentering,
]

variabledistances = [
    __var__v7_l10_lelbow_reentrant,
    __var__v7_l10_lelbow_left,
    __var__v7_l30_lelbow_left_reen_left,
    __var__v7_l30_lelbow_reen_left_reen,

    __var__v10_l10_relbow_reentrant,
    __var__v10_l10_relbow_left,
    __var__v10_l30_relbow_right_reen_right,
    __var__v10_l30_relbow_reen_right_reen,

    __var__v8_l10_lelbow_ascend,
    __var__v8_l10_lelbow_descending,
    __var__v8_l30_lelbow_ascending,
    __var__v8_l30_lelbow_descending,

    __var__v11_l10_relbow_descend,
    __var__v11_l10_relbow_ascend,
    __var__v11_l30_relbow_longdescend,
    __var__v11_l30_relbow_longascend,

    __var__v9_l10_lelbow_neutral,
    __var__v9_l10_lelbow_left,
    __var__v9_l30_lelbow_left_neutral,

    __var__v12_l10_relbow_right,
    __var__v12_l10_relbow_neutral,
    __var__v12_l30_relbow_right_reentering,
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v7_l10_lelbow_reentrant, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_left, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l30_lelbow_left_reen_left, <, 4.0)),
    Atom(ScalarCondition(__var__v7_l30_lelbow_reen_left_reen, <, 4.0)),

    Atom(ScalarCondition(__var__v10_l10_relbow_reentrant, <, 2.0)),
    Atom(ScalarCondition(__var__v10_l10_relbow_left, <, 4.0)),
    Atom(ScalarCondition(__var__v10_l30_relbow_right_reen_right, <, 4.0)),
    Atom(ScalarCondition(__var__v10_l30_relbow_reen_right_reen, <, 4.0)),

    Atom(ScalarCondition(__var__v8_l10_lelbow_ascend, <, 2.0)),
    Atom(ScalarCondition(__var__v8_l10_lelbow_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v8_l30_lelbow_ascending, <, 4.0)),
    Atom(ScalarCondition(__var__v8_l30_lelbow_descending, <, 4.0)),

    Atom(ScalarCondition(__var__v11_l10_relbow_descend, <, 2.0)),
    Atom(ScalarCondition(__var__v11_l10_relbow_ascend, <, 2.0)),
    Atom(ScalarCondition(__var__v11_l30_relbow_longdescend, <, 4.0)),
    Atom(ScalarCondition(__var__v11_l30_relbow_longascend, <, 4.0)),

    Atom(ScalarCondition(__var__v9_l10_lelbow_neutral, <, 2.0)),
    Atom(ScalarCondition(__var__v9_l10_lelbow_left, <, 2.0)),
    Atom(ScalarCondition(__var__v9_l30_lelbow_left_neutral, <, 4.0)),

    Atom(ScalarCondition(__var__v12_l10_relbow_right, <, 2.0)),
    Atom(ScalarCondition(__var__v12_l10_relbow_neutral, <, 2.0)),
    Atom(ScalarCondition(__var__v12_l30_relbow_right_reentering, <, 4.0)),
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
        diamond(IA_L).(propositional_atoms),
        diamond(IA_B).(propositional_atoms),
        diamond(IA_E).(propositional_atoms),
        diamond(IA_D).(propositional_atoms),
        diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)

_itemsetmeasures = [(dimensional_gsupport, 0.3, 0.3)]
_rulemeasures = [(dimensional_gconfidence, 0.3, 0.3)]


logiset = scalarlogiset(SWC, variabledistances)

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
