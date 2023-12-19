module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

using Reexport

using SoleModels
using SoleLogics
using SoleData

using FunctionWrappers: FunctionWrapper

include("measures.jl")
export lsetmeas, lrulemeas
export gsetmeas, grulemeas

include("core.jl")

export apriori, fpgrowth

end
