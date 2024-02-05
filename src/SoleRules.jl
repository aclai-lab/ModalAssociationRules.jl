module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

using Combinatorics
using FunctionWrappers: FunctionWrapper
using IterTools
using Parameters
using Random

using Reexport
@reexport using SoleModels
@reexport using SoleLogics
@reexport using SoleData

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance, nworlds
using SoleModels: SupportedLogiset

using StatsBase

include("core.jl")

export Item
export LmeasMemo, LmeasMemoKey, GmeasMemo, GmeasMemoKey

export Itemset, ItemsetContent
export setlocalmemo, getlocalmemo, getglobalmemo, setglobalmemo
export value, merge, grow

export ARule
export antecedent, consequent

export ItemLmeas, ItemGmeas, RuleLmeas, RuleGmeas
export lsupport, gsupport
export lconfidence, gconfidence

export ARuleMiner,
    dataset, algorithm, alphabet,
    item_meas, rule_meas,
    freqitems, nonfreqitems, arules
    mine, apply

include("apriori.jl")

export apriori

include("utils.jl")

export equicut, quantilecut
export make_conditions

end
