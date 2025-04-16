# this script collects policies regarding mining;
# they are both structural, syntactical and semantical.


# policies related to the mining structure
# deprecated: there are no such filters at the moment.
# see "data_mining_policies(::AbstractMiner)".

# policies related to frequent itemsets mining

"""
    function islimited_length_itemset(; maxlength::Union{Nothing,Integer}=nothing)::Function

Closure returning a boolean function `F` with one argument `itemset::Itemset`.

`F` is true if the length of the given `itemset` does not exceed the given thresholds.

# Arguments
- `maxlength::Union{Nothing,Integer}=nothing`: maximum `itemset`'s length; when `nothing`,
    defaults to `typemax(Int16)`.

See also [`Itemset`](@ref), [`itemset_mining_policies`](@ref).
"""
function islimited_length_itemset(; maxlength::Union{Nothing,Integer}=nothing)::Function
    if isnothing(maxlength)
        maxlength = typemax(Int16)
    end

    if maxlength <= 0
        throw(ArgumentError("maxlength must be > 0 (given value is $(maxlength))"))
    end

    return function _islimited_length_itemset(itemset::Itemset)
        return length(itemset) <= maxlength
    end
end


"""
    function isanchored_itemset(;
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

See [`Item`](@ref), [`Itemset`](@ref), [`itemset_mining_policies`](@ref),
[`isanchored_arule`](@ref).
"""
function isanchored_itemset(; npropositions::Integer=1, ignoreuntillength::Integer=1)::Function
    # atleast `npropositions` items in the antecedent are not modal

    if npropositions < 0 || ignoreuntillength < 0
        throw(ArgumentError("All parameters must be >= 0; (given values: " *
                "npropositions=$(npropositions), ignoreuntillength=$(ignoreuntillength))"))
    end

    return function _isanchored_itemset(itemset::Itemset)
        length(itemset) <= ignoreuntillength ||
        count(it -> formula(it) isa Atom, itemset) >= npropositions
    end
end


"""
    function isdimensionally_coherent_itemset(;)::Function

Closure returning a boolean function `F` with one argument `itemset::Itemset`.

This is needed to ensure the Itemset is coherent with the dimensional definition of local
support. All the propositions (or anchors) in an itemset must be `VariableDistance`s
wrapping references of the same size.

See also [`Itemset`](@ref), [`itemset_mining_policies`](@ref), `SoleData.VariableDistance`.
"""
function isdimensionally_coherent_itemset(;)::Function
    # since we have no arguments, this closure seems useless;
    # however, we stick to the same pattern.

    return function _isdimensionally_coherent_itemset(itemset::Itemset)
        # a generic Itemset contains Atoms and SyntaxTrees:
        # the former are always propositions, while the latter are modal literals;
        # we want to keep only the propositions, since they are the anchor of our itemset.
        anchors = filter(item -> formula(item) isa Atom, itemset)

        # in particular, every Variable must not be a VariableDistance (e.g., VariableMin)
        _anchortypes = Set([feature(anchor) |> typeof for anchor in anchors])
        if !any(_anchortype -> _anchortype <: VariableDistance, _anchortypes)
            return true
        end

        # or all the anchors must be VariableDistances (the two cannot be mixed)
        if !all(type -> type <: VariableDistance, _anchortypes)
            return false
        end

        # also, all their references must be of the same size (e.g., 5-length intervals)
        _referencesize = vardistance -> feature(vardistance) |> refsize
        _anchorsize = _referencesize(anchors[1])

        return all(anchor -> _referencesize(anchor) == _anchorsize, anchors)
    end
end


# policies related to association rule generation


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

See also [`antecedent`](@ref), [`ARule`](@ref), [`arule_mining_policies`](@ref),
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

    return function _islimited_length_arule(rule::ARule)::Bool
        return length(rule |> antecedent) <= antecedent_maxlength &&
            length(rule |> consequent) <= consequent_maxlength
    end
end

"""
    function isanchored_arule(; npropositions::Integer=1)::Function

Closure returning a boolean function `F` with one argument `rule::ARule`.

`F` is true if the given `rule` contains atleast `npropositions` *propositional anchors*
(that is, propositions without modal operators).

# Arguments
- `npropositions::Integer=1`: minimum number of propositional anchors (propositions with
    no modal operators) in the antecedent of the given rule.

See [`antecedent`](@ref), [`ARule`](@ref), [`arule_mining_policies`](@ref),
[`generaterules`](@ref), [`Item`](@ref), [`Miner`](@ref).
"""
function isanchored_arule(; npropositions::Integer=1)::Function
    # atleast `npropositions` items in the antecedent are not modal

    if npropositions < 0
        throw(
            ArgumentError("npropositions must be >= 0 (given value is $(npropositions))"))
    end

    return function _isanchored_arule(rule::ARule)
        return isanchored_itemset(;
            npropositions=npropositions, ignoreuntillength=0)(antecedent(rule))
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
    antecedent of the given rule.+
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
        _formula = _formula isa Atom ? _formula : _formula.children |> first
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

    return function _isheterogeneous_arule(rule::ARule)
        return all(
            # for each antecedent item
            ant_item ->
                # no other items in antecedent shares (too much) the same variable
                count(__ant_item ->
                    ishomogeneous(ant_item, __ant_item), antecedent(rule)
                ) <= antecedent_nrepetitions &&

                # every consequent item does not shares (too much) the same variable
                # with the fixed antecedent
                count(cons_item ->
                    ishomogeneous(ant_item, cons_item), consequent(rule)
                ) <= consequent_nrepetitions,

            antecedent(rule)
        )
    end

end

"""
TODO
Also, save this measures for each rule in an additional information field.
"""
function min_number_of_lmeasures_satisfied()::Bool
end

"""
TODO
"""
function similar_pattern()
end
