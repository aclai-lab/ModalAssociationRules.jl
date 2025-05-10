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
    count_accumulator = DefaultDict{Item, Integer}(0)

    # to find local support threshold we need to search for its corresponding global
    # measure (global support), obtaining a MeaningfulnessMeasure tuple;
    # its second element is the threshold we are looking for.
    _lsupport_threshold = findmeasure(miner, lsupport)[2]

    _nworlds = nworlds(miner)

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
function fpgrowth(miner::AbstractMiner, X::MineableData)::Nothing
    if !(ModalAssociationRules.gsupport in reduce(vcat, itemsetmeasures(miner)))
        throw(ArgumentError("FP-Growth " *
            "requires global support (gsupport) as meaningfulness measure in order to " *
            "work. Please, add a tuple (gsupport, local support threshold, " *
            "global support threshold) to miner.itemset_constrained_measures field.\n" *
            "Note that local support is needed too, but it is already considered " *
            "internally by global support."
        ))
    end

    _ninstances = ninstances(X)
    local_results = Vector{Bulldozer}(undef, _ninstances)

    chunks = Iterators.partition(1:_ninstances, div(_ninstances, Threads.nthreads()))
    tasks = map(chunks) do chunk
        Threads.@spawn _fpgrowth(Bulldozer(miner, chunk))
    end
    local_results = fetch.(tasks)

    # reduce all the local-memoization structures obtained before,
    # and proceed to compute global supports
    local_results = bulldozer_reduce(local_results)
    fpgrowth_fragments = load_localmemo!(miner, local_results)

    # global setting
    for (itemset, gfrequency_int) in fpgrowth_fragments
        # an itemsets is mined if the flag is still true at the end of the cycle
        saveflag = true

        # apply frequent items mining policies here
        for policy in itemset_policies(miner)
            if !policy(itemset)
                saveflag = false
                break
            end
        end

        if !saveflag
            # atleast one policy does not hold
            continue
        end

        # manually compute and save miner's global support if >= min threhsold;
        _threshold = getglobalthreshold(miner, gsupport)
        gfrequency = gfrequency_int / _ninstances

        if gfrequency >= _threshold
            globalmemo!(miner, GmeasMemoKey((Symbol(gsupport), itemset)), gfrequency)

            # for those itemsets, also check other measures and save the frequent ones.
            for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
                if gmeas_algo == gsupport
                    # this is already computed by `gfrequency`
                    continue
                end

                # note that when calling a generic gmeas_algo created using @globalmemo,
                # the result is automatically memoized and we do not need to also call
                # globalmemo! like in the case before, where we computed gsupport manually.
                if gmeas_algo(itemset, X, lthreshold, miner) < gthreshold
                    saveflag = false
                    break
                end
            end

            if saveflag
                # all the meaningfulness measures holds
                push!(freqitems(miner), itemset)
            end
        end
    end
end

# `fpgrowth` main logic
function _fpgrowth(miner::Bulldozer{D,I}) where {D<:MineableData,I<:Item}
    kripkeframe = frame(miner)
    _nworlds = nworlds(miner)
    nworld_to_itemset = [Itemset{I}() for _ in 1:_nworlds]

    for ith_instance in instancesrange(miner)
        # :current_instance miningstate represent the real instance in the original dataset
        # that is, the non-sliced dataset.
        miningstate!(miner, :current_instance, ith_instance)

        # get the frequent 1-length itemsets from the first candidates set;
        # also leverage parallelization
        __itemsetmeasures = itemsetmeasures(miner)
        __items = items(miner)
        frequents_channel = Channel{Itemset{I}}(length(__items))

        Threads.@threads for candidate in Itemset{I}.(__items)
            for (gmeas_algo, lthreshold, gthreshold) in __itemsetmeasures
                if localof(gmeas_algo)(
                    candidate, data(miner, ith_instance), miner) >= lthreshold

                    put!(frequents_channel, candidate)
                end
            end
        end
        close(frequents_channel)
        frequents = unique(collect(frequents_channel))

        # alternative way to get the frequent 1-length itemsets;
        # this is serial, thus does not leverage Channel nor Threads.@threads
        # frequents = [candidate
        #     for candidate in Itemset{I}.(items(miner))
        #     for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
        #     # in all the existing literature, the only measure needed here is `lsupport`;
        #     # however, we give the possibility to control more granularly what does it mean
        #     # for an itemset to be *locally frequent*.
        #     if localof(gmeas_algo)(
        #         candidate,
        #         data(miner, ith_instance),
        #         miner
        #     ) >= lthreshold
        # ] |> unique

        for (nworld, _) in enumerate(SoleLogics.allworlds(miner; ith_instance=ith_instance))
            _itemset_in_world = [
                itemset
                for itemset in frequents
                if miningstate(
                    miner,
                    :instance_item_toworlds
                )[(instanceprojection(miner, ith_instance), itemset)][nworld] > 0
            ]

            nworld_to_itemset[nworld] = length(_itemset_in_world) > 0 ?
                union(_itemset_in_world...) :
                Itemset{I}()

            # count 1-length frequent itemsets frequency;
            # a.k.a prepare miner internal miningstate state to handle an FPGrowth call.
            for item in nworld_to_itemset[nworld]
                miningstate(miner, :current_items_frequency)[item] += 1
            end
        end

        # create an initial fptree and populate it
        fptree = FPTree()
        grow!(fptree, nworld_to_itemset; miner=miner)

        # create and fill an header table, necessary to traverse FPTrees horizontally
        htable = HeaderTable(fptree; miner=miner)

        # call main logic
        _fpgrowth_kernel(fptree, htable, miner, FPTree())
    end

    # return the given miner, whose internal state has been updated
    return miner
end

# `fpgrowth` recursive logic; scroll down to see initialization section.
function _fpgrowth_kernel(
    fptree::FPTree,
    htable::HeaderTable,
    miner::Bulldozer{D,I},
    leftout_fptree::FPTree
) where {D<:MineableData,I<:Item}
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

        _nworlds = nworlds(miner)

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
    miner::Bulldozer
)
    # we consider each combination of items (where the itemset `survivor_itemset` is fixed)
    # which also do honor the `itemset_policies`
    for combo in Iterators.filter(
            _combo -> all(__policy -> __policy(_combo), itemset_policies(miner)),
            combine_items(survivor_itemset, leftout_itemset)
        )
        # each combo must be reshaped, following a certain order specified
        # universally by the miner (lexicographic ordering).
        sort!(combo)

        # instance for which we want to update local support
        memokey = (:lsupport, combo, miningstate(miner, :current_instance))

        # new local support value
        lsupport_value = lsupport_value_calculator(combo)

        # first time found for this instance
        first_time_found = !haskey(localmemo(miner), memokey)

        # local support needs to be updated
        if first_time_found || lsupport_value > localmemo(miner, memokey, isprojected=true)
            localmemo!(miner,
                (:lsupport, combo, miningstate(miner, :current_instance)),
                lsupport_value,
                isprojected=true
            )
        end
    end
end

function anchored_fpgrowth(miner::AbstractMiner, X::MineableData; kwargs...)::Nothing
    try
        isanchored_miner(miner)
    catch
        rethrow()
    end

    # TODO - separate propositional motifs of different length here

    # fpgrowth is going to express the anchored semantics, thus, is safe to call it
    fpgrowth(miner, X; kwargs...)
end


"""
    initminingstate(::typeof(fpgrowth), ::MineableData)::MiningState

[`MiningState`](@ref) fields levereged when executing FP-Growth algorithm.

See also [`hasminingstate`](@ref), [`MiningState`](@ref), [`miningstate`](@ref).
"""
function initminingstate(
    ::Union{typeof(fpgrowth), typeof(anchored_fpgrowth)},
    ::MineableData
)::MiningState
    return MiningState([
        # given an instance I and an itemset λ, the default behaviour when computing
        # local support is to perform model checking in order to establish in how
        # many worlds the relation I,w ⊧ λ is satisfied;
        # a numerical value is obtained, but the exact worlds in which the truth relation
        # holds is not kept in memory. We save them in thanks to this field.
        # See also `lsupport` implementation.
        :instance_item_toworlds => Dict{Tuple{Int,Itemset},WorldMask}([]),

        # when modal fpgrowth calls propositional fpgrowth multiple times, each call
        # has to know its specific 1-length itemsets ordering (that is, one Item);
        # otherwise, the building process of fptrees is not correct anymore.
        :current_items_frequency => DefaultDict{Item,Int}(0),

        # keep track of which instance (of a generic MineableData) is currently being mined
        :current_instance => 1
    ])
end
