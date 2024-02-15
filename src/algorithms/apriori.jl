"""
    apriori(; fulldump::Bool=true, verbose::Bool=true)::Function

Wrapper function for the Apriori algorithm over a modal dataset.
Returns a `function f(miner::ARuleMiner, X::AbstractDataset)::Nothing` that runs the main
Apriori algorithm logic, [as described here](https://ceur-ws.org/Vol-3284/492.pdf).
"""
function apriori(;
    fulldump::Bool=true,   # mostly for testing purposes, also keeps track of non-frequent patterns
    verbose::Bool=true,
)::Function

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

                # IDEA: this could be a list comprehension
                # frequents = [candidate
                #    for (gmeas_algo, lthreshold, gthreshold) in item_meas(miner)
                #        for candidate in candidates
                #        if gmeas_algo(item, X, lthreshold, miner=miner) >= gthreshold
                #    ]
                for (gmeas_algo, lthreshold, gthreshold) in item_meas(miner)
                    if gmeas_algo(item, X, lthreshold, miner=miner) < gthreshold
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

            # TODO: unique! here?
            unique!(frequents)
            sort!(frequents, by=t -> getglobalmemo(miner, (:gsupport, t)) , rev=true)

            # save frequent and nonfrequent itemsets inside miner structure
            push!(freqitems(miner), frequents...)
            push!(nonfreqitems(miner), nonfrequents...)

            # generate new candidates
            k = (candidates |> first |> length) + 1

            # TODO: remove collect and make the code lazy
            candidates = prune(candidates, frequents, k) |> collect

            # empty support structures
            empty!(frequents)
            empty!(nonfrequents)

            if verbose
                println("Starting new computational loop with $(length(candidates)) " *
                        "candidates.")
            end
        end
    end

    return _apriori
end
