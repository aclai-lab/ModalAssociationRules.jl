import Base.filter!
using Base.Threads

"""
    struct Miner{
        D<:MineableData,
        I<:Item
    } <: AbstractMiner
        X::D                            # target dataset

        algorithm::Function             # algorithm used to perform extraction

        items::Vector{I}                # alphabet

        # meaningfulness measures
        itemset_constrained_measures::Vector{<:MeaningfulnessMeasure}
        arule_constrained_measures::Vector{<:MeaningfulnessMeasure}

        freqitems::Vector{Itemset}      # collected frequent itemsets
        arules::Vector{ARule}           # collected association rules

        localmemo::LmeasMemo            # local memoization structure
        globalmemo::GmeasMemo           # global memoization structure

        worldfilter::Union{Nothing,WorldFilter}       # metarules about world filterings
        itemset_mining_policies::Vector{<:Function}   # metarules about itemsets mining
        arule_mining_policies::Vector{<:Function}     # metarules about arules mining

        miningstate::MiningState        # mining algorithm miningstate (see documentation)

        info::Info                      # general informations

        # locks on memoization and miningstate structures
        lmemolock::ReentrantLock
        gmemolock::ReentrantLock
        miningstatelock::ReentrantLock
    end

Concrete [`AbstractMiner`](@ref) containing both the data, the logic and the
parameterization to perform association rule mining in the modal setting.

# Examples
```julia-repl
julia> using ModalAssociationRules
julia> using SoleData

# Load NATOPS DataFrame
julia> X_df, y = load_NATOPS();

# Convert NATOPS DataFrame to a Logiset
julia> X = scalarlogiset(X_df)

# Prepare some propositional atoms
julia> p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
julia> q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
julia> r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

# Prepare modal atoms using later relationship - see [`SoleLogics.IntervalRelation`](@ref))
julia> lp = box(IA_L)(p)
julia> lq = diamond(IA_L)(q)
julia> lr = box(IA_L)(r)

# Compose a vector of items, regrouping the atoms defined before
julia> my_alphabet = Vector{Item}([p, q, r, lp, lq, lr])

# Establish which meaningfulness measures you want to define the notion of itemset and
# association rule holding on an instance and on a modal dataset
julia> my_itemsetmeasures = [(gsupport, 0.1, 0.1)]
julia> my_rulemeasures = [(gconfidence, 0.1, 0.1)]

# (optional) Establish a filter to iterate the worlds in a generic modal instance
julia> my_worldfilter = SoleLogics.FunctionalWorldFilter(
        x -> length(x) >= 3 && length(x) <= 10, Interval{Int}
    )

# (optional) Establish a policy to further restrict itemsets that can be considered frequent
julia> my_itemset_mining_policies = [islimited_length_itemset()]

# (optional) Establish a policy to further restrict rules that can be considered
# association rules
julia> my_arule_mining_policies = [
        islimited_length_arule(), isanchored_arule(), isheterogeneous_arule()
    ]

# Create an association rule miner wrapping `fpgrowth` algorithm - see [`fpgrowth`](@ref);
julia> miner = Miner(X, fpgrowth, my_alphabet,
        my_itemsetmeasures, my_rulemeasures,
        worldfilter=my_worldfilter,
        itemset_mining_policies=my_itemset_mining_policies,
        arule_mining_policies=my_arule_mining_policies
    )

# We mine using mine!
# (optional) We could pass kwargs to forward them to the mining algorithm
julia> mine!(miner)

# Print all the mined association rules
julia> for arule in generaterules(miner)
    println(arule)
end
```

See also  [`ARule`](@ref), [`Bulldozer`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Info`](@ref), [`isanchored_arule`](@ref), [`isheterogeneous_arule`](@ref),
[`islimited_length_arule()`](@ref), [`islimited_length_itemset()`](@ref),
[`Item`](@ref), [`Itemset`](@ref), [`GmeasMemo`](@ref), [`LmeasMemo`](@ref),
[`MiningState`](@ref), `SoleLogics.WorldFilter`.
"""
struct Miner{
    D<:MineableData,
    I<:Item
} <: AbstractMiner
    X::D                            # target dataset

    algorithm::Function             # algorithm used to perform extraction

    items::Vector{I}                # alphabet

    # meaningfulness measures
    itemset_constrained_measures::Vector{<:MeaningfulnessMeasure}
    arule_constrained_measures::Vector{<:MeaningfulnessMeasure}

    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    localmemo::LmeasMemo            # local memoization structure
    globalmemo::GmeasMemo           # global memoization structure

    worldfilter::Union{Nothing,WorldFilter}       # metarules about world filterings
    itemset_mining_policies::Vector{<:Function}   # metarules about itemsets mining
    arule_mining_policies::Vector{<:Function}     # metarules about arules mining

    miningstate::MiningState        # mining algorithm miningstate (see documentation)

    info::Info                      # general informations

    # locks on memoization and miningstate structures
    lmemolock::ReentrantLock
    gmemolock::ReentrantLock
    miningstatelock::ReentrantLock

    function Miner(
        X::D,
        algorithm::Function,
        items::Vector{I},

        itemset_constrained_measures::Vector{<:MeaningfulnessMeasure}=[
            (gsupport, 0.1, 0.1)
        ],
        arule_constrained_measures::Vector{<:MeaningfulnessMeasure}=[
            (gconfidence, 0.2, 0.2)
        ];

        worldfilter::Union{Nothing,WorldFilter}=nothing,
        itemset_mining_policies::Vector{<:Function}=Vector{Function}([

        ]),
        arule_mining_policies::Vector{<:Function}=Vector{Function}([
            islimited_length_arule(),
            isanchored_arule(),
            isheterogeneous_arule(),
        ]),

        info::Info=Info(:istrained => false, :size => nothing)
    ) where {
        D<:MineableData,
        I<:Item,
    }
        # dataset frames must be equal
        if !(allequal([SoleLogics.frame(X, ith_instance)
            for ith_instance in 1:ninstances(X)]))
            throw(ArgumentError("Instances frame is shaped " *
                "differently. Please, provide an uniform dataset to guarantee " *
                "mining correctness."
            ))
        end

        # gsupport is crucial to mine association rule
        if !(gsupport in first.(itemset_constrained_measures) ||
            gsupport in first.(itemset_constrained_measures))
            throw(ArgumentError(
                "Miner requires global support " *
                "(gsupport) as meaningfulness measure in order to work properly. " *
                "Please, add a tuple (gsupport, local support threshold, global support " *
                "threshold) to itemset_constrained_measures field.\n" *
                "Local support (lsupport) is needed too, but it is already considered " *
                "internally by gsupport."))
        end

        miningstate = initminingstate(algorithm, X)

        new{D,I}(X, algorithm, unique(items),
            itemset_constrained_measures, arule_constrained_measures,
            Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(),
            worldfilter, itemset_mining_policies, arule_mining_policies,
            miningstate, info,
            ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end
end

"""
    datatype(::Miner{D,I}) where {D<:MineableData,I<:Item}

Retrieve the type of [`MineableData`](@ref) wrapped within the [`Miner`](@ref).
"""
datatype(::Miner{D,I}) where {D<:MineableData,I<:Item} = D

"""
    itemtype(::Miner{D,I}) where {D<:MineableData,I<:Item} = I

Retrieve the most general type of [`Item`](@ref) wrapped within the [`Miner`](@ref).
"""
itemtype(::Miner{D,I}) where {D<:MineableData,I<:Item} = I

"""
    data(miner::Miner)::MineableData

See [`data(::AbstractMiner)`](@ref).
"""
data(miner::Miner)::MineableData = miner.X

"""
    items(miner::Miner)

See [`items(::AbstractMiner)`](@ref).
"""
items(miner::Miner) = miner.items

"""
    algorithm(miner::Miner)::Function

See [`algorithm(::AbstractMiner)`](@ref).
"""
algorithm(miner::Miner)::Function = miner.algorithm

"""
    freqitems(miner::Miner)

See [`freqitems(::AbstractMiner)`](@ref).
"""
freqitems(miner::Miner) = miner.freqitems

"""
arules(miner::Miner)
See [`arules(::AbstractMiner)`](@ref).
"""
arules(miner::Miner) = miner.arules

"""
    itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

See [`itemsetmeasures(::AbstractMiner)`]
"""
itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
miner.itemset_constrained_measures

"""
rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

See [`rulemeasures(miner::AbstractMiner)`](@ref).
"""
rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
miner.arule_constrained_measures

"""
    lmemolock(miner::Miner) = miner.lmemolock

Getter for `miner`'s lock dedicated to protect [`localmemo`](@ref).

See also [`gmemolock`](@ref), [`localmemo`](@ref), [`Miner`](@ref).
"""
lmemolock(miner::Miner) = miner.lmemolock

"""
    gmemolock(miner::Miner) = miner.gmemolock

Getter for `miner`'s lock dedicated to protect [`globalmemo`](@ref).

See also [`globalmemo`](@ref), [`lmemolock`](@ref), [`Miner`](@ref).
"""
gmemolock(miner::Miner) = miner.gmemolock

"""
    miningstatelock(miner::Miner) = miner.miningstatelock

Getter for `miner`'s lock dedicated to protect [`miningstate`](@ref) structure.

See also [`Miner`](@ref), [`miningstate`](@ref).
"""
miningstatelock(miner::Miner) = miner.miningstatelock

"""
localmemo(miner::Miner)::LmeasMemo

See [`localmemo(::AbstractMiner)`](@ref).
"""
localmemo(miner::Miner) = miner.localmemo

"""
    localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by
`miner`.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold) = begin
    lock(lmemolock(miner)) do
        miner.localmemo[key] = val
    end
end

"""
globalmemo(miner::Miner)::GmeasMemo

See [`globalmemo(::AbstractMiner)`](@ref).
"""
globalmemo(miner::Miner) = miner.globalmemo

"""
    globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the global memoization structure wrapped by
`miner`.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold) = begin
    lock(gmemolock(miner)) do
        miner.globalmemo[key] = val
    end
end

"""
    worldfilter(miner::Miner)

See also [`worldfilter(::AbstractMiner)`](@ref).
"""
worldfilter(miner::Miner) = miner.worldfilter

"""
    function itemset_mining_policies(miner::Miner)

See [`itemset_mining_policies(::AbstractMiner)`](@ref).
"""
itemset_mining_policies(miner::Miner) = miner.itemset_mining_policies

"""
    arule_mining_policies(miner::Miner)

See [`itemset_mining_policies(::AbstractMiner)`](@ref).
"""
arule_mining_policies(miner::Miner) = miner.arule_mining_policies

"""
    miningstate!(miner::Miner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`miningstate`](@ref).

See also [`Miner`](@ref), [`hasminingstate`](@ref), [`initminingstate`](@ref),
[`MiningState`](@ref).
"""
miningstate!(miner::Miner, key::Symbol, val) = lock(miningstatelock(miner)) do
     miner.miningstate[key] = val
end
miningstate!(miner::Miner, key::Symbol, inner_key, val) = begin
    lock(miningstatelock(miner)) do
        miner.miningstate[key][inner_key] = val
    end
end

"""
    Base.filter!(
        targets::Vector{Union{ARule,Itemset}},
        policies_pool::Vector{Function}
    )

Apply `Base.filter!` on an [`ARule`](@ref)s or [`Itemset`](@ref)s collection,
w.r.t. the family of policies `policies_pool`.

See also [`ARule`](@ref), [`Base.filter!(::Vector{Itemset}, ::Miner)`](@ref),
[`Itemset`](@ref), [`Base.filter!(::Vector{ARule}, ::Miner)`](@ref), [`Miner`](@ref).
"""
function Base.filter!(
    targets::Union{<:Vector{<:ARule},Vector{<:Itemset}},
    policies_pool::Vector{<:Function}
)
    filter!(target -> all(policy -> policy(target), policies_pool), targets)
end

"""
    Base.filter!(itemsets::Vector{Itemset}, miner::Miner) = filter!(

`filter!` the [`Itemset`](@ref)s wrapped in `miner`.

See also [`Base.filter!(::Vector{ARule}, ::Miner)`](@ref), [`Itemset`](@ref),
[`itemset_mining_policies`](@ref), [`Miner`](@ref).
"""
Base.filter!(itemsets::Vector{<:Itemset}, miner::Miner) = filter!(
    itemsets, itemset_mining_policies(miner)
)

"""
    Base.filter!(arules::Vector{ARule}, miner::Miner)

See also [`ARule`](@ref), [`arule_mining_policies`](@ref),
[`Base.filter!(::Vector{Itemset}, ::Miner)`](@ref), [`Itemset`](@ref), [`Miner`](@ref).
"""
Base.filter!(arules::Vector{ARule}, miner::Miner) = filter!(
    arules, arule_mining_policies(miner)
)

"""
miningstate(miner::Miner)

See [`miningstate(::AbstractMiner)`](@ref).
"""
miningstate(miner::Miner) = miner.miningstate

"""
    info(miner::Miner)::Info = miner.info

Getter for `miner`'s structure holding meta informations about mining.

See also [`Miner`](@ref).
"""
info(miner::Miner)::Info = miner.info



# Miner's utilities


function Base.show(io::IO, miner::Miner)
    println(io, "$(data(miner))")

    println(io, "Alphabet: $(items(miner))\n")
    println(io, "Items measures: $(itemsetmeasures(miner))")
    println(io, "Rules measures: $(rulemeasures(miner))\n")

    println(io, "# of frequent patterns mined: $(length(freqitems(miner)))")
    println(io, "# of association rules mined: $(length(arules(miner)))\n")

    println(io, "Local measures memoization structure entries: " *
        "$(length(miner.localmemo |> keys))")
    println(io, "Global measures memoization structure entries: " *
        "$(length(miner.globalmemo |> keys))\n")

    print(io, "Additional infos: $(info(miner) |> keys)\n")
    print(io, "Specialization fields: $(miningstate(miner) |> keys)")
end

"""
    arule_analysis(arule::ARule, miner::Miner; io::IO=stdout, localities=false)

See also [`arule_analysis(::Arule, ::AbstractMiner)`](@ref), [`ARule`](@ref),
[`Miner`](@ref).
"""
function arule_analysis(
    arule::ARule,
    miner::Miner;
    io::IO=stdout,
    itemset_local_info::Bool=false,
    itemset_global_info::Bool=false,
    arule_measures=[gconfidence, glift, gconviction, gleverage],
    verbose::Bool=false,
    variablenames::Union{Nothing,Vector{String}}=nothing
)
    # print constraints
    if verbose
        itemset_global_info = true
        itemset_local_info = true
    end

    if itemset_local_info
        itemset_global_info = true
    end

    Base.show(io, arule; variablenames=variablenames)
    println(io, "")

    # report global emasures for the rule
    for measure in arule_measures
        gmeassym = measure |> Symbol

        if !haskey(globalmemo(miner), (gmeassym, arule))
            continue
        end

        println(io, "\t$(gmeassym): $(globalmemo(miner, (gmeassym, arule)))")
    end
    # TODO - report local measures for the rule, if there are any

    # report global measures for both antecedent and consequent
    if itemset_global_info
        for measure in itemsetmeasures(miner)
            globalmeasure = first(measure)
            gmeassym = globalmeasure |> Symbol

            println(io, "\t$(gmeassym)(X): " *
                "$(globalmemo(miner, (gmeassym, antecedent(arule))))")
            # if itemset_local_info
            # TODO -  report local measures for the antecedent (use `itemsets_localities`)

            println(io, "\t$(gmeassym)(Y): " *
                "$(globalmemo(miner, (gmeassym, consequent(arule))))")
            # if itemset_local_info
            # TODO -  report local measures for the consequent (use `itemsets_localities`)

            _entire_content = union(antecedent(arule), consequent(arule))
            println(io, "\t$(gmeassym)(X⋃Y): " *
                "$(globalmemo(miner, (gmeassym, _entire_content)))")
            # if itemset_local_info
            # TODO -  report local measures for the consequent (use `itemsets_localities`)

        end
    end
end

"""
    generaterules!(miner::Miner)

See [`generaterules!(::Miner)`](@ref).
"""
function generaterules!(miner::Miner)
    if !info(miner, :istrained)
        throw(ErrorException("The miner should be trained before generating rules. " *
            "Please, invoke `mine!`."
        ))
    end

    return _parallel_generaterules(freqitems(miner), miner)
end

"""
    generaterules(itemsets::AbstractVector{Itemset}, miner::Miner)

See [`generaterules(::AbstractVector{Itemset}, ::AbstractMiner)`](@ref).
"""
@resumable function generaterules(
    itemsets::AbstractVector{Itemset},
    miner::Miner;
    # TODO: this parameter is momentary and enables the computation of additional metrics
    # other than the `rulemeasures` specified within `miner`.
    compute_additional_metrics::Bool=true
)
    # From the original paper at 3.4 here:
    # http://www.rakesh.agrawal-family.com/papers/tkde96passoc_rj.pdf
    #
    # Given a frequent itemset l, rule generation examines each non-empty subset a
    # and generates the rule a => (l-a) with support = support(l) and
    # confidence = support(l)/support(a).
    # This computation can efficiently be done by examining the largest subsets of l first
    # and only proceeding to smaller subsets if the generated rules have the required
    # minimum confidence.
    # For example, given a frequent itemset ABCD, if the rule ABC => D does not have minimum
    # confidence, neither will AB => CD, and so we need not consider it.

    for itemset in filter(x -> length(x) >= 2, itemsets)
        subsets = powerset(itemset)

        for subset in subsets
            # subsets are built already sorted incrementally;
            # hence, since we want the antecedent to be longer initially,
            # the first subset values corresponds to (see comment below)
            # (l-a)
            _consequent = subset == Any[] ? Itemset{Item}() : subset
            # a
            _antecedent = symdiff(itemset, _consequent) |> Itemset

            # degenerate case
            if length(_antecedent) < 1 || length(_consequent) != 1
                continue
            end

            currentrule = ARule((_antecedent, _consequent))

            # apply generation policies to remove unwanted rules
            unwanted = false
            for policy in arule_mining_policies(miner)
                if !policy(currentrule)
                    unwanted = true
                    break
                end
            end

            if unwanted
                continue
            end

            interesting = true

            # compute meaningfulness measures
            for meas in rulemeasures(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, data(miner), lthreshold, miner)

                # some meaningfulness measure test is failed
                if gmeas_result < gthreshold
                    interesting = false
                    break
                end
            end

            # all meaningfulness measure tests passed
            if interesting

                if compute_additional_metrics
                    # TODO: deprecate `compute_additional_metrics` kwarg and move this code
                    # in the cycle where a generic global measure is computed.
                    (_, __lthreshold, _) = rulemeasures(miner) |> first

                    for gmeas_algo in [glift, gconviction, gleverage]
                        gmeas_algo(currentrule, data(miner), __lthreshold, miner)
                    end
                end

                push!(arules(miner), currentrule)
                @yield currentrule
            # since a meaningfulness measure test failed,
            # we don't want to keep generating rules.
            else
                break
            end
        end
    end
end

# TODO: deprecate `generaterules` (which is a generator, working with 1 thread)
# and keep this multi-threaded version.
# This is called in `generaterules!`.
function _parallel_generaterules(
    itemsets::AbstractVector{Itemset},
    miner::Miner;
    # TODO: this parameter is momentary and enables the computation of additional metrics
    # other than the `rulemeasures` specified within `miner`.
    compute_additional_metrics::Bool=true
)
    @threads for itemset in filter(x -> length(x) >= 2, itemsets)
        subsets = powerset(itemset)

        for subset in subsets
            # subsets are built already sorted incrementally;
            # hence, since we want the antecedent to be longer initially,
            # the first subset values corresponds to (see comment below)
            # (l-a)
            _consequent = subset == Any[] ? Itemset{Item}() : subset
            # a
            _antecedent = symdiff(itemset, _consequent) |> Itemset

            # degenerate case
            if length(_antecedent) < 1 || length(_consequent) != 1
                continue
            end

            currentrule = ARule((_antecedent, _consequent))

            # apply generation policies to remove unwanted rules
            unwanted = false
            for policy in arule_mining_policies(miner)
                if !policy(currentrule)
                    unwanted = true
                    break
                end
            end

            if unwanted
                continue
            end

            interesting = true
            for meas in rulemeasures(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, data(miner), lthreshold, miner)

                # some meaningfulness measure test is failed
                if gmeas_result < gthreshold
                    interesting = false
                    break
                end
            end

            # all meaningfulness measure tests passed
            if interesting

                if compute_additional_metrics
                    # TODO: deprecate `compute_additional_metrics` kwarg and move this code
                    # in the cycle where a generic global measure is computed.
                    (_, __lthreshold, _) = rulemeasures(miner) |> first

                    for gmeas_algo in [glift, gconviction, gleverage]
                        gmeas_algo(currentrule, data(miner), __lthreshold, miner)
                    end
                end

                push!(arules(miner), currentrule)
            # since a meaningfulness measure test failed,
            # we don't want to keep generating rules.
            else
                break
            end
        end
    end

    return arules(miner)
end

# some utilities and new dispatches coming from external packages

"""
    function SoleLogics.frame(miner::AbstractMiner)

Getter for the frame wrapped within `miner`'s data field.

See also [`data`](@ref), [`Miner`](@ref).
"""
function SoleLogics.frame(miner::Miner; ith_instance::Integer=1)
    return SoleLogics.frame(data(miner), ith_instance)
end
