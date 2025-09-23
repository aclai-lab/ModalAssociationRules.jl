```@meta
CurrentModule = ModalAssociationRules
```

Symbolic modal learning is a branch of machine learning which deals with training classical symbolic machine learning models (e.g., list and set of rules, decision trees, random forests, association rules, etc.) but substituting propositional logic with a more expressive logical formalism (yet, computationally more affordable than first order logic), that is, a specific kind of modal logic.

In the context of this package, modal logic helps us highlight complex relations hidden in data, especially in *unstructured data*, consisting of graph-like relational data, time series, spatial databases, text, etc. For more information about the modal symbolic learning, we suggest reading the main page of [`Sole.jl` framework](https://github.com/aclai-lab/Sole.jl) and [`SoleLogics.jl`](https://github.com/aclai-lab/SoleLogics.jl).

The idea is to discretize complex data into relational objects called *Kripke models*, each of which consists of many propositional models called *worlds*, and expliciting the relations between worlds. In this way, it is possible to mine complex [`Itemset`](@ref), including a certain subset of [`Item`](@ref) that are true on a target world, but also *modally enhanced* items that are true on related worlds.

A picture is worth a thousand words. Here you are a slightly more complex example, with respect to the one at the top of [`Getting started`](@ref getting-started) section.




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

We already introduced [`lsupport`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref) and [`gconfidence`](@ref) in the [`Getting started`](#man-core) section. Other measures that are already built into the package, are the following; note how they are always organized in both local and global versions.

```@docs
llift
glift
lconviction
gconviction
lleverage
gleverage
```