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
    fpgrowth algorithm, via building [`ConditionalPatternBase`](@ref)s iteratively while
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
    content!(fptree::FPTree, item::Item)

Setter for `fptree`'s content (the wrapped item).

See also [`content`](@ref), [`FPTree`](@ref).
"""
content!(fptree::FPTree, item::Item) = fptree.content = item

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

    function _retrieve(fptree::FPTree)::Itemset
        # TODO - I am forced to parametrize Itemset, but here I cannot be dependant from
        # a Miner object! I don't know which items are being manipulated.
        retrieved = [_retrieve(child) for child in children(fptree)]

        retrieved = length(retrieved) > 0 ?
            union(retrieved...) :
            Itemset{Item}()

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
        miner::Union{Nothing,AbstractMiner}=nothing
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
    function checksanity!(htable::HeaderTable, miner::AbstractMiner)::Bool

Check if `htable` internal state is correct, that is, its `items` are sorted decreasingly
by global support.
If `items` are already sorted, return `true`; otherwise, sort them and return `false`.

See also [`AbstractMiner`](@ref), [`gsupport`](@ref), [`HeaderTable`](@ref),
[`items`](@ref).
"""
function checksanity!(htable::HeaderTable, miner::AbstractMiner)::Bool
    _issorted = issorted(
        items(htable),
        by=t -> miningstate(miner, :current_items_frequency)[t],
        rev=true
    )

    # force sorting if needed
    if !_issorted
        sort!(items(htable), by=t -> miningstate(
            miner, :current_items_frequency)[t],
            rev=true
        )
    end

    return _issorted
end

"""
    Base.reverse(htable::HeaderTable)

Iterator on `htable` wrapped [`Item`](@ref)s, in reverse order.

See also [`HeaderTable`](@ref), [`Item`](@ref).
"""
Base.reverse(htable::HeaderTable) = reverse(items(htable))

doc_fptree_grow = """
    TODO - rewrite this docstring

    function grow!(
        fptree::FPTree,
        itemset::Itemset,
        ith_instance::Int64,
        miner::AbstractMiner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    function grow!(
        fptree::FPTree,
        itemset::EnhancedItemset,
        ith_instance::Int64,
        miner::AbstractMiner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

    grow!(
        fptree::FPTree,
        enhanceditemsets::Union{ConditionalPatternBase,Vector{Itemset}},
        miner::AbstractMiner;
        htable::Union{Nothing,HeaderTable}=nothing
    )

Push one or more [`Itemset`](@ref)s/[`EnhancedItemset`](@ref) to an [`FPTree`](@ref).
If an [`HeaderTable`](@ref) is provided, it is leveraged to develop internal links.

See also [`EnhancedItemset`](@ref), [`FPTree`](@ref), [`gsupport`](@ref),
[`HeaderTable`](@ref), [`Itemset`](@ref).
"""

"""$(doc_fptree_grow)"""
function grow!(
    fptree::FPTree,
    enhanceditemset::EnhancedItemset;
    miner::Union{Nothing,AbstractMiner},
    kwargs...
)
    _itemset = itemset(enhanceditemset)

    # base case
    if length(_itemset) == 0
        return
    end

    # sorting must be guaranteed: remember an FPTree essentially is a prefix tree
    sort!(_itemset, by=t -> miningstate(
        miner, :current_items_frequency)[t], rev=true)

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
        grow!(
            subfptree, (_itemset[2:end], _count) |> EnhancedItemset; miner=miner, kwargs...)
    else
        # here we want to create a new children FPTree, and set this as its parent;
        # note that we don't want to update count and contributors since we already
        # copy it from the enhanced itemset.
        subfptree = FPTree(enhanceditemset)
        children!(fptree, subfptree)
    end
end

"""$(doc_fptree_grow)"""
function grow!(
    fptree::FPTree,
    itemset::IT;
    miner::Union{Nothing,AbstractMiner},
    kwargs...
) where {IT<:Itemset}
    grow!(fptree, convert(EnhancedItemset, itemset, 1); miner=miner, kwargs...)
end

"""$(doc_fptree_grow)"""
function grow!(
    fptree::FPTree,
    collection::Union{ConditionalPatternBase,Vector{IT}};
    miner::Union{Nothing,AbstractMiner},
    kwargs...
) where {IT<:Itemset}
    map(element -> grow!(fptree, element; miner=miner, kwargs...), collection)
end
