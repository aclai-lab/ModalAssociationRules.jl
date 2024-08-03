```@meta
CurrentModule = ModalAssociationRules
```

# ModalAssociationRules

## Introduction

Welcome to the documentation for [ModalAssociationRules](https://github.com/aclai-lab/ModalAssociationRules.jl), a Julia package for mining (modal) association rules in ModalAssociationRules.jl. 

## Installation

To install ModalAssociationRules.jl, use the Julia package manager:
```julia
using Pkg
Pkg.add("ModalAssociationRules")
```

## Feature Summary

* Define your own meaningfulness measures to work with modal datasets, by simply calling the macros `lmeas` and `gmeas`.
* Construct and manipulate `Itemset`s and `Association rules` that support custom modal logic, such as [Halpern Shoham Interval Logic](https://dl.acm.org/doi/pdf/10.1145/115234.115351).
* Configure and start your mining by easily creating a `Miner` object, containing the initial items, a list of meaningfulness measures and a reference to the underlying algorithm.
* Mine using state-of-the-art algorithm `FP-Growth`, optimized to leverage parallelization, or simply make your own by following an interface. 

## Package potential at a glance
Consider a time series dataset obtained by recording the hand movements of an operator. Instead of working it through propositional logic, we decide to segment each time serie in intervals, and we build relationships between intervals through a certain modal logic.

In particular, we choose [HS Interval Logic](https://dl.acm.org/doi/pdf/10.1145/115234.115351) in order to establish relationships such as "interval X **OVERLAPS** with Y", or "interval Y comes **AFTER** X".

Now that the dataset is ready we define, let's say manually, some itemset. An itemset, essentially, is a conjunction of facts (possibly, one fact). For example we define the two following itemset:

1) `max[ΔY[Hand tip r and thumb r]] ≤ 0.0`
2) `[O]min[Y[Hand tip r]] ≥ -0.5`

The first one is the fact *in the current interval, the right hand is oriented downward*, or *the vertical distance between right hand middle finger tip and right hand thumb tip is negative*.

In the second fact, the relation **OVERLAPS** must be considered universally because of the square brackets. It can be translated into the phrase *in all the intervals overlapping with the current one, the hand is located higher than $-0.5$*.

Now that we have arranged two facts (itemsets), we want to probe the dataset looking for association rules. To do so, we first need to examine four meaningfulness measures:

1) local support: in an instance, count how many 
2) global support
3) local confidence
4) global confidence

After that, consider four meaningfulness measures: local support, global support, local confidence and global confidence.

We want to extract the association rules hidden in the dataset

An association rule supporting , shaped starting from a temporal dataset talking about hand gestures, segmented into intervals, could be the one below. It means *if in a time interval the vertical distance between right hand middle finger tip and thumb tip is negative, then some specific meaningfulness measures hold while*

```(max[ΔY[Hand tip r and thumb r]] ≤ 0.0) => ([O]min[Y[Hand tip r]] ≥ -0.5)```

## About

The package is developed by the [ACLAI Lab](https://aclai.unife.it/en/) @ University of Ferrara.

*ModalAssociationRules.jl* lives in the context of [*Sole.jl*](https://github.com/aclai-lab/Sole.jl), an open-source framework for *symbolic machine learning*, originally designed for machine learning based on modal logics (see [Eduard I. Stan](https://eduardstan.github.io/)'s PhD thesis *'Foundations of Modal Symbolic Learning'* [here](https://www.repository.unipr.it/bitstream/1889/5219/5/main.pdf)).

## More on Sole
- [SoleBase.jl](https://github.com/aclai-lab/SoleBase.jl)
- [SoleLogics.jl](https://github.com/aclai-lab/SoleLogics.jl)
- [MultiData.jl](https://github.com/aclai-lab/MultiData.jl)
- [SoleModels.jl](https://github.com/aclai-lab/SoleModels.jl)
- [SoleData.jl](https://github.com/aclai-lab/SoleData.jl)
- [SoleFeatures.jl](https://github.com/aclai-lab/SoleFeatures.jl) 
- [SolePostHoc.jl](https://github.com/aclai-lab/SolePostHoc.jl)
