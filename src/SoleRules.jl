module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

import Base.count, Base.push!, Base.show
using Combinatorics
using DataStructures
using IterTools
using Parameters
using Random
using ResumableFunctions

using Reexport
@reexport using SoleBase
@reexport using SoleLogics
@reexport using MultiData
@reexport using SoleData
using SoleModels
# export SoleModels.evaluate

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
export Info, Powerup

export Miner
export dataset, algorithm
export itemsetmeasures, additemmeas
export rulemeasures, addrulemeas
export freqitems, arules
export measures, getmeasure, measurebylocal, measurebyglobal
export getlocalthreshold, getglobalthreshold
export localmemo, localmemo!
export globalmemo, globalmemo!
export powerups, powerups!, haspowerup, initpowerups
export info, info!, hasinfo

export contributors, contributors!

export mine, apply, generaterules

include("meaningfulness-measures.jl")

export lsupport, gsupport
export lconfidence, gconfidence

include("arulemining-utils.jl")

export combine, prune, prune!
export grow_prune, coalesce_contributors
export arules_generator # wrapped by generaterules

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
export checksanity!
export patternbase
export fpgrowth, @equip_contributors

include("utils.jl")         # IDEA: move this in SoleData

export equicut, quantilecut
export make_conditions

include("ideas.jl")
export mirages!

end
