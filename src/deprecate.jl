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


# Old dataset loader exports, which now lives in SoleData
export load_epilepsy, load_hugadb, load_libras, load_NATOPS

using SoleData.Artifacts: load
using SoleData.Artifacts: EpilepsyLoader, HuGaDBLoader, LibrasLoader, NatopsLoader

@deprecate load_epilepsy() load(EpilepsyLoader())
@deprecate load_epilepsy(::String, ::String) load(EpilepsyLoader())

@deprecate load_hugadb() load(HuGaDBLoader())
@deprecate load_hugadb(::String, ::String) load(HuGaDBLoader())

@deprecate load_libras() load(LibrasLoader())
@deprecate load_libras(::String, ::String) load(LibrasLoader())

@deprecate load_NATOPS() load(NatopsLoader())
@deprecate load_NATOPS(::String, ::String) load(NatopsLoader())
