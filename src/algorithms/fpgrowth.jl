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
    [`EnhancedItemset`](@ref). This is crucial to generate new FPTree during fpgrowth
    algorithm, via building [`ConditionalPatternBase`](@ref) iteratively while avoiding
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
        miner::Union{Nothing,ARuleMiner}=nothing
    )
        # singleton design pattern
        FPTree(itemset, Val(isroot); miner=miner, ninstance=ninstance)
    end

    # root constructor
    function FPTree(
        itemset::Itemset,
        ::Val{true};
        ninstance::Union{Nothing,Int64},
        miner::Union{Nothing,ARuleMiner}=nothing
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
        ninstance::Union{Nothing,Int64},
        miner::Union{Nothing,ARuleMiner}=nothing
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
contributors!(fptree::FPTree, contribution::WorldMask) = fptree.contributors = contribution

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
        "$(fptree |> content |> syntaxstring)")

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

    # Item -> FPTree association
    link::Dict{Item,Union{Nothing,FPTree}}

    function HeaderTable()
        new(Item[], Dict{Item,Union{Nothing,FPTree}}())
    end

    function HeaderTable(items::Vector{<:Item}, fptseed::FPTree)
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

        return htable
    end

    function HeaderTable(itemsets::Vector{<:Itemset}, fptseed::FPTree)
        return HeaderTable(convert.(Item, itemsets), fptseed)
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
    function checksanity!(htable::HeaderTable, miner::ARuleMiner)::Bool

Check if `htable` internal state is correct, that is, its `items` are sorted decreasingly
by global support.
If `items` are already sorted, return `true`; otherwise, sort them and return `false`.

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

    Base.push!(
        fptree::FPTree,
        enhanceditemsets::ConditionalPatternBase,
        miner::ARuleMiner;
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
#     miner::ARuleMiner;
#     htable::HeaderTable
# ) where {T <: Union{Itemset, EnhancedItemset}}

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

    if htable !== nothing && _fptree_content !== nothing && link(fptree) === nothing
        link!(htable, fptree)
    end

    # end of push case
    if length(itemset) == 0
        return
    end

    # retrieve the item to grow the tree;
    # to grow a find pattern tree in the modal case scenario, each item has to be associated
    # with its global counter (always 1!) and its contributors array (see [`WorldMask`]).
    item = first(itemset)
    _contributors = contributors(:lsupport, item, ninstance, miner)

    # check if a subtree whose content is the first item in `itemset` already exists
    _children = children(fptree)
    _children_idx = findfirst(child -> content(child) == item, _children)
    if !isnothing(_children_idx)
        subfptree = _children[_children_idx]
    # if it does not, then create a new children FPTree, and set this as its parent
    else
        subfptree = FPTree(itemset; isroot=false, miner=miner, ninstance=ninstance)
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
) = map(ninstance ->
    push!(fptree, itemsets[ninstance], ninstance, miner; htable=htable), 1:ninstances)

function Base.push!(
    fptree::FPTree,
    enhanceditemset::EnhancedItemset,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing,
)
    # if an header table is provided, and its entry associated with the content of `fptree`
    # is still empty, then perform a linking.
    _fptree_content = content(fptree)

    if htable !== nothing && _fptree_content !== nothing && link(fptree) === nothing
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
        subfptree = _children[_children_idx]
    # if it does not, then create a new children FPTree, and set this as its parent
    else
        subfptree = FPTree(enhanceditemset) # IDEA: see IDEA below
        children!(fptree, subfptree)
    end

    addcount!(subfptree, _count)
    addcontributors!(subfptree, _contributors)

    # IDEA: this brings up a useless overhead, in the case of IDEA up above;
    # when a FPTree is created from an EnhancedItemset, the header table should already
    # do its linkings. Change FPTree(enhanceditemset) to a specific builder method.
    push!(subfptree, enhanceditemset[2:end], miner; htable=htable)
end

Base.push!(
    fptree::FPTree,
    enhanceditemsets::ConditionalPatternBase,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing
) = [push!(fptree, itemset, miner; htable=htable) for itemset in enhanceditemsets]

"""
    Base.reverse(htable::HeaderTable)

Iterator on `htable` wrapped [`Item`](@ref)s, in reverse order.

See also [`HeaderTable`](@ref), [`Item`](@ref).
"""
Base.reverse(htable::HeaderTable) = reverse(items(htable))

"""
    patternbase(item::Item, htable::HeaderTable, miner::ARuleMiner)::ConditionalPatternBase

Retrieve the [`ConditionalPatternBase`](@ref) of `fptree` based on `item`.

The conditional pattern based on a [`FPTree`](@ref) is the set of all the paths from the
tree root to nodes containing `item` (not included). Each of these paths is represented
by an [`EnhancedItemset`](@ref), where each [`Item`](@ref) is associated with a
[`WorldMask`](@ref), given by the minimum of its [`contributors`](@ref) and the ones of
`item`.

The [`EnhancedItemset`](@ref)s in the returned [`ConditionalPatternBase`](@ref) are sorted
decreasingly by [`gsupport`](@ref).

See also [`ARuleMiner`](@ref), [`ConditionalPatternBase`](@ref), [`contributors`](@ref),
[`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`FPTree`](@ref), [`Item`](@ref),
[`Itemset`](@ref), [`WorldMask`](@ref).
"""
function patternbase(
    item::Item,
    htable::HeaderTable,
    miner::ARuleMiner
)::ConditionalPatternBase
    # think a pattern base as a vector of vector of itemsets (a vector of vector of items);
    # the reason why the type is explicited differently here, is that every item must be
    # associated with a specific WorldMask to guarantee correctness.
    _patternbase = ConditionalPatternBase([])

    # follow horizontal references starting from `htable`;
    # for each reference, collect all the ancestors keeping a WorldMask which, at each
    # position, is the minimum between the value in reference's mask and the new node one.
    fptree = link(htable, item)
    fptcount = count(fptree)

    # just the contributors length; new variable to avoid calling this multiple times later
    _fptcontributors_length = length(contributors(fptree))

    while !isnothing(fptree)
        enhanceditemset = EnhancedItemset([])
        ancestorfpt = parent(fptree)
        fptcontributors = contributors(fptree)

        # IDEA: `content(ancestorfpt)` is repeated two times while one variable is enough
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

    # needed to filter out new unfrequent items in the pattern base
    lsupp_integer_threshold = convert(Int64, floor(
        getlocalthreshold(miner, lsupport) * _fptcontributors_length
    ))
    gsupp_integer_threshold = convert(Int64, floor(
        getglobalthreshold(miner, gsupport) * ninstances(dataset(miner))
    ))

    # filter out unfrequent itemsets from a pattern base
    # IDEA: allocating two dictionaries here, instead of a single Dict with `Pair` values,
    # is a waste. Is there a way to obtain the same effect using no immutable structures?
    globalbouncer = DefaultDict{Item,Int64}(0)   # record of respected global thresholds
    localbouncer = DefaultDict{Item,WorldMask}(  # record of respected local thresholds
        ones(Int64, _fptcontributors_length))
    ispromoted = Dict{Item,Bool}([])          # winner items, which will compose the pbase

    # collection phase
    for itemset in _patternbase         # for each Vector{Tuple{Item,Int64,WorldMask}}
        for enhanceditem in itemset     # for each Tuple{Item,Int64,WorldMask} in itemset
            item, _count, _contributors = enhanceditem
            globalbouncer[item] += _count
            localbouncer[item] += _contributors
        end
    end

    # now that dictionaries are filled, establish which are promoted and apply changes
    # in the filtering phase.
    for item in keys(globalbouncer)
        if globalbouncer[item] < gsupp_integer_threshold ||
            Base.count(x ->
               x > gsupp_integer_threshold, localbouncer[item]) < lsupp_integer_threshold
            ispromoted[item] = false
        else
            ispromoted[item] = true
        end
    end

    # filtering phase
    _patternbase = map(itemset -> filter!(t -> ispromoted[first(t)], itemset), _patternbase)

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
Returns a [`MiningAlgo`](@ref) that runs the main
FP-Growth algorithm logic,
[as described here](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf).

See also [`MiningAlgo`](@ref).
"""
function fpgrowth(;
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

        if verbose
            printstyled("Generating frequent itemsets of length 1...\n", color=:green)
        end

        # get the frequent itemsets from the first candidates set;
        # note that meaningfulness measure should leverage memoization when miner is given!
        frequents = [candidate
            for (gmeas_algo, lthreshold, gthreshold) in item_meas(miner)
            for candidate in Itemset.(items(miner))
            if gmeas_algo(candidate, X, lthreshold, miner=miner) >= gthreshold
        ] |> unique

        if verbose
            printstyled("Saving computed metrics into miner...\n", color=:green)
        end

        # update miner with the frequent itemsets just computed
        push!(freqitems(miner), frequents...)

        if verbose
            printstyled("Initializing data structures...\n", color=:green)
        end

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

        if verbose
            printstyled("Mining longer frequent itemsets...\n", color=:green)
        end

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

            if verbose
                printstyled("Merging $(leftout_items |> length) leftout items with " *
                "a single-list FPTree of length $(survivor_items |> length)\n", color=:blue)
            end

            # we know that all the combinations of `survivor_items` are frequent with
            # `leftout_items`, but we need to save (inside miner) the exact local support
            # and global support for each new itemset: those measures are computed below.
            _n_worlds = contributors(fptree) |> length
            _n_instances = dataset(miner) |> ninstances

            for combo in combine(survivor_items, leftout_items) |> collect
                _supp_mask = findmin([
                    sum([
                        contributors(:lsupport, itemset, i, miner)
                        for i in 1:ninstances(dataset(miner))
                    ])
                    for itemset in combo
                ])

                # updating local supports
                map(i -> localmemo!(miner, (:lsupport, combo, i), _supp_mask[i]),
                    1:ninstances(dataset(miner)))

                # updating global support
                #TODO:
                globalmemo!(miner, (:gsupport, combo), count(... > g integer threshold))

                push!(freqitems(miner), combo)
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
                    projection(_patternbase; miner=miner)

                # if the new fptree is not empty, call this recursively,
                # considering `item` as a leftout item.
                if length(children(conditional_fptree)) > 0
                    _fpgrowth_kernel(conditional_fptree, conditional_htable, miner,
                        vcat(leftout_items, item))
                end
            end
        end
    end

    return _fpgrowth_preamble
end
