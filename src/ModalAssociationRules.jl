module ModalAssociationRules

import Base.count, Base.push!
import Base.size, Base.getindex, Base.IndexStyle, Base.setindex!, Base.iterate
import Base.length, Base.similar, Base.show, Base.union, Base.hash
import Base.firstindex, Base.lastindex

using Clustering
using Combinatorics
using DataStructures
using Distributed
using IterTools
using MatrixProfile
using Parameters
using Random
using ResumableFunctions
using StaticArrays

using Reexport
@reexport using SoleBase
@reexport using SoleLogics
@reexport using MultiData
@reexport using SoleData

using SoleLogics: AbstractInterpretation, getinstance, LogicalInstance
using SoleLogics: nworlds, frame, allworlds, nworlds
using SoleLogics: filterworlds, WorldFilter

using SoleData: SupportedLogiset
using SoleData: VariableMin, VariableMax, VariableDistance

using StatsBase

include("core.jl")

export AbstractMiner

export AbstractItem
export Item, formula, feature
export ItemCollection

export AbstractItemset

export SmallItemset
export mask, applymask, itemsetpopulation

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

include("types/miner.jl")

export data, algorithm
export items, freqitems, arules
export itemsetmeasures, arulemeasures

export measures, findmeasure
export getlocalthreshold, getglobalthreshold
export localmemo, localmemo!
export globalmemo, globalmemo!

export worldfilter
export itemsetpolicies, arulepolicies

export miningstate, miningstate!, hasminingstate, initminingstate
export info, info!, hasinfo
export mine!, apply!
export generaterules, generaterules!

export partial_deepcopy, reduceminer!

include("mining-policies.jl")

export islimited_length_itemset, isanchoreditemset, isdimensionally_coherent_itemset
export islimited_length_arule, isanchoredarule, isheterogeneous_arule
export isanchored_miner

include("utils/miner.jl")

export Miner
export itemtype, nitems, datatype, itemsettype
export arule_analysis, all_arule_analysis

include("utils/bulldozer.jl") # TODO: replace Itemset with the new type

export Bulldozer
export datalock, memolock, miningstatelock

include("meaningfulness-measures.jl")

export @localmeasure, @globalmeasure, @linkmeas
export lsupport, gsupport
export lconfidence, gconfidence
export llift, glift
export lconviction, gconviction
export lleverage, gleverage

include("algorithms/apriori.jl")

export combineitems, growprune
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

include("algorithms/eclat.jl")

export eclat

include("algorithms/anchored-semantics.jl")

export anchored_semantics
export anchored_growprune, anchored_apriori
export anchored_fpgrowth
####
#### # utilities to help an user generate an alphabet graphically;
#### # see future-work folder.
#### # include("alphabet-proposal.jl")
#### # export motifsalphabet
####
include("deprecate.jl")

end
