# README: see experiments-driver.jl

LWC = X[151:180, :]
_r = 1

############################################################################################
# hand x: left (1) and right (4)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v1_l10 = motifsalphabet(LWC[:,1], 10, 25; r=_r, th=1);
__motif__v1_l10_lhand_inside = _motifs_v1_l10[[1,7,10]]
__motif__v1_l10_lhand_outside = _motifs_v1_l10[[4,5,6,9]]

__var__v1_l10_lhand_inside = VariableDistance(1,
    __motif__v1_l10_lhand_inside,
    distance=expdistance,
    featurename="Inside"
)
__var__v1_l10_lhand_outside = VariableDistance(1,
    __motif__v1_l10_lhand_outside,
    distance=expdistance,
    featurename="Outside"
)

# handpicked motif
__motif__v1_l20_lhand_inside_outside = LWC[1,1][13:32] |> _normalize

__var__v1_l20_lhand_inside_neutral = VariableDistance(1,
    __motif__v1_l20_lhand_inside_outside,
    distance=expdistance,
    featurename="Inside⋅Neutral"
)


## Right
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(LWC[:,4], 10, 25; r=_r, th=1);
__motif__v1_l10_rhand_out = _motifs_v4_l10[[1,3,5,6,9]]
__motif__v1_l10_rhand_inside = _motifs_v4_l10[[2,4,7,8]]

__var__v1_l10_rhand_out = VariableDistance(4,
    __motif__v1_l10_rhand_out,
    distance=expdistance,
    featurename="Out"
)
__var__v1_l10_rhand_inside = VariableDistance(4,
    __motif__v1_l10_rhand_inside,
    distance=expdistance,
    featurename="Inside"
)

# handpicked motif
__motif__v1_l30_rhand_prepare_relax = LWC[1,4][10:39] |> _normalize

__var__v1_l30_rhand_prepare_relax = VariableDistance(4,
    __motif__v1_l30_rhand_prepare_relax,
    distance=expdistance,
    featurename="Behind⋅Out"
)


############################################################################################
# hand y: left (2) and right (5)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v2_l10 = motifsalphabet(LWC[:,2], 10, 25; r=_r, th=1);
__motif__v2_l10_lhand_ascending = _motifs_v2_l10[[1,4,6,7,9,10,11]]
__motif__v2_l10_lhand_descending = _motifs_v2_l10[[2,5,8,12]]

__var__v2_l10_lhand_ascending = VariableDistance(2,
    __motif__v2_l10_lhand_ascending,
    distance=expdistance,
    featurename="Ascending"
)
__var__v2_l10_lhand_descending = VariableDistance(2,
    __motif__v2_l10_lhand_descending,
    distance=expdistance,
    featurename="Neutral"
)

# handpicked motif
__motif__v2_l20_lhand_ascending_descending = LWC[1,2][13:32] |> _normalize

__var__v2_l20_lhand_ascending_descending = VariableDistance(2,
    __motif__v2_l20_lhand_ascending_descending,
    distance=expdistance,
    featurename="Ascending⋅Descending"
)


## Right
_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(LWC[:,5], 10, 25; r=_r, th=1);
__motif__v5_l10_rhand_ascending = _motifs_v5_l10[[1,2,3,4,6,9]]
__motif__v5_l10_rhand_descending = _motifs_v5_l10[[5,7,8,10,11]]

__var__v5_l10_rhand_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_ascending,
    distance=expdistance,
    featurename="Ascending"
)
__var__v5_l10_rhand_descending = VariableDistance(5,
    __motif__v5_l10_rhand_descending,
    distance=expdistance,
    featurename="Descending"
)

# handpicked motif
__motif__v5_l20_rhand_ascdesc = LWC[1,5][10:29] |> _normalize

__var__v5_l20_rhand_ascdesc = VariableDistance(4,
    __motif__v5_l20_rhand_ascdesc,
    distance=expdistance,
    featurename="Ascending⋅Descending"
)


############################################################################################
# hand z: left (3) and right (6)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v3_l10 = motifsalphabet(LWC[:,3], 10, 35; r=_r, th=5);
__motif__v3_l10_lhand_front = _motifs_v3_l10[[27,28,29,30,31,32,33,35]]
__motif__v3_l10_lhand_behind = _motifs_v3_l10[[2,4,6,8,9,10,13,34]]

__var__v3_l10_lhand_front = VariableDistance(3,
    __motif__v3_l10_lhand_front,
    distance=expdistance,
    featurename="Front"
)
__var__v3_l10_lhand_behind = VariableDistance(3,
    __motif__v3_l10_lhand_behind,
    distance=expdistance,
    featurename="Behind"
)

# handpicked motif
__motif__v3_l40_lhand_ascending_descending = LWC[1,3][10:40] |> _normalize

__var__v3_l40_lhand_ascending_descending = VariableDistance(3,
    __motif__v3_l40_lhand_ascending_descending,
    distance=expdistance,
    featurename="Ascending⋅Descending"
)


## Right
_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(LWC[:,5], 10, 35; r=_r, th=5);
__motif__v5_l10_rhand_ascending = _motifs_v5_l10[[1,2,3,4,6,9,11,12,13]]
__motif__v5_l10_rhand_descending = _motifs_v5_l10[[5,7,8,10,14]]

__var__v5_l10_rhand_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_ascending,
    distance=expdistance,
    featurename="Front"
)
__var__v5_l10_rhand_descending = VariableDistance(5,
    __motif__v5_l10_rhand_descending,
    distance=expdistance,
    featurename="Behind"
)

# handpicked motif
__motif__v5_l20_rhand_frontal_arc = LWC[1,5][10:29] |> _normalize

__var__v5_l20_rhand_frontal_arc = VariableDistance(5,
    __motif__v5_l20_rhand_frontal_arc,
    distance=expdistance,
    featurename="Front⋅Arc"
)


############################################################################################
# elbow x: left (7) and right (9)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v7_l10 = motifsalphabet(LWC[:,7], 10, 25; r=_r, th=5);
__motif__v7_l10_lelbow_left = _motifs_v7_l10[[5,11,19]]
__motif__v7_l10_lelbow_neutral = _motifs_v7_l10[[1,3,6,7,9]]

__var__v7_l10_lelbow_behind = VariableDistance(7,
    __motif__v7_l10_lelbow_left,
    distance=expdistance,
    featurename="Left"
)
__var__v7_l10_lelbow_neutral = VariableDistance(7,
    __motif__v7_l10_lelbow_neutral,
    distance=expdistance,
    featurename="Neutral"
)

# handpicked motif
__motif__v7_l20_lelbow_left_neutral = LWC[1,7][13:32] |> _normalize

__var__v7_l20_lelbow_behind_neutral = VariableDistance(3,
    __motif__v7_l20_lelbow_left_neutral,
    distance=expdistance,
    featurename="Left⋅Neutral"
)


## Right
_mp, _raw_motifs, _motifs_v9_l10 = motifsalphabet(LWC[:,9], 10, 25; r=_r, th=10);
__motif__v9_l10_relbow_right = _motifs_v9_l10[[6,7,16,18,19]]
__motif__v9_l10_relbow_neutral = _motifs_v9_l10[[2,3,15,17]]

__var__v9_l10_relbow_enter = VariableDistance(9,
    __motif__v9_l10_relbow_right,
    distance=expdistance,
    featurename="Right"
)
__var__v9_l10_relbow_neutral = VariableDistance(9,
    __motif__v9_l10_relbow_neutral,
    distance=expdistance,
    featurename="Neutral"
)

# handpicked motif
__motif__v9_l20_relbow_right_neutral = LWC[1,9][13:32] |> _normalize

__var__v9_l20_relbow_right_neutral = VariableDistance(5,
    __motif__v9_l20_relbow_right_neutral,
    distance=expdistance,
    featurename="Right⋅Neutral"
)


############################################################################################
# assembly
############################################################################################

allmotifs = [
    # put motifs here
    __motif__v1_l10_lhand_inside,
    __motif__v1_l10_lhand_outside,
    __motif__v1_l20_lhand_inside_outside,
    __motif__v1_l10_rhand_out,
    __motif__v1_l10_rhand_inside,
    __motif__v1_l30_rhand_prepare_relax,
    __motif__v2_l10_lhand_ascending,
    __motif__v2_l10_lhand_descending,
    __motif__v2_l20_lhand_ascending_descending,
    __motif__v5_l10_rhand_ascending,
    __motif__v5_l10_rhand_descending,
    __motif__v5_l20_rhand_ascdesc,
    __motif__v3_l10_lhand_front,
    __motif__v3_l10_lhand_behind,
    __motif__v3_l40_lhand_ascending_descending,
    __motif__v5_l10_rhand_ascending,
    __motif__v5_l10_rhand_descending,
    __motif__v5_l20_rhand_frontal_arc,
    __motif__v7_l10_lelbow_left,
    __motif__v7_l10_lelbow_neutral,
    __motif__v7_l20_lelbow_left_neutral,
    __motif__v9_l10_relbow_right,
    __motif__v9_l10_relbow_neutral,
    __motif__v9_l20_relbow_right_neutral
]

variabledistances = [
    # put variables here
    __var__v1_l10_lhand_inside,
    __var__v1_l10_lhand_outside,
    __var__v1_l20_lhand_inside_neutral,
    __var__v1_l10_rhand_out,
    __var__v1_l10_rhand_inside,
    __var__v1_l30_rhand_prepare_relax,
    __var__v2_l10_lhand_ascending,
    __var__v2_l10_lhand_descending,
    __var__v2_l20_lhand_ascending_descending,
    __var__v5_l10_rhand_ascending,
    __var__v5_l10_rhand_descending,
    __var__v5_l20_rhand_ascdesc,
    __var__v3_l10_lhand_front,
    __var__v3_l10_lhand_behind,
    __var__v3_l40_lhand_ascending_descending,
    __var__v5_l10_rhand_ascending,
    __var__v5_l10_rhand_descending,
    __var__v5_l20_rhand_frontal_arc,
    __var__v7_l10_lelbow_behind,
    __var__v7_l10_lelbow_neutral,
    __var__v7_l20_lelbow_behind_neutral,
    __var__v9_l10_relbow_enter,
    __var__v9_l10_relbow_neutral,
    __var__v9_l20_relbow_right_neutral
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v1_l10_lhand_inside, <, _r)),
    Atom(ScalarCondition(__var__v1_l10_lhand_outside, <, _r)),
    Atom(ScalarCondition(__var__v1_l20_lhand_inside_neutral, <, _r)),
    Atom(ScalarCondition(__var__v1_l10_rhand_out, <, _r)),
    Atom(ScalarCondition(__var__v1_l10_rhand_inside, <, _r)),
    Atom(ScalarCondition(__var__v1_l30_rhand_prepare_relax, <, _r)),
    Atom(ScalarCondition(__var__v2_l10_lhand_ascending, <, _r)),
    Atom(ScalarCondition(__var__v2_l10_lhand_descending, <, _r)),
    Atom(ScalarCondition(__var__v2_l20_lhand_ascending_descending, <, _r)),
    Atom(ScalarCondition(__var__v5_l10_rhand_ascending, <, _r)),
    Atom(ScalarCondition(__var__v5_l10_rhand_descending, <, _r)),
    Atom(ScalarCondition(__var__v5_l20_rhand_ascdesc, <, _r)),
    Atom(ScalarCondition(__var__v3_l10_lhand_front, <, _r)),
    Atom(ScalarCondition(__var__v3_l10_lhand_behind, <, _r)),
    Atom(ScalarCondition(__var__v3_l40_lhand_ascending_descending, <, _r)),
    Atom(ScalarCondition(__var__v5_l10_rhand_ascending, <, _r)),
    Atom(ScalarCondition(__var__v5_l10_rhand_descending, <, _r)),
    Atom(ScalarCondition(__var__v5_l20_rhand_frontal_arc, <, _r)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_behind, <, _r)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_neutral, <, _r)),
    Atom(ScalarCondition(__var__v7_l20_lelbow_behind_neutral, <, _r)),
    Atom(ScalarCondition(__var__v9_l10_relbow_enter, <, _r)),
    Atom(ScalarCondition(__var__v9_l10_relbow_neutral, <, _r)),
    Atom(ScalarCondition(__var__v9_l20_relbow_right_neutral, <, _r)),
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
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
    (glift, 0.0, 0.0)
]

logiset = scalarlogiset(LWC, variabledistances)

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
