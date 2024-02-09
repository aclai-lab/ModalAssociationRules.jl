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
struct FPTree
    content::Union{Nothing,Item}    # the Item contained in this node (nothing if root)
    children::Vector{FPTree}        # children nodes
    contributors::UInt64            # hash representing the worlds contributing to this node

    function FPTree()
        new(nothing, FPTree[], 0)
    end

    function FPTree(itemset::Itemset; isroot=false)
        FPTree(itemset, Val(isroot))
    end

    # root constructor
    function FPTree(itemset::Itemset, ::Val{true})

    end

    function FPTree(itemset::Itemset, ::Val{false})

    end
end

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

    function _fpgrowth(miner::ARuleMiner, X::AbstractDataset)::Nothing
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
            if gmeas_algo(item, X, lthreshold, miner=miner) >= gthreshold
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


    end

    return _fpgrowth
end
