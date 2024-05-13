using Test

using Date
using ModalAssociationRules
using SoleData
using StatsBase

import ModalAssociationRules.children

RESULTS_PATH = "test/experiments/results/"

X_df, y = load_NATOPS();
X = scalarlogiset(X_df)

function experiment!(
    X::AbstractDataset,
    algorithm::Function,
    items::Vector{Item},
    itemsetmeasures::Vector{<:MeaningfulnessMeasure},
    rulemeasures::Vector{<:MeaningfulnessMeasure};
    reportname::Union{Nothing,String}=nothing
)
    miner = Miner(X, algorithm, items, itemsetmeasures, rulemeasures)
    mine!(miner)
    generaterules!(miner) |> collect

    if isnothing(reportname)
        reportname = now() |> string
    end
    reportname = RESULTS_PATH * reportname
    report = open(reportname, "w")

    for rule in sort(
        arules(fpgrowth_miner), by=x -> fpgrowth_miner.gmemo[(:gconfidence, x)], rev=true)
        write(report, analyze(rule, miner))
    end

    close(report)
end
