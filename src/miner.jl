"""
    struct Miner{
        DATA<:MineableData,
        MINALGO<:Function,
        I<:Item,
        IMEAS<:MeaningfulnessMeasure,
        RMEAS<:MeaningfulnessMeasure
    }
        X::DATA                             # target dataset
        algorithm::MINALGO                  # algorithm used to perform extraction
        items::Vector{I}                    # items considered during the extraction

                                            # meaningfulness measures
        item_constrained_measures::Vector{IMEAS}
        rule_constrained_measures::Vector{RMEAS}

        freqitems::Vector{Itemset}          # collected frequent itemsets
        arules::Vector{ARule}               # collected association rules

        lmemo::LmeasMemo                    # local memoization structure
        gmemo::GmeasMemo                    # global memoization structure

        powerups::Powerup                   # mining algorithm powerups (see documentation)
        info::Info                          # general informations
    end

Machine learning model interface to perform association rules extraction.

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

See also  [`ARule`](@ref), [`apriori`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Itemset`](@ref), [`GmeasMemo`](@ref), [`LmeasMemo`](@ref).
"""
struct Miner{
    DATA<:MineableData,
    MINALGO<:Function,
    I<:Item,
    IMEAS<:MeaningfulnessMeasure,
    RMEAS<:MeaningfulnessMeasure
} <: AbstractMiner
    # target dataset
    X::DATA
    # algorithm used to perform extraction
    algorithm::MINALGO
    # items considered during the extraction
    items::Vector{I}

    # meaningfulness measures
    item_constrained_measures::Vector{IMEAS}
    rule_constrained_measures::Vector{RMEAS}

    freqitems::Vector{Itemset}      # collected frequent itemsets
    arules::Vector{ARule}           # collected association rules

    lmemo::LmeasMemo                # local memoization structure
    gmemo::GmeasMemo                # global memoization structure

    powerups::Powerup               # mining algorithm powerups (see documentation)
    info::Info                      # general informations

    function Miner(
        X::DATA,
        algorithm::MINALGO,
        items::Vector{I},
        item_constrained_measures::Vector{IMEAS} = [(gsupport, 0.1, 0.1)],
        rule_constrained_measures::Vector{RMEAS} = [(gconfidence, 0.2, 0.2)];
        rulesift::Vector{<:Function} = Vector{Function}([
            anchor_rulecheck,
            non_selfabsorbed_rulecheck
        ]),
        disable_rulesifting::Bool = false,
        info::Info = Info(:istrained => false)
    ) where {
        DATA<:MineableData,
        MINALGO<:Function,
        I<:Item,
        IMEAS<:MeaningfulnessMeasure,
        RMEAS<:MeaningfulnessMeasure
    }
        # dataset frames must be equal
        @assert allequal([SoleLogics.frame(X, ith_instance)
            for ith_instance in 1:ninstances(X)]) "Instances frame is shaped " *
            "differently. Please, provide an uniform dataset to guarantee " *
            "mining correctness."

        # gsupport is indispensable to mine association rule
        @assert ModalAssociationRules.gsupport in reduce(
            vcat, item_constrained_measures) "Miner requires global support " *
            "(gsupport) as meaningfulness measure in order to work properly. " *
            "Please, add a tuple (gsupport, local support threshold, global support " *
            "threshold) to item_constrained_measures field.\n" *
            "Local support (lsupport) is needed too, but it is already considered " *
            "internally by gsupport."

        powerups = initpowerups(algorithm, X)
        if !disable_rulesifting
            powerups[:rulesift] = rulesift
        end

        new{DATA,MINALGO,I,IMEAS,RMEAS}(X, algorithm, unique(items),
            item_constrained_measures, rule_constrained_measures,
            Vector{Itemset}([]), Vector{ARule}([]),
            LmeasMemo(), GmeasMemo(), powerups, info
        )
    end
end

"""
    data(miner::Miner)::MineableData

Getter for the dataset wrapped by `miner`s.

See [`SoleBase.MineableData`](@ref),
[`SoleLogics.LogicalInstance`](@ref), [`Miner`](@ref).
"""
data(miner::Miner)::MineableData = miner.X

"""
    algorithm(miner::Miner)::Function

Getter for the mining algorithm loaded into `miner`.

See [`Miner`](@ref).
"""
algorithm(miner::Miner)::Function = miner.algorithm

"""
    items(miner::AbstractMiner)

Getter for the items of [`Item`](@ref)s loaded into `miner`.

See [`Item`](@ref), [`Miner`](@ref).
"""
items(miner::AbstractMiner) = miner.items

"""
    itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

Return the [`MeaningfulnessMeasure`](@ref)s tailored to work with [`Itemset`](@ref)s,
loaded inside `miner`.

See  [`Itemset`](@ref), [`MeaningfulnessMeasure`](@ref), [`Miner`](@ref).
"""
itemsetmeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
    miner.item_constrained_measures

"""
    additemmeas(miner::Miner, measure::MeaningfulnessMeasure)

Add a new `measure` to `miner`'s [`itemsetmeasures`](@ref).

See also [`addrulemeas`](@ref), [`Miner`](@ref), [`rulemeasures`](@ref).
"""
function additemmeas(miner::Miner, measure::MeaningfulnessMeasure)
    @assert measure in first.(itemsetmeasures(miner)) "Miner already contains $(measure)."
    push!(itemsetmeasures(miner), measure)
end

"""
    rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

Return the [`MeaningfulnessMeasure`](@ref)s tailored to work with [`ARule`](@ref)s, loaded
inside `miner`.

See [`Miner`](@ref), [`ARule`](@ref), [`MeaningfulnessMeasure`](@ref).
"""
rulemeasures(miner::Miner)::Vector{<:MeaningfulnessMeasure} =
    miner.rule_constrained_measures

"""
    addrulemeas(miner::Miner, measure::MeaningfulnessMeasure)

Add a new `measure` to `miner`'s [`rulemeasures`](@ref).

See also [`itemsetmeasures`](@ref), [`Miner`](@ref), [`rulemeasures`](@ref).
"""
function addrulemeas(miner::Miner, measure::MeaningfulnessMeasure)
    @assert measure in first.(rulemeasures(miner)) "Miner already contains $(measure)."
    push!(rulemeasures(miner), measure)
end

"""
    measures(miner::Miner)::Vector{<:MeaningfulnessMeasure}

Return all the [`MeaningfulnessMeasures`](@ref) wrapped by `miner`.

See also [`MeaningfulnessMeasure`](@ref), [`Miner`](@ref).
"""
function measures(miner::Miner)::Vector{<:MeaningfulnessMeasure}
    return vcat(itemsetmeasures(miner), rulemeasures(miner))
end

"""
    findmeasure(
        miner::AbstractMiner,
        meas::Function;
        recognizer::Function=islocalof
    )::MeaningfulnessMeasure

Retrieve the [`MeaningfulnessMeasure`](@ref) associated with `meas`.

See also [`isglobalof`](@ref), [`islocalof`](@ref), [`MeaningfulnessMeasure`](@ref),
[`Miner`](@ref).
"""
function findmeasure(
    miner::AbstractMiner,
    meas::Function;
    recognizer::Function=islocalof
)::MeaningfulnessMeasure
    try
        return Iterators.filter(
            m -> first(m)==meas || recognizer(meas, first(m)), measures(miner)) |> first
    catch e
        if isa(e, ArgumentError)
            error("The provided miner has no measure $meas. " *
            "Maybe the miner is not initialized properly, and $meas is omitted. " *
            "Please use itemsetmeasures/rulemeasures to check which measures are , " *
            "available and miner's setters to add a new measures and their thresholds.")
        else
            rethrow(e)
        end
    end
end

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
    freqitems(miner::Miner)

Return all frequent [`Itemset`](@ref)s mined by `miner`.

See also [`Itemset`](@ref), [`Miner`](@ref).
"""
freqitems(miner::Miner) = miner.freqitems

"""
    arules(miner::Miner)

Return all the [`ARule`](@ref)s mined by `miner`.

See also [`ARule`](@ref), [`Miner`](@ref).
"""
arules(miner::Miner) = miner.arules

"""
    localmemo(miner::Miner)::LmeasMemo
    localmemo(miner::Miner, key::LmeasMemoKey)

Return the local memoization structure inside `miner`, or a specific entry if a
[`LmeasMemoKey`](@ref) is provided.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
localmemo(miner::AbstractMiner)::LmeasMemo = miner.lmemo
localmemo(miner::AbstractMiner, key::LmeasMemoKey) = get(miner.lmemo, key, nothing)

"""
    localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the local memoization structure wrapped by `miner`.

See also [`Miner`](@ref), [`LmeasMemo`](@ref), [`LmeasMemoKey`](@ref).
"""
function localmemo!(miner::Miner, key::LmeasMemoKey, val::Threshold)
    miner.lmemo[key] = val
end

"""
    globalmemo(miner::Miner)::GmeasMemo
    globalmemo(miner::Miner, key::GmeasMemoKey)

Return the global memoization structure inside `miner`, or a specific entry if a
[`GmeasMemoKey`](@ref) is provided.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo(miner::Miner)::GmeasMemo = miner.gmemo
globalmemo(miner::Miner, key::GmeasMemoKey) = get(miner.gmemo, key, nothing)

"""
    globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold)

Setter for a specific entry `key` inside the global memoization structure wrapped by
`miner`.

See also [`Miner`](@ref), [`GmeasMemo`](@ref), [`GmeasMemoKey`](@ref).
"""
globalmemo!(miner::Miner, key::GmeasMemoKey, val::Threshold) = begin
    miner.gmemo[key] = val
end



# Miner's specializations structures

"""
    powerups(miner::Miner)::Powerup
    powerups(miner::Miner, key::Symbol)
    powerups(miner::Miner, key::Symbol, inner_key)

Getter for the entire powerups structure currently loaded in `miner`, or a specific powerup.

See also [`haspowerup`](@ref), [`initpowerups`](@ref), [`Miner`](@ref), [`Powerup`](@ref).
"""
powerups(miner::Miner)::Powerup = miner.powerups
powerups(miner::Miner, key::Symbol) = miner.powerups[key]
powerups(miner::Miner, key::Symbol, inner_key) = miner.powerups[key][inner_key]

"""
    powerups!(miner::Miner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`powerups`](@ref).

See also [`haspowerup`](@ref), [`initpowerups`](@ref), [`Miner`](@ref), [`Powerup`](@ref).
"""
powerups!(miner::Miner, key::Symbol, val) = miner.powerups[key] = val
powerups!(miner::Miner, key::Symbol, inner_key, val) = miner.powerups[key][inner_key] = val

"""
    haspowerup(miner::Miner, key::Symbol)

Return whether `miner` powerups field contains an entry `key`.

See also [`Miner`](@ref), [`Powerup`](@ref), [`powerups`](@ref).
"""
haspowerup(miner::Miner, key::Symbol) = haskey(miner |> powerups, key)

"""
    initpowerups(::Function, ::MineableData)

This defines how [`Miner`](@ref)'s `powerup` field is filled to optimize the mining.
"""
initpowerups(::Function, ::MineableData)::Powerup = Powerup()

"""
    info(miner::Miner)::Powerup
    info(miner::Miner, key::Symbol)

Getter for the entire additional informations field inside a `miner`, or one of its specific
entries.

See also [`Miner`](@ref), [`Powerup`](@ref).
"""
info(miner::Miner)::Powerup = miner.info
info(miner::Miner, key::Symbol) = miner.info[key]

"""
    info!(miner::Miner, key::Symbol, val)

Setter for the content of a specific field of `miner`'s [`info`](@ref).

See also [`hasinfo`](@ref), [`info`](@ref), [`Miner`](@ref).
"""
info!(miner::Miner, key::Symbol, val) = miner.info[key] = val

"""
    hasinfo(miner::Miner, key::Symbol)

Return whether `miner` additional informations field contains an entry `key`.

See also [`Miner`](@ref).
"""
hasinfo(miner::Miner, key::Symbol) = haskey(miner |> info, key)

"""
    mine!(miner::Miner; kwargs...)

Synonym for `ModalAssociationRules.apply!(miner, data(miner))`.

See also [`ARule`](@ref), [`Itemset`](@ref), [`ModalAssociationRules.apply`](@ref).
"""
function mine!(miner::Miner; kwargs...)
    return apply!(miner, data(miner); kwargs...)
end

"""
    apply!(miner::Miner, X::MineableData; forcemining::Bool=false, kwargs...)

Extract association rules in the dataset referenced by `miner`, saving the interesting
[`Itemset`](@ref)s inside `miner`.
Then, return a generator of [`ARule`](@ref)s.

!!! note
    All the kwargs are forwarded to the mining algorithm within `miner`.

See also [`ARule`](@ref), [`Itemset`](@ref).
"""
function apply!(miner::Miner, X::MineableData; forcemining::Bool=false, kwargs...)
    if info(miner, :istrained) && !forcemining
        @warn "Miner has already been trained. To force mining, set `forcemining=true`."
        return Nothing
    end

    miner.algorithm(miner, X; kwargs...)
    info!(miner, :istrained, true)

    return generaterules(freqitems(miner), miner)
end

"""
    generaterules!(miner::Miner; kwargs...)

Return a generator of [`ARule`](@ref)s, given an already trained [`Miner`](@ref).

See also [`ARule`](@ref), [`Miner`](@ref).
"""
function generaterules!(miner::Miner)
    if !info(miner, :istrained)
        error("Miner should be trained before generating rules. Please, invoke `mine!`.")
    end

    return generaterules(freqitems(miner), miner)
end

function Base.show(io::IO, miner::Miner)
    println(io, "$(data(miner))")

    println(io, "Alphabet: $(items(miner))\n")
    println(io, "Items measures: $(itemsetmeasures(miner))")
    println(io, "Rules measures: $(rulemeasures(miner))\n")

    println(io, "# of frequent patterns mined: $(length(freqitems(miner)))")
    println(io, "# of association rules mined: $(length(arules(miner)))\n")

    println(io, "Local measures memoization structure entries: " *
        "$(length(miner.lmemo |> keys))")
    println(io, "Global measures memoization structure entries: " *
        "$(length(miner.gmemo |> keys))\n")

    print(io, "Additional infos: $(info(miner) |> keys)\n")
    print(io, "Specialization fields: $(powerups(miner) |> keys)")
end

"""
    analyze(arule::ARule, miner::Miner; io::IO=stdout, localities=false)

Print an [`ARule`](@ref) analysis to the console, including related meaningfulness measures
values.

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
        gmeas = first(measure)
        gmeassym = gmeas |> Symbol

        println(io, "\t$(gmeassym): $(globalmemo(miner, (gmeassym, arule)))")

        # report local measures for the rule
        if rule_local_info
            # find local measure (its name, as Symbol) associated with the global measure
            lmeassym = ModalAssociationRules.localof(gmeas) |> Symbol
            for i in 1:ninstances(miner |> data)
                print(io, "$(lmeassym): $(localmemo(miner, (lmeassym, arule, i))) ")
            end
            println(io, "")
        end
    end

    # report global measures for both antecedent and consequent
    if itemsets_global_info
        for measure in itemsetmeasures(miner)
            gmeas = first(measure)
            gmeassym = gmeas |> Symbol

            println(io, "\t$(gmeassym) - (antecedent): " *
                "$(globalmemo(miner, (gmeassym, antecedent(arule))))")
            # if itemsets_local_info
            # TODO: report local measures for the antecedent (use `itemsets_localities`)

            println(io, "\t$(gmeassym) - (consequent): " *
                "$(globalmemo(miner, (gmeassym, consequent(arule))))")
            # if itemsets_local_info
            # TODO: report local measures for the consequent (use `itemsets_localities`)

            _entire_content = union(antecedent(arule), consequent(arule))
            println(io, "\t$(gmeassym) - (entire): " *
                "$(globalmemo(miner, (gmeassym, _entire_content)))")
            # if itemsets_local_info
            # TODO: report local measures for the consequent (use `itemsets_localities`)

        end
    end

    println(io, "")
end



# Some utilities and new dispatches of external packages

function SoleLogics.frame(miner::Miner)
    return SoleLogics.frame(data(miner), 1)
end

function SoleLogics.allworlds(miner::Miner)
    return frame(miner) |> SoleLogics.allworlds
end

function SoleLogics.nworlds(miner::Miner)
    return frame(miner) |> SoleLogics.nworlds
end
