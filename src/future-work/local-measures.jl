# The following local measures are so granular that are still not tested on real modal datasets

##### _lconfidence_logic = (rule, X, ith_instance, miner) -> begin
#####     _instance = getinstance(X, ith_instance)
#####     num = lsupport(convert(Itemset, rule), _instance, miner)
#####     den = lsupport(antecedent(rule), _instance, miner)
#####
#####     return Dict(:measure => num/den)
##### end
#####
##### _llift_logic = (rule, X, ith_instance, miner) -> begin
#####     num = lconfidence(rule, X, ith_instance, miner)
#####     den = lsupport(consequent(rule), getinstance(X, ith_instance), miner)
#####
#####     return Dict(:measure => num/den)
##### end
#####
##### _lconviction_logic = (rule, X, ith_instance, miner) -> begin
#####     _instance = getinstance(X, ith_instance)
#####
#####     num = 1 - lsupport(consequent(rule), X, _instance, miner)
#####     den = 1 - lconfidence(rule, X, _instance, miner)
#####
#####     return Dict(:measure => num/den)
##### end
#####
##### _lleverage_logic = (rule, X, ith_instance, miner) -> begin
#####     _instance = getinstance(X, ith_instance)
#####
#####     _ans = lsupport(convert(Itemset, rule), X, _instance, miner) - \
#####         lsupport(antecedent(rule), X, _instance, miner) * \
#####         lsupport(consequent(rule), X, _instance, miner)
#####
#####     return Dict(:measure => _ans)
##### end
#####
##### """
#####     function lconfidence(
#####         rule::ARule,
#####         ith_instance::LogicalInstance;
#####         miner::Union{Nothing,AbstractMiner}=nothing
#####     )::Float64
#####
##### Compute the local confidence for the given `rule`.
#####
##### Local confidence is the ratio between [`lsupport`](@ref) of an [`ARule`](@ref) on a
##### [`LogicalInstance`](@ref) and the [`lsupport`](@ref) of the [`antecedent`](@ref) of the
##### same rule.
#####
##### If a miner is provided, then its internal state is updated and used to leverage memoization.
#####
##### See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref),
##### [`LogicalInstance`](@ref), [`lsupport`](@ref), [`Threshold`](@ref).
##### """
##### @localmeasure lconfidence _lconfidence_logic
#####
##### """
#####     function llift(
#####         rule::ARule,
#####         ith_instance::LogicalInstance;
#####         miner::Union{Nothing,AbstractMiner}=nothing
#####     )::Float64
#####
##### Compute the local lift for the given `rule`.
#####
##### Local lift measures how far from independence are `rule`'s [`antecedent`](@ref) and
##### [`consequent`](@ref) on a modal logic instance.
#####
##### Given an [`ARule`](@ref) `X ⇒ Y`, if local lift value is around 1, then this means that
##### `P(X ⋃ Y) = P(X)P(Y)`, and hence, the two [`Itemset`](@ref)s `X` and `Y` are independant.
##### If value is greater than (lower than) 1, then this means that `X` and `Y` are dependant
##### and positively (negatively) correlated [`Itemset`](@ref)s.
#####
##### If a miner is provided, then its internal state is updated and used to leverage memoization.
#####
##### See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref), [`glift`](@ref),
##### [`LogicalInstance`](@ref), [`llift`](@ref), [`Threshold`](@ref).
##### """
##### @localmeasure llift _llift_logic
#####
#####
##### """
#####     function lconviction(
#####         rule::ARule,
#####         ith_instance::LogicalInstance;
#####         miner::Union{Nothing,AbstractMiner}=nothing
#####     )::Float64
#####
##### Compute the local conviction for the given `rule`.
#####
##### Conviction attempts to measure the degree of implication of a rule.
##### It's value ranges from 0 to +∞.
##### Unlike lift, conviction is sensitive to rule direction; like lift, values far from 1
##### indicate interesting rules.
#####
##### If a miner is provided, then its internal state is updated and used to leverage memoization.
#####
##### See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref),
##### [`LogicalInstance`](@ref), [`llift`](@ref), [`Threshold`](@ref).
##### """
##### @localmeasure lconviction _lconviction_logic
#####
##### """
#####     function lleverage(
#####         rule::ARule,
#####         X::SupportedLogiset,
#####         threshold::Threshold;
#####         miner::Union{Nothing,AbstractMiner}=nothing
#####     )::Float64
#####
##### Compute the local leverage for the given `rule`.
#####
##### Measures how much more counting is obtained from the co-occurrence of the
##### [`antecedent`](@ref) and [`consequent`](@ref) from the expected (from independence).
#####
##### This value ranges between [-0.25,0.25].
#####
##### See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref),
##### [`consequent`](@ref), [`LogicalInstance`](@ref), [`Threshold`](@ref).
##### """
##### @localmeasure lleverage _lleverage_logic
#####
#####
##### @linkmeas gconfidence lconfidence
#####
##### @linkmeas glift llift
#####
##### @linkmeas gconviction lconviction
#####
##### @linkmeas gleverage lleverage
#####
