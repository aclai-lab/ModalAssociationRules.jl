############################################################################################
#### Itemsets ##############################################################################
############################################################################################

"""
    combine_items(itemsets::Vector{<:Itemset}, newlength::Integer)

Return a generator which combines [`Itemset`](@ref)s from `itemsets` into new itemsets of
length `newlength` by taking all combinations of two itemsets and joining them.

See also [`Itemset`](@ref).
"""
function combine_items(itemsets::Vector{<:Itemset}, newlength::Integer)
    return Iterators.filter(
        combo -> length(combo) == newlength,
        Iterators.map(
            combo -> union(combo[1], combo[2]),
            combinations(itemsets, 2)
        )
    )
end

"""
    combine_items(variable::Vector{<:Item}, fixed::Vector{<:Item})

Return a generator of [`Itemset`](@ref), which iterates the combinations of [`Item`](@ref)s
in `variable` and prepend them to `fixed` vector.

See also [`Item`](@ref), [`Itemset`](@ref).
"""
function combine_items(variable::Vector{<:Item}, fixed::Vector{<:Item})
    return (Itemset(union(combo, fixed)) for combo in combinations(variable))
end

"""
    grow_prune(candidates::Vector{Itemset}, frequents::Vector{Itemset}, k::Integer)

Return a generator, which yields only the `candidates` for which every (k-1)-length subset
is in `frequents`.

See also [`Itemset`](@ref).
"""
function grow_prune(candidates::Vector{Itemset}, frequents::Vector{Itemset}, k::Integer)
    # if the frequents set does not contain the subset of a certain candidate,
    # that candidate is pruned out.
    return Iterators.filter(
            # the iterator yields only itemsets for which every combo is in frequents;
            # note: why first(combo)? Because combinations(itemset, k-1) returns vectors,
            # each one wrapping one Itemset, but we just need that exact itemset.
            itemset -> all(
                combo -> Itemset(combo) in frequents, combinations(itemset, k-1)),
                combine_items(candidates, k)
        )
end

############################################################################################
#### Association rules #####################################################################
############################################################################################

"""
    function anchor_rulecheck(rule::ARule)::Bool

Return true if the given [`ARule`](@ref) contains a propositional anchor, that is,
atleast one [`Item`](@ref) in its [`antecedent`](@ref) is a propositional letter.

See [`antecedent`](@ref), [`ARule`](@ref), [`generaterules`](@ref), [`Item`](@ref),
[`Miner`](@ref).
"""
function anchor_rulecheck(rule::ARule)::Bool
    # not all items in the antecedent are modal
    return !all(it -> it isa SyntaxBranch && it |> token |> ismodal, antecedent(rule))
end

"""
    function non_selfabsorbed_rulecheck(rule::ARule)::Bool

Return true if the given [`ARule`](@ref) is not self-absorbing, that is,
for each [`Item`](@ref) in its [`antecedent`](@ref) wrapping a variable `V`,
the other items in the antecedent does not refer to `V`, and
every item in the [`consequent`](@ref) does not refer to `V` too.

See [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`generaterules`](@ref),
[`Item`](@ref), [`Miner`](@ref).
"""
function non_selfabsorbed_rulecheck(rule::ARule)::Bool
    # TODO: this could be moved to SoleData
    function _extract_variable(item::Item)::Int64
        # extract the Atom wrapped inside a SyntaxTree;
        # if `item` is already an Atom, do nothing.
        item = item isa Atom ? item : item.children |> first
        return item.value.metacond.feature.i_variable
    end

    return all(
        # for each antecedent item
        ant_it ->
            # no other items in antecedent share the same variable
            count(
                _ant_it -> _extract_variable(ant_it) == _extract_variable(_ant_it),
                antecedent(rule)
            ) == 1 &&
            # every consequent item does not share the same variable
            all(
                cons_it -> _extract_variable(ant_it) != _extract_variable(cons_it),
                consequent(rule)
            ),
        antecedent(rule)
    )
end

"""
    generaterules(itemsets::Vector{Itemset}, miner::Miner)

Raw subroutine of [`generaterules!(miner::Miner; kwargs...)`](@ref).

Generates [`ARule`](@ref) from the given collection of `itemsets` and `miner`.

The strategy followed is
[described here](https://rakesh.agrawal-family.com/papers/sigmod93assoc.pdf)
at section 2.2.

To establish the meaningfulness of each association rule, check if it meets the global
constraints specified in `rulemeasures(miner)`, and yields the rule if so.

See also [`ARule`](@ref), [`Miner`](@ref), [`Itemset`](@ref), [`rulemeasures`](@ref).
"""
@resumable function generaterules(
    itemsets::Vector{Itemset},
    miner::Miner
)
    # From the original paper at 3.4 here:
    # http://www.rakesh.agrawal-family.com/papers/tkde96passoc_rj.pdf
    #
    # Given a frequent itemset l, rule generation examines each non-empty subset a
    # and generates the rule a => (l-a) with support = support(l) and
    # confidence = support(l)/support(a).
    # This computation can efficiently be done by examining the largest subsets of l first
    # and only proceeding to smaller subsets if the generated rules have the required
    # minimum confidence.
    # For example, given a frequent itemset ABCD, if the rule ABC => D does not have minimum
    # confidence, neither will AB => CD, and so we need not consider it.

    for itemset in filter(x -> length(x) >= 2, itemsets)
        subsets = powerset(itemset)

        for subset in subsets
            # subsets are built already sorted incrementally;
            # hence, since we want the antecedent to be longer initially,
            # the first subset values corresponds to (see comment below)
            # (l-a)
            _consequent = subset |> Itemset
            # a
            _antecedent = symdiff(items(itemset), items(_consequent)) |> Itemset

            # degenerate case
            if length(_antecedent) < 1 || length(_consequent) != 1
                continue
            end

            currentrule = ARule((_antecedent, _consequent))

            # sift pipeline to remove unwanted rules;
            # this can be customized at Miner-construction time.
            if !all(sift -> sift(currentrule) == true, powerups(miner, :rulesift))
                continue
            end

            interesting = true
            for meas in rulemeasures(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, dataset(miner), lthreshold, miner=miner)

                # some meaningfulness measure test is failed
                if gmeas_result < gthreshold
                    interesting = false
                    break
                end
            end

            # all meaningfulness measure tests passed
            if interesting
                push!(arules(miner), currentrule)
                @yield currentrule
            # since a meaningfulness measure test failed,
            # we don't want to keep generating rules.
            else
                break
            end
        end
    end
end

############################################################################################
#### Miner #################################################################################
############################################################################################
# TODO: rename those in local_threshold_integer/global_threshold_integer
"""
    getlocalthreshold_integer(miner::Miner, meas::Function)

See [`getlocalthreshold`](@ref).
"""
function getlocalthreshold_integer(miner::Miner, meas::Function)
    _nworlds = SoleLogics.frame(dataset(miner), 1) |> SoleLogics.nworlds
    return convert(Int64, floor(getlocalthreshold(miner, meas) * _nworlds))
end

"""
    getglobalthreshold_integer(miner::Miner, meas::Function, ninstances::Int64)

See [`getglobalthreshold`](@ref).
"""
function getglobalthreshold_integer(miner::Miner, meas::Function)
    return convert(
            Int64, floor(getglobalthreshold(miner, meas) * ninstances(dataset(miner))))
end
