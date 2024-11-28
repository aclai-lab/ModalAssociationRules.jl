"""
    struct Bulldozer{
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    } <: AbstractMiner
        # modal dataset data collection
        data::Vector{SoleLogics.LogicalInstance}

        # alphabet
        items::Vector{I}

        # measures associated with mined itemsets
        itemsetmeasures::Vector{<:MeaningfulnessMeasure}

        # meaningfulness measures memoization structure
        localmemo::LmeasMemo

        # special fields related to mining algorithms
        itemset_mining_policies::Vector{<:Function}
        miningstate::MiningState

        # locks on data, memoization structure and miningstate structure
        datalock::ReentrantLock
        memolock::ReentrantLock
        miningstatelock::ReentrantLock
    }

Concrete [`AbstractMiner`](@ref) specialized to mine a single modal instance.

[`Bulldozer`](@ref)'s interface is similar to [`Miner`](@ref)'s one, but contains only
the essential fields necessary to work locally within a Kripke model, and is designed to be
thread-safe.

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
    itemset_mining_policies::Vector{<:Function}
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
        itemset_mining_policies::Vector{<:Function}=Function[],
        miningstate::MiningState=MiningState()
    ) where {D<:MineableData,I<:Item}
        return new{D,I}(data, instancesrange, items, itemsetmeasures, LmeasMemo(),
            itemset_mining_policies, miningstate,
            ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end

    function Bulldozer(miner::Miner, instancesrange::UnitRange{<:Integer})
        data_slice = slicedataset(data(miner), instancesrange)

        return Bulldozer(
                data_slice,
                instancesrange,
                items(miner),
                itemsetmeasures(miner),
                itemset_mining_policies=deepcopy(itemset_mining_policies(miner)),
                miningstate=deepcopy(miningstate(miner))
            )
    end

    function Bulldozer(miner::Miner, ith_instance::Integer)
        # fallback to UnitRange constructor
        Bulldozer(miner, ith_instance:ith_instance)
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
TODO
"""
datatype(::Bulldozer{D}) where {D<:MineableData} = D

"""
TODO
"""
itemtype(::Bulldozer{D,I}) where {D,I<:Item} = I


"""
    instancesrange(bulldozer::Bulldozer)

TODO
"""
instancesrange(bulldozer::Bulldozer) = bulldozer.instancesrange

"""
    instanceprojection(bulldozer::Bulldozer, ith_instance::Integer)

TODO
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
    instance_projection = ith_instance - first(instancesrange(bulldozer)) + 1
    SoleLogics.getinstance(data(bulldozer), instance_projection)
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

See [`localmemo(::AbstractMiner)`](@ref).
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

TODO
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

    bulldozer.localmemo[key] = val
end

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
    function SoleLogics.frame(bulldozer::Bulldozer)

Getter for the frame of the instance wrapped by `bulldozer`.
"""
function SoleLogics.frame(bulldozer::Bulldozer)
    ith_instance = miningstate(bulldozer, :current_instance)
    instance = data(bulldozer, ith_instance)

    SoleLogics.frame(instance.s, ith_instance)
end


"""
    function bulldozer_reduce(b1::Bulldozer, b2::Bulldozer)::LmeasMemo

Reduce many [`Bulldozer`](@ref)s together, merging their local memo structures in linear
time.

See also [`LmeasMemo`](@ref), [`localmemo(::Bulldozer)`](@ref);
"""
function bulldozer_reduce(local_results::AbstractVector{<:Bulldozer})
    b1lmemo = local_results |> first |> localmemo

    for i in 2:length(local_results)
        b2lmemo = local_results[i] |> localmemo
        for k in keys(b2lmemo)
            # There is no need of the `if` statement below, since each Bulldozer
            # refers to a different instance intrinsically for its nature.
            # if haskey(b1lmemo, k) b1lmemo[k] += b2lmemo[k] else
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
    fpgrowth_fragments = DefaultDict{Itemset,Int64}(0)
    min_lsupport_threshold = findmeasure(miner, lsupport)[2]

    for (lmemokey, lmeasvalue) in localmemo
        meas, subject, _ = lmemokey
        localmemo!(miner, lmemokey, lmeasvalue)
        if meas == :lsupport && lmeasvalue >= min_lsupport_threshold
            fpgrowth_fragments[subject] += 1
        end
    end

    return fpgrowth_fragments
end
