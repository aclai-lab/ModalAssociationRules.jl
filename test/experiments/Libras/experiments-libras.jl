include("test/experiments/experiments-driver.jl")

X, y = load_libras();

############################################################################################
# General alphabet definition
############################################################################################
_snippet(_snippets, i) = _snippets.snippets[i].seq

# snippets from "Curved Swing"
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
    featurename="LUR∩R"
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


# Y length 20
S = snippets(reduce(vcat, CSW[:,2]), 5, 20; m=20)
__motifs__v2_l20_down_slightlyup = [_snippet(S,1)]
__motifs__v2_l20_up_down = [_snippet(S,2), _snippet(S,4)]
__motifs__v2_l20_slightlyup_down_up = [_snippet(S,3), _snippet(S,5)]

# Y length 40
S = snippets(reduce(vcat, CSW[:,2]), 5, 40; m=40)
# the movement is not performed with the complete range of movement, but is messy
__motifs__v2_l40_short_movement_range = [_snippet(S,1)]
__motifs__v2_l40_perfect_movement = [_snippet(S,2), _snippet(S,4)]
__motifs__v2_l40_slightlyup_down_up = [_snippet(S,3), _snippet(S,5)]


############################################################################################
# Experiment #1: Curved swing
############################################################################################
include("test/experiments/Libras/libras1.jl")

println("Running experiment #1: ")
experiment!(miner, "Libras", "v1_curved_swing.txt")

############################################################################################
# Experiment #2: Vertical zig-zag
############################################################################################
include("test/experiments/Libras/libras2.jl")

println("Running experiment #2: ")
experiment!(miner, "Libras", "v2_vertical_zigzac.txt")
