"""
    abstract type AbstractItem end

Generic encoding for a fact.

See also [`Item`](@ref).
"""
abstract type AbstractItem end

"""
    struct Item{F<:SoleLogics.Formula}
        formula::F
    end

Fundamental type in the context of
[association rule mining](https://en.wikipedia.org/wiki/Association_rule_learning).

The name [`Item`](@ref) comes from the classical association rule mining jargon,
but it is simply a wrapper around a logical formula, whose truth value can be checked on a
model. To know more about logical formulas, see
[SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).

See also [`ARule`](@ref), [`gconfidence`](@ref), [`Itemset`](@ref),
[`MeaningfulnessMeasure`](@ref), [SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).
"""
struct Item{F<:SoleLogics.Formula} <: AbstractItem
    formula::F

    function Item(formula::F) where {F<:SoleLogics.Formula}
        return new{F}(formula)
    end
end

function Base.convert(::Type{Item}, formula::SoleLogics.Formula)::Item
    return Item(formula)
end

"""
    formula(item::Item{F}) where {F}

See also [`Item`](@ref), [SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).
"""
formula(item::Item{F}) where {F<:SoleLogics.Formula} = item.formula

function Base.isless(a::Item, b::Item)
    isless(hash(a), hash(b))
end

function Base.show(io::IO, item::Item)
    print(io, syntaxstring(item.formula))
end

"""
    feature(item::Item)::VarFeature

Utility to extract the feature wrapped within an [`Item`](@ref).

See also [`Item`](@ref), `SoleData.VarFeature`, `SoleData.AbstractUnivariateFeature`.
"""
function feature(item::Item)
    # temporary variable holding the intermediate steps of item's manipulation
    _intermediate = item |> formula

    # _intermediate could be <A>(Feature) or <A><A>(Feature) and so on.
    while _intermediate isa SoleLogics.SyntaxBranch
        _intermediate = _intermediate |> SoleLogics.children |> first
    end

    return _intermediate |> SoleData.value |> SoleData.metacond |> SoleData.feature
end

"""
TODO: refine docstring
"""
const ItemCollection{N,I} = Ref{SVector{N,I}} where {N,I<:AbstractItem}

############################################################################################

"""
TODO: refine docstring

    abstract type AbstractItemset end

Generic encoding for a set of facts.

See also [`Itemset`](@ref).
"""
abstract type AbstractItemset end

"""
TODO: refine docstring

Suppose U isa UInt64; then, mask[1] encodes is a bit mask over the first 64 elements of
an [`Item`](@ref) collection; mask[2] encodes the range [65,128] and so on.
"""
struct SmallItemset{N,U<:Unsigned} <: AbstractItemset
    mask::SVector{N,U}

    function SmallItemset(mask::U) where {U}
        new{1,U}(SVector{1,U}(mask))
    end

    function SmallItemset(svec::SVector{N,U}) where {N,U<:Unsigned}
        new{N,U}(svec)
    end
end

mask(si::SmallItemset) = si.mask

Base.length(si::SmallItemset) = begin
    si |> mask .|> Base.count_ones |> sum
end

targetfxs = [Base.intersect, Base.union, Base.isequal, Base.:(==)]
for f in targetfxs
    fname = Symbol(f)
    @eval import Base: $fname
    @eval begin
        function ($fname)(
            it1::SmallItemset{N,U},
            it2::SmallItemset{N,U}
        ) where {N,U<:Unsigned}
            zip(it1 |> mask, it2 |> mask) .|> ($f)
        end
    end
    @eval export $fname
end

"""
TODO: refine docstring

Split the item collection into chunks, depending on the size of U.
Then, for each chunk, mask the corresponding items.

# Examples
```julia
julia> myitemset = SmallItemset(SVector{2}([UInt64(5), UInt64(1)]) )
julia> myitemcollection = ItemCollection{300,Item}(Item[
    Atom(ScalarCondition(VariableMin(i), >, -1.0))
    for i in 1:300
])
julia> applymask(myitemset, myitemcollection)
```
"""
function applymask(
    si::SmallItemset{N,U},
    ic::ItemCollection{M,I}
) where {N,M,U<:Unsigned,I<:AbstractItem}
    masks = mask(si)

    # the item collection can be divided into chunks, possibly encoding U binary masks
    chunksize = U(1 << sizeof(U))
    chunks = Iterators.partition(ic[], chunksize)

    # precompute total items to allocate output
    totitems = sum(count_ones.(masks))
    # unfortunately, totitems is unknown at compile time
    result = Vector{Item}(undef, totitems)
    pos = 1

    @inbounds for (ithmask, chunk) in zip(masks, chunks)
        copymask = ithmask

        while copymask != 0
            j = trailing_zeros(copymask) + 1

            result[pos] = chunk[j]
            pos += 1

            copymask &= copymask-1
        end
    end

    return result
end

"""
    const Itemset{I<:Item} = Vector{I}

Vector collecting multiple [`Item`](@ref)s.

Semantically, [`Itemset`](@ref)s represent [`Item`](@ref)s (that is, formulas) conjunctions.

!!! note
    In the context of association rule mining, *interesting* itemsets are manipulated to
    discover *interesting* relations between [`Item`](@ref)s, in the form of association
    rules ([ARule](@ref)).

    Interestingness is established through a set of [`MeaningfulnessMeasure`](@ref).

!!! details
    Itemsets are implemented as a vector for two reasons:

    1. [lookup is faster](https://www.juliabloggers.com/set-vs-vector-lookup-in-julia-a-closer-look/)
        when the collection is small (an itemset is unlikely to consist of more than 100
        items);

    2. most of the time, we want to keep an ordering between items while searching for
        interesting itemsets.

# Examples
```julia
julia> p = ScalarCondition(VariableMin(1), >, 1.0)  |> Atom |> Item
min[V1] > 1.0
julia> q = ScalarCondition(VariableMin(2), >=, 0.0) |> Atom |> Item
min[V2] ≥ 0.0

julia> pq = Itemset([p,q])
julia> qp = Itemset([q,p])

julia> pq == qp
true
julia> pq === qp
false

julia> r = ScalarCondition(VariableMax(3), <=, 2.0) |> Atom |> Item
max[V3] ≤ 2.0
julia> pqr = [pq; r];

julia> pq in pqr
true

julia> formula(pqr) |> syntaxstring
"(min[V1] > 1.0) ∧ (min[V2] ≥ 0.0) ∧ (max[V3] ≤ 2.0)"
```

See also [`ARule`](@ref), [`formula`](@ref), [`gsupport`](@ref), [`Item`](@ref),
[`lsupport`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const Itemset{I<:Item} = Vector{I}

Itemset() = Itemset{Item}()
Itemset{I}() where {I<:Item} = I[]
Itemset{I}(item::Item) where {I<:Item} = I[item]

Itemset(f::SoleLogics.Formula) = Itemset{Item}(Item(f))
Itemset(item::Item) = Itemset{typeof(item)}(item)
Itemset(items::Vector{I}) where {I<:Item} = Itemset{I}(items)

function Base.convert(::Type{Itemset}, item::Item)
    return Itemset{typeof(item)}(item)
end

function Base.:(==)(itemset1::Itemset, itemset2::Itemset)
    # order is important
    # return items(itemset1) == items(itemset2)

    # order is ignored
    # TODO test using ⊂ instead of in
    return length(itemset1) == length(itemset2) && itemset1 in itemset2
end

function Base.in(itemset1::Itemset, itemset2::Itemset)
    # naive quadratic search solution is better than the second one (commented)
    # since itemsets are intended to be fairly short (6/7 conjuncts at most).
    return all(item -> item in itemset2, itemset1)
    # return issubset(Set(itemset1) in Set(itemset2))
end

function Base.show(io::IO, itemset::Itemset)
    print(io, "[" * join([syntaxstring(item) for item in itemset], ", ") * "]")
end

"""
    formula(itemset::Itemset)::SoleLogics.LeftmostConjunctiveForm

Conjunctive normal form of the [`Item`](@ref)s contained in `itemset`.

See also [`Item`](@ref), [`Itemset`](@ref),
[`SoleLogics.LeftmostConjunctiveForm`](https://aclai-lab.github.io/SoleLogics.jl/stable/more-on-formulas/#SoleLogics.LeftmostConjunctiveForm)
"""
formula(itemset::Itemset)::SoleLogics.LeftmostConjunctiveForm = begin
    formula.(itemset) |> LeftmostConjunctiveForm
end

"""
    const ARule = Tuple{Itemset,Itemset}

An association rule represents a *frequent* and *meaningful* co-occurrence relationship of
the form "X ⇒ Y", between two [`Itemset`](@ref)s X and Y, where X ∩ Y = ∅, respectively
called [`antecedent`](@ref) and [`consequent`](@ref).

!!! note
    Extracting all the [`ARule`](@ref) "hidden" in the data is the main purpose of
    association rule mining (ARM).

    Given an itemset Z containing atleast two [`Item`](@ref)s (|Z| ≥ 2), it can be
    partitioned in two (sub)itemsets X and Y; trying all the possible binary partitioning
    of Z is a systematic way to generate [`ARule`](@ref)s.

    The general framework always followed by ARM techniques is to, firstly, generate all the
    frequent itemsets considering a set of [`MeaningfulnessMeasure`](@ref) specifically
    tailored to work with [`Itemset`](@ref)s.

    Thereafter, all the association rules are generated by testing all the combinations of
    frequent itemsets against another set of [`MeaningfulnessMeasure`](@ref), this time
    designed to capture how interesting a rule is.

See also [`antecedent`](@ref), [`consequent`](@ref), [`gconfidence`](@ref),
[`Itemset`](@ref), [`lconfidence`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
struct ARule
    antecedent::Itemset
    consequent::Itemset

    function ARule(antecedent::Itemset, consequent::Itemset)
        intersection = intersect(antecedent, consequent)
        if !(intersection |> length == 0)
            throw(ArgumentError("Invalid rule. " *
                "Antecedent and consequent share the following items: $(intersection)."
            ))
        end

        new(antecedent, consequent)
    end

    function ARule(doublet::Tuple{Itemset,Itemset})
        ARule(first(doublet), last(doublet))
    end
end

Itemset(rule::ARule) = convert(Itemset, rule)

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

"""
    function Base.:(==)(rule1::ARule, rule2::ARule)

Antecedent (consequent) [`Item`](@ref)s ordering could be different between the two
[`ARule`](@ref), but they are essentially the same rule.

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref).
"""
function Base.:(==)(rule1::ARule, rule2::ARule)
    # first antecedent must be included in the second one,
    # same when considering the consequent;
    # if this is true and lengths are the same, then the two parts coincides.
    return length(antecedent(rule1)) == length(antecedent(rule2)) &&
        length(consequent(rule1)) == length(consequent(rule2)) &&
        antecedent(rule1) in antecedent(rule2) &&
        consequent(rule1) in consequent(rule2)
end

"""
    function Base.convert(::Type{Itemset}, arule::ARule)::Itemset

Convert an [`ARule`](@ref) to an [`Itemset`](@ref) by merging its [`antecedent`](@ref)
and consequent [`consequent`](@ref).

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`Itemset`](@ref).
"""
function Base.convert(::Type{Itemset}, arule::ARule)::Itemset
    return Itemset(vcat(antecedent(arule), consequent(arule)))
end

function Base.hash(arule::ARule, h::UInt)
    _antecedent = sort(arule |> antecedent)
    _consequent = sort(arule |> consequent)
    return hash(vcat(_antecedent, _consequent), h)
end

function Base.show(
    io::IO,
    arule::ARule;
    variablenames::Union{Nothing,Vector{String}}=nothing
)
    _antecedent = arule |> antecedent |> formula
    _consequent = arule |> consequent |> formula

    print(io, "$(syntaxstring(_antecedent, variable_names_map=variablenames)) => " *
        "$(syntaxstring(_consequent, variable_names_map=variablenames))")
end

"""
    ARMSubject = Union{ARule,Itemset}

Each entity mined through an association rule mining algorithm.

See also [`ARule`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref), [`Itemset`](@ref),
[`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
const ARMSubject = Union{ARule,Itemset}



"""
    const Threshold = Float64

Threshold value type for [`MeaningfulnessMeasure`](@ref)s.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref),
[`lsupport`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const Threshold = Float64

"""
    const MeaningfulnessMeasure = Tuple{Function, Threshold, Threshold}

To fully understand this description, we suggest reading
[this article](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf).

In the classic propositional case scenario, we can think each instance as a propositional
interpretation, or equivalently, as a Kripke frame containing only one world.
In this setting, a meaningfulness measure indicates how many times a specific property of
an [`Itemset`](@ref) (or an [`ARule`](@ref)) is satisfied.

The most important meaningfulness measure is *support*, defined as "the number of instances
in a dataset that satisfy an itemset" (it is defined similarly for association rules,
where we consider the itemset obtained by combining both rule's antecedent and consequent).
Other meaningfulness measures can be defined in function of support.

In the context of modal logic, where the instances of a dataset are relational objects
called Kripke frames, every meaningfulness measure must capture two aspects: how much an
[`Itemset`](@ref) or an [`ARule`](@ref) is meaningful *within an instance*, and how much the
same object is meaningful *across all the instances*, that is, how many times it resulted
meaningful within an instance. Note that those two aspects coincide in the propositional
scenario.

When a meaningfulness measure is applied locally within an instance, it is said to be
"local". Otherwise, it is said to be "global".
For example, local support is defined as "the number of worlds within an instance, which
satisfy an itemset".
To define global support we need to define a *minimum local support threshold* sl which is
a real number between 0 and 1. Now, we can say that global support is "the number of
instances for which local support overpassed the minimum local support threshold".

As in the propositional setting, more meaningfulness measures can be defined starting from
support, but now they must respect the local/global dichotomy.

We now have all the ingredients to understand this type definition.
A [`MeaningfulnessMeasure`](@ref) is a tuple composed of a global meaningfulness
measure, a local threshold used internally, and a global threshold we would like our
itemsets (rules) to overpass.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lsupport`](@ref),
[`lconfidence`](@ref).
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
    When implementing a custom meaningfulness measure, make sure to implement both
    [`islocalof`](@ref)/[`isglobalof`](@ref) and [`localof`](@ref)/[`globalof`](@ref).
    This is fundamental to guarantee the correct behavior of some methods, such as
    [`getlocalthreshold`](@ref).
    Alternatively, you can simply use the macro [`@linkmeas`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`isglobalof`](@ref),
[`linkmeas`](@ref), [`lsupport`](@ref).
"""
islocalof(::Function, ::Function)::Bool = false

"""
    isglobalof(::Function, ::Function)::Bool

Twin trait of [`islocalof`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`islocalof`](@ref),
[`linkmeas`](@ref), [`lsupport`](@ref).
"""
isglobalof(::Function, ::Function)::Bool = false

"""
    localof(::Function)::Union{Nothing,MeaningfulnessMeasure}

Return the local measure associated with the given one.

See also [`islocalof`](@ref), [`isglobalof`](@ref), [`globalof`](@ref), [`linkmeas`](@ref).
"""
localof(::Function) = nothing

"""
    globalof(::Function)::Union{Nothing,MeaningfulnessMeasure} = nothing

Return the global measure associated with the given one.

See also [`linkmeas`](@ref), [`islocalof`](@ref), [`isglobalof`](@ref), [`localof`](@ref).
"""
globalof(::Function) = nothing

"""
    const WorldMask = BitVector

Bitmask whose i-th position stores whether a certain (local) [`MeaningfulnessMeasure`](@ref)
applied on a specific [`Itemset`](@ref)s is true on the i-th world of a data instance.

The term "world" comes from the fact that a data instance is expressed as an entity-relation
object, such as a `SoleLogics.KripkeStructure`.

See also [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const WorldMask = BitVector

# utility structures

"""
    const LmeasMemoKey = Tuple{Symbol,ARMSubject,Integer}

Key of a [`LmeasMemo`](@ref) dictionary.
Represents a local meaningfulness measure name (as a `Symbol`), a [`ARMSubject`](@ref),
and the number of a dataset instance where the measure is applied.

See also [`ARMSubject`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref),
[`lconfidence`](@ref).
"""
const LmeasMemoKey = Tuple{Symbol,ARMSubject,Integer}

"""
    const LmeasMemo = Dict{LmeasMemoKey,Threshold}

Association between a local measure of a [`ARMSubject`](@ref) on a specific dataset
instance, and its value.

See also [`ARMSubject`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref),
[`lconfidence`](@ref).
"""
const LmeasMemo = Dict{LmeasMemoKey,Threshold}

"""
    const GmeasMemoKey = Tuple{Symbol,ARMSubject}

Key of a [`GmeasMemo`](@ref) dictionary.
Represents a global meaningfulness measure name (as a `Symbol`) and a [`ARMSubject`](@ref).

See also [`ARMSubject`](@ref), [`GmeasMemo`](@ref), [`gconfidence`](@ref),
[`gsupport`](@ref).
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
    const MiningState = Dict{Symbol,Any}

Additional informations associated with an [`ARMSubject`](@ref) that can be used to
specialize any concrete type deriving from [`AbstractMiner`](@ref), thus augmenting its
capabilities.

To understand how to specialize a [`Miner`](@ref), see [`hasminingstate`](@ref),
[`initminingstate`](@ref), ['miningstate`](@ref), [`miningstate!`](@ref).
"""
const MiningState = Dict{Symbol,Any}

"""
    const Info = Dict{Symbol,Any}

Storage reserved to metadata about mining (e.g., execution time).

See also [`info`](@ref), [`info!`](@ref), [`hasinfo`](@ref), [`Miner`](@ref).
"""
const Info = Dict{Symbol,Any}

"""
    const MineableData = AbstractDataset

Any type on which mining can be performed.

See also [`Miner`](@info).
"""
const MineableData = AbstractDataset

"""
    initminingstate(::Function, ::MineableData)

This trait defines how to initialize the [`MiningState`](@ref) structure of an
[`AbstractMiner`](@ref), in order to customize it to your needings depending on a specific
function/data pairing.

See ealso [`hasminingstate`](@ref), [`AbstractMiner`](@ref), [`MiningState`](@ref),
[`miningstate`](@ref).
"""
initminingstate(::Function, ::MineableData)::MiningState = MiningState()
