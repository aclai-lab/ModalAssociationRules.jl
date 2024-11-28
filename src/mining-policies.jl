# this script collects policies regarding mining;
# they are both structural, syntactical and semantical.

# policies related to the mining structure
"""
TODO ()
"""
function islimited_dimensionality_world()
end


# policies related to frequent itemsets mining

"""
TODO
"""
function islimited_length_itemset()::Bool
end

# policies related to association rule generation

"""
    function islimited_length_arule(;
        antecedent_maxlength::Union{Nothing,Integer}=nothing,
        consequent_maxlength::Union{Nothing,Integer}=1
    )::Function

Closure returning a boolean function `F` with one argument `rule::ARule`.

`F` is true if the length of `rule`'s [`antecedent`](@ref) (and [`consequent`](@ref)) does
not exceed the given limit.

# Arguments
- `antecedent_maxlength::Union{Nothing,Integer}=nothing`: maximum antecedent length of
    the given rule;
- `consequent_maxlength::Union{Nothing,Integer}=1`: maximum consequent length of the given
    rule.

See also [`ARule`](@ref), [`antecedent`](@ref), [`consequent`](@ref).
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

See [`antecedent`](@ref), [`ARule`](@ref), [`generaterules`](@ref), [`Item`](@ref),
[`Miner`](@ref).
"""
function isanchored_arule(; npropositions::Integer=1)::Function
    # atleast `npropositions` items in the antecedent are not modal

    if npropositions < 0
        throw(
            ArgumentError("npropositions must be >= 0 (given value is $(npropositions))"))
    end

    return function _isanchored_arule(rule::ARule)
        if npropositions == 1
            # specific optimization
            return !all(
                it -> it isa SyntaxBranch && it |> token |> ismodal, antecedent(rule))
        else
            # general case
            return count(
                it -> it isa SyntaxBranch && it |> token |> ismodal,
                antecedent(rule)
            ) >= npropositions
        end
    end
end

"""
    function isheterogeneous_arule(;
        antecedent_nrepetitions::Integer=1,
        consequent_nrepetitions::Integer=0
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

See [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`generaterules`](@ref),
[`Item`](@ref), [`Miner`](@ref).
"""
function isheterogeneous_arule(;
    antecedent_nrepetitions::Integer=1,
    consequent_nrepetitions::Integer=0
)::Function

    function _extract_variable(item::Item)::Integer
        # if `item` is already an Atom, do nothing.
        # TODO - this could be moved to SoleData
        _formula = formula(item)
        _formula = _formula isa Atom ? _formula : _formula.children |> first
        return _formula.value.metacond.feature.i_variable
    end

    return function _isheterogeneous_arule(rule::ARule)
        return all(
            # for each antecedent item
            ant_item ->
                # no other items in antecedent shares (too much) the same variable
                count(__ant_item ->
                    _extract_variable(ant_item) == _extract_variable(__ant_item),
                    antecedent(rule)
                ) <= antecedent_nrepetitions &&

                # every consequent item does not shares (too much) the same variable
                # with the fixed antecedent
                count(cons_item ->
                    _extract_variable(ant_item) == _extract_variable(cons_item),
                    consequent(rule)
                ) <= consequent_nrepetitions,
            antecedent(rule)
        )
    end

end

"""
TODO
Also, save this measures for each rule in an additional information field
"""
function min_number_of_lmeasures_satisfied()::Bool
end

"""
"""
function similar_pattern()
end
