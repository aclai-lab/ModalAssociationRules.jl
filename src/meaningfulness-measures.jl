"""
Collection of [`powerups`](@ref) references which are injected when creating a generic
local meaningfulness measure using [`lmeas`](@ref).
"""
LOCAL_POWERUP_SYMBOLS = [
    :instance_item_toworlds
]
"""
Collection of [`powerups`](@ref) references which are injected when creating a generic
global meaningfulness measure using [`gmeas`](@ref).
"""
GLOBAL_POWERUP_SYMBOLS = []

"""
    macro lmeas(measname, measlogic)

Build a generic local meaningfulness measure.
By default, internal `miner`'s memoization is leveraged.
To specialize an already existent measure, take a look at [`powerups`](@ref) system.

See also [`haspowerups`](@ref), [`Miner`](@ref), [`powerups`](@ref).
"""
macro lmeas(measname, measlogic)
    fname = Symbol(measname)

    quote
        # wrap the given `measlogic` to leverage memoization and document it
        Core.@__doc__ function $(esc(fname))(
            subject::ARMSubject,
            instance::LogicalInstance,
            miner::Miner
        )
            # retrieve logiset and the specific instance
            X, ith_instance = instance.s, instance.ith_instance

            # key to access memoization structures
            memokey = LmeasMemoKey((Symbol($(esc(fname))), subject, ith_instance))

            # leverage memoization if possible
            memoized = localmemo(miner, memokey)
            if !isnothing(memoized)
                return memoized
            end

            # compute local measure
            response = $(esc(measlogic))(subject, X, ith_instance, miner)
            measure = response[:measure]

            # save measure in memoization structure;
            # also, do more stuff depending on `powerups` dispatch (see the documentation).
            localmemo!(miner, memokey, measure)
            for powerup in LOCAL_POWERUP_SYMBOLS
                # the numerical value necessary to save more informations about the relation
                # between an instance and an subject must be obtained by the internal logic
                # of the meaningfulness measure callback.
                if haspowerup(miner, powerup) && haskey(response, powerup)
                    powerups(miner, powerup)[(ith_instance, subject)] = response[powerup]
                end
            end
            # Note that the powerups system could potentially irrorate the entire package
            # and could be expandend/specialized;
            # for example, a category of powerups is necessary to fill (ith_instance, subject)
            # fields, other are necessary to save informations about something else.

            return measure
        end

        # export the generated function
        export $(esc(fname))
    end
end

"""
    macro gmeas(measname, measlogic)

Build a generic global meaningfulness measure.
By default, internal `miner`'s memoization is leveraged.
To specialize an already existent measure, take a look at [`powerups`](@ref) system.

See also [`haspowerups`](@ref), [`Miner`](@ref), [`powerups`](@ref).
"""
macro gmeas(measname, measlogic)
    fname = Symbol(measname)

    quote
        # wrap the given `measlogic` to leverage memoization
        Core.@__doc__ function $(esc(fname))(
            subject::ARMSubject,
            X::SupportedLogiset,
            threshold::Threshold,
            miner::Miner
        )
            # key to access memoization structures
            memokey = GmeasMemoKey((Symbol($(esc(fname))), subject))

            # leverage memoization if possible
            memoized = globalmemo(miner, memokey)
            if !isnothing(memoized)
                return memoized
            end

            # compute local measure
            response = $(esc(measlogic))(subject, X, threshold, miner)
            measure = response[:measure]

            # save measure in memoization structure;
            # also, do more stuff depending on `powerups` dispatch (see the documentation).
            # to know more, see `lmeas` comments.
            globalmemo!(miner, memokey, measure)
            for powerup in GLOBAL_POWERUP_SYMBOLS
                if haspowerup(miner, powerup) && haskey(response, powerup)
                    powerups(miner, powerup)[(subject)] = response[powerup]
                end
            end

            return measure
        end

        # export the generated function
        export $(esc(fname))
    end
end

"""
    macro linkmeas(gmeasname, lmeasname)

Link together two [`MeaningfulnessMeasure`](@ref), automatically defining
[`globalof`](@ref)/[`localof`](@ref) and [`isglobalof`](@ref)/[`islocalof`](@ref).

See also [`globalof`](@ref), [`localof`](@ref), [`isglobalof`](@ref), [`islocalof`](@ref).
"""
macro linkmeas(gmeasname, lmeasname)
    quote
        ModalAssociationRules.islocalof(
            ::typeof($(lmeasname)), ::typeof($(gmeasname))) = true
        ModalAssociationRules.isglobalof(
            ::typeof($(gmeasname)), ::typeof($(lmeasname))) = true
        ModalAssociationRules.localof(::typeof($(gmeasname))) = $(lmeasname)
        ModalAssociationRules.globalof(::typeof($(lmeasname))) = $(gmeasname)
    end
end

# core logic of `lsupport`, as a lambda function
_lsupport_logic = (itemset, X, ith_instance, miner) -> begin
    # bool vector, representing on which world an Itemset holds
    wmask = [check(toformula(itemset), X, ith_instance, w) for w in allworlds(X, ith_instance)]

    # return the result, and eventually the information needed to support powerups
    return Dict(
        :measure => count(wmask) / nworlds(X, ith_instance),
        :instance_item_toworlds => wmask,
    )
end

# core logic of `gsupport`, as a lambda function
_gsupport_logic = (itemset, X, threshold, miner) -> begin
    _measure = sum([
        lsupport(itemset, getinstance(X, ith_instance), miner) >= threshold
        for ith_instance in 1:ninstances(X)
    ]) / ninstances(X)

    return Dict(:measure => _measure)
end

"""
    function lsupport(
        itemset::Itemset,
        instance::LogicalInstance;
        miner::Union{Nothing,Miner}=nothing
    )::Float64

Compute the local support for the given `itemset` in the given `instance`.

Local support is the ratio between the number of worlds in a [`LogicalInstance`](@ref) where
and [`Itemset`](@ref) is true and the total number of worlds in the same instance.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`Miner`](@ref), [`LogicalInstance`](@ref), [`Itemset`](@ref).
"""
@lmeas lsupport _lsupport_logic

"""
    function gsupport(
        itemset::Itemset,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,Miner}=nothing
    )::Float64

Compute the global support for the given `itemset` on a logiset `X`, considering `threshold`
as the threshold for the local support called internally.

Global support is the ratio between the number of [`LogicalInstance`](@ref)s in a
[`SupportedLogiset`](@ref) for which the local support, [`lsupport`](@ref), is greater than
a [`Threshold`](@ref), and the total number of instances in the same logiset.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`Miner`](@ref), [`LogicalInstance`](@ref), [`Itemset`](@ref),
[`SupportedLogiset`](@ref), [`Threshold`](@ref).
"""
@gmeas gsupport _gsupport_logic

_lconfidence_logic = (rule, X, ith_instance, miner) -> begin
    den = lsupport(antecedent(rule), getinstance(X, ith_instance), miner)
    num = lsupport(convert(Itemset, rule), getinstance(X, ith_instance), miner)

    # Return the result, and eventually the information needed to support powerups
    return Dict(:measure => num/den)
end

_gconfidence_logic = (rule, X, threshold, miner) -> begin
    _antecedent = antecedent(rule)
    _consequent = consequent(rule)
    _union = union(_antecedent, _consequent)

    num = gsupport(_union, X, threshold, miner)
    den = gsupport(_antecedent, X, threshold, miner)
    return Dict(:measure => num/den)
end

"""
    function lconfidence(
        rule::ARule,
        ith_instance::LogicalInstance;
        miner::Union{Nothing,Miner}=nothing
    )::Float64

Compute the local confidence for the given `rule` in the given instance.

Local confidence is the ratio between [`lsupport`](@ref) of an [`ARule`](@ref) on
a [`LogicalInstance`](@ref) and the [`lsupport`](@ref) of the [`antecedent`](@ref) of the
same rule.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`antecedent`](@ref), [`ARule`](@ref), [`Miner`](@ref),
[`LogicalInstance`](@ref), [`lsupport`](@ref).
"""
@lmeas lconfidence _lconfidence_logic

"""
    function gconfidence(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,Miner}=nothing
    )::Float64

Compute the global confidence for the given `rule` on a logiset `X`, considering
`threshold` as the threshold for the global support called internally.

Global confidence is the ratio between [`gsupport`](@ref) of an [`ARule`](@ref) on
a [`SupportedLogiset`](@ref) and the [`gsupport`](@ref) of the [`antecedent`](@ref) of
the same rule.

If a miner is provided, then its internal state is updated and used to leverage
memoization.

See also [`antecedent`](@ref), [`ARule`](@ref), [`Miner`](@ref), [`gsupport`](@ref),
[`SupportedLogiset`](@ref).
"""
@gmeas gconfidence _gconfidence_logic

# all the meaningfulness measures defined in this file are linked here,
# meaning that a global measure is associated to its corresponding local one.
@linkmeas gsupport lsupport
@linkmeas gconfidence lconfidence
