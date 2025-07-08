```@meta
CurrentModule = ModalAssociationRules
```

# [Built in data structures](@id data-structures)

## FPTree

```@docs
FPTree

content(fptree::FPTree)
content!(fptree::FPTree, item::Item)

parent(fptree::FPTree)
parent!(fptree::FPTree, parentfpt::Union{Nothing,FPTree})

children(fptree::FPTree)
children!(fptree::FPTree, child::FPTree)

retrieveleaf

Base.count(fptree::FPTree)
count!(fptree::FPTree, newcount::Integer)
addcount!(fptree::FPTree, deltacount::Integer)

grow!(fptree::FPTree, itemset::Itemset, ith_instance::Integer, miner::AbstractMiner)

link(fptree::FPTree)
link!(from::FPTree, to::FPTree)
follow(fptree::FPTree)

islist(fptree::FPTree)
```

## HeaderTable

```@docs
HeaderTable

items(htable::HeaderTable)
link(htable::HeaderTable)

follow(htable::HeaderTable, item::Item)
link!(htable::HeaderTable, fptree::FPTree)

checksanity!(htable::HeaderTable, miner::Miner)
Base.reverse(htable::HeaderTable)
```