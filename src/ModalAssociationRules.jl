module ModalAssociationRules

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

export AbstractMiner, Miner
export data, algorithm
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

export reincarnate

export frame, allworlds, nworlds

include("meaningfulness-measures.jl")

export @lmeas, @gmeas
export lsupport, gsupport
export lconfidence, gconfidence

include("utils/mining-utilities.jl")
export Bulldozer
export instance, instancenumber, frame
export datalock, memolock, poweruplock
export bulldozer_reduce, bulldozer_reduce2

export combine_items, prune, prune!
export grow_prune, coalesce_contributors
export anchor_rulecheck, non_selfabsorbed_rulecheck
export generaterules
export getlocalthreshold_integer, getglobalthreshold_integer

include("algorithms/apriori.jl")

export apriori

include("data-structures.jl")

export FPTree
export content, parent, children, count
export content!, parent!, children!
export count!, addcount!
export isroot, islist
export itemset_from_fplist, retrieveleaf
export grow!

export HeaderTable, items
export link, link!, follow
export checksanity!

include("algorithms/fpgrowth.jl")

export patternbase, bounce!, projection
export fpgrowth

include("utils/natops-loader.jl")

export load_NATOPS

include("utils/literals-selector.jl")   # TODO: move this in SoleData

export equicut, quantilecut
export makeconditions

end
