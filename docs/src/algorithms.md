```@meta
CurrentModule = ModalAssociationRules
```

# [Available algorithms](@id algorithms)

## Candidate generation based

```@docs
apriori
```

## TreeProjection based

### FPGrowth

```@docs
fpgrowth
```

FPGrowth algorithm relies on two data structures, [`FPTree`](@ref) and [`HeaderTable`](@ref).
To know more about them and their, please refer to the documentation here [data-structures](@ref).

FPGrowth algorithm relies on the following two routines.

```@docs
patternbase(item::Item, htable::HeaderTable, miner::Miner)
projection(pbase::ConditionalPatternBase, miner::Miner)
```

Also, FPGrowth requires the [`Miner`](@ref) to remember the worlds associated with the extracted frequent itemsets.
To add this functionality, we can define a new dispatch of [`initminingstate`](@ref): it is automatically considered to enrich the miner, while building it together with [`fpgrowth`](@ref) as mining algorithm.

```@docs
initminingstate(::typeof(fpgrowth), ::AbstractDataset)
```

## Anchored semantics

```@docs
anchored_semantics
anchored_apriori
anchored_fpgrowth
```