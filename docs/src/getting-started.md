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
lsupport(itemset::Itemset, logi_instance::LogicalInstance; miner::Union{Nothing,ARuleMiner}=nothing)
gsupport(itemset::Itemset, X::SupportedLogiset, threshold::Threshold; miner::Union{Nothing,ARuleMiner} = nothing)
lconfidence(rule::ARule, logi_instance::LogicalInstance; miner::Union{Nothing,ARuleMiner} = nothing)
gconfidence(rule::ARule, X::SupportedLogiset, threshold::Threshold; miner::Union{Nothing,ARuleMiner} = nothing)
```

## Mining structures

Finally, we are ready to start mining. To do so, we need to create an [`ARuleMiner`](@ref) object.
We just need to specify which dataset we are working with, a [`MiningAlgo`](@ref), a vector of initial [`Item`](@ref), and the [`MeaningfulnessMeasure](@ref)s to establish [`ARMSubject`](@ref) interestingness.

```@docs
ARuleMiner
MiningAlgo

dataset(miner::ARuleMiner)
algorithm(miner::ARuleMiner)
items(miner::ARuleMiner)

item_meas(miner::ARuleMiner)
rule_meas(miner::ARuleMiner)
getlocalthreshold(miner::ARuleMiner, meas::Function)
setlocalthreshold(miner::ARuleMiner, meas::Function, threshold::Threshold)
getglobalthreshold(miner::ARuleMiner, meas::Function)
setglobalthreshold(miner::ARuleMiner, meas::Function, threshold::Threshold)
```

After an [`ARuleMiner`](@ref) ends mining, frequent [`Itemset`](@ref)s and [`ARule`](@ref) are accessibles through the getters below.
```@docs
freqitems(miner::ARuleMiner)
arules(miner::ARuleMiner)
```

```@docs
localmemo(miner::ARuleMiner)
localmemo!(miner::ARuleMiner, key::LmeasMemoKey, val::Threshold)
globalmemo(miner::ARuleMiner)
globalmemo!(miner::ARuleMiner, key::GmeasMemoKey, val::Threshold)
```

To customize and specialize an [`ARuleMiner`](@ref), [`info`](@ref) comes in our help.
We will see this aspect later in the documentation.
```@docs
info(miner::ARuleMiner)
```

To conclude this section, this is how to start mining.
```@docs
mine(miner::ARuleMiner)
apply(miner::ARuleMiner, X::AbstractDataset)
```