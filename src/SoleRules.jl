module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

using FunctionWrappers: FunctionWrapper
using Parameters

using Reexport
@reexport using SoleModels
@reexport using SoleLogics
@reexport using SoleData

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance, nworlds
using SoleModels: SupportedLogiset

include("core.jl")

export Item, Itemset, ARule

export ItemLmeas, ItemGmeas, RuleLmeas, RuleGmeas
export lsupport, gsupport
export lconfidence, gconfidence

export ARuleMiner,
    dataset, algorithm, alphabet,
    item_meas, rule_meas,
    freqitems, nonfreqitems, arules

export apriori, fpgrowth

end
