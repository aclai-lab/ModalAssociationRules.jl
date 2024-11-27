# ARule utilities

"""
    function anchor_rulecheck(rule::ARule)::Bool

Return true if the given [`ARule`](@ref) contains a propositional anchor, that is,
atleast one [`Item`](@ref) in its [`antecedent`](@ref) is a propositional letter.

See [`antecedent`](@ref), [`ARule`](@ref), [`generaterules`](@ref), [`Item`](@ref),
[`Miner`](@ref).
"""
function anchor_rulecheck(rule::ARule)::Bool
    # TODO - add kwarg npropositionals

    # not all items in the antecedent are modal
    return !all(it -> it isa SyntaxBranch && it |> token |> ismodal, antecedent(rule))
end

"""
    function non_selfabsorbed_rulecheck(rule::ARule)::Bool

Return true if the given [`ARule`](@ref) is not self-absorbing, that is,
for each [`Item`](@ref) in its [`antecedent`](@ref) wrapping a variable `V`,
the other items in the antecedent does not refer to `V`, and
every item in the [`consequent`](@ref) does not refer to `V` too.

See [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`generaterules`](@ref),
[`Item`](@ref), [`Miner`](@ref).
"""
function non_selfabsorbed_rulecheck(rule::ARule)::Bool
    # TODO - this could be moved to SoleData
    function _extract_variable(item::Item)::Integer
        # if `item` is already an Atom, do nothing.
        _formula = formula(item)
        _formula = _formula isa Atom ? _formula : _formula.children |> first
        return _formula.value.metacond.feature.i_variable
    end

    return all(
        # for each antecedent item
        ant_item ->
            # no other items in antecedent share the same variable
            count(
                _ant_item -> _extract_variable(ant_item) == _extract_variable(_ant_item),
                antecedent(rule)
            ) == 1 &&
            # every consequent item does not share the same variable
            all(
                cons_item -> _extract_variable(ant_item) != _extract_variable(cons_item),
                consequent(rule)
            ),
        antecedent(rule)
    )
end

"""
TODO (defaulted to 1)
"""
function max_consequent_number()::Bool
end

"""
TODO
"""
function max_itemset_length()::Bool
end

"""
TODO
Also, save this measures for each rule in an additional information field
"""
function min_number_of_lmeasures_satisfied()::Bool
end

"""
TODO ()
"""
function min_worlds_dimensionality()
end

"""
"""
function similar_pattern()
end
