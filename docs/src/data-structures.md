```@meta
CurrentModule = SoleRules
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
count!(fptree::FPTree, newcount::Int64)
addcount!(fptree::FPTree, deltacount::Int64)

contributors(fptree::FPTree)
contributors!(fptree::FPTree, contribution::WorldMask)
addcontributors!(fptree::FPTree, contribution::WorldMask)

link(fptree::FPTree)
link!(from::FPTree, to::FPTree)
follow(fptree::FPTree)

islist(fptree::FPTree)
retrieveall(fptree::FPTree)

Base.push!(fptree::FPTree, itemset::Itemset, ninstance::Int64, miner::ARuleMiner; htable::Union{Nothing,HeaderTable}=nothing)

```

## HeaderTable

```@docs
HeaderTable

items(htable::HeaderTable)
link(htable::HeaderTable)

follow(htable::HeaderTable, item::Item)
link!(htable::HeaderTable, fptree::FPTree)

checksanity!(htable::HeaderTable, miner::ARuleMiner)
Base.reverse(htable::HeaderTable)
```