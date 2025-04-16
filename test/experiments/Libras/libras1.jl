# README: see experiments-driver.jl and experiments-libras.jl

# isolate "Curved swing" class
CSW = reduce(vcat, [X[1:12, :], X[180:192, :]])

############################################################################################
# right hand X variable generations
############################################################################################

# remember: motifsalphabet(data, windowlength, #extractions)
_mp, _raw_motifs, _motifs_v1_l10 = motifsalphabet(
    CSW[:,1], 10, 5; r=1, th=10, clipcorrection=false
);
__motifs__v1_l10_rhand_x_right = _motifs_v1_l10[[3,4]]
__motifs__v1_l10_rhand_x_left = _motifs_v1_l10[[1,2,5]]

__var__v1_l10_rhand_x_right = VariableDistance(1,
    __motifs__v1_l10_rhand_x_right,
    distance=expdistance,
    featurename="Right"
)
__var__v1_l10_rhand_x_left = VariableDistance(1,
    __motifs__v1_l10_rhand_x_left,
    distance=expdistance,
    featurename="Left"
)


_mp, _raw_motifs, _motifs_v1_l40 = motifsalphabet(
    CSW[:,1], 40, 5; r=2, th=0, clipcorrection=false
);
__motifs__v1_l40_rhand_x_wave = _motifs_v1_l40

__var__v1_l40_rhand_x_wave = VariableDistance(1,
    __motifs__v1_l40_rhand_x_wave,
    distance=expdistance,
    featurename="Wave"
)


############################################################################################
# right hand Y variable generations
############################################################################################

_mp, _raw_motifs, _motifs_v2_l10 = motifsalphabet(
    CSW[:,2], 10, 10; r=1, th=0, clipcorrection=true
);
__motifs__v2_l10_rhand_y_up = _motifs_v2_l10[[1,2,4,5,7]]
__motifs__v2_l10_rhand_y_down = _motifs_v2_l10[[8,9,10]]

__var__v2_l10_rhand_y_up = VariableDistance(2,
    __motifs__v2_l10_rhand_y_up,
    distance=expdistance,
    featurename="Up"
)
__var__v2_l10_rhand_y_down = VariableDistance(2,
    __motifs__v2_l10_rhand_y_down,
    distance=expdistance,
    featurename="Down"
)

_mp, _raw_motifs, _motifs_v2_l40 = motifsalphabet(
    CSW[:,2], 40, 5; r=2, th=0, clipcorrection=true
);
__motifs__v2_l40_rhand_y_wave = _motifs_v2_l40

__var__v2_l40_rhand_y_wave = VariableDistance(2,
    __motifs__v2_l40_rhand_y_wave,
    distance=expdistance,
    featurename="Wave"
)

############################################################################################
# assembly the motifs here
############################################################################################


allmotifs = [
    __motifs__v1_l10_rhand_x_right,
    __motifs__v1_l10_rhand_x_left,
    __motifs__v1_l40_rhand_x_wave,

    __motifs__v2_l10_rhand_y_up,
    __motifs__v2_l10_rhand_y_down,
    __motifs__v2_l40_rhand_y_wave,
]

variabledistances = [
    __var__v1_l10_rhand_x_right,
    __var__v1_l10_rhand_x_left,
    __var__v1_l40_rhand_x_wave,

    __var__v2_l10_rhand_y_up,
    __var__v2_l10_rhand_y_down,
    __var__v2_l40_rhand_y_wave,
];


############################################################################################
# now create your alphabet
############################################################################################


propositional_atoms = [
    Atom(ScalarCondition(__var__v1_l10_rhand_x_right, <=, 1)),
    Atom(ScalarCondition(__var__v1_l10_rhand_x_left, <=, 1)),
    Atom(ScalarCondition(__var__v1_l40_rhand_x_wave, <=, 2)),

    Atom(ScalarCondition(__var__v2_l10_rhand_y_up, <=, 1)),
    Atom(ScalarCondition(__var__v2_l10_rhand_y_down, <=, 1)),
    Atom(ScalarCondition(__var__v2_l40_rhand_y_wave, <=, 2)),
];

_atoms = reduce(vcat, [
        propositional_atoms,
        diamond(IA_A).(propositional_atoms),
        # diamond(IA_L).(propositional_atoms),
        diamond(IA_B).(propositional_atoms),
        diamond(IA_E).(propositional_atoms),
        diamond(IA_D).(propositional_atoms),
        # diamond(IA_O).(propositional_atoms),
    ]
)
_items = Vector{Item}(_atoms)


############################################################################################
# set mining parameters
############################################################################################


_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [
    (gconfidence, 0.1, 0.1),
    (glift, 0.0, 0.0)
]


############################################################################################
# arrange data into a logiset and wrap it inside a miner
############################################################################################


logiset = scalarlogiset(CSW, variabledistances)

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
