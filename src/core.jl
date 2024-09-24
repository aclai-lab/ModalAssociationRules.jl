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
    variablenames::Union{Nothing,Vector{String}}=nothing
)
    _antecedent = arule |> antecedent |> toformula
    _consequent = arule |> consequent |> toformula

    print(io, "$(syntaxstring(_antecedent, variable_names_map=variablenames)) => " *
        "$(syntaxstring(_consequent, variable_names_map=variablenames))")
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

Essentially, this is a tool you can use to to store information to be considered global
within the miner.

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

"""
    const MineableData = MineableData

Any type on which mining can be performed.

See also [`Miner`](@info).
"""
const MineableData = AbstractDataset

"""
This abstract type is intended to identify any entity with a primary structural role during
mining.

See also [`Miner`](@ref), [`Bulldozer`](@ref).
"""
abstract type AbstractMiner end
