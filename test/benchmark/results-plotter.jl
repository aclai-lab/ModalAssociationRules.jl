using ModalAssociationRules
using JSON

using Plots
using PGFPlotsX
pgfplotsx()

RESULTS_REPOSITORY = joinpath(@__DIR__, "test", "benchmark", "results")

apriori_data = JSON.parsefile(joinpath(RESULTS_REPOSITORY, "apriori.json"))
fpgrowth_data = JSON.parsefile(joinpath(RESULTS_REPOSITORY, "fpgrowth.json"))
eclat_data = JSON.parsefile(joinpath(RESULTS_REPOSITORY, "eclat.json"))

xaxis = reverse(fpgrowth_data["min_local_supports"]) # 0.0 : 0.05 : 1.00

# apriori needs a NaN padding since certain times are not recorded,
# as they are VERY big numbers;
# BEWARE: the padding changes depending on the experiments' configuration
apriori_mls = apriori_data["min_local_supports"][5:end]
apriori_times = apriori_data["meantimes"]

reverse!(apriori_mls)
reverse!(apriori_times)
while apriori_mls[end] > 0.0
    push!(apriori_mls, round(apriori_mls[end] - 0.05; digits=2))
    push!(apriori_times, NaN)
end

apriori_data["min_local_supports"] = reverse(apriori_mls)
apriori_data["meantimes"] = reverse(apriori_times)

datasets = [
    (apriori_data, "ModalApriori", :orange),
    (fpgrowth_data, "ModalFP-Growth", :blue),
    (eclat_data, "ModalEclat", :red),
]

# times per cpu threshold
p_times = plot(;
    title="Time execution comparison of three MARM algorithms",
    xlabel="Minimum lsupp threshold",
    ylabel="CPU time [s]",
    legend=:topleft,
    size=(600, 300),
);

for (_data, label, color) in datasets
    yaxis = _data["meantimes"] / 1e9
    plot!(p_times, xaxis, yaxis; label=label, lw=1, color=color)
end

savefig(p_times, joinpath(RESULTS_REPOSITORY, "comparison_times.tex"))
savefig(p_times, joinpath(RESULTS_REPOSITORY, "comparison_times.png"))

# memory usage

p_memory = plot(;
    title="Allocations comparison of three MARM algorithms",
    xlabel="Minimum lsupp threshold",
    ylabel="Memory [MBs]",
    legend=:topleft,
    size=(600, 300),
);

apriori_data["memories"] = vcat([NaN, NaN, NaN, NaN], apriori_data["memories"])

for (_data, label, color) in datasets
    yaxis = _data["memories"] / 10e6
    plot!(p_memory, xaxis, yaxis; label=label, lw=1, color=color)
end

savefig(p_memory, joinpath(RESULTS_REPOSITORY, "comparison_memory.tex"))
savefig(p_memory, joinpath(RESULTS_REPOSITORY, "comparison_memory.png"))
