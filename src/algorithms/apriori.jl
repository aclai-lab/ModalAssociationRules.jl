"""
    combineitems(itemsets::AbstractVector{<:Itemset}, newlength::Integer)

Return a generator which combines [`Itemset`](@ref)s from `itemsets` into new itemsets of
length `newlength` by taking all combinations of two itemsets and joining them.

See also [`Itemset`](@ref).
"""
function combineitems(
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
    combineitems(variable::AbstractVector{<:Item}, fixed::AbstractVector{<:Item})

Return a generator of [`Itemset`](@ref), which iterates the combinations of [`Item`](@ref)s
in `variable` and prepend them to `fixed` vector.

See also [`Item`](@ref), [`Itemset`](@ref).
"""
function combineitems(
    variable::AbstractVector{I},
    fixed::AbstractVector{I}
) where {I<:Item}
    # TODO - this may be deprecated
    return (Itemset(union(combo, fixed)) for combo in combinations(variable))
end

"""
    growprune(
        candidates::AbstractVector{Itemset},
        frequents::AbstractVector{Itemset},
        k::Integer
    )

Return a generator, which yields only the `candidates` for which every (k-1)-length subset
is in `frequents`.

See also [`Itemset`](@ref).
"""
function growprune(
    candidates::AbstractVector{IT},
    frequents::AbstractSet{Itemset},
    k::Integer,
    miner::AbstractMiner
) where {IT<:AbstractItemset}
    # if the frequents set does not contain the subset of a certain candidate,
    # that candidate is pruned out;
    #
    # * TODO this method would probably a lot faster in the case where the computation of
    # combinations is performed directly on the bit masks; unfortunately, it is quite
    # tricky to implement since we do not assume to be working with just one mask
    # (e.g., one UInt64) but many bits concatenated in different words.

    return Iterators.filter(
        # the iterator yields only itemsets for which every combo is in frequents;
        # note: why first(combo)? Because combinations(itemset, k-1) returns vectors,
        # each one wrapping one Itemset, but we just need that exact itemset.
        itemset -> all(
            combo -> combo in frequents,
            combinations(applymask(itemset, miner), k-1) # *
        ),
        combineitems(candidates, k) |> unique # I think this could simply be a collect
    )
end

"""
    apriori(miner::Miner; verbose::Bool=true)::Nothing

Apriori algorithm, [as described here](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf)
but generalized to also work with modal logic.

# Arguments
- `miner::M`: miner containing the data and the extraction parameterization;
- `prunestrategy::Function=growprune`: strategy to prune candidates between one iteration
and the successive;
- `verbose::Bool=false`: print informations about each iteration.

See also [`growprune`](@ref), [`Miner`](@ref), [`MineableData`](@ref).
"""
function apriori(
    miner::M;
    prunestrategy::Function=growprune,
    verbose::Bool=false
)::M where {M<:AbstractMiner}
    X = data(miner)

    # TODO: this should not assume UInt64 precision! use "; prec=precision(miner)"
    candidates = itemsetpopulation(miner)

    # filter!(candidates, miner)  # apply filtering policies
    # TODO policies are disabled while replacing the old Itemset type with the new one

    # this is a buffer containing ONLY the frequent itemsets of length k-1
    # TODO: probably, is better to use some other Set definition
    _previousfreq = Set{Itemset}()

    while !isempty(candidates)
        frequents_lock = ReentrantLock()

        # get the frequent itemsets from the first candidates set
        Threads.@threads for candidate in candidates
            # check if global support and other custom global measures are high enough
            all(
                gmeas_algo(candidate, X, lthreshold, miner) >= gthreshold
                for (gmeas_algo, lthreshold, gthreshold) in itemsetmeasures(miner)
            ) && lock(frequents_lock) do
                # we store the new frequent itemset within the miner object
                push!(freqitems(miner), candidate)

                # we also keep track of it on the temporary buffer, which is needed later
                # to prune out the candidates of length k for which no k-1 subset appears
                # here
                push!(_previousfreq, applymask(candidate, miner))
            end
        end

        # retrieve the new generation of candidates by doing some combinatorics trick;
        # we do not want duplicates ([p,q,r] and [q,r,p] are considered duplicates).
        k = (candidates |> first |> length) + 1

        candidates = prunestrategy(candidates, _previousfreq, k, miner) |> collect
        empty!(_previousfreq)

        verbose && printstyled("Starting new computational loop with " *
            "$(length(candidates)) candidates (of length $(k))...\n", color=:green)

        # TODO: policies are disabled while replacing the old Itemset type with the new one
        # filter!(candidates, miner)  # apply filtering policies
    end

    return miner
end
