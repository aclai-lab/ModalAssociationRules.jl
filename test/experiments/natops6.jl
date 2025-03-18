
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
__motif__v1_l30_lhand_inside_neutral = LWC[1,1][13:33]

__var__v1_l30_lhand_inside_neutral = VariableDistance(1,
    __motif__v1_l30_lhand_inside_neutral,
    distance=x -> _mydistance(x, __motif__v1_l30_lhand_inside_neutral),
    featurename="Inside⋅Neutral"
)


## Right
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(LWC[:,4], 10, 5; r=10, th=1);
__motif__v1_l10_rhand_out = _motifs_v1_l10[3]
__motif__v1_l10_rhand_inside = _motifs_v1_l10[2]

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
__motif__v1_l30_rhand_prepare_relax = LWC[1,4][10:40]

__var__v1_l30_rhand_prepare_relax = VariableDistance(4,
    __motif__v1_l30_rhand_prepare_relax,
    distance=x -> _mydistance(x, __motif__v1_l30_rhand_prepare_relax),
    featurename="Entering⋅Out"
)

# TODO: hands y, hands z, elbows xyz;
# maybe wrists are interesting too because of their rotation


############################################################################################
# assembly
############################################################################################

allmotifs = [
    # put motifs here
]

variabledistances = [
    # put variables here
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v7_l10_lhand_ascending, <, 2.0)),
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

_itemsetmeasures = [(dimensional_gsupport, 0.5, 0.5)]
_rulemeasures = [(dimensional_gconfidence, 0.7, 0.5)]


logiset = scalarlogiset(LWC, variabledistances)

apriori_miner = Miner(
    logiset,
    apriori,
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
