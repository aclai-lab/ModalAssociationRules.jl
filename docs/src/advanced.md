```@meta
CurrentModule = ModalAssociationRules
```

# [Advanced usage](@id advanced-usage)

## Mining Policies

It is possible to limit the action of the mining, to force an [`AbstractMiner`](@ref) to only consider a subset of the available data.

```@docs
worldfilter
```

We can also constrain the generation of new itemsets and rules, by defining a vector of policies.
For what regards itemsets, the following dispatches are available:

```@docs
itemset_policies
islimited_length_itemset
isanchored_itemset
isdimensionally_coherent_itemset
```

The following are referred to association rules:

```@docs
arule_policies
islimited_length_arule
isanchored_arule
isheterogeneous_arule
```

To apply the policies, simply call the following.

```@docs
Base.filter!(targets::Vector{Union{ARule,Itemset}}, policies_pool::Vector{Function})
```

## Anchored semantics

To ensure the mining process is *fair* when dealing with modal operators, we must ensure that the miner is compliant with *anchored semantics constraints*.

```@docs
isanchored_miner
anchored_apriori
anchored_fpgrowth
anchored_eclat
```

Each algorithm above is simply a small wrapper around [`anchored_semantics`](@ref):

```@docs
anchored_semantics
```

## Utilities

The following utilities often involve performing some combinatoric trick between [`Itemset`](@ref)s and [`ARule`](@ref)s, and might be useful to avoid reinventing the wheel.

```@docs
combine_items
grow_prune
anchored_grow_prune
```
