```@meta
CurrentModule = ModalAssociationRules
```

# [Hands-on](@id hands-on)

## Step-by-step Experiment

Here, we retrace the experiments implemented [in this article](assets/articles/time2025.pdf).

They are related to body tracking; in particular, we want to describe the movement of [NATOPS dataset](https://timeseriesclassification.com/description.php?Dataset=NATOPS).

```julia
using ModalAssociationRules
using SoleData

# load a sample dataset (NATOPS)
# and transform it into a scalar logiset.
X_df, y = load_NATOPS()
X = scalarlogiset(X_df[1:30, :])

# focus on just the first three variables;
# define a collection of Items, that is, 
# an alphabet of propositional letters (propositions)
# and modal literals. 
p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

lp = box(IA_L)(p)
lq = diamond(IA_L)(q)
lr = box(IA_L)(r)

items = Vector{Item}([p, q, r, lp, lq, lr])

# define which measures to use to establish the interestingness
# of both itemsets (groups of items) and association rules;
# also define a minimum threshold that must be surpassed both 
# locally, inside an instance, and globally across all instances.

# 0.1 is the local minsup, while 0.2 is the global minsup.
itemsetmeasures = [(gsupport, 0.1, 0.2)]
# 0.3 is the local minconfidence, while 0.5 is the global one.
arulemeasures = [(gconfidence, 0.3, 0.5)]

# choose an association rule mining algorithm, like fpgrowth;
# we can finally define a Miner machine.
miner = Miner(X, fpgrowth, items, itemsetmeasures, arulemeasures)

# we execute the miner and retrieve the resulting rules
mine!(miner)
myrules = arules(miner)
```

We can create more complex Miner objects by specifying three kinds of policies, which define the properties that must be satisfied by X's worlds, the Itemsets collected during the mining, and the final ARules.

```julia
miner = Miner(
    X
    fpgrowth,
    items,
    itemsetmeasures,
    arulemeasures,

    # we specify a condition that the worlds of the logiset X must honor
    worldfilter=SoleLogics.FunctionalWorldFilter(
        x -> length(x) <= 10, Interval{Int}
    ),

    # an itemset is considered meaningful if it also honors specific condiitons
    itemsetpolicies=[islimited_length_itemset(; maxlength=5)],

    # similarly, for the association rules extracted
    arule_policies=[
        islimited_length_arule(; antecedent_maxlength=5),
        isanchored_arule(; npropositions=1),
        isheterogeneous_arule(; antecedent_nrepetitions=1, consequent_nrepetitions=0),
    ],
)
```

## Implementing a new meaningfulness measure

At the moment of writing, [`lsupport`](@ref) and [`gsupport`](@ref) must always be leveraged when extracting frequent itemsets, while the global fragment of the other [`MeaningfulnessMeasures`](@ref) is exploited by [`generaterules`](@ref) to generate the final list of [`ARule`](@ref)s.

Although still not used, the local counterpart of meaningfulness measures for association rules could be an idea for further costraining the generation. In general, we suggest to always implement a local and a global part for you meaningfulness measures.

Every local measure must adhere to the following interface:

```julia
(s::ARMSubject, X::MineableData, ith_instance::Int64, miner::AbstractMiner)
```

and it can defined with the macro below.

```julia
@localmeasure mylocalmeasure _mylocalmeasure_logic
```

Every global measure must adhere this interface instead:

```julia
(s::ARMSubject, X::MineableData, threshold::Float64, miner::AbstractMiner)
```

and it can be defined using [`@globalmeasure`](ref).

Remember you can link your implementations using [`@linkeas`](@ref), and retrieve each counterpart (local-to-global and vinceversa) using [`findmeasure`](@ref).

We could play by implementing one of the many meaningfulness measures proposed [in this paper](https://link.springer.com/chapter/10.1007/978-3-540-44918-8_3). For example, we could implement `lift` as follows:

```julia
# local measure, based on local support
_llift_logic = (rule, X, ith_instance, miner) -> begin
    _instance = getinstance(X, ith_instance)

    num = lconfidence(rule, _instance, miner)
    den = lsupport(consequent(rule), _instance, miner)

    return Dict(:measure => num/den)
end

# global measure, based on global support
_glift_logic = (rule, X, threshold, miner) -> begin
    num = gconfidence(rule, X, threshold, miner)
    den = gsupport(consequent(rule), X, threshold, miner)

    return Dict(:measure => num/den)
end

@localmeasure llift _llift_logic
@globalmeasure glift _glift_logic
@linkmeas glift llift
```

## Writing a new mining algorithm

While the logic for enumerating the association rules from a set of frequent itemsets is quite straightforward, you can implement your custom frequent itemset extraction process by simplying accepting an [`AbstractMiner`](@ref) as the only argument (this is what [`apply!`](@ref) driver function expects).

For adapting an already existing kind of [`AbstractMiner`](@ref) to your needings, you can leverage [`initminingstate`](@ref) trait. This is particularly useful when you don't want to define a whole new miner structure, but just want to consider some auxiliary data structures during the mining.