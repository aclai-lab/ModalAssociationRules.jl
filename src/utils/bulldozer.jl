"""
    struct Bulldozer{
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    } <: AbstractMiner
        # reference to a modal dataset ith instance
        instance::SoleLogics.LogicalInstance
        ith_instance::Integer

        items::Vector{I}                    # alphabet

        itemsetmeasures::Vector{IMEAS}      # measures associated with mined itemsets

        localmemo::LmeasMemo                # meaningfulness measures memoization structure

        miningstate::MiningState            # special fields related to mining algorithms

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
struct Bulldozer{I<:Item} <: AbstractMiner
    # reference to a modal dataset ith instance
    instance::SoleLogics.LogicalInstance
    ith_instance::Integer

    items::Vector{I}                # alphabet

    # measures associated with mined itemsets
    itemsetmeasures::Vector{<:MeaningfulnessMeasure}

    localmemo::LmeasMemo            # meaningfulness measures memoization structure

    miningstate::MiningState        # special fields related to mining algorithms

    # locks on data, memoization structure and miningstate structure
    datalock::ReentrantLock
    memolock::ReentrantLock
    miningstatelock::ReentrantLock

    function Bulldozer(
        instance::SoleLogics.LogicalInstance,
        ith_instance::Integer,
        items::Vector{I},
        itemsetmeasures::Vector{<:MeaningfulnessMeasure};
        miningstate::MiningState=MiningState()
    ) where {I<:Item}
        return new{I}(instance, ith_instance, items, itemsetmeasures, LmeasMemo(),
            miningstate, ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end

    function Bulldozer(miner::Miner, ith_instance::Integer)
        return Bulldozer(
                SoleLogics.getinstance(miner |> data, ith_instance),
                ith_instance,
                items(miner),
                itemsetmeasures(miner),
                miningstate=deepcopy(miningstate(miner))
            )
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
itemtype(::Bulldozer{I}) where {I<:Item} = I

"""
    data(bulldozer::Bulldozer)

See [`data(::AbstractMiner)`](@ref), [`SoleLogics.LogicalInstance`](@ref).
"""
data(bulldozer::Bulldozer) = bulldozer.instance

"""
    items(bulldozer::Bulldozer)

See [`items(::AbstractMiner)`](@ref).
"""
items(bulldozer::Bulldozer) = bulldozer.items

"""
    instance(bulldozer::Bulldozer) = bulldozer.instance

Getter for the instance wrapped by `bulldozer`'s.
Synonym for [`data(::Bulldozer)`](@ref).

See also [`instancenumber(::Bulldozer)`](@ref).
"""
instance(bulldozer::Bulldozer) = bulldozer.instance

"""
    instancenumber(bulldozer::Bulldozer)

Retrieve the instance number associated with `bulldozer`.

See also [`Bulldozer`](@ref), [`data(::Bulldozer)`](@ref).
"""
instancenumber(bulldozer::Bulldozer) = bulldozer.ith_instance

"""
    itemsetmeasures(bulldozer::Bulldozer)::Vector{<:MeaningfulnessMeasure}

See also [`itemsetmeasures(::AbstractMiner)`](@ref).
"""
itemsetmeasures(
    bulldozer::Bulldozer
)::Vector{<:MeaningfulnessMeasure} = bulldozer.itemsetmeasures

"""
    localmemo(miner::Bulldozer)

See [`localmemo(::AbstractMiner)`](@ref).
"""
localmemo(miner::Bulldozer) = miner.localmemo

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
    miningstate!(miner::Bulldozer, key::Symbol, val)
    miningstate!(miner::Bulldozer, key::Symbol, inner_key, val)

Setter for the content of a specific `miner`'s [`miningstate`](@ref).
"""
miningstate!(miner::Bulldozer, key::Symbol, val) = lock(miningstatelock(miner)) do
    miner.miningstate[key] = val
end
miningstate!(miner::Bulldozer, key::Symbol, inner_key, val) = begin
    lock(miningstatelock(miner)) do
        miner.miningstate[key][inner_key] = val
    end
end

"""
    hasminingstate(miner::Bulldozer, key::Symbol)

Return whether `miner` miningstate field contains a field `key`.

See also [`Bulldozer`](@ref), [`miningstate`](@ref), [`miningstate!`](@ref).
"""
hasminingstate(miner::Bulldozer, key::Symbol) = lock(miningstatelock(miner)) do
    haskey(miner |> miningstate, key)
end

"""
    measures(miner::Bulldozer)

Synonym for [`itemsetmeasures`](ref).
This exists to adhere to [`Miner`](@ref)'s interface.

See also [`itemsetmeasures`](@ref), [`Miner`](@ref).
"""
measures(miner::Bulldozer) = itemsetmeasures(miner)



# utilities

"""
    function SoleLogics.frame(bulldozer::Bulldozer)

Getter for the frame of the instance wrapped by `bulldozer`.
See also [`instance(::Bulldozer)`](@ref).
"""
function SoleLogics.frame(bulldozer::Bulldozer)
    _instance = instance(bulldozer)
    SoleLogics.frame(_instance.s, instancenumber(bulldozer))
end


"""
    function bulldozer_reduce(b1::Bulldozer, b2::Bulldozer)::LmeasMemo

Reduce many [`Bulldozer`](@ref)s together, merging their local memo structures in linear
time.

See also [`LmeasMemo`](@ref), [`localmemo(::Bulldozer)`](@ref);
"""
function bulldozer_reduce(local_results::AbstractVector{Bulldozer})
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
Load a local memoization structure inside `miner`.
Also, returns a dictionary associating each loaded local [`Itemset`](@ref) loaded to its
its global support, in order to simplify `miner`'s job when working in the global setting.

See also [`Itemset`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref), [`Miner`](@ref).
"""
function load_localmemo!(miner::AbstractMiner, localmemo::LmeasMemo)
    # remember a local memo key is a Tuple{Symbol,ARMSubject,Int64}

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
