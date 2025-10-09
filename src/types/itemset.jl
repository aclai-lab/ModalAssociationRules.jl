
"""
    abstract type AbstractItemset end

Generic type for itemsets.

See also [`Item`](@ref), [`SmallItemset`](@ref), [`Itemset`](@ref).
"""
abstract type AbstractItemset end



##### SmallItemset definition ##############################################################

"""
    struct SmallItemset{N,U<:Unsigned} <: AbstractItemset

Efficient itemset, encoding a set of items as a multiword mask over a
[`ItemCollection`](@ref).

Support `U` is a `UInt64` and we want to represent a specific itemset from a collection of
128 items. Then, we only need two U values for encoding any combination of items.

# Interface

- mask(si::SmallItemset)
- Base.length(si::SmallItemset)
- Base.intersect(si::SmallItemset, si::SmallItemset)
- Base.union(si::SmallItemset, si::SmallItemset)
- diff(si::SmallItemset, si::SmallItemset)
- Base.isequal(si::SmallItemset) and Base.(:==)(si::SmallItemset)
- applymask(si::SmallItemset, ic::ItemCollection)
- Base.count_ones(si::SmallItemset)
- bitpowerset(si::SmallItemset{N,U}) where {N,U<:Unsigned}

See also [`applymask`](@ref), [`diff`](@ref), [`mask`](@ref).
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

"""
    mask(si::SmallItemset)

Return the `SVector` wrapped within `si`, that is, the static array of unsigned integers
encoding a bitmask (that you can use to select specific items from a collection).

See also [`applymask`](@ref), [`SmallItemset`](@ref).
"""
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

"""
    diff(s1::SmallItemset{N,U}, s2::SmallItemset{N,U}) where {N,U}

Return a new `SmallItemset` wrapping the broadcasted xor between `mask(s1)` and `mask(s2)`.

See also [`mask`](@ref), [`SmallItemset`](@ref).
"""
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
    Base.count_ones(si::SmallItemset{N,U}) where {N,U}

Broadcast `Base.count_ones` on all the masks wrapped by a [`SmallItemset`](@ref).

See also [`SmallItemset`](@ref).
"""
function Base.count_ones(si::SmallItemset{N,U}) where {N,U}
    return si |> mask .|> count_ones |> sum
end

"""
    function applymask(
        si::SmallItemset{N,U},
        ic::ItemCollection{M,I}
    ) where {N,M,U<:Unsigned,I<:AbstractItem}

Split `ic` into chunks, depending on the size of U.
Then, for each chunk, apply the correct mask wrapped within `si`.

# Examples
```julia
julia> myitemset = SmallItemset(SVector{2}([UInt64(5), UInt64(1)]) )
julia> myitemcollection = ItemCollection{300,Item}(Item[
    Atom(ScalarCondition(VariableMin(i), >, -1.0))
    for i in 1:300
])
julia> applymask(myitemset, myitemcollection)
```

See also [`ItemCollection`](@ref), [`SmallItemset`](@ref).
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
    itemsetpopulation(miner::AbstractMiner; prec::Type{<:Unsigned}=UInt64)

Generate a [`SmallItemset`](@ref) for each item in `miner`. If the items are 3, for example,
then the masks of the 3 result SmallItemset are 001, 010, 100.

The number of unsigned wrapped within each resulting itemset depends on the choosen
precision `prec` and the number of items within `miner`. For example, if the miner contains
100 items and `prec` is set to be UInt32, then each [`SmallItemset`](@ref) returned from
this call will contain 4 UInt32 (3 would be capable to only encode the first 94 items).

See also [`AbstractMiner`](@ref), [`mask`](@ref), [`SmallItemset`](@ref).
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
    bitpowerset(si::SmallItemset{N,U}) where {N,U<:Unsigned}

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

!!! warning
    This is deprecated and should be used only when you explicitly want to keep your items
    in memory, instead of compactly embodying them into [`SmallItemset`](@ref)s.

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
