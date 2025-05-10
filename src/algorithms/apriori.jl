"""
    combine_items(itemsets::AbstractVector{<:Itemset}, newlength::Integer)

Return a generator which combines [`Itemset`](@ref)s from `itemsets` into new itemsets of
length `newlength` by taking all combinations of two itemsets and joining them.

See also [`Itemset`](@ref).
"""
function combine_items(itemsets::AbstractVector{<:Itemset}, newlength::Integer)
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
function combine_items(variable::AbstractVector{<:Item}, fixed::AbstractVector{<:Item})
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
    candidates::AbstractVector{Itemset{I}},
    frequents::AbstractVector{Itemset{I}},
    k::Integer
) where {I<:Item}
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

    filter!(candidates, miner)  # apply filtering policies
    while !isempty(candidates)
        frequents = Itemset{_itemtype}[]
        frequents_lock = ReentrantLock()

        # get the frequent itemsets from the first candidates set
        Threads.@threads for candidate in candidates
            any(
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
        candidates = sort.(grow_prune(candidates, frequents, k) |> collect) |> unique

        verbose && printstyled("Starting new computational loop with " *
            "$(length(candidates)) candidates (of length $(k))...\n", color=:green)

        filter!(candidates, miner)  # apply filtering policies
    end
end

"""
    anchored_apriori(miner::AbstractMiner, X::MineableData; kwargs...)::Nothing

Anchored version of [`apriori`](@ref) algorithm, that is exactly `apriori` but assuring
that `miner` possess atleast [`isanchored_itemset`](@ref) policy, with `ignoreuntillength`
parameter set to 1 or higher.

TODO - insert a reference to TIME2025 article.

See also [`AbstractMiner`](@ref), [`apriori`](@ref), [`isanchored_itemset`](@ref),
[`MineableData`](@ref).
"""
function anchored_apriori(miner::AbstractMiner, X::MineableData; kwargs...)::Nothing
    try
        isanchored_miner(miner)
    catch
        rethrow()
    end

    # apriori is going to express the anchored semantics, thus, is safe to call it
    apriori(miner, X; kwargs...)
end
