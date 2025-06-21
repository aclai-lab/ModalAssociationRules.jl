# ModalAssociationRules.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/dev)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl)
[![codecov](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl/branch/main/graph/badge.svg?token=LT9IYIYNFI)](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl)

Association rules in Julia!

## Usage

Creation of a `Miner` object.

```julia
using ModalAssociationRules
using SoleData

# load a sample dataset (NATOPS)
# and transform it in a scalar logiset.
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
# also define a minimum threshold that must be overpassed both 
# locally, inside an instance, and globally across all instances.

# 0.1 is the local minsup, while 0.2 is the global minsup.
itemsetmeasures = [(gsupport, 0.1, 0.2)]
# 0.3 is the local minconfidence, while 0.5 is the global one.
arulemeasures = [(gconfidence, 0.3, 0.5)]

# choose an association rule mining algorithm, like fpgrowth;
# we can finally define a Miner machine.
miner = Miner(X, fpgrowth, items, itemsetmeasures, arulemeasures)
```

Miner execution and results retrieval.

```julia
mine!(miner)
mined_itemsets = freqitems(miner)
mined_arules = arules(miner)
```

We can create more complex `Miner` objects by specifying three kind of policies, which defines the properties that must be satisfied by `X`'s worlds, the `Itemset`s collected during the mining, and the final `ARule`s.

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
    itemset_policies=[islimited_length_itemset(; maxlength=5)],

    # similarly, for the association rules extracted
    arule_policies=[
        islimited_length_arule(; antecedent_maxlength=5),
        isanchored_arule(; npropositions=1),
        isheterogeneous_arule(; antecedent_nrepetitions=1, consequent_nrepetitions=0),
    ],
)
```

## Compilation (development dependencies)

This package heavily depends on the [Sole](https://github.com/aclai-lab/Sole.jl) ecosystem.

To compile this package while referencing the `dev` branches of the other necessary Sole package, clone and instantiate them in a common folder, following the steps below.

    git clone https://github.com/aclai-lab/SoleBase.jl.git
    git clone https://github.com/aclai-lab/MultiData.jl.git
    git clone https://github.com/aclai-lab/SoleLogics.jl.git
    git clone https://github.com/aclai-lab/SoleData.jl.git
    git clone https://github.com/aclai-lab/SoleModels.jl.git
    git clone https://github.com/aclai-lab/ModalAssociationRules.jl.git

For each folder, checkout on `dev` branch and open the Julia REPL to install the dpendencies associated:

    SoleBase              -> ]instantiate
    MultiData             -> ]dev SoleBase
    SoleLogics            -> ]dev SoleBase
    SoleData              -> ]dev SoleBase SoleLogics MultiData
    SoleModels            -> ]dev SoleBase MultiData SoleLogics SoleData
    ModalAssociationRules -> ]dev SoleBase MultiData SoleLogics SoleData SoleModels

When not specified (every time but in SoleBase), also execute ```]instantiate```.

