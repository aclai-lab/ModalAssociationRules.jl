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
    Xvertical = Dict{Itemset{_itemtype}, Vector{<:WorldMask}}()

    # we want to obtain a vertical format from data:
    # given an item c, we collect the instance IDs on which c holds;
    # if the mining is constrained, we ensure the constraints are applied on 1-itemsets.
    candidates = Itemset{_itemtype}.(items(miner))
    filter!(candidates, miner)

    Threads.@threads for candidate in candidates
        # we keep track of the instances for which a candidate has enough global support;
        # m is a MeaningfulnessMeasure;
        # see comment (1) at the end
        if all(m -> m[1](candidate, X, m[2], miner) >= m[3], itemsetmeasures(miner))
            push!(freqitems(miner), candidate)

            Xvertical[candidate] = (
                miningstate(miner, :worldmask)[(ith_instance, candidate)]
                for ith_instance in 1:ninstances(X)
            ) |> collect
        end
    end

    # this is of type Vector{Pair{Itemset,BitMatrix}}
    Xvertical_sorted = collect(Xvertical)
    Xvertical_sorted = sort!(
        Xvertical_sorted,
        by=kv->globalmemo(miner, (:gsupport, kv[1])),
        rev=true
    )

    function _eclat!(
        miner::M,
        # AbstractVector since a view (SubArray) will be passe
        futurestates::AbstractArray{Pair{IT,IM}},
        # e.g., I am proceeding the computation from [p,q] with BitMatrix [1,0,0,1,1]
        prevstate::Pair{IT,IM},
        # all the itemsetmeasures global thresholds that must be respected
        lthreshold::T,
        gthreshold::T
    ) where {M<:AbstractMiner, IT<:Itemset, IM<:Vector{<:WorldMask}, T<:Threshold}
        # base case of the DFS
        if length(futurestates) == 0
            return
        end

        for currentstate in futurestates
            _newstate_itemset = union(currentstate[1], prevstate[1]) |> sort!
            _newstate_worldmasks = map(
                s -> s[1] .& s[2], zip(currentstate[2], prevstate[2])
            )

            newstate = Pair{IT,IM}(
                _newstate_itemset,
                _newstate_worldmasks
            )

            # the new candidate state should have enough global support, and respect all the
            # policies related to itemsets
            newstate_gsupport = mean(
                mask -> mean(mask) >= lthreshold,
                newstate[2]
            )

            # WARNING: the user could want to save space and do not save all the metadata
            # related to the local support of each itemset;
            # moreover, mean computation is redundant here.
            for ith_instance in 1:ninstances(X)
                localmemo!(
                    miner,
                    (:lsupport, newstate[1], ith_instance),
                    mean(newstate[2][ith_instance])
                )
            end

            if newstate_gsupport > gthreshold &&
                all(policy -> policy(newstate[1]), itemset_policies(miner))

                push!(freqitems(miner), newstate[1])
                globalmemo!(
                    miner, GmeasMemoKey((:gsupport, newstate[1])), newstate_gsupport)
                _eclat!(miner, @view(futurestates[2:end]), newstate, lthreshold, gthreshold)
            end

        end
    end

    # for each possible initial prefix, let's execute a DFS;
    # if my itemsets are A,B,C,D, then we need to explore B,C,D starting from A,
    # C,D starting from B, and D starting from C.
    # Threads.@threads # TODO
    ((_, lthreshold, gthreshold),) = itemsetmeasures(miner)
    for i in 2:length(Xvertical_sorted)
        _eclat!(
            miner,
            @view(Xvertical_sorted[i:end]),
            Xvertical_sorted[i-1],
            lthreshold,
            gthreshold
        )
    end

    return miner
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
        :worldmask => Dict{Tuple{Int,Itemset},WorldMask}()
    ])
end
