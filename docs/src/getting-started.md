```@meta
CurrentModule = SoleRules
```

```@contents
Pages = ["getting-started.md"]
```

# [Getting started](@id man-core)

In this introductory section you will learn about the main building blocks of SoleRules.jl. 
Also if a good picture about *association rule mining* (ARM, from now onwards) is given during the documentation, to make the most out of this documentation we suggest to read the following articles:
- [association rule mining introduction and Apriori algorithm](https://ceur-ws.org/Vol-3284/492.pdf)
- [FPGrowth algorithm](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf)
Those up above introduce two important algorithms, which are also built-in in this package. Moreover, the latter one is the state-of-the-art in the field of ARM.

Further on in the documentation, the potential of SoleRules.jl will emerge: this package's raison d'être is to generalize the already existing ARM algorithms to modal logics, which are more expressive than propositional one and computationally less expensive than first order logic. If you are new to Sole.jl and you want to learn more about modal logic, please have a look at [SoleLogics.jl](https://github.com/aclai-lab/SoleLogics.jl) for a general overview on the topic, or follow this documentation and return to this link if needed.

## Core definitions

One [`Item`](@ref) is just a logical formula, which can be interpreted by a certain model. At the moment, here, we don't care about how models are represented by Sole.jl under the hood, or how interpretation algorithm works: what matters is that [`Item`](@ref)s are manipulated by ARM algorithms, which try to find which conjunctions between items are most *statistically significant*.

```@docs
Item
Itemset
```

Notice that one [`Itemset`](@ref) could be a set, but actually it is a vector: this is because, often, ARM algorithms need to establish an order between items in itemsets to work efficiently. To convert an [`Itemset`](@ref) in its [conjunctive normla form](https://en.wikipedia.org/wiki/Conjunctive_normal_form) we simply call [`toformula`](@ref).
```@docs
toformula
```

Enough about [`Itemset`](@ref)s. Our final goal is to produce *association rules*. 

```@docs
ARule
content(rule::ARule)
antecedent(rule::ARule)
consequent(rule::ARule)
```

When you want to consider a generic entity obtained through an association rule mining algorithm (*frequent itemsets* and, of course, *association rules*) just use the following type.
```@docs
ARMSubject
```

## Measures

We cannot establish when a [`ARMSubject`](@ref) is interesting just by looking at its shape: we need *meaningfulness measures*. 
```@docs
Threshold
MeaningfulnessMeasure
islocalof(::Function, ::Function)
isglobalof(::Function, ::Function)
```

The following are little data structures which will return useful later, when you will read about how a dataset is "mined", looking for [`ARMSubject`](@ref)s.
```@docs
LmeasMemoKey
LmeasMemo
GmeasMemoKey
GmeasMemo
```

What follows is a list of the already built-in meaningfulness measures.
In the [`hands-on`](@ref) section you will learn how to implement your own measure.

```@docs
lsupport(itemset::Itemset, logi_instance::LogicalInstance; miner::Union{Nothing,Miner}=nothing)
gsupport(itemset::Itemset, X::SupportedLogiset, threshold::Threshold; miner::Union{Nothing,Miner} = nothing)
lconfidence(rule::ARule, logi_instance::LogicalInstance; miner::Union{Nothing,Miner} = nothing)
gconfidence(rule::ARule, X::SupportedLogiset, threshold::Threshold; miner::Union{Nothing,Miner} = nothing)
```

## Mining structures

Finally, we are ready to start mining. To do so, we need to create a [`Miner`](@ref) object.
We just need to specify which dataset we are working with, together with a mining function, a vector of initial [`Item`](@ref)s, and the [`MeaningfulnessMeasure](@ref)s to establish [`ARMSubject`](@ref) interestingness.

```@docs
Miner

dataset(miner::Miner)
algorithm(miner::Miner)
items(miner::Miner)

itemsetmeasures(miner::Miner)
rulemeasures(miner::Miner)
getlocalthreshold(miner::Miner, meas::Function)
setlocalthreshold(miner::Miner, meas::Function, threshold::Threshold)
getglobalthreshold(miner::Miner, meas::Function)
setglobalthreshold(miner::Miner, meas::Function, threshold::Threshold)
```

After a [`Miner`](@ref) ends mining, frequent [`Itemset`](@ref)s and [`ARule`](@ref) are accessibles through the getters below.
```@docs
freqitems(miner::Miner)
arules(miner::Miner)
```

```@docs
localmemo(miner::Miner)
localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)
globalmemo(miner::Miner)
globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold)
```

The [`info`](@ref) field in [`Miner`](@ref) is a dictionary used to store extra informations about the miner, such as statistics about mining. Currently, since the package is still being developed, the `info` field only contains a flag indicating whether the `miner` has been used for mining or no.
```@docs
info(miner::Miner)
info!(miner::Miner, key::Symbol, val)
hasinfo(miner::Miner, key::Symbol)
```

When writing your own mining algorithm, or when mining with a particular kind of dataset, you might need to specialize the [`Miner`](@ref), keeping, for example, custom meta data and data structures. To specialize a [`Miner`](@ref), you can fill a [`Powerup`](@ref) structure to fit your needs.

```@docs
Powerup
powerups(miner::Miner)
powerups!(miner::Miner, key::Symbol, val)
haspowerup(miner::Miner, key::Symbol)
initpowerups(::Function, ::AbstractDataset)
```

To conclude this section, this is how to start mining.
```@docs
mine!(miner::Miner)
apply!(miner::Miner, X::AbstractDataset)
```