```@meta
CurrentModule = ModalAssociationRules
```

# [Getting started](@id getting-started)

In this introductory section, you will learn about the main building blocks of ModalAssociationRules.jl. 
Also, if a good picture about *association rule mining* (ARM, from now onwards) is given during the documentation, to make the most out of this guide, we suggest reading the following articles:
- [Association rule mining introduction and Apriori algorithm](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf)
- [FPGrowth algorithm](https://www.cs.sfu.ca/~jpei/publications/sigmod00.pdf)
The above introduces two important algorithms, which are also built into this package. Moreover, the latter one is the state-of-the-art in the field of ARM.

Further on in the documentation, the potential of ModalAssociationRules.jl will emerge: this package's raison d'être is to generalize the already existing ARM algorithms to modal logics, which are more expressive than propositional ones (as it allows to reason in terms of relational data) and computationally less expensive than first-order logic. If you are new to [Sole.jl](https://github.com/aclai-lab/Sole.jl) and you want to learn more about modal logic, please have a look at [SoleLogics.jl](https://github.com/aclai-lab/SoleLogics.jl) for a general overview on the topic, or follow this documentation and return to the link if needed.

## Fast introduction

Consider a time series dataset. For example, let us consider the [NATOPS](https://github.com/yalesong/natops) dataset, obtained by recording the movement of different body parts of an operator. We are interested in extracting temporal considerations hidden in the data. To do so, we can highlight specific intervals in each time series (we assume every signal to have the same length). For example, consider the following time series encoding the vertical trajectory of the right-hand of an operator.

```@raw comment
<!-- Figure code:
plot(X[1][1,5], label="Right hand", linecolor=:orange, linewidth=2, size=(500,250)); xlabel!("Time"); ylabel!("Position on y axis") 
-->
```

![I have command movement, specifically the right hand y-axis of the operator](assets/figures/natops-y-hand-signal.png)

At this point, we can highlight different intervals on the signal. For example, via windowing:

```@raw comment
<!-- Figure code:
X_df, y = load_NATOPS();
X = X_df[1:30, :]

windows = [(s:s+9) for s in 1:10:41]
for i in windows
    x = collect(i)
    y = @view X[1,5][x]

    p = plot(x, y; 
        label="Right hand", linecolor=:blue, linewidth=2, 
        size=(500,250), ylims=(-2,1.9), 
        xticks=collect(1:50), xlabel="Time", ylabel="Position on y axis"
    )
    
    savefig(p, string <| i[1])
end

# this is an alternative minimal version, considering every possible window (minimum size is set to 10)
windows = [ 
    [(s:s+9) for s in 1:10:41]..., 
    [(s:s+19) for s in 1:10:31]...,  
    [(s:s+29) for s in 1:10:21]...,  
    [(s:s+39) for s in 1:10:11]...,  
    [(s:s+49) for s in 1:10:1]...,  
]

for i in windows
    x = collect(i)
    y = @view X[1,5][x]

    p = plot(x, y;
        label=false,            # remove legend
        linecolor=:blue,
        linewidth=2,
        size=(10 * length(i), 250),
        ylims=(-2, 1.9),
        xticks=false,           # remove x-axis ticks
        yticks=false,           # remove y-axis ticks
        xlabel="",              # remove x label
        ylabel="",              # remove y label
        framestyle=:none        # remove frame/axes completely
    )

    _first = i |> first
    _last = i |> last
    
    savefig(p,  "$(_first)-to-$(_last).png")
end
!-->
```

![1st window of the signal above.](assets/figures/natops-y-hand-signal-split1.png)
![2nd window of the signal above.](assets/figures/natops-y-hand-signal-split2.png)
![3rd window of the signal above.](assets/figures/natops-y-hand-signal-split3.png)
![4th window of the signal above.](assets/figures/natops-y-hand-signal-split4.png)
![5th window of the signal above.](assets/figures/natops-y-hand-signal-split5.png)

At this point, we can define a set of logical facts ([`Item`](@ref)s in the jargon) to express a particular property of each interval. We are interested in extracting complex associations hidden in data. In this case, we need a logical formalism capable of capturing temporal relations between different intervals.
In particular, [HS Interval Logic](https://dl.acm.org/doi/pdf/10.1145/115234.115351) comes in handy to establish relations such as "the item p holds on the interval X, while the item q holds on the interval Y, and Y comes after X".

What we want to do, in general, is to extend propositional logic with a specific [modal logic](https://en.wikipedia.org/wiki/Modal_logic) formalism (hence, the name of this package) that lets us reason in terms of dimensional relations in data while, at the same time, is not as computational expensive as [first order logic](https://en.wikipedia.org/wiki/First-order_logic).

To give you a more concrete example, consider the following two items, called `p` and `q`. We define them as if we were in the Julia REPL.

```julia
# ScalarCondition is a "generic comparison strategy" defined in SoleData.jl; it says that the maximum in an object encoding a piece of the first variable (in the example above, the right hand vertical movement) must be greater than the threshold 0.5. 

# Atom is a wrapper provided by SoleLogics.jl, to later establish the truth value of a structure.
p = ScalarCondition(VariableMin(1), <, -1.0) |> Atom

# This fact is true on the intervals [1:10] and [11:20] in the example above.
q = ScalarCondition(VariableMax(1), >=, 0.0) |> Atom

# IA_A is the After relation of Allen's interval algebra; "diamond" is one of two modalities (the other one is called "box"); we can ignore it for simplicity here.
ap = diamond(IA_A)(p)

alphabet = [p,q,ap]
```

Note that the example provided, although concrete, is still a toy example as each interval is completely flattened to just one scalar value. In practice, we would like to deal with more expressive kinds of `ScalarCondition`.

Now that we have arranged an alphabet of items, we want to establish which items co-occur together by computing the relative frequency of every possible combination of items (this is the most naive mining strategy but, at the moment, let us forget about performance). Item combinations are called *itemsets*, and the relative frequency of how many times an itemset is true within the data is typically called *support*.

| Itemset | [1:10] | [11:20] | [21:30] | [31:40] | [41:50] | Support
|-------|-------|-------|-------|-------|-------|-------|
| [p] | true | true | true |   | true | 4/5
| [q] |   |   | true | true | true | 3/5
| [ap] | true | true |  | true |  | 3/5
| [p,ap] | true | true |  |  | | 2/5 
| [q,ap] |  |  | true |  | true | 2/5
| [p,q,ap] |  |  |  |  |  | 0/5

Note that the relative frequency decreases as the itemset we consider gets bigger. Also, note how the *after* operator in `ap` shifts the truth values of `p` one space to the left in the table; in this sense, a temporal declination of a fact is simply a special mask of bits obtained by the fact itself. 

Let us say that we want to consider the itemset `[p,ap]` to be frequent, that is, we consider its support to be high enough. The support for an itemset could be very high because it expresses a triviality, so we want to further process the itemset and better analyze it via statistical meaningfulness measures.

In particular, we could consider the two rules `[p] => [ap]` and `[ap] => [p]`. If they turn out to be *meaningful* to us, then we call such rules *association rules*. 

The high-level pipeline we described should be useful to proceed with reading the rest of the documentation.

## Core definitions

One [`Item`](@ref) is just a logical formula, which can be interpreted by a certain model. At the moment, here, we don't care about how models are represented by Sole.jl under the hood, or how the checking algorithm works: what matters is that [`Item`](@ref)s are manipulated by ARM algorithms, which try to find which conjunctions between items are most *statistically significant*.

```@docs
Item
Itemset
```

Notice that one [`Itemset`](@ref) could be a set, but actually it is a vector: this is because, often, ARM algorithms need to establish an order between items in itemsets to work efficiently. To convert an [`Itemset`](@ref) in its [conjunctive normal form](https://en.wikipedia.org/wiki/Conjunctive_normal_form) we simply call [`formula`](@ref).
```@docs
formula
```

In general, an [`Itemset`](@ref) behaves exactly like you would expect a `Vector{Item}` would do. At the end of the day, the only difference is that manipulating an [`Itemset`](@ref), for example through `push!` or `union`, guarantees the wrapped items always keep the same sorting.

Enough about [`Itemset`](@ref)s. Our final goal is to produce *association rules*. 

```@docs
ARule
content(rule::ARule)
antecedent(rule::ARule)
consequent(rule::ARule)
```

To print an [`ARule`](@ref) enriched with more informations (at the moment, this is everything we need to know), we can use the following.
```@docs
arule_analysis(arule::ARule, miner::Miner; io::IO=stdout)
```

Sometimes we could be interested in writing a function that consider a generic entity obtained through an association rule mining algorithm (*frequent itemsets* and, of course, *association rules*). Think about a dictionary mapping some extracted pattern to metadata. We call that generic entity "an ARM subject", and the following union type comes in help.
```@docs
ARMSubject
```

## Measures

To establish when an [`ARMSubject`](@ref) is interesting, we need *meaningfulness measures*. 
```@docs
Threshold
MeaningfulnessMeasure

islocalof(::Function, ::Function)
localof(::Function)

isglobalof(::Function, ::Function)
globalof(::Function)
```

The following are little data structures which will return useful later, when you will read about how a dataset is mined, looking for [`ARMSubject`](@ref)s.
```@docs
LmeasMemoKey
LmeasMemo
GmeasMemoKey
GmeasMemo
```

What follows is a list of the already built-in meaningfulness measures.
In the [`Hands on`](@hands-on) section you will learn how to implement your own measure.
More information are available in the [`Modal generalization`](@man-modal-generalization) section.

```@docs
lsupport
gsupport
lconfidence
gconfidence
```

## Mining structures

Finally, we are ready to start mining. To do so, we can create a custom [`AbstractMiner`](@ref) type.

```@docs
AbstractMiner
```

The main implementation of such an interface is embodied by the [`Miner`](@ref) object.
To mine using a Miner, we just need to specify which dataset we are working with, together with a mining function, a vector of initial [`Item`](@ref)s, and the [`MeaningfulnessMeasure`](@ref)s to establish [`ARMSubject`](@ref) interestingness.

```@docs
Miner
```

Let us see which getters and setters are available for [`Miner`](@ref).

```@docs
data(miner::Miner)
algorithm(miner::Miner)
items(miner::Miner)

measures(miner::Miner)
findmeasure(miner::Miner,meas::Function; recognizer::Function=islocalof)
itemsetmeasures(miner::Miner)
arulemeasures(miner::Miner)

getlocalthreshold(miner::Miner, meas::Function)
getglobalthreshold(miner::Miner, meas::Function)
```

After a [`Miner`](@ref) ends mining (we will see how to mine in a second), frequent [`Itemset`](@ref)s and [`ARule`](@ref) are accessible through the getters below.
```@docs
freqitems(miner::Miner)
arules(miner::Miner)
```

To start the mining algorithm, simply call the following:
```@docs
mine!(miner::Miner)
```

The mining call returns an [`ARule`](@ref) generator. Since the extracted rules could be several, it's up to you to collect all the rules in a step or arule_analysis them lazily, collecting them one at a time. You can also call the mining function ignoring it's return value, and then generate the rules later by calling the following.

```@docs
generaterules!(miner::Miner)
```

During both the mining and the rules generation phases, the values returned by [`MeaningfulnessMeasure`](@ref) applied on a certain [`ARMSubject`](@ref) are saved (memoized) inside the [`Miner`](@ref). Thanks to the methods hereafter, a [`Miner`](@ref) can avoid useless recomputations.

```@docs
localmemo(miner::Miner)
localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)
globalmemo(miner::Miner)
globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold)
```

## Miner customization

A [`Miner`](@ref) also contains two fields to keep additional information, those are [`info`](@ref) and [`miningstate`](@ref).

The [`info`](@ref) field in [`Miner`](@ref) is a dictionary used to store extra information about the miner, such as statistics about mining. Currently, since the package is still being developed, the `info` field only contains a flag indicating whether the `miner` has been used for mining or not.

```@docs
Info
info(miner::Miner)
info!(miner::Miner, key::Symbol, val)
hasinfo(miner::Miner, key::Symbol)
```

When writing your own mining algorithm, or when mining with a particular kind of dataset, you might need to specialize the [`Miner`](@ref), keeping, for example, custom metadata and data structures. To specialize a [`Miner`](@ref), you can fill a [`MiningState`](@ref) structure to fit your needs.

```@docs
MiningState
miningstate(miner::Miner)
miningstate!(miner::Miner, key::Symbol, val)
hasminingstate(miner::Miner, key::Symbol)
initminingstate(::Function, ::AbstractDataset)
```

## Parallelization

To support parallel mining, we provide a [`Bulldozer`](@ref) miner, that is, a lightweight copy of [`Miner`](@ref) which mines a specific section of the data in its own thread.

```@docs
Bulldozer
datalock(bulldozer::Bulldozer)
memolock(bulldozer::Bulldozer)
miningstatelock(bulldozer::Bulldozer)

datatype(::Bulldozer{D}) where {D<:MineableData}
itemtype(::Bulldozer{D,I}) where {D,I<:Item}
instancesrange(bulldozer::Bulldozer)
instanceprojection(bulldozer::Bulldozer, ith_instance::Integer)

data(bulldozer::Bulldozer)

items(bulldozer::Bulldozer)
itemsetmeasures(bulldozer::Bulldozer)


localmemo(bulldozer::Bulldozer)

worldfilter(bulldozer::Bulldozer)

itemset_policies(bulldozer::Bulldozer)

miningstate(bulldozer::Bulldozer)
miningstate!(bulldozer::Bulldozer, key::Symbol, val)

hasminingstate(bulldozer::Bulldozer, key::Symbol)

measures(bulldozer::Bulldozer)

miner_reduce!(local_results::AbstractVector{B}) where {B<:Bulldozer}
load_localmemo!(miner::AbstractMiner, localmemo::LmeasMemo)
```


