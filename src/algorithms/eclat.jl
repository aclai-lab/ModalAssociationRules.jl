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

        push!(freqitems(miner), candidate)
    end

    # this is of type Vector{Pair{Itemset,InstanceMask}}
    Xvertical_sorted = collect(Xvertical)
    Xvertical_sorted = sort!(Xvertical_sorted, by=kv->sum(kv[2]), rev=true)

    # see comment (1) at the end.
    gthresholds = Threshold[gthreshold for (_, _, gthreshold) in itemsetmeasures(miner)]

    function _eclat!(
        miner::M,
        # AbstractVector since a view (SubArray) will be passe
        futurestates::AbstractArray{Pair{IT,IM}},
        # e.g., I am proceeding the computation from [p,q] with InstanceMask [1,0,0,1,1]
        prevstate::Pair{IT,IM},
        # all the itemsetmeasures global thresholds that must be respected
        gthresholds::Vector{T}
    ) where {M<:AbstractMiner, IT<:Itemset, IM<:BitVector, T<:Threshold}
        # base case of the DFS
        if length(futurestates) == 0
            return
        end

        # let us say that prevstate is ([A], [1,0,...])
        # and currentstate is ([B], [1,1,...])
        for currentstate in futurestates
            # the new candidate state could be ([A,B], [1,0,...])
            newstate = Pair{IT,IM}(
                union(currentstate[1], prevstate[1]), # the new candidate itemset
                currentstate[2] .& prevstate[2] # the instance mask encoding for global measures
            )

            # the new candidate state should have enough global support, and respect all the
            # policies related to itemsets
            newstate_gsupport = (newstate[2] |> sum) / length(newstate[2])
            if all(threshold -> newstate_gsupport >= threshold, gthresholds) && \
                all(policy -> policy(newstate[1]), itemset_policies(miner))

                # at this point, we recur on ([C], [1,1,...]) pinpointing ([A,B], [1,0,...])
                push!(freqitems(miner), newstate[1])
                _eclat!(miner, @view(futurestates[2:end]), newstate, gthresholds)
            end

            # in any case, the for loop goes on and we try merging [D] with [A,B]
        end
    end

    # for each possible initial prefix, let's execute a DFS;
    # if my itemsets are A,B,C,D, then we need to explore B,C,D starting from A,
    # C,D starting from B, and D starting from C.
    # Threads.@threads
    for i in 2:length(Xvertical_sorted)
        _eclat!(
            miner,
            @view(Xvertical_sorted[i:end]),
            Xvertical_sorted[i-1],
            gthresholds
        )
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
