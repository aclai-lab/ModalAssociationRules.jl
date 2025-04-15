include("test/experiments/experiments-driver.jl")

X, y = load_libras();

############################################################################################
# Experiment #1:
############################################################################################
include("test/experiments/Libras/libras1.jl")

println("Running experiment #1: ")
experiment!(miner, "Libras", "v1_curved_swing.txt")
