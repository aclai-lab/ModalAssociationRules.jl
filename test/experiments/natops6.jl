# README: see matrix-profile.jl

LWC = X[151:180, :]

############################################################################################
# hand x: left (1) and right (4)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v1_l10 = motifsalphabet(LWC[:,1], 10, 5; r=10, th=1);
__motif__v1_l10_lhand_inside = _motifs_v1_l10[4]
__motif__v1_l10_lhand_neutral = _motifs_v1_l10[1]

__var__v1_l10_lhand_inside = VariableDistance(1,
    __motif__v1_l10_lhand_inside,
    distance=x -> _mydistance(x, __motif__v1_l10_lhand_inside),
    featurename="Inside"
)
__var__v1_l10_lhand_neutral = VariableDistance(1,
    __motif__v1_l10_lhand_neutral,
    distance=x -> _mydistance(x, __motif__v1_l10_lhand_neutral),
    featurename="Neutral"
)

# handpicked motif
__motif__v1_l20_lhand_inside_neutral = LWC[1,1][13:32]

__var__v1_l20_lhand_inside_neutral = VariableDistance(1,
    __motif__v1_l20_lhand_inside_neutral,
    distance=x -> _mydistance(x, __motif__v1_l20_lhand_inside_neutral),
    featurename="Inside⋅Neutral"
)


## Right
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(LWC[:,4], 10, 5; r=10, th=1);
__motif__v1_l10_rhand_out = _motifs_v4_l10[3]
__motif__v1_l10_rhand_inside = _motifs_v4_l10[2]

__var__v1_l10_rhand_out = VariableDistance(4,
    __motif__v1_l10_rhand_out,
    distance=x -> _mydistance(x, __motif__v1_l10_rhand_out),
    featurename="Out"
)
__var__v1_l10_rhand_inside = VariableDistance(4,
    __motif__v1_l10_rhand_inside,
    distance=x -> _mydistance(x, __motif__v1_l10_rhand_inside),
    featurename="Inside"
)

# handpicked motif
__motif__v1_l30_rhand_prepare_relax = LWC[1,4][10:39]

__var__v1_l30_rhand_prepare_relax = VariableDistance(4,
    __motif__v1_l30_rhand_prepare_relax,
    distance=x -> _mydistance(x, __motif__v1_l30_rhand_prepare_relax),
    featurename="Entering⋅Out"
)


############################################################################################
# hand y: left (2) and right (5)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v2_l10 = motifsalphabet(LWC[:,2], 10, 5; r=10, th=1);
__motif__v2_l10_lhand_ascending = _motifs_v2_l10[4]
__motif__v2_l10_lhand_descending = _motifs_v2_l10[2]

__var__v2_l10_lhand_ascending = VariableDistance(2,
    __motif__v2_l10_lhand_ascending,
    distance=x -> _mydistance(x, __motif__v2_l10_lhand_ascending),
    featurename="Ascending"
)
__var__v2_l10_lhand_descending = VariableDistance(2,
    __motif__v2_l10_lhand_descending,
    distance=x -> _mydistance(x, __motif__v2_l10_lhand_descending),
    featurename="Neutral"
)

# handpicked motif
__motif__v2_l20_lhand_ascending_descending = LWC[1,2][13:32]

__var__v2_l20_lhand_ascending_descending = VariableDistance(2,
    __motif__v2_l20_lhand_ascending_descending,
    distance=x -> _mydistance(x, __motif__v2_l20_lhand_ascending_descending),
    featurename="Ascending⋅Descending"
)


## Right
_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(LWC[:,5], 10, 5; r=10, th=1);
__motif__v5_l10_rhand_ascending = _motifs_v5_l10[1]
__motif__v5_l10_rhand_descending = _motifs_v5_l10[5]

__var__v5_l10_rhand_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_ascending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_ascending),
    featurename="Ascending"
)
__var__v5_l10_rhand_descending = VariableDistance(5,
    __motif__v5_l10_rhand_descending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_descending),
    featurename="Descending"
)

# handpicked motif
__motif__v5_l20_rhand_ascdesc = LWC[1,5][10:29]

__var__v5_l20_rhand_ascdesc = VariableDistance(4,
    __motif__v5_l20_rhand_ascdesc,
    distance=x -> _mydistance(x, __motif__v5_l20_rhand_ascdesc),
    featurename="Ascending⋅Descending"
)


############################################################################################
# hand z: left (3) and right (6)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v3_l10 = motifsalphabet(LWC[:,3], 10, 5; r=10, th=1);
__motif__v3_l10_lhand_front = _motifs_v3_l10[5]
__motif__v3_l10_lhand_entering = _motifs_v3_l10[2]

__var__v3_l10_lhand_front = VariableDistance(3,
    __motif__v3_l10_lhand_front,
    distance=x -> _mydistance(x, __motif__v3_l10_lhand_front),
    featurename="Front"
)
__var__v3_l10_lhand_entering = VariableDistance(3,
    __motif__v3_l10_lhand_entering,
    distance=x -> _mydistance(x, __motif__v3_l10_lhand_entering),
    featurename="Entering"
)

# handpicked motif
__motif__v3_l40_lhand_ascending_descending = LWC[1,3][10:40]

__var__v3_l40_lhand_ascending_descending = VariableDistance(3,
    __motif__v3_l40_lhand_ascending_descending,
    distance=x -> _mydistance(x, __motif__v3_l40_lhand_ascending_descending),
    featurename="Ascending⋅Descending"
)


## Right
_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(LWC[:,5], 10, 5; r=10, th=1);
__motif__v5_l10_rhand_ascending = _motifs_v4_l10[1]
__motif__v5_l10_rhand_descending = _motifs_v4_l10[5]

__var__v5_l10_rhand_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_ascending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_ascending),
    featurename="Ascending"
)
__var__v5_l10_rhand_descending = VariableDistance(5,
    __motif__v5_l10_rhand_descending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_descending),
    featurename="Descending"
)

# handpicked motif
__motif__v5_l20_rhand_frontal_arc = LWC[1,5][10:29]

__var__v5_l20_rhand_frontal_arc = VariableDistance(5,
    __motif__v5_l20_rhand_frontal_arc,
    distance=x -> _mydistance(x, __motif__v5_l20_rhand_frontal_arc),
    featurename="Front⋅Arc"
)


############################################################################################
# elbow x: left (7) and right (9)
############################################################################################

## Left
_mp, _raw_motifs, _motifs_v7_l10 = motifsalphabet(LWC[:,7], 10, 5; r=10, th=1);
__motif__v7_l10_lelbow_entering = _motifs_v7_l10[2]
__motif__v7_l10_lelbow_neutral = _motifs_v7_l10[4]

__var__v7_l10_lelbow_entering = VariableDistance(7,
    __motif__v7_l10_lelbow_entering,
    distance=x -> _mydistance(x, __motif__v7_l10_lelbow_entering),
    featurename="Entering"
)
__var__v7_l10_lelbow_neutral = VariableDistance(7,
    __motif__v7_l10_lelbow_neutral,
    distance=x -> _mydistance(x, __motif__v7_l10_lelbow_neutral),
    featurename="Neutral"
)

# handpicked motif
__motif__v7_l20_lelbow_entering_neutral = LWC[1,7][13:32]

__var__v7_l20_lelbow_entering_neutral = VariableDistance(3,
    __motif__v7_l20_lelbow_entering_neutral,
    distance=x -> _mydistance(x, __motif__v7_l20_lelbow_entering_neutral),
    featurename="Entering⋅Neutral"
)


## Right
_mp, _raw_motifs, _motifs_v9_l10 = motifsalphabet(LWC[:,9], 10, 5; r=10, th=5);
__motif__v9_l10_relbow_enter = _motifs_v9_l10[2]
__motif__v9_l10_relbow_exit = _motifs_v9_l10[5]

__var__v9_l10_relbow_enter = VariableDistance(9,
    __motif__v9_l10_relbow_enter,
    distance=x -> _mydistance(x, __motif__v9_l10_relbow_enter),
    featurename="Enter"
)
__var__v9_l10_relbow_exit = VariableDistance(9,
    __motif__v9_l10_relbow_exit,
    distance=x -> _mydistance(x, __motif__v9_l10_relbow_exit),
    featurename="Exit"
)

# handpicked motif
__motif__v9_l20_relbow_enterexit = LWC[1,9][13:32]

__var__v9_l20_relbow_enterexit = VariableDistance(5,
    __motif__v9_l20_relbow_enterexit,
    distance=x -> _mydistance(x, __motif__v9_l20_relbow_enterexit),
    featurename="Enter⋅Exit"
)

############################################################################################


# TODO: elbows yz;
# maybe wrists are interesting too because of their rotation


############################################################################################
# assembly
############################################################################################

allmotifs = [
    # put motifs here
    __motif__v1_l10_lhand_inside,
    __motif__v1_l10_lhand_neutral,
    __motif__v1_l20_lhand_inside_neutral,
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
    __motif__v3_l10_lhand_entering,
    __motif__v3_l40_lhand_ascending_descending,
    __motif__v5_l10_rhand_ascending,
    __motif__v5_l10_rhand_descending,
    __motif__v5_l20_rhand_frontal_arc,
    __motif__v7_l10_lelbow_entering,
    __motif__v7_l10_lelbow_neutral,
    __motif__v7_l20_lelbow_entering_neutral,
    __motif__v9_l10_relbow_enter,
    __motif__v9_l10_relbow_exit,
    __motif__v9_l20_relbow_enterexit
]

variabledistances = [
    # put variables here
    __var__v1_l10_lhand_inside,
    __var__v1_l10_lhand_neutral,
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
    __var__v3_l10_lhand_entering,
    __var__v3_l40_lhand_ascending_descending,
    __var__v5_l10_rhand_ascending,
    __var__v5_l10_rhand_descending,
    __var__v5_l20_rhand_frontal_arc,
    __var__v7_l10_lelbow_entering,
    __var__v7_l10_lelbow_neutral,
    __var__v7_l20_lelbow_entering_neutral,
    __var__v9_l10_relbow_enter,
    __var__v9_l10_relbow_exit,
    __var__v9_l20_relbow_enterexit
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v1_l10_lhand_inside, <, 2.0)),
    Atom(ScalarCondition(__var__v1_l10_lhand_neutral, <, 2.0)),
    Atom(ScalarCondition(__var__v1_l20_lhand_inside_neutral, <, 2.0)),
    Atom(ScalarCondition(__var__v1_l10_rhand_out, <, 2.0)),
    Atom(ScalarCondition(__var__v1_l10_rhand_inside, <, 2.0)),
    Atom(ScalarCondition(__var__v1_l30_rhand_prepare_relax, <, 2.0)),
    Atom(ScalarCondition(__var__v2_l10_lhand_ascending, <, 2.0)),
    Atom(ScalarCondition(__var__v2_l10_lhand_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v2_l20_lhand_ascending_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_ascending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l20_rhand_ascdesc, <, 2.0)),
    Atom(ScalarCondition(__var__v3_l10_lhand_front, <, 2.0)),
    Atom(ScalarCondition(__var__v3_l10_lhand_entering, <, 2.0)),
    Atom(ScalarCondition(__var__v3_l40_lhand_ascending_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_ascending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l20_rhand_frontal_arc, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_entering, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_neutral, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l20_lelbow_entering_neutral, <, 2.0)),
    Atom(ScalarCondition(__var__v9_l10_relbow_enter, <, 2.0)),
    Atom(ScalarCondition(__var__v9_l10_relbow_exit, <, 2.0)),
    Atom(ScalarCondition(__var__v9_l20_relbow_enterexit, <, 2.0)),
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
        diamond(IA_B).(propositional_atoms),
        diamond(IA_E).(propositional_atoms),
        diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)

_itemsetmeasures = [(dimensional_gsupport, 0.5, 0.5)]
_rulemeasures = [
    (gconfidence, 0.3, 0.3),
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
        isdimensionally_coherent_itemset(),
        islimited_length_itemset(
            maxlength=5
        ),
    ],
    arule_mining_policies=Function[
        islimited_length_arule(
            antecedent_maxlength=4,
            consequent_maxlength=1
        ),
        isanchored_arule(),
        isheterogeneous_arule(
            antecedent_nrepetitions=1,
            consequent_nrepetitions=0
        ),
    ]
)
