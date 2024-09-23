# Bulldozer utilities

"""
    struct Bulldozer{
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    } <: AbstractMiner
        instance::SoleLogics.LogicalInstance
        ith_instance::Int64

        items::Vector{I}

        lmemo::LmeasMemo
        itemsetmeasures::Vector{IMEAS}
        powerups::Powerup

        datalock::ReentrantLock
        memolock::ReentrantLock
        poweruplock::ReentrantLock
    }

Thread-safe specialized structure, useful to handle mining within a modal `instance`.

When writing your multi-threaded/multi-processes mining algorithm, you can use a
monolithic [`Miner`](@ref) structure to collect the initial parameterization, map many
Bulldozers (merging their local memoization structure) and then reduce the results.

See also [`AbstractMiner`](@ref), [`Miner`](@ref).
"""
struct Bulldozer{
    I<:Item,
    IMEAS<:MeaningfulnessMeasure
} <: AbstractMiner
    instance::SoleLogics.LogicalInstance
    ith_instance::Int64

    items::Vector{I}

    lmemo::LmeasMemo
    itemsetmeasures::Vector{IMEAS}
    powerups::Powerup

    datalock::ReentrantLock
    memolock::ReentrantLock
    poweruplock::ReentrantLock

    function Bulldozer(
        instance::SoleLogics.LogicalInstance,
        ith_instance::Int64,
        items::Vector{I},
        itemsetmeasures::Vector{IMEAS};
        powerups::Powerup=Powerup()
    ) where {
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    }
        return new{I,IMEAS}(instance, ith_instance, items, LmeasMemo(), itemsetmeasures,
            powerups, ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end

    function Bulldozer(miner::Miner, ith_instance::Int64)
        return Bulldozer(
                SoleLogics.getinstance(miner |> data, ith_instance),
                ith_instance,
                items(miner),
                itemsetmeasures(miner),
                powerups=deepcopy(powerups(miner))
            )
    end
end

"""
    instance(bulldozer::Bulldozer)

Getter for the instance wrapped by `bulldozer`.
See also [`Bulldozer`](@ref), [`SoleLogics.LogicalInstance`](@ref).
"""
instance(bulldozer::Bulldozer) = bulldozer.instance

"""
    instancenumber(bulldozer::Bulldozer)

Retrieve the instance number associated with `bulldozer`.
See also [`Bulldozer`](@ref), [`instance(bulldozer::Bulldozer)`](@ref).
"""
instancenumber(bulldozer::Bulldozer) = bulldozer.ith_instance

"""
Getter for the frame of the instance wrapped by `bulldozer`.
See also [`instance(bulldozer::Bulldozer)`](@ref).
"""
function SoleLogics.frame(bulldozer::Bulldozer)
    # consider the instance wrapped by `bulldozer`;
    # get retrieve Kripke frame shape by the instance's parent Logiset.
    _instance = instance(bulldozer)
    SoleLogics.frame(_instance.s, instancenumber(bulldozer))
end

"""
    datalock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the
[`SoleLogics.LogicalInstance`](@ref) wrapped by a [`Bulldozer`](@ref).
"""
datalock(bulldozer::Bulldozer) = bulldozer.datalock

"""
    memolock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the inner [`Bulldozer`](@ref)'s
memoization structure
"""
memolock(bulldozer::Bulldozer) = bulldozer.memolock

"""
    poweruplock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the customizable dictionary within
a [`Bulldozer`](@ref).
"""
poweruplock(bulldozer::Bulldozer) = bulldozer.poweruplock

"""
    localmemo!(bulldozer::Bulldozer, key::LmeasMemoKey, val::Threshold)

Setter for [`Bulldozer`](@ref)'s memoization structure.
"""
localmemo!(
    bulldozer::Bulldozer,
    key::LmeasMemoKey,
    val::Threshold
) = lock(memolock(bulldozer)) do
    bulldozer.lmemo[key] = val
end

itemsetmeasures(
    bulldozer::Bulldozer
)::Vector{<:MeaningfulnessMeasure} = bulldozer.itemsetmeasures

"""
    powerups(bulldozer::Bulldozer)::Powerup
    powerups(bulldozer::Bulldozer, key::Symbol)::Any
    powerups(bulldozer::Bulldozer, key::Symbol, inner_key)::Any

Getter for the customizable dictionary wrapped by a [`Bulldozer`](@ref).
"""
powerups(bulldozer::Bulldozer)::Powerup = lock(poweruplock(bulldozer)) do
    bulldozer.powerups
end
powerups(bulldozer::Bulldozer, key::Symbol)::Any = lock(poweruplock(bulldozer)) do
    bulldozer.powerups[key]
end
powerups(
    bulldozer::Bulldozer,
    key::Symbol,
    inner_key
)::Any = lock(poweruplock(bulldozer)) do
    (bulldozer.powerups[key])[inner_key]
end

powerups!(miner::Bulldozer, key::Symbol, val) = lock(poweruplock(miner)) do
    miner.powerups[key] = val
end
powerups!(miner::Bulldozer, key::Symbol, inner_key, val) = lock(poweruplock(miner)) do
    miner.powerups[key][inner_key] = val
end

"""
    haspowerup(miner::Bulldozer, key::Symbol)

Return whether `bulldozer` powerups field contains an entry `key`.
"""
haspowerup(miner::Bulldozer, key::Symbol) = lock(poweruplock(miner)) do
    haskey(miner |> powerups, key)
end

# Just to mantain Miner's interfaces
measures(miner::Bulldozer) = itemsetmeasures(miner)

"""
    function bulldozer_reduce(b1::Bulldozer, b2::Bulldozer)::LmeasMemo

Reduce many [`Bulldozer`](@ref)s together, merging their local memo structures.
"""
function bulldozer_reduce(
    b1lmemo::Union{Bulldozer,LmeasMemo},
    b2lmemo::Union{Bulldozer,LmeasMemo}
)::LmeasMemo
    if b1lmemo isa Bulldozer
        b1lmemo = localmemo(b1lmemo)
    end

    if b2lmemo isa Bulldozer
        b2lmemo = localmemo(b2lmemo)
    end

    for k in keys(b2lmemo)
        if haskey(b1lmemo, k)
            b1lmemo[k] += b2lmemo[k]
        else
            b1lmemo[k] = b2lmemo[k]
        end
    end

    return b1lmemo
end

function bulldozer_reduce2(local_results::Vector{Bulldozer})
    b1lmemo = local_results |> first |> localmemo

    for i in 2:length(local_results)
        b2lmemo = local_results[i] |> localmemo
        for k in keys(b2lmemo)
            if haskey(b1lmemo, k)
                b1lmemo[k] += b2lmemo[k]
            else
                b1lmemo[k] = b2lmemo[k]
            end
        end
    end

    return b1lmemo
end

"""
Load a local memoization structure inside `miner`.
Also, returns a dictionary associating each loaded local [`Itemset`](@ref) loaded to its
its global support, in order to simplify `miner`'s job when working in the global setting.

See also [`Itemset`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref), [`Miner`](@ref).
"""
function load_bulldozer!(miner::Miner, lmemo::LmeasMemo)
    # a local memo key is a Tuple{Symbol,ARMSubject,Int64}

    fpgrowth_fragments = DefaultDict{Itemset,Int64}(0)
    min_lsupport_threshold = findmeasure(miner, lsupport)[2]

    for (lmemokey, lmeasvalue) in lmemo
        meas, subject, _ = lmemokey
        localmemo!(miner, lmemokey, lmeasvalue)
        if meas == :lsupport && lmeasvalue > min_lsupport_threshold
            fpgrowth_fragments[subject] += 1
        end
    end

    return fpgrowth_fragments
end



# Itemset utilities

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



# ARule utilities

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
            # this can be customized at construction time - see Miner constructor kwargs.
            # NOTE: for some reason, the equivalent expression
            # `if !all(sift -> sift(currentrule), powerups(miner, :rulesift)) continue end`
            # does not work, since `currentrule` is not identified from external scope.
            sifted = false
            for sift in powerups(miner, :rulesift)
                if !sift(currentrule)
                    sifted = true
                    break
                end
            end

            # this rule is unwanted, w.r.t sifting mechanism
            if sifted
                continue
            end

            interesting = true
            for meas in rulemeasures(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, data(miner), lthreshold, miner)

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



# Miner utilities

# TODO: rename those in local_threshold_integer/global_threshold_integer
"""
    getlocalthreshold_integer(miner::Miner, meas::Function)

See [`getlocalthreshold`](@ref).
"""
function getlocalthreshold_integer(miner::Miner, meas::Function)
    _nworlds = SoleLogics.frame(data(miner), 1) |> SoleLogics.nworlds
    return convert(Int64, floor(getlocalthreshold(miner, meas) * _nworlds))
end

"""
    getglobalthreshold_integer(miner::Miner, meas::Function, ninstances::Int64)

See [`getglobalthreshold`](@ref).
"""
function getglobalthreshold_integer(miner::Miner, meas::Function)
    return convert(
            Int64, floor(getglobalthreshold(miner, meas) * ninstances(data(miner))))
end
