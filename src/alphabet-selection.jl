using Discretizers
using Distributions
using Plots
using Plots.Measures
using SoleData: AbstractCondition, computeunivariatefeature, feature

"""
NOTE: this is currently being moved in SoleData, under the name of `select_alphabet`.
Pull request is currently under revision, this method will then be deprecated.

    function __arm_select_alphabet(
        X::Vector{<:Real},
        metacondition::Vector{<:AbstractCondition},
        discretizer::Vector{<:DiscretizationAlgorithm}
    )
    function __arm_select_alphabet(
        X::Vector{<:Vector{<:Real}},
        metacondition::Vector{<:AbstractCondition},
        discretizer::Vector{<:DiscretizationAlgorithm}
    )

Select an alphabet, that is, a set of [`Item`](@ref)s wrapping `SoleData.AbstractCondition`.

# Arguments
- `X::Vector{<:Vector{<:Real}}`: dataset column containing real numbers or real vectors;
- `metacondition::Vector{<:AbstractCondition}`: abstract type for representing a condition
    that can be interpreted end evaluated on worlds of logical dataset instances
    (e.g., a generic "max[V1] ≤ ⍰" where "?" is a threshold that has to be defined);
- `discretizer::Vector{<:DiscretizationAlgoritm}`: a strategy to perform binning over
    a distribution.

# Examples
```julia
julia> using ModalAssociationRules
julia> using Discretizers

julia> X, _ = load_NATOPS()

# to generate an alphabet, we choose a variable (a column of X) and our metacondition
julia> variable = 1
julia> max_metacondition = ScalarMetaCondition(VariableMax(variable), <=)
 ScalarMetaCondition{VariableMax{Integer}, typeof(<=)}: max[V1] ≤ ⍰

# we choose how we want to discretize the distribution of the variable
julia> nbins = 5
# we specify a strategy to perform discretization
julia> discretizer = Discretizers.DiscretizeQuantile(nbins)

# we obtain one alphabet and pretty print it
julia> alphabet1 = __arm_select_alphabet(X[1:30,variable], max_metacondition, discretizer)
julia> syntaxstring.(alphabet1[_quantile_discretizer])
4-element Vector{String}:
 "max[V1] ≤ -0.63"
 "max[V1] ≤ -0.57"
 "max[V1] ≤ -0.5"
 "max[V1] ≤ -0.44"

# for each time series in X (or for the only time series X), consider each possible
# interval and apply the feature on it; if you are considering other kind of dimensional
# data (e.g., spatial), adapt the following list comprehension.
julia> max_applied_on_all_intervals = [
        SoleData.computeunivariatefeature(max_metacondition |> SoleData.feature, v[i:j])
        for v in X[1:30, 1]
        for i in 1:length(v)
        for j in i+1:length(v)
    ]

# now you can call `__arm_select_alphabet` with the new preprocessed time series.
julia> alphabet2 = __arm_select_alphabet(
    max_applied_on_all_intervals, max_metacondition, discretizer)
julia> syntaxstring.(alphabet2)
4-element Vector{String}:
 "max[V1] ≤ -0.61"
 "max[V1] ≤ -0.53"
 "max[V1] ≤ -0.47"
 "max[V1] ≤ -0.4"

# we can obtain the same result as before by simplying setting `consider_all_subintervals`
julia> alphabet3 = __arm_select_alphabet(X[1:30,variable], max_metacondition, discretizer;
            consider_all_subintervals=true)
julia> syntaxstring.(alphabet2)
4-element Vector{String}:
 "max[V1] ≤ -0.61"
 "max[V1] ≤ -0.53"
 "max[V1] ≤ -0.47"
 "max[V1] ≤ -0.4"
```

!!! note
    We could also consider an ad-hoc distribution for a certain feature type;
    for example, when working with a `ScalarMetaCondition` `max[V1] ≤ ⍰` on a time series,
    we could consider each possible sub-interval in the time series and apply `max` on it
    before perform binning.

See also `Discretizers.DiscretizationAlgorithm`, [`Item`](@ref),
`SoleData.AbstractCondition`, `SoleData.ScalarMetaCondition`.
"""
function __arm_select_alphabet(
    X::Vector{<:Real},
    metacondition::AbstractCondition,
    discretizer::DiscretizationAlgorithm;
    cutextrema::Bool=true
)
    alphabet = Vector{AbstractCondition}()

    # for each strategy, found the edges of each bin
    _binedges = binedges(discretizer, X)

    # extrema bins are removed, if requested and if possible
    if cutextrema
        _binedges_length = length(_binedges)
        if _binedges_length <= 2
            throw(
                ArgumentError("Cannot remove extrema: $(_binedges_length) bins found"))
        else
            popfirst!(_binedges)
            pop!(_binedges)
        end
    end

    # for each metacondition, apply a threshold (a bin edge)

    for threshold in _binedges
        push!(alphabet, ScalarCondition(metacondition, round(threshold, digits=2)))
    end

    return alphabet
end

function __arm_select_alphabet(
    X::Vector{<:Vector{<:Real}},
    metacondition::AbstractCondition,
    discretizer::DiscretizationAlgorithm;
    consider_all_subintervals::Bool=false,
    kwargs...
)
    if consider_all_subintervals
        _X = [
                SoleData.computeunivariatefeature(metacondition |> SoleData.feature, v[i:j])
                # for each vector, we consider the superior triangular matrix
                for v in X
                for i in 1:length(v)
                for j in i+1:length(v)
            ]
    else
        _X = reduce(vcat, X)
    end

    return __arm_select_alphabet(_X, metacondition, discretizer; kwargs...)
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
