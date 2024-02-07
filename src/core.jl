############################################################################################
#### Fundamental definitions ###############################################################
############################################################################################
const Threshold = Float64
const Item = SoleLogics.Formula
const Itemset = Vector{Item}

function Itemset(item::Item)
    Itemset([item])
end
function Itemset(itemsets::Vector{Itemset})
    Itemset(union(itemsets...))
end

value(itemset::Itemset) = LeftmostConjunctiveForm(itemset)

const ARule = Tuple{Itemset,Itemset} # NOTE: see SoleLogics.Rule
antecedent(rule::ARule) = first(rule)
consequent(rule::ARule) = last(rule)

# See meaningfulness measures section.
# A ConstrainedMeasure is a tuple shaped as (global measure, local threshold, global threshold)
const ConstrainedMeasure = Tuple{Function, Threshold, Threshold}

# Dynamic programming utility structures
const MemoARM = Union{Itemset,ARule} # memoizable association-rule-mining types

const LmeasMemoKey = Tuple{Symbol,MemoARM,Integer} # (local measure, itemset/arule, the world where is applied)
const LmeasMemo = Dict{LmeasMemoKey,Float64} # local measure of an itemset on a world => value

const GmeasMemoKey = Tuple{Symbol,MemoARM}
const GmeasMemo = Dict{GmeasMemoKey,Float64} # global measure of an itemset/arule => value

# Given an itemsets vector, return the pairwise combination of such itemsets such that
# the combination's length is `newlength`.
function combine(itemsets::Vector{<:Itemset}, newlength::Integer)
    return Iterators.map(
        x -> union(x[1], x[2]), # NOTE: repetition here
        Iterators.filter(
            x -> length(union(x[1],x[2])) == newlength,
            combinations(itemsets,2)
        )
    )
end

############################################################################################
#### Association rule miner machine ########################################################
############################################################################################

"""
Generic machine learning model interface to perform association rules extraction.
"""
struct ARuleMiner
    # target dataset
    X::AbstractDataset
    # algorithm used to perform extraction
    algo::FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

    alphabet::Vector{Item} # NOTE: cannot instanciate Item inside ExplicitAlphabet

    # meaningfulness measures
    item_constrained_measures::Vector{<:ConstrainedMeasure}
    rule_constrained_measures::Vector{<:ConstrainedMeasure}

    nonfreqitems::Vector{Itemset}   # non-frequent itemsets dump
    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    lmemo::LmeasMemo                # local memoization structure
    gmemo::GmeasMemo                # global memoization structure
    info::NamedTuple                # general informations

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item},
        item_constrained_measures::Vector{<:ConstrainedMeasure},
        rule_constrained_measures::Vector{<:ConstrainedMeasure},
    )
        new(X, MiningAlgo(algo), alphabet,
            item_constrained_measures,
            rule_constrained_measures,
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), (;))
    end

    function ARuleMiner(
        X::AbstractDataset,
        algo::Function,
        alphabet::Vector{Item}
    )
        # ARuleMiner(X, MiningAlgo(algo), alphabet,
        new(X, MiningAlgo(algo), alphabet,
            [(gsupport, 0.5, 0.5)], [(gconfidence, 0.5, 0.5)],
            Vector{Itemset}([]), Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), (;)
        );
    end
end

const MiningAlgo = FunctionWrapper{Nothing,Tuple{ARuleMiner,AbstractDataset}}

dataset(miner::ARuleMiner) = miner.X
algorithm(miner::ARuleMiner) = miner.algo
alphabet(miner::ARuleMiner) = miner.alphabet

item_meas(miner::ARuleMiner) = miner.item_constrained_measures
rule_meas(miner::ARuleMiner) = miner.rule_constrained_measures

freqitems(miner::ARuleMiner) = miner.freqitems
nonfreqitems(miner::ARuleMiner) = miner.nonfreqitems
arules(miner::ARuleMiner) = miner.arules

setlocalmemo(miner::ARuleMiner, key::LmeasMemoKey, val::Float64) = miner.lmemo[key] = val
getlocalmemo(miner::ARuleMiner, key::LmeasMemoKey) = get(miner.lmemo, key, nothing)

setglobalmemo(miner::ARuleMiner, key::GmeasMemoKey, val::Float64) = miner.gmemo[key] = val
getglobalmemo(miner::ARuleMiner, key::GmeasMemoKey) = get(miner.gmemo, key, nothing)

function mine(miner::ARuleMiner)
    apply(miner, dataset(miner))
end

function apply(miner::ARuleMiner, X::AbstractDataset)
    # extract frequent itemsets
    miner.algo(miner, X)
    return true
end

@resumable function arules_generator(
    itemsets::Vector{Itemset},
    miner::ARuleMiner
)
    for itemset in itemsets
        subsets = powerset(itemset)
        for subset in subsets
            _antecedent = subset
            _consequent = symdiff(itemset, subset)

            if length(_antecedent) == 0 || length(_consequent) == 0
                continue
            end

            interesting = true
            currentrule = ARule((_antecedent, _consequent))

            for meas in rule_meas(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, dataset(miner), lthreshold, miner=miner)

                if gmeas_result < gthreshold
                    interesting = false
                    break
                end
            end

            @yield currentrule
        end
    end
end

############################################################################################
#### Meaningfulness measures ###############################################################
############################################################################################

function lsupport(
    itemset::Itemset,
    logi_instance::LogicalInstance;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # retrieve logiset, and the specific instance
    X, i_instance = logi_instance.s, logi_instance.i_instance

    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getlocalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    # compute local measure, then divide it by the instance total number of worlds
    ans = sum([check(value(itemset), X, i_instance, w) for w in allworlds(X, i_instance)])
    ans = ans / nworlds(X, i_instance)

    if !isnothing(miner)
        setlocalmemo(miner, memokey, ans)
    end

    return ans
end

function gsupport(
    itemset::Itemset,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gsupport), itemset))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getglobalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    # compute global measure, then divide it by the dataset total number of instances
    ans = sum([lsupport(itemset, getinstance(X, i_instance); miner=miner) >= threshold
        for i_instance in 1:ninstances(X)])
    ans = ans / ninstances(X)

    if !isnothing(miner)
        setglobalmemo(miner, memokey, ans)
    end

    return ans
end

function lconfidence(
    rule::ARule,
    logi_instance::LogicalInstance;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lconfidence), rule, logi_instance.i_instance))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getglobalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    ans = lsupport(SoleRules.merge(_antecedent, _consequent), logi_instance; miner=miner) /
        lsupport(_antecedent, logi_instance; miner=miner)

    if !isnothing(miner)
        setlocalmemo(miner, memokey, ans)
    end

    return ans
end

function gconfidence(
    rule::ARule,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,ARuleMiner} = nothing
)::Float64
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gconfidence), rule))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner)
        memoized = getglobalmemo(miner, memokey)
        if !isnothing(memoized) return memoized end
    end

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)

    ans = gsupport(union(_antecedent, _consequent), X, threshold; miner=miner) /
        gsupport(_antecedent, X, threshold; miner=miner)

    if !isnothing(miner)
        setglobalmemo(miner, memokey, ans)
    end

    return ans
end
