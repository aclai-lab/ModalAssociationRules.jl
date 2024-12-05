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
using SoleLogics: filterworlds, WorldFilter

using SoleData: SupportedLogiset
using SoleData: VariableMin, VariableMax

using StatsBase

include("core.jl")

export Item, formula
export Itemset

export ARule
export content, antecedent, consequent

export ARMSubject

export Threshold
export MeaningfulnessMeasure
export islocalof, isglobalof
export localof, globalof

export WorldMask

export LmeasMemoKey, LmeasMemo
export GmeasMemoKey, GmeasMemo

export MiningState
export Info
export MineableData

export MineableData

include("types/miner.jl")

export AbstractMiner
export data, algorithm
export items, freqitems, arules
export itemsetmeasures, rulemeasures

export measures, findmeasure
export getlocalthreshold, getglobalthreshold
export localmemo, localmemo!
export globalmemo, globalmemo!

export worldfilter
export itemset_mining_policies, arule_mining_policies

export miningstate, miningstate!, hasminingstate, initminingstate
export info, info!, hasinfo
export mine!, apply!
export generaterules, generaterules!

include("utils/miner.jl")

export Miner
export itemtype, datatype
export frame, allworlds, nworlds
export analyze

include("utils/bulldozer.jl")

export Bulldozer
export datalock, memolock, miningstatelock
export bulldozer_reduce
export frame

include("meaningfulness-measures.jl")

export @localmeasure, @globalmeasure, @linkmeas
export lsupport, gsupport
export lconfidence, gconfidence

include("mining-policies.jl")

export islimited_length_itemset
export islimited_length_arule, isanchored_arule, isheterogeneous_arule

include("algorithms/apriori.jl")

export combine_items, grow_prune
export apriori

include("data-structures.jl")

export EnhancedItemset, count
export ConditionalPatternBase

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

include("analysis.jl")

export plot_rules_analysis

include("alphabet-selection.jl")
export __arm_select_alphabet
export time_series_distribution_analysis # TODO - this might be moved to SoleData

include("natops-loader.jl")

export load_NATOPS

end
