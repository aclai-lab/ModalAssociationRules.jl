```@meta
CurrentModule = ModalAssociationRules
```

# [Advanced usage](@id advanced-usage)

The following utilities often involve performing some combinatoric trick between [`Itemset`](@ref)s and [`ARule`](@ref)s, and might be useful to avoid reinventing the wheel.

## Items and Itemsets

```@docs
combine_items
grow_prune
```

## Association rules
```@docs
generaterules(itemsets::Vector{Itemset}, miner::Miner)
```

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