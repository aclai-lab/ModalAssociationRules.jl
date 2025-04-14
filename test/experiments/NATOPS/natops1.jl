# README: see matrix-profile.jl

# isolate "I have command class"
IHCC = X[1:30, :]

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(IHCC[:,4], 10, 5; r=5, th=2);
__motif__v4_l10_rhand_x_right = _motifs_v4_l10[3]
__motif__v4_l10_rhand_x_align = _motifs_v4_l10[5]

__var__v4_l10_rhand_x_right = VariableDistance(4,
    __motif__v4_l10_rhand_x_right,
    distance=x -> expdistance(x, __motif__v4_l10_rhand_x_right),
    featurename="Right"
)
__var__v4_l10_rhand_x_align = VariableDistance(4,
    __motif__v4_l10_rhand_x_align,
    distance=x -> expdistance(x, __motif__v4_l10_rhand_x_align),
    featurename="Align"
)


_mp, _raw_motifs, _motifs_v4_l40 = motifsalphabet(IHCC[:,4], 30, 10; r=5, th=0);
__motif__v4_l40_rhand_x_align_inverting_right = _motifs_v4_l40[8]

__var__v4_l40_rhand_x_align_inverting_right = VariableDistance(4,
    __motif__v4_l40_rhand_x_align_inverting_right,
    distance=x -> expdistance(x, __motif__v4_l40_rhand_x_align_inverting_right),
    featurename="Align⋅Right"
)


# right hand Y variable generations

_mp, _raw_motifs, _motifs_v5_l10 = motifsalphabet(IHCC[:,5], 10, 10; r=5, th=0);
__motif__v5_l10_rhand_y_ascending = _motifs_v5_l10[7]
__motif__v5_l10_rhand_y_descending = _motifs_v5_l10[2]

__var__v5_l10_rhand_y_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_y_ascending,
    distance=x -> expdistance(x, __motif__v5_l10_rhand_y_ascending),
    featurename="Ascending"
)
__var__v5_l10_rhand_y_descending = VariableDistance(5,
    __motif__v5_l10_rhand_y_descending,
    distance=x -> expdistance(x, __motif__v5_l10_rhand_y_descending),
    featurename="Descending"
)


_mp, _raw_motifs, _motifs_v5_l40 = motifsalphabet(IHCC[:,5], 40, 10; r=5, th=5);
__motif__v5_l40_rhand_y_ascdesc = _motifs_v5_l40[7]

__var__v5_l40_rhand_y_ascdesc = VariableDistance(5,
    __motif__v5_l40_rhand_y_ascdesc,
    distance=x -> expdistance(x, __motif__v5_l40_rhand_y_ascdesc),
    featurename="Ascending⋅Descending"
)

# right hand Z variable generation

_mp, _raw_motifs, _motifs_v6_l10 = motifsalphabet(IHCC[:,6], 10, 10; r=5, th=2);
__motif__v6_l10_rhand_z_away_front = _motifs_v6_l10[2]
__motif__v6_l10_rhand_z_closer_front = _motifs_v5_l10[6]


__var__v6_l10_rhand_z_away_front = VariableDistance(6,
    __motif__v6_l10_rhand_z_away_front,
    distance=x -> expdistance(x, __motif__v6_l10_rhand_z_away_front),
    featurename="AwayFront"
)

__var__v6_l10_rhand_z_closer_front = VariableDistance(6,
    __motif__v6_l10_rhand_z_closer_front,
    distance=x -> expdistance(x, __motif__v6_l10_rhand_z_closer_front),
    featurename="NeutralFront"
)

# variables assembly;
# insert your variables in variabledistances array,
# then adjust the _distance_threshold (which is equal for each ScalarCondition)
# and the meaningfulness measures thresholds.

allmotifs = [
    __motif__v4_l10_rhand_x_right,
    __motif__v4_l10_rhand_x_align,
    __motif__v4_l40_rhand_x_align_inverting_right,

    __motif__v5_l10_rhand_y_ascending,
    __motif__v5_l10_rhand_y_descending,
    __motif__v5_l40_rhand_y_ascdesc,

    __motif__v6_l10_rhand_z_away_front,
    __motif__v6_l10_rhand_z_closer_front,
]

variabledistances = [
    __var__v4_l10_rhand_x_right,
    __var__v4_l10_rhand_x_align,
    __var__v4_l40_rhand_x_align_inverting_right,

    __var__v5_l10_rhand_y_ascending,
    __var__v5_l10_rhand_y_descending,
    __var__v5_l40_rhand_y_ascdesc,

    __var__v6_l10_rhand_z_away_front,
    __var__v6_l10_rhand_z_closer_front,
];

propositional_atoms = [
    Atom(ScalarCondition(
            __var__v4_l10_rhand_x_right, <, round(suggest_threshold(
                __motif__v4_l10_rhand_x_right, IHCC[:,4]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v4_l10_rhand_x_align, <, round(suggest_threshold(
                __motif__v4_l10_rhand_x_align, IHCC[:,4]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v4_l40_rhand_x_align_inverting_right, <, round(suggest_threshold(
                __motif__v4_l40_rhand_x_align_inverting_right, IHCC[:,4]; _percentile=5
            ) |> first, digits=2)
        )
    ),

    Atom(ScalarCondition(
            __var__v5_l10_rhand_y_ascending, <, round(suggest_threshold(
                __motif__v5_l10_rhand_y_ascending, IHCC[:,5]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v5_l10_rhand_y_descending, <, round(suggest_threshold(
                __motif__v5_l10_rhand_y_descending, IHCC[:,5]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v5_l40_rhand_y_ascdesc, <, round(suggest_threshold(
                __motif__v5_l40_rhand_y_ascdesc, IHCC[:,5]; _percentile=5
            ) |> first, digits=2)
        )
    ),

    Atom(ScalarCondition(
            __var__v6_l10_rhand_z_away_front, <, round(suggest_threshold(
                __motif__v6_l10_rhand_z_away_front, IHCC[:,6]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v6_l10_rhand_z_closer_front, <, round(suggest_threshold(
                __motif__v6_l10_rhand_z_closer_front, IHCC[:,6]; _percentile=5
            ) |> first, digits=2)
        )
    ),
];

_atoms = reduce(vcat, [
        propositional_atoms,
        # diamond(IA_A).(propositional_atoms),
        # diamond(IA_L).(propositional_atoms),
        # diamond(IA_B).(propositional_atoms),
        # diamond(IA_E).(propositional_atoms),
        # diamond(IA_D).(propositional_atoms),
        # diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)

_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [
    (gconfidence, 0.1, 0.1),
    (glift, 0.0, 0.0)
]

logiset = scalarlogiset(IHCC, variabledistances)

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
        islimited_length_arule(
            consequent_maxlength=3
        ),
        isanchored_arule(),
        # isheterogeneous_arule(),
    ]
)
