"""
    struct Bulldozer{
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    } <: AbstractMiner
        # data mineable by the Bulldozer
        data::D

        # original instance ids associated with the current slice of data
        # if this is 5:10, this this means that the first instance of the slice is
        # the original fifth and so on.
        instancesrange::UnitRange{<:Integer}

        # alphabet
        items::Vector{I}

        # measures associated with mined itemsets
        itemsetmeasures::Vector{<:MeaningfulnessMeasure}

        # meaningfulness measures memoization structure
        localmemo::LmeasMemo

        # special fields related to mining algorithms
        worldfilter::Union{Nothing,WorldFilter}
        itemset_policies::Vector{<:Function}
        miningstate::MiningState

        # locks on data, memoization structure and miningstate structure
        datalock::ReentrantLock
        memolock::ReentrantLock
        miningstatelock::ReentrantLock
    }

Concrete [`AbstractMiner`](@ref) specialized to mine a single modal instance.

[`Bulldozer`](@ref)'s interface is similar to [`Miner`](@ref)'s one, but contains only
the essential fields necessary to work locally within a Kripke structure, and is designed to
be thread-safe.

!!! note
    Bulldozers are designed to easily implement multi-threaded mining algorithms.
    When doing so, you can use a monolithic miner structure to collect the initial
    parameterization, map the computation on many bulldozers, each of which can be easily
    constructed from the miner itself, and then reduce the results together.

See also [`AbstractMiner`](@ref), [`Miner`](@ref).
"""
struct Bulldozer{D<:MineableData,I<:Item} <: AbstractMiner
    # data mineable by the Bulldozer
    data::D

    # original instance ids associated with the current slice of data
    # if this is 5:10, this this means that the first instance of the slice is
    # the original fifth and so on.
    instancesrange::UnitRange{<:Integer}

    # alphabet
    items::Vector{I}

    # measures associated with mined itemsets
    itemsetmeasures::Vector{<:MeaningfulnessMeasure}

    # meaningfulness measures memoization structure
    localmemo::LmeasMemo

    # special fields related to mining algorithms
    worldfilter::Union{Nothing,WorldFilter}
    itemset_policies::Vector{<:Function}
    miningstate::MiningState

    # locks on data, memoization structure and miningstate structure
    datalock::ReentrantLock
    memolock::ReentrantLock
    miningstatelock::ReentrantLock

    function Bulldozer(
        data::D,
        instancesrange::UnitRange{<:Integer},
        items::Vector{I},
        itemsetmeasures::Vector{<:MeaningfulnessMeasure};
        worldfilter::Union{Nothing,WorldFilter}=nothing,
        itemset_policies::Vector{<:Function}=Function[],
        miningstate::MiningState=MiningState()
    ) where {D<:MineableData,I<:Item}
        return new{D,I}(data, instancesrange, items, itemsetmeasures, LmeasMemo(),
            worldfilter, itemset_policies, miningstate,
            ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end

    function Bulldozer(miner::Miner, instancesrange::UnitRange{<:Integer}; kwargs...)
        data_slice = slicedataset(data(miner), instancesrange)

        return Bulldozer(
                data_slice,
                instancesrange,
                items(miner),
                itemsetmeasures(miner),
                worldfilter=deepcopy(worldfilter(miner)),
                itemset_policies=deepcopy(itemset_policies(miner)),
                miningstate=deepcopy(miningstate(miner));
                kwargs...
            )
    end

    function Bulldozer(miner::Miner, ith_instance::Integer; kwargs...)
        # fallback to UnitRange constructor
        Bulldozer(miner, ith_instance:ith_instance; kwargs...)
    end
end

"""
    datalock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the
[`SoleLogics.LogicalInstance`](@ref) wrapped by a [`Bulldozer`](@ref).
"""
datalock(bulldozer::Bulldozer) = bulldozer.datalock

"""
    memolock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the inner [`Bulldozer`](@ref)'s
memoization structure
"""
memolock(bulldozer::Bulldozer) = bulldozer.memolock

"""
    miningstatelock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the customizable dictionary within
a [`Bulldozer`](@ref).
"""
miningstatelock(bulldozer::Bulldozer) = bulldozer.miningstatelock

"""
    datatype(::Bulldozer{D}) where {D<:MineableData} = D

Return the type of the [`MineableData`](@ref) given by [`data(::Bulldozer)`](@ref).

See also [`Bulldozer`](@ref), [`data(::Bulldozer)`](@ref), [`MineableData`](@ref).
"""
datatype(::Bulldozer{D}) where {D<:MineableData} = D


"""
    itemtype(::Bulldozer{D,I}) where {D,I<:Item} = I

Return the type of the [`Item`](@ref)s given by [`items(::Bulldozer)`](@ref).

See also [`Bulldozer`](@ref), [`items(::Bulldozer)`](@ref), [`MineableData`](@ref).
"""
itemtype(::Bulldozer{D,I}) where {D,I<:Item} = I



"""
    instancesrange(bulldozer::Bulldozer)

Return the instance slice range on which `bulldozer` is working.
"""
instancesrange(bulldozer::Bulldozer) = bulldozer.instancesrange

"""
    instanceprojection(bulldozer::Bulldozer, ith_instance::Integer)

Maps the `ith_instance` on a range starting from 1, instead of [`instancerange`](@ref).

See also [`Bulldozer`](@ref), [`instancerange`](@ref).
"""
instanceprojection(bulldozer::Bulldozer, ith_instance::Integer) = begin
    return ith_instance - first(instancesrange(bulldozer)) + 1
end

"""
    data(bulldozer::Bulldozer)
    data(bulldozer::Bulldozer, ith_instance::Integer)

Getter for the [`MineableData`](@ref) wrapped within `bulldozer`, or a specific instance.

See [`data(::AbstractMiner)`](@ref), [`SoleLogics.LogicalInstance`](@ref),
[`MineableData`](@ref).
"""
data(bulldozer::Bulldozer) = bulldozer.data
data(bulldozer::Bulldozer, ith_instance::Integer) = begin
    SoleLogics.getinstance(data(bulldozer), instanceprojection(bulldozer, ith_instance))
end

"""
items(bulldozer::Bulldozer)

See [`items(::AbstractMiner)`](@ref).
"""
items(bulldozer::Bulldozer) = bulldozer.items

"""
    itemsetmeasures(bulldozer::Bulldozer)::Vector{<:MeaningfulnessMeasure}

    See also [`itemsetmeasures(::AbstractMiner)`](@ref).
    """
itemsetmeasures(
    bulldozer::Bulldozer
)::Vector{<:MeaningfulnessMeasure} = bulldozer.itemsetmeasures

"""
    localmemo(bulldozer::Bulldozer)
    localmemo(bulldozer::Bulldozer, key::LmeasMemoKey)

See [`localmemo(::AbstractMiner)`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo(bulldozer::Bulldozer) = bulldozer.localmemo
localmemo(bulldozer::Bulldozer, key::LmeasMemoKey; isprojected::Bool=false) = begin
    # see localmemo!: when memoizing a new local measure,
    # the number of the instance is projected depending on
    # the `instancesrange` of the Bulldozer.

    if !isprojected
        _symbol, _armsubject, _ith_instance = key
        _ith_instance = _ith_instance + first(instancesrange(bulldozer)) - 1
        key = LmeasMemoKey((_symbol, _armsubject, _ith_instance))
    end

    get(localmemo(bulldozer), key, nothing)
end

"""
    localmemo!(bulldozer::Bulldozer, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by
`bulldozer`.

See also [`Bulldozer`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo!(
    bulldozer::Bulldozer,
    key::LmeasMemoKey,
    val::Threshold;
    isprojected::Bool=false
) = begin

    if !isprojected
        _symbol, _armsubject, _ith_instance = key
        _ith_instance = _ith_instance + first(instancesrange(bulldozer)) - 1
        key = LmeasMemoKey((_symbol, _armsubject, _ith_instance))
    end

    lock(datalock(bulldozer)) do
        bulldozer.localmemo[key] = val
    end
end



"""
    worldfilter(bulldozer::Bulldozer) = bulldozer.worldfilter

See also [`worldfilter(::AbstractMiner)`](@ref).
"""
worldfilter(bulldozer::Bulldozer) = bulldozer.worldfilter

"""
    itemset_policies(bulldozer::Bulldozer)

See also [`itemset_policies(::AbstractMiner)`](@ref).
"""
itemset_policies(bulldozer::Bulldozer) = bulldozer.itemset_policies


"""
    miningstate(bulldozer::Bulldozer)::MiningState
    miningstate(bulldozer::Bulldozer, key::Symbol)::Any
    miningstate(bulldozer::Bulldozer, key::Symbol, inner_key)::Any

Getter for the customizable dictionary wrapped by a [`Bulldozer`](@ref).

See also [`miningstate!(::Bulldozer)`].
"""
miningstate(bulldozer::Bulldozer)::MiningState = lock(miningstatelock(bulldozer)) do
    bulldozer.miningstate
end
miningstate(bulldozer::Bulldozer, key::Symbol)::Any = lock(miningstatelock(bulldozer)) do
    miningstate(bulldozer)[key]
end
miningstate(
    bulldozer::Bulldozer,
    key::Symbol,
    inner_key
)::Any = lock(miningstatelock(bulldozer)) do
    miningstate(bulldozer, key)[inner_key]
end

"""
    miningstate!(bulldozer::Bulldozer, key::Symbol, val)
    miningstate!(bulldozer::Bulldozer, key::Symbol, inner_key, val)

Setter for the content of a specific `bulldozer`'s [`miningstate`](@ref).
"""
miningstate!(bulldozer::Bulldozer, key::Symbol, val) = lock(miningstatelock(bulldozer)) do
    bulldozer.miningstate[key] = val
end
miningstate!(bulldozer::Bulldozer, key::Symbol, inner_key, val) = begin
    lock(miningstatelock(bulldozer)) do
        bulldozer.miningstate[key][inner_key] = val
    end
end

"""
    hasminingstate(bulldozer::Bulldozer, key::Symbol)

Return whether `bulldozer` miningstate field contains a field `key`.

See also [`Bulldozer`](@ref), [`miningstate`](@ref), [`miningstate!`](@ref).
"""
hasminingstate(bulldozer::Bulldozer, key::Symbol) = lock(miningstatelock(bulldozer)) do
    haskey(bulldozer |> miningstate, key)
end

"""
    measures(bulldozer::Bulldozer)

Synonym for [`itemsetmeasures`](ref).
This exists to adhere to [`Miner`](@ref)'s interface.

See also [`Bulldozer`](@ref), [`itemsetmeasures`](@ref), [`Miner`](@ref).
"""
measures(bulldozer::Bulldozer) = itemsetmeasures(bulldozer)



# utilities

"""
    function miner_reduce!(b1::Bulldozer, b2::Bulldozer)::LmeasMemo

Reduce many [`Bulldozer`](@ref)s together, merging their local memo structures in linear
time.

!!! note
    This method will soon be deprecated in favour of a general dispatch
    miner_reduce!(::AbstractVector{M})

See also [`LmeasMemo`](@ref), [`localmemo(::Bulldozer)`](@ref);
"""
function miner_reduce!(local_results::AbstractVector{B}) where {B<:Bulldozer}
    b1lmemo = local_results |> first |> localmemo

    for i in 2:length(local_results)
        b2lmemo = local_results[i] |> localmemo
        for k in keys(b2lmemo)
            b1lmemo[k] = b2lmemo[k]
        end
    end

    return b1lmemo
end

"""
    function load_localmemo!(miner::AbstractMiner, localmemo::LmeasMemo)

Load a local memoization structure inside `miner`.
Also, returns a dictionary associating each loaded local [`Itemset`](@ref) loaded to its
its global support, in order to simplify `miner`'s job when working in the global setting.

See also [`Itemset`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref), [`Miner`](@ref).
"""
function load_localmemo!(miner::AbstractMiner, localmemo::LmeasMemo)
    fragments = DefaultDict{Itemset,Integer}(0)
    min_lsupport_threshold = findmeasure(miner, lsupport)[2]

    for (lmemokey, lmeasvalue) in localmemo
        meas, subject, _ = lmemokey
        localmemo!(miner, lmemokey, lmeasvalue)
        if meas == :lsupport && lmeasvalue >= min_lsupport_threshold
            fragments[subject] += 1
        end
    end

    return fragments
end

# more utilities and new dispatches coming from external packages

"""
    function SoleLogics.frame(bulldozer::Bulldozer)

Getter for the frame wrapped within `bulldozer`'s i-th instance.

See also [`Bulldozer`](@ref), [`data`](@ref), [`miningstate`](@ref).
"""
function SoleLogics.frame(bulldozer::Bulldozer; kwargs...)
    ith_instance = miningstate(bulldozer, :current_instance)
    instance = data(bulldozer, ith_instance)

    frame(instance.s, ith_instance)
end
