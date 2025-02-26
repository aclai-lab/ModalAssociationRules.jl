using Discretizers
using Distributions
using ModalAssociationRules
using Plots
using Plots.Measures
using SoleData: AbstractCondition
using Test


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
_alphabets = __arm_select_alphabet(X[1:30,variable], metaconditions, discretizers)

# now, we choose how to mix up all the obtained literals;
# for example, we choose to only focus on quantile-based discretization.
_alphabet = _alphabets[_quantile_discretizer]
println("Extracted alphabet for discretizer $(_quantile_discretizer)")
println(syntaxstring.(_alphabet))

# we also log a graphical report of all the binnings
for variable in variables(X)
    time_series_distribution_analysis(
        X[1:30,variable],
        n_uniform_width_bins=5,
        n_quantile_bins=5,
        __arm_select_alphabet=true,
        plot_title_variable=variable,
        plot_title_additional_info="for the first class",
        save=true,
        savepath=joinpath(@__DIR__, "test", "analyses"),
        filename_metadata="class1"
    )
end
