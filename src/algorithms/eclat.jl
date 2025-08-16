"""
    eclat(miner::Miner, X::MineableData; verbose::Bool=true)::Nothing

## Examples

julia> using ModalAssociationRules
julia> X_df, y = load_NATOPS();
julia> X_df_1_have_command = X_df[1:30, :]
julia> X1 = scalarlogiset(X_df_1_have_command)

julia> manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
julia> manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
julia> manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))
julia> manual_lp = box(IA_L)(manual_p)
julia> manual_lq = diamond(IA_L)(manual_q)
julia> manual_lr = box(IA_L)(manual_r)
julia>
julia> manual_items = Vector{Item}([manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

julia> _1_items = Vector{Item}([manual_p, manual_q, manual_lp, manual_lq])
julia> _1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
julia> _1_rulemeasures = [(gconfidence, 0.2, 0.2)]

julia> eclat_miner = Miner(X1, eclat, _1_items, _1_itemsetmeasures, _1_rulemeasures)
julia> pq = Itemset([manual_p |> Item, manual_q |> Item])
julia> x = gsupport(pq, X1, 0.1, eclat_miner)

julia> mine!(eclat_miner)

See also [`anchored_eclat`](@ref), [`Miner`](@ref).
"""
function eclat(miner::M)::M where {M<:AbstractMiner}
    _itemtype = itemtype(miner)
    X = data(miner)
    Xvertical = Dict{Itemset{_itemtype}, InstanceMask}()

    # we want to obtain a vertical format from data:
    # given an item c, we collect the instance IDs on which c holds;
    # if the mining is constrained, we ensure the constraints are applied on 1-itemsets.
    candidates = Itemset{_itemtype}.(items(miner))
    filter!(candidates, miner)

    Threads.@threads for candidate in candidates
        # if the candidate global support is enough ...
        [
            # see comment (1) at the end.
            gmeas_algo(candidate, X, lthreshold, miner) >= gthreshold
            for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
        ]
        # ... we keep track of the instances on which it holds
        Xvertical[candidate] = miningstate(miner, :instancemask, candidate)
    end

    # this is of type Vector{Pair{Itemset,InstanceMask}}
    Xvertical_sorted = collect(Xvertical)
    Xvertical_sorted = sort!(Xvertical_sorted, by=kv->sum(kv[2]), rev=true)

    # see comment (1) at the end.
    gthresholds = Threshold[gthreshold for (_, _, gthreshold) in itemsetmeasures(miner)]

    function _eclat!(
        miner::M,
        # AbstractVector since a view (SubArray) will be passe
        rollingstates::AbstractVector{Pair{Itemset,InstanceMask}},
        # e.g., I am proceeding the computation from [p,q] with InstanceMask [1,0,0,1,1]
        prevstate::Pair{Itemset,InstanceMask},
        # all the itemsetmeasures global thresholds that must be respected
        gthresholds::Vector{Threshold}
    ) where {M<:AbstractMiner}
        # every state is the pair in which [1] is the itemset and [2] is the instance mask
        currentstate, futurestates = rollingstates |> first, @view(rollingstates[2:end])

        newstate = Pair{Itemset,InstanceMask}(
            union(currentstate[1], prevstate[1]), # the new candidate itemset
            currentstate[2] .& prevstate[2] # the instance mask encoding for global measures
        )

        newmask_sum = newstate[2] |> sum
        if all(threshold -> newmask_sum >= threhsold, gthresholds)
            push!(freqitems(miner), newstate[1])
            _eclat!(miner, futurestates, newmask, gthresholds)
        end
    end

    # for each possible initial prefix, let's execute a DFS;
    # if my itemsets are A,B,C,D, then we need to explore B,C,D starting from A,
    # C,D starting from B, and D starting from C.
    Threads.@threads for i in 2:(length(Xvertical_sorted)-1)
        # the first argument is the entire list of pairs (itemset, instances);
        # the second argument is the starting instance mask
        _eclat!(
            miner, @view(Xvertical_sorted[i:end]), Xvertical_sorted[i-1], gthresholds)
    end

    return miner

    # notes:
    # (1)   actually we could just consider gsupport...
    #       the point is that, in the future, more itemsetmeasures may be considered.
end


"""
    initminingstate(::typeof(eclat), ::MineableData)::MiningState

[`MiningState`](@ref) fields levereged when executing the Eclat algorithm.

See also [`hasminingstate`](@ref), [`MiningState`](@ref), [`miningstate`](@ref).
"""
function initminingstate(
    ::typeof(eclat),
    ::MineableData
)::MiningState
    return MiningState([
        :instancemask => Dict{Itemset,InstanceMask}(),
    ])
end
