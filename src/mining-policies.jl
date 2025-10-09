# this script collects policies to regulate mining, controlling both shape and semantics
# of the extracted frequent itemsets and association rules.

using SoleData: VariableDistance


##### policies for itemsets ################################################################


"""
    function islimited_length_itemset(; maxlength::Union{Nothing,Integer}=nothing)::Function

Closure returning a boolean function `F` having one argument `itemset`, subtype of
[`AbstractItemset`](@ref).

`F` is true if the length of the given `itemset` does not exceed the given thresholds.

# Arguments
- `maxlength::Union{Nothing,Integer}=nothing`: maximum `itemset`'s length; when `nothing`,
    defaults to `typemax(Int16)`.

!!! note
    The returned function adheres to the common interface of itemset's policies and,
    actually, also accepts a second [`AbstractMiner`](@ref) argument.

    In this case, it can be ignored.

See also [`AbstractItemset`](@ref), [`itemsetpolicies`](@ref).
"""
function islimited_length_itemset(; maxlength::Union{Nothing,Integer}=nothing)::Function
    if isnothing(maxlength)
        maxlength = typemax(Int16)
    end

    if maxlength <= 0
        throw(ArgumentError("maxlength must be > 0 (given value is $(maxlength))"))
    end

    return function _islimited_length_itemset(
        itemset::IT,
        _::M # to adhere to the common interface
    ) where {IT<:AbstractItemset, M<:AbstractMiner}
        return length(itemset) <= maxlength
    end
end


"""
    function isanchoreditemset(;
        npropositions::Integer=1,
        ignoreuntillength::Integer=1
    )::Function

Closure returning a boolean function `F` with one argument `rule::Itemset`.

`F` is true if the given `itemset` contains atleast `npropositions` *propositional anchors*
(that is, propositions without modal operators).

# Arguments
- `npropositions::Integer=1`: minimum number of propositional anchors (propositions with
    no modal operators) in the antecedent of the given rule.
- `ignoreuntillength::Integer=1`: avoid applying the policy to isolated [`Item`](@ref)s, or
    [`Itemset`](@ref) short enough.

See [`AbstractItemset`](@ref), [`Item`](@ref), [`itemsetpolicies`](@ref),
[`isanchoredarule`](@ref).
"""
function isanchoreditemset(; npropositions::Integer=1, ignoreuntillength::Integer=1)::Function
    # atleast `npropositions` items in the antecedent are not modal

    if npropositions < 0 || ignoreuntillength < 0
        throw(ArgumentError("All parameters must be >= 0; (given values: " *
                "npropositions=$(npropositions), ignoreuntillength=$(ignoreuntillength))"))
    end

    # beware to this policy; consider a candidate-based mining algorithm such as apriori;
    # since this policy discards the itemset "⟨A⟩Up[V2] ≤ 1.0 ∧ ⟨A⟩⟨A⟩Down[V2] ≤ 1.0"
    # there is no way to join it with an anchored one such as
    # "⟨A⟩Up[V2] ≤ 1.0 ∧ Down[V2] ≤ 1.0";

    return function _isanchoreditemset(
        itemset::IT,
        miner::M
    ) where {IT<:AbstractItemset, M<:AbstractMiner}
        _itemset = applymask(itemset, miner)

        return length(_itemset) <= ignoreuntillength ||
            count(it -> formula(it) isa Atom, _itemset) >= npropositions
    end
end


"""
    function isdimensionally_coherent_itemset(;)::Function

Closure returning a boolean function `F` with one argument `itemset`, which is a subtype
of [`AbstractItemset`](@ref).

This is needed to ensure the Itemset is coherent with the dimensional definition of local
support. All the propositions (or anchors) in an itemset must be `VariableDistance`s
wrapping references of the same size.

See also [`AbstractItemset`](@ref), [`itemsetpolicies`](@ref), `SoleData.VariableDistance`.
"""
function isdimensionally_coherent_itemset(;)::Function
    # since we have no arguments, this closure seems useless;
    # however, we stick to the same pattern.

    return function _isdimensionally_coherent_itemset(
        itemset::IT,
        miner::M
    ) where {IT<:AbstractItemset, M<:AbstractMiner}
        itemset = applymask(itemset, miner)

        # a generic Itemset contains Atoms and SyntaxTrees:
        # the former are always propositions, while the latter are modal literals;
        # we want to keep only the propositions, since they are the anchor of our itemset.
        anchors = filter(item -> formula(item) isa Atom, itemset)

        # in particular, every Variable must not be a VariableDistance (e.g., VariableMin)
        _anchortypes = Set([feature(anchor) |> typeof for anchor in anchors])
        if !any(_anchortype -> _anchortype <: SoleData.VariableDistance, _anchortypes)
            return true
        end

        # or all the anchors must be VariableDistances (the two cannot be mixed)
        if !all(type -> type <: SoleData.VariableDistance, _anchortypes)
            return false
        end

        # also, all their references must be of the same size (e.g., 5-length intervals)
        # after https://github.com/aclai-lab/SoleData.jl/pull/62, the definition of refsize
        # is broken, and will be fixed in SoleData > 0.16.5
        # _referencesize = vardistance -> feature(vardistance) |> refsize

        # this is an hotfix
        _referencesize = vardistance -> feature(vardistance) |> references |> first |> size

        _anchorsize = _referencesize(anchors[1])

        return all(anchor -> _referencesize(anchor) == _anchorsize, anchors)
    end
end



##### policies for rules ###################################################################


"""
    function islimited_length_arule(;
        antecedent_maxlength::Union{Nothing,Integer}=nothing,
        consequent_maxlength::Union{Nothing,Integer}=1
    )::Function

Closure returning a boolean function `F` with one argument `rule::ARule`.

`F` is true if the length of `rule`'s [`antecedent`](@ref) (and [`consequent`](@ref)) does
not exceed the given thresholds.


# Arguments
- `antecedent_maxlength::Union{Nothing,Integer}=nothing`: maximum antecedent length of
    the given rule; when `nothing`, defaults to `typemax(Int16)`;
- `consequent_maxlength::Union{Nothing,Integer}=1`: maximum consequent length of the given
    rule; when `nothing`, defaults to `typemax(Int16)`.

!!! note
    The returned function adheres to the common interface of itemset's policies and,
    actually, also accepts a second [`AbstractMiner`](@ref) argument.

    In this case, it can be ignored.

See also [`antecedent`](@ref), [`ARule`](@ref), [`arulepolicies`](@ref),
[`consequent`](@ref).
"""
function islimited_length_arule(;
    antecedent_maxlength::Union{Nothing,Integer}=nothing,
    consequent_maxlength::Union{Nothing,Integer}=1
)::Function
    function _check(threshold::Union{Nothing,Integer})::Integer
        if isnothing(threshold)
            return typemax(Int16)
        elseif threshold > 0
            return threshold
        else
            throw(ArgumentError("Invalid maximum length threshold ($(threshold))."))
        end
    end

    antecedent_maxlength = _check(antecedent_maxlength)
    consequent_maxlength = _check(consequent_maxlength)

    return function _islimited_length_arule(
        rule::ARule,
        _::M
    )::Bool where {M<:AbstractMiner}
        return length(rule |> antecedent) <= antecedent_maxlength &&
            length(rule |> consequent) <= consequent_maxlength
    end
end

"""
    function isanchoredarule(; npropositions::Integer=1)::Function

Closure returning a boolean function `F` with one argument `rule::ARule` and an
[`AbstractMiner`](@ref).

`F` is true if the given `rule` contains atleast `npropositions` *propositional anchors*
(that is, propositions without modal operators).

# Arguments
- `npropositions::Integer=1`: minimum number of propositional anchors (propositions with
    no modal operators) in the antecedent of the given rule.

See [`antecedent`](@ref), [`ARule`](@ref), [`arulepolicies`](@ref),
[`generaterules`](@ref), [`Item`](@ref), [`Miner`](@ref).
"""
function isanchoredarule(; npropositions::Integer=1)::Function
    # atleast `npropositions` items in the antecedent are not modal

    if npropositions < 0
        throw(
            ArgumentError("npropositions must be >= 0 (given value is $(npropositions))"))
    end

    return function _isanchoredarule(rule::ARule, miner::M) where {M<:AbstractMiner}
        _itemset = antecedent(rule)

        return isanchoreditemset(;
            npropositions=npropositions, ignoreuntillength=0)(_itemset, miner)
    end
end

"""
    function isheterogeneous_arule(;
        antecedent_nrepetitions::Integer=1,
        consequent_nrepetitions::Integer=0,
        consider_thresholds::Bool=false
    )::Function

Closure returning a boolean function `F` with one argument `rule::ARule`.

`F` is true if the given `rule` is heterogeneous, that is, across all the [`Item`](@ref)
in `rule` [`antecedent`](@ref) and [`consequent`](@ref), the number of identical variables
`V` is at most `nrepetitions`.

# Arguments
- `antecedent_nrepetitions::Integer=1`: maximum allowed number of identical variables in the
    antecedent of the given rule.
- `consequent_nrepetitions::Integer=0`: maximum allowed number of identical variables
    between the antecedent and the consequent of the given rule.
- `consider_thresholds::Bool=false`: if true, both identical variables and thresholds
    are considered in the counting.

See [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`generaterules`](@ref),
[`Item`](@ref), [`Miner`](@ref).
"""
function isheterogeneous_arule(;
    antecedent_nrepetitions::Integer=1,
    consequent_nrepetitions::Integer=0,
    consider_thresholds::Bool=false
)::Function
    if antecedent_nrepetitions < 1
        throw(
            ArgumentError("antecedent_nrepetitions must be >= 1 " *
            "(given value is $(antecedent_nrepetitions))"))
    end

    if consequent_nrepetitions < 0
        throw(
            ArgumentError("consequent_nrepetitions must be >= 0 " *
            "(given value is $(consequent_nrepetitions))"))
    end

    function __extract_value(item::Item)
        _formula = formula(item)

        while _formula isa SoleLogics.SyntaxBranch
            _formula = _formula |> SoleLogics.children |> first
        end

        return _formula |> SoleLogics.value
    end

    function _extract_variable_number(item::Item)
        return __extract_value(item) |> SoleData.metacond |> SoleData.feature |>
            SoleData.i_variable
    end

    function _extract_threshold(item::Item)
        return __extract_value(item) |> SoleData.value |> SoleData.threshold
    end

    # two items are too similar
    function ishomogeneous(item1::Item, item2::Item)
        return _extract_variable_number(item1) == _extract_variable_number(item2) &&
            (!consider_thresholds || _extract_threshold(item1) == _extract_threshold(item2))
    end

    return function _isheterogeneous_arule(rule::ARule, miner::M) where {M<:AbstractMiner}
        _antecedent = applymask(antecedent(rule), miner)
        _consequent = applymask(consequent(rule), miner)

        return all(
            # for each antecedent item
            ant_item ->
                # no other items in antecedent shares (too much) the same variable
                count(__ant_item ->
                    ishomogeneous(ant_item, __ant_item), _antecedent
                ) <= antecedent_nrepetitions &&

                # every consequent item does not shares (too much) the same variable
                # with the fixed antecedent
                count(cons_item ->
                    ishomogeneous(ant_item, cons_item), _consequent
                ) <= consequent_nrepetitions,

            antecedent(rule)
        )
    end

end
