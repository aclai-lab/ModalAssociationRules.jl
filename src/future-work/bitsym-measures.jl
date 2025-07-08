# This file contains the implementation of some bit-symmetric measures that could be
# integrated in "meaningfulness-measures.jl"

##### _lchisquared_logic = (rule, X, ith_instance, miner) -> begin
#####     # TODO - this might be broken
#####
#####     N = ninstances(X)
#####     _instance = getinstance(X, ith_instance)
#####
#####     a1 = antecedent(rule)
#####     a2 = NEGATION(a1 |> formula) |> Itemset
#####
#####     c1 = consequent(rule)
#####     c2 = NEGATION(b1 |> formula) |> Itemset
#####
#####     _ans = N * sum((R) -> lleverage(ARule(first(R),last(R)), X, _instance, miner)^2 /
#####         (lsupport(first(R), X, _instance, miner) * lsupport(last(R), X, _instance, miner)),
#####         IterTools.product([a1, a2], [c1, c2])
#####     )
#####
#####     return Dict(:measure => _ans)
##### end
#####
##### _gchisquared_logic = (rule, X, threshold, miner) -> begin
#####     # TODO - this might be broken
#####
#####     N = ninstances(X)
#####
#####     a1 = antecedent(rule)
#####     a2 = NEGATION(a1 |> formula) |> Itemset
#####
#####     c1 = consequent(rule)
#####     c2 = NEGATION(c1 |> formula) |> Itemset
#####
#####     _ans = N * sum((R) -> gleverage(ARule(first(R),last(R)), X, threshold, miner)^2 /
#####         (gsupport(first(R), X, threshold, miner) * gsupport(last(R), X, threshold, miner)),
#####         IterTools.product([a1, a2], [c1, c2]) |> collect |> vec
#####     )
#####
#####     return Dict(:measure => _ans)
##### end
#####
##### """
#####     function lchisquared(
#####         rule::ARule,
#####         X::SupportedLogiset,
#####         threshold::Threshold;
#####         miner::Union{Nothing,AbstractMiner}=nothing
#####     )::Float64
#####
##### 𝛸²-test for a `rule`, in the local setting (within a modal instance).
#####
##### This test assists in deciding about the independence of these items which suggests that the
##### measure is not feasible for ranking purposes.
#####
##### [`AbstractMiner`](@ref), [`Threshold`](@ref).
##### """
##### @localmeasure lchisquared _lchisquared_logic
#####
##### """
#####     function gchisquared(
#####         rule::ARule,
#####         X::SupportedLogiset,
#####         threshold::Threshold;
#####         miner::Union{Nothing,AbstractMiner}=nothing
#####     )::Float64
#####
##### See also [`lchisquared`](@ref).
##### """
##### @globalmeasure gchisquared _gchisquared_logic
#####
#####
##### @linkmeas gchisquared lchisquared
#####
