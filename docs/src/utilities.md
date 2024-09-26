```@meta
CurrentModule = ModalAssociationRules
```

```@contents
Pages = ["getting-started.md"]
```

# [Utilities](@id man-utilities)

The following utilities often involve performing some combinatoric trick between [`Itemset`](@ref)s and [`ARule`](@ref)s, and  might be useful to avoid reinventing the wheel.

## Items and Itemsets

```@docs
combine_items
grow_prune
coalesce_contributors(itemset::Itemset, miner::Miner; localmeasure::Function=lsupport)
```

## Association rules
```@docs
generaterules(itemsets::Vector{Itemset}, miner::Miner)
```