"""
    apriori(; fulldump::Bool=true, verbose::Bool=true)::Function

Wrapper function for the Apriori algorithm over a modal dataset.
Returns a `function f(miner::ARuleMiner, X::AbstractDataset)::Nothing` that runs the main
Apriori algorithm logic, [as described here](https://ceur-ws.org/Vol-3284/492.pdf).
"""
function apriori(;
    fulldump::Bool=true,   # also keeps track of non-frequent patterns (testing purposes)
    verbose::Bool=true,
)::Function

    # modal apriori main logic, as in https://ceur-ws.org/Vol-3284/492.pdf
    function _apriori(miner::ARuleMiner, X::AbstractDataset)::Nothing
        @assert SoleRules.gsupport in reduce(vcat, item_meas(miner)) "Apriori requires " *
        "global support (gsupport) as meaningfulness measure in order to " *
        "work. Please, add a tuple (gsupport, local support threshold, " *
        "global support threshold) to miner.item_constrained_measures field.\n" *
        "Local support is needed too, but it is already considered in the global case."

        # candidates of length 1 are all the letters in our items
        candidates = Itemset.(items(miner))

        while !isempty(candidates)
            # get the frequent itemsets from the first candidates set;
            # note that meaningfulness measure should leverage memoization when
            # miner is given.
            frequents = [candidate
                for (gmeas_algo, lthreshold, gthreshold) in item_meas(miner)
                for candidate in candidates
                # specifically, global support also calls local support and updates
                # contributors
                if gmeas_algo(candidate, X, lthreshold, miner=miner) >= gthreshold
            ]

            # sort!(frequents, by=t -> globalmemo(miner, (:gsupport, t)), rev=true)

            # save frequent itemsets inside the miner machine
            push!(freqitems(miner), frequents...)

            k = (candidates |> first |> length) + 1
            candidates = prune(candidates, frequents, k) |> collect |> unique

            if verbose
                println("Starting new computational loop with $(length(candidates)) " *
                        "candidates.")
            end
        end
    end

    return _apriori
end
