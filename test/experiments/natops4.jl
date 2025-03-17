
SWC = X[91:120, :]


# Left (7) and right (10) elbow X

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
    featurename="Left⋅Reentring⋅Left"
)

__var__v7_l30_lelbow_left_reen_left = VariableDistance(7,
    __motif__v7_l30_lelbow_reen_left_reen,
    distance=x -> _mydistance(x, __motif__v7_l30_lelbow_reen_left_reen),
    featurename="Reentring⋅Left⋅Reentring"
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
    featurename="Right⋅Reentring⋅Right"
)

__var__v10_l30_relbow_right_reen_right = VariableDistance(10,
__motif__v10_l30_relbow_reen_right_reen,
    distance=x -> _mydistance(x, __motif__v10_l30_relbow_reen_right_reen),
    featurename="Reentring⋅Right⋅Reentring"
)


allmotifs = [
    __motif__v7_l10_lelbow_reentrant,
    __motif__v7_l10_lelbow_left,
    __motif__v7_l30_lelbow_left_reen_left,
    __motif__v7_l30_lelbow_reen_left_reen,

    __motif__v10_l10_relbow_reentrant,
    __motif__v10_l10_relbow_right,
    __motif__v10_l30_relbow_right_reen_right,
    __motif__v10_l30_relbow_reen_right_reen,
]

variabledistances = [
    __var__v7_l10_lelbow_reentrant,
    __var__v7_l10_lelbow_left,
    __var__v7_l30_lelbow_left_reen_left,
    __var__v7_l30_lelbow_left_reen_left,

    __var__v10_l10_relbow_reentrant,
    __var__v10_l10_relbow_left,
    __var__v10_l30_relbow_right_reen_right,
    __var__v10_l30_relbow_right_reen_right,
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v7_l10_lelbow_reentrant, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l10_lelbow_left, <, 2.0)),
    Atom(ScalarCondition(__var__v7_l30_lelbow_left_reen_left, <, 4.0)),
    Atom(ScalarCondition(__var__v7_l30_lelbow_left_reen_left, <, 4.0)),

    Atom(ScalarCondition(__var__v10_l10_relbow_reentrant, <, 2.0)),
    Atom(ScalarCondition(__var__v10_l10_relbow_left, <, 4.0)),
    Atom(ScalarCondition(__var__v10_l30_relbow_right_reen_right, <, 4.0)),
    Atom(ScalarCondition(__var__v10_l30_relbow_right_reen_right, <, 4.0)),
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
