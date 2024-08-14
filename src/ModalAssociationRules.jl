module ModalAssociationRules
# Currently, the only topic covered by ModalAssociationRules is Association Rules.

import Base.count, Base.push!
import Base.size, Base.getindex, Base.IndexStyle, Base.setindex!, Base.iterate
import Base.length, Base.similar, Base.show, Base.union, Base.hash
import Base.firstindex, Base.lastindex

using Combinatorics
using DataStructures
using Distributed
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
@reexport using SoleModels

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance
using SoleLogics: nworlds, frame, allworlds, nworlds

using SoleData: SupportedLogiset
using SoleData: VariableMin, VariableMax

using StatsBase

include("core.jl")

export Item
export Itemset, toformula, slice

export Threshold
export WorldMask, EnhancedItemset, ConditionalPatternBase

export ARule
export antecedent, consequent

export MeaningfulnessMeasure
export islocalof, isglobalof
export localof, globalof

export ARMSubject
export LmeasMemoKey, LmeasMemo
export GmeasMemoKey, GmeasMemo
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
export mine!, apply!, generaterules!
export analyze

export frame, allworlds, nworlds

include("meaningfulness-measures.jl")

export @lmeas, @gmeas
export lsupport, gsupport
export lconfidence, gconfidence

include("utils/arulemining-utils.jl")

export combine_items, prune, prune!
export grow_prune, coalesce_contributors
export anchor_rulecheck, non_selfabsorbed_rulecheck
export generaterules # see generaterules!
export getlocalthreshold_integer, getglobalthreshold_integer

include("algorithms/apriori.jl")

export apriori

include("algorithms/fpgrowth.jl")

export FPTree
export content, parent, children, count
export content!, parent!, children!
export count!, addcount!
export isroot, islist
export itemset_from_fplist, retrieveleaf
export grow!

export HeaderTable, items
export link, link!, follow  # dispatches for both FPTree and HeaderTable
export checksanity!
export patternbase
export fpgrowth

include("utils/natops-loader.jl")

export load_NATOPS

include("utils/literals-selector.jl")   # TODO: move this in SoleData

export equicut, quantilecut
export makeconditions

end
