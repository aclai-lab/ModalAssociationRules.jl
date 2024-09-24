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
        _itemset = Itemset([])                  # prepare the new enhanced itemset content
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
            items(_itemset),
            by=t -> powerups(miner, :current_items_frequency)[Itemset(t)],
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

    # DEPRECATED
    # _support_meas = Iterators.filter(m -> m[1] == gsupport, itemsetmeasures(miner)) |> first
    # _lsupport_threshold = _support_meas[2]


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
            enhanceditemset |> itemset |> items
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
        grow!(fptree, pbase, miner)
    end

    return fptree, HeaderTable(fptree; miner=miner)
end

"""
    TODO: comment this
"""
function _fragments_reducer(
    a::DefaultDict{Itemset,Int},
    b::DefaultDict{Itemset,Int}
)::DefaultDict{Itemset,Int}
    for k in keys(b)
        if haskey(a,k)
            a[k] += b[k]
        else
            a[k] = b[k]
        end
    end

    return a
end

############################################################################################
#### Main FP-Growth logic ##################################################################
############################################################################################

"""
    fpgrowth(miner::Miner, X::MineableData; verbose::Bool=true)::Nothing

FP-Growth algorithm,
[as described here](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf)
but generalized to also work with modal logic.

# Arguments

- `miner`: miner containing the extraction parameterization;
- `X`: data from which you want to mine association rules;
- `parallel`: enable multi-threaded execution, using `Threads.nthreads()` threads;
- `distributed`: enable multi-processing execution, with `Distributed.nworkers()` processes;
- `verbose`: print detailed informations while the algorithm runs.

See also [`Miner`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref),
[`SoleBase.AbstractDataset`](@ref)
"""
function fpgrowth(
    miner::Miner,
    X::MineableData;
    parallel::Bool=true,
    distributed::Bool=false,
    verbose::Bool=false
)::Nothing
    @assert ModalAssociationRules.gsupport in reduce(vcat, itemsetmeasures(miner)) "" *
    "FP-Growth " *
    "requires global support (gsupport) as meaningfulness measure in order to " *
        "work. Please, add a tuple (gsupport, local support threshold, " *
        "global support threshold) to miner.item_constrained_measures field.\n" *
        "Note that local support is needed too, but it is already considered internally " *
        "by global support."

    _nthreads = Threads.nthreads()
    _nworkers = Distributed.nworkers()

    if verbose && parallel
        printstyled("Multithreading enabled: # threads = $(_nthreads).\n", color=:green)
        if _nthreads == 1
            printstyled(
                "You probably forget to set a higher number of threads!\n", color=:red)
            printstyled("Remember to use --threads/-t flag, " *
                "or change JULIA_NUM_THREADS environment variable\n", color=:red)
        end
    end

    if verbose && distributed
        printstyled("Workload distributed across #$(Distributed.nprocs()) processes.\n",
            color=:green)
        if _nworkers == 1
            printstyled(
                "You probably forget to set a higher number of processes!\n", color=:red)
            printstyled("Remember to set the -p flag.\n",  color=:red)
        end
    end

    # establish an arbitrary general lexicographic ordering,
    # then save it inside the miner as a powerup.
    incremental = 0
    for candidate in items(miner)
        # :lexicographic_ordering is only changed one time by the serial code;
        # algorithm should be correct also without this.
        powerups(miner, :lexicographic_ordering)[candidate] = incremental
        incremental += 1
    end

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
    fpgrowth_fragments = load_bulldozer!(miner, local_results)

    # global setting
    for (itemset, gfrequency_int) in fpgrowth_fragments
        _threshold = getglobalthreshold(miner, gsupport)
        gfrequency = gfrequency_int / _ninstances
        if gfrequency >= _threshold
            globalmemo!(miner, GmeasMemoKey((Symbol(gsupport), itemset)), gfrequency)
            push!(freqitems(miner), itemset)
        end

        # TODO - check other custom meaningfulness measures
    end
end

# `fpgrowth` main logic
function _fpgrowth(miner::Bulldozer)
    # this will be used by the miner to understand how to order the items of each itemset
    miner.powerups[:current_items_frequency] = DefaultDict{Itemset,Int}(0)
    miner.powerups[:instance_item_toworlds] = Dict{Tuple{Int,Itemset},WorldMask}([])

    kripkeframe = frame(miner)
    _nworlds = kripkeframe |> SoleLogics.nworlds
    nworld_to_itemset = [Itemset() for _ in 1:_nworlds]

    # get the frequent 1-length itemsets from the first candidates set;
    frequents = [candidate
        # TODO we take for granted that the only measure related to items is always support
        for (_, lthreshold, _) in itemsetmeasures(miner)
        for candidate in Itemset.(items(miner))
        if lsupport(candidate, instance(miner), miner) >= lthreshold
    ] |> unique

    for (nworld, w) in enumerate(kripkeframe |> SoleLogics.allworlds)
        nworld_to_itemset[nworld] = [
            itemset
            for itemset in frequents
            if powerups(miner, :instance_item_toworlds
                )[(instancenumber(miner), itemset)][nworld] > 0
        ] |> union

        # count 1-length frequent itemsets frequency;
        # a.k.a prepare miner internal powerups state to handle an FPGrowth call.
        for item in nworld_to_itemset[nworld]
            powerups(miner,
                :current_items_frequency)[Itemset(item)] += 1
        end
    end

    # create an initial fptree and populate it
    fptree = FPTree()
    ModalAssociationRules.grow!(fptree, nworld_to_itemset, miner)

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
    miner::Bulldozer,
    leftout_fptree::FPTree
)
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
            Itemset(),
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
    for combo in combine_items(items(survivor_itemset), items(leftout_itemset))
        # each combo must be reshaped, following a certain order specified
        # universally by the miner.

        sort!(items(combo), by=t -> powerups(miner, :lexicographic_ordering, t))

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
    initpowerups(::typeof(fpgrowth), ::MineableData)::Powerup

Powerups suite for FP-Growth algorithm.
When initializing a [`Miner`](@ref) with [`fpgrowth`](@ref) algorithm, this defines
how miner's `powerup` field is filled to optimize the mining.
See also [`haspowerup`](@ref), [`powerup`](@ref).
"""
function initpowerups(::typeof(fpgrowth), ::MineableData)::Powerup
    return Powerup([
        # given and instance I and an itemset λ, the default behaviour when computing
        # local support is to perform model checking to establish in how many worlds
        # the relation I,w ⊧ λ is satisfied.
        # A numerical value is obtained, but the exact worlds in which the truth relation
        # holds is not kept in memory by default.
        # Here, however, we want to keep track of the relation.
        # See `lsupport` implementation.
        :instance_item_toworlds => Dict{Tuple{Int,Itemset},WorldMask}([]),

        # when modal fpgrowth calls propositional fpgrowth multiple times, each call
        # has to know its specific 1-length itemsets ordering;
        # otherwise, the building process of fptrees is not correct anymore.
        # To avoid race condition, the first integer in the dictionary's key
        # contains the number of the current operating thread id.
        :current_items_frequency => DefaultDict{Tuple{Int,Itemset},Int}(0),

        # necessary to reshape all the extracted itemsets to a common ordering
        :lexicographic_ordering => Dict{Item,Int}([])
    ])
end
