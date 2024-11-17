"""
    apriori(miner::Miner, X::MineableData; verbose::Bool=true)::Nothing

Apriori algorithm, [as described here](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf) but generalized
to also work with modal logic.

# Arguments

- `miner`: miner containing the extraction parameterization;
- `X`: data from which you want to mine association rules;
- `verbose`: print informations about each iteration.

See also [`Miner`](@ref), [`SoleBase.MineableData`](@ref).
"""
function apriori(
    miner::AbstractMiner,
    X::MineableData;
    verbose::Bool=false
)::Nothing
    _itemtype = itemtype(miner)

    # candidates of length 1 are all the letters in our items
    candidates = Itemset{_itemtype}.(items(miner))

    while !isempty(candidates)
        # get the frequent itemsets from the first candidates set;
        # note that meaningfulness measure should leverage memoization when miner is given.
        frequents = [candidate
            for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
            for candidate in candidates
            # specifically, global support also calls local support and updates
            # contributors
            if gmeas_algo(candidate, X, lthreshold, miner) >= gthreshold
        ] |> Vector{Itemset{_itemtype}}

        # save frequent itemsets inside the miner machine
        push!(freqitems(miner), frequents...)

        # retrieve the new generation of candidates by doing some combinatorics trick;
        # we do not want duplicates ([p,q,r] and [q,r,p] are considered duplicates).
        k = (candidates |> first |> length) + 1
        candidates = sort.(grow_prune(candidates, frequents, k) |> collect) |> unique

        verbose && printstyled("Starting new computational loop with " *
            "$(length(candidates)) candidates...\n", color=:green)
    end
end
