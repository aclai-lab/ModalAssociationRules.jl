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
* Define your own meaningfulness measures to work with both propositional and modal datasets, by simply calling the macros `localmeasure` and `globalmeasure`.
* Configure an experiment by creating a `Miner` object, and start your mining by choosing an extraction algorithm. We provide the state-of-the-art algorithm `FP-Growth`, optimized to leverage parallelization, but you can easily write your own algorithm by following a simple interface. 

## Package potential at a glance

Consider a time series dataset obtained by recording the hand movements of an operator. Instead of working it through propositional logic, we decide to segment each time series in intervals, and we build relationships between intervals through a certain modal logic.

In particular, we choose [HS Interval Logic](https://dl.acm.org/doi/pdf/10.1145/115234.115351) in order to establish relationships such as "interval X **OVERLAPS** with Y", or "interval Y comes **AFTER** X".

Now that the dataset is ready, we define some **itemset**. An itemset is a conjunction of facts (possibly, one fact, called **item** in the jargon). For example, we define the two following itemsets called $A$ and $B$:

1) $A \coloneqq \text{max}[Δ\text{Y[Hand tip r and thumb r]}] ≤ 0.0$
2) $B \coloneqq [\text{O}]\text{min}[\text{Y[Hand tip r]}] ≥ -0.5$

The first one could be translated as *in the current interval, the right hand is oriented downward*. We could also read it as *the vertical distance between the right-hand middle finger tip and the right-hand thumb tip is negative*.

In the second fact, the relation **OVERLAPS** must be considered universally because of the square brackets. It can be translated into the phrase *in all the intervals overlapping with the current one, the hand is located higher than $-0.5$*.

Now that we have arranged two itemsets, we want to establish if they are interesting based of a frequentist approach. In particular, we want to compute the **support** of each itemset, that is, the relative frequency of how many times the itemset is true within the data. 

By leveraging a mining algorithm, we can join frequent itemsets two by two, iterating until it is not possible to join itemsets anymore.

Let us say that the itemset $\{A,B\}$ turns out to be frequent. At this point, we can generate two rules $A \Rightarrow B$ and $B \Rightarrow A$. Now, we can compute specific meaningfulness measures to determine whether a rule is an association rule or not.

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
