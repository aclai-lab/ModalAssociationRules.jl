module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

using Combinatorics
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

export ARule
export antecedent, consequent

export Threshold
export ConstrainedMeasure, islocalof, isglobalof
export ARMSubject
export LmeasMemoKey, LmeasMemo
export GmeasMemoKey, GmeasMemo
export WorldsMask, Contributors

export ARuleMiner
export dataset, algorithm
export item_meas, rule_meas
export freqitems, nonfreqitems, arules
export getlocalthreshold, setlocalthreshold
export getglobalthreshold, setglobalthreshold
export getlocalmemo, setlocalmemo
export getglobalmemo, setglobalmemo
export info

export mine, apply

include("meaningfulness-measures.jl")

export lsupport, gsupport
export lconfidence, gconfidence

include("manipulations.jl")

export combine, prune
export getcontributors
export arules_generator

include("algorithms/apriori.jl")

export apriori

include("algorithms/fpgrowth.jl")

export FPTree
export content, parent, children, count, contributors
export content!, parent!, children!, count!, addcount!, contributors!

export HeaderTable, items
export linkage, linkage!, follow, link! # common between FPTree and HeaderTable

export fpgrowth
export fpoptimize

include("utils.jl")

export equicut, quantilecut
export make_conditions

end
