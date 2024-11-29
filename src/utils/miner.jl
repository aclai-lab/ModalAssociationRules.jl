"""
    struct Miner{
        D<:MineableData,
        I<:Item,
    } <: AbstractMiner
        X::D                            # target dataset

        algorithm::Function             # algorithm used to perform extraction

        items::Vector{I}                # items considered during the extraction

        # meaningfulness measures
        itemset_constrained_measures::Vector{IMEAS}
        arule_constrained_measures::Vector{RMEAS}

        freqitems::Vector{Itemset}      # collected frequent itemsets
        arules::Vector{ARule}           # collected association rules

        localmemo::LmeasMemo            # local memoization structure
        globalmemo::GmeasMemo           # global memoization structure

        miningstate::MiningState        # special fields related to mining algorithm

        info::Info                      # general informations
    end

Concrete [`AbstractMiner`](@ref) containing both the data, the logic and the
parameterization to perform association rule mining in the modal setting.

# Examples
```julia-repl
julia> using ModalAssociationRules
julia> using SoleData

# Load NATOPS DataFrame
julia> X_df, y = load_arff_dataset("NATOPS");

# Convert NATOPS DataFrame to a Logiset
julia> X = scalarlogiset(X_df)

# Prepare some propositional atoms
julia> p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
julia> q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
julia> r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

# Prepare modal atoms using later relationship - see [`SoleLogics.IntervalRelation`](@ref))
julia> lp = box(IA_L)(p)
julia> lq = diamond(IA_L)(q)
julia> lr = boxlater(r)

# Compose a vector of items, regrouping the atoms defined before
julia> manual_alphabet = Vector{Item}([p, q, r, lp, lq, lr])

# Create an association rule miner wrapping `fpgrowth` algorithm - see [`fpgrowth`](@ref);
# note that meaningfulness measures are not explicited and, thus, are defaulted as in the
# call below.
julia> miner = Miner(X, fpgrowth(), manual_alphabet)

# Create an association rule miner, expliciting global meaningfulness measures with their
# local and global thresholds, both for [`Itemset`](@ref)s and [`ARule`](@ref).
julia> miner = Miner(X, fpgrowth(), manual_alphabet,
    [(gsupport, 0.1, 0.1)], [(gconfidence, 0.2, 0.2)])

# Consider the dataset and learning algorithm wrapped by `miner` (resp., `X` and `fpgrowth`)
# Mine the frequent itemsets, that is, those for which item measures are large enough.
# Then iterate the generator returned by [`mine`](@ref) to enumerate association rules.
julia> for arule in ModalAssociationRules.mine!(miner)
    println(miner)
end
```

!!! note
    Miner's constructor provides a `rulesfit` keyword argument, which is a collection of
    functions defining an association rules generation politic.
    To know more, see [`isanchored_arule`](@ref) and [`isheterogeneous_arule`](@ref).

See also  [`ARule`](@ref), [`Bulldozer`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Info`](@ref), [`Itemset`](@ref), [`GmeasMemo`](@ref), [`LmeasMemo`](@ref),
[`MiningState`](@ref).
"""
struct Miner{
    D<:MineableData,
    I<:Item
} <: AbstractMiner
    X::D                            # target dataset

    algorithm::Function             # algorithm used to perform extraction

    items::Vector{I}                # alphabet

    # meaningfulness measures
    itemset_constrained_measures::Vector{<:MeaningfulnessMeasure}
    arule_constrained_measures::Vector{<:MeaningfulnessMeasure}

    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    localmemo::LmeasMemo            # local memoization structure
    globalmemo::GmeasMemo           # global memoization structure

    miningstate::MiningState        # mining algorithm miningstate (see documentation)

    itemset_mining_policies::Vector{<:Function}   # metarules about itemsets mining
    arule_mining_policies::Vector{<:Function}     # metarules about arules mining

    info::Info                      # general informations

    function Miner(
        X::D,
        algorithm::Function,
        items::Vector{I},

        itemset_constrained_measures::Vector{<:MeaningfulnessMeasure} = [
            (gsupport, 0.1, 0.1)
        ],
        arule_constrained_measures::Vector{<:MeaningfulnessMeasure} = [
            (gconfidence, 0.2, 0.2)
        ];

        itemset_mining_policies::Vector{<:Function} = Vector{Function}([

        ]),
        arule_mining_policies::Vector{<:Function} = Vector{Function}([
            islimited_length_arule(),
            isanchored_arule(),
            isheterogeneous_arule(),
        ]),

        info::Info = Info(:istrained => false)
    ) where {
        D<:MineableData,
        I<:Item,
    }
        # dataset frames must be equal
        if !(allequal([SoleLogics.frame(X, ith_instance)
            for ith_instance in 1:ninstances(X)]))
            throw(ArgumentError("Instances frame is shaped " *
                "differently. Please, provide an uniform dataset to guarantee " *
                "mining correctness."
            ))
        end

        # gsupport is crucial to mine association rule
        if !(ModalAssociationRules.gsupport in first.(itemset_constrained_measures))
            throw(ArgumentError(
                "Miner requires global support " *
                "(gsupport) as meaningfulness measure in order to work properly. " *
                "Please, add a tuple (gsupport, local support threshold, global support " *
                "threshold) to itemset_constrained_measures field.\n" *
                "Local support (lsupport) is needed too, but it is already considered " *
                "internally by gsupport."))
        end

        miningstate = initminingstate(algorithm, X)

        new{D,I}(X, algorithm, unique(items),
            itemset_constrained_measures, arule_constrained_measures,
            Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(),
            miningstate,
            itemset_mining_policies, arule_mining_policies,
            info
        )
    end
end

"""
    datatype(::Miner{D,I}) where {D<:MineableData,I<:Item}

Retrieve the type of [`MineableData`](@ref) wrapped within the [`Miner`](@ref).
"""
datatype(::Miner{D,I}) where {D<:MineableData,I<:Item} = D

"""
    itemtype(::Miner{D,I}) where {D<:MineableData,I<:Item} = I

Retrieve the most general type of [`Item`](@ref) wrapped within the [`Miner`](@ref).
"""
itemtype(::Miner{D,I}) where {D<:MineableData,I<:Item} = I

"""
    data(miner::Miner)::MineableData

See [`data(::AbstractMiner)`](@ref).
"""
data(miner::Miner)::MineableData = miner.X

"""
    items(miner::Miner)

See [`items(::AbstractMiner)`](@ref).
"""
items(miner::Miner) = miner.items

"""
    algorithm(miner::Miner)::Function

See [`algorithm(::AbstractMiner)`](@ref).
"""
algorithm(miner::Miner)::Function = miner.algorithm

"""
    freqitems(miner::Miner)

See [`freqitems(::AbstractMiner)`](@ref).
"""
freqitems(miner::Miner) = miner.freqitems

"""
    arules(miner::Miner)
See [`arules(::AbstractMiner)`](@ref).
"""
arules(miner::Miner) = miner.arules

"""
    itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

See [`itemsetmeasures(::AbstractMiner)`]
"""
itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
    miner.itemset_constrained_measures

"""
    rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

See [`rulemeasures(miner::AbstractMiner)`](@ref).
"""
rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
    miner.arule_constrained_measures

"""
    localmemo(miner::Miner)::LmeasMemo

See [`localmemo(::AbstractMiner)`](@ref).
"""
localmemo(miner::Miner) = miner.localmemo

"""
    globalmemo(miner::Miner)::GmeasMemo

See [`globalmemo(::AbstractMiner)`](@ref).
"""
globalmemo(miner::Miner) = miner.globalmemo

"""
    miningstate(miner::Miner)

See [`miningstate(::AbstractMiner)`](@ref).
"""
miningstate(miner::Miner) = miner.miningstate

"""
    info(miner::Miner)::Info = miner.info

Getter for `miner`'s structure holding meta informations about mining.

See also [`Miner`](@ref).
"""
info(miner::Miner)::Info = miner.info



# Miner's utilities

"""
    getlocalthreshold(miner::Miner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work locally (that is, analyzing "the inside"
of a dataset's instances) in `miner`.

See [`Miner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
function getlocalthreshold(miner::Miner, meas::Function)::Threshold
    return findmeasure(miner, meas)[2]
end

"""
    getglobalthreshold(miner::Miner, meas::Function)::Threshold

Getter for the [`Threshold`](@ref) associated with the function wrapped by some
[`MeaningfulnessMeasure`](@ref) tailored to work globally (that is, measuring the behavior
of a specific local-measure across all dataset's instances) in `miner`.

See [`Miner`](@ref), [`MeaningfulnessMeasure`](@ref), [`Threshold`](@ref).
"""
function getglobalthreshold(miner::Miner, meas::Function)::Threshold
    return findmeasure(miner, meas) |> last
end



"""
    function itemset_mining_policies(miner::Miner)

See [`itemset_mining_policies(::AbstractMiner)`](@ref).
"""
itemset_mining_policies(miner::Miner) = miner.itemset_mining_policies

"""
    arule_mining_policies(miner::Miner)

See [`itemset_mining_policies(::AbstractMiner)`](@ref).
"""
arule_mining_policies(miner::Miner) = miner.arule_mining_policies

function Base.show(io::IO, miner::Miner)
    println(io, "$(data(miner))")

    println(io, "Alphabet: $(items(miner))\n")
    println(io, "Items measures: $(itemsetmeasures(miner))")
    println(io, "Rules measures: $(rulemeasures(miner))\n")

    println(io, "# of frequent patterns mined: $(length(freqitems(miner)))")
    println(io, "# of association rules mined: $(length(arules(miner)))\n")

    println(io, "Local measures memoization structure entries: " *
        "$(length(miner.localmemo |> keys))")
    println(io, "Global measures memoization structure entries: " *
        "$(length(miner.globalmemo |> keys))\n")

    print(io, "Additional infos: $(info(miner) |> keys)\n")
    print(io, "Specialization fields: $(miningstate(miner) |> keys)")
end

"""
    analyze(arule::ARule, miner::Miner; io::IO=stdout, localities=false)

Detailed print of an [`ARule`](@ref) to the console, including related meaningfulness
measures values.

!!! warning
    Printing may be missing some information, as this needs to be refactored.
    We reccomend to realy on a custom dispatch at the moment.

See also [`ARule`](@ref), [`Miner`](@ref).
"""
function analyze(
    arule::ARule,
    miner::Miner;
    io::IO=stdout,
    itemsets_local_info::Bool=false,
    itemsets_global_info::Bool=false,
    rule_local_info::Bool=false,
    verbose::Bool=false,
    variablenames::Union{Nothing,Vector{String}}=nothing
)
    # print constraints
    if verbose
        itemsets_global_info = true
        itemsets_local_info = true
        rule_local_info = true
    end

    if itemsets_local_info
        itemsets_global_info = true
    end

    Base.show(io, arule; variablenames=variablenames)
    println(io, "")

    # report global emasures for the rule
    for measure in rulemeasures(miner)
        globalmeasure = first(measure)
        gmeassym = globalmeasure |> Symbol

        println(io, "\t$(gmeassym): $(globalmemo(miner, (gmeassym, arule)))")

        # report local measures for the rule
        if rule_local_info
            # find local measure (its name, as Symbol) associated with the global measure
            lmeassym = ModalAssociationRules.localof(globalmeasure) |> Symbol
            for i in 1:ninstances(miner |> data)
                println(io, "\t$(lmeassym): $(localmemo(miner, (lmeassym, arule, i))) ")
            end
            println(io, "")
        end
    end

    # report global measures for both antecedent and consequent
    if itemsets_global_info
        for measure in itemsetmeasures(miner)
            globalmeasure = first(measure)
            gmeassym = globalmeasure |> Symbol

            println(io, "\t$(gmeassym) - (antecedent): " *
                "$(globalmemo(miner, (gmeassym, antecedent(arule))))")
            # if itemsets_local_info
            # TODO -  report local measures for the antecedent (use `itemsets_localities`)

            println(io, "\t$(gmeassym) - (consequent): " *
                "$(globalmemo(miner, (gmeassym, consequent(arule))))")
            # if itemsets_local_info
            # TODO -  report local measures for the consequent (use `itemsets_localities`)

            _entire_content = union(antecedent(arule), consequent(arule))
            println(io, "\t$(gmeassym) - (entire): " *
                "$(globalmemo(miner, (gmeassym, _entire_content)))")
            # if itemsets_local_info
            # TODO -  report local measures for the consequent (use `itemsets_localities`)

        end
    end
end

"""
    generaterules!(miner::Miner)

See [`generaterules!(::Miner)`](@ref).
"""
function generaterules!(miner::Miner)
    if !info(miner, :istrained)
        throw(ErrorException("The miner should be trained before generating rules. " *
            "Please, invoke `mine!`."
        ))
    end

    return generaterules(freqitems(miner), miner)
end

"""
    generaterules(itemsets::AbstractVector{Itemset}, miner::Miner)

See [`generaterules(::AbstractVector{Itemset}, ::AbstractMiner)`](@ref).
"""
@resumable function generaterules(
    itemsets::AbstractVector{Itemset},
    miner::Miner;
    # TODO: this parameter is momentary and enables the computation of additional metrics
    # other than the `rulemeasures` specified within `miner`.
    compute_additional_metrics::Bool=true
)
    # From the original paper at 3.4 here:
    # http://www.rakesh.agrawal-family.com/papers/tkde96passoc_rj.pdf
    #
    # Given a frequent itemset l, rule generation examines each non-empty subset a
    # and generates the rule a => (l-a) with support = support(l) and
    # confidence = support(l)/support(a).
    # This computation can efficiently be done by examining the largest subsets of l first
    # and only proceeding to smaller subsets if the generated rules have the required
    # minimum confidence.
    # For example, given a frequent itemset ABCD, if the rule ABC => D does not have minimum
    # confidence, neither will AB => CD, and so we need not consider it.

    for itemset in filter(x -> length(x) >= 2, itemsets)
        subsets = powerset(itemset)

        for subset in subsets
            # subsets are built already sorted incrementally;
            # hence, since we want the antecedent to be longer initially,
            # the first subset values corresponds to (see comment below)
            # (l-a)
            _consequent = subset == Any[] ? Itemset{Item}() : subset
            # a
            _antecedent = symdiff(itemset, _consequent) |> Itemset

            # degenerate case
            if length(_antecedent) < 1 || length(_consequent) != 1
                continue
            end

            currentrule = ARule((_antecedent, _consequent))

            # apply generation policies to remove unwanted rules
            unwanted = false
            for policy in arule_mining_policies(miner)
                if !policy(currentrule)
                    unwanted = true
                    break
                end
            end

            if unwanted
                continue
            end

            interesting = true
            for meas in rulemeasures(miner)
                (gmeas_algo, lthreshold, gthreshold) = meas
                gmeas_result = gmeas_algo(
                    currentrule, data(miner), lthreshold, miner)

                # some meaningfulness measure test is failed
                if gmeas_result < gthreshold
                    interesting = false
                    break
                end
            end

            # all meaningfulness measure tests passed
            if interesting

                if compute_additional_metrics
                    # TODO: deprecate `compute_additional_metrics` kwarg and move this code
                    # in the cycle where a generic global measure is computed.
                    (_, __lthreshold, _) = rulemeasures(miner) |> first

                    for gmeas_algo in [glift, gconviction, gleverage]
                        gmeas_algo(currentrule, data(miner), __lthreshold, miner)
                    end
                end

                push!(arules(miner), currentrule)
                @yield currentrule
            # since a meaningfulness measure test failed,
            # we don't want to keep generating rules.
            else
                break
            end
        end
    end
end



# some utilities and new dispatches coming from external packages

"""
    function SoleLogics.frame(miner::AbstractMiner)

Getter for the frame wrapped within `miner`'s data field.

See also [`data`](@ref), [`Miner`](@ref).
"""
function SoleLogics.frame(miner::Miner)
    return SoleLogics.frame(data(miner), 1)
end

# TODO remove this if test works
# function SoleLogics.nworlds(miner::Miner)
#     return frame(miner) |> SoleLogics.nworlds
# end
