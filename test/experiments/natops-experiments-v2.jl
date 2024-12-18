using Dates
using Discretizers
using ModalAssociationRules
import ModalAssociationRules.children
using Plots
using Plots.Measures
using PrettyTables
using StatsBase

using SoleData
using SoleData: AbstractUnivariateFeature

using SoleLogics
using SoleLogics: IA_B, IA_Bi, IA_E, IA_Ei, IA_D, IA_Di, IA_O

"""
    function modalwise_alphabet_extraction(
        C::Vector{<:Vector{<:Real}},
        feature::AbstractUnivariateFeature,
        discretizer::DiscretizationAlgorithm;
        results_folder::String="test/experiments/results/",
        palette::ColorPalette=palette(:viridis),
        signal_color::Symbol=:blue,
        threshold_color::Symbol=:darkgreen,
        bin_edge_color::Symbol=:red
    )

Generic pipeline to extract an alphabet from dimensional data.
Might require a bit of adaptation in the spatial (e.g., images) scenario.

See also `Discretizers.DiscretizationAlgorithm`, `SoleData.AbstractUnivariateFeature`.
"""
function modalwise_alphabet_extraction(
    C::Vector{<:Vector{<:Real}},
    nvariable::Integer,
    feature::AbstractUnivariateFeature,
    discretizer::DiscretizationAlgorithm;
    results_folder::String="test/experiments/results/",
    palette::ColorPalette=palette(:viridis),
    signal_color::Symbol=:blue,
    threshold_color::Symbol=:darkgreen,
    bin_edge_color::Symbol=:red
)
    default(palette=palette)
    results_folder = "test/experiments/results/"
    featurename = split(syntaxstring(feature), "[") |> first # e.g., "max[V5]" -> "max"

    # compute mse pairwise
    function _mse_between_pairs(v1::T, v2::T) where {T<:Vector{<:Real}}
        sum(v -> (first(v)-last(v))^2, zip(v1,v2)) / length(v1)
    end

    # from N distributions of the same type, compute the mean point by point and
    # return a new distribution
    function _get_representative_distribution(vs::Vector{<:Vector{<:Real}})
        _length_v = length(vs |> first)
        new_distribution = ones(_length_v)

        for i in 1:_length_v
            new_distribution[i] = mean([v[i] for v in vs])
        end

        return new_distribution
    end

    # remove the first and last element of a vector
    function _remove_extrema(v::Vector{<:Real})
        return v[2:(length(v)-1)]
    end


    # all instances plot
    all_plot = plot(C, framestyle=:box, alpha=0.25, labels="")
    title!("V$(nvariable) (all instances)")
    savefig(all_plot, joinpath(results_folder, "v$(nvariable)_$(featurename)_01_all.png"))


    # representative distribution plot
    R = _get_representative_distribution(C)
    Rlen = length(R)
    R_plot = plot(R, framestyle=:box, alpha=1, labels="")
    plot!(C, framestyle=:box, alpha=0.1, labels="")
    title!("Representative distribution for V$(nvariable)")
    savefig(R_plot, joinpath(results_folder, "v$(nvariable)_$(featurename)_02_repr.png"))


    # perform and plot binning on representative distribution
    R_binedges = binedges(discretizer, sort(R))
    R_bin_plot = plot(R, framestyle=:box, alpha=1, labels="")
    plot!(C, framestyle=:box, alpha=0.1, labels="")
    hline!(
        R_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    title!("Binned representative distribution for V$(nvariable)")
    savefig(R_bin_plot, joinpath(
        results_folder,
        "v$(nvariable)_$(featurename)_03_repr_bin.png"
    ))


    # we perform binning on an interval-wise scenario, considering worlds between 0% and
    # 50% of the original signal's length; binning is plotted using an histogram
    _minimum_wlength = 1
    _maximum_wlength = floor(Rlen * 0.5) |> Int64
    _, R_granular_binedges = plot_binning(
        [R], feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            # bounds are 0% and 50% of the original series length
            x -> length(x) >= _minimum_wlength && length(x) <= _maximum_wlength,
            Interval{Int}
        ),
        title="$(feature) applied on w s.t. \n" *
            "$(_minimum_wlength)<=|w|<=$(_maximum_wlength)",
        savefig_path=joinpath(results_folder,
            "v$(nvariable)_$(featurename)_04_repr_bin_his_wleq" *
            "$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )


    # compare the binned obtained by applying the given feature in a granular way,
    # with the binning performed on the raw signal
    R_granular_bin_plot = plot(R, framestyle=:box, alpha=1, labels="")
    plot!(C, framestyle=:box, alpha=0.1, labels="")
    hline!(
        R_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    hline!(
        R_granular_binedges,
        linestyle=:dot, linewidth=2,
        labels="$(syntaxstring(feature)) on w in W s.t. " *
            "$(_minimum_wlength) <= |w| <= $(_maximum_wlength))",
        color=:red
    )
    title!("Comparison between raw and interval-wise binning")
    savefig(
        R_granular_bin_plot,
        joinpath(
            results_folder,
            "v$(nvariable)_$(featurename)_05_repr_bin_wleq" *
            "$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )


    # we perform binning on an interval-wise scenario, considering worlds between 25% and
    # 75% of the original signal's length; binning is plotted using an histogram
    _minimum_wlength = floor(Rlen * 0.25) |> Int64
    _maximum_wlength = floor(Rlen * 0.75) |> Int64
    _, R_coarse_binedges = plot_binning(
        [R], feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            # bounds are 0% and 50% of the original series length
            x -> length(x) >= _minimum_wlength && length(x) <= _maximum_wlength,
            Interval{Int}
        ),
        title="$(feature) applied on w s.t. \n" *
            "$(_minimum_wlength)<=|w|<=$(_maximum_wlength)",
        savefig_path=joinpath(results_folder,
            "v$(nvariable)_$(featurename)_06_repr_bin_his_wleq" *
            "$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )


    # compare the binned obtained by applying the given feature in a coarse way,
    # with the binning performed on the raw signal
    R_coarse_bin_plot = plot(R, framestyle=:box, alpha=1, labels="")
    plot!(C, framestyle=:box, alpha=0.1, labels="")
    hline!(
        R_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    hline!(
        R_coarse_binedges,
        linestyle=:dot, linewidth=2,
        labels="$(syntaxstring(feature)) on w in W s.t. " *
            "$(_minimum_wlength) <= |w| <= $(_maximum_wlength))",
        color=:red
    )
    title!("Comparison between raw and interval-wise binning")
    savefig(
        R_coarse_bin_plot,
        joinpath(
            results_folder,
            "v$(nvariable)_$(featurename)_07_repr_bin_wleq" *
            "$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )


    # we investigate every possible interval range, and choose the interval-wise binning
    # in order to minimize MSE with the original raw binning;
    # the catch is we have a minimum length required, in order for an interval to be
    # interesting to us (this strongly depends from how the dataset is built)
    mse_matrix = fill(NaN, Rlen, Rlen)

    for (_start, _end) in Iterators.filter(
            # integrality condition on each interval
            x -> first(x) <= last(x),
            Iterators.product(1:Rlen, 1:Rlen)
        )

        # compute binning for (_start, _end) pair, then compute a similarity with the
        # raw binning using MSE (to punish outliers) and update the MSE matrix
        try
            _, _candidate_binedges = plot_binning(
                [R], feature, discretizer;
                worldfilter=SoleLogics.FunctionalWorldFilter(
                    # bounds are 5 and 10, which are 10% and 20% of the series length
                    x -> length(x) >= _start && length(x) <= _end, Interval{Int}),
                _binedges_only=true
            )

            _mse = _mse_between_pairs(
                _remove_extrema(R_binedges), _remove_extrema(_candidate_binedges))

            mse_matrix[_end, _start] = _mse
        catch
            # possible reasons: no bins remaining error (binning is not feasible)
            continue
        end
    end

    all_binnings_heatmap = heatmap(mse_matrix, color=:reds,
        xlabel="Interval minimum length", ylabel="Interval maximum length",
        title="MSE similarity between different binnings"
    )
    savefig(
        all_binnings_heatmap,
        joinpath(
            results_folder,
            "v$(nvariable)_$(featurename)_08_allbins_heatmap.png"
        )
    )


    # we want to analyze the data depending on how it is collected;
    # for example, in NATOPS, each sample's duration is nearly about 2.14 seconds.
    # WARNING: this must be adjusted depending on what kind of data you are studying!

    # we want to encode atleast 0.4 seconds in each interval, so we resolve:
    # x * (total_time / npoints) ≅ 0.4, that is, x ≅ 0.4 * npoints / total_time
    L = floor(0.4 * Rlen / 2.14) |> Integer # exact length of our intervals

    _, R_L_binedges = plot_binning(
        [R], feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            x -> length(x) == L,
            Interval{Int}
        ),
        title="$(feature) applied on w s.t. |w|=$(L)",
        savefig_path=joinpath(results_folder,
            "v$(nvariable)_$(featurename)_09_repr_bin_his_weq$(L).png"
        )
    )

    # compare the binned obtained by applying the given feature in an exact way
    R_L_bin_plot = plot(R, framestyle=:box, alpha=1, labels="")
    plot!(C, framestyle=:box, alpha=0.1, labels="")
    hline!(
        R_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    hline!(
        R_L_binedges,
        linestyle=:dot, linewidth=2,
        labels="$(syntaxstring(feature)) on w in W s.t. |w|=$(L)",
        color=:red
    )
    title!("Comparison between raw and interval-wise binning")
    savefig(
        R_L_bin_plot,
        joinpath(
            results_folder,
            "v$(nvariable)_$(featurename)_10_repr_bin_weq$(L).png"
        )
    )
end


# driver code

X_df, y = load_NATOPS();
X_df_1_have_command = X_df[1:30, :]

nvariable = 5
nbins = 3

_alphabet = modalwise_alphabet_extraction(
    X_df_1_have_command[:,nvariable],
    nvariable,
    VariableMin(nvariable),
    DiscretizeQuantile(3, true)
)
