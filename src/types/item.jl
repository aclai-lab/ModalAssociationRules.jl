
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
model.

To know more about logical formulas in `Sole.jl`, see
[SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).

See also [`AbstractItemset`](@ref).
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

Return the `SoleLogics.Formula` wrapped within `item`.

See also [`Item`](@ref).
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
    const ItemCollection{N,I} = Ref{SVector{N,I}} where {N,I<:AbstractItem}

Reference to a collection of [`Item`](@ref)s.

See also [`AbstractItem`](@ref), [`Item`](@ref).
"""
const ItemCollection{N,I} = Ref{SVector{N,I}} where {N,I<:AbstractItem}
