# Decorators to DRY when defining meaningfulness measures
function _lmeas_decorator(
    itemset::Itemset,
    X::AbstractDataset,
    i_instance::Integer,
    miner::ARuleMiner,
    measlogic::Function
)
    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance)) # NOTE: symbol should be an argument to

    # leverage memoization if a miner is provided, and it already computed the measure
    memoized = localmemo(miner, memokey)
    if !isnothing(memoized) return memoized end

    ans = measlogic(itemset, X, i_instance)

    # before returning the measure result, perform memoization
    localmemo!(miner, memokey, ans)

    return ans
end

function _gmeas_decorator(
    itemset::Itemset,
    X::AbstractDataset,
    miner::ARuleMiner,
    measlogic::Function
)
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gsupport), itemset)) # NOTE: symbol should be an argument to

    # leverage memoization if a miner is provided, and it already computed the measure
    memoized = globalmemo(miner, memokey)
    if !isnothing(memoized) return memoized end

    ans = measlogic(itemset, X)

    # before returning the measure result, perform memoization
    globalmemo!(miner, memokey, ans)

    return ans
end

"""
    function mirages!(
        candidates::Vector{Itemset},
        bouncer::DefaultDict{Itemset,WorldsMask},
        threshold::Int64
    )
"""
function mirages!(
    itemsets::Vector{Itemset},
    bouncer::DefaultDict{Itemset,WorldsMask},
    threshold::Int64
)
    k = itemsets |> first |> length

    # for each candidate, consider the worlds mask/contributors of all its sub-items;
    # compute the i-th contributor of the i-th contributor the minimum across all
    # contributors, then ...
    filter!(itemset ->
        count(i -> i > 0,
            [bouncer[c] for c in combinations(itemset, k-1)] |> findmin |> first
        ) >= threshold, itemsets
    )
end
