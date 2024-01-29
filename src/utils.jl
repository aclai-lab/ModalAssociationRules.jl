
"""
Bin [`DataFrame`] values into discrete, equispaced intervals.
Return the sorted separation values vector for each variable.
"""
function cut(X_df::DataFrame; ncuts=3, keepbounds=false)
    ncols = nvariables(X_df)

    # for each variable, store a sorted list of its separation values
    ans = Vector{Vector{Float64}}([])

    for col in 1:ncols
        # concatenate and sort all the values
        vals = sort!(vcat(X_df[:,col]...))

        # get bin length
        valslen = length(vals)
        binlen = Integer(floor(valslen / (ncuts+1)))

        # if keepbounds is true, also consider 1-index and end-index
        if keepbounds
            # note that binlen:binlen:valslen is different from 1:binlen:valslen,
            # where indexes are [1, binlen+1, (binlen+1)*2, ...]
            push!(ans, vcat(vals[1], vals[binlen:binlen:valslen]))
        else
            push!(ans, vals[binlen:binlen:valslen-binlen])
        end

        push!(ans, )
    end

    return ans
end
