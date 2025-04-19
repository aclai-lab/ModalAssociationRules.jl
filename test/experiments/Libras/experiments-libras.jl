include("test/experiments/experiments-driver.jl")

X, y = load_libras();

############################################################################################
# General alphabet definition
############################################################################################

# utility to extract a snippet's inner Vector from the definition in MatrixProfiles.jl
_snippet(_snippets, i) = _snippets.snippets[i].seq

############################################################################################
# Literals from Curve Swing class
############################################################################################
CSW = reduce(vcat, [X[1:12, :], X[180:192, :]])

# X length 10
S = snippets(reduce(vcat, CSW[:,1]), 5, 10; m=10)
__motifs__v1_l10_left = [_snippet(S,1)]
__motifs__v1_l10_right = [_snippet(S,2)]
__motifs__v1_l10_right_to_left = [_snippet(S,3), _snippet(S,5)]
__motifs__v1_l10_left_to_right = [_snippet(S,4)]


__var__v1_l10_left = VariableDistance(1,
    __motifs__v1_l10_left,
    distance=expdistance,
    featurename="Left"
)
__var__v1_l10_right = VariableDistance(1,
    __motifs__v1_l10_right,
    distance=expdistance,
    featurename="Right"
)
__var__v1_l10_right_to_left = VariableDistance(1,
    __motifs__v1_l10_right_to_left,
    distance=expdistance,
    featurename="R→L"
)
__var__v1_l10_left_to_right = VariableDistance(1,
    __motifs__v1_l10_left_to_right,
    distance=expdistance,
    featurename="L→R"
)

# X length 20
S = snippets(reduce(vcat, CSW[:,1]), 5, 20; m=20)
__motifs__v1_l20_right_inv_left_inv_right = [_snippet(S,1)]
__motifs__v1_l20_left_inv_right_inv_left = [_snippet(S,2)]
__motifs__v1_l20_left_inv_right = [_snippet(S,3)]
__motifs__v1_l20_right_inv_left = [_snippet(S,4), _snippet(S,5)]

__var__v1_l20_right_inv_left_inv_right = VariableDistance(1,
    __motifs__v1_l20_right_inv_left_inv_right,
    distance=expdistance,
    featurename="R∩L∪R"
)
__var__v1_l20_left_inv_right_inv_left = VariableDistance(1,
    __motifs__v1_l20_left_inv_right_inv_left,
    distance=expdistance,
    featurename="LUR∩L"
)
__var__v1_l20_left_inv_right = VariableDistance(1,
    __motifs__v1_l20_left_inv_right,
    distance=expdistance,
    featurename="LUR"
)
__var__v1_l20_right_inv_left = VariableDistance(1,
    __motifs__v1_l20_right_inv_left,
    distance=expdistance,
    featurename="R∩L"
)

# X length 40
S = snippets(reduce(vcat, CSW[:,1]), 5, 40; m=40)
__motifs__v1_l40_fullleft_fullright_fullleft = [_snippet(S,1)]
__motifs__v1_l40_fullright_fullleft_fullright = [_snippet(S,2)]
__motifs__v1_l40_right_left_right_left = [_snippet(S,3)]

__var__v1_l40_fullleft_fullright_fullleft = VariableDistance(1,
    __motifs__v1_l40_fullleft_fullright_fullleft,
    distance=expdistance,
    featurename="U∩"
)
__var__v1_l40_fullright_fullleft_fullright = VariableDistance(1,
    __motifs__v1_l40_fullright_fullleft_fullright,
    distance=expdistance,
    featurename="∩U^"
)
__var__v1_l40_right_left_right_left = VariableDistance(1,
    __motifs__v1_l40_right_left_right_left,
    distance=expdistance,
    featurename="V^V"
)



# Y length 10
S = snippets(reduce(vcat, CSW[:,2]), 5, 10; m=10)
__motifs__v2_l10_down = [_snippet(S,1)]
__motifs__v2_l10_up = [_snippet(S,2)]
__motifs__v2_l10_up_down = [_snippet(S,3), _snippet(S,5)]
__motifs__v2_l10_down_up = [_snippet(S,4)]

__var__v2_l10_down = VariableDistance(2,
    __motifs__v2_l10_down,
    distance=expdistance,
    featurename="Down"
)
__var__v2_l10_up = VariableDistance(2,
    __motifs__v2_l10_up,
    distance=expdistance,
    featurename="Up"
)
__var__v2_l10_up_down = VariableDistance(2,
    __motifs__v2_l10_up_down,
    distance=expdistance,
    featurename="UpDown"
)
__var__v2_l10_down_up = VariableDistance(2,
    __motifs__v2_l10_down_up,
    distance=expdistance,
    featurename="DownUp"
)

# Y length 20
S = snippets(reduce(vcat, CSW[:,2]), 5, 20; m=20)
__motifs__v2_l20_down_slightlyup = [_snippet(S,1)]
__motifs__v2_l20_up_down = [_snippet(S,2), _snippet(S,4)]
__motifs__v2_l20_slightlyup_down_up = [_snippet(S,3), _snippet(S,5)]

__var__v2_l20_down_slightlyup = VariableDistance(2,
    __motifs__v2_l20_down_slightlyup,
    distance=expdistance,
    featurename="^.-"
)
__var__v2_l20_up_down = VariableDistance(2,
    __motifs__v2_l20_up_down,
    distance=expdistance,
    featurename="LongUpDown"
)
__var__v2_l20_slightlyup_down_up = VariableDistance(2,
    __motifs__v2_l20_slightlyup_down_up,
    distance=expdistance,
    featurename=".-.^"
)


# Y length 40
S = snippets(reduce(vcat, CSW[:,2]), 5, 40; m=40)
# the movement is not performed with the complete range of movement, but is messy
__motifs__v2_l40_short_movement_range = [_snippet(S,1)]
__motifs__v2_l40_perfect_movement = [_snippet(S,2), _snippet(S,4)]
__motifs__v2_l40_slightlyup_down_up = [_snippet(S,3), _snippet(S,5)]

__var__v2_l40_short_movement_range = VariableDistance(2,
    __motifs__v2_l40_short_movement_range,
    distance=expdistance,
    featurename="FullLazyRange"
)
__var__v2_l40_perfect_movement = VariableDistance(2,
    __motifs__v2_l40_perfect_movement,
    distance=expdistance,
    featurename="∩U∩"
)
__var__v2_l40_slightlyup_down_up = VariableDistance(2,
    __motifs__v2_l40_slightlyup_down_up,
    distance=expdistance,
    featurename="-^-"
)


# fallback to _suggest_threshold for VariableDistances
function __suggest_threshold(var::VariableDistance, data; kwargs...)
    _refs = references(var)
    _i_variable = i_variable(var)

    _ans = first.(map(
        _ref -> suggest_threshold(_ref, data[:,_i_variable]; kwargs...) , _refs)) |> maximum
    return round(_ans; digits=2)
end

variable_distances_CSW = [
    __var__v1_l10_left,
    __var__v1_l10_right,
    __var__v1_l10_right_to_left,
    __var__v1_l10_left_to_right,
    __var__v1_l20_right_inv_left_inv_right,
    __var__v1_l20_left_inv_right_inv_left,
    __var__v1_l20_left_inv_right,
    __var__v1_l20_right_inv_left,
    __var__v1_l40_fullleft_fullright_fullleft,
    __var__v1_l40_fullright_fullleft_fullright,
    __var__v1_l40_right_left_right_left,
    __var__v2_l10_down,
    __var__v2_l10_up,
    __var__v2_l10_up_down,
    __var__v2_l10_down_up,
    __var__v2_l20_down_slightlyup,
    __var__v2_l20_up_down,
    __var__v2_l20_slightlyup_down_up,
    __var__v2_l40_short_movement_range,
    __var__v2_l40_perfect_movement,
    __var__v2_l40_slightlyup_down_up,
]

propositional_atoms_CSW = [
    Atom(ScalarCondition(var, <=, __suggest_threshold(var, CSW; _percentile=15)))
    for var in variable_distances_CSW
]


############################################################################################
# Literals from Circle
############################################################################################
CRC = reduce(vcat, [X[133:144, :], X[313:324, :]])

# X length 10 (they are identical to those of Curved Swing class)
# X length 20 " "
# X length 40
S = snippets(reduce(vcat, CRC[:,1]), 5, 40; m=40)
__motifs__v1_l40_full_right_left = [_snippet(S,1), _snippet(S,4)]
__motifs__v1_l40_full_left_right = [_snippet(S,2), _snippet(S,3)]

__var__v1_l40_full_right_left = VariableDistance(1,
    __motifs__v1_l40_full_right_left,
    distance=expdistance,
    featurename="⟹⟸"
)
__var__v1_l40_full_left_right = VariableDistance(1,
    __motifs__v1_l40_full_left_right,
    distance=expdistance,
    featurename="⟸⟹"
)

# Y are the same as Curved Swing Class

variable_distances_CRC = [
    __var__v1_l40_full_right_left,
    __var__v1_l40_full_left_right
]

propositional_atoms_CRC = [
    Atom(ScalarCondition(var, <=, __suggest_threshold(var, CRC; _percentile=15)))
    for var in variable_distances_CRC
]

############################################################################################
# Final Assembly
############################################################################################

variabledistances = reduce(vcat, [variable_distances_CSW, variable_distances_CRC])
propositional_atoms = reduce(vcat, [propositional_atoms_CSW, propositional_atoms_CRC])

_atoms = reduce(vcat, [
    propositional_atoms,

    diamond(IA_A).(propositional_atoms),
    diamond(IA_A).(diamond(IA_A).(propositional_atoms)),

    # diamond(IA_L).(propositional_atoms),

    diamond(IA_B).(propositional_atoms),
    # diamond(IA_A).(diamond(IA_B).(propositional_atoms)),
    diamond(IA_E).(propositional_atoms),
    # diamond(SoleLogics.converse(IA_A)).(diamond(IA_E).(propositional_atoms)),

    # diamond(IA_D).(propositional_atoms),

    diamond(IA_O).(propositional_atoms),
])

_items = Vector{Item}(_atoms)

_itemsetmeasures = [(gsupport, 0.1, 0.1)]

_rulemeasures = [
    (gconfidence, 0.1, 0.1),
    (glift, 0.0, 0.0),
    (dimensional_glift, 0.0, 0.0)
]

############################################################################################
# Experiments
############################################################################################

include("test/experiments/Libras/libras1.jl")
include("test/experiments/Libras/libras2.jl")
