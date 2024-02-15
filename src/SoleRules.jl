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
export WorldsMask, EnhancedItemset, ConditionalPatternBase

export ARule
export antecedent, consequent

export ConstrainedMeasure, islocalof, isglobalof
export ARMSubject
export LmeasMemoKey, LmeasMemo, Contributors
export GmeasMemoKey, GmeasMemo
export Contributors

export ARuleMiner
export dataset, algorithm
export item_meas, rule_meas
export freqitems, nonfreqitems, arules
export getlocalthreshold, setlocalthreshold
export getglobalthreshold, setglobalthreshold
export localmemo, localmemo!
export globalmemo, globalmemo!

export info
export contributors, contributors!, mergecontributors

export mine, apply

include("meaningfulness-measures.jl")

export lsupport, gsupport
export lconfidence, gconfidence

include("arulemining-utils.jl")

export combine, prune
export contributors
export arules_generator

include("algorithms/apriori.jl")

export apriori

include("algorithms/fpgrowth.jl")

export FPTree
export content, parent, children, count
export content!, parent!, children!, count!, addcount!, addcontributors!
export islist, retrieveall

export HeaderTable, items
export link, link!, follow  # dispatches for both FPTree and HeaderTable
export patternbase
export fpgrowth, @modalminer

include("utils.jl")         # IDEA: move this in SoleData

export equicut, quantilecut
export make_conditions

end
