# README: see experiments-driver.jl and experiments-libras.jl

# isolate "Curved swing" class
VZZ = reduce(vcat, [X[1:12, :], X[180:192, :]])

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v1_l10 = motifsalphabet(
    VZZ[:,1], 10, 5; r=1, th=10, clipcorrection=false
);
__motif__v1_l10_rhand_x_right = _motifs_v1_l10[4]
__motif__v1_l10_rhand_x_left = _motifs_v1_l10[1]

__var__v1_l10_rhand_x_right = VariableDistance(1,
    __motif__v1_l10_rhand_x_right,
    distance=x -> expdistance(x, __motif__v1_l10_rhand_x_right),
    featurename="Right"
)
__var__v1_l10_rhand_x_left = VariableDistance(1,
    __motif__v1_l10_rhand_x_left,
    distance=x -> expdistance(x, __motif__v1_l10_rhand_x_left),
    featurename="Left"
)


_mp, _raw_motifs, _motifs_v1_l40 = motifsalphabet(
    VZZ[:,1], 40, 5; r=2, th=0, clipcorrection=false
);
__motif__v1_l40_rhand_x_wave = _motifs_v1_l40[4]

__var__v1_l40_rhand_x_wave = VariableDistance(1,
    __motif__v1_l40_rhand_x_wave,
    distance=x -> expdistance(x, __motif__v1_l40_rhand_x_wave),
    featurename="Wave"
)

# assembly the motifs here

allmotifs = [
    __motif__v1_l10_rhand_x_right,
    __motif__v1_l10_rhand_x_left,
    __motif__v1_l40_rhand_x_wave,
]

variabledistances = [
    __var__v1_l10_rhand_x_right,
    __var__v1_l10_rhand_x_left,
    __var__v1_l40_rhand_x_wave,
];

# now create your alphabet

propositional_atoms = [
    Atom(ScalarCondition(__var__v1_l10_rhand_x_right, <=, 1)),
    Atom(ScalarCondition(__var__v1_l10_rhand_x_left, <=, 1)),
    Atom(ScalarCondition(__var__v1_l40_rhand_x_wave, <=, 2)),
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
