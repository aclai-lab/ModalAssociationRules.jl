```@meta
CurrentModule = SoleRules
```

```@contents
Pages = ["algorithms.md"]
```

# [Available algorithms](@id algorithms)

## Candidate generation based

```@docs
apriori(;fulldump::Bool=true, verbose::Bool=true)
```

## TreeProjection based

### FPGrowth

```@docs
fpgrowth(;fulldump::Bool=true, verbose::Bool=true)
```

FPGrowth algorithm relies on two data structures, [`FPTree`](@ref) and [`HeaderTable`](@ref).
To know more about them and their, please refer to the documentation here [data-structures](@ref).

FPGrowth algorithm relies on the following two routines.

```@docs
patternbase(item::Item, htable::HeaderTable, miner::ARuleMiner)
projection(pbase::ConditionalPatternBase; miner::Union{Nothing,ARuleMiner}=nothing)
```