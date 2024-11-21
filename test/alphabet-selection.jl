using Discretizers
using Distributions
using ModalAssociationRules
using Plots
using Plots.Measures
using Test

"""
    function distribution_analysis(X::Vector{T}) where {T<:Vector{<:Float64}}

Study the column `X` of a dataset, where each element represents a time series.
The study is returned under the form of plots. In particular:

- all the normal distributions (the pairs (μ,σ) are computed for each vector);
- the normal distribution obtained by computing the mean of all (μ,σ) pairs;
- various binning techniques (see Arguments section) applied on the previous plot:
    binning techniques are implemented in `Discretizers` package.

# Arguments
- `X`: a list of time series;
- `n_uniform_width_bins`=5: number of bins computed by `DiscretizeUniformWidth` strategy;
- `n_quantile_bins`=5: number of bins computed by `DiscretizeQuantile` strategy;
- `palette`=palette(:batlow10): plots color palette.
"""
function distribution_analysis(
    X::Vector{T};
    n_uniform_width_bins::Integer=5,
    n_quantile_bins::Integer=5,
    palette::ColorPalette=palette(:batlow10)
) where {T<:Vector{<:Float64}}
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
    plot!(xaxis, pdfₓ, label="", title="(μ,σ) as means of (μᵢ,σᵢ)", show=false)

    # normal parameters of all the given values
    pdfᵥ = pdf.(Normal(μᵥ, σᵥ), xaxis)

    # plot equispaced discretization
    uniform_width_discretizer = DiscretizeUniformWidth(n_uniform_width_bins)
    uniform_width_binedges = binedges(uniform_width_discretizer, V)
    p3 = plot(xaxis, pdfᵥ, label="", title="Uniform width (nbins=$(n_uniform_width_bins))")
    vline!(p3, uniform_width_binedges, label="", color=:green, linestyle=:dash)

    # plot quantile-based discretization
    quantile_discretizer = DiscretizeQuantile(n_quantile_bins)
    quantile_binedges = binedges(quantile_discretizer, V)
    p4 = plot(xaxis, pdfᵥ, label="", title="Uniform area (nbins=$(n_quantile_bins))")
    vline!(p4, quantile_binedges, label="", color=:green, linestyle=:dash)

    layout = @layout [a b; c d]
    return plot(p1, p2, p3, p4, layout=layout, framestyle=:box, size=(1280, 1024))
end

X, _ = load_NATOPS();
distribution_analysis(X[:,21])
