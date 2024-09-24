"""
    apriori(miner::Miner, X::MineableData; verbose::Bool=true)::Nothing

Apriori algorithm, [as described here](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf) but generalized
to also work with modal logic.

# Arguments

-`miner`: miner containing the extraction parameterization;
- `X`: data from which you want to mine association rules;
- `verbose`: print informations about each iteration.

See also [`Miner`](@ref), [`SoleBase.MineableData`](@ref).
"""
function apriori(miner::Miner, X::MineableData; verbose::Bool=false)::Nothing
    # candidates of length 1 are all the letters in our items
    candidates = Itemset.(items(miner))

    while !isempty(candidates)
        # get the frequent itemsets from the first candidates set;
        # note that meaningfulness measure should leverage memoization when miner is given.
        frequents = [candidate
            for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
            for candidate in candidates
            # specifically, global support also calls local support and updates
            # contributors
            if gmeas_algo(candidate, X, lthreshold, miner) >= gthreshold
        ]

        # save frequent itemsets inside the miner machine
        push!(freqitems(miner), frequents...)
        k = (candidates |> first |> length) + 1
        candidates = grow_prune(candidates, frequents, k) |> collect |> unique

        verbose && printstyled("Starting new computational loop with " *
            "$(length(candidates)) candidates...\n", color=:green)
    end
end
