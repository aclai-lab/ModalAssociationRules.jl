############################################################################################
#### Data structures #######################################################################
############################################################################################

"""
    mutable struct FPTree
        content::Union{Nothing,Item}        # Item contained in this node (nothing if root)

        parent::Union{Nothing,FPTree}       # parent node
        const children::Vector{FPTree}      # children nodes

        count::Int64                        # number of equal Items this node represents

        link::Union{Nothing,FPTree}         # link to another FPTree root
    end

Fundamental data structure used in FP-Growth algorithm.
Essentialy, an [`FPTree`](@ref) is a prefix tree where a root-leaf path represent an
[`Itemset`](@ref).

Consider the [`Itemset`](@ref)s sorted by [`gsupport`](@ref) of their items.
An [`FPTree`](@ref) is such that the common [`Item`](@ref)s-prefix shared by different
[`Itemset`](@ref)s is not stored multiple times.

This implementation generalizes the propositional logic case scenario to modal logic;
given two [`Itemset`](@ref)s sharing a [`Item`](@ref) prefix, the worlds in which they are
true is accumulated.

!!! info
    Did you notice? One FPTree structure contains all the information needed to construct an
    [`EnhancedItemset`](@ref). This is crucial to generate new [`FPTree`](@ref)s during
    fpgrowth algorithm, via building [`ConditionalPatternBase`](@ref) iteratively while
    avoiding visiting the dataset over and over again.

See also [`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`gsupport`](@ref), [`Item`](@ref),
[`Itemset`](@ref), [`WorldMask`](@ref).
"""
mutable struct FPTree
    content::Union{Nothing,Item}        # Item contained in this node (nothing if root)
    parent::Union{Nothing,FPTree}       # parent node
    const children::Vector{FPTree}      # children nodes
    count::Int64                        # number of equal Items this node represents

    link::Union{Nothing,FPTree}         # link to another FPTree root

    # empty constructor
    function FPTree()
        new(nothing, nothing, FPTree[], 0, nothing)
    end

    # choose root or new subtree constructor
    function FPTree(itemset::Itemset; isroot=true)
        # singleton design pattern
        FPTree(itemset, Val(isroot))
    end

    # root constructor
    function FPTree(itemset::Itemset, ::Val{true})
        # make FPTree empty root
        fptree = FPTree()

        # start growing a path
        children!(fptree, FPTree(itemset; isroot=false))

        return fptree
    end

    # internal tree constructor
    function FPTree(itemset::Itemset, ::Val{false})
        # peek element is pushed first: `2,3,...,lastindex(itemset)` will follow
        item = itemset[1]

        # leaf or internal node case scenario
        fptree = length(itemset) == 1 ?
            new(item, nothing, FPTree[], 1, nothing) :
            new(item, nothing,
                FPTree[FPTree(itemset[2:end]; isroot=false)], 1, nothing)

        # vertical link
        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end

    function FPTree(item::Item, count::Int64)
        return new(item, nothing, FPTree[], count, nothing)
    end

    function FPTree(enhanceditemset::EnhancedItemset)
        _itemset = itemset(enhanceditemset)
        _count = count(enhanceditemset)
        _item = first(_itemset)

        fptree = length(_itemset) == 1 ?
            new(_item, nothing, FPTree[], _count, nothing) :
            new(_item, nothing,
                FPTree[(_itemset[2:end], _count) |> EnhancedItemset |> FPTree],
                _count, nothing
            )

        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end
end

"""
    content(fptree::FPTree)::Union{Nothing,Item}

Getter for the [`Item`](@ref) (possibly empty) wrapped by `fptree`.

See also [`content!`](@ref), [`FPTree`](@ref).
"""
content(fptree::FPTree)::Union{Nothing,Item} = fptree.content

"""
    parent(fptree::FPTree)::Union{Nothing,FPTree}

Getter for the parent [`FPTree`](@ref)s of `fptree`.

See also [`FPTree`](@ref), [`parent!`](@ref).
"""
parent(fptree::FPTree)::Union{Nothing,FPTree} = fptree.parent

"""
    children(fptree::FPTree)::Vector{FPTree}

Getter for the list of children [`FPTree`](@ref)s of `fptree`.

See also [`children!`](@ref), [`FPTree`](@ref).
"""
children(fptree::FPTree)::Vector{FPTree} = fptree.children

"""
    Base.count(fptree::FPTree)::Int64

Getter for the `fptree` internal counter.
Essentially, it represents the number of overlappings [`Item`](@ref) which ended up in
`fptree` node during the building process of the tree itself.

See also [`count!`](@ref), [`FPTree`](@ref), [`Item`](@ref).
"""
Base.count(fptree::FPTree)::Int64 = fptree.count

"""
    link(fptree::FPTree)::Union{Nothing,FPTree}

Getter for `fptree`'s next brother [`FPTree`](@ref).
`fptree`'s brotherhood is the set of all the [`FPTree`](@ref) whose content is exactly
`fptree.content`.

See also [`content`](@ref), [`FPTree`](@ref).
"""
link(fptree::FPTree)::Union{Nothing,FPTree} = fptree.link

"""
    content!(fptree::FPTree, item::Union{Nothing,Item})

Setter for `fptree`'s content (the wrapped item).

See also [`content`](@ref), [`FPTree`](@ref).
"""
content!(fptree::FPTree, item::Union{Nothing,Item}) = fptree.content = item

"""
    parent!(fptree::FPTree, item::Union{Nothing,FPTree})

Setter for `fptree`'s parent [`FPTree`](@ref).

See also [`FPTree`](@ref), [`parent`](@ref).
"""
parent!(fptree::FPTree, parentfpt::Union{Nothing,FPTree}) = fptree.parent = parentfpt

"""
    children!(fptree::FPTree, child::FPTree)

Add a new [`FPTree`](@ref) to `fptree`'s children vector.

!!! warning
    This method forces the new children to be added: it is a caller's responsability to
    check whether `child` is not already a children of `fptree` and, if so, handle the case.
    This check is performed, for example, in [`grow!`](@ref).

!!! note
    This method already sets the new children parent to `fptree` itself.

See also [`children`](@ref), [`FPTree`](@ref).
"""
children!(fptree::FPTree, child::FPTree) = begin
    push!(children(fptree), child)
    parent!(child, fptree)
end

"""
    count!(fptree::FPTree, newcount::Int64)

Setter for `fptree`'s internal counter to a fixed value `newcount`.

See also [`count`](@ref), [`FPTree`](@ref).
"""
count!(fptree::FPTree, newcount::Int64) = fptree.count = newcount

"""
    addcount!(fptree::FPTree, newcount::Int64)

Add `newcount` to `fptree`'s internal counter.

See also [`count`](@ref), [`FPTree`](@ref).
"""
addcount!(fptree::FPTree, deltacount::Int64) = fptree.count += deltacount

function isroot(fptree::FPTree)::Bool
    return fptree |> content |> isnothing
end

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
    function itemset_from_fplist(fptree::FPTree)::Itemset

Return all the unique [`Item`](@ref)s appearing in `fptree`.

See also [`FPTree`](@ref), [`Item`](@ref), [`Itemset`](@ref).
"""
function itemset_from_fplist(fptree::FPTree)::Itemset
    @assert islist(fptree) "FPTree is not shaped as list, function call is ambiguous."

    function _retrieve(fptree::FPTree)
        retrieved = Itemset([_retrieve(child) for child in children(fptree)])
        _content = content(fptree)

        if !isnothing(_content)
            push!(retrieved, _content)
        end

        return retrieved
    end

    return _retrieve(fptree)
end

function retrievebycontent(fptree::FPTree, target::Item)::Union{Nothing,FPTree}
    @assert islist(fptree) "FPTree is not shaped as list, function call is ambiguous."

    if content(fptree) == target
        return fptree
    elseif length(fptree |> children) == 0
        return nothing
    else
        return retrievebycontent(fptree |> children |> first, target)
    end
end

"""
    function retrieveleaf(fptree::FPTree)::FPTree

Return a reference to the last node in a list-shaped [`FPTree`](@ref).

See also [`FPTree`](@ref);
"""
function retrieveleaf(fptree::FPTree)::FPTree
    @assert islist(fptree) "FPTree is not shaped as list, function call is ambiguous."

    if length(fptree |> children) == 0
        return fptree
    else
        return retrieveleaf(fptree |> children |> first)
    end
end

"""
    function follow(fptree::FPTree)::Union{Nothing,FPTree}

Follow `fptree` link to (an internal node of) another [`FPTree`](@ref).

See also [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function follow(fptree::FPTree)::Union{Nothing,FPTree}
    arrival = link(fptree)
    return isnothing(arrival) ? fptree : follow(arrival)
end

"""
    function link!(from::FPTree, to::FPTree)

Establish a link between two [`FPTree`](@ref)s.
If the starting tree is already linked with something, the already existing link are
followed until a new "empty-linked" [`FPTree`](@ref) is found.

See also [`follow`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function link!(from::FPTree, to::FPTree)
    # find the last FPTree by iteratively following the internal link
    @assert from !== link(from) "Error - self linking the following FPTree: \n$(from)"

    from = follow(from)
    from.link = to
end

function Base.show(io::IO, fptree::FPTree; indentation::Int64=0)
    _children = children(fptree)

    println(io, "-"^indentation * "*"^(length(_children)==0) *
        "$(fptree |> content |> syntaxstring) \t\t count: $(count(fptree))")

    for child in children(fptree)
        Base.show(io, child; indentation=indentation+1)
    end
end

"""
    struct HeaderTable
        items::Vector{Item}
        link::Dict{Item,Union{Nothing,FPTree}}
    end

Utility data structure used to fastly access [`FPTree`](@ref) internal nodes.
"""
struct HeaderTable
    # vector of Items, sorted decreasingly by global support
    items::Vector{Item}

    # association Item -> FPTree
    link::Dict{Item,Union{Nothing,FPTree}}

    function HeaderTable()
        new(Item[], Dict{Item,Union{Nothing,FPTree}}())
    end

    function HeaderTable(
        fptseed::FPTree;
        miner::Union{Nothing,Miner}=nothing
    )
        htable = new(Vector{Item}(), Dict{Item,Union{Nothing,FPTree}}([]))

        function fillhtable!(_children::Vector{FPTree}, htable::HeaderTable)
            # recursively fill htable
            for c in _children
                link!(htable, c)
                fillhtable!(children(c), htable)
            end
        end

        fillhtable!(children(fptseed), htable)

        if !isnothing(miner)
            checksanity!(htable, miner)
        end

        return htable
    end
end

"""
    items(htable::HeaderTable)::Vector{Item}

Getter for the [`Item`](@ref)s loaded inside `htable`.

See also [`HeaderTable`](@ref), [`Item`](@ref).
"""
items(htable::HeaderTable)::Vector{Item} = htable.items

"""
    link(htable::HeaderTable)
    link(htable::HeaderTable, item::Item)

Getter for the link structure wrapped by `htable`, or one of its specific entry.

The link structure is, essentially, a dictionary associating an [`Item`](@ref) to a
specific [`FPTree`](@ref).

See also [`FPTree`](@ref), [`HeaderTable`](@ref), [`Item`](@ref), [`link!`](@ref).
"""
link(htable::HeaderTable) = htable.link
link(htable::HeaderTable, item::Item) = htable.link[item]

"""
    function follow(htable::HeaderTable, item::Item)::Union{Nothing,FPTree}

Follow `htable` link to (an internal node of) a [`FPTree`](@ref).

See also [`FPTree`](@ref), [`HeaderTable`](@ref), [`Item`](@ref), [`link`](@ref),
[`link!`](@ref).
"""
function follow(htable::HeaderTable, item::Item)::Union{Nothing,FPTree}
    arrival = link(htable, item)
    return isnothing(arrival) ? arrival : follow(arrival)
end

"""
    function link!(htable::HeaderTable, fptree::FPTree)

Establish a link towards `fptree`, [`follow`](@ref)ing the entry in `htable` corresponding
to the [`content`](@ref) of `fptree`.

See also [`content`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function link!(htable::HeaderTable, fptree::FPTree)
    _content = content(fptree)

    hitems = items(htable)
    if !(_content in hitems)
        # the content of `fptree` was never seen before by this `htable`
        push!(hitems, _content)
        htable.link[_content] = fptree
        return
    end

    if isnothing(htable.link[_content])
        # the content of `fptree` is already loaded: an empty `HeaderTable` constructor
        # was called sometime before now and the entry associated with the content is empty.
        htable.link[_content] = fptree
    else
        # a new linkage is established
        from = follow(htable, _content)
        if from !== fptree
            link!(from, fptree)
        end
    end
end

"""
    function checksanity!(htable::HeaderTable, miner::Miner)::Bool

Check if `htable` internal state is correct, that is, its `items` are sorted decreasingly
by global support.
If `items` are already sorted, return `true`; otherwise, sort them and return `false`.

See also [`Miner`](@ref), [`gsupport`](@ref), [`HeaderTable`](@ref), [`items`](@ref).
"""
function checksanity!(htable::HeaderTable, miner::Miner)::Bool
    _issorted = issorted(items(htable),
        by=t -> powerups(miner, :current_items_frequency)[Itemset(t)], rev=true)

    # force sorting if needed
    if !_issorted
        sort!(items(htable),
            by=t -> powerups(miner, :current_items_frequency)[Itemset(t)], rev=true)
    end

    return _issorted
end

doc_fptree_push = """
    function grow!(
        fptree::FPTree,
        itemset::Itemset,
        ninstance::Int64,
        miner::Miner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    function grow!(
        fptree::FPTree,
        itemset::EnhancedItemset,
        ninstance::Int64,
        miner::Miner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    grow!(
        fptree::FPTree,
        enhanceditemsets::Union{ConditionalPatternBase,Vector{Itemset}},
        miner::Miner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

Push one or more [`Itemset`](@ref)s/[`EnhancedItemset`](@ref) to an [`FPTree`](@ref).
If an [`HeaderTable`](@ref) is provided, it is leveraged to develop internal links.

See also [`EnhancedItemset`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref), [`Itemset`](@ref).
"""

"""$(doc_fptree_push)"""
function grow!(
    fptree::FPTree,
    enhanceditemset::EnhancedItemset,
    miner::Miner
)
    _itemset = itemset(enhanceditemset)

    # base case
    if length(_itemset) == 0
        return
    end

    # sorting must be guaranteed: remember an FPTree essentially is a prefix tree
    sort!(items(_itemset),
        by=t -> powerups(miner, :current_items_frequency)[Itemset(t)], rev=true)

    # retrieve the item to grow the tree, and its count
    _count = count(enhanceditemset)
    _item = first(_itemset)

    # check if a subtree whose content is `_item` already exists
    _children = children(fptree)

    _children_idx = findfirst(child -> content(child) == _item, _children)
    if !isnothing(_children_idx)
        # there is no need to create a new child, just grow an already existing one
        subfptree = _children[_children_idx]
        addcount!(subfptree, _count)
        grow!(subfptree, (_itemset[2:end], _count) |> EnhancedItemset, miner)
    else
        # here we want to create a new children FPTree, and set this as its parent;
        # note that we don't want to update count and contributors since we already
        # copy it from the enhanced itemset.
        subfptree = FPTree(enhanceditemset)
        children!(fptree, subfptree)
    end
end

"""$(doc_fptree_push)"""
function grow!(
    fptree::FPTree,
    itemset::Itemset,
    miner::Miner
)
    grow!(fptree, convert(EnhancedItemset, itemset, 1), miner)
end

"""$(doc_fptree_push)"""
function grow!(
    fptree::FPTree,
    collection::Union{ConditionalPatternBase,Vector{Itemset}},
    miner::Miner;
    kwargs...
)
    map(element -> grow!(fptree, element, miner; kwargs...), collection)
end

"""
    Base.reverse(htable::HeaderTable)

Iterator on `htable` wrapped [`Item`](@ref)s, in reverse order.

See also [`HeaderTable`](@ref), [`Item`](@ref).
"""
Base.reverse(htable::HeaderTable) = reverse(items(htable))

"""
    patternbase(item::Item, htable::HeaderTable, miner::Miner)::ConditionalPatternBase

Retrieve the [`ConditionalPatternBase`](@ref) of `fptree` based on `item`.

The conditional pattern based on a [`FPTree`](@ref) is the set of all the paths from the
tree root to nodes containing `item` (not included). Each of these paths is represented
by an [`EnhancedItemset`](@ref).

The [`EnhancedItemset`](@ref)s in the returned [`ConditionalPatternBase`](@ref) are sorted
decreasingly by [`gsupport`](@ref).

See also [`Miner`](@ref), [`ConditionalPatternBase`](@ref), [`contributors`](@ref),
[`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`FPTree`](@ref), [`Item`](@ref),
[`Itemset`](@ref), [`WorldMask`](@ref).
"""
function patternbase(
    item::Item,
    htable::HeaderTable,
    miner::Miner
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
        sort!(items(_itemset),
            by=t -> powerups(miner, :current_items_frequency)[Itemset(t)], rev=true)

        push!(_patternbase, EnhancedItemset((_itemset, fptcount)))

        fptree = link(fptree)
    end

    # assert pattern base does not contain dirty leftovers
    filter!(x -> !isempty(first(x)), _patternbase)

    return _patternbase, leftout_count
end

function bounce!(pbase::ConditionalPatternBase, miner::Miner)
    # accumulators needed to establish whether an enhanced itemset is promoted or no
    count_accumulator = DefaultDict{Item, Int64}(0)

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
            count_accumulator[_item] / nworlds(miner) >= getlocalthreshold(miner, gsupport),
            enhanceditemset |> itemset |> items
        )
    end

    # assert pattern base does not contain dirty leftovers
    filter!(x -> !isempty(first(x)), pbase)
end

"""
    function projection(pbase::ConditionalPatternBase, miner::Miner)

Return respectively a [`FPTree`](@ref) and a [`HeaderTable`](@ref) starting from `pbase`.
A [`Miner`](@ref) must be provided to guarantee the generated header table internal state
is OK, that is, its items are sorted decreasingly by [`gsupport`](@ref).

See also [`ConditionalPatternBase`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref), [`Miner`](@ref).
"""
function projection(
    pbase::ConditionalPatternBase,
    miner::Miner
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
function _fragments_reducer(a::DefaultDict{Itemset, Int},  b::DefaultDict{Itemset, Int})
    c = deepcopy(a) # TODO: deepcopy should not be needed here

    for k in keys(b)
        c[k] += b[k]
    end

    return c
end

############################################################################################
#### Main FP-Growth logic ##################################################################
############################################################################################

"""
    fpgrowth(miner::Miner, X::AbstractDataset; verbose::Bool=true)::Nothing

FP-Growth algorithm,
[as described here](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf)
but generalized to also work with modal logic.

See also [`Miner`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref),
[`SoleBase.AbstractDataset`](@ref)
"""
function fpgrowth(
    miner::Miner,
    X::AbstractDataset;
    parallel::Bool=false, # WIP
    distributed::Bool=true,
    verbose::Bool=false
)::Nothing
    # How does ModalFP-Growth work?
    # Consider the dataset rearranged as follows:
    #
    #       w0  w1  ... wN
    #   I0
    #   I1
    #   ..
    #   IN
    #
    # For each instance I, apply fpgrowth horizontally across worlds to find all the
    # locally frequent itemsets associated with I;
    # then, merge all the results together to compute the global support of each generated
    # itemset (that is, how many times an itemset appear as the result of an FP-Growth
    # application on an Instance)

    # initialization logic
    @assert ModalAssociationRules.gsupport in reduce(vcat, itemsetmeasures(miner)) "" *
        "FP-Growth " *
        "requires global support (gsupport) as meaningfulness measure in order to " *
        "work. Please, add a tuple (gsupport, local support threshold, " *
        "global support threshold) to miner.item_constrained_measures field.\n" *
        "Note that local support is needed too, but it is already considered internally " *
        "by global support."

    if Threads.nthreads() > 1
        verbose && parallelize && printstyled("Multithreading enabled with " *
            "#$(Threads.nthreads()) threads\n")
    end

    # arbitrary general lexicographic ordering
    incremental = 0
    for candidate in items(miner)
        powerups(miner, :lexicographic_ordering)[candidate] = incremental
        incremental += 1
    end

    fpgrowth_fragments = reduce(
        _fragments_reducer,
        Distributed.pmap(
            ninstance -> _fpgrowth(ninstance, miner),
            1:ninstances(X);
            distributed=distributed,
            # on_error=e -> TODO
        )
    )

    for (itemset, gfrequency_int) in fpgrowth_fragments
        _threshold = getglobalthreshold(miner, gsupport)
        gfrequency = gfrequency_int / ninstances(X)
        if gfrequency >= _threshold
            globalmemo!(miner, GmeasMemoKey((Symbol(gsupport), itemset)), gfrequency)
            push!(freqitems(miner), itemset)
        end

        # TODO: check other custom meaningfulness measures
    end
end

# `fpgrowth` main logic
function _fpgrowth(
    ninstance::Int,
    _miner::Miner
)
    # avoid data-race (e.g., if this function is used in a pmap)
    # TODO: I want each worker to work with the exact and only memory he needs.
    miner = deepcopy(_miner)
    X = dataset(miner)

    # collect the local results, accumulated by this run;
    # those results are reduced together (e.g., if this function is used in a pmap)
    fpgrowth_fragments = DefaultDict{Itemset, Int}(0)

    # the instance we are applying fpgrowth to has to be remembered to properly store
    # local support at the end of each sub-fpgrowth execution.
    powerups!(miner, :current_instance, ninstance)

    # the frequency of each 1-length frequent itemset is tracked in a fresh dictionary;
    # this may vary between each iteration of this cycle (each sub-fpgrowth execution).
    powerups!(miner, :current_items_frequency, DefaultDict{Itemset, Int}(0))

    # from now on, the instance is fixed and we apply fpgrowth horizontally;
    # the assumption here is that all the frames are shaped equally.
    kripkeframe = SoleLogics.frame(X, 1)
    _nworlds = kripkeframe |> SoleLogics.nworlds
    nworld_to_itemset = [Itemset() for _ in 1:_nworlds]

    # get the frequent 1-length itemsets from the first candidates set;
    frequents = [candidate
        for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
        for candidate in Itemset.(items(miner))
        if lsupport(candidate, getinstance(X, ninstance), miner) >= lthreshold
    ] |> unique

    for itemset in frequents
        fpgrowth_fragments[itemset] += 1
    end

    for (nworld, w) in enumerate(kripkeframe |> SoleLogics.allworlds)
        nworld_to_itemset[nworld] = [
            itemset
            for itemset in frequents
            if powerups(
                miner, :instance_item_toworlds)[(ninstance, itemset)][nworld] > 0
        ] |> union

        # count 1-length frequent itemsets frequency;
        # a.k.a prepare miner internal powerups state to handle an FPGrowth call.
        for item in nworld_to_itemset[nworld]
            powerups(miner, :current_items_frequency)[Itemset(item)] += 1
        end
    end

    # create an initial fptree and populate it
    fptree = FPTree()
    ModalAssociationRules.grow!(fptree, nworld_to_itemset, miner)

    # create and fill an header table, necessary to traverse FPTrees horizontally
    htable = HeaderTable(fptree; miner=miner)

    # call main logic
    _fpgrowth_kernel(fptree, htable, miner, FPTree(), fpgrowth_fragments)

    return fpgrowth_fragments
end

# `fpgrowth` recursive logic; scroll down to see initialization section.
function _fpgrowth_kernel(
    fptree::FPTree,
    htable::HeaderTable,
    miner::Miner,
    leftout_fptree::FPTree,
    fpgrowth_fragments::DefaultDict{Itemset, Int}
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
                return _leftout_count / nworlds(miner)
            end,
            (combo) -> begin
                #  we don't want to consider the single item combination case
                return (length(combo) > 1 ? 1 : 0)
            end,
            miner,
            fpgrowth_fragments
        )

        _fpgrowth_count_phase(
            leftout_itemset,
            Itemset(),
            (combo) -> begin
                # here, computation is simpler than the previous
                # `lsupport_value_calculator` lambda function implementation.
                return count(retrieveleaf(leftout_fptree)) / nworlds(miner)
            end,
            (combo) -> begin
                # we don't want to consider the single item combination case
                return (length(combo) > 1 ? 1 : 0)
            end,
            miner,
            fpgrowth_fragments
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
                _leftout_fptree,
                fpgrowth_fragments
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
    miner::Miner,
    fpgrowth_fragments::DefaultDict{Itemset, Int}
)
    for combo in combine_items(items(survivor_itemset), items(leftout_itemset))
        # each combo must be reshaped, following a certain order specified
        # universally by the miner.
        sort!(items(combo), by=t -> powerups(miner, :lexicographic_ordering)[t])

        # instance for which we want to update local support
        current_instance = powerups(miner, :current_instance)
        memokey = (:lsupport, combo, current_instance)

        # new local support value
        lsupport_value = lsupport_value_calculator(combo)

        # first time found for this instance
        first_time_found = !haskey(miner.lmemo, memokey)

        # local support needs to be updated
        if first_time_found || lsupport_value > miner.lmemo[memokey]
            localmemo!(miner,
                (:lsupport, combo, current_instance),
                lsupport_value
            )
        end

        # if local support was set from fresh (and not updated), then also update
        # the information needed to reconstruct global support later.
        if first_time_found
            fpgrowth_fragments[combo] += count_increment_strategy(combo)
        end
    end
end

"""
    initpowerups(::typeof(fpgrowth), ::AbstractDataset)::Powerup

Powerups suite for FP-Growth algorithm.
When initializing a [`Miner`](@ref) with [`fpgrowth`](@ref) algorithm, this defines
how miner's `powerup` field is filled to optimize the mining.
See also [`haspowerup`](@ref), [`powerup`](@ref).
"""
function initpowerups(::typeof(fpgrowth), ::AbstractDataset)::Powerup
    return Powerup([
        # given and instance I and an itemset λ, the default behaviour when computing
        # local support is to perform model checking to establish in how many worlds
        # the relation I,w ⊧ λ is satisfied.
        # A numerical value is obtained, but the exact worlds in which the truth relation
        # holds is not kept in memory by default.
        # Here, however, we want to keep track of the relation.
        # See `lsupport` implementation.
        :instance_item_toworlds => Dict{Tuple{Int, Itemset}, WorldMask}([]),

        # current instance number;
        # needed when computing local support to remember which
        # instance is associated with a sub-fpgrowth execution.
        :current_instance => 0,

        # when modal fpgrowth calls propositional fpgrowth multiple times, each call
        # has to know its specific 1-length itemsets ordering;
        # otherwise, the building process of fptrees is not correct anymore.
        :current_items_frequency => DefaultDict{Itemset, Int}(0),

        # necessary to reshape all the extracted itemsets to a common ordering
        :lexicographic_ordering => Dict{Item, Int}([])
    ])
end
