"""
    function apriori(
        fulldump::Bool = true
    )::Function

Wrapper of Apriori algorithm over a (modal) dataset.
This returns a void function whose arg
"""
function apriori(;
    fulldump::Bool = true   # mostly for testing purposes
)::Function

    # look at the (k-1)-subsets of each candidate itemset:
    # if a subset was not frequent, then prune it.
    function _prune(
        candidates::Vector{Itemset},
        frequents::Vector{Itemset},
        k::Integer
    )
        # if the frequents set does not contain the subset of a certain candidate,
        # that candidate is pruned out.
        return Iterators.filter(
            # the iterator yields only itemsets for which every combo is in frequents
            itemset -> all(combo -> combo in frequents, combinations(itemset, k-1)),
            combine(candidates, k)
        )
    end

    # modal apriori main logic, as in https://ceur-ws.org/Vol-3284/492.pdf
    function _apriori(miner::ARuleMiner, X::AbstractDataset)::Nothing
        # candidates of length 1 - all the letters in our alphabet
        candidates = Itemset.(alphabet(miner))

        frequents = Vector{Itemset}([])     # frequent itemsets collection
        nonfrequents = Vector{Itemset}([])  # non-frequent itemsets collection (testing)

        while !isempty(candidates)
           # for each candidate, establish if it is interesting or not
            for item in candidates
                interesting = true

                for meas in item_meas(miner)
                    (gmeas_algo, lthreshold, gthreshold) = meas
                    if gmeas_algo(item, X, lthreshold) < gthreshold
                        interesting = false
                        break
                    end
                end

                if interesting
                    # dump the just computed frequent itemsets inside the miner
                    push!(frequents, item)
                elseif fulldump
                    # dump the non-frequent itemsets (maybe because of testing purposes)
                    push!(nonfrequents, item)
                end
            end

            # save frequent and nonfrequent itemsets inside miner structure
            push!(freqitems(miner), frequents...)
            push!(nonfreqitems(miner), nonfrequents...)

            # generate new candidates
            k = (candidates |> first |> length) + 1

            # TODO: remove collect and make the code lazy
            candidates = _prune(candidates, frequents, k) |> collect

            # empty support structures
            empty!(frequents)
            empty!(nonfrequents)

            println("Printing candidates")
            println(candidates)
            println("Starting new computational loop...")
            println("Current candidates size: $(length(candidates))")
            println("________________________---")
        end
    end

    return _apriori
end
