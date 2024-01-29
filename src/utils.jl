# shared logic amongs methods that performs binning;
# see equicut and quantilecut
function _cut(X_df::DataFrame, cutpolitic::Function)
    ncols = nvariables(X_df)

    # for each variable, store a sorted list of its separation values
    ans = Vector{Vector{Float64}}([])

    for col in 1:ncols
        vals = vcat(X_df[:,col]...)
        push!(ans, cutpolitic(vals))
    end

    return ans
end

"""
Bin [`DataFrame`](@ref) values into discrete, equispaced intervals.
Return the sorted separation values vector for each variable.
"""
function equicut(X_df::DataFrame; nbins=3, keepbounds=false)

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

    return _cut(X_df, _equicut)
end

"""
Bin [`DataFrame`](@ref) values in equal-sized bins.
Return the sorted separation values vector for each variable.
"""
function quantilecut(X_df::DataFrame; nbins=3)

    function _quantilecut(vals::Vector{Float64})
        h = fit(Histogram, vals, nbins=nbins)
        return vals[sort(h.weights)]
    end

    return _cut(X_df, _quantilecut)
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
