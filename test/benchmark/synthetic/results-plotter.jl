using ModalAssociationRules

using Plots
using PGFPlotsX
pgfplotsx()

RESULTS_REPOSITORY = joinpath(@__DIR__, "test", "benchmark", "synthetic", "results")
configuration = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, CONFIG_FILENAME))




# results = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, "results", "v2-fpgrowth.json"))
#
# X = Float64.(results["min_global_supports"])
# Y = Float64.(results["min_local_supports"])
#
# XGRID = repeat(X', length(Y))
# YGRID = repeat(Y', length(X))
#
# Z = Float64.(reshape(results["meantimes"], 20, 20))

# surface(
#     XGRID, YGRID, Z,
#     xlabel = "Min gsupp",
#     ylabel = "Min lsupp",
#     zlabel = "Time",
#     zlims = (0, 1e7),
#     contour = :projection
# )
