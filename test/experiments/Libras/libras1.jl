# README: see experiments-driver.jl and experiments-libras.jl

# isolate "Vertical zigzag" class
VZZ = X[1:24, :]

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v4_l10 = motifsalphabet(
    VZZ[:,1], 10, 5; r=1, th=10, clipcorrection=false
);

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

# assembly the motifs here

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

# now create your alphabet

propositional_atoms = [
    Atom(ScalarCondition(
            __var__v4_l10_rhand_x_right, <, round(suggest_threshold(
                __motif__v4_l10_rhand_x_right, VZZ[:,4]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v4_l10_rhand_x_align, <, round(suggest_threshold(
                __motif__v4_l10_rhand_x_align, VZZ[:,4]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v4_l40_rhand_x_align_inverting_right, <, round(suggest_threshold(
                __motif__v4_l40_rhand_x_align_inverting_right, VZZ[:,4]; _percentile=5
            ) |> first, digits=2)
        )
    ),

    Atom(ScalarCondition(
            __var__v5_l10_rhand_y_ascending, <, round(suggest_threshold(
                __motif__v5_l10_rhand_y_ascending, VZZ[:,5]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v5_l10_rhand_y_descending, <, round(suggest_threshold(
                __motif__v5_l10_rhand_y_descending, VZZ[:,5]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v5_l40_rhand_y_ascdesc, <, round(suggest_threshold(
                __motif__v5_l40_rhand_y_ascdesc, VZZ[:,5]; _percentile=5
            ) |> first, digits=2)
        )
    ),

    Atom(ScalarCondition(
            __var__v6_l10_rhand_z_away_front, <, round(suggest_threshold(
                __motif__v6_l10_rhand_z_away_front, VZZ[:,6]; _percentile=5
            ) |> first, digits=2)
        )
    ),
    Atom(ScalarCondition(
            __var__v6_l10_rhand_z_closer_front, <, round(suggest_threshold(
                __motif__v6_l10_rhand_z_closer_front, VZZ[:,6]; _percentile=5
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

# mining parameters

_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [
    (gconfidence, 0.1, 0.1),
    (glift, 0.0, 0.0)
]

# arrange data into a logiset and wrap it inside a miner

logiset = scalarlogiset(VZZ, variabledistances)

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
