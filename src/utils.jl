# shared logic amongs methods that performs binning; see equicut and quantilecut.
# Explanation:
# consider the variable targetted by feature (feature.i_variable);
# return a sorted list of its separation values.
function _cut(X_df::DataFrame, feature::AbstractFeature, cutpolitic::Function)
    vals = map(x -> feature([x]), X_df[:,feature.i_variable])
    return cutpolitic(vcat(vals))
end

"""
Bin [`DataFrame`](@ref) values into discrete, equispaced intervals.
Return the sorted separation values vector for each variable.
"""
function equicut(
    X_df::DataFrame;
    # this might be initialized with UnivariateValue
    features::Vector{AbstractFeature}=Vector{AbstractFeature}(
        [UnivariateMin(1), UnivariateMax(1)]
    ),
    nbins=3,
    keepbounds=false
)

    function _equicut(vals::Vector{Float64})
        if !issorted(vals)
           sort!(vals)
        end

        # get bin length
        valslen = length(vals)
        binlen = Integer(floor(valslen / (nbins+1)))

        # if keepbounds is true, also consider 1-index and end-index
        if keepbounds
            # note that binlen:binlen:valslen is different from 1:binlen:valslen,
            # where indexes are [1, binlen+1, (binlen+1)*2, ...]
            return vcat(vals[1], vals[binlen:binlen:valslen])
        else
            return vals[binlen:binlen:valslen-binlen]
        end
    end

    # return the thresholds associated with each feature
    ans = Vector{Vector{Float64}}([])
    for feature in features
        push!(ans, _cut(X_df, feature, _equicut))
    end
    return ans
end

"""
Bin [`DataFrame`](@ref) values in equal-sized bins.
Return the sorted separation values vector for each variable.
"""
function quantilecut(
    X_df::DataFrame;
    features::Vector{AbstractFeature}=Vector{AbstractFeature}(
        [UnivariateMin(1), UnivariateMax(1)]
    ),
    nbins=3
)

    function _quantilecut(vals::Vector{Float64})
        h = fit(Histogram, vals, nbins=nbins)
        return vals[sort(h.weights)]
    end

    ans = Vector{Vector{Float64}}([])
    for feature in features
        print(_cut(X_df, feature, _quantilecut))
        push!(ans, _cut(X_df, feature, _quantilecut))
    end
    return ans
end

"""
Return the atoms wrapping all the possible conditions shaped as
    condition(feature(nvariable) testop threshold)
such as
    `ScalarCondition(UnivariateMin(1), >, -0.5)`
whose [`syntaxstring`](@ref) is
    `min[V3] > 1.1`

See also [`syntaxstring`](@ref), [`SoleModels.TestOperator`](@ref),
[`SoleLogics.UnivariateFeature`](@ref).
"""
function make_conditions(
    thresholds::Vector{Float64},
    nvariables::Vector{Int64},
    features::Vector{DataType}, # NOTE: this could be Vector{<:AbstractFeature}
    testops::Vector{SoleModels.TestOperator};
    condition = ScalarCondition
)
    return [
        Atom(condition(feature(nvariable), testop, threshold))
        for (threshold, nvariable, feature, testop)
            in IterTools.product(thresholds, nvariables, features, testops)
    ]
end
