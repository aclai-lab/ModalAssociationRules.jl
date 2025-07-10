```@meta
CurrentModule = ModalAssociationRules
```

# [Association rule mining with modal logic](@id man-modal-generalization)

## New building blocks

```@docs
WorldMask
EnhancedItemset
ConditionalPatternBase
```

## Modal logic in action
```@docs
initminingstate(::typeof(fpgrowth), ::MineableData)
```

## Meaningfulness measures 

In general, we can define new meaningfulness measures by leveraging the following macros.

```@docs
@localmeasure
@globalmeasure
@linkmeas
```

We already introduced [`lsupport`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref) and [`gconfidence`](@ref) in the [`Getting started`](@man-core) section. Other measures that are already built into the package, are the following; note how they are always organized in both local and global versions.

```@docs
llift
glift
lconviction
gconviction
lleverage
gleverage
```