"""
    patternbase(
        item::Item,
        htable::HeaderTable,
        miner::AbstractMiner
    )::ConditionalPatternBase

Retrieve the [`ConditionalPatternBase`](@ref) of `fptree` based on `item`.

The conditional pattern based on a [`FPTree`](@ref) is the set of all the paths from the
tree root to nodes containing `item` (not included). Each of these paths is represented
by an [`EnhancedItemset`](@ref).

The [`EnhancedItemset`](@ref)s in the returned [`ConditionalPatternBase`](@ref) are sorted
decreasingly by [`gsupport`](@ref).

See also [`AbstractMiner`](@ref), [`ConditionalPatternBase`](@ref), [`contributors`](@ref),
[`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`FPTree`](@ref), [`Item`](@ref),
[`Itemset`](@ref), [`WorldMask`](@ref).
"""
function patternbase(
    item::Item,
    htable::HeaderTable,
    miner::AbstractMiner
)
    # think a pattern base as a vector of vector of itemsets;
    # the reason why the type is explicited differently here, is that every item must be
    # associated with a specific WorldMask to guarantee correctness.
    _patternbase = ConditionalPatternBase([])

    # follow horizontal references starting from `htable`;
    # for each reference, collect all the ancestors keeping a WorldMask which, at each
    # position, is the minimum between the value in reference's mask and the new node one.
    fptree = link(htable, item)

    leftout_count = 0

    while !isnothing(fptree)
        _itemset = Itemset{itemtype(miner)}([]) # prepare the new enhanced itemset content
        ancestorfpt = parent(fptree)            # parent reference to climb up
        fptcount = count(fptree)                # count to be propagated to ancestors
        leftout_count += fptcount               # count associated with the item lefted out

        # look at ancestors, and collect them keeping count of
        # the leaf node from which we started this vertical visit.
        while !isnothing(content(ancestorfpt))
            push!(_itemset, content(ancestorfpt))
            ancestorfpt = parent(ancestorfpt)
        end

        # before following the link, push the collected enhanced itemset;
        # items inside the itemset are sorted decreasingly by global support.
        # Note that, although we are working with enhanced itemsets, the sorting only
        # requires to consider the items inside them (so, the "non-enhanced" part).
        sort!(
            _itemset,
            by=t -> miningstate(miner, :current_items_frequency)[t],
            rev=true
        )

        push!(_patternbase, EnhancedItemset((_itemset, fptcount)))

        fptree = link(fptree)
    end

    # assert pattern base does not contain dirty leftovers
    filter!(x -> !isempty(first(x)), _patternbase)

    return _patternbase, leftout_count
end

"""
    function bounce!(pbase::ConditionalPatternBase, miner::AbstractMiner)

Filter out non-frequent [`EnhancedItemset`](@ref)s from a [`ConditionalPatternBase`](@ref).

See also [`ConditionalPatternBase`](@ref), [`EnhancedItemset`](@ref). [`FPTree`](@ref).
"""
function bounce!(pbase::ConditionalPatternBase, miner::AbstractMiner)
    # accumulators needed to establish whether an enhanced itemset is promoted or no
    count_accumulator = DefaultDict{Item, Int64}(0)

    # to find local support threshold we need to search for its corresponding global
    # measure (global support), obtaining a MeaningfulnessMeasure tuple;
    # its second element is the threshold we are looking for.
    _lsupport_threshold = findmeasure(miner, lsupport)[2]

    _nworlds = frame(miner) |> SoleLogics.nworlds

    # enhanceditemset shape : (itemset, count)
    for enhanceditemset in pbase
        _itemset = itemset(enhanceditemset)
        _count = count(enhanceditemset)
        for _item in _itemset
            count_accumulator[_item] += _count
        end
    end

    for enhanceditemset in pbase
        filter!(_item ->
            count_accumulator[_item] / _nworlds >= _lsupport_threshold,
            enhanceditemset |> itemset
        )
    end

    # assert pattern base does not contain dirty leftovers
    filter!(x -> !isempty(first(x)), pbase)
end

"""
    function projection(pbase::ConditionalPatternBase, miner::AbstractMiner)

Return respectively a [`FPTree`](@ref) and a [`HeaderTable`](@ref) starting from `pbase`.
An [`AbstractMiner`](@ref) must be provided to guarantee the generated header table internal
state is OK, that is, its items are sorted decreasingly by [`gsupport`](@ref).

See also [`ConditionalPatternBase`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref), [`AbstractMiner`](@ref).
"""
function projection(
    pbase::ConditionalPatternBase,
    miner::AbstractMiner
)
    # what this function does, essentially, is to filter the given pattern base.
    fptree = FPTree()

    if length(pbase) > 0
        bounce!(pbase, miner)
        grow!(fptree, pbase; miner=miner)
    end

    return fptree, HeaderTable(fptree; miner=miner)
end



# fpgrowth implementation starts here

"""
    fpgrowth(miner::AbstractMiner, X::MineableData; verbose::Bool=true)::Nothing

(Modal) FP-Growth algorithm, [as described here](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf).

# Arguments

- `miner`: miner containing the extraction parameterization;
- `X`: data from which you want to mine association rules;
- `parallel`: enable multi-threaded execution, using `Threads.nthreads()` threads;
- `distributed`: enable multi-processing execution, with `Distributed.nworkers()` processes;
- `verbose`: print detailed informations while the algorithm runs.

# Requirements
This implementation requires a custom [`Bulldozer`](@ref) constructor capable of handling
the given [`AbstractMiner`](@ref). In particular, the following dispatch must be
implemented:

```Bulldozer(miner::MyMinerType, ith_instance::Integer)```

See also [`AbstractMiner`](@ref), [`Bulldozer`](@ref), [`FPTree`](@ref),
[`HeaderTable`](@ref), [`SoleBase.AbstractDataset`](@ref)
"""
function fpgrowth(
    miner::AbstractMiner,
    X::MineableData;
    parallel::Bool=true,
    distributed::Bool=false
)::Nothing
    @assert ModalAssociationRules.gsupport in reduce(vcat, itemsetmeasures(miner)) "" *
    "FP-Growth " *
    "requires global support (gsupport) as meaningfulness measure in order to " *
        "work. Please, add a tuple (gsupport, local support threshold, " *
        "global support threshold) to miner.item_constrained_measures field.\n" *
        "Note that local support is needed too, but it is already considered internally " *
        "by global support."

    _ninstances = ninstances(X)
    local_results = Vector{Bulldozer}(undef, _ninstances)
    if parallel
        # leverage multi-threading: apply fp-growth one time per instance,
        Threads.@threads for ith_instance in 1:_ninstances
            local_results[ith_instance] = _fpgrowth(Bulldozer(miner, ith_instance))
        end
    else
        for ith_instance in 1:_ninstances
            local_results[ith_instance] = _fpgrowth(Bulldozer(miner, ith_instance))
        end
    end

    # reduce all the local-memoization structures obtained before,
    # and proceed to compute global supports
    # local_results = reduce(bulldozer_reduce, local_results)
    local_results = bulldozer_reduce(local_results)
    fpgrowth_fragments = load_localmemo!(miner, local_results)

    # global setting
    for (itemset, gfrequency_int) in fpgrowth_fragments
        # manually compute and save miner's global support if >= min threhsold;
        _threshold = getglobalthreshold(miner, gsupport)
        gfrequency = gfrequency_int / _ninstances

        if gfrequency >= _threshold
            globalmemo!(miner, GmeasMemoKey((Symbol(gsupport), itemset)), gfrequency)

            # for those itemsets, also check other measures and save the frequent ones.
            saveflag = true
            for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
                if gmeas_algo == gsupport
                    continue
                end

                # note that when calling a generic gmeas_algo created using @globalmemo,
                # the result is automatically memoized and we do not need to also call
                # globalmemo! like in the case before, where we computed gsupport manually.
                if gmeas_algo(itemset, X, lthreshold, miner) < gthreshold
                    saveflag = !saveflag
                    break
                end
            end

            if saveflag
                push!(freqitems(miner), itemset)
            end
        end
    end
end

# `fpgrowth` main logic
function _fpgrowth(miner::Bulldozer{I}) where {I<:Item}
    kripkeframe = frame(miner)
    _nworlds = kripkeframe |> SoleLogics.nworlds
    nworld_to_itemset = [Itemset{I}() for _ in 1:_nworlds]

    # get the frequent 1-length itemsets from the first candidates set;
    frequents = [candidate
        for candidate in Itemset{I}.(items(miner))
        for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
        # in all the existing literature, the only measure needed here is be `lsupport`;
        # however, we give the possibility to control more granularly what does it mean
        # for an itemset to be *locally frequent*.
        if localof(gmeas_algo)(candidate, data(miner), miner) >= lthreshold
    ] |> unique

    for (nworld, w) in enumerate(kripkeframe |> SoleLogics.allworlds)
        _itemset_in_world = [
            itemset
            for itemset in frequents
            if miningstate(miner, :instance_item_toworlds
                )[(instancenumber(miner), itemset)][nworld] > 0
        ]

        nworld_to_itemset[nworld] = length(_itemset_in_world) > 0 ?
            union(_itemset_in_world...) :
            Itemset{I}()

        # count 1-length frequent itemsets frequency;
        # a.k.a prepare miner internal miningstate state to handle an FPGrowth call.
        for item in nworld_to_itemset[nworld]
            miningstate(miner,
                :current_items_frequency)[item] += 1
        end
    end

    # create an initial fptree and populate it
    fptree = FPTree()
    grow!(fptree, nworld_to_itemset; miner=miner)

    # create and fill an header table, necessary to traverse FPTrees horizontally
    htable = HeaderTable(fptree; miner=miner)

    # call main logic
    _fpgrowth_kernel(fptree, htable, miner, FPTree())

    # return the given miner, whose internal state has been updated
    return miner
end

# `fpgrowth` recursive logic; scroll down to see initialization section.
function _fpgrowth_kernel(
    fptree::FPTree,
    htable::HeaderTable,
    miner::Bulldozer{I},
    leftout_fptree::FPTree
) where {I<:Item}
    # if `fptree` contains only one path (hence, it can be considered a linked list),
    # then combine all the Itemsets collected from previous step with the remained ones.
    if islist(fptree)
        # all the survived items, from which compose new frequent itemsets
        survivor_itemset = itemset_from_fplist(fptree)
        leftout_itemset = itemset_from_fplist(leftout_fptree)

        leftout_count_dict = Dict{Item, Float64}()
        if fptree |> children |> length > 0
            for item in survivor_itemset
                leftout_count_dict[item] =
                    retrievebycontent(fptree, item) |> count
            end
        end

        _nworlds = frame(miner) |> SoleLogics.nworlds

        _fpgrowth_count_phase(
            survivor_itemset,
            leftout_itemset,
            #=
                `lsupport_value_calculator` lambda function explanation;
                consider the following FPTree:

                nothing                  count: 0
                -min[V3] > -3.6                  count: 1326
                --[L]min[V3] > -3.6              count: 1326
                ---[L]min[V1] > -0.5             count: 1311
                ----*min[V1] > -0.5              count: 990

                if combo contains [L]min[V1] but does not contain min[V1],
                then we should consider 1311.
            =#
            (combo) -> begin
                _leftout_count = typemax(Int64)
                for item in keys(leftout_count_dict)
                    if item in combo && leftout_count_dict[item] < _leftout_count
                        _leftout_count = min(_leftout_count, leftout_count_dict[item])
                    end
                end
                return _leftout_count / _nworlds
            end,
            (combo) -> begin
                #  we don't want to consider the single item combination case
                return (length(combo) > 1 ? 1 : 0)
            end,
            miner
        )

        _fpgrowth_count_phase(
            leftout_itemset,
            Itemset{I}(),
            (combo) -> begin
                # here, computation is simpler than the previous
                # `lsupport_value_calculator` lambda function implementation.
                return count(retrieveleaf(leftout_fptree)) / _nworlds
            end,
            (combo) -> begin
                # we don't want to consider the single item combination case
                return (length(combo) > 1 ? 1 : 0)
            end,
            miner
        )
    else
        for item in reverse(htable)
            # a (conditional) pattern base is a vector of "enhanced" itemsets
            _patternbase, _leftout_count = patternbase(item, htable, miner)

            # a new FPTree is projected, via the conditional pattern base retrieved
            # starting from `fptree` nodes whose content is exactly `item`;
            # a projection is a subset of the original dataset, viewed as a FPTree.
            conditional_fptree, conditional_htable =
                projection(_patternbase, miner)

            # update the leftout fptree with a new children
            _leftout_fptree = deepcopy(leftout_fptree)
            children!(retrieveleaf(_leftout_fptree), FPTree(item, _leftout_count))

            # if the new fptree is not empty, call this recursively,
            # considering `item` as a leftout item.
            _fpgrowth_kernel(
                conditional_fptree,
                conditional_htable,
                miner,
                _leftout_fptree
            )
        end
    end
end

# utility function; see `_fpgrowth_kernel`
function _fpgrowth_count_phase(
    survivor_itemset::Itemset,
    leftout_itemset::Itemset,
    lsupport_value_calculator::Function,
    count_increment_strategy::Function,
    miner::Bulldozer
)
    for combo in combine_items(survivor_itemset, leftout_itemset)
        # each combo must be reshaped, following a certain order specified
        # universally by the miner (lexicographi ordering).
        sort!(combo)

        # instance for which we want to update local support
        memokey = (:lsupport, combo, instancenumber(miner))

        # new local support value
        lsupport_value = lsupport_value_calculator(combo)

        # first time found for this instance
        first_time_found = !haskey(localmemo(miner), memokey)

        # local support needs to be updated
        if first_time_found || lsupport_value > localmemo(miner, memokey)
            localmemo!(miner, (:lsupport, combo, instancenumber(miner)), lsupport_value)
        end

        # if local support was set from fresh (and not updated), then also update
        # the information needed to reconstruct global support later.
        # DEPRECATED - this is now handled by reduction function
        # if first_time_found
        #     fpgrowth_fragments[combo] += count_increment_strategy(combo)
        # end
    end
end

"""
    initminingstate(::typeof(fpgrowth), ::MineableData)::MiningState

[`MiningState`](@ref) fields levereged when executing FP-Growth algorithm.

See also [`hasminingstate`](@ref), [`MiningState`](@ref), [`miningstate`](@ref).
"""
function initminingstate(::typeof(fpgrowth), ::MineableData)::MiningState
    return MiningState([
        # given and instance I and an itemset λ, the default behaviour when computing
        # local support is to perform model checking to establish in how many worlds
        # the relation I,w ⊧ λ is satisfied;
        # a numerical value is obtained, but the exact worlds in which the truth relation
        # holds is not kept in memory. We save them in thanks to this field.
        # See also `lsupport` implementation.
        :instance_item_toworlds => Dict{Tuple{Int,Itemset},WorldMask}([]),

        # when modal fpgrowth calls propositional fpgrowth multiple times, each call
        # has to know its specific 1-length itemsets ordering (that is, one Item);
        # otherwise, the building process of fptrees is not correct anymore.
        :current_items_frequency => DefaultDict{Item,Int}(0),
    ])
end
