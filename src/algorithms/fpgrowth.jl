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
            _ninstance_toitemsets_sorted[i] = sort([
                itemset
                for itemset in frequents
                if getlocalmemo(miner, (:lsupport, itemset, i)) > lsupport_threshold
            ], by=t -> getglobalmemo(miner, (:gsupport, t)), rev=true)
        end


    end

    return _fpgrowth
end
