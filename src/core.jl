import Base.==, Base.hash

"""
Any entity capable of perform association rule mining.

# Interface

Each new concrete miner structure must define the following getters and setters.
Actually, depending on its purposes, a structure may partially implement these dispatches.
For example, [`Miner`](@ref) does completely implement the interface while
[`Bulldozer`](@ref) does not.

- data(miner::AbstractMiner)
- items(miner::AbstractMiner)
- algorithm(miner::AbstractMiner)

- freqitems(miner::AbstractMiner)
- arules(miner::AbstractMiner)

- itemsetmeasures(miner::AbstractMiner)
- arulemeasures(miner::AbstractMiner)

- localmemo(miner::AbstractMiner)
- localmemo!(miner::AbstractMiner)
- globalmemo(miner::AbstractMiner)
- globalmemo!(miner::AbstractMiner)

- worldfilter(miner::AbstractMiner)
- itemset_policies(miner::AbstractMiner)
- arule_policies(miner::AbstractMiner)

- miningstate(miner::AbstractMiner)
- miningstate!(miner::AbstractMiner)
- info(miner::AbstractMiner)

See also [`Miner`](@ref), [`Bulldozer`](@ref).
"""
abstract type AbstractMiner end


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

    function SmallItemset(v::Vector{T}) where {T}
        lv = length(v)
        new{lv,T}(SVector{lv,T}(v))
    end

    function SmallItemset{N,U}(args...) where {N,U}
        new{N,U}(args...)
    end

    function SmallItemset(svec::SVector{N,U}) where {N,U<:Unsigned}
        new{N,U}(svec)
    end

    # make a SmallItemset embodying enough bits to cover the items within miner
    function SmallItemset(miner::AbstractMiner; prec::Type{<:Unsigned}=UInt64)
        itemslength = miner |> items |> length

        # number of integers to be wrapped within the constructed SmallItemset
        sveclength = (itemslength/(sizeof(prec)*8)) |> ceil |> Int64

        # each mask in the constructed SmallItemset is going to be empty
        new{sveclength, prec}(SVector{sveclength, prec}(repeat([prec(0)], prec)))
    end
end

mask(si::SmallItemset) = si.mask

Base.length(si::SmallItemset) = begin
    si |> mask .|> Base.count_ones |> sum
end

function Base.intersect(s1::SmallItemset{N,U}, s2::SmallItemset{N,U}) where {N,U}
    return SmallItemset(mask(s1) .& mask(s2))
end

function Base.union(s1::SmallItemset{N,U}, s2::SmallItemset{N,U}) where {N,U}
    return SmallItemset(mask(s1) .| mask(s2))
end

function diff(s1::SmallItemset{N,U}, s2::SmallItemset{N,U}) where {N,U}
    return SmallItemset(mask(s1) .⊻ mask(s2))
end

function Base.isequal(s1::SmallItemset{N,U}, s2::SmallItemset{N,U}) where {N,U}
    return s1 == s2
end

function ==(s1::SmallItemset{N,U}, s2::SmallItemset{N,U}) where {N,U}
    m1 = mask(s1)
    m2 = mask(s2)
    acc = zero(eltype(m1))

    @inbounds for i in eachindex(m1)
        acc |= m1[i] ⊻ m2[i]
    end

    return acc == 0
end

"""
Broadcast `Base.count_ones` on all the masks wrapped by a [`SmallItemset`](@ref).
"""
function Base.count_ones(si::SmallItemset{N,U}) where {N,U}
    return si |> mask .|> count_ones |> sum
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
applymask(
    itemset::SmallItemset{N,U},
    miner::A
) where {N,U,A<:AbstractMiner} = applymask(itemset, items(miner) |> Ref)

"""
TODO: refine docstring

Generate a [`SmallItemset`](@ref) for each item in `miner`. If the items are 3, for example,
then the masks of the 3 result SmallItemset are 001, 010, 100.
"""
function itemsetpopulation(miner::AbstractMiner; prec::Type{<:Unsigned}=UInt64)
    itemslength = miner |> items |> length
    bitsinmask = sizeof(prec)*8 # how many bits are there in a mask
    sveclength = (itemslength/bitsinmask) |> ceil |> Int64

    result = SVector{sveclength,prec}[]

    # each item in miner is represented by a binary number, with all 0 but one
    _selector = 1 # which chunk of a SVector should contain the only 1?
    _values = zeros(prec, sveclength)
    for i in 1:itemslength
        val = prec(1)

        if i % (bitsinmask+1) == 0
            _selector += 1
        else
            val <<= ((i-1) - (_selector-1)*bitsinmask) # avoid recomputing modulo
        end

        # update, push and reset the values buffer
        _values[_selector] = val
        push!(result, SVector{sveclength,prec}(_values))
        _values[_selector] = prec(0)
    end

    return SmallItemset.(result)
end

"""
Compute the powerset of one (or many) unsigned integers, encoding a bitmask (or bitmasks
embodying multiple words).

# Examples
julia> bitpowerset(UInt64(7))
8-element SVector{8, UInt64} with indices SOneTo(8):
 0x0000000000000000
 0x0000000000000001
 0x0000000000000002
 0x0000000000000003
 0x0000000000000004
 0x0000000000000005
 0x0000000000000006
 0x0000000000000007
"""
function bitpowerset(si::SmallItemset{N,U}) where {N,U<:Unsigned}
    return Iterators.product((si |> mask .|> bitpowerset)...)
end
function bitpowerset(x::U) where {U<:Unsigned}
    n = count_ones(x)
    indices = findall(b -> b == 1, digits(x, base=2))
    result = U[]

    for _mask in 0:(U(1) << n)-1
        subset = U(0)
        for i in 1:n
            if (_mask >> (i-1)) & 1 == 1
                subset |= U(1) << (indices[i]-1)
            end
        end
        push!(result, subset)
    end

    return SVector{length(result),U}(result)
end

##### Itemset definition ###################################################################

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
struct ARule{IT<:AbstractItemset}
    antecedent::IT
    consequent::IT

    function ARule(antecedent::IT, consequent::IT) where {IT<:AbstractItemset}
        intersection = intersect(antecedent, consequent)
        if !(intersection |> length == 0)
            throw(ArgumentError("Invalid rule. " *
                "Antecedent and consequent share the following items: $(intersection)."
            ))
        end

        new{IT}(antecedent, consequent)
    end

    function ARule(doublet::Tuple{IT,IT}) where {IT<:AbstractItemset}
        ARule(first(doublet), last(doublet))
    end
end

function applymask(rule::ARule, miner::AbstractMiner)
    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    return Itemset(
        applymask(_antecedent |> mask, miner),
        applymask(_consequent |> mask, miner)
    )
end

SmallItemset(rule::ARule) = convert(SmallItemset, rule)
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
antecedent(rule::ARule{IT}) where {IT} = rule.antecedent

"""
    consequent(rule::ARule)::Itemset

Getter for `rule`'s consequent.

See also [`consequent`](@ref), [`ARule`](@ref), [`Itemset`](@ref).
"""
consequent(rule::ARule{IT}) where {IT} = rule.consequent

"""
    function Base.:(==)(rule1::ARule, rule2::ARule)

Antecedent (consequent) [`Item`](@ref)s ordering could be different between the two
[`ARule`](@ref), but they are essentially the same rule.

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref).
"""
function Base.:(==)(rule1::ARule, rule2::ARule)
    _antecedent1 = antecedent(rule1)
    _consequent1 = consequent(rule1)

    _antecedent2 = antecedent(rule2)
    _consequent2 = consequent(rule2)

    # first antecedent must be included in the second one,
    # same when considering the consequent;
    # if this is true and lengths are the same, then the two parts coincides.
    return intersect(_antecedent1, _antecedent2) == _antecedent1 &&
        intersect(_consequent1, _consequent2) == _consequent1
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

"""
    function Base.convert(::Type{SmallItemset}, arule::ARule)::Itemset

Convert an [`ARule`](@ref) to a [`SmallItemset`](@ref) by merging its [`antecedent`](@ref)
and consequent [`consequent`](@ref).

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`Itemset`](@ref).
"""
function Base.convert(::Type{SmallItemset}, arule::ARule)::SmallItemset
    return union(antecedent(arule), consequent(arule))
end

function Base.hash(arule::ARule, h::UInt)
    # the previous version was sort(arule |> antecedent)
    # but sort is already guaranteed from insertion
    _antecedent = arule |> antecedent
    _consequent = arule |> consequent
    return hash(vcat(_antecedent, _consequent), h)
end

function Base.show(io::IO, arule::ARule{IT}) where {IT}
    _antecedent = arule |> antecedent |> mask
    _consequent = arule |> consequent |> mask

    print(io, "$(_antecedent) => $(_consequent)")
end

function Base.show(io::IO, arule::ARule{IT}, miner::AbstractMiner) where {IT}
    _antecedentstr = applymask(arule |> antecedent, miner) |> syntaxstring
    _consequentstr = applymask(arule |> consequent, miner) |> syntaxstring

    print(io, "$(_antecedentstr) => $(_consequentstr)");
end

"""
    ARMSubject = Union{ARule,Itemset}

Each entity mined through an association rule mining algorithm.

See also [`ARule`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref), [`Itemset`](@ref),
[`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
const ARMSubject = Union{ARule,SmallItemset,Itemset}

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
