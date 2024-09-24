"""
    struct Bulldozer{
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    } <: AbstractMiner
        instance::SoleLogics.LogicalInstance
        ith_instance::Int64

        items::Vector{I}

        lmemo::LmeasMemo
        itemsetmeasures::Vector{IMEAS}
        powerups::Powerup

        datalock::ReentrantLock
        memolock::ReentrantLock
        poweruplock::ReentrantLock
    }

Thread-safe specialized structure, useful to handle mining within a modal `instance`.

When writing your multi-threaded/multi-processes mining algorithm, you can use a
monolithic [`Miner`](@ref) structure to collect the initial parameterization, map many
Bulldozers (merging their local memoization structure) and then reduce the results.

See also [`AbstractMiner`](@ref), [`Miner`](@ref).
"""
struct Bulldozer{
    I<:Item,
    IMEAS<:MeaningfulnessMeasure
} <: AbstractMiner
    instance::SoleLogics.LogicalInstance
    ith_instance::Int64

    items::Vector{I}

    lmemo::LmeasMemo
    itemsetmeasures::Vector{IMEAS}
    powerups::Powerup

    datalock::ReentrantLock
    memolock::ReentrantLock
    poweruplock::ReentrantLock

    function Bulldozer(
        instance::SoleLogics.LogicalInstance,
        ith_instance::Int64,
        items::Vector{I},
        itemsetmeasures::Vector{IMEAS};
        powerups::Powerup=Powerup()
    ) where {
        I<:Item,
        IMEAS<:MeaningfulnessMeasure
    }
        return new{I,IMEAS}(instance, ith_instance, items, LmeasMemo(), itemsetmeasures,
            powerups, ReentrantLock(), ReentrantLock(), ReentrantLock()
        )
    end

    function Bulldozer(miner::Miner, ith_instance::Int64)
        return Bulldozer(
                SoleLogics.getinstance(miner |> data, ith_instance),
                ith_instance,
                items(miner),
                itemsetmeasures(miner),
                powerups=deepcopy(powerups(miner))
            )
    end
end

"""
    instance(bulldozer::Bulldozer)

Getter for the instance wrapped by `bulldozer`.
See also [`Bulldozer`](@ref), [`SoleLogics.LogicalInstance`](@ref).
"""
instance(bulldozer::Bulldozer) = bulldozer.instance

"""
    instancenumber(bulldozer::Bulldozer)

Retrieve the instance number associated with `bulldozer`.
See also [`Bulldozer`](@ref), [`instance(bulldozer::Bulldozer)`](@ref).
"""
instancenumber(bulldozer::Bulldozer) = bulldozer.ith_instance

"""
Getter for the frame of the instance wrapped by `bulldozer`.
See also [`instance(bulldozer::Bulldozer)`](@ref).
"""
function SoleLogics.frame(bulldozer::Bulldozer)
    # consider the instance wrapped by `bulldozer`;
    # get retrieve Kripke frame shape by the instance's parent Logiset.
    _instance = instance(bulldozer)
    SoleLogics.frame(_instance.s, instancenumber(bulldozer))
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
    poweruplock(bulldozer::Bulldozer)

Getter for the [`ReentrantLock`](@ref) associated with the customizable dictionary within
a [`Bulldozer`](@ref).
"""
poweruplock(bulldozer::Bulldozer) = bulldozer.poweruplock

"""
    localmemo!(bulldozer::Bulldozer, key::LmeasMemoKey, val::Threshold)

Setter for [`Bulldozer`](@ref)'s memoization structure.
"""
localmemo!(
    bulldozer::Bulldozer,
    key::LmeasMemoKey,
    val::Threshold
) = lock(memolock(bulldozer)) do
    bulldozer.lmemo[key] = val
end

itemsetmeasures(
    bulldozer::Bulldozer
)::Vector{<:MeaningfulnessMeasure} = bulldozer.itemsetmeasures

"""
    powerups(bulldozer::Bulldozer)::Powerup
    powerups(bulldozer::Bulldozer, key::Symbol)::Any
    powerups(bulldozer::Bulldozer, key::Symbol, inner_key)::Any

Getter for the customizable dictionary wrapped by a [`Bulldozer`](@ref).
"""
powerups(bulldozer::Bulldozer)::Powerup = lock(poweruplock(bulldozer)) do
    bulldozer.powerups
end
powerups(bulldozer::Bulldozer, key::Symbol)::Any = lock(poweruplock(bulldozer)) do
    bulldozer.powerups[key]
end
powerups(
    bulldozer::Bulldozer,
    key::Symbol,
    inner_key
)::Any = lock(poweruplock(bulldozer)) do
    (bulldozer.powerups[key])[inner_key]
end

powerups!(miner::Bulldozer, key::Symbol, val) = lock(poweruplock(miner)) do
    miner.powerups[key] = val
end
powerups!(miner::Bulldozer, key::Symbol, inner_key, val) = lock(poweruplock(miner)) do
    miner.powerups[key][inner_key] = val
end

"""
    haspowerup(miner::Bulldozer, key::Symbol)

Return whether `bulldozer` powerups field contains an entry `key`.
"""
haspowerup(miner::Bulldozer, key::Symbol) = lock(poweruplock(miner)) do
    haskey(miner |> powerups, key)
end

# Just to mantain Miner's interfaces
measures(miner::Bulldozer) = itemsetmeasures(miner)


"""
    function bulldozer_reduce(b1::Bulldozer, b2::Bulldozer)::LmeasMemo

Reduce many [`Bulldozer`](@ref)s together, merging their local memo structures
in linear time.
"""
function bulldozer_reduce(local_results::Vector{Bulldozer})
    b1lmemo = local_results |> first |> localmemo

    for i in 2:length(local_results)
        b2lmemo = local_results[i] |> localmemo
        for k in keys(b2lmemo)
            if haskey(b1lmemo, k)
                b1lmemo[k] += b2lmemo[k]
            else
                b1lmemo[k] = b2lmemo[k]
            end
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
function load_bulldozer!(miner::Miner, lmemo::LmeasMemo)
    # a local memo key is a Tuple{Symbol,ARMSubject,Int64}

    fpgrowth_fragments = DefaultDict{Itemset,Int64}(0)
    min_lsupport_threshold = findmeasure(miner, lsupport)[2]

    for (lmemokey, lmeasvalue) in lmemo
        meas, subject, _ = lmemokey
        localmemo!(miner, lmemokey, lmeasvalue)
        if meas == :lsupport && lmeasvalue > min_lsupport_threshold
            fpgrowth_fragments[subject] += 1
        end
    end

    return fpgrowth_fragments
end
