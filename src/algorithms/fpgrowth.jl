############################################################################################
#### Data structures #######################################################################
############################################################################################

"""
Fundamental data structure used in FP-Growth algorithm.
Essentialy, an [`FPTree`](@ref) is a prefix tree where a root-leaf path represent an
[`Itemset`](@ref).

Consider the [`Itemset`](@ref)s sorted by [`gsupport`](@ref) of their items.
An [`FPTree`](@ref) is such that the common [`Item`](@ref)s-prefix shared by different
[`Itemset`](@ref)s is not stored multiple times.

This implementation generalizes the propositional logic case scenario to modal logic;
given two [`Itemset`](@ref)s sharing a [`Item`](@ref) prefix, the worlds in which they are
true is accumulated.
"""
mutable struct FPTree
    content::Union{Nothing,Item}        # Item contained in this node (nothing if root)

    parent::Union{Nothing,FPTree}       # parent node
    const children::Vector{FPTree}      # children nodes

    count::Int64                        # number of equal Items this node represents

    const contributors::WorldsMask      # worlds contributing to this node
    linkages::Union{Nothing,FPTree}     # link to another FPTree root

    # empty constructor
    function FPTree()
        new(nothing, nothing, FPTree[], 0, Int64[], nothing)
    end

    # choose root or new subtree constructor;
    # ninstance is needed to start defining `contributors` for each node,
    # as this is not a standard, propositional FPTree but a more general modal one.
    function FPTree(itemset::Itemset, ninstance::Int64, miner::ARuleMiner; isroot=true)
        FPTree(itemset, ninstance, miner, Val(isroot)) # singleton design pattern
    end

    # root constructor
    function FPTree(itemset::Itemset, ninstance::Int64, miner::ARuleMiner, ::Val{true})
        # make FPTree empty root
        fptree = FPTree()

        # start growing a path
        children!(fptree, FPTree(itemset, miner; isroot=false))

        return fptree
    end

    # internal tree constructor
    function FPTree(itemset::Itemset, ninstance::Int64, miner::ARuleMiner, ::Val{false})
        item = itemset[1]
        _contributors = SoleRules.contributors(:lsupport, item, ninstance, miner)

        fptree = length(itemset) == 1 ?
            new(item, nothing, FPTree[], 1, _contributors, nothing) :
            new(item, nothing,
                FPTree[FPTree(itemset[2:end], ninstance, miner; isroot=false)],
                1, _contributors, nothing)

        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end

    function FPTree(enhanceditemset::EnhancedItemset, miner::ARuleMiner)
        item, _count, _contributors = first(enhanceditemset)
        fptree = length(enhanceditemset) == 1 ?
            new(item, nothing, FPTree[], _count, _contributors, nothing) :
            new(item, nothing, FPTree[FPTree(enhanceditemset[2:end], miner)],
                _count, _contributors, nothing)

        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end
end

doc_fptree_getters = """
    content(fptree::FPTree)::Union{Nothing,Item}
    parent(fptree::FPTree)::Union{Nothing,FPTree}
    children(fptree::FPTree)::Vector{FPTree}
    count(fptree::FPTree)::Int64
    contributors(fptree::FPTree)::WorldsMask
    linkages(fptree::FPTree)::Union{Nothing,FPTree}

[`FPTree`](@ref) getters.
"""

doc_fptree_setters = """
    content!(fptree::FPTree)::Union{Nothing,Item}
    parent!(fptree::FPTree)::Union{Nothing,FPTree}
    children!(fptree::FPTree)::Vector{FPTree}
    count!(fptree::FPTree)::Int64
    addcount!(fptree::FPTree, deltacount::Int64)
    contributors!(fptree::FPTree, contribution::WorldsMask)
    addcontributors!(fptree::FPTree)::WorldsMask
    link!(fptree::FPTree)::Union{Nothing,FPTree}

[`FPTree`](@ref) setters.
"""

"""$(doc_fptree_getters)"""
content(fptree::FPTree)::Union{Nothing,Item} = fptree.content
"""$(doc_fptree_getters)"""
parent(fptree::FPTree)::Union{Nothing,FPTree} = fptree.parent
"""$(doc_fptree_getters)"""
children(fptree::FPTree)::Vector{FPTree} = fptree.children

"""$(doc_fptree_getters)"""
Base.count(fptree::FPTree)::Int64 = fptree.count
"""$(doc_fptree_getters)"""
contributors(fptree::FPTree)::WorldsMask = fptree.contributors

"""$(doc_fptree_getters)"""
linkages(fptree::FPTree)::Union{Nothing,FPTree} = fptree.linkages

"""$(doc_fptree_setters)"""
content!(fptree::FPTree, item::Union{Nothing,Item}) = fptree.content = item
"""$(doc_fptree_setters)"""
parent!(fptree::FPTree, parentfpt::Union{Nothing,FPTree}) = fptree.parent = parentfpt
"""$(doc_fptree_setters)"""
children!(fptree::FPTree, child::FPTree) = begin
    push!(children(fptree), child)
    parent!(child, fptree)
end

"""$(doc_fptree_setters)"""
count!(fptree::FPTree, newcount::Int64) = fptree.count = newcount
"""$(doc_fptree_setters)"""
addcount!(fptree::FPTree, deltacount::Int64) = fptree.count += deltacount
"""$(doc_fptree_setters)"""
contributors!(fptree::FPTree, contribution::WorldsMask) = fptree.contributors = contribution
"""$(doc_fptree_setters)"""
addcontributors!(fptree::FPTree, contribution::WorldsMask) =
    fptree.contributors .+= contribution

"""
    islist(fptree::FPTree)::Bool

Return true if every subtree in `fptree` has exactly 0 or 1 children.

See also [`FPTree`](@ref)
"""
function islist(fptree::FPTree)::Bool
    arity = fptree |> children |> length

    if arity == 1
        return islist(fptree |> children |> first)
    elseif arity > 1
        return false
    else
        # arity is 0
        return true
    end
end

"""
    function retrieveall(fptree::FPTree)::Itemset

Return all the [`Item`](@ref) contained in `fptree`.

See also [`FPTree`](@ref), [`Item`](@ref), [`Itemset`](@ref).
"""
function retrieveall(fptree::FPTree)::Itemset

    # internal function just to avoid repeating the final `unique`
    function _retrieve(fptree::FPTree)
        retrieved = Itemset([_retrieve(child) for child in children(fptree)])

        if !isempty(retrieved)
            retrieved = reduce(vcat, retrieved |> unique)
        end

        _content = content(fptree)

        if !isnothing(_content)
            push!(retrieved, _content)
        end

        return retrieved
    end

    return _retrieve(fptree)
end

"""
    function follow(fptree::FPTree)::Union{Nothing,FPTree}

Follow `fptree` linkages to (an internal node of) another [`FPTree`](@ref).

See also [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function follow(fptree::FPTree)::Union{Nothing,FPTree}
    arrival = linkages(fptree)
    return isnothing(arrival) ? fptree : follow(arrival)
end

"""
    function link!(from::FPTree, to::FPTree)

Establish a linkages between two [`FPTree`](@ref)s.
If the starting tree is already linked with something, the already existing linkages are
followed until a new "empty-linked" [`FPTree`](@ref) is found.

See also [`follow`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function link!(from::FPTree, to::FPTree)
    # find the last FPTree by iteratively following the internal link
    from = follow(from)
    from.linkages = to
end

function Base.show(io::IO, fptree::FPTree; indentation::Int64=0)
    _children = children(fptree)
    println(io, "-"^indentation * "*"^(length(_children)==0) *
        "$(fptree |> content |> syntaxstring)")

    for child in children(fptree)
        Base.show(io, child; indentation=indentation+1)
    end
end

"""
    struct HeaderTable
        items::Vector{Item}
        linkages::Dict{Item,Union{Nothing,FPTree}}
    end

Utility data structure used to fastly access [`FPTree`](@ref) internal nodes.
"""
struct HeaderTable
    items::Vector{Item} # vector of Items, sorted decreasingly by global support
    linkages::Dict{Item,Union{Nothing,FPTree}} # Item -> FPTree internal node association

    function HeaderTable()
        new(Item[], Dict{Item,Union{Nothing,FPTree}}())
    end

    function HeaderTable(items::Vector{<:Item}, fptseed::FPTree)
        # make an empty htable, whose entries are `Item` objects, in `items`
        htable = new(items, Dict{Item,Union{Nothing,FPTree}}([
            item => nothing for item in items]))

        # iteratively fill htable
        child = children(fptseed)
        while !isempty(child)
            link!(htable, fptseed)
            child = children(child)
        end

        return htable
    end

    function HeaderTable(itemsets::Vector{<:Itemset}, fptseed::FPTree)
        return HeaderTable(convert.(Item, itemsets), fptseed)
    end
end

doc_htable_getters = """
    items(htable::HeaderTable)

    linkages(htable::HeaderTable)
    linkages(htable::HeaderTable, item::Item)

[`HeaderTable`](@ref) getters.
"""

doc_htable_setters = """
    link!(htable::HeaderTable, item::Item, fptree::FPTree)

[`HeaderTable`](@ref) setters.
"""

"""$(doc_htable_getters)"""
items(htable::HeaderTable) = htable.items

"""$(doc_htable_getters)"""
linkages(htable::HeaderTable) = htable.linkages

"""$(doc_htable_getters)"""
linkages(htable::HeaderTable, item::Item) = htable.linkages[item]

"""$(doc_htable_setters)"""
function link!(htable::HeaderTable, item::Item, fptree::FPTree)
    htitems = items(htable)
    if !(item in htitems)
        push!(htitems, item)
    end

    htable.linkages[item] = fptree
end

"""
    function follow(htable::HeaderTable, item::Item)::Union{Nothing,FPTree}

Follow `htable` linkages to (an internal node of) a [`FPTree`](@ref).
"""
function follow(htable::HeaderTable, item::Item)::Union{Nothing,FPTree}
    arrival = linkages(htable, item)
    return isnothing(arrival) ? arrival : follow(arrival)
end

"""
    function link!(htable::HeaderTable, fptree::FPTree)

Establish a linkages between the entry in `htable` corresponding to the [`content`](@ref)
of `fptree`.

See also [`content`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function link!(htable::HeaderTable, fptree::FPTree)
    _content = content(fptree)
    arrival = follow(htable, _content)

    # the content of `fptree` was never seen before by this `htable`
    if linkages(htable, _content) |> isnothing
        link!(htable, _content, fptree)
    # the arrival FPTree is linked to the new `fptree`
    elseif arrival isa FPTree
        link!(arrival, fptree)
    # invalid option
    else
        error("Error trying to establish a linkages between HeaderTable and an object " *
            "of type $(typeof(arrival)).")
    end
end
"""
    function checksanity!(htable::HeaderTable, miner::ARuleMiner)::Bool

Check if `htable` internal state is correct, that is, its `items` are sorted decreasingly
by global support.

See also [`ARuleMiner`](@ref), [`gsupport`](@ref), [`HeaderTable`](@ref), [`items`](@ref).
"""
function checksanity!(htable::HeaderTable, miner::ARuleMiner)::Bool
    _issorted = issorted(items(htable),
        by=t -> globalmemo(miner, (:gsupport, Itemset(t))), rev=true)

    if !_issorted
        sort!(items(htable), by=t -> globalmemo(miner, (:gsupport, Itemset(t))), rev=true)
    end

    return _issorted
end

doc_fptree_push = """
    function Base.push!(
        fptree::FPTree,
        itemset::Itemset,
        ninstance::Int64,
        miner::ARuleMiner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    function Base.push!(
        fptree::FPTree,
        itemset::EnhancedItemset,
        ninstance::Int64,
        miner::ARuleMiner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    function Base.push!(
        fptree::FPTree,
        itemsets::Vector{T},
        miner::ARuleMiner;
        htable::HeaderTable
    ) where {T <: Union{Itemset, EnhancedItemset}}

Push one or more [`Itemset`](@ref)s/[`EnhancedItemset`](@ref) to an [`FPTree`](@ref).
If an [`HeaderTable`](@ref) is provided, it is leveraged to develop internal links.

!!! warning
    To optimally leverage the compression capabilities of [`FPTree`](@ref)s, the
    [`Itemset`](@ref)s provided should be sorted decreasingly by [`gsupport`](@ref).
    By default, to improve performances, this check is not performed inside this method.

See also [`EnhancedItemset`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref), [`Itemset`](@ref).
"""

"""$(doc_fptree_push)"""
function Base.push!(
    fptree::FPTree,
    itemset::Itemset,
    ninstance::Int64,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing,
)
    # if an header table is provided, and its entry associated with the content of `fptree`
    # is still empty, then perform a linking.
    _fptree_content = content(fptree)
    if !isnothing(htable) && _fptree_content !== nothing
        link!(htable, _fptree_content, fptree)
    end

    # end of push case
    if length(itemset) == 0
        return
    end

    # retrieve the item to grow the tree;
    # to grow a find pattern tree in the modal case scenario, each item has to be associated
    # with its global counter (always 1!) and its contributors array (see [`WorldsMask`]).
    item = first(itemset)
    _contributors = contributors(:lsupport, item, ninstance, miner)

    # check if a subtree whose content is the first item in `itemset` already exists
    _children = children(fptree)
    _children_idx = findfirst(child -> content(child) == item, _children)
    if !isnothing(_children_idx)
        subfptree = _children[_children_idx]
    # if it does not, then create a new children FPTree, and set this as its parent
    else
        subfptree = FPTree(itemset, ninstance, miner; isroot=false)
        children!(fptree, subfptree)
    end

    # in either case, update global and local "counters"
    addcount!(subfptree, 1)
    addcontributors!(subfptree, _contributors)

    # from the new children FPTree, continue the growing process
    push!(subfptree, itemset[2:end], ninstance, miner; htable=htable)
end


Base.push!(
    fptree::FPTree,
    itemsets::Vector{Itemset},
    ninstances::Int64,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing
) = [push!(fptree, itemsets[ninstance], ninstance, miner; htable=htable)
        for ninstance in 1:ninstances]

# TODO: the following is almost identical to the dispatch for `Itemset`s;
# just change
# - how contributors is computed (in one chase, using `contributors` and in this
#   case by accessing the `EnhancedItemset`).
# - make ninstance facultative (it is not needed when using enhanced itemsets)
# The dispatch that takes a collection instead of a single (enhanced) itemset, should
# consider itemsets::Vector{T} where {T <: Union{EnhancedItemset,Itemset}}
function Base.push!(
    fptree::FPTree,
    enhanceditemset::EnhancedItemset,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing,
)
    # if an header table is provided, and its entry associated with the content of `fptree`
    # is still empty, then perform a linking.
    _fptree_content = content(fptree)
    if !isnothing(htable) && _fptree_content !== nothing
        link!(htable, _fptree_content, fptree)
    end

    # end of push case
    if length(enhanceditemset) == 0
        return
    end

    # retrieve the item to grow the tree;
    # to grow a find pattern tree in the modal case scenario, each item has to be associated
    # with its global and local "counters" collected previously.
    # You may ask: "why collected previously?". Well, this dispatch is specialized to
    # grow conditional pattern base
    item, _count, _contributors = first(enhanceditemset)

    # check if a subtree whose content is the first item in `itemset` already exists
    _children = children(fptree)
    _children_idx = findfirst(child -> content(child) == item, _children)
    if !isnothing(_children_idx)
        subfptree = _children[_children_idx]
    # if it does not, then create a new children FPTree, and set this as its parent
    else
        subfptree = FPTree(enhanceditemset, miner) # IDEA: see IDEA below
        children!(fptree, subfptree)
    end

    addcount!(subfptree, _count)
    addcontributors!(subfptree, _contributors)

    # IDEA: this brings up a useless overhead, in the case of IDEA up above;
    # when a FPTree is created from an EnhancedItemset, the header table should already
    # do its linkings. Change FPTree(enhanceditemset) to a specific builder method.
    push!(subfptree, enhanceditemset[2:end], miner; htable=htable)
end

"""$(doc_fptree_push)"""
Base.push!(
    fptree::FPTree,
    enhanceditemsets::ConditionalPatternBase,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing
) = [push!(fptree, itemset, miner; htable=htable) for itemset in enhanceditemsets]

"""
    Base.reverse(htable::HeaderTable)

Iterator on `htable` [`items`](@ref).

See also [`HeaderTable`](@ref), [`Item`](@ref), [`items`](@ref).
"""
Base.reverse(htable::HeaderTable) = reverse(items(htable))

"""
    patternbase(item::Item, htable::HeaderTable, miner::ARuleMiner)::ConditionalPatternBase

Retrieve the conditional pattern base of `fptree` based on `item`.

The conditional pattern based on a [`FPTree`](@ref) is the set of all the paths from the
tree root to nodes containing `item` (not included). Each of these paths is represented
by an [`EnhancedItemset`](@ref), where each [`Item`](@ref) is associated with a
[`WorldsMask`](@ref), given by the minimum of its [`contributors`](@ref) and the ones of
`item`.

The [`EnhancedItemset`](@ref)s in the returned [`ConditionalPatternBase`](@ref) are sorted
decreasingly by [`gsupport`](@ref), as memoized in `miner`.

See also [`ARuleMiner`](@ref), [`ConditionalPatternBase`](@ref), [`contributors`](@ref),
[`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`FPTree`](@ref), [`Item`](@ref),
[`Itemset`](@ref), [`WorldsMask`](@ref).
"""
function patternbase(
    item::Item,
    htable::HeaderTable,
    miner::ARuleMiner
)::ConditionalPatternBase
    # think a pattern base as a vector of vector of itemsets (a vector of vector of items);
    # the reason why the type is explicited differently here, is that every item must be
    # associated with a specific WorldsMask to guarantee correctness.
    _patternbase = ConditionalPatternBase([])

    # follow horizontal references starting from `htable`;
    # for each reference, collect all the ancestors keeping a WorldsMask which, at each
    # position, is the minimum between the value in reference's mask and the new node one.
    fptree = linkages(htable, item)
    fptcount = count(fptree)
    fptcontributors = contributors(fptree)

    # new variable to avoid calling length multiple times later
    _fptcontributors_length = length(fptcontributors)

    # needed to filter out new unfrequent items in the pattern base
    lsupp_integer_threshold = convert(Int64, floor(
        getlocalthreshold(miner, lsupport) * _fptcontributors_length
    ))
    gsupp_integer_threshold = convert(Int64, floor(
        getglobalthreshold(miner, gsupport) * ninstances(dataset(miner))
    ))

    while !isnothing(fptree)
        enhanceditemset = EnhancedItemset([])
        ancestorfpt = parent(fptree)

        # IDEA: `content(ancestorfpt)` is repeated two times while one variable is enough
        while !isnothing(content(ancestorfpt))
            # prepend! instead of push! because we must keep the top-down order of items
            # in a path, but we are visiting a branch from bottom upwards.
            prepend!(enhanceditemset, [(content(ancestorfpt), fptcount,
                min(fptcontributors, ancestorfpt |> contributors))])
            ancestorfpt = parent(ancestorfpt)
        end

        # before following the linkages, push the collected enhanced itemset;
        # items inside the itemset are sorted decreasingly by global support.
        # Note that, although we are working with enhanced itemsets, the sorting only
        # requires to consider the items inside them (so, the "non-enhanced" part).
        sort!(enhanceditemset,
            by=t -> globalmemo(miner, (:gsupport, Itemset([t |> first]) )), rev=true)

        push!(_patternbase, enhanceditemset)
        fptree = linkages(fptree)
    end

    # filter out unfrequent itemsets from a pattern base
    # IDEA: allocating two dictionaries here, instead of a single Dict with `Pair` values,
    # is a waste. Is there a way to obtain the same effect using no immutable structures?
    globalbouncer = DefaultDict{Item,Int64}(0)   # record of respected global thresholds
    localbouncer = DefaultDict{Item,WorldsMask}( # record of respected local thresholds
        zeros(Int64, _fptcontributors_length))
    ispromoted = Dict{Item,Bool}([])          # winner items, which will compose the pbase

    # collection phase
    for itemset in _patternbase         # for each Vector{Tuple{Item,Int64,WorldsMask}}
        for enhanceditem in itemset     # for each Tuple{Item,Int64,WorldsMask} in itemset
            item, _count, _contributors = enhanceditem
            globalbouncer[item] += _count
            map!(sum, localbouncer[item], _contributors)
        end
    end

    # now that dictionaries are filled, establish which are promoted and apply changes
    # in the filtering phase.
    for item in keys(globalbouncer)
        if globalbouncer[item] < gsupp_integer_threshold ||
            Base.count(x ->
                x > 0, localbouncer[item]) < lsupp_integer_threshold
            ispromoted[item] = false
        else
            ispromoted[item] = true
        end
    end

    # filtering phase
    map(itemset -> filter!(t -> ispromoted[first(t)], itemset), _patternbase)

    return _patternbase
end

"""
    function projection(
        pbase::ConditionalPatternBase;
        miner::Union{Nothing,ARuleMiner}=nothing
    )

Return respectively a [`FPTree`](@ref) and a [`HeaderTable`](@ref) starting from `pbase`.
It is reccomended to also provide an [`ARuleMiner`](@ref) to guarantee the generated
header table internal state is OK, that is, its items are sorted decreasingly by
[`gsupport`](@ref).

See also [`ConditionalPatternBase`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref).
"""
function projection(
    pbase::ConditionalPatternBase;
    miner::Union{Nothing,ARuleMiner}=nothing
)
    fptree = FPTree()
    htable = HeaderTable()
    push!(fptree, pbase, miner; htable=htable)

    if !isnothing(miner)
        checksanity!(htable, miner)
    else
        @warn "Mining structure not provided. Correctness is not guaranteed."
    end

    return fptree, htable
end

############################################################################################
#### Main FP-Growth logic ##################################################################
############################################################################################

"""
    fpgrowth(; fulldump::Bool=true, verbose::Bool=true)::Function

Wrapper function for the FP-Growth algorithm over a modal dataset.
Returns a `function f(miner::ARuleMiner, X::AbstractDataset)::Nothing` that runs the main
FP-Growth algorithm logic,
[as described here](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf).
"""
function fpgrowth(;
    fulldump::Bool=true,   # mostly for testing purposes
    verbose::Bool=true,
)::Function

    function _fpgrowth_preamble(miner::ARuleMiner, X::AbstractDataset)::Nothing
        @assert SoleRules.gsupport in reduce(vcat, item_meas(miner)) "FP-Growth requires " *
            "global support (gsupport) as meaningfulness measure in order to " *
            "work. Please, add a tuple (gsupport, local support threshold, " *
            "global support threshold) to miner.item_constrained_measures field.\n" *
            "Local support is needed too, but it is already considered in the global case."

        # retrieve local support threshold, as this is necessary later to filter which
        # frequent items are meaningful on each instance.
        lsupport_threshold = getlocalthreshold(miner, SoleRules.gsupport)

        # get the frequent itemsets from the first candidates set;
        # note that meaningfulness measure should leverage memoization when miner is given!
        frequents = [candidate
            for (gmeas_algo, lthreshold, gthreshold) in item_meas(miner)
            for candidate in Itemset.(alphabet(miner))
            if gmeas_algo(candidate, X, lthreshold, miner=miner) >= gthreshold
        ] |> unique

        # update miner with the frequent itemsets just computed
        push!(freqitems(miner), frequents...)

        # associate each instance in the dataset with its frequent itemsets
        _ninstances = ninstances(X)
        ninstance_toitemsets_sorted = [Itemset() for _ in 1:_ninstances] # Vector{Itemset}

        # for each instance, sort its frequent itemsets by global support
        for i in 1:_ninstances
            ninstance_toitemsets_sorted[i] = reduce(vcat, sort([
                    itemset
                    for itemset in frequents
                    if localmemo(miner, (:lsupport, itemset, i)) > lsupport_threshold
                ], by=t -> globalmemo(miner, (:gsupport, t)), rev=true)
            )
        end

        # create an initial fptree
        fptree = FPTree()

        # create and fill an header table, necessary to traverse FPTrees horizontally
        htable = HeaderTable(frequents, fptree)
        SoleRules.push!(fptree, ninstance_toitemsets_sorted, _ninstances, miner;
            htable=htable)

        # call main logic
        _fpgrowth_kernel(fptree, htable, miner, Itemset())
    end

    function _fpgrowth_kernel(
        fptree::FPTree,
        htable::HeaderTable,
        miner::ARuleMiner,
        leftout_items::Itemset
    )
        # if `fptree` contains only one path (hence, it can be considered a linked list),
        # then combine all the Itemsets collected from previous step with the remained ones.
        if islist(fptree)
            survivor_items = retrieveall(fptree)
            push!(freqitems(miner), (combine(survivor_items, leftout_items)|>collect)...)
        else
            # check header table internal state
            checksanity!(htable,miner)

            for item in reverse(htable)
                # a (conditional) pattern base is a vector of "enhanced" itemsets, that is,
                # itemsets whose items are paired with a contributors vector.
                _patternbase = patternbase(item, htable, miner)

                # A new FPTree is built starting from just the conditional pattern base;
                # note that a header table is associated with the new fptree.
                # `conditional_htable` internal state might be corrupted (no sorted items),
                # but projection invokes a sanity checker inside.
                conditional_fptree, conditional_htable =
                    projection(_patternbase; miner=miner)

                # if the new fptree is not empty, call this recursively, considering `item`
                # as a leftout item.
                if length(children(conditional_fptree)) > 0
                    _fpgrowth_kernel(conditional_fptree, conditional_htable, miner,
                        vcat(leftout_items, item))
                end
            end
        end
    end

    return _fpgrowth_preamble
end
