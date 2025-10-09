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

        worldfilter::Union{Nothing,WorldFilter} # metarules about world filterings
        itemsetpolicies::Vector{<:Function}    # metarules about itemsets mining
        arule_policies::Vector{<:Function}      # metarules about arules mining

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
julia> my_itemsetpolicies = [islimited_length_itemset()]

# (optional) Establish a policy to further restrict rules that can be considered
# association rules
julia> my_arule_policies = [
        islimited_length_arule(), isanchored_arule(), isheterogeneous_arule()
    ]

# Create an association rule miner wrapping `fpgrowth` algorithm - see [`fpgrowth`](@ref);
julia> miner = Miner(X, fpgrowth, my_alphabet,
        my_itemsetmeasures, my_rulemeasures,
        worldfilter=my_worldfilter,
        itemsetpolicies=my_itemsetpolicies,
        arule_policies=my_arule_policies
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
    N,
    I<:AbstractItem,
    IT<:AbstractItemset
} <: AbstractMiner
    X::D                            # target dataset

    algorithm::Function             # algorithm used to perform extraction

    items::SVector{N,I}             # alphabet

    # meaningfulness measures
    itemset_constrained_measures::Vector{<:MeaningfulnessMeasure}
    arule_constrained_measures::Vector{<:MeaningfulnessMeasure}

    freqitems::Vector{IT}           # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    localmemo::LmeasMemo            # local memoization structure
    globalmemo::GmeasMemo           # global memoization structure

    worldfilter::Union{Nothing,WorldFilter} # metarules about world filterings
    itemsetpolicies::Vector{<:Function}    # metarules about itemsets mining
    arule_policies::Vector{<:Function}      # metarules about arules mining

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
        itemsetpolicies::Vector{<:Function}=Vector{Function}([
#### TODO            isanchored_itemset(), # to ensure one proposition is the point-of-reference
#### TODO            isdimensionally_coherent_itemset() # to ensure no different anchors coexist
        ]),
        arule_policies::Vector{<:Function}=Vector{Function}([
#### TODO            islimited_length_arule(),
#### TODO            isanchored_arule(),
#### TODO            isheterogeneous_arule(),
        ]),

        info::Info=Info(:istrained => false, :size => nothing);
        itemsetprecision::Type{<:Unsigned}=UInt64,
    ) where {
        D<:MineableData,
        I<:AbstractItem
    }
        items = unique(items)

        # dataset frames must be equal
        # TODO - support MultiLogiset mining
        if X isa SoleData.MultiLogiset
            throw(ArgumentError("MultiLogiset mining is currently not supported."))
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

        # number of binary masks needed to retrieve an entire itemset from an ItemCollection
        nitems = length(items)
        nmasks = ceil(nitems / (sizeof(itemsetprecision)*8)) |> Int64
        itemsettype = SmallItemset{nmasks, itemsetprecision}

        new{D,nitems,I,itemsettype}(
            X,
            algorithm,
            SVector{nitems,I}(items),
            itemset_constrained_measures,
            arule_constrained_measures,
            Vector{itemsettype}(),
            Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(),
            worldfilter, itemsetpolicies, arule_policies,
            miningstate, info,
            ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end
end

"""
    datatype(::Miner{D,I}) where {D<:MineableData,I<:Item}

Retrieve the type of [`MineableData`](@ref) wrapped within the [`Miner`](@ref).
"""
datatype(::Miner{D,N,I,IT}) where {D<:MineableData,N,I<:Item,IT<:AbstractItemset} = D

"""
Just a synonym for length(items(miner)).

!!! note
    By knowing the length at construction time, a `SVector` is created, instead of a
    dynamic structure.
"""
nitems(::Miner{D,N,I,IT}) where {D<:MineableData,N,I<:Item,IT<:AbstractItemset} = N

"""
    itemtype(::Miner{D,I}) where {D<:MineableData,I<:Item} = I

Retrieve the most general type of [`Item`](@ref) wrapped within the [`Miner`](@ref).
"""
itemtype(::Miner{D,N,I,IT}) where {D<:MineableData,N,I<:Item,IT<:AbstractItemset} = I

"""
Retrieve the type of the itemsets wrapped within the miner.
"""
itemsettype(::Miner{D,N,I,IT}) where {D<:MineableData,N,I<:Item,IT<:AbstractItemset} = IT

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
arulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

See [`arulemeasures(miner::AbstractMiner)`](@ref).
"""
arulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
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
    function itemsetpolicies(miner::Miner)

See [`itemsetpolicies(::AbstractMiner)`](@ref).
"""
itemsetpolicies(miner::Miner) = miner.itemsetpolicies

"""
    arule_policies(miner::Miner)

See [`itemsetpolicies(::AbstractMiner)`](@ref).
"""
arule_policies(miner::Miner) = miner.arule_policies

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

# TODO - this should be moved to core
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
    targets::Union{<:Vector{<:ARule},Vector{IT}},
    policies_pool::Vector{<:Function}
) where {IT<:AbstractItemset}
    filter!(target -> all(policy -> policy(target), policies_pool), targets)
end

"""
    Base.filter!(itemsets::Vector{Itemset}, miner::Miner)

`filter!` the [`Itemset`](@ref)s wrapped in `miner`.

See also [`Base.filter!(::Vector{ARule}, ::Miner)`](@ref), [`Itemset`](@ref),
[`itemsetpolicies`](@ref), [`Miner`](@ref).
"""
Base.filter!(itemsets::Vector{IT}, miner::Miner) where {IT<:AbstractItemset} = filter!(
    itemsets, itemsetpolicies(miner)
)

"""
    Base.filter!(arules::Vector{ARule}, miner::Miner)

See also [`ARule`](@ref), [`arule_policies`](@ref),
[`Base.filter!(::Vector{Itemset}, ::Miner)`](@ref), [`Itemset`](@ref), [`Miner`](@ref).
"""
Base.filter!(arules::Vector{ARule}, miner::Miner) = filter!(
    arules, arule_policies(miner)
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
    println(io, "Rules measures: $(arulemeasures(miner))\n")

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

See [`generaterules(::AbstractVector{Itemset}, ::Miner)`](@ref).
"""
function generaterules!(miner::Miner)
    if !info(miner, :istrained)
        throw(ErrorException("The miner should be trained before generating rules. " *
            "Please, invoke `mine!`."
        ))
    end

    return generaterules(freqitems(miner), miner)
end


"""
    generaterules(itemsets::AbstractVector{Itemset}, miner::Miner)

Return a generator for the [`ARule`](@ref)s that can be generated starting from the
itemsets in `itemsets`, using the mining state saved within the `miner` structure.

See [`Itemset`](@ref), [`Miner`](@ref).
"""
function generaterules(
    itemsets::AbstractVector{IT},
    miner::Miner
) where {IT<:AbstractItemset}
    arule_lock = ReentrantLock()

    @threads for itemset in filter(x -> length(x) >= 2, itemsets)
        # TODO - we could directly work on the bit representation of the itemset,
        # without converting it from SmallItemset to Itemset.

        # subsets = powerset(itemset)

        subsets = bitpowerset(itemset)
        for subset in subsets

            subset = SmallItemset(SVector(subset...))

            if count_ones(subset) == 0
                continue
            end

            # subsets are built already sorted incrementally;
            # hence, since we want the antecedent to be longer initially,
            # the first subset values corresponds to (see comment below)
            # (l-a)
            _consequent = subset

            # a
            _antecedent = diff(itemset, _consequent)

            # degenerate case
            if length(_antecedent) < 1 || length(_consequent) < 1
                continue
            end

            currentrule = ARule((_antecedent, _consequent))

            # apply generation policies to remove unwanted rules
            unwanted = false
            for policy in arule_policies(miner)
                if !policy(currentrule)
                    unwanted = true
                    break
                end
            end

            if unwanted
                continue
            end

            interesting = true
            for meas in arulemeasures(miner)
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
                lock(arule_lock) do
                    push!(arules(miner), currentrule)
                end
            else
                break
            end
        end
    end

    return arules(miner)
end


# utilities


"""
    partial_deepcopy(original::Miner, newitems::Union{nothing,Vector{I}}=nothing)

Deepcopy a [`Miner`](@ref), but maintain a reference to the original data wrapped
from the original miner.

This is useful if you need to split a Miner in many pieces to
extract frequent [`Itemset`](@ref)s with different characteristics, while maintaining a
common reference to the same [`MineableData`](@ref).

# Arguments
- `original::Miner`: the miner from which perform deepcopy.

# Keyword Arguments
- `new_items::Union{Nothing,Vector{I}}=nothing`: overwrites [`items`](@ref) collection;
- `new_worldfilter::Union{Nothing,WorldFilter}=nothing`: overwrites
[`worldfilter`](@ref);
- `new_itemsetpolicies`::Union{Nothing,Vector{<:Function}}=nothing`: overwrites
[`itemsetpolicies`](@ref);
- `new_arule_policies`::Union{Nothing,Vector{<:Function}}=nothing`: overwrites
[`arule_policies`](@ref).

See also [`anchored_fpgrowth`](@ref), [`arule_policies`](@ref), [`items`](@ref),
[`Itemset`](@ref), [`itemsetpolicies`](@ref), [`MineableData`](@ref), [`Miner`](@ref),
[`worldfilter`](@ref).
"""
function partial_deepcopy(
    original::Miner;
    new_items::Union{Nothing,Vector{I}}=nothing,
    new_worldfilter::Union{Nothing,WorldFilter}=nothing,
    new_itemsetpolicies::Union{Nothing,Vector{<:Function}}=nothing,
    new_arule_policies::Union{Nothing,Vector{<:Function}}=nothing
) where {I<:Item}
    if isnothing(new_items)
        new_items = deepcopy(original |> items)
    end
    if isnothing(new_worldfilter)
        new_worldfilter = deepcopy(original |> worldfilter)
    end
    if isnothing(new_itemsetpolicies)
        new_itemsetpolicies = deepcopy(original |> itemsetpolicies)
    end
    if isnothing(new_arule_policies)
        new_arule_policies = deepcopy(original |> arule_policies)
    end

    return Miner(
        data(original), # keep the reference here
        deepcopy(original |> algorithm),
        new_items,
        deepcopy(original |> itemsetmeasures),
        deepcopy(original |> arulemeasures);
        worldfilter = new_worldfilter,
        itemsetpolicies = new_itemsetpolicies,
        arule_policies = new_arule_policies,
        info = deepcopy(original |> info)
    )
end

# dispatches coming for external packages


"""
    function SoleLogics.frame(miner::AbstractMiner)

Getter for the frame wrapped within `miner`'s data field.

See also [`data`](@ref), [`Miner`](@ref).
"""
function SoleLogics.frame(miner::Miner; ith_instance::Integer=1)
    return frame(data(miner), ith_instance)
end
