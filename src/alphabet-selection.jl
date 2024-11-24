using Discretizers
using Distributions
using Plots
using Plots.Measures
using SoleData: AbstractCondition

"""
    function select_alphabet(
        X::Vector{<:Real},
        metaconditions::Vector{<:AbstractCondition},
        discretizers::Vector{<:DiscretizationAlgorithm}
    )
    function select_alphabet(
        X::Vector{<:Vector{<:Real}},
        metaconditions::Vector{<:AbstractCondition},
        discretizers::Vector{<:DiscretizationAlgorithm}
    )

Select an alphabet, that is, a set of [`Item`](@ref)s wrapping `SoleData.AbstractCondition`.

# Arguments
- `X::Vector{<:Vector{<:Real}}`: dataset column containing real numbers or real vectors;
- `metaconditions::Vector{<:AbstractCondition}`: abstract type for representing conditions
    that can be interpreted end evaluated on worlds of logical dataset instances
    (e.g., a generic "max[V1] ≤ ⍰" where "?" is a threshold that has to be defined);
- `discretizers::Vector{<:DiscretizationAlgoritm}`: a strategy to perform binning over
    a distribution.

# Examples
```julia
julia> X, _ = load_NATOPS()

# to generate an alphabet, we choose a variable (a column of X) and our metaconditions
julia> variable = 1
julia> metaconditions = [
    ScalarMetaCondition(VariableMax(variable), <=),
    ScalarMetaCondition(VariableMin(variable), >=)
]
2-element Vector{ScalarMetaCondition}:
 ScalarMetaCondition{VariableMax{Int64}, typeof(<=)}: max[V1] ≤ ⍰
 ScalarMetaCondition{VariableMin{Int64}, typeof(>=)}: min[V1] ≥ ⍰

# we choose how we want to discretize the distribution of the variable
julia> nbins = 5
julia> _uniform_width_discretizer = Discretizers.DiscretizeUniformWidth(nbins)
julia> _quantile_discretizer = Discretizers.DiscretizeQuantile(nbins)
julia> discretizers = [_uniform_width_discretizer, _quantile_discretizer]

# we obtain one alphabet for each strategy
julia> alphabets = select_alphabet(X[1:30,variable], metaconditions, discretizers)
julia> syntaxstring.(alphabets[_quantile_discretizer])
12-element Vector{String}:
 "max[V1] ≤ -1.02"
 "min[V1] ≥ -1.02"
 "max[V1] ≤ -0.63"
 "min[V1] ≥ -0.63"
 "max[V1] ≤ -0.57"
 "min[V1] ≥ -0.57"
 "max[V1] ≤ -0.5"
 "min[V1] ≥ -0.5"
 "max[V1] ≤ -0.44"
 "min[V1] ≥ -0.44"
 "max[V1] ≤ -0.31"
 "min[V1] ≥ -0.31"

See also `Discretizers.DiscretizationAlgorithm`, [`Item`](@ref),
`SoleData.AbstractCondition`.
 ```
"""
function select_alphabet(
    X::Vector{<:Real},
    metaconditions::Vector{<:AbstractCondition},
    discretizers::Vector{<:DiscretizationAlgorithm};
    remove_extrema::Bool=true
)
    alphabets = Dict{DiscretizationAlgorithm,Vector{<:AbstractCondition}}()

    # for each strategy, found the edges of each bin
    for discretizer in discretizers
        _binedges = binedges(discretizer, X)

        # extrema bins are removed, if requested and if possible
        if remove_extrema
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
        alphabets[discretizer] = Vector{AbstractCondition}()
        for (condition, threshold) in Iterators.product(metaconditions, _binedges)
            push!(
                alphabets[discretizer],
                ScalarCondition(condition, round(threshold, digits=2))
            )
        end
    end

    return alphabets
end

function select_alphabet(
    X::Vector{<:Vector{<:Real}},
    metaconditions::Vector{<:AbstractCondition},
    discretizers::Vector{<:DiscretizationAlgorithm}
)
    return select_alphabet(reduce(vcat,X), metaconditions, discretizers)
end

"""
    function time_series_distribution_analysis(
        X::Vector{<:Vector{<:Real}};
        n_uniform_width_bins::Integer=5,
        n_quantile_bins::Integer=5,
        select_alphabet::Bool=true,
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
- `select_alphabet::Bool=true`: show a possible extracted alphabet in an additional plot,
    using [`select_alphabet`](@ref) with two default [`ScalarMetaCondition`](@ref)s and
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
    select_alphabet::Bool=true,
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
    if !select_alphabet
        text_content = "No additional informations.\nSet `select_alphabet=true` to show."
    else
        # `select_alphabet` returns a map from strategy to alphabet,
        # this is why there are square brackets at the end of the function call.
        alphabet = ModalAssociationRules.select_alphabet(
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
