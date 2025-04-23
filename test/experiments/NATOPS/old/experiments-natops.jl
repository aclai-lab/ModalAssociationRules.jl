include("test/experiments/experiments-driver.jl")

X, y = load_NATOPS();
insertcols!(X, 25, "ΔY[Thumb r and Hand tip r]" => X[:,5]-X[:,23])

############################################################################################
# Experiment #1: just a small example
############################################################################################
include("test/experiments/NATOPS/natops0.jl")

############################################################################################
# Experiment #1: describe the right hand in "I have command class"
############################################################################################
include("test/experiments/NATOPS/natops1.jl")

println("Running experiment #1:")
experiment!(miner, "NATOPS", "v1_rhand_ihavecommand.txt")

############################################################################################
# Experiment #2: describe the right hand in "All clear class"
############################################################################################
include("test/experiments/NATOPS/natops2.jl")

println("Running experiment #2: ")
experiment!(miner, "NATOPS", "v2_rhand_allclear.txt")

############################################################################################
# Experiment #3: describe the right hand in "Not clear"
############################################################################################
include("test/experiments/NATOPS/natops3.jl")

println("Running experiment #3: ")
experiment!(miner, "NATOPS", "v3_rhand_notclear.txt")

############################################################################################
# Experiment #4: describe wrists and elbows in "Spread wings"
############################################################################################
include("test/experiments/NATOPS/natops4.jl")

println("Running experiment #4: ")
experiment!(miner, "NATOPS", "v4_wristelbow_spreadwings.txt")

############################################################################################
# Experiment #5: describe wrists and elbows in "Fold wings"
############################################################################################
include("test/experiments/NATOPS/natops5.jl")

println("Running experiment #5: ")
experiment!(miner, "NATOPS", "v5_wristelbow_foldwings.txt")

############################################################################################
# Experiment #6: describe wrists and elbows in "Lock wings"
############################################################################################
include("test/experiments/NATOPS/natops6.jl")

println("Running experiment #6: ")
experiment!(miner, "NATOPS", "v6_elbowhand_lockwings.txt")

############################################################################################
# Experiment #7: try to describe every class starting from a common dictionary
############################################################################################

expdistance = zeuclidean
include("test/experiments/NATOPS/natops7.jl")

function findvar(variables, name)
    return variables[findall(v -> featurename(v) == name, variables)] |> first
end

logiset, miner = __init_experiment(IHCC)
experiment!(miner, "test/experiments/NATOPS", "v7c1_i_have_command")

logiset, miner = __init_experiment(IHCC)
experiment!(miner, "test/experiments/NATOPS", "v7c2_all_clear")

logiset, miner = __init_experiment(IHCC)
experiment!(miner, "test/experiments/NATOPS", "v7c3_not_clear")

logiset, miner = __init_experiment(ACC)
experiment!(miner, "test/experiments/NATOPS", "v7c4_spread_wings")

logiset, miner = __init_experiment(FWC)
experiment!(miner, "test/experiments/NATOPS", "v7c5_fold_wings")

logiset, miner = __init_experiment(IHCC)
experiment!(miner, "test/experiments/NATOPS", "v7c6_lock_wings")


expdistance = (x,y) -> sqrt(sum((x .- y).^2))
include("test/experiments/NATOPS/natops7.jl")
logiset, miner = __init_experiment(IHCC)
experiment!(miner, "NATOPS", "v7c1_i_have_command_euclidean")
