# README: see experiments-driver.jl

# this is identical to Experiment #2, but the instances are different
FWC = X[121:150, :]

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

logiset = scalarlogiset(FWC, variabledistances)

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
