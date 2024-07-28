"""
Collection of [`powerups`](@ref) references which are injected when creating a generic
local meaningfulness measure using [`lmeas`](@ref).
"""
LOCAL_POWERUP_SYMBOLS = [
    :instance_item_toworlds
]
GLOBAL_POWERUP_SYMBOLS = []

"""
    function lmeas(
        itemset::Itemset,
        instance::LogicalInstance,
        miner::Miner,
        measlogic::Function
    )

Build a generic local meaningfulness measure.
By default, internal `miner`'s memoization is leveraged.
To specialize an already existent measure, take a look at [`powerups`](@ref) system.

See also [`haspowerups`](@ref), [`Miner`](@ref), [`powerups`](@ref).
"""
macro lmeas(measname, measlogic)
    fname = Symbol(measname)

    quote
        # wrap the given `measlogic` to leverage memoization
        function $(esc(fname))(subject::ARMSubject, instance::LogicalInstance, miner::Miner)
            # retrieve logiset and the specific instance
            X, i_instance = instance.s, instance.i_instance

            # key to access memoization structures
            memokey = LmeasMemoKey((Symbol($(esc(fname))), subject, i_instance))

            # leverage memoization if possible
            memoized = localmemo(miner, memokey)
            if !isnothing(memoized)
                return memoized
            end

            # compute local measure
            response = $(esc(measlogic))(subject, instance, miner)
            measure = response[:measure]

            # save measure in memoization structure;
            # also, do more stuff depending on `powerups` dispatch (see the documentation).
            localmemo!(miner, memokey, measure)
            for powerup in LOCAL_POWERUP_SYMBOLS
                # the numerical value necessary to save more informations about the relation
                # between an instance and an subject must be obtained by the internal logic
                # of the meaningfulness measure callback.
                if haspowerup(miner, powerup) && haskey(response, powerup)
                    powerups(miner, powerup)[(i_instance, subject)] = response[powerup]
                end
            end
            # Note that the powerups system could potentially irrorate the entire package
            # and could be expandend/specialized;
            # for example, a category of powerups is necessary to fill (i_instance, subject)
            # fields, other are necessary to save informations about something else.

            return measure
        end

        # export the generated function
        export $(esc(fname))
    end
end

_lsupport_logic = (itemset, instance, miner) -> begin
    X, i_instance = instance.s, instance.i_instance # dataset(miner)

    # Bool vector, representing on which world an Itemset holds
    wmask = [check(toformula(itemset), X, i_instance, w) for w in allworlds(X, i_instance)]

    # Return the result, and eventually the information needed to support powerups
    return Dict(
        :measure => count(wmask) / nworlds(X, i_instance),
        :instance_item_toworlds => wmask
    )
end

# TODO: see how to document this
# """
#     function lsupport(
#         itemset::Itemset,
#         instance::LogicalInstance;
#         miner::Union{Nothing,Miner}=nothing
#     )::Float64
#
# Compute the local support for the given `itemset` in the given `instance`.
#
# Local support is the ratio between the number of worlds in a [`LogicalInstance`](@ref) where
# and [`Itemset`](@ref) is true and the total number of worlds in the same instance.
#
# If a miner is provided, then its internal state is updated and used to leverage memoization.
#
# See also [`Miner`](@ref), [`LogicalInstance`](@ref), [`Itemset`](@ref).
# """
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
function gsupport(
    itemset::Itemset,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,Miner}=nothing,
    mymemo_on::Bool=true,
    internalmemo_on::Bool=true
)::Float64
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gsupport), itemset))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner) && mymemo_on
        memoized = globalmemo(miner, memokey)
        if !isnothing(memoized)
            return memoized
        end
    end

    # compute global measure, then divide it by the dataset total number of instances
    ans = sum([
            lsupport(itemset, getinstance(X, i_instance), miner) >= threshold
            for i_instance in 1:ninstances(X)
        ]) / ninstances(X)

    if !isnothing(miner)
        globalmemo!(miner, memokey, ans)
    end

    return ans
end

islocalof(::typeof(lsupport), ::typeof(gsupport)) = true
isglobalof(::typeof(gsupport), ::typeof(lsupport)) = true

localof(::typeof(gsupport)) = lsupport
globalof(::typeof(lsupport)) = gsupport

_lconfidence_logic = (rule, instance, miner) -> begin
    num = lsupport(convert(Itemset, rule), instance, miner)
    den = lsupport(antecedent(rule), instance, miner)

    # Return the result, and eventually the information needed to support powerups
    return Dict(:measure => num/den)
end

# TODO: remove miner keywords from lconfidence calls, since now the interface has changed
# TODO: see how to document this
# """
#     function lconfidence(
#         rule::ARule,
#         instance::LogicalInstance;
#         miner::Union{Nothing,Miner}=nothing
#     )::Float64
#
# Compute the local confidence for the given `rule` in the given `instance`.
#
# Local confidence is the ratio between [`lsupport`](@ref) of an [`ARule`](@ref) on
# a [`LogicalInstance`](@ref) and the [`lsupport`](@ref) of the [`antecedent`](@ref) of the
# same rule.
#
# If a miner is provided, then its internal state is updated and used to leverage memoization.
#
# See also [`antecedent`](@ref), [`ARule`](@ref), [`Miner`](@ref),
# [`LogicalInstance`](@ref), [`lsupport`](@ref).
# """
@lmeas lconfidence _lconfidence_logic

"""
function gconfidence(
    rule::ARule,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,Miner}=nothing
    )::Float64

    Compute the global confidence for the given `rule` on a logiset `X`, considering `threshold`
        as the threshold for the global support called internally.

            Global confidence is the ratio between [`gsupport`](@ref) of an [`ARule`](@ref) on
            a [`SupportedLogiset`](@ref) and the [`gsupport`](@ref) of the [`antecedent`](@ref) of the
            same rule.

            If a miner is provided, then its internal state is updated and used to leverage memoization.

            See also [`antecedent`](@ref), [`ARule`](@ref), [`Miner`](@ref),
            [`gsupport`](@ref), [`SupportedLogiset`](@ref).
            """
            function gconfidence(
    rule::ARule,
    X::SupportedLogiset,
    threshold::Threshold;
    miner::Union{Nothing,Miner}=nothing,
    mymemo_on::Bool=true,
    internalmemo_on::Bool=true
)::Float64
    # this is needed to access memoization structures
    memokey = GmeasMemoKey((Symbol(gconfidence), rule))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner) && internalmemo_on
        memoized = globalmemo(miner, memokey)
        if !isnothing(memoized)
            return memoized
        end
    end

    _antecedent = antecedent(rule)
    _consequent = consequent(rule)
    _union = union(_antecedent, _consequent)

    # denominator could be near to zero
    den = gsupport(_antecedent, X, threshold; miner=miner, mymemo_on=true)

    ans = 0.0
    num = 0.0
    if (den <= 100*eps())
        return 0.0 # illegal denominator
        # error("Illegal denominator when computing global confidence: (value is $(den))")
    else
        num = gsupport(_union, X, threshold; miner=miner, mymemo_on=true)
        ans = num / den
    end

    if (ans > 1.0)
        @error "Critical error: global confidence overflow on $(rule). (value is $(ans))"
    end

    if !isnothing(miner)
        globalmemo!(miner, memokey, ans)
    end

    return ans
end

islocalof(::typeof(lconfidence), ::typeof(gconfidence)) = true
isglobalof(::typeof(gconfidence), ::typeof(lconfidence)) = true

localof(::typeof(gconfidence)) = lconfidence
globalof(::typeof(lconfidence)) = gconfidence
