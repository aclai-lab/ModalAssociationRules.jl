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

function modalwise_alphabet_extraction(
    𝐶::Vector{<:Vector{<:Real}},
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
    all_plot = plot(𝐶, framestyle=:box, alpha=0.25, labels="")
    title!("V$(nvariable) (all instances)")
    savefig(all_plot, joinpath(results_folder, "v$(nvariable)_01_all.png"))


    # representative distribution plot
    𝑅 = _get_representative_distribution(𝐶)
    𝑅_plot = plot(𝑅, framestyle=:box, alpha=1, labels="")
    plot!(𝐶, framestyle=:box, alpha=0.1, labels="")
    title!("Representative distribution for V$(nvariable)")
    savefig(𝑅_plot, joinpath(results_folder, "v$(nvariable)_02_repr.png"))


    # perform and plot binning on representative distribution
    𝑅_binedges = binedges(discretizer, sort(𝑅))
    𝑅_bin_plot = plot(𝑅, framestyle=:box, alpha=1, labels="")
    plot!(𝐶, framestyle=:box, alpha=0.1, labels="")
    hline!(
        𝑅_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    title!("Binned representative distribution for V$(nvariable)")
    savefig(
        𝑅_bin_plot, joinpath(results_folder, "v$(nvariable)_03_repr_bin.png"))


    # we perform binning on an interval-wise scenario, considering worlds between 0% and
    # 50% of the original signal's length; binning is plotted using an histogram
    _minimum_wlength = 1
    _maximum_wlength = floor(length(𝑅) * 0.5) |> Int64
    _, 𝑅_granular_binedges = plot_binning(
        [𝑅], feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            # bounds are 0% and 50% of the original series length
            x -> length(x) >= _minimum_wlength && length(x) <= _maximum_wlength,
            Interval{Int}
        ),
        savefig_path=joinpath(results_folder,
            "v$(nvariable)_04_repr_bin_his_wleq$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )


    # compare the binned obtained by applying the given feature in a granular way,
    # with the binning performed on the raw signal
    𝑅_granular_bin_plot = plot(𝑅, framestyle=:box, alpha=1, labels="")
    plot!(𝐶, framestyle=:box, alpha=0.1, labels="")
    hline!(
        𝑅_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    hline!(
        𝑅_granular_binedges,
        linestyle=:dot, linewidth=2,
        labels="$(syntaxstring(feature)) on w in W s.t. " *
            "$(_minimum_wlength) <= |w| <= $(_maximum_wlength))",
        color=:red
    )
    title!("Comparison between raw and interval-wise binning")
    savefig(
        𝑅_granular_bin_plot,
        joinpath(
            results_folder,
            "v$(nvariable)_05_repr_bin_wleq$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )

    # we perform binning on an interval-wise scenario, considering worlds between 0% and
    # 50% of the original signal's length; binning is plotted using an histogram
    _minimum_wlength = floor(length(𝑅) * 0.25) |> Int64
    _maximum_wlength = floor(length(𝑅) * 0.75) |> Int64
    _, 𝑅_coarse_binedges = plot_binning(
        [𝑅], feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            # bounds are 0% and 50% of the original series length
            x -> length(x) >= _minimum_wlength && length(x) <= _maximum_wlength,
            Interval{Int}
        ),
        savefig_path=joinpath(results_folder,
            "v$(nvariable)_06_repr_bin_his_wleq$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )


    # compare the binned obtained by applying the given feature in a coarse way,
    # with the binning performed on the raw signal
    𝑅_coarse_bin_plot = plot(𝑅, framestyle=:box, alpha=1, labels="")
    plot!(𝐶, framestyle=:box, alpha=0.1, labels="")
    hline!(
        𝑅_binedges,
        linestyle=:dash, linewidth=2,
        labels="Binning w. $(discretizer)", color=threshold_color
    )
    hline!(
        𝑅_coarse_binedges,
        linestyle=:dot, linewidth=2,
        labels="$(syntaxstring(feature)) on w in W s.t. " *
            "$(_minimum_wlength) <= |w| <= $(_maximum_wlength))",
        color=:red
    )
    title!("Comparison between raw and interval-wise binning")
    savefig(
        𝑅_coarse_bin_plot,
        joinpath(
            results_folder,
            "v$(nvariable)_07_repr_bin_wleq$(_maximum_wlength)g$(_minimum_wlength).png"
        )
    )
end


nvariable = 5
nbins = 3

_alphabet = modalwise_alphabet_extraction(
    X_df_1_have_command[:,nvariable],
    VariableMax(nvariable),
    DiscretizeQuantile(3, true)
)



# we distinguish 4 phases, which we can encode in natural language as follows:
# 1. initial ascending phase,  2. mature ascending phase,
# 3. initial descending phase, 4. mature descending phase

# when transforming the representative signal in a kripke frame, we are building a
# relational model with multiple intervals at different lengths.

# we try with granular binedges

_, _repr_granular_binedges = plot_binning(
    [_repr_dis], _feature, discretizer;
    worldfilter=SoleLogics.FunctionalWorldFilter(
        # bounds are 0% and 50% of the original series length (GRANULAR RESULT)
        x -> length(x) >= 1 && length(x) <= 25, Interval{Int}),
    savefig_path=joinpath(results_folder, "v$(nvariable)_repr_max_3bin_wleq25g1")
)

_repr_binedges = binedges(discretizer, sort(_repr_dis))
rhand_y_repr_dis = plot(
    _repr_dis, framestyle=:box, alpha=1, labels="")
plot!(X_df_1_have_command[:,nvariable], framestyle=:box, alpha=0.1, labels="")
hline!(
    _repr_binedges,
    linestyle=:dash, linewidth=2,
    labels="Binning threshold (raw signal)", color=threshold_color
)
hline!(
    _repr_granular_binedges,
    linestyle=:dot, linewidth=2,
    labels="Binning threshold (max on intervals i s.t. 1 <= |i| <= 25)", color=:red
)
title!("Representative right hand signal binned")
savefig(rhand_y_repr_dis, joinpath(results_folder, "v$(nvariable)_rpr_binned_max_3bin_wlq25g1.png"))

# now we try with a more coarse one

_, _repr_coarse_binedges = plot_binning(
    [_repr_dis], _feature, DiscretizeQuantile(nbins,true);
    worldfilter=SoleLogics.FunctionalWorldFilter(
        # bounds are 0% and 50% of the original series length (GRANULAR RESULT)
        x -> length(x) >= 0 && length(x) <= 50, Interval{Int}),
    savefig_path=joinpath(results_folder, "v$(nvariable)_repr_max_3bin_wleq25g1")
)

_repr_binedges = binedges(discretizer, sort(_repr_dis))
rhand_y_repr_dis = plot(
    _repr_dis, framestyle=:box, alpha=1, labels="")
plot!(X_df_1_have_command[:,nvariable], framestyle=:box, alpha=0.1, labels="")
hline!(
    _repr_binedges,
    linestyle=:dash, linewidth=2,
    labels="Binning threshold (raw signal)", color=threshold_color
)
hline!(
    _repr_coarse_binedges,
    linestyle=:dot, linewidth=2,
    labels="Binning threshold (max on all intervals)", color=:red
)
title!("Representative right hand signal binned")
savefig(rhand_y_repr_dis, joinpath(results_folder, "v$(nvariable)_rpr_binned_max_3bin_wlq50g25.png"))


# we try to find the best range to approximate the original binning (on the raw signal)
_best_match_mse = 999
_best_match_binning = nothing
_best_match_start = 1
_best_match_end = 2

# we want atleast a length of 5, to avoid the degenerate case of testing 1-lenght intervals
for (_start, _end) in Iterators.product(1:50, 1:50)
    # valid intervals condition
    if _start > _end
        continue
    end

    try
        # we want to test which binning is the best
        _, _binedges = plot_binning(
            [_repr_dis], _feature, discretizer;
            worldfilter=SoleLogics.FunctionalWorldFilter(
                # bounds are 5 and 10, which are 10% and 20% of the original series length
                x -> length(x) >= _start && length(x) <= _end, Interval{Int}),
            _binedges_only=true
        )

        # we cut the extrema and compare only the inner values
        # we want to isolate a pair from the original raw binning on the representative
        # distribution;
        _mse = _mse_between_pairs(
            _remove_extrema(_repr_binedges), _remove_extrema(_binedges))

        if _mse < _best_match_mse
            _best_match_mse = _mse
            _best_match_binning = _binedges
            _best_match_start = _start
            _best_match_end = _end
        end
    catch
        # possible reasons: no bins remaining error from length >= 26 onwards
        continue
    end

    # plot every possible combination of interval lengths
    # rhand_y_repr_dis = plot(
    #     _repr_dis, framestyle=:box, alpha=1, labels="")
    # plot!(X_df_1_have_command[:,nvariable], framestyle=:box, alpha=0.1, labels="")
    # hline!(
    #     _repr_binedges,
    #     linestyle=:dash, linewidth=2,
    #     labels="Binning threshold (raw signal)", color=threshold_color
    # )
    # hline!(
    #     _binedges,
    #     linestyle=:dot, linewidth=2,
    #     labels="Binning threshold (max on intervals i s.t. $(_start) <= |i| <= " *
    #         "$(_end))", color=:red
    # )
    # title!("Representative right hand signal binned")
    # savefig(rhand_y_repr_dis, joinpath(
    #         results_folder,
    #         "v$(nvariable)_rpr_binned_max_3bin_wleq$(_start)g$(_end)"
    #     )
    # )

end

# we plot the binning obtained for the optimal case (which minimizes MSE)

rhand_y_repr_dis = plot(
    _repr_dis, framestyle=:box, alpha=1, labels="")
plot!(X_df_1_have_command[:,nvariable], framestyle=:box, alpha=0.1, labels="")
hline!(
    _repr_binedges,
    linestyle=:dash, linewidth=2,
    labels="Binning threshold (raw signal)", color=threshold_color
)
hline!(
    _best_match_binning,
    linestyle=:dot, linewidth=2,
    labels="Binning threshold (max on intervals i s.t. $(_best_match_start) <= |i| <= " *
        "$(_best_match_end))", color=:red
)
title!("Representative right hand signal binned")
savefig(rhand_y_repr_dis, joinpath(
        results_folder,
        "v$(nvariable)_rpr_binned_max_3bin_wleq$(_best_match_start)g$(_best_match_end)"
    )
)



# first of all, let's plot the right hand Y original signal
rhand_y_signal_plot = plot(
    X_df_1_have_command[1,nvariable],
    framestyle=:box, labels="Right hand tips Y coordinate",
    color=signal_color, alpha=0.25
)
hline!(
    _domainexpert_thresholds,
    linestyle=:dash, linewidth=2,
    labels="Intuitive thresholding point", color=threshold_color
)
title!("Right hand signal")
savefig(rhand_y_signal_plot, joinpath(results_folder, "v$(nvariable)_3bin.png"))

# now, we apply the feature to each subinterval and show the result
plot_binning(
    X_df_1_have_command[:,nvariable], _feature, discretizer;
    savefig_path=joinpath(results_folder, "v$(nvariable)_modal_max_3bin")
)

# we try to use a filter to consider granular worlds ...
_, _granular_binedges = plot_binning(
    X_df_1_have_command[:,nvariable], _feature, discretizer;
    worldfilter=SoleLogics.FunctionalWorldFilter(
        # bounds are 0% and 50% of the original series length (GRANULAR RESULT)
        x -> length(x) >= 1 && length(x) <= 25, Interval{Int}),
    savefig_path=joinpath(results_folder, "v$(nvariable)_modal_max_3bin_wleq25g1")
)

rhand_y_modal_plot = plot(
    X_df[1:30,nvariable], framestyle=:box, labels="", color=signal_color, alpha=0.25)
hline!(
    _domainexpert_thresholds,
    linestyle=:dash, linewidth=2,
    labels="Intuitive thresholding point", color=threshold_color
)
hline!(_granular_binedges[2:length(_granular_binedges)-1],
    linewidth=2, linestyle=:dash, labels="Bin edge", color=bin_edge_color)
title!("Right hand signal, intervals i such that 1 <= |i| <= 25")
savefig(
    rhand_y_modal_plot,
    joinpath(results_folder, "v$(nvariable)_3bin_granular_wleq25g1.png")
)

# ... coarse worlds ...
_, _coarse_binedges = plot_binning(
    X_df_1_have_command[:,nvariable], _feature, discretizer;
    worldfilter=SoleLogics.FunctionalWorldFilter(
        # bounds are 50% and 99% of the original series length (GRANULAR RESULT)
        x -> length(x) >= 25 && length(x) <= 50, Interval{Int}),
    savefig_path=joinpath(results_folder, "v$(nvariable)_modal_max_3bin_wleq50g25")
)

rhand_y_modal_plot = plot(
    X_df[1:30,nvariable], framestyle=:box, labels="", color=signal_color, alpha=0.25)
hline!(
    _domainexpert_thresholds,
    linestyle=:dash, linewidth=2,
    labels="Intuitive thresholding point", color=threshold_color
)
hline!(_coarse_binedges[2:length(_coarse_binedges)-1],
    linewidth=2, linestyle=:dash, labels="Bin edge", color=bin_edge_color)
title!("Right hand signal, intervals i such that 25 <= |i| <= 50")
savefig(rhand_y_modal_plot,
    joinpath(results_folder, "v$(nvariable)_3bin_granular_wleq50g25.png")
)

# let's find the right size by trying all the possible ranges
for (_start, _end) in Iterators.product(1:50, 1:50)

    if _start > _end
        continue
    end

    _, _binedges = plot_binning(
        X_df_1_have_command[:,nvariable], _feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            # bounds are 5 and 10, which are 10% and 20% of the original series length
            x -> length(x) >= _start && length(x) <= _end, Interval{Int}),
        _binedges_only=true
    )
end

# and just the right size:
# we try to use a filter to consider worlds in a more granular fashion;
# then, we plot the just found thresholds in the original distribution
_, _good_binedges = plot_binning(
    X_df_1_have_command[:,nvariable], _feature, discretizer;
    worldfilter=SoleLogics.FunctionalWorldFilter(
        # bounds are 5 and 10, which are 10% and 20% of the original series length
        x -> length(x) >= 1 && length(x) <= 10, Interval{Int}),
    savefig_path=joinpath(results_folder, "v$(nvariable)_modal_max_3bin_wleq10g5")
)
# remove extrema from the binning edges
_good_binedges = _good_binedges[2:length(_good_binedges)-1]

rhand_y_modal_plot = plot(
    X_df[1:30,nvariable], framestyle=:box, labels="", color=signal_color, alpha=0.25)
hline!(
    _domainexpert_thresholds,
    linestyle=:dash, linewidth=2,
    labels="Intuitive thresholding point", color=threshold_color
)
hline!(_good_binedges,
    linewidth=2, linestyle=:dash, labels="Bin edge", color=bin_edge_color)
title!("Right hand signal, intervals i such that 5 <= |i| <= 10")
savefig(
    rhand_y_modal_plot,
    joinpath(results_folder, "v$(nvariable)_3bin_granular_wleq10g5.png")
)

# let's see if the strategy of always considering intervals whose length is between 5 and 10
# is always feasible
for nvariable in [4,6]
    _feature = VariableMax(nvariable)

    _, _good_binedges = plot_binning(
        X_df_1_have_command[:,nvariable], _feature, discretizer;
        worldfilter=SoleLogics.FunctionalWorldFilter(
            # bounds are 5 and 10, which are 10% and 20% of the original series length
            x -> length(x) >= 5 && length(x) <= 10, Interval{Int}),
        savefig_path=joinpath(results_folder, "v$(nvariable)_modal_max_3bin_wleq10g5")
    )

    _modal_plot = plot(
        X_df[1:30,nvariable], framestyle=:box, label="", color=signal_color, alpha=0.25)
    hline!(_good_binedges[2:length(_good_binedges)-1],
        linewidth=2, linestyle=:dash, labels="Bin edge", color=bin_edge_color)
    title!("V$(nvariable), intervals i such that 5 <= |i| <= 10")
    savefig(
        _modal_plot, joinpath(results_folder, "v$(nvariable)_3bin_granular_wleq10g5.png"))
end
