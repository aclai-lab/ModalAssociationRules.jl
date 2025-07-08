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

The following measures are built into the package. Note how they are always organized in a local and a global version.

```@docs
lsupport
gsupport
lconfidence
gconfidence
llift
glift
lconviction
gconviction
lleverage
gleverage
```