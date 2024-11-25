using Plots

"""
TODO
"""
function plot_rules_analysis(
    miner::AbstractMiner
)
    supp_vs_confidence_plot = plot(
        xlims=(0, 1), ylims=(0, 1),
        xlabel="Support", ylabel="Confidence",
        title="Support vs Confidence",
        framestyle=:box
    )

    for r in arules(miner)
        scatter!(
            [globalmemo(miner, (:gsupport, Itemset(r)))],
            [globalmemo(miner, (:gconfidence, r))],
            label=false
        )
    end

    return supp_vs_confidence_plot
end
