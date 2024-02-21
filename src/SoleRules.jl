module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

import Base.count, Base.push!, Base.show
using Combinatorics
using DataStructures
using FunctionWrappers: FunctionWrapper
using IterTools
using Parameters
using Random
using ResumableFunctions

using Reexport
@reexport using SoleBase
@reexport using SoleLogics
@reexport using MultiData
@reexport using SoleModels
@reexport using SoleData

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance, nworlds
using SoleData: SupportedLogiset

using StatsBase

include("core.jl")

export Item
export Itemset, toformula

export Threshold
export WorldMask, EnhancedItemset, ConditionalPatternBase

export ARule
export antecedent, consequent

export MeaningfulnessMeasure, islocalof, isglobalof
export ARMSubject
export LmeasMemoKey, LmeasMemo, Contributors
export GmeasMemoKey, GmeasMemo
export Contributors

export ARuleMiner
export dataset, algorithm
export item_meas, rule_meas
export freqitems, arules
export getlocalthreshold, setlocalthreshold
export getglobalthreshold, setglobalthreshold
export localmemo, localmemo!
export globalmemo, globalmemo!
export info, isequipped

export MiningAlgo

export contributors, contributors!

export mine, apply

include("meaningfulness-measures.jl")

export lsupport, gsupport
export lconfidence, gconfidence

include("arulemining-utils.jl")

export combine, prune, prune!
export grow_prune, coalesce_contributors
export arules_generator

include("algorithms/apriori.jl")

export apriori

include("algorithms/fpgrowth.jl")

export FPTree
export content, parent, children, count
export content!, parent!, children!
export count!, addcount!, addcontributors!
export islist, retrieveall

export HeaderTable, items
export link, link!, follow  # dispatches for both FPTree and HeaderTable
export patternbase
export fpgrowth, @equip_contributors

include("utils.jl")         # IDEA: move this in SoleData

export equicut, quantilecut
export make_conditions

include("ideas.jl")
export mirages!

end
