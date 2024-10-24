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
- globalmemo(miner::AbstractMiner)

- miningstate(miner::AbstractMiner)
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
    localmemo(miner::Miner)::LmeasMemo
    localmemo(miner::Miner, key::LmeasMemoKey)

Return the local memoization structure inside `miner`, or a specific entry if a
[`LmeasMemoKey`](@ref) is provided.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo(::AbstractMiner)::LmeasMemo = error("Not implemented.")
localmemo(miner::AbstractMiner, key::LmeasMemoKey)::Union{Nothing,Threshold} = begin
    get(localmemo(miner), key, nothing)
end

"""
    localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by `miner`.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo!(miner::AbstractMiner, key::LmeasMemoKey, val::Threshold) = begin
    miner.localmemo[key] = val
end

"""
    globalmemo(miner::Miner)::GmeasMemo
    globalmemo(miner::Miner, key::GmeasMemoKey)

Return the global memoization structure inside `miner`, or a specific entry if a
[`GmeasMemoKey`](@ref) is provided.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo(::AbstractMiner)::GmeasMemo = error("Not implemented.")
globalmemo(miner::AbstractMiner, key::GmeasMemoKey)::Union{Nothing,Threshold} = begin
    get(globalmemo(miner), key, nothing)
end

"""
    globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the global memoization structure wrapped by
`miner`.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo!(miner::AbstractMiner, key::GmeasMemoKey, val::Threshold) = begin
    miner.globalmemo[key] = val
end



"""
    miningstate(miner::Miner)::MiningState
    miningstate(miner::Miner, key::Symbol)
    miningstate(miner::Miner, key::Symbol, inner_key)

Getter for the entire [`MiningState`](@ref) structure currently loaded in `miner`,
a field within it or the value of a specific field.

See also [`Miner`](@ref), [`hasminingstate`](@ref), [`initminingstate`](@ref),
[`MiningState`](@ref).
"""
miningstate(::AbstractMiner)::MiningState = error("Not implemented.")
miningstate(miner::AbstractMiner, key::Symbol) = miningstate(miner)[key]
miningstate(miner::AbstractMiner, key::Symbol, inner_key) = begin
    miningstate(miner)[key][inner_key]
end

"""
    miningstate!(miner::Miner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`miningstate`](@ref).

See also [`Miner`](@ref), [`hasminingstate`](@ref), [`initminingstate`](@ref),
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
info(miner::AbstractMiner, key::Symbol) = info(miner)[key]

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
    if info(miner, :istrained) && !forcemining
        @warn "The miner has already been trained. To force mining, set `forcemining=true`."
        return Nothing
    end

    algorithm(miner)(miner, X; kwargs...)
    info!(miner, :istrained, true)

    return generaterules(freqitems(miner), miner)
end

"""
    generaterules!(miner::AbstractMiner; kwargs...)

Return a generator of [`ARule`](@ref)s, given an already trained `miner`.

See also [`ARule`](@ref), [`AbstractMiner`](@ref).
"""
function generaterules!(miner::AbstractMiner)
    if !info(miner, :istrained)
        error("The miner should be trained before generating rules. " *
            "Please, invoke `mine!`.")
    end

    return generaterules(freqitems(miner), miner)
end
