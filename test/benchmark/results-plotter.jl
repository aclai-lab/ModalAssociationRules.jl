using ModalAssociationRules
using JSON

using Plots
using PGFPlotsX
pgfplotsx()

RESULTS_REPOSITORY = joinpath(@__DIR__, "test", "benchmark", "results")

apriori_data =  JSON.parsefile(joinpath(RESULTS_REPOSITORY, "apriori.json"))
fpgrowth_data =  JSON.parsefile(joinpath(RESULTS_REPOSITORY, "fpgrowth.json"))
eclat_data =  JSON.parsefile(joinpath(RESULTS_REPOSITORY, "eclat.json"))

xaxis = fpgrowth_data["min_local_supports"] # 0.0 : 0.05 : 1.00

# apriori needs a NaN padding since certain times are not recorded,
# as they are VERY big numbers)
apriori_mls = apriori_data["min_local_supports"]
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
    (eclat_data, "ModalEclat", :red)
]

p = plot(
    title="Time execution comparison of three MARM algorithms",
    xlabel="Minimum lsupp threshold",
    ylabel="CPU time [s]",
    legend=:topright,
    size=(600,300)
);

for (_data, label, color) in datasets
    yaxis = _data["meantimes"] / 1e9
    plot!(p, xaxis, yaxis, label=label, lw=1, color=color);
end

# display(p)

savefig(p, joinpath(RESULTS_REPOSITORY, "comparison.tex"))
