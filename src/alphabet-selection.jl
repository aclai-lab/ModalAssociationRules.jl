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
    discretizers::Vector{<:DiscretizationAlgorithm}
)
    V = reduce(vcat, X)
    alphabets = Dict{DiscretizationAlgorithm,Vector{<:AbstractCondition}}()

    for discretizer in discretizers
        _binedges = binedges(discretizer, V)

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
    function time_series_distribution_analysis(X::Vector{T}) where {T<:Vector{<:Float64}}

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
    palette::ColorPalette=palette(:batlow10),
    plot_title_variable="?",
    plot_title_additional_info="",
    save::Bool=true,
    savepath::String=joinpath(@__DIR__, "test", "analyses"),
    filename_metadata::String=".plt"
)
    default(palette=palette)

    global_minimum, global_maximum = (v -> (minimum(v), maximum(v)))(V)
    xaxis = range(global_minimum, stop=global_maximum, length=100)

    # the simplest plot: print everything
    plot_all_distributions = plot()
    for v in X
        plot!(xaxis, v, label="", title="Every time series")
    end

    # aggregate all the vectors in X, in one vector (this will be needed later)
    V = reduce(vcat, X)
    μᵥ, σᵥ = mean(V), std(V)

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
    uniform_width_binning_plot = plot(
        xaxis, pdfᵥ, label="", title="Uniform width (nbins=$(n_uniform_width_bins))")
    vline!(
        uniform_width_binning_plot, uniform_width_binedges,
        label="", color=:red, alpha=0.75, linewidth=2)
    histogram!(V, bins=100, label="", alpha=0.25, normalize=true)

    # plot quantile-based discretization
    quantile_binedges = binedges(DiscretizeQuantile(n_quantile_bins), V)
    uniform_area_binning_plot = plot(
        xaxis, pdfᵥ, label="", title="Uniform area (nbins=$(n_quantile_bins))")
    vline!(uniform_area_binning_plot, quantile_binedges,
        label="", color=:red, alpha=0.75, linewidth=2)
    histogram!(V, bins=100, label="", alpha=0.25, normalize=true)

    layout = @layout [a b c; d e]
    final_plot = plot(
        plot_all_distributions, plot_all_normals, plot_normals_aggregation,
        uniform_width_binning_plot, uniform_area_binning_plot,
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
