import Base.==, Base.hash

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
- arulemeasures(miner::AbstractMiner)

- localmemo(miner::AbstractMiner)
- localmemo!(miner::AbstractMiner)
- globalmemo(miner::AbstractMiner)
- globalmemo!(miner::AbstractMiner)

- worldfilter(miner::AbstractMiner)
- itemsetpolicies(miner::AbstractMiner)
- arulepolicies(miner::AbstractMiner)

- miningstate(miner::AbstractMiner)
- miningstate!(miner::AbstractMiner)
- info(miner::AbstractMiner)

See also [`Miner`](@ref), [`Bulldozer`](@ref).
"""
abstract type AbstractMiner end

# AbstractItem and ItemCollection const
include("types/item.jl")

# AbstractItemset, with Itemset and ExplicitItemset
include("types/itemset.jl")

# Association rule definition
include("types/arule.jl")

# Constants permeating all the package
include("types/const.jl")

"""
    initminingstate(::Function, ::MineableData)

This trait defines how to initialize the [`MiningState`](@ref) structure of an
[`AbstractMiner`](@ref), in order to customize it to your needings depending on a specific
function/data pairing.

See ealso [`hasminingstate`](@ref), [`AbstractMiner`](@ref), [`MiningState`](@ref),
[`miningstate`](@ref).
"""
initminingstate(::Function, ::MineableData)::MiningState = MiningState()

"""
    applypolicies!(itemsets::Vector{IT}, miner::Miner) where {IT<:AbstractItemset}
    applypolicies!(arules::Vector{ARule}, miner::Miner)

Apply the policies wrapped within `miner` to the first argument, which can either be
a collection of [`AbstractItemset`](@ref) or of [`ARule`](@ref).

See also [`itemsetpolicies`](@ref).
"""
function applypolicies!(
    itemsets::Vector{IT},
    miner::Miner
) where {IT<:AbstractItemset}
    filter!(target -> all(policy -> policy(target, miner), policies_pool), itemsets)
end
function applypolicies!(
    arules::Vector{ARule},
    miner::Miner
)
    filter!(target -> all(policy -> policy(target, miner), policies_pool), arules)
end
