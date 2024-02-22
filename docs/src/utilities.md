```@meta
CurrentModule = SoleRules
```

```@contents
Pages = ["getting-started.md"]
```

# [Utilities](@id man-utilities)

The following utilities often involve performing some combinatoric trick between [`Itemset`](@ref)s and [`ARule`](@ref)s, and  might be useful to avoid reinventing the wheel.

## Items and Itemsets

```@docs
combine
grow_prune
coalesce_contributors(itemset::Itemset, miner::ARuleMiner; lmeas::Function=lsupport)
```

## Association rules
```@docs
arules_generator(itemsets::Vector{Itemset}, miner::ARuleMiner)
```