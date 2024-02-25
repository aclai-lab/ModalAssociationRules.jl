"""
    apriori(miner::Miner, X::AbstractDataset; verbose::Bool=true)::Nothing

Apriori algorithm, [as described here](https://ceur-ws.org/Vol-3284/492.pdf).

See also [`Miner`](@ref), [`SoleBase.AbstractDataset`](@ref).
"""
function apriori(miner::Miner, X::AbstractDataset; verbose::Bool=false)::Nothing
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
        candidates = grow_prune(candidates, frequents, k) |> collect |> unique


        verbose && printstyled("Starting new computational loop with " *
        "$(length(candidates)) candidates...\n", color=:green)
    end
end
