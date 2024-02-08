############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
"""
    const Item = SoleLogics.Formula

Fundamental type in the context of association rule mining.
An [`Item`](@ref) is a logical formula, which can be [`SoleLogics.check`](@ref)ed on models.

See also [`SoleLogics.check`](@ref), [`SoleLogics.Formula`].
"""
const Item = SoleLogics.Formula

"""
    const Itemset = Vector{Item}
    function Itemset(item::Item)
    function Itemset(itemsets::Vector{Itemset})

Collection of *unique* [`Item`](@ref)s.
In the context of association rule mining, we want to work with interesting
[`Itemset`](@ref)s: how much interesting is an [`Itemset`](@ref) is established through
specific meaningfulness measures such as [`lsupport`](@ref) and [`gsupport`](@ref).
"""
const Itemset = Vector{Item}
Itemset(item::Item) = Itemset([item])
Itemset(itemsets::Vector{Itemset}) = Itemset(union(itemsets...))

"""
    value(itemset::Itemset) # TODO: change toformula

Conjunctive normal form of the [`Item`](@ref)s contained in `itemset`.

See also [`SoleLogics.LeftmostConjunctiveForm`](@ref)
"""
value(itemset::Itemset) = LeftmostConjunctiveForm(itemset)

"""
    const ARule = Tuple{Itemset,Itemset}

An association rule represents a strong and meaningful co-occurrence relationship between
two [`Itemset`](@ref)s whose intersection is empty.

The meaningfulness of an [`ARule`](@ref) can be established through specific meaningfulness
measures.
For example, local confidence ([`lconfidence`](@ref)) when testing the rule on
a specific logical instance of a dataset, or global confidence ([`gconfidence`](@ref))
when testing the rule on an entire dataset.

See also [`gconfidence`](@ref), [`lconfidence`](@ref), [`Itemset`](@ref).
"""
const ARule = Tuple{Itemset,Itemset} # NOTE: see SoleLogics.Rule
antecedent(rule::ARule) = first(rule)
consequent(rule::ARule) = last(rule)

# See meaningfulness measures section.
# A ConstrainedMeasure is a tuple shaped as (global measure, local threshold, global threshold)
"""
    const Threshold = Float64

Threshold value for meaningfulness measures.
"""
const Threshold = Float64

"""
    const ConstrainedMeasure = Tuple{Function, Threshold, Threshold}

In the context of modal logic, where the instances of a dataset are relational objects,
every meaningfulness measure must capture two aspects: how much an [`Itemset`](@ref) or an
[`ARule`](@ref) is meaningful *inside an instance*, and how much the same object is
meaningful *across the instances*.

For this reason, we can think of a meaningfulness measure as a matryoshka composed of
an external global measure and an internal local measure.
The global measure tests for how many instances a local measure overpass a local threshold.
At the end of the process, a global threshold can be used to establish if the global measure
is actually meaningful or not.
(Note that this generalizes the propositional logic case scenario, where it is enough to just apply a
measure across instances.)

Therefore, a [`ConstrainedMeasure`](@ref) is a tuple composed of a global meaningfulness
measure, a local threshold and a global threshold.

See also [`gconfidence`](@ref), [`gsupport`](@ref).
"""
const ConstrainedMeasure = Tuple{Function, Threshold, Threshold}

"""
    MemoARM = Union{Itemset,ARule} # TODO: change to ARMSubject   (MemoSubject)

[Memoizable](https://en.wikipedia.org/wiki/Memoization) types for association rule mining
(ARM).

See also [] TODO: add link to ARM memoization section.
"""
const MemoARM = Union{Itemset,ARule} # memoizable association-rule-mining types

"""
    const LmeasMemoKey = Tuple{Symbol,MemoARM,Int64}

Key of a [`LmeasMemo`](@ref) dictionary.
Represents a local meaningfulness measure name (as a *Symbol*), a [`MemoARM`](@ref),
and the number of a dataset instance where the measure is applied.

See also [`LmeasMemo`](@ref), [`MemoARM`](@ref).
"""
const LmeasMemoKey = Tuple{Symbol,MemoARM,Int64}

"""
    const LmeasMemo = Dict{LmeasMemoKey,Float64}

Association between a local measure of a [`MemoARM`](@ref) on a specific dataset instance,
and its value.

See also [`LmeasMemoKey`](@ref), [`MemoARM`](@ref).
"""
const LmeasMemo = Dict{LmeasMemoKey,Float64}

"""
    const GmeasMemoKey = Tuple{Symbol,MemoARM}

Key of a [`GmeasMemo`](@ref) dictionary.
Represents a global meaningfulness measure name (as a *Symbol*) and a [`MemoARM`](@ref).

See also [`GmeasMemo`](@ref), [`MemoARM`](@ref).
"""
const GmeasMemoKey = Tuple{Symbol,MemoARM}

"""
    const GmeasMemo = Dict{GmeasMemoKey,Float64}

Association between a global measure of a [`MemoARM`](@ref) on a dataset, and its value.

The reference to the dataset is not explicited here, since [`GmeasMemo`](@ref) is intended
to be used as a [memoization](https://en.wikipedia.org/wiki/Memoization) structure inside # TODO: remove repetition
structures which performs mining, and knows the dataset they are working with.

See also [`GmeasMemoKey`](@ref), [`MemoARM`](@ref).
"""
const GmeasMemo = Dict{GmeasMemoKey,Float64} # global measure of an itemset/arule => value

"""
    combine(itemsets, newlength)

Combines itemsets from `itemsets` into new itemsets of length `newlength`
by taking all combinations of two itemsets and unioning them.
"""
function combine(itemsets::Vector{<:Itemset}, newlength::Integer)
    return
        Iterators.filter(
            combo -> length(combo) == newlength,
            Iterators.map(
                combo -> union(combo[1], combo[2]),
                combinations(itemsets, 2)
            )
        )
    )
end

############################################################################################
#### Association rule miner machine ########################################################
############################################################################################

"""
    struct ARuleMiner
        X::AbstractDataset              # target dataset
        algo::MiningAlgo                # algorithm used to perform extraction

        alphabet::Vector{Item}

        # global meaningfulness measures and their thresholds (both local and global)
        item_constrained_measures::Vector{<:ConstrainedMeasure}
        rule_constrained_measures::Vector{<:ConstrainedMeasure}

        nonfreqitems::Vector{Itemset}   # non-frequent itemsets dump
        freqitems::Vector{Itemset}      # collected frequent itemsets
        arules::Vector{ARule}           # collected association rules

        lmemo::LmeasMemo                # local memoization structure
        gmemo::GmeasMemo                # global memoization structure
        info::NamedTuple                # general informations
    end

Machine learning model interface to perform association rules extraction.

TODO: explain in deep (example of construction, launch and save results)
TODO: atleast one usage example

See also  [`ARule`](@ref), [`ConstrainedMeasure`](@ref), [`Itemset`](@ref),
[`GmeasMemo`](@ref), [`LmeasMemo`](@ref), [`MiningAlgo`](@ref).
"""
struct ARuleMiner
    # target dataset
    X::AbstractDataset
    # algorithm used to perform extraction
    algo::FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}
    alphabet::Vector{Item} # NOTE: this could be a generator, TODO: change name

    # meaningfulness measures
    item_constrained_measures::Vector{<:ConstrainedMeasure}
    rule_constrained_measures::Vector{<:ConstrainedMeasure}

    nonfreqitems::Vector{Itemset}   # non-frequent itemsets dump
    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    lmemo::LmeasMemo                # local memoization structure
    gmemo::GmeasMemo                # global memoization structure
    info::NamedTuple                # general informations

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item},
        item_constrained_measures::Vector{<:ConstrainedMeasure},
        rule_constrained_measures::Vector{<:ConstrainedMeasure},
    )
        new(X, MiningAlgo(algo), alphabet,
            item_constrained_measures,
            rule_constrained_measures,
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), (;)
        )
    end

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item}
    )
        # ARuleMiner(X, MiningAlgo(algo), alphabet,
        new(X, MiningAlgo(algo), alphabet,
            [(gsupport, 0.5, 0.5)], [(gconfidence, 0.5, 0.5)],
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), (;)
        )
    end
end

"""
    const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

[Function wrapper](https://github.com/yuyichao/FunctionWrappers.jl) representing a function
which performs mining of frequent [`Itemset`](@ref)s in a [`ARuleMiner`](@ref).

See also [`SoleLogics.AbstractDataset`](@ref), [`ARuleMiner`](@ref).
"""
const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

doc_aruleminer_getters = """
    dataset(miner::ARuleMiner)::AbstractDataset
    algorithm(miner::ARuleMiner)::MiningAlgo
    alphabet(miner::ARuleMiner)::Vector{Item}

    item_meas(miner::ARuleMiner)::Vector{<:ConstrainedMeasure}
    rule_meas(miner::ARuleMiner)::Vector{<:ConstrainedMeasure}

    freqitems(miner::ARuleMiner)::Vector{Itemset}
    nonfreqitems(miner::ARuleMiner)::Vector{Itemset}
    arules(miner::ARuleMiner)::Vector{ARule}

    getlocalmemo(miner::ARuleMiner, key::LmeasMemoKey)::Float64
    getglobalmemo(miner::ARuleMiner, key::GmeasMemoKey)::Float64

Getters for [`ARuleMiner`](@ref) fields.
"""

doc_aruleminer_setters = """
    setlocalmemo(miner::ARuleMiner, key::LmeasMemoKey, val::Float64)
    setglobalmemo(miner::ARuleMiner, key::GmeasMemoKey, val::Float64)

Setters for [`ARuleMiner`](@ref) fields.
"""

"""$(doc_aruleminer_getters)"""
dataset(miner::ARuleMiner)::AbstractDataset = miner.X

"""$(doc_aruleminer_getters)"""
algorithm(miner::ARuleMiner)::MiningAlgo = miner.algo
"""$(doc_aruleminer_getters)"""
alphabet(miner::ARuleMiner) = miner.alphabet

"""$(doc_aruleminer_getters)"""
item_meas(miner::ARuleMiner) = miner.item_constrained_measures
"""$(doc_aruleminer_getters)"""
rule_meas(miner::ARuleMiner) = miner.rule_constrained_measures

"""$(doc_aruleminer_getters)"""
freqitems(miner::ARuleMiner) = miner.freqitems
"""$(doc_aruleminer_getters)"""
nonfreqitems(miner::ARuleMiner) = miner.nonfreqitems
"""$(doc_aruleminer_getters)"""
arules(miner::ARuleMiner) = miner.arules

"""$(doc_aruleminer_getters)"""
getlocalmemo(miner::ARuleMiner, key::LmeasMemoKey) = get(miner.lmemo, key, nothing)
"""$(doc_aruleminer_setters)"""
setlocalmemo(miner::ARuleMiner, key::LmeasMemoKey, val::Float64) = miner.lmemo[key] = val

"""$(doc_aruleminer_getters)"""
getglobalmemo(miner::ARuleMiner, key::GmeasMemoKey) = get(miner.gmemo, key, nothing)
"""$(doc_aruleminer_setters)"""
setglobalmemo(miner::ARuleMiner, key::GmeasMemoKey, val::Float64) = miner.gmemo[key] = val

"""
    function mine(miner::ARuleMiner)

Synonym for *SoleRules.apply(miner, dataset(miner))*.

See also [`ARule`](@ref), [`Itemset`](@ref), [`SoleRules.apply`](@ref).
"""
function mine(miner::ARuleMiner)
    return apply(miner, dataset(miner))
end

"""
    function apply(miner::ARuleMiner, X::AbstractDataset)

Extract association rules in the dataset referenced by *miner*, saving the interesting
[`Itemset`](@ref)s inside *miner*.
Then, return a generator of [`ARules`](@ref)s.

See also [`ARule`](@ref), [`Itemset`](@ref).
"""
function apply(miner::ARuleMiner, X::AbstractDataset)
    # extract frequent itemsets
    miner.algo(miner, X)
    return arules_generator(freqitems(miner), miner)
end

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

            @yield currentrule
        end
    end
end

############################################################################################
#### Meaningfulness measures ###############################################################
############################################################################################

function lsupport(
    itemset::Itemset,
    logi_instance::LogicalInstance;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # retrieve logiset, and the specific instance
    X, i_instance = logi_instance.s, logi_instance.i_instance

    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getlocalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    # compute local measure, then divide it by the instance total number of worlds
    ans = sum([check(value(itemset), X, i_instance, w)
        for w in allworlds(X, i_instance)]) / nworlds(X, i_instance)

    if !isnothing(miner)
        setlocalmemo(miner, memokey, ans)
    end

    return ans
end

function gsupport(
    itemset::Itemset,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gsupport), itemset))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getglobalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    # compute global measure, then divide it by the dataset total number of instances
    ans = sum([lsupport(itemset, getinstance(X, i_instance); miner=miner) >= threshold
        for i_instance in 1:ninstances(X)]) / ninstances(X)

    if !isnothing(miner)
        setglobalmemo(miner, memokey, ans)
    end

    return ans
end

function lconfidence(
    rule::ARule,
    logi_instance::LogicalInstance;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lconfidence), rule, logi_instance.i_instance))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getglobalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    ans = lsupport(SoleRules.merge(_antecedent, _consequent), logi_instance; miner=miner) /
        lsupport(_antecedent, logi_instance; miner=miner)

    if !isnothing(miner)
        setlocalmemo(miner, memokey, ans)
    end

    return ans
end

function gconfidence(
    rule::ARule,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gconfidence), rule))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getglobalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    ans = gsupport(union(_antecedent, _consequent), X, threshold; miner=miner) /
        gsupport(_antecedent, X, threshold; miner=miner)

    if !isnothing(miner)
        setglobalmemo(miner, memokey, ans)
    end

    return ans
end
