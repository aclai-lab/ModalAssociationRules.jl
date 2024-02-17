############################################################################################
#### Itemsets ##############################################################################
############################################################################################

"""
    combine(itemsets::Vector{<:Itemset}, newlength::Integer)

Return a generator which combines [`Itemset`](@ref)s from `itemsets` into new itemsets of
length `newlength` by taking all combinations of two itemsets and joining them.

See also [`Itemset`](@ref).
"""
function combine(itemsets::Vector{<:Itemset}, newlength::Integer)
    return Iterators.filter(
        combo -> length(combo) == newlength,
        Iterators.map(
            combo -> union(combo[1], combo[2]),
            combinations(itemsets, 2)
        )
    )
end

"""
    combine(variable::Vector{<:Item}, fixed::Vector{<:Item})

Return a generator which iterates the combinations of [`Item`](@ref)s in `variable` and
prepend them to `fixed` vector.

See also [`Item`](@ref).
"""
function combine(variable::Vector{<:Item}, fixed::Vector{<:Item})
    return (Itemset(vcat(combo, fixed)) for combo in combinations(variable))
end

"""
    function prune(candidates::Vector{Itemset}, frequents::Vector{Itemset}, k::Integer)

Return a generator, which yields only the `candidates` for which every (k-1)-length subset
is in `frequents`.

See also [`Itemset`](@ref).
"""
function prune(candidates::Vector{Itemset}, frequents::Vector{Itemset}, k::Integer)
    # if the frequents set does not contain the subset of a certain candidate,
    # that candidate is pruned out.
    return Iterators.filter(
        # the iterator yields only itemsets for which every combo is in frequents
        itemset -> all(combo ->
            combo in frequents, combinations(itemset, k-1)),
        combine(candidates, k)
    )
end

# TODO: write docstring
# TODO: make this prune!, avoiding returning candidates
function prune(
    candidates::Vector{Itemset},
    frequents::Vector{Itemset},
    k::Integer,
    bouncer::DefaultDict{Itemset,WorldsMask},
    lthreshold::Int64,
    gthreshold::Int64
)
    candidates = prune(candidates, frequents, k) |> collect |> unique

    # calling mirages! is proper of the modal case scenario
    # if !isempty(candidates)
    #    mirages!(candidates, bouncer, lthreshold, gthreshold)
    # end

    return candidates
end

############################################################################################
#### Association rules #####################################################################
############################################################################################

"""
    arules_generator(itemsets::Vector{Itemset}, miner::ARuleMiner)

Generates association rules from the given collection of `itemsets` and `miner`.
Iterates through the powerset of each itemset to generate meaningful [`ARule`](@ref).

To establish the meaningfulness of each association rule, check if it meets the global
constraints specified in `rule_meas(miner)`, and yields the rule if so.

See also [`ARule`](@ref), [`ARuleMiner`](@ref), [`Itemset`](@ref), [`rule_meas`](@ref).
"""
@resumable function arules_generator(
    itemsets::Vector{Itemset},
    miner::ARuleMiner
)
    for itemset in itemsets
        subsets = powerset(itemset)
        for subset in subsets
            _antecedent = subset
            _consequent = symdiff(itemset, subset)

            if length(_antecedent) == 0 || length(_consequent) == 0
                continue
            end

            interesting = true
            currentrule = ARule((_antecedent, _consequent))

            for meas in rule_meas(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, dataset(miner), lthreshold, miner=miner)

                if gmeas_result < gthreshold
                    interesting = false
                    break
                end
            end

            if interesting
                push!(arules(miner), currentrule)
                @yield currentrule
            end
        end
    end
end
