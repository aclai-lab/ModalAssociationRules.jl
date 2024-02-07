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
    memoized = getlocalmemo(miner, memokey)
    if !isnothing(memoized) return memoized end

    ans = measlogic(itemset, X, i_instance)

    # before returning the measure result, perform memoization
    setlocalmemo(miner, memokey, ans)

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
    memoized = getglobalmemo(miner, memokey)
    if !isnothing(memoized) return memoized end

    ans = measlogic(itemset, X)

    # before returning the measure result, perform memoization
    setglobalmemo(miner, memokey, ans)

    return ans
end
