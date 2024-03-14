############################################################################################
#### Data structures #######################################################################
############################################################################################

"""
    mutable struct FPTree
        content::Union{Nothing,Item}        # Item contained in this node (nothing if root)

        parent::Union{Nothing,FPTree}       # parent node
        const children::Vector{FPTree}      # children nodes

        count::Int64                        # number of equal Items this node represents

        # how many times lsupp(content) does overpass
        # the corresponding threshold for each world
        const contributors::WorldMask

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
    fpgrowth algorithm, via building [`ConditionalPatternBase`](@ref) iteratively while avoiding
    visiting the dataset over and over again.

See also [`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`gsupport`](@ref), [`Item`](@ref),
[`Itemset`](@ref), [`WorldMask`](@ref).
"""
mutable struct FPTree
    content::Union{Nothing,Item}        # Item contained in this node (nothing if root)
    parent::Union{Nothing,FPTree}       # parent node
    const children::Vector{FPTree}      # children nodes
    count::Int64                        # number of equal Items this node represents

    # how many times lsupp(content) does overpass
    # the corresponding threshold for each world
    const contributors::WorldMask
    link::Union{Nothing,FPTree}         # link to another FPTree root

    # empty constructor
    function FPTree()
        new(nothing, nothing, FPTree[], 0, Int64[], nothing)
    end

    # choose root or new subtree constructor;
    # ninstance is needed to start defining `contributors` for each node,
    # as this is not a standard, propositional FPTree but a more general modal one.
    function FPTree(
        itemset::Itemset;
        ninstance::Union{Nothing,Int64}=nothing,
        isroot=true,
        miner::Union{Nothing,Miner}=nothing
    )
        # singleton design pattern
        FPTree(itemset, Val(isroot); miner=miner, ninstance=ninstance)
    end

    # root constructor
    function FPTree(
        itemset::Itemset,
        ::Val{true};
        ninstance::Union{Nothing,Int64},
        miner::Union{Nothing,Miner}=nothing
    )
        # make FPTree empty root
        fptree = FPTree()

        # start growing a path
        children!(fptree, FPTree(itemset; isroot=false, miner=miner, ninstance=ninstance))

        return fptree
    end

    # internal tree constructor
    function FPTree(
        itemset::Itemset,
        ::Val{false};
        miner::Union{Nothing,Miner}=nothing,
        ninstance::Union{Nothing,Int64}=nothing
    )
        item = itemset[1]

        @assert !xor(isnothing(miner), isnothing(ninstance)) "Miner and instance number " *
            "associated with the FPTree creation must be given simultaneously as kwargs."

        _contributors = isnothing(miner) ?
            zeros(Int64,1) : SoleRules.contributors(:lsupport, item, ninstance, miner)

        fptree = length(itemset) == 1 ?
            new(item, nothing, FPTree[], 1, _contributors, nothing) :
            new(item, nothing,
                FPTree[
                    FPTree(itemset[2:end]; isroot=false, miner=miner, ninstance=ninstance)],
                1, _contributors, nothing)

        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end

    function FPTree(enhanceditemset::EnhancedItemset)
        item, _count, _contributors = first(enhanceditemset)
        fptree = length(enhanceditemset) == 1 ?
            new(item, nothing, FPTree[], _count, _contributors, nothing) :
            new(item, nothing, FPTree[FPTree(enhanceditemset[2:end])],
                _count, _contributors, nothing)

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
    contributors(fptree::FPTree)::WorldMask

Getter for the `fptree` contributors array.

Consider the [`Contributors`](@ref) definition.
In the specific case of an [`FPTree`](@ref), the contributors array is simply a vector of
integers which answers the following question for each i-th world of a generic instance:
given a local support threshold `t`, how many times is `lsupp(content) >= t` ?

Essentially, it represents the number of overlappings [`Item`](@ref) which ended up in
`fptree` node during the building process of the tree itself.

See also [`Contributors`](@ref), [`contributors!`](@ref), [`FPTree`](@ref), [`Item`](@ref),
[`lsupport`](@ref).
"""
contributors(fptree::FPTree)::WorldMask = fptree.contributors

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
    This check is performed, for example, in [`Base.push!`](@ref).

!!! note
    This method already sets the new children parent to `fptree` itself.

See also [`Base.push!`](@ref), [`children`](@ref), [`FPTree`](@ref).
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

"""
    contributors!(fptree::FPTree, contribution::WorldMask)

Setter for `fptree`'s internal contributors mask to `contribution` [`WorldMask`](@ref).

See also [`contributors`](@ref), [`FPTree`](@ref), [`WorldMask`](@ref).
"""
function contributors!(fptree::FPTree, contribution::WorldMask)
    @assert length(contributors(fptree)) == length(contribution) "Masks length mismatch. " *
        "FPTree contributors mask length is $(length(contributors(fptree))), while the " *
        "provided mask length is $(length(contribution))."

    map!(x -> x, contributors(fptree), contribution)
end

"""
    addcontributors!(fptree::FPTree, contribution::WorldMask) =

Add the `contribution` [`WorldMask`](@ref) to `fptree`'s internal contributors mask.

See also [`contributors`](@ref), [`FPTree`](@ref), [`WorldMask`](@ref).
"""
addcontributors!(fptree::FPTree, contribution::WorldMask) =
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

Return all the unique [`Item`](@ref)s appearing in `fptree`.

See also [`FPTree`](@ref), [`Item`](@ref), [`Itemset`](@ref).
"""
function retrieveall(fptree::FPTree)::Itemset
    # internal function just to avoid repeating the final `unique`
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
    from = follow(from)

    if from.link === nothing && to.link === nothing
        from.link = to
    end
end

function Base.show(io::IO, fptree::FPTree; indentation::Int64=0)
    _children = children(fptree)
    println(io, "-"^indentation * "*"^(length(_children)==0) *
        "$(fptree |> content |> syntaxstring) - count: $(count(fptree))")

    for child in children(fptree)
        Base.show(io, child; indentation=indentation+1)
    end
end

"""
    prune!(fptree::FPTree, miner::Miner)

Prune subtrees of `fptree`, if their [`count`](@ref) or [`contributors`](@ref) is not enough
to overpass the integer threshold associated with [`gsupport`](@ref) or [`lsupport`](@ref).

See also [`contributors`](@ref), [`count`](@ref), [`FPTree`](@ref),
[`getglobalthreshold_integer`](@ref), [`gsupport`](@ref),
[`getlocalthreshold_integer`](@ref), [`lsupport`](@ref).
"""
function prune!(fptree::FPTree, miner::Miner)
    if isempty(children(fptree))
        return
    end

    # float gsupport threshold
    gsupp_t = getglobalthreshold(miner, gsupport)

    # gsupport integer threshold
    gsupp_int_t = getglobalthreshold_integer(miner, gsupport, ninstances(dataset(miner)))

    # contributors length and lsupport integer threshold
    contribslen = children(fptree)[1] |> contributors |> length
    lsupp_int_t =  getlocalthreshold_integer(
        miner, lsupport, contribslen)

    # is global support honored by child?
    filter!(child -> count(child) >= gsupp_int_t, children(fptree))

    # percentage of worlds for which local support is satisfied,
    # must be greater than global support.
    filter!(child ->
            count(c -> c >= lsupp_int_t, contributors(child)) / contribslen >= gsupp_t,
        children(fptree)
    )

    for child in children(fptree)
        prune!(child, miner)
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

    # Item -> FPTree association
    link::Dict{Item,Union{Nothing,FPTree}}

    function HeaderTable()
        new(Item[], Dict{Item,Union{Nothing,FPTree}}())
    end

    function HeaderTable(
        items::Vector{<:Item},
        fptseed::FPTree;
        miner::Union{Nothing,Miner}=nothing
    )
        @assert content(fptseed) === nothing "`fptseed` is not a seeder " *
        "FPTree, that is, its root content is $(content(fptseed)) instead of " *
        "nothing."

        @assert islist(fptseed) "`fptseed` is not a simple list FPTree. " *
        "Currently, only simple list FPTree are supported to automatically " *
        "build and HeaderTable. Please, make sure islist(fptseed) is true."

        # make an empty htable, whose entries are `Item` objects, in `items`
        htable = new(items, Dict{Item,Union{Nothing,FPTree}}([
            item => nothing for item in items]))

        # iteratively fill htable
        child = children(fptseed)
        while !isempty(child)
            childfpt = first(child)
            link!(htable, childfpt)
            child = children(childfpt)
        end

        if !isnothing(miner)
            checksanity!(htable, miner)
        end

        return htable
    end

    function HeaderTable(
        itemsets::Vector{<:Itemset},
        fptseed::FPTree;
        miner::Union{Nothing,Miner}=nothing
    )
        return HeaderTable(convert.(Item, itemsets), fptseed; miner=miner)
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

    # the content of `fptree` was never seen before by this `htable`
    hitems = items(htable)
    if !(_content in hitems)
        push!(hitems, _content)
        htable.link[_content] = nothing
    end

    # the content of `fptree` was loaded into the header table, but never looked up
    if link(htable, _content) |> isnothing
        htable.link[_content] = fptree
        return
    end

    # the arrival FPTree is linked to the new `fptree`
    arrival = follow(htable, _content)
    if arrival isa FPTree && arrival != fptree
        link!(arrival, fptree)
    # invalid optionì
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
        miner::Miner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    function Base.push!(
        fptree::FPTree,
        itemset::EnhancedItemset,
        ninstance::Int64,
        miner::Miner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    Base.push!(
        fptree::FPTree,
        enhanceditemsets::ConditionalPatternBase,
        miner::Miner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

Push one or more [`Itemset`](@ref)s/[`EnhancedItemset`](@ref) to an [`FPTree`](@ref).
If an [`HeaderTable`](@ref) is provided, it is leveraged to develop internal links.

!!! warning
    To optimally leverage the compression capabilities of [`FPTree`](@ref)s, the
    [`Itemset`](@ref)s provided should be sorted decreasingly by [`gsupport`](@ref).
    By default, to improve performances, this check is not performed inside this method.

See also [`EnhancedItemset`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref), [`Itemset`](@ref).
"""

# # IDEA: write uniquely the following dispatch, merging Itemset and EnhancedItemset cases
# function Base.push!(
#     fptree::FPTree,
#     itemsets::Vector{T},
#     miner::Miner;
#     htable::HeaderTable
# ) where {T <: Union{Itemset, EnhancedItemset}}

"""$(doc_fptree_push)"""
function Base.push!(
    fptree::FPTree,
    itemset::Itemset,
    ninstance::Int64,
    miner::Miner;
    htable::Union{Nothing,HeaderTable}=nothing
)
    # if an header table is provided, and its entry associated with the content of `fptree`
    # is still empty, then perform a linking.
    _fptree_content = content(fptree)

    if htable !== nothing && _fptree_content !== nothing && link(fptree) === nothing
        link!(htable, fptree)
    end

    # end of push case
    if length(itemset) == 0
        return
    end

    sort!(items(itemset), by=t -> globalmemo(miner, (:gsupport, Itemset(t))), rev=true)

    # retrieve the item to grow the tree;
    # to grow a find pattern tree in the modal case scenario, each item has to be associated
    # with its global counter (always 1!) and its contributors array (see [`WorldMask`]).
    item = first(itemset)

    _contributors = contributors(:lsupport, item, ninstance, miner)

    # check if a subtree whose content is the first item in `itemset` already exists
    _children = children(fptree)
    _children_idx = findfirst(child -> content(child) == item, _children)
    if !isnothing(_children_idx)
        # a child containing item already exist: grow deeper in this direction
        subfptree = _children[_children_idx]
        addcount!(subfptree, 1)
        addcontributors!(subfptree, _contributors)
        push!(subfptree, itemset[2:end], ninstance, miner; htable=htable)
    else
        # if it does not, then create a new children FPTree, and set this as its parent
        subfptree = FPTree(itemset; isroot=false, miner=miner, ninstance=ninstance)
        children!(fptree, subfptree)
        addcount!(subfptree, 1)
        addcontributors!(subfptree, _contributors)
    end
end

Base.push!(
    fptree::FPTree,
    itemsets::Vector{Itemset},
    ninstances::Int64,
    miner::Miner;
    htable::Union{Nothing,HeaderTable}=nothing,
    kwargs...
) = map(ninstance -> push!(
    fptree, itemsets[ninstance], ninstance, miner; htable=htable, kwargs...), 1:ninstances)

function Base.push!(
    fptree::FPTree,
    enhanceditemset::EnhancedItemset,
    miner::Miner;
    htable::Union{Nothing,HeaderTable}=nothing,
)
    # if an header table is provided, and its entry associated with the content of `fptree`
    # is still empty, then perform a linking.
    if htable !== nothing && content(fptree) !== nothing && link(fptree) === nothing
        link!(htable, fptree)
    end

    # end of push case
    if length(enhanceditemset) == 0
        return
    end

    # retrieve the item to grow the tree;
    # to grow a find pattern tree in the modal case scenario, each item has to be associated
    # with its global and local "counters" collected previously.
    # You may ask: why collected previously? Well, this dispatch is specialized to grow
    # conditional pattern base.
    item, _count, _contributors = first(enhanceditemset)

    # check if a subtree whose content is the first item in `itemset` already exists
    _children = children(fptree)

    _children_idx = findfirst(child -> content(child) == item, _children)
    if !isnothing(_children_idx)
        # i don't want to create a new child, just grow an already existing one
        subfptree = _children[_children_idx]
        addcount!(subfptree, _count)

        # here it is wrong to cumulate contributors; instead, we keep the minimum pairwise.
        # After the initial "apriori like" phase of fpgrowth, and the construction of the
        # first FPTree, the information about the local support of each item is always
        # decreasing as the itemsets in which they live grows longer and longer.
        contributors!(subfptree, map(min, contributors(subfptree), _contributors))

        push!(subfptree, enhanceditemset[2:end], miner; htable=htable)
    else
        # here i want to create a new children FPTree, and set this as its parent;
        # note that, here, i don't want to update count and contributors since i am already
        # copying them from the enhanced itemset.
        subfptree = FPTree(enhanceditemset)
        children!(fptree, subfptree)
    end
end

Base.push!(
    fptree::FPTree,
    enhanceditemsets::ConditionalPatternBase,
    miner::Miner;
    htable::Union{Nothing,HeaderTable}=nothing
) = [push!(fptree, itemset, miner; htable=htable) for itemset in enhanceditemsets]

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
by an [`EnhancedItemset`](@ref), where each [`Item`](@ref) is associated with a
[`WorldMask`](@ref), given by the minimum of its [`contributors`](@ref) and the ones of
`item`.

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
)::ConditionalPatternBase
    # think a pattern base as a vector of vector of itemsets;
    # the reason why the type is explicited differently here, is that every item must be
    # associated with a specific WorldMask to guarantee correctness.
    _patternbase = ConditionalPatternBase([])

    # follow horizontal references starting from `htable`;
    # for each reference, collect all the ancestors keeping a WorldMask which, at each
    # position, is the minimum between the value in reference's mask and the new node one.
    fptree = link(htable, item)
    cumulated_count = 0

    while !isnothing(fptree)
        fptcount = count(fptree)
        fptcontributors = contributors(fptree)

        cumulated_count += fptcount

        enhanceditemset = EnhancedItemset([])
        ancestorfpt = parent(fptree)

        # look at ancestors, and get collect them keeping count and contributors of
        # the leaf node from which we started this vertical visit.
        while !isnothing(content(ancestorfpt))
            # prepend! instead of push! because we must keep the top-down order of items
            # in a path, but we are visiting a branch from bottom upwards.
            prepend!(enhanceditemset, [(content(ancestorfpt), fptcount,
                map(min, fptcontributors, ancestorfpt |> contributors))])

            ancestorfpt = parent(ancestorfpt)
        end

        # before following the link, push the collected enhanced itemset;
        # items inside the itemset are sorted decreasingly by global support.
        # Note that, although we are working with enhanced itemsets, the sorting only
        # requires to consider the items inside them (so, the "non-enhanced" part).
        sort!(enhanceditemset,
            by=t -> globalmemo(miner, (:gsupport, Itemset([t |> first]) )), rev=true)

        push!(_patternbase, enhanceditemset)

        fptree = link(fptree)
    end

    return _patternbase
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
    fptree = FPTree()
    htable = HeaderTable()
    push!(fptree, pbase, miner; htable=htable)

    if !isnothing(miner)
        checksanity!(htable, miner)
    else
        @warn "Mining structure not provided. Correctness is not guaranteed."
    end

    prune!(fptree, miner)

    return fptree, htable
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
function fpgrowth(miner::Miner, X::AbstractDataset; verbose::Bool=false)::Nothing
    # initialization logic
    @assert SoleRules.gsupport in reduce(vcat, itemsetmeasures(miner)) "FP-Growth " *
        "requires global support (gsupport) as meaningfulness measure in order to " *
        "work. Please, add a tuple (gsupport, local support threshold, " *
        "global support threshold) to miner.item_constrained_measures field.\n" *
        "Local support is needed too, but it is already considered in the global case."

    # retrieve local support threshold, as this is necessary later to filter which
    # frequent items are meaningful on each instance.
    lsupport_threshold = getlocalthreshold(miner, SoleRules.gsupport)

    verbose && printstyled("Generating frequent itemsets of length 1...\n", color=:green)

    # get the frequent itemsets from the first candidates set;
    # note that meaningfulness measure should leverage memoization when miner is given!
    frequents = [candidate
        for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
        for candidate in Itemset.(items(miner))
        if gmeas_algo(candidate, X, lthreshold, miner=miner) >= gthreshold
    ] |> unique

    verbose && printstyled("Saving computed metrics into miner...\n", color=:green)

    # update miner with the frequent itemsets just computed
    push!(freqitems(miner), frequents...)

    verbose && printstyled("Preprocessing frequent itemsets...\n", color=:green)

    # associate each instance in the dataset with its frequent itemsets
    _ninstances = ninstances(X)
    ninstance_to_sorteditemset = [Itemset() for _ in 1:_ninstances] # Vector{Itemset}

    # for each instance, sort its frequent itemsets by global support
    for i in 1:_ninstances
        _sorteditemsets = sort([
                itemset
                for itemset in frequents
                if localmemo(miner, (:lsupport, itemset, i)) > lsupport_threshold
            ], by=t -> globalmemo(miner, (:gsupport, t)), rev=true)

        ninstance_to_sorteditemset[i] = length(_sorteditemsets) > 0 ?
            union(_sorteditemsets) :        # single-item Itemsets are merged together
            Itemset()                       # i-th instance has no itemsets
    end

    verbose && printstyled("Initializing seed FPTree and Header table...\n", color=:green)

    # create an initial fptree
    fptree = FPTree()
    # create and fill an header table, necessary to traverse FPTrees horizontally
    htable = HeaderTable(frequents, fptree; miner=miner)

    verbose && printstyled("Growing seed FPTree...\n", color=:green)

    SoleRules.push!(fptree, ninstance_to_sorteditemset, _ninstances, miner; htable=htable)

    verbose && printstyled("Mining longer frequent itemsets...\n", color=:green)

    println("INITIAL FPTREE")
    println(fptree)

    # `fpgrowth` recursive logic piece
    function _fpgrowth_kernel(
        fptree::FPTree,
        htable::HeaderTable,
        miner::Miner,
        leftout_itemset::Itemset
    )
        # if `fptree` contains only one path (hence, it can be considered a linked list),
        # then combine all the Itemsets collected from previous step with the remained ones.
        if islist(fptree)
            # representative FPTree node, to retrieve global and local support
            leader_fpnode = children(fptree)[1]

            # all the survived items, from which compose new frequent itemsets
            survivor_itemset = retrieveall(fptree)

            _ninstances = ninstances(dataset(miner))

            verbose &&
                printstyled("Merging $(leftout_itemset |> length) leftout items with a " *
                "single-list FPTree of length $(survivor_itemset |> length)\n", color=:blue)

            for combo in combine(items(survivor_itemset), items(leftout_itemset))
                globalmemo!(
                    miner, (:gsupport, combo), (leader_fpnode |> count) / _ninstances)

                # single-itemset case is already handled by the first pass over the dataset
                if length(combo) > 1
                    push!(freqitems(miner), combo)
                end
            end

        else
            for item in reverse(htable)
                # a (conditional) pattern base is a vector of "enhanced" itemsets, that is,
                # itemsets whose items are paired with a contributors vector.
                _patternbase = patternbase(item, htable, miner)

                # a new FPTree is projected, via the conditional pattern base retrieved
                # starting from `fptree` nodes whose content is exactly `item`.
                # A projection, is, essentialy, a slice/subset of the dataset
                # rapresented by an FPTree.
                # Also, the header table associated with the projection is returned.
                conditional_fptree, conditional_htable =
                    projection(_patternbase, miner)

                # if the new fptree is not empty, call this recursively,
                # considering `item` as a leftout item.
                if length(children(conditional_fptree)) > 0
                    _fpgrowth_kernel(conditional_fptree, conditional_htable, miner,
                        union(leftout_itemset, Itemset(item)))
                end
            end
        end
    end

    # call main logic
    _fpgrowth_kernel(fptree, htable, miner, Itemset())
end

"""
    initpowerups(::typeof(fpgrowth), ::AbstractDataset)::Powerup

Powerups suite for FP-Growth algorithm.

When initializing a [`Miner`](@ref) with [`fpgrowth`](@ref) algorithm, this defines
how miner's `powerup` field is filled to optimize the mining.

See also [`haspowerup`](@ref), [`powerup`](@ref).
"""
function initpowerups(::typeof(fpgrowth), ::AbstractDataset)::Powerup
    return Powerup([:contributors => Contributors([])])
end
