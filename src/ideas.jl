# This is a collection of ideas that might be useful.
# Sometimes these are already used and exported, sometimes they need a little of tweaking
# and refactoring to be useful or efficient.

# Decorators to DRY when defining meaningfulness measures
### function _lmeas_decorator(
###     itemset::Itemset,
###     X::AbstractDataset,
###     i_instance::Integer,
###     miner::Miner,
###     measlogic::Function
### )
###     # this is needed to access memoization structures
###     # a dispatch should already ask for a Symbol
###     memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance))
###
###     # leverage memoization if a miner is provided, and it already computed the measure
###     memoized = localmemo(miner, memokey)
###     if !isnothing(memoized) return memoized end
###
###     ans = measlogic(itemset, X, i_instance)
###
###     # before returning the measure result, perform memoization
###     localmemo!(miner, memokey, ans)
###
###     return ans
### end
###
### function _gmeas_decorator(
###     itemset::Itemset,
###     X::AbstractDataset,
###     miner::Miner,
###     measlogic::Function
### )
###     # this is needed to access memoization structures
###     # a dispatch should already ask for a Symbol
###     memokey = GmeasMemoKey((Symbol(gsupport), itemset))
###
###     # leverage memoization if a miner is provided, and it already computed the measure
###     memoized = globalmemo(miner, memokey)
###     if !isnothing(memoized) return memoized end
###
###     ans = measlogic(itemset, X)
###
###     # before returning the measure result, perform memoization
###     globalmemo!(miner, memokey, ans)
###
###     return ans
### end
###


### struct Itemset{I<:Item}
###     items::Vector{I}
###
###     Itemset(item::I) where {I<:Item} = new{I}([item])
###     Itemset(itemset::Vector{I}) where {I<:Item} = new{I}(itemset |> unique |> sort)
### #    Itemset(itemsets::Vector{I}) where {I<:Item} = Itemset.([union(itemsets...)...])
### end
###
### @forward Itemset.items size, getindex, IndexStyle, setindex!, iterate, length, similar, show
