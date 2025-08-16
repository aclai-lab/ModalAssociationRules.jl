"""
    eclat(miner::Miner, X::MineableData; verbose::Bool=true)::Nothing

## Examples

julia> using ModalAssociationRules
julia> X_df, y = load_NATOPS();
julia> X_df_1_have_command = X_df[1:30, :]
julia> X1 = scalarlogiset(X_df_1_have_command)

julia> manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
julia> manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
julia> manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))
julia> manual_lp = box(IA_L)(manual_p)
julia> manual_lq = diamond(IA_L)(manual_q)
julia> manual_lr = box(IA_L)(manual_r)
julia>
julia> manual_items = Vector{Item}([manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

julia> _1_items = Vector{Item}([manual_p, manual_q, manual_lp, manual_lq])
julia> _1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
julia> _1_rulemeasures = [(gconfidence, 0.2, 0.2)]

julia> eclat_miner = Miner(X1, eclat, _1_items, _1_itemsetmeasures, _1_rulemeasures)

See also [`anchored_eclat`](@ref), [`Miner`](@ref).
"""
function eclat(miner::M)::M where {M<:AbstractMiner}
    _itemtype = itemtype(miner)
    X = data(miner)



    return miner
end
