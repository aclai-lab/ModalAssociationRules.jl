```@meta
CurrentModule = SoleRules
```

```@contents
Pages = ["getting-started.md"]
```

# [Getting started](@id man-core)

In this introductory section you will learn about the main building blocks of SoleRules.

## Core definitions

```@docs
Item

Itemset
toformula

Threshold

ARule
content(rule::ARule)
antecedent(rule::ARule)
consequent(rule::ARule)

ARMSubject
```

## Measures

```@docs
MeaningfulnessMeasure
islocalof(::Function, ::Function)
isglobalof(::Function, ::Function)

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

freqitems(miner::ARuleMiner)
arules(miner::ARuleMiner)

localmemo(miner::ARuleMiner)
localmemo!(miner::ARuleMiner, key::LmeasMemoKey, val::Threshold)
globalmemo(miner::ARuleMiner)
globalmemo!(miner::ARuleMiner, key::GmeasMemoKey, val::Threshold)
info(miner::ARuleMiner)

mine(miner::ARuleMiner)
apply(miner::ARuleMiner, X::AbstractDataset)
```