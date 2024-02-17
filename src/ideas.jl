# This is a collection of ideas that might be useful.
# Sometimes these are already used and exported, sometimes they need a little of tweaking
# and refactoring to be useful or efficient.

# Decorators to DRY when defining meaningfulness measures
function _lmeas_decorator(
    itemset::Itemset,
    X::AbstractDataset,
    i_instance::Integer,
    miner::ARuleMiner,
    measlogic::Function
)
    # this is needed to access memoization structures
    # a dispatch should already ask for a Symbol
    memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance))

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
    # a dispatch should already ask for a Symbol
    memokey = GmeasMemoKey((Symbol(gsupport), itemset))

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
        itemsets::Vector{Itemset},
        bouncer::DefaultDict{Itemset,WorldsMask},
        lthreshold::Int64,
        gthreshold::Int64
    )

Filter those [`Itemset`](@ref) in `itemsets` who seems potential frequent patterns, but are
not.

During the candidate-generation phase of an association rule mining algorithm (e.g.,
[`apriori`](@ref)), when  two [`Itemset`](@ref)s A and B are merged together in an itemset
C = Merge([A1,A2,...A(n-1)], [A1,A2,...,B(n-1)]) = [A1,A2,...,A(n-1),B(n-1)], some
sub-itemset might be new to the algorithm (it did never see it).

This function determines whether atleast one sub-itemset hides the fact that it is locally
true ON DIFFERENT WORLDS with respect to the initial itemsets A and B.
"""
function mirages!(
    itemsets::Vector{Itemset},
    bouncer::DefaultDict{Itemset,WorldsMask},
    lthreshold::Int64,
    gthreshold::Int64 # TODO: remove this
)
    k = itemsets |> first |> length

    # TODO: compare this code with fpgrowth.jl -> patternbase -> row 600
    filter!(itemset ->
        Base.count(i -> i > lthreshold,
            [bouncer[c] for c in combinations(itemset, k-1)] |> findmin |> first
        ) >= gthreshold,
        itemsets
    )
end
