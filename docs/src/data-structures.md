```@meta
CurrentModule = ModalAssociationRules
```

```@contents
Pages = ["data-structures.md"]
```
# [Built in data structures](@id data-structures)

## FPTree

```@docs
FPTree

content(fptree::FPTree)
content!(fptree::FPTree, item::Union{Nothing,Item})

parent(fptree::FPTree)
parent!(fptree::FPTree, parentfpt::Union{Nothing,FPTree})

children(fptree::FPTree)
children!(fptree::FPTree, child::FPTree)

Base.count(fptree::FPTree)
count!(fptree::FPTree, newcount::Integer)
addcount!(fptree::FPTree, deltacount::Integer)

Base.push!(fptree::FPTree, itemset::Itemset, ninstance::Integer, miner::Miner; htable::Union{Nothing,HeaderTable}=nothing)

link(fptree::FPTree)
link!(from::FPTree, to::FPTree)
follow(fptree::FPTree)

islist(fptree::FPTree)
retrieveall(fptree::FPTree)
prune!(fptree::FPTree, miner::Miner)
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