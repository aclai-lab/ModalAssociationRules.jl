```@meta
CurrentModule = ModalAssociationRules
```

Symbolic modal learning is a branch of machine learning which deals with training classical symbolic machine learning models (e.g., list and set of rules, decision trees, random forests, association rules, etc.) but substituting propositional logic with a more expressive logical formalism (yet, computationally more affordable than first order logic), that is, a specific kind of modal logic.

In the context of this package, modal logic helps us highlight complex relations hidden in data, especially in *unstructured data*, consisting of graph-like relational data, time series, spatial databases, text, etc. For more information about the modal symbolic learning, we suggest reading the main page of [`Sole.jl` framework](https://github.com/aclai-lab/Sole.jl) and [`SoleLogics.jl`](https://github.com/aclai-lab/SoleLogics.jl).

The idea is to discretize complex data into relational objects called *Kripke models*, each of which consists of many propositional models called *worlds*, and expliciting the relations between worlds. In this way, it is possible to mine complex [`Itemset`](@ref), including a certain subset of [`Item`](@ref) that are true on a target world, but also *modally enhanced* items that are true on related worlds.

A picture is worth a thousand words. Here you are a slightly more complex example, with respect to the one at the top of [`Getting started`](@ref getting-started) section. We consider this monovariate time series:

![Monovariate time series.](assets/figures/natops-signals/logiset/original-ts.png)

We want to encode a graph-like structure from the data above. We could think of various strategies, one of which is to consider every contiguous subsequence in the time series and model it as a set of intervals.

![Monovariate time series sliced into intervals.](assets/figures/natops-signals/logiset/logiset-signals.png)

At this point, we can see every resulting blue signal as a propositional model, on which items may be evaluated as true or false. In the modal logic jargon, this is exactly a Kripke model.

![Kripke model resulting from the image above.](assets/figures/natops-signals/logiset/logiset-worlds.png)

After fixing a set of suitable relations, we express them with arcs in the structure. Without defining them, we graphically present some possible relations between intervals. The one below is the *begins* relation.

![Begins relation.](assets/figures/natops-signals/logiset/begins.png)

Conversely, this one is the *ends* relation.

![Ends relation.](assets/figures/natops-signals/logiset/ends.png)

When an interval is completely included in another one, then we say that it happens *during* the other one.

![During relation.](assets/figures/natops-signals/logiset/during.png)

Finally, we say that an interval comes just *after* another one if its end coincides with the beginning of the other one.

![After relation.](assets/figures/natops-signals/logiset/after.png)

Every relation $R$ can be declined in an *existential* or a *universal* way. In the former (latter) case, given an item $p$, we say that $<R>p$ is true on $w$ if at least one world (all worlds) $w'$ is such that $wRw'$ and $p$ is true on $w'$. Such relations can be encoded thanks to SoleLogics.jl; in particular, we use `diamond(relation_name)` to indicate an *existential modality* while `box(relation_name)` to indicate universal ones:

```julia
myitem = ScalarCondition(VariableDistance(1, [1,2,3]), <=, 1.0) |> diamond(IA_L)
```

# [Association rule mining with modal logic](@id man-modal-generalization)

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