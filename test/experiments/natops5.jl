
# this is identical to Experiment #2, but the instances are different
FWC = X[121:150, :]

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

_itemsetmeasures = [(dimensional_gsupport, 0.5, 0.5)]
_rulemeasures = [
    (gconfidence, 0.3, 0.3),
    (glift, 0.0, 0.0)
]

logiset = scalarlogiset(FWC, variabledistances)

fpgrowth_miner = Miner(
    logiset,
    fpgrowth,
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
