# README: see experiments-driver.jl

SWC = X[91:120, :]

_r = 1

############################################################################################
# elbow x: left (7) and right (10)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v7_l10 = motifsalphabet(SWC[:,7], 10, 100; r=_r, th=10);
__motif__v7_l10_lelbow_reentrant = _motifs_v7_l10[[16,18,19,20,29,30,32]]
__motif__v7_l10_lelbow_left = _motifs_v7_l10[[22,24,31,33]]

__var__v7_l10_lelbow_reentrant = VariableDistance(7,
    __motif__v7_l10_lelbow_reentrant,
    distance=expdistance,
    featurename="Reentrant"
)
__var__v7_l10_lelbow_left = VariableDistance(7,
    __motif__v7_l10_lelbow_left,
    distance=expdistance,
    featurename="Left"
)

_mp, _raw_motifs, _motifs_v7_l40 = motifsalphabet(SWC[:,7], 40, 25; r=_r, th=5);
__motif__v7_l40_lelbow_left_reen_left = _motifs_v7_l40[[22,25,10]]

__var__v7_l40_lelbow_left_reen_left = VariableDistance(7,
    __motif__v7_l40_lelbow_left_reen_left,
    distance=expdistance,
    featurename="Left⋅Reentering⋅Left"
)


## Right
_mp, _raw_motifs, _motifs_v10_l10 = motifsalphabet(SWC[:,10], 10, 25; r=_r, th=5);
__motif__v10_l10_relbow_right = _motifs_v10_l10[[1,2,3,6,8,10]]
__motif__v10_l10_relbow_reentrant = _motifs_v10_l10[[4,5,9,14,25]]

__var__v10_l10_relbow_reentrant = VariableDistance(10,
    __motif__v10_l10_relbow_reentrant,
    distance=expdistance,
    featurename="Reentrant"
)
__var__v10_l10_relbow_left = VariableDistance(10,
    __motif__v10_l10_relbow_right,
    distance=expdistance,
    featurename="Right"
)

_mp, _raw_motifs, _motifs_v10_l40 = motifsalphabet(SWC[:,10], 40, 50; r=_r, th=5);
# due to investigating plot(_raw_motifs[25:50])
__motif__v10_l40_relbow_right_reen_right = _motifs_v10_l40[[26+1,26+20,26+23,26+24]]

__var__v10_l40_relbow_right_reen_right = VariableDistance(10,
    __motif__v10_l40_relbow_right_reen_right,
    distance=expdistance,
    featurename="Right⋅Reentering⋅Right"
)

############################################################################################
# elbow y: left (8) and right (11)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v8_l10 = motifsalphabet(SWC[:,8], 10, 30; r=_r, th=5);
__motif__v8_l10_lelbow_ascend = _motifs_v8_l10[[28]]
__motif__v8_l10_lelbow_descending = _motifs_v8_l10[[3,19,20]]

__var__v8_l10_lelbow_ascend = VariableDistance(8,
    __motif__v8_l10_lelbow_ascend,
    distance=expdistance,
    featurename="Ascending"
)
__var__v8_l10_lelbow_descending = VariableDistance(8,
    __motif__v8_l10_lelbow_descending,
    distance=expdistance,
    featurename="Descending"
)


_mp, _raw_motifs, _motifs_v8_l40 = motifsalphabet(SWC[:,8], 40, 25; r=_r, th=5);
__motif__v8_l40_lelbow_ascending = _motifs_v8_l40[[4,7,19]]
__motif__v8_l40_lelbow_descending = _motifs_v8_l40[[9,14]]

__var__v8_l40_lelbow_ascending = VariableDistance(8,
    __motif__v8_l40_lelbow_ascending,
    distance=expdistance,
    featurename="Long⋅Ascending"
)

__var__v8_l40_lelbow_descending = VariableDistance(8,
    __motif__v8_l40_lelbow_descending,
    distance=expdistance,
    featurename="Long⋅Descending"
)

## Right
_mp, _raw_motifs, _motifs_v11_l10 = motifsalphabet(SWC[:,11], 10, 45; r=_r, th=5);
__motif__v11_l10_relbow_descend = _motifs_v11_l10[[11,18,19,25]]
__motif__v11_l10_relbow_ascend = _motifs_v11_l10[[27,38]]

__var__v11_l10_relbow_descend = VariableDistance(11,
    __motif__v11_l10_relbow_descend,
    distance=expdistance,
    featurename="Descending"
)
__var__v11_l10_relbow_ascend = VariableDistance(11,
    __motif__v11_l10_relbow_ascend,
    distance=expdistance,
    featurename="Ascending"
)


_mp, _raw_motifs, _motifs_v11_l40 = motifsalphabet(SWC[:,11], 40, 25; r=_r, th=5);
__motif__v11_l40_relbow_longdescend = _motifs_v11_l40[[1,2,3,4]]
__motif__v11_l40_relbow_longascend = _motifs_v11_l40[[6,17]]

__var__v11_l40_relbow_longdescend = VariableDistance(11,
    __motif__v11_l40_relbow_longdescend,
    distance=expdistance,
    featurename="Long⋅Descending"
)

__var__v11_l40_relbow_longascend = VariableDistance(11,
    __motif__v11_l40_relbow_longascend,
    distance=expdistance,
    featurename="Long⋅Ascending"
)

############################################################################################
# elbow z: left (9) and right (12)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v9_l10 = motifsalphabet(SWC[:,9], 10, 25; r=_r, th=5);
__motif__v9_l10_lelbow_left = _motifs_v9_l10[[11,13,16]]
__motif__v9_l10_lelbow_neutral = _motifs_v9_l10[[4,17]]

__var__v9_l10_lelbow_left = VariableDistance(9,
    __motif__v9_l10_lelbow_left,
    distance=expdistance,
    featurename="Front"
)
__var__v9_l10_lelbow_neutral = VariableDistance(9,
    __motif__v9_l10_lelbow_neutral,
    distance=expdistance,
    featurename="Neutral"
)


_mp, _raw_motifs, _motifs_v9_l40 = motifsalphabet(SWC[:,9], 40, 25; r=_r, th=5);
__motif__v9_l40_lelbow_left_neutral = _motifs_v9_l40[[19,24]]

__var__v9_l40_lelbow_left_neutral = VariableDistance(9,
    __motif__v9_l40_lelbow_left_neutral,
    distance=expdistance,
    featurename="Front⋅Neutral"
)

## Right
_mp, _raw_motifs, _motifs_v12_l10 = motifsalphabet(SWC[:,12], 10, 25; r=_r, th=5);
__motif__v12_l10_relbow_right = _motifs_v12_l10[[15,21,24]]
__motif__v12_l10_relbow_neutral = _motifs_v12_l10[[6,8,18]]

__var__v12_l10_relbow_right = VariableDistance(12,
    __motif__v12_l10_relbow_right,
    distance=expdistance,
    featurename="Front"
)
__var__v12_l10_relbow_neutral = VariableDistance(12,
    __motif__v12_l10_relbow_neutral,
    distance=expdistance,
    featurename="Neutral"
)


_mp, _raw_motifs, _motifs_v12_l40 = motifsalphabet(SWC[:,12], 40, 25; r=_r, th=5);
__motif__v12_l40_relbow_right_reentering = _motifs_v12_l40[[3,5,6,13,19]]

__var__v12_l40_relbow_right_reentering = VariableDistance(12,
    __motif__v12_l40_relbow_right_reentering,
    distance=expdistance,
    featurename="Behind⋅Front"
)

############################################################################################
# assembly
############################################################################################

allmotifs = [
    __motif__v7_l10_lelbow_reentrant,
    __motif__v7_l10_lelbow_left,
    __motif__v7_l40_lelbow_left_reen_left,

    __motif__v10_l10_relbow_reentrant,
    __motif__v10_l10_relbow_right,
    __motif__v10_l40_relbow_right_reen_right,
    __motif__v10_l40_relbow_reen_right_reen,

    __motif__v8_l10_lelbow_ascend,
    __motif__v8_l10_lelbow_descending,
    __motif__v8_l40_lelbow_ascending,
    __motif__v8_l40_lelbow_descending,

    __motif__v11_l10_relbow_descend,
    __motif__v11_l10_relbow_ascend,
    __motif__v11_l40_relbow_longdescend,
    __motif__v11_l40_relbow_longascend,

    __motif__v9_l10_lelbow_neutral,
    __motif__v9_l10_lelbow_left,
    __motif__v9_l40_lelbow_left_neutral,

    __motif__v12_l10_relbow_right,
    __motif__v12_l10_relbow_neutral,
    __motif__v12_l40_relbow_right_reentering,
]

variabledistances = [
    __var__v7_l10_lelbow_reentrant,
    __var__v7_l10_lelbow_left,
    __var__v7_l40_lelbow_left_reen_left,

    __var__v10_l10_relbow_reentrant,
    __var__v10_l10_relbow_left,
    __var__v10_l40_relbow_right_reen_right,

    __var__v8_l10_lelbow_ascend,
    __var__v8_l10_lelbow_descending,
    __var__v8_l40_lelbow_ascending,
    __var__v8_l40_lelbow_descending,

    __var__v11_l10_relbow_descend,
    __var__v11_l10_relbow_ascend,
    __var__v11_l40_relbow_longdescend,
    __var__v11_l40_relbow_longascend,

    __var__v9_l10_lelbow_neutral,
    __var__v9_l10_lelbow_left,
    __var__v9_l40_lelbow_left_neutral,

    __var__v12_l10_relbow_right,
    __var__v12_l10_relbow_neutral,
    __var__v12_l40_relbow_right_reentering,
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v7_l10_lelbow_reentrant, <, _r)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_left, <, _r)),
    Atom(ScalarCondition(__var__v7_l40_lelbow_left_reen_left, <, _r)),

    Atom(ScalarCondition(__var__v10_l10_relbow_reentrant, <, _r)),
    Atom(ScalarCondition(__var__v10_l10_relbow_left, <, _r)),
    Atom(ScalarCondition(__var__v10_l40_relbow_right_reen_right, <, _r)),

    Atom(ScalarCondition(__var__v8_l10_lelbow_ascend, <, _r)),
    Atom(ScalarCondition(__var__v8_l10_lelbow_descending, <, _r)),
    Atom(ScalarCondition(__var__v8_l40_lelbow_ascending, <, _r)),
    Atom(ScalarCondition(__var__v8_l40_lelbow_descending, <, _r)),

    Atom(ScalarCondition(__var__v11_l10_relbow_descend, <, _r)),
    Atom(ScalarCondition(__var__v11_l10_relbow_ascend, <, _r)),
    Atom(ScalarCondition(__var__v11_l40_relbow_longdescend, <, _r)),
    Atom(ScalarCondition(__var__v11_l40_relbow_longascend, <, _r)),

    Atom(ScalarCondition(__var__v9_l10_lelbow_neutral, <, _r)),
    Atom(ScalarCondition(__var__v9_l10_lelbow_left, <, _r)),
    Atom(ScalarCondition(__var__v9_l40_lelbow_left_neutral, <, _r)),

    Atom(ScalarCondition(__var__v12_l10_relbow_right, <, _r)),
    Atom(ScalarCondition(__var__v12_l10_relbow_neutral, <, _r)),
    Atom(ScalarCondition(__var__v12_l40_relbow_right_reentering, <, _r)),
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

_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [
    (gconfidence, 0.1, 0.1),
    (glift, 0.0, 0.0),
    (dimensional_glift, 0.0, 0.0)
]

logiset = scalarlogiset(SWC, variabledistances)

miner = Miner(
    logiset,
    miningalgo,
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
