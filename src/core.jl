############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
"""
    const Item = SoleLogics.Formula

Fundamental type in the context of
[association rule mining](https://en.wikipedia.org/wiki/Association_rule_learning).
An [`Item`](@ref) is a logical formula, which can be [`SoleLogics.check`](@ref)ed on models.

The purpose of association rule mining is to discover interesting relations between
[`Item`](@ref)s, regrouped in [`Itemset`](@ref)s, to generate association rules
([`ARule`](@ref)).

Interestingness is established through a set of [`MeaningfulnessMeasure`](@ref).

See also [`SoleLogics.check`](@ref), [`gconfidence`](@ref), [`lsupport`](@ref),
[`MeaningfulnessMeasure`](@ref), [`SoleLogics.Formula`](@ref).
"""
const Item = SoleLogics.Formula

"""
    const Itemset = Vector{Item}
    function Itemset(item::Item)
    function Itemset(itemsets::Vector{Itemset})

Collection of *unique* [`Item`](@ref)s.

Given a [`MeaningfulnessMeasure`](@ref) `meas` and a threshold to be overpassed, `t`,
then an itemset `itemset` is said to be meaningfull with respect to `meas` if and only if
`meas(itemset) > t`.
Alternatively, it is said to be *frequent*.

Generally speaking, meaningfulness (or interestingness) of an itemset is directly
correlated to its frequency in the data: intuitively, when a pattern is recurrent in data,
then it is candidate to be interesting.

Every association rule mining algorithm aims to find *frequent* itemsets by applying
meaningfulness measures such as local and global support, respectively [`lsupport`](@ref)
and [`gsupport`](@ref).

Frequent itemsets are then used to generate association rules ([`ARule`](@ref)).

See also [`ARule`](@ref), [`gsupport`](@ref), [`Item`](@ref), [`lsupport`](@ref),
[`MeaningfulnessMeasure`](@ref).
"""
const Itemset = Vector{Item}
Itemset(item::Item) = Itemset([item])
Itemset(itemsets::Vector{Itemset}) = Itemset.([union(itemsets...)...])

function Base.convert(::Type{Item}, itemset::Itemset)::Item
    @assert length(itemset) == 1 "Cannot convert $(itemset) of length $(length(itemset)) " *
        "to Item: itemset must contain exactly one item"
    return first(itemset)
end

function Base.show(io::IO, itemset::Itemset)
    print(io, "[" * join([syntaxstring(item) for item in itemset], ", ") * "]")
end

function Base.in(itemset::Itemset, target::Itemset)
    all(item -> item in target, itemset)
end

# this dispatch is needed to force the check to not consider the order of items in itemsets
function Base.in(itemset::Itemset, targets::Vector{Itemset})
    for target in targets
        if itemset in target
            return true
        end
    end

    return true
end

"""
    toformula(itemset::Itemset)

Conjunctive normal form of the [`Item`](@ref)s contained in `itemset`.

See also [`Item`](@ref), [`Itemset`](@ref), [`SoleLogics.LeftmostConjunctiveForm`](@ref)
"""
toformula(itemset::Itemset) = LeftmostConjunctiveForm(itemset)

# See meaningfulness measures section.
# A MeaningfulnessMeasure is a tuple shaped as (global measure, local threshold, global threshold)
"""
    const Threshold = Float64

Threshold value for meaningfulness measures.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref),
[`lsupport`](@ref).
"""
const Threshold = Float64

"""
    const WorldsMask = Vector{Int64}

Vector whose i-th position stores how many times a certain [`MeaningfulnessMeasure`](@ref)
applied on a specific [`Itemset`](@ref)s is true on the i-th world of multiple instances.

If a single instance is considered, then this acts as a bit mask.

For example, if we consider 5 instances, each of which containing 3 worlds, then the worlds
mask of an itemset could be [5,2,0], meaning that the itemset is always true on the first
world of every instance. If we consider the second world, the same itemset is true on it
only on two instances. If we consider the third world, then the itemset is never true.

See also [`Contributors`](@ref), [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const WorldsMask = Vector{Int64}

"""
    const EnhancedItemset = Vector{Tuple{Item,Int64,WorldsMask}}

"Enhanced" representation of an [`Itemset`](@ref), in which each [`Item`](@ref) is
associated to a counter and a specific [`WorldsMask`](@ref).

Consider an [`Item`](@ref) called `item`.
The first counter keeps the value of [`gsupport`](@ref) applied on `item` itself.
The second counter counts on which worlds [`Item`](@ref) is true.

Intuitively, this type is useful to represent and manipulate collections of items when we
want to avoid iterating an entire dataset multiple times when extracting frequent
[`Itemset`](@ref). This type is widely used to

!!! info
    To give you a better insight into where this type of data is used, this is widely used
    behind the scenes in the implementation of [`fpgrowth`](@ref) algorithm, which is the
    state of art algorithm to perform ARM.

See also [`fpgrowth`](@ref), [`Item`](@ref), [`Itemset`](@ref), [`WorldsMask`](@ref).
"""
const EnhancedItemset = Vector{Tuple{Item,Int64,WorldsMask}}

function Base.convert(::Type{EnhancedItemset}, itemset::Itemset, nworlds::Int64)
    return [(item, zeros(Int64, nworlds)) for item in itemset]
end

function Base.convert(::Type{Itemset}, enhanceditemset::EnhancedItemset)
    return [first(enhanceditem) for enhanceditem in enhanceditemset]
end

"""
    const ConditionalPatternBase = Vector{EnhancedItemset}

Collection of [`EnhancedItemset`](@ref).
This is useful to manipulate certain data structures when looking for frequent
[`Itemset`](@ref)s, such as [`FPTree`](@ref).

This is used to implement [`fpgrowth`](@ref) algorithm
[as described here](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf).

See also [`EnhancedItemset`](@ref), [`fpgrowth`](@ref), [`FPTree`](@ref).
"""
const ConditionalPatternBase = Vector{EnhancedItemset}

"""
    const ARule = Tuple{Itemset,Itemset}

An association rule represents a strong and meaningful co-occurrence relationship between
two [`Itemset`](@ref)s whose intersection is empty.

Generating all the [`ARule`](@ref) "hidden" in the data is the main purpose of ARM.

The general framework always followed by ARM techniques is to, firstly, generate all the
frequent itemsets considering a set of [`MeaningfulnessMeasure`](@ref) specifically
tailored to work with [`Itemset`](@ref)s.
Thereafter, all the association rules are generated by testing all the combinations of
frequent itemsets against another set of [`MeaningfulnessMeasure`](@ref), this time
designed to capture how "reliable" a rule is.

See also [`gconfidence`](@ref), [`Itemset`](@ref), [`lconfidence`](@ref),
[`MeaningfulnessMeasure`](@ref).
"""
const ARule = Tuple{Itemset,Itemset} # NOTE: see SoleLogics.Rule
antecedent(rule::ARule) = first(rule)
consequent(rule::ARule) = last(rule)

"""
    const MeaningfulnessMeasure = Tuple{Function, Threshold, Threshold}

In the classic propositional case scenario where each instance of a dataset is composed of
just a single world (it is a propositional interpretation), a meaningfulness measure
is simply a function which measures how many times a property of an [`Itemset`](@ref) or an
[`ARule`](@ref) is respected across all instances of the dataset.

In the context of modal logic, where the instances of a dataset are relational objects,
every meaningfulness measure must capture two aspects: how much an [`Itemset`](@ref) or an
[`ARule`](@ref) is meaningful *inside an instance*, and how much the same object is
meaningful *across all the instances*.

For this reason, we can think of a meaningfulness measure as a matryoshka composed of
an external global measure and an internal local measure.
The global measure tests for how many instances a local measure overpass a local threshold.
At the end of the process, a global threshold can be used to establish if the global measure
is actually meaningful or not.
(Note that this generalizes the propositional logic case scenario, where it is enough to
just apply a measure across instances.)

Therefore, a [`MeaningfulnessMeasure`](@ref) is a tuple composed of a global meaningfulness
measure, a local threshold and a global threshold.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref),
[`lsupport`](@ref).
"""
const MeaningfulnessMeasure = Tuple{Function, Threshold, Threshold}

doc_islocalof = doc_isglobalof = """
    islocalof(::Function, ::Function)::Bool
    isglobalof(::Function, ::Function)::Bool

Trait to indicate that a local meaningfulness measure is used as subroutine in a global
measure, or, vice versa, a global measure contains a local measure.

For example, `islocalof(lsupport, gsupport)` is `true`, and `isglobalof(gsupport, lsupport)`
is `false`.

!!! warning
    When implementing a custom meaningfulness measure, make sure to implement both
    traits if necessary. This is fundamental to guarantee the correct behavior of some
    methods, such as [`getlocalthreshold`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`lsupport`](@ref).
"""

"""$(doc_islocalof)"""
islocalof(::Function, ::Function)::Bool = false
"""$(doc_isglobalof)"""
isglobalof(::Function, ::Function)::Bool = false

"""
    ARMSubject = Union{ARule,Itemset}

[Memoizable](https://en.wikipedia.org/wiki/Memoization) types for association rule mining
(ARM).

See also [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref), [`LmeasMemo`](@ref),
[`LmeasMemoKey`](@ref).
"""
const ARMSubject = Union{ARule,Itemset} # memoizable association-rule-mining types

"""
    const LmeasMemoKey = Tuple{Symbol,ARMSubject,Int64}

Key of a [`LmeasMemo`](@ref) dictionary.
Represents a local meaningfulness measure name (as a `Symbol`), a [`ARMSubject`](@ref),
and the number of a dataset instance where the measure is applied.

See also [`LmeasMemo`](@ref), [`ARMSubject`](@ref).
"""
const LmeasMemoKey = Tuple{Symbol,ARMSubject,Int64}

"""
    const LmeasMemo = Dict{LmeasMemoKey,Threshold}

Association between a local measure of a [`ARMSubject`](@ref) on a specific dataset
instance, and its value.

See also [`LmeasMemoKey`](@ref), [`ARMSubject`](@ref).
"""
const LmeasMemo = Dict{LmeasMemoKey,Threshold}

"""
Structure for storing association between a local measure, applied on a certain
[`ARMSubject`](@ref) on a certain [`LogicalInstance`](@ref), and a vector of integers
representing the worlds for which the measure is greater than a certain threshold.

This type is intended to be used inside an [`ARuleMiner`](@ref) `info` named tuple, to
support the execution of, for example, [`fpgrowth`](@ref) algorthm.

See also [`LmeasMemoKey`](@ref), [`WorldMask`](@ref)
"""
const Contributors = Dict{LmeasMemoKey, WorldsMask}

"""
    const GmeasMemoKey = Tuple{Symbol,ARMSubject}

Key of a [`GmeasMemo`](@ref) dictionary.
Represents a global meaningfulness measure name (as a `Symbol`) and a [`ARMSubject`](@ref).

See also [`GmeasMemo`](@ref), [`ARMSubject`](@ref).
"""
const GmeasMemoKey = Tuple{Symbol,ARMSubject}

"""
    const GmeasMemo = Dict{GmeasMemoKey,Threshold}

Association between a global measure of a [`ARMSubject`](@ref) on a dataset, and its value.

The reference to the dataset is not explicited here, since [`GmeasMemo`](@ref) is intended
to be used as a [memoization](https://en.wikipedia.org/wiki/Memoization) structure inside
[`ARuleMiner`](@ref) objects, and the latter already knows the dataset they are working
with.

See also [`GmeasMemoKey`](@ref), [`ARMSubject`](@ref).
"""
const GmeasMemo = Dict{GmeasMemoKey,Threshold} # global measure of an itemset/arule => value

############################################################################################
#### Association rule miner machines #######################################################
############################################################################################

"""
    struct ARuleMiner
        X::AbstractDataset              # target dataset
        algo::MiningAlgo                # algorithm used to perform extraction

        items::Vector{Item}

        # global meaningfulness measures and their thresholds (both local and global)
        item_constrained_measures::Vector{<:MeaningfulnessMeasure}
        rule_constrained_measures::Vector{<:MeaningfulnessMeasure}

        nonfreqitems::Vector{Itemset}   # non-frequent itemsets dump
        freqitems::Vector{Itemset}      # collected frequent itemsets
        arules::Vector{ARule}           # collected association rules

        lmemo::LmeasMemo                # local memoization structure
        gmemo::GmeasMemo                # global memoization structure
        info::NamedTuple                # general informations
    end

Machine learning model interface to perform association rules extraction.

# Examples
```julia-repl
julia> using SoleRules
julia> using SoleData

# Load NATOPS DataFrame
julia> X_df, y = load_arff_dataset("NATOPS");

# Convert NATOPS DataFrame to a Logiset
julia> X = scalarlogiset(X_df)

# Prepare some propositional atoms
julia> p = Atom(ScalarCondition(UnivariateMin(1), >, -0.5))
julia> q = Atom(ScalarCondition(UnivariateMin(2), <=, -2.2))
julia> r = Atom(ScalarCondition(UnivariateMin(3), >, -3.6))

# Prepare modal atoms using later relationship - see [`SoleLogics.IntervalRelation`](@ref))
julia> lp = box(IA_L)(p)
julia> lq = diamond(IA_L)(q)
julia> lr = boxlater(r)

# Compose a vector of items, regrouping the atoms defined before
julia> manual_alphabet = Vector{Item}([p, q, r, lp, lq, lr])

# Create an association rule miner wrapping `apriori` algorithm - see [`apriori`](@ref);
# note that meaningfulness measures are not explicited and, thus, are defaulted as in the
# call below.
julia> miner = ARuleMiner(X, apriori(), manual_alphabet)

# Create an association rule miner, expliciting global meaningfulness measures with their
# local and global thresholds, both for [`Itemset`](@ref)s and [`ARule`](@ref).
julia> miner = ARuleMiner(X, apriori(), manual_alphabet,
    [(gsupport, 0.1, 0.1)], [(gconfidence, 0.2, 0.2)])

# Consider the dataset and learning algorithm wrapped by `miner` (resp., `X` and `apriori`)
# Mine the frequent itemsets, that is, those for which item measures are large enough.
# Then iterate the generator returned by [`mine`](@ref) to enumerate association rules.
julia> for arule in SoleRules.mine(miner)
    println(miner)
end
```

See also  [`ARule`](@ref), [`apriori`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Itemset`](@ref), [`GmeasMemo`](@ref), [`LmeasMemo`](@ref), [`MiningAlgo`](@ref).
"""
struct ARuleMiner
    # target dataset
    X::AbstractDataset
    # algorithm used to perform extraction
    algo::FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}
    items::Vector{Item}

    # meaningfulness measures
    item_constrained_measures::Vector{<:MeaningfulnessMeasure}
    rule_constrained_measures::Vector{<:MeaningfulnessMeasure}

    nonfreqitems::Vector{Itemset}   # non-frequent itemsets dump
    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    lmemo::LmeasMemo                # local memoization structure
    gmemo::GmeasMemo                # global memoization structure
    info::NamedTuple                # general informations

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        items::Vector{<:Item},
        item_constrained_measures::Vector{<:MeaningfulnessMeasure},
        rule_constrained_measures::Vector{<:MeaningfulnessMeasure};
        info::NamedTuple = (;)
    )
        new(X, MiningAlgo(algo), unique(items),
            item_constrained_measures, rule_constrained_measures,
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), info
        )
    end

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        items::Vector{<:Item}
    )
        ARuleMiner(X, MiningAlgo(algo), items,
            [(gsupport, 0.1, 0.1)], [(gconfidence, 0.2, 0.2)]
        )
    end
end

"""
    const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

[Function wrapper](https://github.com/yuyichao/FunctionWrappers.jl) representing a function
which performs mining of frequent [`Itemset`](@ref)s in a [`ARuleMiner`](@ref).

See also [`SoleLogics.AbstractDataset`](@ref), [`ARuleMiner`](@ref), [`apriori`](@ref),
[`fpgrowth`](@ref).
"""
const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

"""
    dataset(miner::ARuleMiner)::AbstractDataset

Getter for the dataset wrapped by `miner`s.

See [`SoleBase.AbstractDataset`](@ref), [`ARuleMiner`](@ref).
"""
dataset(miner::ARuleMiner)::AbstractDataset = miner.X

"""
    algorithm(miner::ARuleMiner)::MiningAlgo

Getter for the mining algorithm loaded into `miner`.

See [`ARuleMiner`](@ref), [`MiningAlgo`](@ref).
"""
algorithm(miner::ARuleMiner)::MiningAlgo = miner.algo

"""
    items(miner::ARuleMiner)

Getter for the [`Item`](@ref)s loaded into `miner`.

See [`ARuleMiner`](@ref), [`Item`](@ref), [`MiningAlgo`](@ref).
"""
items(miner::ARuleMiner) = miner.items

"""
    item_meas(miner::ARuleMiner)::Vector{<:MeaningfulnessMeasure}

Return the [`MeaningfulnessMeasure`](@ref)s tailored to work with [`Itemset`](@ref)s,
loaded inside `miner`.

See [`ARuleMiner`](@ref), [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref)
"""
item_meas(miner::ARuleMiner)::Vector{<:MeaningfulnessMeasure} =
    miner.item_constrained_measures

"""
    rule_meas(miner::ARuleMiner)::Vector{<:MeaningfulnessMeasure}

Return the [`MeaningfulnessMeasure`](@ref)s tailored to work with [`ARule`](@ref)s, loaded
inside `miner`.

See [`ARuleMiner`](@ref), [`ARule`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
rule_meas(miner::ARuleMiner)::Vector{<:MeaningfulnessMeasure} =
    miner.rule_constrained_measures

"""
    getlocalthreshold(miner::ARuleMiner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work locally (that is, analyzing "the inside"
of a dataset's instances) in `miner`.

See [`ARuleMiner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
getlocalthreshold(miner::ARuleMiner, meas::Function)::Threshold = begin
    for (gmeas, _, lthreshold) in item_meas(miner)
        if gmeas == meas || islocalof(meas, gmeas)
            return lthreshold
        end
    end

    error("The provided miner has no local threshold for $meas. Maybe the miner is not " *
        "initialized properly, and $meas is omitted. Please use item_meas/rule_meas " *
        "to check which measures are available, and setlocalthreshold to add a new " *
        "local measure, together with its local threshold.")
end

"""
    setlocalthreshold(miner::ARuleMiner, meas::Function, threshold::Threshold)

Setter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work locally (that is, analyzing "the inside"
of a dataset's instances) in `miner`.

See [`ARuleMiner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
setlocalthreshold(miner::ARuleMiner, meas::Function, threshold::Threshold) = begin
    error("TODO: This method is not implemented yet.")
end

"""
    getglobalthreshold(miner::ARuleMiner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work globally (that is, measuring the behavior
of a specific local-measure across all dataset's instances) in `miner`.

See [`ARuleMiner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
getglobalthreshold(miner::ARuleMiner, meas::Function)::Threshold = begin
    for (gmeas, gthreshold, _) in item_meas(miner)
        if gmeas == meas
            return gthreshold
        end
    end

    error("The provided miner has no global threshold for $meas. Maybe the miner is not " *
    "initialized properly, and $meas is omitted. Please use item_meas/rule_meas " *
    "to check which measures are available, and setglobalthreshold to add a new " *
    "global measure, together with local and global thresholds.")
end

"""
    setlocalthreshold(miner::ARuleMiner, meas::Function, threshold::Threshold)

Setter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work globally (that is, measuring the behavior
of a specific local-measure across all dataset's instances) in `miner`.

See [`ARuleMiner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
setglobalthreshold(miner::ARuleMiner, meas::Function, threshold::Threshold) = begin
    error("TODO: This method is not implemented yet.")
end

"""
    freqitems(miner::ARuleMiner)

Return all frequent [`Itemset`](@ref)s mined by `miner`.

See also [`ARuleMiner`](@ref), [`Itemset`](@ref).
"""
freqitems(miner::ARuleMiner) = miner.freqitems


"""
    nonfreqitems(miner::ARuleMiner)

Return all non-frequent [`Itemset`](@ref)s mined by `miner`.

See also [`ARuleMiner`](@ref), [`Itemset`](@ref).
"""
nonfreqitems(miner::ARuleMiner) = miner.nonfreqitems

"""
    arules(miner::ARuleMiner)

Return all the [`ARule`](@ref)s mined by `miner`.

See also [`ARule`](@ref), [`ARuleMiner`](@ref).
"""
arules(miner::ARuleMiner) = miner.arules

"""
    localmemo(miner::ARuleMiner)::LmeasMemo
    localmemo(miner::ARuleMiner, key::LmeasMemoKey)

Return the local memoization structure inside `miner`, or a specific entry if a
[`LmeasMemoKey`](@ref) is provided.

See also [`ARuleMiner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo(miner::ARuleMiner)::LmeasMemo = miner.lmemo
localmemo(miner::ARuleMiner, key::LmeasMemoKey) = get(miner.lmemo, key, nothing)

"""
    localmemo!(miner::ARuleMiner, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by `miner`.

See also [`ARuleMiner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo!(miner::ARuleMiner, key::LmeasMemoKey, val::Threshold) = miner.lmemo[key] = val

"""
    globalmemo(miner::ARuleMiner)::GmeasMemo
    globalmemo(miner::ARuleMiner, key::GmeasMemoKey)

Return the global memoization structure inside `miner`, or a specific entry if a
[`GmeasMemoKey`](@ref) is provided.

See also [`ARuleMiner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo(miner::ARuleMiner)::GmeasMemo = miner.gmemo
globalmemo(miner::ARuleMiner, key::GmeasMemoKey) = get(miner.gmemo, key, nothing)

"""
    globalmemo!(miner::ARuleMiner, key::GmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the global memoization structure wrapped by
`miner`.

See also [`ARuleMiner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo!(miner::ARuleMiner, key::GmeasMemoKey, val::Threshold) = miner.gmemo[key] = val

############################################################################################
#### ARuleMiner machines specializations ###################################################
############################################################################################

"""
    info(miner::ARuleMiner)::NamedTuple
    info(miner::ARuleMiner, key::Symbol)

Getter for the entire additional informations field inside a `miner`, or one of its specific
entries.

See also [`ARuleMiner`](@ref), [`NamedTuple`](@ref).
"""
info(miner::ARuleMiner)::NamedTuple = miner.info
info(miner::ARuleMiner, key::Symbol) = getfield(miner.info, key)

"""
    isequipped(miner::ARuleMiner, key::Symbol)

Return whether `miner` additional information field contains an entry `key`.

See also [`ARuleMiner`](@ref), [`info`](@ref).
"""
isequipped(miner::ARuleMiner, key::Symbol) = haskey(miner |> info, key)

"""
    macro equip_contributors(ex)

Enable [`ARuleMiner`](@ref) contructor to handle [`fpgrowth`](@ref) efficiently by
leveraging a [`Contributors`](@ref) structure.

# Usage
julia> miner = @equip_contributors ARuleMiner(X, apriori(), manual_alphabet, _item_meas, _rule_meas)

See also [`ARuleMiner`](@ref), [`Contributors`](@ref), [`fpgrowth`](@ref).
"""
macro equip_contributors(ex)
    # Extracting function name and arguments
    func, args = ex.args[1], ex.args[2:end]

    # Constructing the modified expression with kwargs
    return esc(:($(func)($(args...); info=(; contributors=Contributors([])))))

    return new_ex
end

doc_getcontributors = """
    function contributors(
        measname::Symbol,
        item::Item,
        ninstance::Int64,
        miner::ARuleMiner
    )::WorldsMask

    function contributors(
        measname::Symbol,
        itemset::Itemset,
        ninstance::Int64,
        miner::ARuleMiner
    )::WorldsMask

    function contributors(
        memokey::LmeasMemoKey,
        miner::ARuleMiner
    )::WorldsMask

Consider all the contributors of an [`Item`](@ref), that is, all the worlds for which the
[`lsupp`](@ref) is greater than a certain [`Threshold`](@ref).

Return a vector whose size is the number of worlds, and the content is 0 if the local
threshold is not overpassed, 1 otherwise.

!!! warning
    This method requires the [`ARuleMiner`](@ref) to be declared using
    [`@equip_contributors`](@ref).

See also [`Item`](@ref), [`LmeasMemoKey`](@ref), [`lsupp`](@ref), [`@equip_contributors`](@ref),
[`Threshold`](@ref), [`WorldsMask`](@ref).
"""
function contributors(
    memokey::LmeasMemoKey,
    miner::ARuleMiner
)::WorldsMask
    try
        return info(miner, :contributors)[memokey]
    catch
        error("Error when getting contributors of $(measname) applied to  $(item) at " *
        "instance $(ninstance). Please, use @equip_contributors or provide an " *
        "`info=(;contributors=Contributors([]))` when instanciating the miner.")
    end
end
function contributors(
    measname::Symbol,
    itemset::Itemset,
    ninstance::Int64,
    miner::ARuleMiner
)::WorldsMask
    return contributors((measname, itemset, ninstance), miner)
end
function contributors(
    measname::Symbol,
    item::Item,
    ninstance::Int64,
    miner::ARuleMiner
)::WorldsMask
    return contributors(measname, Itemset(item), ninstance, miner)
end

"""
    function contributors!(miner::ARuleMiner, key::LmeasMemoKey, mask::WorldsMask)

Set a `miner`'s contributors entry.

See also [`ARuleMiner`](@ref), [`LmeasMemoKey`](@ref), [`@equip_contributors`](@ref),
[`WorldsMask`](@ref).
"""
function contributors!(miner::ARuleMiner, key::LmeasMemoKey, mask::WorldsMask)
    try
        info(miner, :contributors)[key] = mask
    catch
        error("Please, use @equip_contributors or provide an " *
        "`info=(;contributors=Contributors([]))` when instanciating the miner.")
    end
end

"""
    function mine(miner::ARuleMiner)

Synonym for `SoleRules.apply(miner, dataset(miner))`.

See also [`ARule`](@ref), [`Itemset`](@ref), [`SoleRules.apply`](@ref).
"""
function mine(miner::ARuleMiner)
    return apply(miner, dataset(miner))
end

"""
    function apply(miner::ARuleMiner, X::AbstractDataset)

Extract association rules in the dataset referenced by `miner`, saving the interesting
[`Itemset`](@ref)s inside `miner`.
Then, return a generator of [`ARules`](@ref)s.

See also [`ARule`](@ref), [`Itemset`](@ref).
"""
function apply(miner::ARuleMiner, X::AbstractDataset)
    # extract frequent itemsets
    miner.algo(miner, X)
    return arules_generator(freqitems(miner), miner)
end

function Base.show(io::IO, miner::ARuleMiner)
    println(io, "$(dataset(miner))")

    println(io, "Alphabet: $(items(miner))\n")
    println(io, "Items measures: $(item_meas(miner))")
    println(io, "Rules measures: $(rule_meas(miner))\n")

    println(io, "# of frequent patterns mined: $(length(freqitems(miner)))")
    println(io, "# of association rules mined: $(length(arules(miner)))\n")

    println(io, "Local measures memoization structure entries: " *
        "$(length(miner.lmemo |> keys))")
    println(io, "Global measures memoization structure entries: " *
        "$(length(miner.gmemo |> keys))\n")

    print(io, "Additional infos: $(info(miner) |> keys)")
end
