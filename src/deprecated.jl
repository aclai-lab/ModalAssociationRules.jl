@deprecate apriori(miner::Miner, X::MineableData) = apriori(miner)
@deprecate fpgrowth(miner::Miner, X::MineableData) = fpgrowth(miner)

@deprecate __lsupport lsupport
@deprecate __gsupport gsupport

@deprecate _lsupport_logic _dimensionalwise_lsupport_logic
@deprecate _gsupport_logic _dimensionalwise_gsupport_logic

@deprecate _lconfidence_logic _dimensionalwise_lconfidence_logic
@deprecate _gconfidence_logic _dimensionalwise_gconfidence_logic
