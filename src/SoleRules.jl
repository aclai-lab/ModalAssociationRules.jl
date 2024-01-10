module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

using Reexport

@reexport using SoleModels
@reexport using SoleLogics
@reexport using SoleData

using FunctionWrappers: FunctionWrapper

include("measures.jl")
export lsetmeas, lrulemeas
export gsetmeas, grulemeas

include("core.jl")
export Item, ARule
export apriori, fpgrowth

end
