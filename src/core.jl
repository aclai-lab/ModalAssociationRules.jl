############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
"""
    const Item = SoleLogics.Formula

Fundamental type in the context of
[association rule mining](https://en.wikipedia.org/wiki/Association_rule_learning).
An [`Item`](@ref) is a logical formula, which can be [`SoleLogics.check`](@ref)ed on models.

The purpose of association rule mining (ARM) is to discover interesting relations between
[`Item`](@ref)s, regrouped in [`Itemset`](@ref)s, to generate association rules
([`ARule`](@ref)).

Interestingness is established through a set of [`MeaningfulnessMeasure`](@ref).

See also [`SoleLogics.check`](@ref), [`gconfidence`](@ref), [`lsupport`](@ref),
[`MeaningfulnessMeasure`](@ref), [`SoleLogics.Formula`](@ref).
"""
const Item = SoleLogics.Formula

function Base.isless(a::Item, b::Item)
    isless(hash(a), hash(b))
end

"""
    struct Itemset
        items::Vector{Item}
    end

Collection of *unique* [`Item`](@ref)s.

Given a [`MeaningfulnessMeasure`](@ref) `meas` and a threshold to be overpassed `t`,
then an itemset `itemset` is said to be meaningful with respect to `meas` if and only if
`meas(itemset) > t`.

Generally speaking, meaningfulness (or interestingness) of an itemset is directly
correlated to its frequency in the data: intuitively, when a pattern is recurrent in data,
then it is candidate to be interesting.

Every association rule mining algorithm aims to find *frequent* itemsets by applying
meaningfulness measures such as local and global support, respectively [`lsupport`](@ref)
and [`gsupport`](@ref).

Frequent itemsets are then used to generate association rules ([`ARule`](@ref)).

!!! note
    Despite being implemented as vector, an [`Itemset`](@ref) behaves like a set.
    [Lookup is faster](https://www.juliabloggers.com/set-vs-vector-lookup-in-julia-a-closer-look/)
    and the internal sorting of the items is essential to make mining algorithms work.

    In other words, it is guaranteed that, if two [`Itemset`](@ref) are created with the
    same content, regardless of their items order, then their hash is the same.

See also [`ARule`](@ref), [`gsupport`](@ref), [`Item`](@ref), [`lsupport`](@ref),
[`MeaningfulnessMeasure`](@ref).
"""
struct Itemset
    items::Vector{Item}

    Itemset() = new(Vector{Item}[])
    Itemset(item::I) where {I<:Item} = new(Vector{Item}([item]))
    Itemset(itemset::Vector{I}) where {I<:Item} = new(Vector{Item}(itemset |> unique))

    Itemset(anyvec::Vector{Any}) = begin
        @assert isempty(anyvec) "Illegal constructor call"
        return Itemset()
    end

    Itemset(itemsets::Vector{Itemset}) = return union(itemsets)
end

@forward Itemset.items size, IndexStyle, setindex!
@forward Itemset.items iterate, length, firstindex, lastindex, similar, show

function Base.getindex(itemset::Itemset, indexes::Vararg{Int,N}) where N
    return Itemset(items(itemset)[indexes...])
end

function Base.getindex(itemset::Itemset, range::AbstractUnitRange{I}) where {I<:Integer}
    return Itemset(items(itemset)[range])
end

function push!(itemset::Itemset, item::Item)
    push!(items(itemset), item)
end

items(itemset::Itemset) = itemset.items

function Base.union(itemsets::Vector{Itemset})
    return Itemset(union(items.([itemsets]...)...))
end

function Base.union(itemsets::Vararg{Itemset,N}) where N
    return union([itemsets...])
end

function Base.hash(itemset::Itemset, h::UInt)
    return hash(itemset |> items |> sort, h)
end

function Base.convert(::Type{Itemset}, item::Item)
    return Itemset(item)
end

function Base.convert(::Type{Itemset}, formulavector::Vector{Formula})
    return Itemset(formulavector)
end

function Base.convert(::Type{Item}, itemset::Itemset)::Item
    @assert length(itemset) == 1 "Cannot convert $(itemset) of length $(length(itemset)) " *
        "to Item: itemset must contain exactly one item"
    return first(itemset)
end

function Base.:(==)(itemset1::Itemset, itemset2::Itemset)
    # order is important
    # return items(itemset1) == items(itemset2)

    # order is ignored
    return length(itemset1) == length(itemset2) && itemset1 in itemset2
end

function Base.in(itemset1::Itemset, itemset2::Itemset)
    # naive quadratic search solution is better than the second one (commented)
    # since itemsets are intended to be fairly short (6/7 conjuncts at most).
    return all(item -> item in items(itemset2), items(itemset1))
    # return issubset(Set(itemset1 |> items) in Set(itemset2 |> items))
end

function Base.show(io::IO, itemset::Itemset)
    print(io, "[" * join([syntaxstring(item) for item in itemset], ", ") * "]")
end

"""
    toformula(itemset::Itemset)

Conjunctive normal form of the [`Item`](@ref)s contained in `itemset`.

See also [`Item`](@ref), [`Itemset`](@ref), [`SoleLogics.LeftmostConjunctiveForm`](@ref)
"""
toformula(itemset::Itemset) = itemset |> items |> LeftmostConjunctiveForm

"""
    const Threshold = Float64

Threshold value for meaningfulness measures.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref),
[`lsupport`](@ref).
"""
const Threshold = Float64

"""
    const WorldMask = Vector{Int64}

Vector whose i-th position stores how many times a certain [`MeaningfulnessMeasure`](@ref)
applied on a specific [`Itemset`](@ref)s is true on the i-th world of multiple instances.

If a single instance is considered, then this acts as a bit mask.

For example, if we consider 5 instances, each of which containing 3 worlds, then the worlds
mask of an itemset could be [5,2,0], meaning that the itemset is always true on the first
world of every instance. If we consider the second world, the same itemset is true on it
only on two instances. If we consider the third world, then the itemset is never true.

See also [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
 const WorldMask = Vector{Int64}

"""
    const EnhancedItem = Tuple{Item,Int64,WorldMask}
"""
const EnhancedItem = Tuple{Item,Int64}

"""
    const EnhancedItemset = Tuple{Itemset,Int64}
"""
const EnhancedItemset = Tuple{Itemset,Int64}

itemset(enhitemset::EnhancedItemset) = first(enhitemset)
count(enhitemset::EnhancedItemset) = last(enhitemset)

function Base.convert(
    ::Type{EnhancedItemset},
    itemset::Itemset,
    count::Int64
)
    return EnhancedItemset((itemset, count))
end

function Base.convert(::Type{Itemset}, enhanceditemset::EnhancedItemset)
    return first(enhanceditemset)
end

function Base.show(io::IO, enhanceditemset::EnhancedItemset)
    print(io, "[$(first(enhanceditemset))] : $(last(enhanceditemset))")
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
two [`Itemset`](@ref)s, callend [`antecedent`](@ref) and [`consequent`](@ref), whose
intersection is empty.

Extracting all the [`ARule`](@ref) "hidden" in the data is the main purpose of ARM.

The general framework always followed by ARM techniques is to, firstly, generate all the
frequent itemsets considering a set of [`MeaningfulnessMeasure`](@ref) specifically
tailored to work with [`Itemset`](@ref)s.
Thereafter, all the association rules are generated by testing all the combinations of
frequent itemsets against another set of [`MeaningfulnessMeasure`](@ref), this time
designed to capture how "reliable" a rule is.

See also [`antecedent`](@ref), [`consequent`](@ref), [`gconfidence`](@ref),
[`Itemset`](@ref), [`lconfidence`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
struct ARule
    antecedent::Itemset
    consequent::Itemset

    function ARule(antecedent::Itemset, consequent::Itemset)
        intersection = intersect(antecedent, consequent)
        @assert intersection |> length == 0 "Invalid rule. " *
        "Antecedent and consequent share the following items: $(intersection)."

        new(antecedent, consequent)
    end

    function ARule(doublet::Tuple{Itemset,Itemset})
        ARule(first(doublet), last(doublet))
    end
end

"""
    content(rule::ARule)::Tuple{Itemset,Itemset}

Getter for the content of an [`ARule`](@ref), that is, both its [`antecedent`](@ref) and
its [`consequent`](@ref).

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`Itemset`](@ref).
"""
content(rule::ARule)::Tuple{Itemset,Itemset} = (rule.antecedent, rule.consequent)

"""
    antecedent(rule::ARule)::Itemset

Getter for `rule`'s antecedent.

See also [`antecedent`](@ref), [`ARule`](@ref), [`Itemset`](@ref).
"""
antecedent(rule::ARule)::Itemset = rule.antecedent

"""
    consequent(rule::ARule)::Itemset

Getter for `rule`'s consequent.

See also [`consequent`](@ref), [`ARule`](@ref), [`Itemset`](@ref).
"""
consequent(rule::ARule)::Itemset = rule.consequent

function Base.:(==)(rule1::ARule, rule2::ARule)
    # first antecedent must be included in the second one,
    # same when considering the consequent;
    # if this is true and lengths are the same, then the two parts coincides.
    return length(antecedent(rule1)) == length(antecedent(rule2)) &&
        length(consequent(rule1)) == length(consequent(rule2)) &&
        antecedent(rule1) in antecedent(rule2) &&
        consequent(rule1) in consequent(rule2)
end

function Base.convert(::Type{Itemset}, arule::ARule)::Itemset
    return Itemset(vcat(antecedent(arule), consequent(arule)))
end

function Base.hash(arule::ARule, h::UInt)
    _antecedent = sort(arule |> antecedent |> items)
    _consequent = sort(arule |> consequent |> items)
    return hash(vcat(_antecedent, _consequent), h)
end

function Base.show(
    io::IO,
    arule::ARule;
    variable_names::Union{Nothing,Vector{String}}=nothing
)
    _antecedent = arule |> antecedent |> toformula
    _consequent = arule |> consequent |> toformula

    print(io, "$(syntaxstring(_antecedent, variable_names_map=variable_names)) => " *
        "$(syntaxstring(_consequent, variable_names_map=variable_names))")
end

"""
    const MeaningfulnessMeasure = Tuple{Function, Threshold, Threshold}

In the classic propositional case scenario where each instance of a [`Logiset`](@ref) is
composed of just a single world (it is a propositional interpretation), a meaningfulness
measure is simply a function which measures how many times a property of an
[`Itemset`](@ref) or an [`ARule`](@ref) is respected across all instances of the dataset.

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
const MeaningfulnessMeasure = Tuple{Function,Threshold,Threshold}

"""
    islocalof(::Function, ::Function)::Bool

Twin method of [`isglobalof`](@ref).

Trait to indicate that a local meaningfulness measure is used as subroutine in a global
measure.

For example, `islocalof(lsupport, gsupport)` is `true`, and `isglobalof(gsupport, lsupport)`
is `false`.

!!! warning
    When implementing a custom meaningfulness measure, make sure to implement both traits
    if necessary. This is fundamental to guarantee the correct behavior of some methods,
    such as [`getlocalthreshold`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`isglobalof`](@ref),
[`lsupport`](@ref).
"""
islocalof(::Function, ::Function)::Bool = false

"""
    isglobalof(::Function, ::Function)::Bool

Twin trait of [`islocalof`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`islocalof`](@ref),
[`lsupport`](@ref).
"""
isglobalof(::Function, ::Function)::Bool = false

"""
    localof(::Function)

Return the local measure associated with the given one.

See also [`islocalof`](@ref), [`isglobalof`](@ref), [`globalof`](@ref).
"""
localof(::Function) = nothing

"""
    globalof(::Function) = nothing

Return the global measure associated with the given one.

See also [`islocalof`](@ref), [`isglobalof`](@ref), [`localof`](@ref).
"""
globalof(::Function) = nothing

"""
    ARMSubject = Union{ARule,Itemset}

[Memoizable](https://en.wikipedia.org/wiki/Memoization) types for association rule mining
(ARM).

See also [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref), [`LmeasMemo`](@ref),
[`LmeasMemoKey`](@ref).
"""
const ARMSubject = Union{ARule,Itemset} # memoizable association-rule-mining types

############################################################################################
#### Utility structures ####################################################################
############################################################################################

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
[`Miner`](@ref) objects, and the latter already knows the dataset they are working
with.

See also [`GmeasMemoKey`](@ref), [`ARMSubject`](@ref).
"""
const GmeasMemo = Dict{GmeasMemoKey,Threshold} # global measure of an itemset/arule => value

"""
    const Powerup = Dict{Symbol,Any}

Additional informations associated with an [`ARMSubject`](@ref) that can be used to
specialize a [`Miner`](@ref), augmenting its capabilities.

To understand how to specialize a [`Miner`](@ref), see [`haspowerup`](@ref),
[`initpowerups`](@ref), ['powerups`](@ref), [`powerups!`](@ref).
"""
const Powerup = Dict{Symbol,Any}

"""
    const Info = Dict{Symbol,Any}

Generic setting storage inside [`Miner`](@ref) structures.

See also [`info`](@ref), [`info!`](@ref), [`hasinfo`](@ref), [`Miner`](@ref).
"""
const Info = Dict{Symbol,Any}

############################################################################################
#### Association rule miner machines #######################################################
############################################################################################

"""
    struct Miner{
        D<:AbstractDataset,
        F<:Function,
        I<:Item,
        IM<:MeaningfulnessMeasure,
        RM<:MeaningfulnessMeasure
    }
        X::D                            # target dataset
        algorithm::F                    # algorithm used to perform extraction
        items::Vector{I}

                                        # meaningfulness measures
        item_constrained_measures::Vector{IM}
        rule_constrained_measures::Vector{RM}

        freqitems::Vector{Itemset}      # collected frequent itemsets
        arules::Vector{ARule}           # collected association rules

        lmemo::LmeasMemo                # local memoization structure
        gmemo::GmeasMemo                # global memoization structure

        powerups::Powerup               # mining algorithm powerups (see documentation)
        info::Info                      # general informations
    end

Machine learning model interface to perform association rules extraction.

# Examples
```julia-repl
julia> using ModalAssociationRules
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

# Create an association rule miner wrapping `fpgrowth` algorithm - see [`fpgrowth`](@ref);
# note that meaningfulness measures are not explicited and, thus, are defaulted as in the
# call below.
julia> miner = Miner(X, fpgrowth(), manual_alphabet)

# Create an association rule miner, expliciting global meaningfulness measures with their
# local and global thresholds, both for [`Itemset`](@ref)s and [`ARule`](@ref).
julia> miner = Miner(X, fpgrowth(), manual_alphabet,
    [(gsupport, 0.1, 0.1)], [(gconfidence, 0.2, 0.2)])

# Consider the dataset and learning algorithm wrapped by `miner` (resp., `X` and `fpgrowth`)
# Mine the frequent itemsets, that is, those for which item measures are large enough.
# Then iterate the generator returned by [`mine`](@ref) to enumerate association rules.
julia> for arule in ModalAssociationRules.mine!(miner)
    println(miner)
end
```

See also  [`ARule`](@ref), [`apriori`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Itemset`](@ref), [`GmeasMemo`](@ref), [`LmeasMemo`](@ref).
"""
struct Miner{
    D<:AbstractDataset,
    F<:Function,
    I<:Item,
    IM<:MeaningfulnessMeasure,
    RM<:MeaningfulnessMeasure
}
    # target dataset
    X::D
    # algorithm used to perform extraction
    algorithm::F
    items::Vector{I}

    # meaningfulness measures
    item_constrained_measures::Vector{IM}
    rule_constrained_measures::Vector{RM}

    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    lmemo::LmeasMemo                # local memoization structure
    gmemo::GmeasMemo                # global memoization structure

    powerups::Powerup               # mining algorithm powerups (see documentation)
    info::Info                      # general informations

    function Miner(
        X::D,
        algorithm::F,
        items::Vector{I},
        item_constrained_measures::Vector{IM} = [(gsupport, 0.1, 0.1)],
        rule_constrained_measures::Vector{RM} = [(gconfidence, 0.2, 0.2)];
        info::Info = Info(:istrained => false)
    ) where {
        D<:AbstractDataset,
        F<:Function,
        I<:Item,
        IM<:MeaningfulnessMeasure,
        RM<:MeaningfulnessMeasure
    }
        # dataset frames must be equal
        @assert allequal([SoleLogics.frame(X, i_instance)
            for i_instance in 1:ninstances(X)]) "Instances frame is shaped differently. " *
            "Please, provide an uniform dataset to guarantee mining correctness."

        # gsupport is indispensable to mine association rule
        @assert ModalAssociationRules.gsupport in reduce(
            vcat, item_constrained_measures) "Miner requires global support " *
            "(gsupport) as meaningfulness measure in order to work properly. " *
            "Please, add a tuple (gsupport, local support threshold, global support " *
            "threshold) to item_constrained_measures field.\n" *
            "Local support (lsupport) is needed too, but it is already considered " *
            "internally by gsupport."

        powerups = initpowerups(algorithm, X)

        new{D,F,I,IM,RM}(X, algorithm, unique(items),
            item_constrained_measures, rule_constrained_measures,
            Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), powerups, info
        )
    end
end

"""
    dataset(miner::Miner)::AbstractDataset

Getter for the dataset wrapped by `miner`s.

See [`SoleBase.AbstractDataset`](@ref), [`Miner`](@ref).
"""
dataset(miner::Miner)::AbstractDataset = miner.X

"""
    algorithm(miner::Miner)::Function

Getter for the mining algorithm loaded into `miner`.

See [`Miner`](@ref).
"""
algorithm(miner::Miner)::Function = miner.algorithm

"""
    items(miner::Miner)

Getter for the items of [`Item`](@ref)s loaded into `miner`.

See [`Item`](@ref), [`Miner`](@ref).
"""
items(miner::Miner) = miner.items

"""
    itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

Return the [`MeaningfulnessMeasure`](@ref)s tailored to work with [`Itemset`](@ref)s,
loaded inside `miner`.

See  [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref), [`Miner`](@ref).
"""
itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
    miner.item_constrained_measures

"""
    additemmeas(miner::Miner, measure::MeaningfulnessMeasure)

Add a new `measure` to `miner`'s [`itemsetmeasures`](@ref).

See also [`addrulemeas`](@ref), [`Miner`](@ref), [`rulemeasures`](@ref).
"""
function additemmeas(miner::Miner, measure::MeaningfulnessMeasure)
    @assert measure in first.(itemsetmeasures(miner)) "Miner already contains $(measure)."
    push!(itemsetmeasures(miner), measure)
end

"""
    rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

Return the [`MeaningfulnessMeasure`](@ref)s tailored to work with [`ARule`](@ref)s, loaded
inside `miner`.

See [`Miner`](@ref), [`ARule`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
    miner.rule_constrained_measures

"""
    addrulemeas(miner::Miner, measure::MeaningfulnessMeasure)

Add a new `measure` to `miner`'s [`rulemeasures`](@ref).

See also [`itemsetmeasures`](@ref), [`Miner`](@ref), [`rulemeasures`](@ref).
"""
function addrulemeas(miner::Miner, measure::MeaningfulnessMeasure)
    @assert measure in first.(rulemeasures(miner)) "Miner already contains $(measure)."
    push!(rulemeasures(miner), measure)
end

"""
    measures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

Return all the [`MeaningfulnessMeasures`](@ref) wrapped by `miner`.

See also [`MeaningfulnessMeasure`](@ref), [`Miner`](@ref).
"""
function measures(miner::Miner)::Vector{<:MeaningfulnessMeasure}
    return vcat(itemsetmeasures(miner), rulemeasures(miner))
end

"""
    findmeasure(
        miner::Miner,
        meas::Function;
        recognizer::Function=islocalof
    )::MeaningfulnessMeasure

Retrieve the [`MeaningfulnessMeasure`](@ref) associated with `meas`.

See also [`isglobalof`](@ref), [`islocalof`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Miner`](@ref).
"""
function findmeasure(
    miner::Miner,
    meas::Function;
    recognizer::Function=islocalof
)::MeaningfulnessMeasure
    try
        return Iterators.filter(
            m -> first(m)==meas || recognizer(meas, first(m)), measures(miner)) |> first
    catch e
        if isa(e, ArgumentError)
            error("The provided miner has no measure $meas. " *
            "Maybe the miner is not initialized properly, and $meas is omitted. " *
            "Please use itemsetmeasures/rulemeasures to check which measures are , " *
            "available and miner's setters to add a new measures and their thresholds.")
        else
            rethrow(e)
        end
    end
end

"""
    getlocalthreshold(miner::Miner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work locally (that is, analyzing "the inside"
of a dataset's instances) in `miner`.

See [`Miner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
function getlocalthreshold(miner::Miner, meas::Function)::Threshold
    return findmeasure(miner, meas)[2]
end

"""
    getglobalthreshold(miner::Miner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work globally (that is, measuring the behavior
of a specific local-measure across all dataset's instances) in `miner`.

See [`Miner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
function getglobalthreshold(miner::Miner, meas::Function)::Threshold
    return findmeasure(miner, meas) |> last
end

"""
    freqitems(miner::Miner)

Return all frequent [`Itemset`](@ref)s mined by `miner`.

See also [`Itemset`](@ref), [`Miner`](@ref).
"""
freqitems(miner::Miner) = miner.freqitems

"""
    arules(miner::Miner)

Return all the [`ARule`](@ref)s mined by `miner`.

See also [`ARule`](@ref), [`Miner`](@ref).
"""
arules(miner::Miner) = miner.arules

"""
    localmemo(miner::Miner)::LmeasMemo
    localmemo(miner::Miner, key::LmeasMemoKey)

Return the local memoization structure inside `miner`, or a specific entry if a
[`LmeasMemoKey`](@ref) is provided.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo(miner::Miner)::LmeasMemo = miner.lmemo
localmemo(miner::Miner, key::LmeasMemoKey) = get(miner.lmemo, key, nothing)

"""
    localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by `miner`.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
function localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)
    miner.lmemo[key] = val
end

"""
    globalmemo(miner::Miner)::GmeasMemo
    globalmemo(miner::Miner, key::GmeasMemoKey)

Return the global memoization structure inside `miner`, or a specific entry if a
[`GmeasMemoKey`](@ref) is provided.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo(miner::Miner)::GmeasMemo = miner.gmemo
globalmemo(miner::Miner, key::GmeasMemoKey) = get(miner.gmemo, key, nothing)

"""
    globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the global memoization structure wrapped by
`miner`.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold) = miner.gmemo[key] = val

############################################################################################
#### Miner machines specializations ########################################################
############################################################################################

"""
    powerups(miner::Miner)::Powerup
    powerups(miner::Miner, key::Symbol)

Getter for the entire powerups structure currently loaded in `miner`, or a specific powerup.

See also [`haspowerup`](@ref), [`initpowerups`](@ref), [`Miner`](@ref), [`Powerup`](@ref).
"""
powerups(miner::Miner)::Powerup = miner.powerups
powerups(miner::Miner, key::Symbol) = miner.powerups[key]

"""
    powerups!(miner::Miner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`powerups`](@ref).

See also [`haspowerup`](@ref), [`initpowerups`](@ref), [`Miner`](@ref), [`Powerup`](@ref).
"""
powerups!(miner::Miner, key::Symbol, val) = miner.powerups[key] = val

"""
    haspowerup(miner::Miner, key::Symbol)

Return whether `miner` powerups field contains an entry `key`.

See also [`Miner`](@ref), [`Powerup`](@ref), [`powerups`](@ref).
"""
haspowerup(miner::Miner, key::Symbol) = haskey(miner |> powerups, key)

"""
    initpowerups(::Function, ::AbstractDataset)

This defines how [`Miner`](@ref)'s `powerup` field is filled to optimize the mining.
"""
initpowerups(::Function, ::AbstractDataset)::Powerup = Powerup()

"""
    info(miner::Miner)::Powerup
    info(miner::Miner, key::Symbol)

Getter for the entire additional informations field inside a `miner`, or one of its specific
entries.

See also [`Miner`](@ref), [`Powerup`](@ref).
"""
info(miner::Miner)::Powerup = miner.info
info(miner::Miner, key::Symbol) = miner.info[key]

"""
    info!(miner::Miner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`info`](@ref).

See also [`hasinfo`](@ref), [`info`](@ref), [`Miner`](@ref).
"""
info!(miner::Miner, key::Symbol, val) = miner.info[key] = val

"""
    hasinfo(miner::Miner, key::Symbol)

Return whether `miner` additional informations field contains an entry `key`.

See also [`Miner`](@ref).
"""
hasinfo(miner::Miner, key::Symbol) = haskey(miner |> info, key)

"""
    mine!(miner::Miner)

Synonym for `ModalAssociationRules.apply!(miner, dataset(miner))`.

See also [`ARule`](@ref), [`Itemset`](@ref), [`ModalAssociationRules.apply`](@ref).
"""
function mine!(miner::Miner; kwargs...)
    return apply!(miner, dataset(miner); kwargs...)
end

"""
    apply!(miner::Miner, X::AbstractDataset)

Extract association rules in the dataset referenced by `miner`, saving the interesting
[`Itemset`](@ref)s inside `miner`.
Then, return a generator of [`ARule`](@ref)s.

See also [`ARule`](@ref), [`Itemset`](@ref).
"""
function apply!(miner::Miner, X::AbstractDataset; forcemining::Bool=false, kwargs...)
    istrained = info(miner, :istrained)
    if istrained && !forcemining
        @warn "Miner has already been trained. To force mining, set `forcemining=true`."
        return Nothing
    end

    miner.algorithm(miner, X; kwargs...)
    info!(miner, :istrained, true)

    return arules_generator(freqitems(miner), miner)
end

"""
    generaterules!(miner::Miner; kwargs...)

Return a generator of [`ARule`](@ref)s, given an already trained [`Miner`](@ref).

See also [`ARule`](@ref), [`Miner`](@ref).
"""
function generaterules!(miner::Miner)
    if !info(miner, :istrained)
        error("Miner should be trained before generating rules. Please, invoke `mine!`.")
    end

    return arules_generator(freqitems(miner), miner)
end

function Base.show(io::IO, miner::Miner)
    println(io, "$(dataset(miner))")

    println(io, "Alphabet: $(items(miner))\n")
    println(io, "Items measures: $(itemsetmeasures(miner))")
    println(io, "Rules measures: $(rulemeasures(miner))\n")

    println(io, "# of frequent patterns mined: $(length(freqitems(miner)))")
    println(io, "# of association rules mined: $(length(arules(miner)))\n")

    println(io, "Local measures memoization structure entries: " *
        "$(length(miner.lmemo |> keys))")
    println(io, "Global measures memoization structure entries: " *
        "$(length(miner.gmemo |> keys))\n")

    print(io, "Additional infos: $(info(miner) |> keys)\n")
    print(io, "Specialization fields: $(powerups(miner) |> keys)")
end

"""
    analyze(arule::ARule, miner::Miner; io::IO=stdout, localities=false)

Print an [`ARule`](@ref) analysis to the console, including related meaningfulness measures
values.

See also [`ARule`](@ref), [`Miner`](@ref).
"""
function analyze(
    arule::ARule,
    miner::Miner;
    io::IO=stdout,
    localities::Bool=false,
    variable_names::Union{Nothing,Vector{String}}=nothing
)
    Base.show(io, arule; variable_names=variable_names)
    println(io, "")

    for measure in rulemeasures(miner)
        # prepare (global) measure name, and its Symbol casting
        gmeas = measure[1]
        gmeassym = gmeas |> Symbol

        # find local measure (its name, as Symbol) associated with the global measure
        lmeassym = ModalAssociationRules.localof(gmeas) |> Symbol

        println(io, "$(gmeassym): $(globalmemo(miner, (gmeassym, arule)))")
        if localities
            for i in 1:ninstances(miner |> dataset)
                print(io, "$(lmeassym): $(localmemo(miner, (lmeassym, arule, i))) ")
            end
            println(io, "")
        end
    end

    println(io, "")
end

############################################################################################
#### Dataset utilities #####################################################################
############################################################################################

function SoleLogics.frame(miner::Miner)
    return SoleLogics.frame(dataset(miner), 1)
end

function SoleLogics.allworlds(miner::Miner)
    return frame(miner) |> SoleLogics.allworlds
end

function SoleLogics.nworlds(miner::Miner)
    return frame(miner) |> SoleLogics.nworlds
end
