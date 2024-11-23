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
    X::Vector{T};
    n_uniform_width_bins::Integer=5,
    n_quantile_bins::Integer=5,
    palette::ColorPalette=palette(:batlow10),
    plot_title_variable="?",
    plot_title_additional_info="",
    save::Bool=true,
    savepath::String=joinpath(@__DIR__, "test", "analyses"),
    filename_metadata::String=".plt"
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

    p3 = histogram(V, bins=30, label="", title="Histogram", alpha=0.5)

    # normal parameters of all the given values
    pdfᵥ = pdf.(Normal(μᵥ, σᵥ), xaxis)

    # plot equispaced discretization
    uniform_width_binedges = binedges(DiscretizeUniformWidth(n_uniform_width_bins), V)
    p4 = plot(xaxis, pdfᵥ, label="", title="Uniform width (nbins=$(n_uniform_width_bins))")
    vline!(p4, uniform_width_binedges, label="", color=:red, linestyle=:dash)

    # plot quantile-based discretization
    quantile_binedges = binedges(DiscretizeQuantile(n_quantile_bins), V)
    p5 = plot(xaxis, pdfᵥ, label="", title="Uniform area (nbins=$(n_quantile_bins))")
    vline!(p5, quantile_binedges, label="", color=:green, linestyle=:dash)

    p6 = histogram(V, bins=quantile_binedges,
        label="", title="Histogram (bins of equal area)")

    layout = @layout [a b c; d e f]
    final_plot = plot(p1, p2, p3, p4, p5, p6,
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

X, _ = load_NATOPS();

for variable in variables(X)
    distribution_analysis(
        X[1:30,variable],
        plot_title_variable=variable,
        plot_title_additional_info="for the first class",
        save=true,
        filename_metadata="all"
    )
end
