# consider the variable targetted by feature (feature.i_variable);
# return a sorted list of its separation values.
function _cut(X_df::DataFrame, feature::Function, var::Integer, cutpolitic::Function)
    vals = map(x -> feature(x), X_df[:,var])
    return cutpolitic(vcat(vals))
end

"""
    function equicut(
        X_df::DataFrame,
        feature::Function,
        var::Integer;
        distance::Integer=3,
        keepleftbound=true
    )

Bin [`DataFrame`](@ref) values into discrete, equispaced intervals.
Spacing is given by the `distance` parameter. For example, the range 1:10 is splitted
in unit ranges shaped as 1:(1+distance), (1+distance):(1+distance*2), and so on.

Return the separation values between ranges, sorted increasingly.
"""
function equicut(
    X_df::DataFrame,
    feature::Function,
    var::Integer;
    distance::Integer=3,
    keepleftbound=true
)
    function _equicut(vals::Vector{Float64})
        unique!(vals)
        if !issorted(vals)
            sort!(vals)
        end

        valslen = length(vals)
        if distance >= valslen
            throw(ErrorException("Distance $(distance) is higher than unique values to " *
                "bin, which is $(valslen). Please lower the distance."))
        end

        ranges = collect(Iterators.partition(1:valslen, distance))
        bounds = [vals[last(r)] for r in ranges]
        if keepleftbound
            append!(bounds, vals[1])
        end
        return bounds |> unique |> sort
    end
    # return the thresholds associated with each feature
    return _cut(X_df, feature, var, _equicut)
end

"""
    function quantilecut(
        X_df::DataFrame,
        feature::Function,
        var::Integer;
        nbins::Integer = 3
    )

Bin [`DataFrame`](@ref) values in equal-sized bins.

Return the sorted separation values vector for each variable.
"""
function quantilecut(
    X_df::DataFrame,
    feature::Function,
    var::Integer;
    nbins::Integer=3
)
    function _quantilecut(vals::Vector{Float64})
        h = fit(Histogram, vals, nbins=nbins)
        return collect(h.edges...)
    end
    return _cut(X_df, feature, var, _quantilecut)
end

"""
    function makeconditions(
        thresholds::Vector{<:Real},
        nvariables::Vector{Int64},
        features::Vector{DataType},
        testops::Vector{SoleData.TestOperator};
        conditiontype = ScalarCondition
    )

Return the atoms wrapping all the possible conditions shaped as
    condition(feature(nvariable) testop threshold)
such as
    `ScalarCondition(VariableMin(1), >, -0.5)`
whose [`syntaxstring`](@ref) is
    `min[V3] > 1.1`

    See also [`syntaxstring`](@ref), [`SoleData.TestOperator`](@ref),
[`SoleLogics.UnivariateFeature`](@ref).
"""
function makeconditions(
    thresholds::Vector{<:Real},
    nvariables::Vector{Int64},
    features::Vector{DataType}, # NOTE: this should be Vector{<:AbstractFeature}
    testops::Vector{SoleData.TestOperator};
    conditiontype = ScalarCondition
)
    return IterTools.imap(
        ((threshold, i_variable, feature, testop),) -> begin
            Atom(conditiontype(feature(i_variable), testop, threshold))
        end,
        IterTools.product(thresholds, nvariables, features, testops)
    )
end
