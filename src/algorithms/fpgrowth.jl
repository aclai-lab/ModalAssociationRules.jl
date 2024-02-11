############################################################################################
#### Data structures #######################################################################
############################################################################################

"""
Fundamental data structure used in FP-Growth algorithm.
Essentialy, an [`FPTree`](@ref) is a prefix tree where a root-leaf path represent an [`Itemset`](@ref).

Consider the [`Itemset`](@ref)s sorted by [`gsupport`](@ref) of their items.
An [`FPTree`](@ref) is such that the common [`Item`](@ref)s-prefix shared by different
[`Itemset`](@ref)s is not stored multiple times.

This implementation generalizes the propositional logic case scenario to modal logic;
given two [`Itemset`](@ref)s sharing a [`Item`](@ref) prefix, they share the same path only
if the worlds in which the they are true is the same.
"""
mutable struct FPTree
    content::Union{Nothing,Item}    # the Item contained in this node (nothing if root)

    parent::Union{Nothing,FPTree}   # parent node
    const children::Vector{FPTree}  # children nodes

    count::Int64                    # number of equal Items this node represents

    const contributors::UInt64      # hash representing the worlds contributing to this node
    linkage::Union{Nothing,FPTree}  # link to another FPTree root

    # empty constructor
    function FPTree()
        new(nothing, nothing, FPTree[], 0, UInt64(0), nothing)
    end

    # choose root or new subtree constructor
    function FPTree(itemset::Itemset, miner::ARuleMiner; isroot=true)
        FPTree(itemset, miner, Val(isroot)) # singleton design pattern
    end

    # root constructor
    function FPTree(itemset::Itemset, miner::ARuleMiner, ::Val{true})
        fptree = FPTree()

        children!(fptree, FPTree(itemset, miner; isroot=false))
        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end

    # internal tree constructor
    function FPTree(itemset::Itemset, miner::ARuleMiner, ::Val{false})
        firstitem = itemset[1]
        contribhash = getcontributors(firstitem, miner)

        fptree = length(itemset) == 1 ?
            new(firstitem, nothing, FPTree[], 1, contribhash, nothing) :
            new(firstitem, nothing, FPTree[FPTree(itemset[2:end], miner; isroot=false)],
                1, contribhash, nothing)

        map(child -> parent!(child, fptree), children(fptree))

        return fptree
    end
end

doc_fptree_getters = """
    content(fptree::FPTree)::Union{Nothing,Item}
    parent(fptree::FPTree)::Union{Nothing,FPTree}
    children(fptree::FPTree)::Vector{FPTree}
    count(fptree::FPTree)::Int64
    contributors(fptree::FPTree)::UInt64
    linkage(fptree::FPTree)::Union{Nothing,FPTree}

[`FPTree`](@ref) getters.
"""

doc_fptree_setters = """
    content!(fptree::FPTree)::Union{Nothing,Item}
    parent!(fptree::FPTree)::Union{Nothing,FPTree}
    children!(fptree::FPTree)::Vector{FPTree}
    count!(fptree::FPTree)::Int64
    addcount!(fptree::FPTree, deltacount::Int64)
    contributors!(fptree::FPTree)::UInt64
    linkage!(fptree::FPTree)::Union{Nothing,FPTree}

[`FPTree`](@ref) setters.
"""

"""$(doc_fptree_getters)"""
content(fptree::FPTree)::Union{Nothing,Item} = fptree.content
"""$(doc_fptree_getters)"""
parent(fptree::FPTree)::Union{Nothing,FPTree} = fptree.parent
"""$(doc_fptree_getters)"""
children(fptree::FPTree)::Vector{FPTree} = fptree.children

"""$(doc_fptree_getters)"""
count(fptree::FPTree)::Int64 = fptree.count
"""$(doc_fptree_getters)"""
contributors(fptree::FPTree)::UInt64 = fptree.contributors

"""$(doc_fptree_getters)"""
linkage(fptree::FPTree)::Union{Nothing,FPTree} = fptree.linkage

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
addcount!(fptree::FPTree, deltacount::Int64) = fptree.count = fptree.count + deltacount
"""$(doc_fptree_setters)"""
contributors!(fptree::FPTree, contribution::UInt64) = fptree.contributors = contribution

"""
    function follow(fptree::FPTree)::Union{Nothing,FPTree}

Follow `fptree` linkage to (an internal node of) another [`FPTree`](@ref).
"""
function follow(fptree::FPTree)::Union{Nothing,FPTree}
    arrival = linkage(fptree)
    return arrival === nothing ? item : follow(arrival)
end

"""
    function link!(from::FPTree, to::FPTree)

Establish a linkage between two [`FPTree`](@ref)s.
If the starting tree is already linked with something, the already existing linkages are
followed until a new "empty-linked" [`FPTree`](@ref) is found.

See also [`follow`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function link!(from::FPTree, to::FPTree)
    # find the last FPTree by iteratively following the internal link
    if !isnothing(linkage(from))
        from = follow(from)
    end

    from.linkage = to
end

"""
    struct HeaderTable
        items::Vector{Item}
        linkage::Dict{Item,Union{Nothing,FPTree}}
    end

Utility data structure used to fastly access [`FPTree`](@ref) internal nodes.
"""
struct HeaderTable
    items::Vector{Item} # vector of Items, sorted decreasingly by global support
    linkage::Dict{Item,Union{Nothing,FPTree}} # Item -> FPTree internal node association

    function HeaderTable(items::Vector{Item}, fptseed::FPTree)
        # make an empty htable, whose entries are `Item` objects, in `items`
        htable = new(items, Dict{Item,FPTree}([item => nothing for item in items]))

        # iteratively fill htable
        child = children(fptseed)
        while !isempty(child)
            link!(htable, fptseed)
            child = children(child)
        end
    end

    function HeaderTable(itemsets::Vector{Itemset}, fptseed::FPTree)
        return HeaderTable(convert.(Item, itemsets), fptseed)
    end
end

doc_htable_getters = """
    items(htable::HeaderTable)
    linkage(htable::HeaderTable, item::Item)

[`HeaderTable`](@ref) getters.
"""

doc_htable_setters = """
    linkage!(htable::HeaderTable, item::Item, fptree::FPTree)

[`HeaderTable`](@ref) setters.
"""

"""$(doc_htable_getters)"""
items(htable::HeaderTable) = htable.items

"""$(doc_htable_getters)"""
linkage(htable::HeaderTable, item::Item) = htable.linkage[item]

"""$(doc_htable_setters)"""
linkage!(htable::HeaderTable, item::Item, fptree::FPTree) = htable.linkage[item] = fptree

"""
    function follow(htable::HeaderTable, item::Item)::Union{Nothing,FPTree}

Follow `htable` linkage to (an internal node of) a [`FPTree`](@ref).
"""
function follow(htable::HeaderTable, item::Item)::Union{Nothing,FPTree}
    arrival = linkage(htable, item)
    return isnothing(arrival) ? item : follow(arrival, item)
end

"""
    function link!(htable::HeaderTable, fptree::FPTree)

Establish a linkage between the entry in `htable` corresponding to the [`content`](@ref)
of `fptree`.

See also [`content`](@ref), [`FPTree`](@ref), [`HeaderTable`](@ref).
"""
function link!(htable::HeaderTable, fptree::FPTree)
    _content = content(fptree)
    arrival = follow(htable, _content)

    # the content of `fptree` was never seen before by this `htable`
    if linkage(htable, _content) |> isnothing
        linkage!(htable, content, fptree)
    # the arrival FPTree is linked to the new `fptree`
    elseif arrival isa FPTree
        link!(arrival, fptree)
    # invalid option
    else
        error("Error trying to establish a linkage between HeaderTable and an object " *
            "of type $(typeof(arrival)).")
    end
end

"""
    function Base.push!(fptree::FPTree, itemset::Itemset, miner::ARuleMiner)
    function Base.push!(fptree::FPTree, itemsets::Vector{Itemset}, miner::ARuleMiner)

Push one or more [`Itemset`](@ref)s to an [`FPTree`](@ref).
If an [`HeaderTable`](@ref) is provided, it is leveraged to develop internal links.

!!! warning
    To optimally leverage the compression capabilities of [`FPTree`](@ref)s, the
    [`Itemset`](@ref)s provided should be sorted decreasingly by [`gsupport`](@ref).
    By default, to improve performances, this check is not performed inside this method.

See also [`FPTree`](@ref), [`gsupport`](@ref), [`HeaderTable`](@ref), [`Itemset`](@ref).
"""
function Base.push!(
    fptree::FPTree,
    itemset::Itemset,
    miner::ARuleMiner;
    htable::Union{Nothing,HeaderTable}=nothing
)
    # recursion base case
    if length(itemset) == 0
        return
    end

    item = convert(Item, itemset)
    item_contributors = getcontributors(item, miner)

    # check if a subtree whose content is the first item in `itemset` already exists
    for child in children(fptree)
        if content(child) == item && contributors(child) == item_contributors
            addcount!(fptree, 1)
            push!(child, itemset[2:end], miner)
            return
        end
    end

    # if no subtree exists, create a new one
    subfptree = FPTree(item, item_contributors)
    children!(fptree, subfptree)
    # and stretch the link coming out from `item` in `htable`, to consider the new child
    link!(htable, subfptree)
end
function Base.push!(
    fptree::FPTree,
    itemsets::Vector{Itemset},
    miner::ARuleMiner,
    htable::HeaderTable
)
    # simply call the single itemset case multiple times
    map(item -> push!(fptree, item, miner; htable=htable), itemsets)
end

############################################################################################
#### Main FP-Growth logic ##################################################################
############################################################################################

"""
    fpgrowth(; fulldump::Bool=true, verbose::Bool=true)::Function

Wrapper function for the FP-Growth algorithm over a modal dataset.
Returns a `function f(miner::ARuleMiner, X::AbstractDataset)::Nothing` that runs the main
FP-Growth algorithm logic, [as described here](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf).
"""
function fpgrowth(;
    fulldump::Bool=true,   # mostly for testing purposes, also keeps track of non-frequent patterns
    verbose::Bool=true,
)::Function

    function _fpgrowth_preamble(miner::ARuleMiner, X::AbstractDataset)::Nothing
        @assert SoleRules.gsupport in reduce(vcat, item_meas(miner)) "FP-Growth requires "*
            "global support (SoleRules.gsupport) as meaningfulness measure in order to " *
            "work. Please, add a tuple (SoleRules.gsupport, local support threshold, " *
            "global support threshold) to miner.item_constrained_measures field."

        # retrieve local support threshold, as this is necessary later to filter which
        # frequent items are meaningful on each instance.
        lsupport_threshold = getlocalthreshold(miner, SoleRules.gsupport)

        # get the frequent itemsets from the first candidates set;
        # note that meaningfulness measure should leverage memoization when miner is given!
        frequents = [candidate
            for (gmeas_algo, lthreshold, gthreshold) in item_meas(miner)
            for candidate in Itemset.(alphabet(miner))
            if gmeas_algo(candidate, X, lthreshold, miner=miner) >= gthreshold
        ]

        # associate each instance in the dataset with its frequent itemsets
        _ninstances = ninstances(X)
        ninstance_toitemsets_sorted = fill(Vector{Itemset}, _ninstances)

        # for each instance, sort its frequent itemsets by global support
        for i in 1:_ninstances
            ninstance_toitemsets_sorted[i] = sort([
                itemset
                for itemset in frequents
                if getlocalmemo(miner, (:lsupport, itemset, i)) > lsupport_threshold
            ], by=t -> getglobalmemo(miner, (:gsupport, t)), rev=true)
        end

        # create an initial fptree
        fptree = FPTree()
        # create and fill an header table, necessary to traverse FPTrees horizontally
        htable = HeaderTable(frequents, fptree)
        push!(fptree, ninstance_toitemsets_sorted, miner)

        # call main logic
        _fpgrowth_kernel(fptree, htable, miner, Itemset())
    end

    function _fpgrowth_kernel(
        fptree::FPTree,
        htable::HeaderTable,
        miner::ARuleMiner,
        pattern::Itemset
    )
        # if fptree only contains a single path, then combine all the possible itemsets
        # if issinglepath(fptree)
        #   pathitems = collectitems(fptree)
        #   map(itemset -> push!(freqitems(miner), itemset),
        #       combinations(Itemset([pattern, pathitems])))
        # else
        #   get the TODO...

    end

    return _fpgrowth_preamble
end
