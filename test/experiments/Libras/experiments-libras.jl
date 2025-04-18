include("test/experiments/experiments-driver.jl")

X, y = load_libras();

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
