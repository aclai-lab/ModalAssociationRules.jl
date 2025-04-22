# README: see experiments-driver.jl

ACC = X[31:60, :]
r_4 = 1
r_5 = 1
r_25 = 1

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(ACC[:,4], 10, 20; r=r_4, th=2);
__motif__v4_l10_rhand_x_right = _motifs_v4_l10[[1,2,5,9,13]]
__motif__v4_l10_rhand_x_align = _motifs_v4_l10[[4,10,12,15,19]]

__var__v4_l10_rhand_x_right = VariableDistance(4,
    __motif__v4_l10_rhand_x_right,
    distance=expdistance,
    featurename="Right"
)
__var__v4_l10_rhand_x_align = VariableDistance(4,
    __motif__v4_l10_rhand_x_align,
    distance=expdistance,
    featurename="Align"
)


_mp, _raw_motifs, _motifs_v4_l40 = motifsalphabet(ACC[:,4], 40, 25; r=r_4, th=5);
__motif__v4_l40_rhand_x_right_align_still = _motifs_v4_l40[[17,24]]

__var__v4_l40_rhand_x_right_align_still = VariableDistance(4,
    __motif__v4_l40_rhand_x_right_align_still,
    distance=expdistance,
    featurename="Right⋅Align"
)


# right hand Y variable generations

_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(ACC[:,5], 10, 25; r=r_5, th=5);
__motif__v5_l10_rhand_y_ascending = _motifs_v5_l10[[1,7,8,9,11,16]]
__motif__v5_l10_rhand_y_descending = _motifs_v5_l10[[2,3,5,6,19,24]]

__var__v5_l10_rhand_y_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_y_ascending,
    distance=expdistance,
    featurename="Ascending"
)
__var__v5_l10_rhand_y_descending = VariableDistance(5,
    __motif__v5_l10_rhand_y_descending,
    distance=expdistance,
    featurename="Descending"
)


_mp, _raw_motifs, _motifs_v5_l40 = motifsalphabet(ACC[:,5], 40, 25; r=r_5, th=2);
__motif__v5_l40_rhand_y_ascending_inverting = _motifs_v5_l40[[22,4,19]]
__motif__v5_l30_rhand_y_inverting_descending = _motifs_v5_l40[[6,8,25]]

__var__v5_l40_rhand_y_ascinvert = VariableDistance(5,
    __motif__v5_l40_rhand_y_ascending_inverting,
    distance=expdistance,
    featurename="Ascending⋅Inverting"
)

__var__v5_l30_rhand_y_invertdesc = VariableDistance(5,
    __motif__v5_l30_rhand_y_inverting_descending,
    distance=expdistance,
    featurename="Inverting⋅Descending"
)


# right thumb Y (actually, r-finger-tips-Y minus r-thumb-Y to consider thumb orientation)

_mp, _raw_motifs, _motifs_v25_l10 = motifsalphabet(ACC[:,25], 10, 25; r=r_25, th=5);
__motif__v25_l10_rhand_thumb_up = _motifs_v25_l10[[7,9,12,18,19]]
__motif__v25_l10_rhand_thumb_down = _motifs_v25_l10[[6,10,20,22,23,25]]

__var__v25_l10_rhand_thumb_up = VariableDistance(25,
    __motif__v25_l10_rhand_thumb_up,
    distance=expdistance,
    featurename="Up"
)
__var__v25_l10_rhand_thumb_down = VariableDistance(25,
    __motif__v25_l10_rhand_thumb_down,
    distance=expdistance,
    featurename="Down"
)

_mp, _raw_motifs, _motifs_v25_l20 = motifsalphabet(ACC[:,25], 20, 25; r=r_25, th=10);
__motif__v25_l20_rhand_thumb_inversion = _motifs_v25_l20[5]

# this is hard to capture using motifs suggestion, but could be if using an ad-hoc GUI tool
# __var__v25_l20_rhand_thumb_inversion = VariableDistance(25,
#     __motif__v25_l20_rhand_thumb_inversion,
#     distance=expdistance,
#     featurename="Inversion"
# )

allmotifs = [
    __motif__v4_l10_rhand_x_right,
    __motif__v4_l10_rhand_x_align,
    __motif__v4_l40_rhand_x_right_align_still,

    __motif__v5_l10_rhand_y_ascending,
    __motif__v5_l10_rhand_y_descending,
    __motif__v5_l40_rhand_y_ascending_inverting,
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
    __var__v5_l40_rhand_y_ascinvert,
    __var__v5_l30_rhand_y_invertdesc,

    __var__v25_l10_rhand_thumb_up,
    __var__v25_l10_rhand_thumb_down,
    # __var__v25_l20_rhand_thumb_inversion
];

propositional_atoms = [
    # bigger intervals' threshold can be relaxed
    Atom(ScalarCondition(__var__v4_l10_rhand_x_right, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l10_rhand_x_align, <, 2.0)),
    Atom(ScalarCondition(__var__v4_l40_rhand_x_right_align_still, <, 4.0)),

    Atom(ScalarCondition(__var__v5_l10_rhand_y_ascending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l10_rhand_y_descending, <, 2.0)),
    Atom(ScalarCondition(__var__v5_l40_rhand_y_ascinvert, <, 4.0)),
    Atom(ScalarCondition(__var__v5_l30_rhand_y_invertdesc, <, 4.0)),

    Atom(ScalarCondition(__var__v25_l10_rhand_thumb_up, <, 1.0)),
    Atom(ScalarCondition(__var__v25_l10_rhand_thumb_down, <, 1.0)),
    # Atom(ScalarCondition(__var__v25_l20_rhand_thumb_inversion, <, 2.0))
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
        # diamond(IA_L).(propositional_atoms),
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

logiset = scalarlogiset(ACC, variabledistances)

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
