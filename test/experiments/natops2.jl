
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
__motif__v4_l40_rhand_x_right_align_still = _motifs_v4_l40[1]

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
        diamond(IA_D).(propositional_atoms),
        diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)

_itemsetmeasures = [(dimensional_gsupport, 0.3, 0.3)]
_rulemeasures = [(dimensional_gconfidence, 0.3, 0.3)]

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
