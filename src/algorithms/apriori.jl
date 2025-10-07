"""
    combine_items(itemsets::AbstractVector{<:Itemset}, newlength::Integer)

Return a generator which combines [`Itemset`](@ref)s from `itemsets` into new itemsets of
length `newlength` by taking all combinations of two itemsets and joining them.

See also [`Itemset`](@ref).
"""
function combine_items(
    itemsets::AbstractVector{IT},
    newlength::Integer
) where {IT<:AbstractItemset}

    return Iterators.filter(
        combo -> length(combo) == newlength,
        Iterators.map(
            combo -> union(combo[1], combo[2]),
            combinations(itemsets, 2)
        )
    )
end

"""
    combine_items(variable::AbstractVector{<:Item}, fixed::AbstractVector{<:Item})

Return a generator of [`Itemset`](@ref), which iterates the combinations of [`Item`](@ref)s
in `variable` and prepend them to `fixed` vector.

See also [`Item`](@ref), [`Itemset`](@ref).
"""
function combine_items(
    variable::AbstractVector{I},
    fixed::AbstractVector{I}
) where {I<:Item}
    # TODO - this may be deprecated
    return (Itemset(union(combo, fixed)) for combo in combinations(variable))
end

"""
    grow_prune(
        candidates::AbstractVector{Itemset},
        frequents::AbstractVector{Itemset},
        k::Integer
    )

Return a generator, which yields only the `candidates` for which every (k-1)-length subset
is in `frequents`.

See also [`Itemset`](@ref).
"""
function grow_prune(
    candidates::AbstractVector{IT},
    frequents::AbstractVector{IT},
    k::Integer
) where {IT<:AbstractItemset}
    # if the frequents set does not contain the subset of a certain candidate,
    # that candidate is pruned out.
    return Iterators.filter(
        # the iterator yields only itemsets for which every combo is in frequents;
        # note: why first(combo)? Because combinations(itemset, k-1) returns vectors,
        # each one wrapping one Itemset, but we just need that exact itemset.
        itemset -> all(
                combo -> Itemset{I}(combo) in frequents, combinations(itemset, k-1)),
        combine_items(candidates, k) |> unique
    )
end

"""
    apriori(miner::Miner; verbose::Bool=true)::Nothing

Apriori algorithm, [as described here](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf)
but generalized to also work with modal logic.

# Arguments
- `miner::M`: miner containing the data and the extraction parameterization;
- `prune_strategy::Function=grow_prune`: strategy to prune candidates between one iteration
and the successive;
- `verbose::Bool=false`: print informations about each iteration.

See also [`grow_prune`](@ref), [`Miner`](@ref), [`MineableData`](@ref).
"""
function apriori(
    miner::M;
    prune_strategy::Function=grow_prune,
    verbose::Bool=false
)::M where {M<:AbstractMiner}
    _itemtype = itemtype(miner)
    X = data(miner)

    # candidates of length 1 are all the letters in our items
    # TODO: this should not assume UInt64 precision! use "; prec=precision(miner)"
    candidates = itemsetpopulation(miner)
    # candidates = Itemset{_itemtype}.(items(miner))

    # filter!(candidates, miner)  # apply filtering policies
    # TODO policies are disabled while replacing the old Itemset type with the new one

    while !isempty(candidates)
        frequents = itemsettype(miner)[]
        frequents_lock = ReentrantLock()

        # get the frequent itemsets from the first candidates set
        Threads.@threads for candidate in candidates
            all(
                gmeas_algo(candidate, X, lthreshold, miner) >= gthreshold
                for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
            ) && lock(frequents_lock) do

                push!(frequents, candidate)
                push!(freqitems(miner), candidate)
            end
        end

        # retrieve the new generation of candidates by doing some combinatorics trick;
        # we do not want duplicates ([p,q,r] and [q,r,p] are considered duplicates).
        k = (candidates |> first |> length) + 1

        println(prune_strategy(candidates, frequents, k) |> collect)

        candidates = sort.(prune_strategy(candidates, frequents, k) |> collect) |> unique

        verbose && printstyled("Starting new computational loop with " *
            "$(length(candidates)) candidates (of length $(k))...\n", color=:green)

        # TODO: policies are disabled while replacing the old Itemset type with the new one
        # filter!(candidates, miner)  # apply filtering policies
    end

    return miner
end
