
"""
    ARMSubject = Union{ARule,Itemset}

Each entity mined through an association rule mining algorithm.

See also [`ARule`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref), [`Itemset`](@ref),
[`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
const ARMSubject = Union{ARule,SmallItemset,Itemset}

"""
    const Threshold = Float64

Threshold value type for [`MeaningfulnessMeasure`](@ref)s.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lconfidence`](@ref),
[`lsupport`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const Threshold = Float64

"""
    const MeaningfulnessMeasure = Tuple{Function, Threshold, Threshold}

To fully understand this description, we suggest reading
[this article](http://ictcs2024.di.unito.it/wp-content/uploads/2024/08/ICTCS_2024_paper_16.pdf).

In the classic propositional case scenario, we can think each instance as a propositional
interpretation, or equivalently, as a Kripke frame containing only one world.
In this setting, a meaningfulness measure indicates how many times a specific property of
an [`Itemset`](@ref) (or an [`ARule`](@ref)) is satisfied.

The most important meaningfulness measure is *support*, defined as "the number of instances
in a dataset that satisfy an itemset" (it is defined similarly for association rules,
where we consider the itemset obtained by combining both rule's antecedent and consequent).
Other meaningfulness measures can be defined in function of support.

In the context of modal logic, where the instances of a dataset are relational objects
called Kripke frames, every meaningfulness measure must capture two aspects: how much an
[`Itemset`](@ref) or an [`ARule`](@ref) is meaningful *within an instance*, and how much the
same object is meaningful *across all the instances*, that is, how many times it resulted
meaningful within an instance. Note that those two aspects coincide in the propositional
scenario.

When a meaningfulness measure is applied locally within an instance, it is said to be
"local". Otherwise, it is said to be "global".
For example, local support is defined as "the number of worlds within an instance, which
satisfy an itemset".
To define global support we need to define a *minimum local support threshold* sl which is
a real number between 0 and 1. Now, we can say that global support is "the number of
instances for which local support overpassed the minimum local support threshold".

As in the propositional setting, more meaningfulness measures can be defined starting from
support, but now they must respect the local/global dichotomy.

We now have all the ingredients to understand this type definition.
A [`MeaningfulnessMeasure`](@ref) is a tuple composed of a global meaningfulness
measure, a local threshold used internally, and a global threshold we would like our
itemsets (rules) to overpass.

See also [`gconfidence`](@ref), [`gsupport`](@ref), [`lsupport`](@ref),
[`lconfidence`](@ref).
"""
const MeaningfulnessMeasure = Tuple{Function,Threshold,Threshold}

"""
    islocalof(::Function, ::Function)::Bool

Twin method of [`isglobalof`](@ref).

Trait to indicate that a local meaningfulness measure is used as subroutine in a global
measure.

For example, `islocalof(lsupport, gsupport)` is `true`, and `isglobalof(gsupport, lsupport)`
is `false`.

!!! warning
    When implementing a custom meaningfulness measure, make sure to implement both
    [`islocalof`](@ref)/[`isglobalof`](@ref) and [`localof`](@ref)/[`globalof`](@ref).
    This is fundamental to guarantee the correct behavior of some methods, such as
    [`getlocalthreshold`](@ref).
    Alternatively, you can simply use the macro [`@linkmeas`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`isglobalof`](@ref),
[`linkmeas`](@ref), [`lsupport`](@ref).
"""
islocalof(::Function, ::Function)::Bool = false

"""
    isglobalof(::Function, ::Function)::Bool

Twin trait of [`islocalof`](@ref).

See also [`getlocalthreshold`](@ref), [`gsupport`](@ref), [`islocalof`](@ref),
[`linkmeas`](@ref), [`lsupport`](@ref).
"""
isglobalof(::Function, ::Function)::Bool = false

"""
    localof(::Function)::Union{Nothing,MeaningfulnessMeasure}

Return the local measure associated with the given one.

See also [`islocalof`](@ref), [`isglobalof`](@ref), [`globalof`](@ref), [`linkmeas`](@ref).
"""
localof(::Function) = nothing

"""
    globalof(::Function)::Union{Nothing,MeaningfulnessMeasure} = nothing

Return the global measure associated with the given one.

See also [`linkmeas`](@ref), [`islocalof`](@ref), [`isglobalof`](@ref), [`localof`](@ref).
"""
globalof(::Function) = nothing

"""
    const WorldMask = BitVector

Bitmask whose i-th position stores whether a certain (local) [`MeaningfulnessMeasure`](@ref)
applied on a specific [`Itemset`](@ref)s is true on the i-th world of a data instance.

The term "world" comes from the fact that a data instance is expressed as an entity-relation
object, such as a `SoleLogics.KripkeStructure`.

See also [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const WorldMask = BitVector

# utility structures

"""
    const LmeasMemoKey = Tuple{Symbol,ARMSubject,Integer}

Key of a [`LmeasMemo`](@ref) dictionary.
Represents a local meaningfulness measure name (as a `Symbol`), a [`ARMSubject`](@ref),
and the number of a dataset instance where the measure is applied.

See also [`ARMSubject`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref),
[`lconfidence`](@ref).
"""
const LmeasMemoKey = Tuple{Symbol,ARMSubject,Integer}

"""
    const LmeasMemo = Dict{LmeasMemoKey,Threshold}

Association between a local measure of a [`ARMSubject`](@ref) on a specific dataset
instance, and its value.

See also [`ARMSubject`](@ref), [`LmeasMemo`](@ref), [`lsupport`](@ref),
[`lconfidence`](@ref).
"""
const LmeasMemo = Dict{LmeasMemoKey,Threshold}

"""
    const GmeasMemoKey = Tuple{Symbol,ARMSubject}

Key of a [`GmeasMemo`](@ref) dictionary.
Represents a global meaningfulness measure name (as a `Symbol`) and a [`ARMSubject`](@ref).

See also [`ARMSubject`](@ref), [`GmeasMemo`](@ref), [`gconfidence`](@ref),
[`gsupport`](@ref).
"""
const GmeasMemoKey = Tuple{Symbol,ARMSubject}

"""
    const GmeasMemo = Dict{GmeasMemoKey,Threshold}

Association between a global measure of a [`ARMSubject`](@ref) on a dataset, and its value.

The reference to the dataset is not explicited here, since [`GmeasMemo`](@ref) is intended
to be used as a [memoization](https://en.wikipedia.org/wiki/Memoization) structure inside
[`Miner`](@ref) objects, and the latter already knows the dataset they are working
with.

See also [`GmeasMemoKey`](@ref), [`ARMSubject`](@ref).
"""
const GmeasMemo = Dict{GmeasMemoKey,Threshold} # global measure of an itemset/arule => value

"""
    const MiningState = Dict{Symbol,Any}

Additional informations associated with an [`ARMSubject`](@ref) that can be used to
specialize any concrete type deriving from [`AbstractMiner`](@ref), thus augmenting its
capabilities.

To understand how to specialize a [`Miner`](@ref), see [`hasminingstate`](@ref),
[`initminingstate`](@ref), ['miningstate`](@ref), [`miningstate!`](@ref).
"""
const MiningState = ConcurrentDict{Symbol,Any}

"""
    const Info = Dict{Symbol,Any}

Storage reserved to metadata about mining (e.g., execution time).

See also [`info`](@ref), [`info!`](@ref), [`hasinfo`](@ref), [`Miner`](@ref).
"""
const Info = Dict{Symbol,Any}

"""
    const MineableData = AbstractDataset

Any type on which mining can be performed.

See also [`Miner`](@info).
"""
const MineableData = AbstractDataset
