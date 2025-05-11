
"""
    anchored_semantics(miner::M, miningalgo; kwargs...)::M where {M<:AbstractMiner}

Logic to be executed before `miningalgo` to make the latter coherent with Anchored.
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

    # lambda to return the refsize of a VariableIstance wrapped within the item
    _item_refsize = item -> formula(item) |> SoleLogics.value |> SoleData.metacond |>
        SoleData.feature |> refsize

    # within the anchors, further separate by dimension of the wrapped references
    # (e.g., a scalar, whose size is "()", or a sequence, whose size is "(1,)" and so on);
    anchor_groups = SoleBase._groupby(item -> _item_refsize(item), anchor_items)

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

    resulting_miner = miner_reduce!(fetch.(tasks); includelmemo=true)

    # perform one latest reduce operation to overwrite the argument miner;
    # this is a bit of overhead.
    return miner_reduce!([miner, resulting_miner])
end
