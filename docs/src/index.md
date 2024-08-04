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

* Construct and manipulate conjunctions of facts (*items*) called *itemsets*, eventually supporting specific modal logic to suit your data (e.g., [Halpern Shoham Interval Logic](https://dl.acm.org/doi/pdf/10.1145/115234.115351) to work with time series).
* Extract the *association rules* hidden in a dataset, starting from a set of items and a list of *meaningfulness measures*.
* Define your own meaningfulness measures to work with both propositional and modal datasets, by simply calling the macros `lmeas` and `gmeas`.
* Configure an experiment by creating as `Miner` object, and start your mining by choosing an extraction algorithm. We provide the state-of-the-art algorithm `FP-Growth`, optimized to leverage parallelization, but you can easily write your own algorithm by following a simple interface. 

## Package potential at a glance

This is a small summary of the [`Hands on section`](@id hands-on).

Consider a time series dataset obtained by recording the hand movements of an operator. Instead of working it through propositional logic, we decide to segment each time serie in intervals, and we build relationships between intervals through a certain modal logic.

In particular, we choose [HS Interval Logic](https://dl.acm.org/doi/pdf/10.1145/115234.115351) in order to establish relationships such as "interval X **OVERLAPS** with Y", or "interval Y comes **AFTER** X".

Now that the dataset is ready we define, let's say manually, some itemset. An itemset, essentially, is a conjunction of facts (possibly, one fact). For example we define the two following itemset called $A$ and $B$:

1) $A \coloneqq \text{max}[Δ\text{Y[Hand tip r and thumb r]}] ≤ 0.0$
2) $B \coloneqq [\text{O}]\text{min}[\text{Y[Hand tip r]}] ≥ -0.5$

The first one is the fact *in the current interval, the right hand is oriented downward*. We could also read *the vertical distance between right hand middle finger tip and right hand thumb tip is negative*.

In the second fact, the relation **OVERLAPS** must be considered universally because of the square brackets. It can be translated into the phrase *in all the intervals overlapping with the current one, the hand is located higher than $-0.5$*.

Now that we have arranged two itemsets, we want to probe the dataset looking for association rules. To do so, we compute some meaningfulness measures:

1) local support: "inside" an instance, count how many times an itemset is true across all the worlds
2) global support: across all instances, count how many times the local support "is significant enough" on an instance

After that we choose a threshold for each kind of support, in order to delineate what does it mean for an itemset to be *frequent* (that is, we are interested in it), or no. 

Let's say that both our original itemsets turns out to be frequent. At this point, we can generate two rules $A \Rightarrow B$ and $B \Rightarrow A$. Now, we can compute specific meaningfulness measures, such as confidence, to establish whether a rule is an *association rule*, or no.

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
