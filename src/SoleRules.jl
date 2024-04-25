module SoleRules
# Currently, the only topic covered by SoleRules is Association Rules.

import Base.count, Base.push!
import Base.size, Base.getindex, Base.IndexStyle, Base.setindex!, Base.iterate
import Base.length, Base.similar, Base.show, Base.union, Base.hash
import Base.firstindex, Base.lastindex

using Combinatorics
using DataStructures
using IterTools
using Lazy: @forward
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

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance
using SoleLogics: nworlds, frame, allworlds, nworlds

using SoleData: SupportedLogiset

using StatsBase

include("core.jl")

export Item
export Itemset, toformula, slice

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
export measures, findmeasure
export getlocalthreshold, getglobalthreshold
export localmemo, localmemo!
export globalmemo, globalmemo!

export powerups, powerups!, haspowerup, initpowerups
export info, info!, hasinfo
export contributors, contributors!
export mine!, apply!, generaterules!

export frame, allworlds, nworlds

include("meaningfulness-measures.jl")

export lsupport, gsupport
export lconfidence, gconfidence

include("arulemining-utils.jl")

export combine, prune, prune!
export grow_prune, coalesce_contributors
export arules_generator # wrapped by generaterules!
export getlocalthreshold_integer, getglobalthreshold_integer

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
export fpgrowth

include("utils.jl")         # IDEA: move this in SoleData

export equicut, quantilecut
export make_conditions

include("ideas.jl")

end
