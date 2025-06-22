"""
    isanchored_miner(miner::AbstractMiner)

Check if `miner` is provided of both `isdimensionally_coherent_itemset` and
`isanchored_itemset` policy and, in particular, if `ignoreuntillength` parameter is set to 1
or above in the latter.

See also [`AbstractMiner`](@ref), [`isanchored_itemset`](@ref),
[`isdimensionally_coherent_itemset`](@ref).
"""
function isanchored_miner(miner::AbstractMiner)
    _itemset_policies = itemset_policies(miner)

    _isanchored_index = findfirst(
        policy -> policy |> Symbol == :_isanchored_itemset, _itemset_policies)

    _isdimensionally_coherent = findfirst(
        policy -> policy |> Symbol == :_isdimensionally_coherent_itemset, _itemset_policies)

    if isnothing(_isanchored_index) || isnothing(_isdimensionally_coherent) || getfield(
        _itemset_policies[_isanchored_index], :ignoreuntillength) == 0

        throw(
            AssertionError("The miner must possess both isdimensionally_coherent_itemset " *
            "and anchored_itemset policy, the latter with ignoreuntillength parameter " *
            "set to 1 or higher."
        ))
    end
end

"""
    anchored_semantics(miner::M, miningalgo; kwargs...)::M where {M<:AbstractMiner}

Logic to be executed before `miningalgo` to make the latter coherent with Anchored.

Keyword arguments are forwarded to `miningalgo`.
"""
function anchored_semantics(
    miner::M,
    miningalgo::Function;
    kwargs...
)::M where {M<:AbstractMiner}
    try
        isanchored_miner(miner)
    catch
        rethrow()
    end

    # separate the propositional items (the anchors) from modal literals
    _items = items(miner)
    anchor_items = filter(item -> formula(item) isa Atom, _items)
    modal_literals = setdiff(_items, anchor_items)

    # lambda to return the refsize of a VariableDistance wrapped within the item
    _item_refsize = item -> formula(item) |> SoleLogics.value |> SoleData.metacond |>
        SoleData.feature |> refsize

    try
        # within the anchors, further separate by dimension of the wrapped references
        # (e.g., a scalar, whose size is "()", or a sequence, whose size is "(1,)" and so on);
        anchor_groups = SoleBase._groupby(item -> _item_refsize(item), anchor_items)
    catch e
        if isa(e, MethodError)
            throw(ErrorException(
                "The items provided within the miner are not suitable for itemsets " *
                "extraction under the anchored semantics; please provide a list of " *
                "SoleData.VariableDistance."
            ))
        else
            rethrow(e)
        end
    end


    # build one miner for each group of anchors, each of which contains the group itself
    # enriched with all the modal_literals set.
    miners = [
        partial_deepcopy(
            miner;
            new_items=vcat(group, modal_literals),

            # TODO - change interval.y - interval.x + 1 into "size(interval)" when
            # size(::GeometricalWorld) is implemented in SoleLogics; see the following issue
            # https://github.com/aclai-lab/SoleLogics.jl/issues/68
            new_worldfilter=SoleLogics.FunctionalWorldFilter(
                interval -> (interval.y - interval.x,) == groupsize, Interval{Int})
        )

        # groupsize here means "the size of every VariableDistance element in a group"
        for (groupsize, group) in anchor_groups
    ]

    tasks = map(miners) do _miner
        Threads.@spawn miningalgo(_miner; kwargs...)
    end

    # NOTE - miner_reduce! is currently called with default kwargs, as they are virtually
    # always the best choice

    resulting_miner = miner_reduce!(fetch.(tasks))

    # perform one latest reduce operation to overwrite the argument miner;
    # this is a bit of overhead.
    return miner_reduce!([miner, resulting_miner])
end


"""
    anchored_grow_prune(
        candidates::AbstractVector{Itemset},
        frequents::AbstractVector{Itemset},
        k::Integer
    )

Return a generator, which yields only the `candidates` for which every (k-1)-length subset
is in `frequents`.

Differently from [`grow_prune`](@ref), this method supports anchored semantics.
This means that, for example, the following [`Itemset`](@ref)s are not pruned
`[[L]min[V1] > -0.5, min[V3] > -3.6]`, `[min[V3] > -3.6, [L]min[V3] > -3.6]` and can be
merged in `[[L]min[V1] > -0.5, min[V3] > -3.6, [L]min[V3] > -3.6]`, since it would be
impossible to generate `[[L]min[V1] > -0.5, [L]min[V3] > -3.6]`.

See also [`grow_prune`](@ref), [`Itemset`](@ref).
"""
function anchored_grow_prune(
    candidates::AbstractVector{Itemset{I}},
    frequents::AbstractVector{Itemset{I}},
    k::Integer
) where {I<:Item}
    return Iterators.filter(
        itemset -> all(
                # if combo does not contain an ancor, just ignore it;
                # this utility is not the most convenient place to apply itemset policies
                # related to anchoredness (e.g., during anchored apriori).
                combo -> (Itemset{I}(combo) in frequents) || !(isanchored_itemset()(combo)),
                combinations(itemset, k-1)
            ),
        combine_items(candidates, k) |> unique
    )
end

"""
    anchored_apriori(miner::AbstractMiner, X::MineableData; kwargs...)::Nothing

Anchored version of [`apriori`](@ref) algorithm, that is exactly `apriori` but assuring
that `miner` possess atleast [`isanchored_itemset`](@ref) policy, with `ignoreuntillength`
parameter set to 1 or higher.

TODO - insert a reference to TIME2025 article.

See also [`AbstractMiner`](@ref), [`apriori`](@ref), [`isanchored_itemset`](@ref),
[`MineableData`](@ref).
"""
function anchored_apriori(miner::M; kwargs...)::M where {M<:AbstractMiner}
    return anchored_semantics(miner, apriori; grow_prune=anchored_grow_prune, kwargs...)
end

"""
    function anchored_fpgrowth(miner::M; kwargs...)::M where {M<:AbstractMiner}

Implementation of [`fpgrowth`](@ref) with *anchored semantics*.
Essentially, [`Item`](@ref)s are `SoleData.VariableDistance`s wrapping motifs.

More information about motifs: <insert-link>
More information about the implementation: <insert-link>

See also [`AbstractMiner`](@ref), ['fpgrowth`](@ref), [`Item`](@ref).
"""
function anchored_fpgrowth(miner::M; kwargs...)::M where {M<:AbstractMiner}
    return anchored_semantics(miner, fpgrowth; kwargs...)
end


# forward from initminingstate(::typeof(fpgrowth))
function initminingstate(
    ::typeof(anchored_fpgrowth),
    ::MineableData
)::MiningState
    return MiningState([
        :instance_item_toworlds => Dict{Tuple{Int,Itemset},WorldMask}([]),
        :current_items_frequency => DefaultDict{Item,Int}(0),
        :current_instance => 1
    ])
end
