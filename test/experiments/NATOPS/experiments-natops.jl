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
include("test/experiments/NATOPS/natops7.jl")

# I have command
logiset = scalarlogiset(IHCC, variables)
miner = Miner(logiset, miningalgo, _items, _itemsetmeasures, _rulemeasures;
    itemset_mining_policies=Function[isanchored_itemset(), isdimensionally_coherent_itemset()],
    arule_mining_policies=Function[islimited_length_arule(consequent_maxlength=3), isanchored_arule()]
)

experiment!(miner, "test/experiments/NATOPS", "v7_i_have_command")
