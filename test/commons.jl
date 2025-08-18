module Commons

using ModalAssociationRules
using Test

# check if global support coincides for each frequent itemset
function isequal_gsupp(miner1::AbstractMiner, miner2::AbstractMiner)
    for itemset in freqitems(miner1)
        @test miner1.globalmemo[
            (:gsupport, itemset)] == miner2.globalmemo[(:gsupport, itemset)]
    end
end

# check if local support coincides for each frequent itemset
function isequal_lsupp(miner1::AbstractMiner, miner2::AbstractMiner)
    for itemset in freqitems(miner1)
        for ninstance in 1:(miner1 |> data |> ninstances)
            miner1_lsupp = get(miner1.localmemo, (:lsupport, itemset, ninstance), -1.0)
            miner2_lsupp = get(miner2.localmemo, (:lsupport, itemset, ninstance), -1.0)

            if miner1_lsupp == -1.0 || miner2_lsupp == -1.0
                # this is fine, and doesn't imply the two algorithms are different.
                # the fact is that, from an operative standpoint of view,
                # fpgrowth may avoid computing local support on certain instances.
                # Example: (:lsupport, [min[V1] > -0.5, min[V3] > -3.6], 3) is never
                # computed by fpgrowth, since it already knows that one of the two item is
                # not frequent enough on instance #3
                # (instead, apriori has to explore this path).
                continue
            elseif miner1_lsupp != miner2_lsupp
                print("Debug print: failed test for itemset $(itemset) at " *
                      " instance $(ninstance)")
            end

            @test miner1_lsupp == miner2_lsupp
        end
    end
end

# check if frequent itemsets are the same, as well as their local and global supports
function compare_freqitems(miner1::AbstractMiner, miner2::AbstractMiner)
    if !info(miner1, :istrained)
        mine!(miner1)
    end

    if !info(miner2, :istrained)
        mine!(miner2)
    end

    miner1_freqs = freqitems(miner1)
    miner2_freqs = freqitems(miner2)

    # check if generated frequent itemsets are the same
    @test length(miner1_freqs) == length(miner2_freqs)
    @test all(item -> item in miner1_freqs, miner2_freqs)

    isequal_gsupp(miner1, miner2)
    isequal_lsupp(miner1, miner2)

    isequal_gsupp(miner2, miner1)
    isequal_lsupp(miner2, miner1)
end

# utility to compare arules between miners;
# see compare_arules
function _compare_arules(miner1::AbstractMiner, miner2::AbstractMiner, rule::ARule)
    # global confidence comparison;
    # here it is implied that rules are already generated using generaterules!
    @test miner1.globalmemo[(:gconfidence, rule)] == miner2.globalmemo[(:gconfidence, rule)]

    # local confidence comparison;
    for ninstance in miner1 |> data |> ninstances
        lconfidence(rule, SoleLogics.getinstance(data(miner1), ninstance), miner1)
        lconfidence(rule, SoleLogics.getinstance(data(miner2), ninstance), miner2)

        @test miner1.localmemo[(:lconfidence, rule, ninstance)] ===
        miner2.localmemo[(:lconfidence, rule, ninstance)]
    end
end

# driver to compare arules between miners
function compare_arules(miner1::AbstractMiner, miner2::AbstractMiner)
    generaterules!(miner1) |> collect
    generaterules!(miner2) |> collect

    @test length(arules(miner1)) == length(arules(miner2))

    for rule in arules(miner1)
        @test rule in arules(miner2)
        _compare_arules(miner1, miner2, rule)
    end
end

# perform comparison
function compare(miner1::AbstractMiner, miner2::AbstractMiner)
    compare_freqitems(miner1, miner2)
    compare_arules(miner1, miner2)
end

function compare(miners::Vector{<:AbstractMiner}; verbose::Bool=false)
    mainminer = first(miners)

    for targetminer in miners[2:end]
        verbose && printstyled(
            "\t$(string(mainminer)) vs $(string(targetminer))", color=:green)
    end

    map(targetminer -> compare(mainminer, targetminer), miners[2:end])
end

export isequal_gsupp, isequal_lsupp
export compare_freqitems, compare_arules
export compare

end # end of module
