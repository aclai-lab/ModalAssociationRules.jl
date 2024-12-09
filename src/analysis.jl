using Discretizers
using Plots
using Plots.Measures


"""
TODO
"""
function plot_arule_analyses(
    miner::AbstractMiner;
    glift_boundaries::Tuple{Float64,Float64}=(0.7,1.3)
)
    supp_vs_confidence_plot = plot(
        xlims=(0, 1.05), ylims=(0, 1.05),
        xlabel="Support", ylabel="Confidence",
        title="Support vs Confidence",
        framestyle=:box
    )

    # find minimum and maximum lift

    for r in arules(miner)
        # x,y,z coordinates
        _gsupport = [globalmemo(miner, (:gsupport, Itemset(r)))]
        _gconfidence = [globalmemo(miner, (:gconfidence, r))]
        _glift = globalmemo(miner, (:glift, r))

        # TODO: transparency depends on lift level

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


"""
Utility function to generate ad-hoc plots for certain kind of experiments.
Simply plot how binning is performed

# Examples
```julia

using ModalAssociationRules
using Discretizers

julia> X_df, _ = load_NATOPS()
julia> X = scalarlogiset(X_df)
julia> X_df_1_have_command = X_df[1:30,:]

# choose the feature that is going to be applied to each sub-interval
julia> nvariable = 5 # this column (V5) represents the Y axis of the right hand
julia> _feature = VariableMax(nvariable)

# choose the discretization strategy (same area, 3 bins)
julia> nbins = 3
julia> discretizer = Discretizers.DiscretizeQuantile(nbins)

# choose a world filtering rule
julia> worldfilter = SoleLogics.FunctionalWorldFilter(
    x -> length(x) >= 10 && length(x) <= 20, Interval{Int})

# now we can visualize the binning across a column
julia> ModalAssociationRules.plot_binning(
    X_df_1_have_command[:,nvariable], _feature, discretizer, worldfilter)
```
"""
function plot_binning(
    X::Vector{<:Vector{<:Real}},
    _feature::AbstractFeature,
    discretizer::DiscretizationAlgorithm;
    worldfilter::SoleLogics.FunctionalWorldFilter=SoleLogics.FunctionalWorldFilter(
        _ -> true, Interval{Int}
    ),
    label="",
    savefig_path::String="",
    _display::Bool=false
)
    _X = [
        SoleData.computeunivariatefeature(_feature, v[i:j])
        # for each vector, we consider the superior triangular matrix
        for v in X
        for i in 1:length(v)
        for j in i+1:length(v)

        if worldfilter.filter(Interval(i,j))
    ]

    sort!(_X)

    _binedges = binedges(discretizer, _X)
    _histogram = histogram(
        _X, label=label, xlabel=syntaxstring(_feature), ylabel="# occurrences")

    for edge in _binedges
        vline!([edge], color=:red, linewidth=2, label=false)
    end

    p = plot!(_histogram, margin=5mm, framestyle=:box)
    savefig(p, savefig_path)

    if _display
        display(_histogram)
    end

    return p, _binedges
end


"""
    function time_series_distribution_analysis(
        X::Vector{<:Vector{<:Real}};
        n_uniform_width_bins::Integer=5,
        n_quantile_bins::Integer=5,
        __arm_select_alphabet::Bool=true,
        palette::ColorPalette=palette(:batlow10),
        plot_title_variable="?",
        plot_title_additional_info="",
        save::Bool=true,
        savepath::String=joinpath(@__DIR__, "test", "analyses"),
        filename_metadata::String=".plt"
    )

Study the column `X` of a dataset, where each element represents a time series.
The study is returned under the form of plots. In particular:

- all the normal distributions (the pairs (μ,σ) are computed for each vector);
- the normal distribution obtained by computing the mean of all (μ,σ) pairs;
- various binning techniques (see Arguments section) applied on the previous plot:
    binning techniques are implemented in `Discretizers` package (see [here
    ](https://nbviewer.org/github/sisl/Discretizers.jl/blob/master/doc/Discretizers.ipynb)).

# Arguments
- `X::Vector{<:Vector{<:Real}}`: a list of time series;
- `n_uniform_width_bins::Integer=5`: number of bins computed by `DiscretizeUniformWidth`
    strategy;
- `n_quantile_bins::Integer=5`: number of bins computed by `DiscretizeQuantile` strategy;
- `__arm_select_alphabet::Bool=true`: show a possible extracted alphabet in an additional plot,
    using [`__arm_select_alphabet`](@ref) with two default [`ScalarMetaCondition`](@ref)s and
    `Discretizers.DiscretizeQuantile(n_quantile_bins)` as discretization strategy.
- `palette::ColorPalette=palette(:batlow10)`: plots color palette;
- `plot_title_variable::Any="?"`: string which specifies which variable is being analysed;
- `plot_title_additional_info::Any=""`: string injected at the end of the title;
- `save::Bool=true`: whether the resulting plot is saved or no;
- `savepath::String=joinpath(@__DIR__, "test", "analyses")`: directory in which the plot is
    saved;
- `filename_metadata::String=".plot"`: string injected before the .png extension of each
    plot.
"""
function time_series_distribution_analysis(
    X::Vector{<:Vector{<:Real}};
    n_uniform_width_bins::Integer=5,
    n_quantile_bins::Integer=5,
    __arm_select_alphabet::Bool=true,
    palette::ColorPalette=palette(:batlow10),
    plot_title_variable="?",
    plot_title_additional_info="",
    save::Bool=true,
    savepath::String=joinpath(@__DIR__, "test", "analyses"),
    filename_metadata::String=".plt"
)
    default(palette=palette)

    # aggregate all the vectors in X, in one vector (this will be needed later)
    V = reduce(vcat, X)
    μᵥ, σᵥ = mean(V), std(V)

    # global minimum & maximum, and xaxis are needed everywhere from now onwards
    _global_minimum, _global_maximum = (v -> (minimum(v), maximum(v)))(V)
    xaxis = range(_global_minimum, stop=_global_maximum, length=100)

    # the simplest plot: print everything
    plot_all_distributions = plot()
    for v in X
        plot!(v, label="", title="Every time series")
    end

    # plot of all the normal distributions for the first class
    plot_all_normals = plot()
    for v in X
        μ, σ = mean(v), std(v)
        xaxis = range(minimum(v), stop=maximum(v), length=100)
        pdfᵥ = pdf.(Normal(μ, σ), xaxis)
        plot!(xaxis, pdfᵥ, label="", title="Every normal distribution", show=false);
    end

    # plot by mean of means and standard deviations
    plot_normals_aggregation = plot()
    μₓ, σₓ = mean(mean.(X)), mean(std.(X)) # note how this is different from mean(V), std(V)
    pdfₓ = pdf.(Normal(μₓ, σₓ), xaxis)
    plot!(xaxis, pdfₓ, label="", title="N(μ,σ) as means of N(μᵢ,σᵢ)", show=false)

    # normal parameters of all the given values
    pdfᵥ = pdf.(Normal(μᵥ, σᵥ), xaxis)

    # plot equispaced discretization
    uniform_width_binedges = binedges(DiscretizeUniformWidth(n_uniform_width_bins), V)
    uniform_width_binning_plot = plot(xaxis, pdfᵥ,
        label="", title="Uniform width (nbins=$(n_uniform_width_bins))")
    vline!(
        uniform_width_binning_plot, uniform_width_binedges,
        label="", color=:red, alpha=0.75, linewidth=2)
    histogram!(V, bins=100, label="", alpha=0.25, normalize=true)

    # plot quantile-based discretization
    _quantile_discretizer = DiscretizeQuantile(n_quantile_bins)
    quantile_binedges = binedges(_quantile_discretizer, V)
    uniform_area_binning_plot = plot(xaxis, pdfᵥ,
        label="", title="Uniform area (nbins=$(n_quantile_bins))")
    vline!(uniform_area_binning_plot, quantile_binedges,
        label="", color=:red, alpha=0.75, linewidth=2)
    histogram!(V, bins=100, label="", alpha=0.25, normalize=true)


    # dummy plot for printing a possible alphabet
    if !__arm_select_alphabet
        text_content = "No additional informations.\nSet `__arm_select_alphabet=true` to show."
    else
        # `__arm_select_alphabet` returns a map from strategy to alphabet,
        # this is why there are square brackets at the end of the function call.
        alphabet = ModalAssociationRules.__arm_select_alphabet(
            V, [ScalarMetaCondition(VariableMax(Symbol(plot_title_variable)), <=),
                ScalarMetaCondition(VariableMin(Symbol(plot_title_variable)), >=)],
            [_quantile_discretizer]
        )[_quantile_discretizer]

        text_content = join(["Possible alphabet",
            "(obtained applying $(_quantile_discretizer))\n",
            syntaxstring.(alphabet)...],
            "\n"
        )
    end

    text_plot = plot(legend=false, framestyle=:none, axis=false)
    annotate!(text_plot, 0.0, 0.5, text(text_content, :left, 10))

    layout = @layout [a b c; d e f]
    final_plot = plot(
        plot_all_distributions, plot_all_normals, plot_normals_aggregation,
        uniform_width_binning_plot, uniform_area_binning_plot, text_plot,
        layout=layout,
        framestyle=:box,
        size=(1280, 1024),
        plot_title="Analysing $(plot_title_variable) $(plot_title_additional_info)"
    )

    if save
        savefig(
            final_plot,
            joinpath(savepath, "$(plot_title_variable).$(filename_metadata).png")
        )
    else
        return final_plot
    end
end
