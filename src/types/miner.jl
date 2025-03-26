"""
Any entity capable of perform association rule mining.

# Interface

Each new concrete miner structure must define the following getters and setters.
Actually, depending on its purposes, a structure may partially implement these dispatches.
For example, [`Miner`](@ref) does completely implement the interface while
[`Bulldozer`](@ref) does not.

- data(miner::AbstractMiner)
- items(miner::AbstractMiner)
- algorithm(miner::AbstractMiner)

- freqitems(miner::AbstractMiner)
- arules(miner::AbstractMiner)

- itemsetmeasures(miner::AbstractMiner)
- rulemeasures(miner::AbstractMiner)

- localmemo(miner::AbstractMiner)
- localmemo!(miner::AbstractMiner)
- globalmemo(miner::AbstractMiner)
- globalmemo!(miner::AbstractMiner)

- worldfilter(miner::AbstractMiner)
- itemset_mining_policies(miner::AbstractMiner)
- arule_mining_policies(miner::AbstractMiner)

- miningstate(miner::AbstractMiner)
- miningstate!(miner::AbstractMiner)
- info(miner::AbstractMiner)

See also [`Miner`](@ref), [`Bulldozer`](@ref).
"""
abstract type AbstractMiner end

"""
    data(miner::AbstractMiner)

Getter for the data to mine, loaded inside `miner`.

See also [`AbstractMiner`](@ref).
"""
data(::AbstractMiner) = error("Not implemented")

"""
    items(miner::AbstractMiner)

Getter for the [`Item`](@ref)s considered during mining by `miner`.

See also [`AbstractMiner`](@ref), [`Item`](@ref).
"""
items(::AbstractMiner) = error("Not implemented")

"""
    algorithm(miner::AbstractMiner)

Reference to the mining algorithm.

See also [`AbstractMiner`](@ref), [`apriori`](@ref), [`fpgrowth`](@ref).
"""
algorithm(::AbstractMiner) = error("Not implemented")


"""
    freqitems(miner::AbstractMiner)

Getter for `miner`'s collection dedicated to store frequent [`Itemset`](@ref)s.

See also [`Item`](@ref), [`Itemset`](@ref)
"""
freqitems(::AbstractMiner) = error("Not implemented")

"""
    arules(miner::AbstractMiner)

Getter for `miner`'s collection dedicated to store interesting [`ARule`](@ref)s.

See also [`ARule`](@ref)
"""
arules(::AbstractMiner) = error("Not implemented")



"""
    itemsetmeasures(miner::AbstractMiner)

Getter for `miner`'s collection dedicated to store the [`MeaningfulnessMeasure`](@ref)s
that must be honored by all the extracted [`Itemset`](@ref)s.

See also [`AbstractMiner`](@ref), [`Itemset`](@ref).
"""
itemsetmeasures(::AbstractMiner) = error("Not implemented")

"""
    rulemeasures(miner::AbstractMiner)

Getter for `miner`'s collection dedicated to store the [`MeaningfulnessMeasure`](@ref)s
that must be honored by all the extracted [`ARule`](@ref)s.

See also [`AbstractMiner`](@ref), [`ARule`](@ref).
"""
rulemeasures(::AbstractMiner) = error("Not implemented")



"""
    localmemo(miner::AbstractMiner)::LmeasMemo
    localmemo(miner::AbstractMiner, key::LmeasMemoKey)

Return the local memoization structure inside `miner`, or a specific entry if a
[`LmeasMemoKey`](@ref) is provided.

See also [`AbstractMiner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo(::AbstractMiner)::LmeasMemo = error("Not implemented.")
localmemo(miner::AbstractMiner, key::LmeasMemoKey)::Union{Nothing,Threshold} = begin
    get(localmemo(miner), key, nothing)
end

"""
    localmemo!(miner::AbstractMiner, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by `miner`.

See also [`AbstractMiner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo!(miner::AbstractMiner, key::LmeasMemoKey, val::Threshold) = begin
    miner.localmemo[key] = val
end

"""
    globalmemo(miner::AbstractMiner)::GmeasMemo
    globalmemo(miner::AbstractMiner, key::GmeasMemoKey)

Return the global memoization structure inside `miner`, or a specific entry if a
[`GmeasMemoKey`](@ref) is provided.

See also [`AbstractMiner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo(::AbstractMiner)::GmeasMemo = error("Not implemented.")
globalmemo(miner::AbstractMiner, key::GmeasMemoKey)::Union{Nothing,Threshold} = begin
    get(globalmemo(miner), key, nothing)
end

"""
    globalmemo!(miner::AbstractMiner, key::GmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the global memoization structure wrapped by
`miner`.

See also [`AbstractMiner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo!(miner::AbstractMiner, key::GmeasMemoKey, val::Threshold) = begin
    miner.globalmemo[key] = val
end



"""
    worldfilter(::AbstractMiner)

Return the world filter policy wrapped within the [`AbstractMiner`](@ref).
This specifies how the worlds of a modal instance must be iterated.

See also [`AbstractMiner`](@ref), [`data(::AbstractMiner)`](@ref), `SoleLogics.WorldFilter`.
"""
worldfilter(::AbstractMiner) = error("Not implemented.")

"""
    function itemset_mining_policies(::AbstractMiner)

Return the mining policies vector wrapped within an [`AbstractMiner`](@ref).
Each mining policies is a meta-rule describing which [`Itemset`](@ref) are accepted
during the mining phase and which are discarded.

!!! warning
    These policies often require to be tailored ad-hoc for a specific mining algorithm,
    and have the role of pruning unwanted explorations of the search space as early as
    possible.

    Keep in mind that you may need to modify some existing policies to make them correct
    and effective for your custom algorithm.

    As far as the algorithms already implemented in this package are concerned,
    generation policies are applied before saving an itemset inside the miner:
    thus, they reduce the waste of memory, but not necessarily of computational time.

See also [`AbstractMiner`](@ref), [`generaterules`](@ref), [`arule_mining_policies`](@ref).
"""
itemset_mining_policies(::AbstractMiner) = error("Not implemented.")

"""
    arule_mining_policies(::AbstractMiner)

Return the association rules generation policies vector wrapped within an
[`AbstractMiner`](@ref).
Each generation policies is a meta-rule describing which [`ARule`](@ref) are accepted
during the generation algorithm and which are discarded.

See also [`AbstractMiner`](@ref), [`generaterules`](@ref),
[`itemset_mining_policies`](@ref).
"""
arule_mining_policies(::AbstractMiner) = error("Not implemented").



"""
    miningstate(miner::AbstractMiner)::MiningState
    miningstate(miner::AbstractMiner, key::Symbol)
    miningstate(miner::AbstractMiner, key::Symbol, inner_key)

Getter for the entire [`MiningState`](@ref) structure currently loaded in `miner`,
a field within it or the value of a specific field.

See also [`AbstractMiner`](@ref), [`hasminingstate`](@ref), [`initminingstate`](@ref),
[`MiningState`](@ref).
"""
miningstate(::AbstractMiner)::MiningState = error("Not implemented.")
miningstate(miner::AbstractMiner, key::Symbol) = miningstate(miner)[key]
miningstate(miner::AbstractMiner, key::Symbol, inner_key) = begin
    miningstate(miner)[key][inner_key]
end

"""
    miningstate!(miner::AbstractMiner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`miningstate`](@ref).

See also [`AbstractMiner`](@ref), [`hasminingstate`](@ref), [`initminingstate`](@ref),
[`MiningState`](@ref).
"""
miningstate!(miner::AbstractMiner, key::Symbol, val) = miner.miningstate[key] = val
miningstate!(miner::AbstractMiner, key::Symbol, inner_key, val) = begin
    miner.miningstate[key][inner_key] = val
end

"""
    hasminingstate(miner::Miner, key::Symbol)

Return whether `miner` [`miningstate`](@ref) contains a field `key`.

See also [`Miner`](@ref), [`MiningState`](@ref), [`miningstate`](@ref).
"""
hasminingstate(miner::AbstractMiner, key::Symbol) = begin
    haskey(miningstate(miner), key)
end

"""
    info(miner::Miner)::MiningState
    info(miner::Miner, key::Symbol)

Getter `miner`'s metadata, such as the elapsed time of the mining algorithm.

See also [`Miner`](@ref), [`MiningState`](@ref).
"""
info(::AbstractMiner)::Info = error("Not implemented")
info(miner::AbstractMiner, key::Symbol) = begin
    _info = info(miner)
    return haskey(_info, key) ? _info[key] : false
end

"""
    info!(miner::Miner, key::Symbol, val)

Setter for `miner`'s metadata.

See also [`hasinfo`](@ref), [`info`](@ref), [`Miner`](@ref).
"""
info!(miner::AbstractMiner, key::Symbol, val) = miner.info[key] = val

"""
    hasinfo(miner::AbstractMiner, key::Symbol)

Return whether `miner` additional informations field contains an entry `key`.

See also [`AbstractMiner`](@ref).
"""
hasinfo(miner::AbstractMiner, key::Symbol) = haskey(info(miner), key)



# General AbstractMiner dispatches

"""
    itemtype(miner::AbstractMiner)

Return the typejoin of all the [`Item`](@ref)s wrapped by `miner`.

See also [`AbstractMiner`](@ref), [`Item`](@ref).
"""
itemtype(miner::AbstractMiner) = begin
    typejoin(typeof.(items(miner))...)
end

"""
    measures(miner::AbstractMiner)::Vector{<:MeaningfulnessMeasure}

Return all the [`MeaningfulnessMeasures`](@ref) wrapped by `miner`.

See also [`AbstractMiner`](@ref), [`itemsetmeasures`](@ref),
[`MeaningfulnessMeasure`](@ref), [`rulemeasures`](@ref).
"""
function measures(miner::AbstractMiner)::Vector{<:MeaningfulnessMeasure}
    return vcat(itemsetmeasures(miner), rulemeasures(miner))
end

"""
    findmeasure(
        miner::AbstractMiner,
        meas::Function;
        recognizer::Function=islocalof
    )::MeaningfulnessMeasure

Retrieve the [`MeaningfulnessMeasure`](@ref) associated with `meas` within `miner`.

See also [`isglobalof`](@ref), [`islocalof`](@ref), [`MeaningfulnessMeasure`](@ref),
[`AbstractMiner`](@ref).
"""
function findmeasure(
    miner::AbstractMiner,
    meas::Function;
    recognizer::Function=islocalof
)::MeaningfulnessMeasure
    try
        return Iterators.filter(
            m -> first(m)==meas || recognizer(meas, first(m)), measures(miner)) |> first
    catch e
        if isa(e, ArgumentError)
            error("The provided miner has no measure $meas. " *
            "Maybe the miner is not initialized properly, and $meas is omitted. " *
            "Please use itemsetmeasures/rulemeasures to check which measures are , " *
            "available and miner's setters to add a new measures and their thresholds.")
        end
    end
end

"""
    getlocalthreshold(miner::AbstractMiner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work locally (that is, analyzing "the inside"
of a dataset's instances) in `miner`.

See [`AbstractMiner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
function getlocalthreshold(miner::AbstractMiner, meas::Function)::Threshold
    return findmeasure(miner, meas)[2]
end

"""
    getglobalthreshold(miner::AbstractMiner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work globally (that is, measuring the behavior
of a specific local-measure across all dataset's instances) in `miner`.

See [`AbstractMiner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
function getglobalthreshold(miner::AbstractMiner, meas::Function)::Threshold
    return findmeasure(miner, meas) |> last
end



"""
    mine!(miner::AbstractMiner; kwargs...)

Synonym for [`apply!](@ref).

See also [`ARule`](@ref), [`Itemset`](@ref), [`apply`](@ref).
"""
function mine!(miner::AbstractMiner; kwargs...)
    return apply!(miner, data(miner); kwargs...)
end

"""
    apply!(miner::AbstractMiner, X::MineableData; forcemining::Bool=false, kwargs...)

Extract association rules from data referenced by `miner` ([`data`](@ref)),
saving the interesting [`Itemset`](@ref)s inside `miner`'s appropriate structure
([`freqitems`](@ref)).

Return a generator of interesting [`ARule`](@ref)s.

!!! note
    All the kwargs are forwarded to the mining algorithm within `miner`.

See also [`ARule`](@ref), [`data`](@ref), [`freqitems`](@ref), [`Itemset`](@ref).
"""
function apply!(miner::AbstractMiner, X::MineableData; forcemining::Bool=false, kwargs...)
    _info = info(miner)

    # if miner is already trained, do not perform mining and return the arules generator
    if haskey(_info, :istrained) && !forcemining
        if _info[:istrained] == true
            @warn "The miner has already been trained. " *
                "To force mining, please set `forcemining=true`."
            return generaterules(freqitems(miner), miner)
        end
    end

    # apply mining algorithm
    algorithm(miner)(miner, X; kwargs...)

    # fill the info field
    if haskey(_info, :istrained)
        info!(miner, :istrained, true)
    end

    if haskey(_info, :size)
        info!(miner, :size, Base.summarysize(miner))
    end

    # return an association rule generator
    return generaterules(freqitems(miner), miner)
end


"""
    generaterules(itemsets::AbstractVector{Itemset}, miner::AbstractMiner)

Raw subroutine of [`generaterules!(miner::AbstractMiner; kwargs...)`](@ref).

Generates [`ARule`](@ref) from the given collection of `itemsets` and `miner`.

The strategy followed is
[described here](https://rakesh.agrawal-family.com/papers/sigmod93assoc.pdf)
at section 2.2.

To establish the meaningfulness of each association rule, check if it meets the global
constraints specified in `rulemeasures(miner)`, and yields the rule if so.

See also [`AbstractMiner`](@ref), [`ARule`](@ref), [`Itemset`](@ref),
[`rulemeasures`](@ref).
"""
@resumable function generaterules(::AbstractVector{Itemset}, ::AbstractMiner)
    error("Not implemented")
end

"""
    generaterules!(miner::Miner; kwargs...)

Return a generator of [`ARule`](@ref)s, given an already trained `miner`.

See also [`AbstractMiner`](@ref), [`ARule`](@ref).
"""
function generaterules!(::AbstractMiner, args...; kwargs...)
    error("Not implemented.")
end


"""
    function arule_analysis(::ARule, ::AbstractMiner, args...; kwargs...)

Detailed print of an [`ARule`](@ref) to standard output.

See also [`AbstractMiner`](@ref), [`ARule`](@ref).
"""
function arule_analysis(::ARule, ::AbstractMiner, args...; kwargs...)
    error("Not implemented.")
end

"""
    all_arule_analysis(miner::AbstractMiner, args...; kwargs...)

Map [`arule_analysis`](@ref) on [`arules`](@ref)(`miner`).
The collection of [`ARule`](@ref)s is sorted decreasingly by [`gconfidence`](@ref).

See also [`AbstractMiner`](@ref), [`ARule`](@ref), [`arule_analysis`](@ref),
[`gconfidence`](@ref).
"""
function all_arule_analysis(miner::AbstractMiner, args...; kwargs...)
    # for each rule, sorted by global confidence, print them
    for r in sort(arules(miner), by = x -> miner.globalmemo[(:gconfidence, x)], rev=true)
        ModalAssociationRules.arule_analysis(
            r, miner, args...;
            variablenames=variablenames,
            itemset_global_info=true,
            kwargs...
        )
    end
end


# interface extending dispatches coming from external packages

"""
    function SoleLogics.frame(::AbstractMiner)

Get the frame wrapped within an [`AbstractMiner`](@ref).

See also [`AbstractMiner`](@ref), `SoleLogics.frame`.
"""
function SoleLogics.frame(::AbstractMiner)
    error("Not implemented.")
end

"""
    function SoleLogics.allworlds(
        miner::AbstractMiner;
        worldfilter::Union{Nothing,WorldFilter}=nothing
    )

Return a generator iterating over all the worlds wrapped within `miner`.

# Arguments
- `miner::AbstractMiner`: miner wrapping atleast one modal instance;
- `ith_instance::Integer=1`: the specific instance you are considering.

!!! note
    If a [`worldfilter`](@ref) is loaded within `miner`, then it is leveareged.

See also [`AbstractMiner`](@ref), `SoleLogics.allworlds`, `SoleLogics.frame`,
[`worldfilter`](@ref).
"""
function SoleLogics.allworlds(
    miner::AbstractMiner;
    ith_instance::Integer=1
)
    _worldfilter = worldfilter(miner)
    if isnothing(_worldfilter)
        return frame(miner; ith_instance=ith_instance) |> SoleLogics.allworlds
    else
        SoleLogics.filterworlds(
            _worldfilter,
            frame(miner; ith_instance=ith_instance) |> SoleLogics.allworlds
        )
    end
end


"""
    function SoleLogics.nworlds(miner::AbstractMiner)

Return the number of worlds returned by [`allworlds(::AbstractMiner)`](@ref).

!!! warning
    Call this method sparingly, as this method does not perform a single lookup but its
    time complexity is linear w.r.t the worlds.

    For now, this is inevitable for implementative reasons.
"""
function SoleLogics.nworlds(miner::AbstractMiner)
    SoleLogics.allworlds(miner) |> collect |> length
end
