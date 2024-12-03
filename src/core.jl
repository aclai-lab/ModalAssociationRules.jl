"""
    struct Item{F<:SoleLogics.Formula}
        formula::F
    end

Fundamental type in the context of
[association rule mining](https://en.wikipedia.org/wiki/Association_rule_learning).

The name [`Item`](@ref) comes from the classical association rule mining jargon,
but it is simply a wrapper around a logical formula, whose truth value can be checked on a
model. To know more about logical formulas, see
[SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).

See also [`ARule`](@ref), [`gconfidence`](@ref), [`Itemset`](@ref),
[`MeaningfulnessMeasure`](@ref), [SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).
"""
struct Item{F<:SoleLogics.Formula}
    formula::F

    function Item(formula::F) where {F<:SoleLogics.Formula}
        return new{F}(formula)
    end
end

function Base.convert(::Type{Item}, formula::SoleLogics.Formula)::Item
    return Item(formula)
end

"""
    formula(item::Item{F}) where {F}

See also [`Item`](@ref), [SoleLogics.Formula](https://aclai-lab.github.io/SoleLogics.jl/stable/getting-started/#SoleLogics.Formula).
"""
formula(item::Item{F}) where {F<:SoleLogics.Formula} = item.formula

function Base.isless(a::Item, b::Item)
    isless(hash(a), hash(b))
end

function Base.show(io::IO, item::Item)
    print(io, syntaxstring(item.formula))
end

"""
    const Itemset{I<:Item} = Vector{I}

Vector collecting multiple [`Item`](@ref)s.

Semantically, [`Itemset`](@ref)s represent [`Item`](@ref)s (that is, formulas) conjunctions.

!!! note
    In the context of association rule mining, *interesting* itemsets are manipulated to
    discover *interesting* relations between [`Item`](@ref)s, in the form of association
    rules ([ARule](@ref)).

    Interestingness is established through a set of [`MeaningfulnessMeasure`](@ref).

!!! details
    Itemsets are implemented as a vector for two reasons:

    1. [lookup is faster](https://www.juliabloggers.com/set-vs-vector-lookup-in-julia-a-closer-look/)
    when the collection is small (an itemset is unlikely to consist of more than 100 items);

    2. most of the time, we want to keep an ordering between items while searching for
    interesting itemsets.

# Examples
```julia
julia> p = ScalarCondition(VariableMin(1), >, 1.0)  |> Atom |> Item
min[V1] > 1.0
julia> q = ScalarCondition(VariableMin(2), >=, 0.0) |> Atom |> Item
min[V2] ≥ 0.0

julia> pq = Itemset([p,q])
julia> qp = Itemset([q,p])

julia> pq == qp
true
julia> pq === qp
false

julia> r = ScalarCondition(VariableMax(3), <=, 2.0) |> Atom |> Item
max[V3] ≤ 2.0
julia> pqr = [pq; r];

julia> pq in pqr
true

julia> formula(pqr) |> syntaxstring
"(min[V1] > 1.0) ∧ (min[V2] ≥ 0.0) ∧ (max[V3] ≤ 2.0)"
```

See also [`ARule`](@ref), [`formula`](@ref), [`gsupport`](@ref), [`Item`](@ref),
[`lsupport`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
const Itemset{I<:Item} = Vector{I}

Itemset{I}() where {I<:Item} = I[]
Itemset{I}(item::Item) where {I<:Item} = I[item]

Itemset(f::SoleLogics.Formula) = Itemset{Item}(Item(f))
Itemset(item::Item) = Itemset{typeof(item)}(item)
Itemset(items::Vector{I}) where {I<:Item} = Itemset{I}(items)

function Base.convert(::Type{Itemset}, item::Item)
    return Itemset{typeof(item)}(item)
end

function Base.:(==)(itemset1::Itemset, itemset2::Itemset)
    # order is important
    # return items(itemset1) == items(itemset2)

    # order is ignored
    # TODO test using ⊂ instead of in
    return length(itemset1) == length(itemset2) && itemset1 in itemset2
end

function Base.in(itemset1::Itemset, itemset2::Itemset)
    # naive quadratic search solution is better than the second one (commented)
    # since itemsets are intended to be fairly short (6/7 conjuncts at most).
    return all(item -> item in itemset2, itemset1)
    # return issubset(Set(itemset1) in Set(itemset2))
end

function Base.show(io::IO, itemset::Itemset)
    print(io, "[" * join([syntaxstring(item) for item in itemset], ", ") * "]")
end

"""
    formula(itemset::Itemset)::SoleLogics.LeftmostConjunctiveForm

Conjunctive normal form of the [`Item`](@ref)s contained in `itemset`.

See also [`Item`](@ref), [`Itemset`](@ref),
[`SoleLogics.LeftmostConjunctiveForm`](https://aclai-lab.github.io/SoleLogics.jl/stable/more-on-formulas/#SoleLogics.LeftmostConjunctiveForm)
"""
formula(itemset::Itemset)::SoleLogics.LeftmostConjunctiveForm = begin
    formula.(itemset) |> LeftmostConjunctiveForm
end

"""
    const ARule = Tuple{Itemset,Itemset}

An association rule represents a *frequent* and *meaningful* co-occurrence relationship of
the form "X ⇒ Y", between two [`Itemset`](@ref)s X and Y, where X ∩ Y = ∅, respectively
called [`antecedent`](@ref) and [`consequent`](@ref).

!!! note
    Extracting all the [`ARule`](@ref) "hidden" in the data is the main purpose of
    association rule mining (ARM).

    Given an itemset Z containing atleast two [`Item`](@ref)s (|Z| ≥ 2), it can be
    partitioned in two (sub)itemsets X and Y; trying all the possible binary partitioning
    of Z is a systematic way to generate [`ARule`](@ref)s.

    The general framework always followed by ARM techniques is to, firstly, generate all the
    frequent itemsets considering a set of [`MeaningfulnessMeasure`](@ref) specifically
    tailored to work with [`Itemset`](@ref)s.

    Thereafter, all the association rules are generated by testing all the combinations of
    frequent itemsets against another set of [`MeaningfulnessMeasure`](@ref), this time
    designed to capture how interesting a rule is.

See also [`antecedent`](@ref), [`consequent`](@ref), [`gconfidence`](@ref),
[`Itemset`](@ref), [`lconfidence`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
struct ARule
    antecedent::Itemset
    consequent::Itemset

    function ARule(antecedent::Itemset, consequent::Itemset)
        intersection = intersect(antecedent, consequent)
        if !(intersection |> length == 0)
            throw(ArgumentError("Invalid rule. " *
                "Antecedent and consequent share the following items: $(intersection)."
            ))
        end

        new(antecedent, consequent)
    end

    function ARule(doublet::Tuple{Itemset,Itemset})
        ARule(first(doublet), last(doublet))
    end
end

Itemset(rule::ARule) = convert(Itemset, rule)

"""
    content(rule::ARule)::Tuple{Itemset,Itemset}

Getter for the content of an [`ARule`](@ref), that is, both its [`antecedent`](@ref) and
its [`consequent`](@ref).

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`Itemset`](@ref).
"""
content(rule::ARule)::Tuple{Itemset,Itemset} = (rule.antecedent, rule.consequent)

"""
    antecedent(rule::ARule)::Itemset

Getter for `rule`'s antecedent.

See also [`antecedent`](@ref), [`ARule`](@ref), [`Itemset`](@ref).
"""
antecedent(rule::ARule)::Itemset = rule.antecedent

"""
    consequent(rule::ARule)::Itemset

Getter for `rule`'s consequent.

See also [`consequent`](@ref), [`ARule`](@ref), [`Itemset`](@ref).
"""
consequent(rule::ARule)::Itemset = rule.consequent

"""
    function Base.:(==)(rule1::ARule, rule2::ARule)

Antecedent (consequent) [`Item`](@ref)s ordering could be different between the two
[`ARule`](@ref), but they are essentially the same rule.

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref).
"""
function Base.:(==)(rule1::ARule, rule2::ARule)
    # first antecedent must be included in the second one,
    # same when considering the consequent;
    # if this is true and lengths are the same, then the two parts coincides.
    return length(antecedent(rule1)) == length(antecedent(rule2)) &&
        length(consequent(rule1)) == length(consequent(rule2)) &&
        antecedent(rule1) in antecedent(rule2) &&
        consequent(rule1) in consequent(rule2)
end

"""
    function Base.convert(::Type{Itemset}, arule::ARule)::Itemset

Convert an [`ARule`](@ref) to an [`Itemset`](@ref) by merging its [`antecedent`](@ref)
and consequent [`consequent`](@ref).

See also [`antecedent`](@ref), [`ARule`](@ref), [`consequent`](@ref), [`Itemset`](@ref).
"""
function Base.convert(::Type{Itemset}, arule::ARule)::Itemset
    return Itemset(vcat(antecedent(arule), consequent(arule)))
end

function Base.hash(arule::ARule, h::UInt)
    _antecedent = sort(arule |> antecedent)
    _consequent = sort(arule |> consequent)
    return hash(vcat(_antecedent, _consequent), h)
end

function Base.show(
    io::IO,
    arule::ARule;
    variablenames::Union{Nothing,Vector{String}}=nothing
)
    _antecedent = arule |> antecedent |> formula
    _consequent = arule |> consequent |> formula

    print(io, "$(syntaxstring(_antecedent, variable_names_map=variablenames)) => " *
        "$(syntaxstring(_consequent, variable_names_map=variablenames))")
end

"""
    ARMSubject = Union{ARule,Itemset}

Each entity mined through an association rule mining algorithm.

See also [`ARule`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref), [`Itemset`](@ref),
[`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
const ARMSubject = Union{ARule,Itemset}



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

Vector whose i-th position stores how many times a certain [`MeaningfulnessMeasure`](@ref)
applied on a specific [`Itemset`](@ref)s is true on the i-th world of multiple instances.

If a single instance is considered, then this acts as a bit mask.

For example, if we consider 5 Kripke models of a modal dataset, each of which containing 3
worlds, then the [`WorldMask`](@ref) of an itemset could be [5,2,0], meaning that the
itemset is always true on the first world of every instance. In the second world, the same
itemset is true on it only for two instances. Considering the third world, then the itemset
is never true.

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
const MiningState = Dict{Symbol,Any}

"""
    const Info = Dict{Symbol,Any}

Storage reserved to metadata about mining (e.g., execution time).

See also [`info`](@ref), [`info!`](@ref), [`hasinfo`](@ref), [`Miner`](@ref).
"""
const Info = Dict{Symbol,Any}

"""
    const MineableData = MineableData

Any type on which mining can be performed.

See also [`Miner`](@info).
"""
const MineableData = AbstractDataset

"""
    initminingstate(::Function, ::MineableData)

This trait defines how to initialize the [`MiningState`](@ref) structure of an
[`AbstractMiner`](@ref), in order to customize it to your needings depending on a specific
function/data pairing.

See ealso [`hasminingstate`](@ref), [`AbstractMiner`](@ref), [`MiningState`](@ref),
[`miningstate`](@ref).
"""
initminingstate(::Function, ::MineableData)::MiningState = MiningState()
