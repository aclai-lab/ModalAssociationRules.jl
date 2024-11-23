using Discretizers
using Distributions
using ModalAssociationRules
using Plots
using Plots.Measures
using SoleData: AbstractCondition
using Test

"""
    function distribution_analysis(X::Vector{T}) where {T<:Vector{<:Float64}}

Study the column `X` of a dataset, where each element represents a time series.
The study is returned under the form of plots. In particular:

- all the normal distributions (the pairs (μ,σ) are computed for each vector);
- the normal distribution obtained by computing the mean of all (μ,σ) pairs;
- various binning techniques (see Arguments section) applied on the previous plot:
    binning techniques are implemented in `Discretizers` package (see [here
    ](https://nbviewer.org/github/sisl/Discretizers.jl/blob/master/doc/Discretizers.ipynb)).

# Arguments
- `X`: a list of time series;
- `n_uniform_width_bins`=5: number of bins computed by `DiscretizeUniformWidth` strategy;
- `n_quantile_bins`=5: number of bins computed by `DiscretizeQuantile` strategy;
- `palette`=palette(:batlow10): plots color palette;
- `plot_title_variable`="?": string which specifies which variable is being analysed;
- `plot_title_additional_info=""`: string injected at the end of the title;
- `save`=true: whether the resulting plot is saved or no;
- `savepath`=joinpath(@__DIR__, "test", "analyses"): directory in which the plot is saved;
- `filename_metadata`=".plot": string injected before the .png extension of each plot.
"""
function distribution_analysis(
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
    default(palette = palette)

    # aggregate all the vectors in X, in one vector (this will be needed later)
    V = reduce(vcat, X)
    μᵥ, σᵥ = mean(V), std(V)

    # plot of all the normal distributions for the first class
    p1 = plot()
    for v in X
        μ, σ = mean(v), std(v)
        xaxis = range(minimum(v), stop=maximum(v), length=100)
        pdfᵥ = pdf.(Normal(μ, σ), xaxis)
        plot!(xaxis, pdfᵥ, label="", title="All the distributions", show=false);
    end

    # plot by mean of means and standard deviations
    global_minimum, global_maximum = (v -> (minimum(v), maximum(v)))(V)
    xaxis = range(global_minimum, stop=global_maximum, length=100)

    p2 = plot()
    μₓ, σₓ = mean(mean.(X)), mean(std.(X)) # note how this is different from mean(V), std(V)
    pdfₓ = pdf.(Normal(μₓ, σₓ), xaxis)
    plot!(xaxis, pdfₓ, label="", title="N(μ,σ) as means of N(μᵢ,σᵢ)", show=false)

    # normal parameters of all the given values
    pdfᵥ = pdf.(Normal(μᵥ, σᵥ), xaxis)

    # plot equispaced discretization
    uniform_width_binedges = binedges(DiscretizeUniformWidth(n_uniform_width_bins), V)
    p3 = plot(xaxis, pdfᵥ, label="", title="Uniform width (nbins=$(n_uniform_width_bins))")
    vline!(p3, uniform_width_binedges, label="", color=:red, alpha=0.75, linewidth=2)
    histogram!(V, bins=100, label="", alpha=0.25, normalize=true)

    # plot quantile-based discretization
    quantile_binedges = binedges(DiscretizeQuantile(n_quantile_bins), V)
    p4 = plot(xaxis, pdfᵥ, label="", title="Uniform area (nbins=$(n_quantile_bins))")
    vline!(p4, quantile_binedges, label="", color=:red, alpha=0.75, linewidth=2)
    histogram!(V, bins=100, label="", alpha=0.25, normalize=true)

    layout = @layout [a b; c d]
    final_plot = plot(p1, p2, p3, p4,
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

"""
    function select_alphabet(
        X::Vector{<:Vector{<:Real}},
        metaconditions::Vector{<:AbstractCondition},
        discretizers::Vector{<:DiscretizationAlgorithm}
    )

TODO
"""
function select_alphabet(
    X::Vector{<:Vector{<:Real}},
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

# driver section
X, _ = load_NATOPS();

# to generate an alphabet, we choose a variable and our metaconditions
variable = 1
metaconditions = [
    ScalarMetaCondition(VariableMax(variable), <=),
    ScalarMetaCondition(VariableMin(variable), >=)
]

# then, the number of bins and the discretization strategies
nbins = 5
_uniform_width_discretizer = DiscretizeUniformWidth(nbins)
_quantile_discretizer = DiscretizeQuantile(nbins)
discretizers = [_uniform_width_discretizer, _quantile_discretizer]

# we obtain one alphabet for each strategy
alphabets = select_alphabet(X[1:30,variable], metaconditions, discretizers)

# now, we choose how to mix up all the obtained literals;
# for example, we choose to only focus on quantile-based discretization.
alphabet = alphabets[_quantile_discretizer]
println("Extracted alphabet for discretizer $(_quantile_discretizer)")
println(syntaxstring.(alphabet))

# we also log a graphical report of all the binnings
for variable in variables(X)
    distribution_analysis(
        X[1:30,variable],
        n_uniform_width_bins=5,
        n_quantile_bins=5,
        plot_title_variable=variable,
        plot_title_additional_info="for the first class",
        save=true,
        filename_metadata="all"
    )
end
