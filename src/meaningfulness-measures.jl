"""
    function lsupport(
        itemset::Itemset,
        logi_instance::LogicalInstance;
        miner::Union{Nothing,Miner}=nothing
    )::Float64

Compute the local support for the given `itemset` in the given `logi_instance`.

Local support is the ratio between the number of worlds in a [`LogicalInstance`](@ref) where
and [`Itemset`](@ref) is true and the total number of worlds in the same instance.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`Miner`](@ref), [`LogicalInstance`](@ref), [`Itemset`](@ref).
"""
function lsupport(
    itemset::Itemset,
    logi_instance::LogicalInstance;
    miner::Union{Nothing,Miner}=nothing,
    mymemo_on::Bool=true
)::Float64
    # retrieve logiset, and the specific instance
    X, i_instance = logi_instance.s, logi_instance.i_instance

    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lsupport), itemset, i_instance))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner) && mymemo_on
        memoized = localmemo(miner, memokey)
        if !isnothing(memoized)
            return memoized
        end
    end

    # keep track of which worlds contributes to compute local support, then compute it
    _contributors = WorldMask([
        check(toformula(itemset), X, i_instance, w)
        for w in allworlds(X, i_instance)
    ])

    ans = sum(_contributors) / nworlds(X, i_instance)

    if !isnothing(miner)
        localmemo!(miner, memokey, ans)

        # IDEA: call two methods here. One is built-in in Sole, and checks every equippable
        # attribute that `miner` can have in its info named tuple.
        # The other dispatch is empty, but customizable by the user to check his things.
        if haspowerup(miner, :instance_item_toworlds)
            powerups(miner, :instance_item_toworlds)[(i_instance, itemset)] = _contributors
        end
    end

    return ans
end

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
        lsupport(
                itemset,
                getinstance(X, i_instance);
                miner=miner,
                mymemo_on=internalmemo_on
            ) >= threshold
            for i_instance in 1:ninstances(X)]
        ) / ninstances(X)

    if !isnothing(miner)
        globalmemo!(miner, memokey, ans)
    end

    return ans
end

islocalof(::typeof(lsupport), ::typeof(gsupport)) = true
isglobalof(::typeof(gsupport), ::typeof(lsupport)) = true

localof(::typeof(gsupport)) = lsupport
globalof(::typeof(lsupport)) = gsupport

"""
    function lconfidence(
        rule::ARule,
        logi_instance::LogicalInstance;
        miner::Union{Nothing,Miner}=nothing
    )::Float64

Compute the local confidence for the given `rule` in the given `logi_instance`.

Local confidence is the ratio between [`lsupport`](@ref) of an [`ARule`](@ref) on
a [`LogicalInstance`](@ref) and the [`lsupport`](@ref) of the [`antecedent`](@ref) of the
same rule.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`antecedent`](@ref), [`ARule`](@ref), [`Miner`](@ref),
[`LogicalInstance`](@ref), [`lsupport`](@ref).
"""
function lconfidence(
    rule::ARule,
    logi_instance::LogicalInstance;
    miner::Union{Nothing,Miner}=nothing,
    mymemo_on::Bool=true,
    internalmemo_on::Bool=true
)::Float64
    # this is needed to access memoization structures
    memokey = LmeasMemoKey((Symbol(lconfidence), rule, logi_instance.i_instance))

    # leverage memoization if a miner is provided, and it already computed the measure
    if !isnothing(miner) && internalmemo_on
        memoized = localmemo(miner, memokey)
        if !isnothing(memoized)
            return memoized
        end
    end

    # denominator could be near to zero
    den = lsupport(antecedent(rule), logi_instance; miner=miner, mymemo_on=internalmemo_on)

    ans = 0.0
    if (den <= 100*eps())
        ans = 0.0 # illegal denominator
        # error("Illegal denominator when computing local confidence: (value is $(den))")
    else
        num = lsupport(
            convert(Itemset, rule), logi_instance; miner=miner, mymemo_on=internalmemo_on)
        ans = num / den
    end


    if !isnothing(miner)
        localmemo!(miner, memokey, ans)
    end

    return ans
end

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
