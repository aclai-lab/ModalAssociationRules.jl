module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

using Reexport

@reexport using SoleModels
@reexport using SoleLogics
@reexport using SoleData

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance
using SoleModels: SupportedLogiset
using FunctionWrappers: FunctionWrapper

include("core.jl")

export Item, Itemset, ARule

export Configuration
export ItemLmeas, ItemGmeas, RuleLmeas, RuleGmeas
export lsupport

export apriori, fpgrowth

end
