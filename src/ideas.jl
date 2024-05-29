# This is a collection of ideas that might be useful.
# Sometimes these are already used and exported, sometimes they need a little of tweaking
# and refactoring to be useful or efficient.

# Decorators to DRY when defining meaningfulness measures
# function make_lmeas(
#     itemset::Itemset,
#     X::AbstractDataset,
#     i_instance::Integer,
#     miner::Miner,
#     measlogic::Function
# )
#     # this is needed to access memoization structures
#     # a dispatch should already ask for a Symbol
#     memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance))
#
#     # leverage memoization if a miner is provided, and it already computed the measure
#     memoized = localmemo(miner, memokey)
#     if !isnothing(memoized) return memoized end
#
#     ans = measlogic(itemset, X, i_instance)
#
#     # before returning the measure result, perform memoization
#     localmemo!(miner, memokey, ans)
#
#     return ans
# end
#
# function make_gmeas(
#     itemset::Itemset,
#     X::AbstractDataset,
#     miner::Miner,
#     measlogic::Function
# )
#     # this is needed to access memoization structures
#     # a dispatch should already ask for a Symbol
#     memokey = GmeasMemoKey((Symbol(gsupport), itemset))
#
#     # leverage memoization if a miner is provided, and it already computed the measure
#     memoized = globalmemo(miner, memokey)
#     if !isnothing(memoized) return memoized end
#
#     ans = measlogic(itemset, X)
#
#     # before returning the measure result, perform memoization
#     globalmemo!(miner, memokey, ans)
#
#     return ans
# end

# FPGrowth global and local support computation from contributors

# we know that all the combinations of items in `survivor_itemset` are frequent
# with `leftout_itemset`, but we need to save (inside miner) the exact local
# and global support for each new itemset: those measures are computed below.
### _nworlds = SoleLogics.nworlds(dataset(miner), 1)
### _ninstances = dataset(miner) |> ninstances
###
### gsupp_integer_threshold = convert(Int64, floor(
###     getglobalthreshold(miner, gsupport) * _ninstances
### ))
### lsupp_integer_threshold = convert(Int64, floor(
###     getlocalthreshold(miner, lsupport) * _nworlds
### ))

### for combo in combine_items(items(survivor_itemset), items(leftout_itemset)) ...

# WARNING: this is wrong...
### occurrences = [
###     sum([
###         contributors(:lsupport, itemset, i, miner)
###         for i in 1:_ninstances
###     ])
###     for itemset in combo
### ]

### nrows = length(occurrences)
### ncols = length(occurrences[1])
### min_occurrences = fill(typemax(Int64), ncols)

### for c in 1:ncols
###     for r in 1:nrows
###         min_occurrences[c] = min(min_occurrences[c], occurrences[r][c])
###     end
### end

# updating local supports
### map(i ->
###     localmemo!(miner, (:lsupport, combo, i),
###     (min_occurrences[i]) / _ninstances),
###     1:_ninstance
### )

# updating global support
# "for how many worlds, a certain number θ of instances contributed
# to overpass a certain threshold?"
### globalmemo!(miner, (:gsupport, combo),
###     count(i -> i >= lsupp_integer_threshold, min_occurrences) / _nworlds)

### end

# macro inject_rulesift(call)
#     if call.head == :call && call.args[1] == :Miner
#         args = call.args[2:end]
#         esc(:(Miner($(args...))))
#     else
#         error("Invalid macro usage. Use the form @inject_rulesift " *
#             "Miner(<args here>)")
#     end
# end
