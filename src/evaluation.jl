using Plots

"""
TODO
"""
function plot_rules_analysis(
    miner::AbstractMiner;
    glift_boundaries::Tuple{Float64,Float64}=(0.7,1.3)
)
    supp_vs_confidence_plot = plot(
        xlims=(0, 1.05), ylims=(0, 1.05),
        xlabel="Support", ylabel="Confidence",
        title="Support vs Confidence",
        framestyle=:box
    )

    for r in arules(miner)
        # x,y,z coordinates
        _gsupport = [globalmemo(miner, (:gsupport, Itemset(r)))]
        _gconfidence = [globalmemo(miner, (:gconfidence, r))]
        _glift = globalmemo(miner, (:glift, r))

        # transparency changes, depending by the fact that lift is honored or not
        _alpha=1.0
        if _glift > first(glift_boundaries) && _glift < last(glift_boundaries)
            _alpha = 0.25
        end

        scatter!(
            [_gsupport],
            [_gconfidence],
            marker_z=_glift,
            label=false,
            markersize=4,
            color=:plasma, # we need a color gradient
            alpha=_alpha
        )
    end

    return supp_vs_confidence_plot
end
