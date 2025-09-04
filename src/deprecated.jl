@deprecate apply!(miner::AbstractMiner, X::MineableData; kwargs...) mine!(miner::AbstractMiner; kwargs...)
@deprecate mine!(miner::AbstractMiner, X::MineableData; kwargs...) mine!(miner::AbstractMiner; kwargs...)

@deprecate apriori(miner::Miner, X::MineableData) apriori(miner)
@deprecate fpgrowth(miner::Miner, X::MineableData) fpgrowth(miner)

# @deprecate __lsupport lsupport
# @deprecate __gsupport gsupport
#
# @deprecate _lsupport_logic _dimensionalwise_lsupport_logic
# @deprecate _gsupport_logic _dimensionalwise_gsupport_logic
#
# @deprecate _lconfidence_logic _dimensionalwise_lconfidence_logic
# @deprecate _gconfidence_logic _dimensionalwise_gconfidence_logic


# Old dataset loaders, which now lives in SoleData
include("loaders/natops-loader.jl")
include("loaders/libras-loader.jl")
include("loaders/epilepsy-loader.jl")
include("loaders/hugadb-loader.jl")

export load_NATOPS, load_libras, load_epilepsy
export load_hugadb, filter_hugadb
