"""
If an [`AbstractMiner`](@ref)'s [`miningstate`](@ref) contains one of these fields,
then it is filled when computing any local meaningfulness measure created using
[`@localmeasure`](@ref) macro.

See also [`AbstractMiner`](@ref), [`@localmeasure`](@ref), [`miningstate`](@ref).
"""
LOCAL_MINING_STATES = [
    :instance_item_toworlds
]

"""
If an [`AbstractMiner`](@ref)'s [`miningstate`](@ref) contains one of these fields,
then it is filled when computing any local meaningfulness measure created using
[`globalmeasure`](@ref) macro.

See also [`AbstractMiner`](@ref), [`@globalmeasure`](@ref), [`miningstate`](@ref).
"""
GLOBAL_MINING_STATES = []

"""
    macro localmeasure(measname, measlogic)

Build a generic local meaningfulness measure, levering the optimizations provided by any
[`AbstractMiner`](@ref).

# Arguments

- `measname`: the name of the local measure you are defining (e.g., lsupport);
- `measlogic`: a lambda function whose arguments are (itemset, data, ith_instance, miner) -
see the note below to know more about this.

!!! note
    When defining a new local measure, you only need to write its essential logic through
    a lambda function (itemset, X, ith_instance, miner).

    In particular, `itemset` is an [`Itemset`](@ref), `X` is a reference to the dataset,
    `ith_instance` is an integer defining on which instance you want to compute the measure,
    and `miner` is the [`AbstractMiner`](@ref) in which you want to save the measure.

    Also, `miner` argument can be used to leverage its [`miningstate`](@ref) structure.
    A complete example of the logic behind local support is shown below:

    ```julia
    _lsupport_logic = (itemset, X, ith_instance, miner) -> begin
        # vector representing on which world an Itemset holds
        wmask = [
            check(formula(itemset), X, ith_instance, w) for w in allworlds(X, ith_instance)]

        # return the result enriched with more informations, that will eventually will be
        # used if miner's miningstate has specific fields (e.g., :instance_item_toworlds).
        return Dict(
            :measure => count(wmask) / length(wmask),
            :instance_item_toworlds => wmask,
        )
    end
    ```

See also [`AbstractMiner`](@ref), [`hasminingstate`](@ref), [`lsupport`](@ref),
[`miningstate`](@ref).
"""
macro localmeasure(measname, measlogic)
    fname = Symbol(measname)

    quote
        # wrap the given `measlogic` to leverage memoization and document it
        Core.@__doc__ function $(esc(fname))(
            subject::ARMSubject,
            instance::LogicalInstance,
            miner::AbstractMiner
        )
            # retrieve logiset and the specific instance
            X, ith_instance = instance.s, instance.i_instance

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
            # do more stuff depending on `miningstate` dispatch (see the documentation).
            localmemo!(miner, memokey, measure)

            for state in LOCAL_MINING_STATES
                # the numerical value to save more informations about the relation
                # between an instance and a subject must be obtained by the internal logic
                # of the meaningfulness measure callback.
                if hasminingstate(miner, state) && haskey(response, state)
                    miningstate!(miner, state, (ith_instance,subject), response[state])
                end
            end

            # Note that the miningstate system could potentially irrorate the entire package
            # and could be expandend/specialized;
            # e.g., a category of miningstate is necessary to fill (ith_instance,subject)
            # fields, other are necessary to save informations about something else.

            return measure
        end

        # export the generated function
        export $(esc(fname))
    end
end

"""
    macro globalmeasure(measname, measlogic)

Build a generic global meaningfulness measure, levering the optimizations provided by any
[`AbstractMiner`](@ref).

# Arguments

- `measname`: the name of the global measure you are defining (e.g., gsupport);
- `measlogic`: a lambda function whose arguments are (rule, X, threshold, miner) - see the
note below to know more about this.

!!! note
    When defining a new global measure, you only need to write its essential logic through
    a lambda function (itemset, X, ith_instance, miner).

    In particular, `itemset` is an [`Itemset`](@ref), `X` is a reference to the dataset
    and `miner` is the [`AbstractMiner`](@ref) in which you want to save the measure.

    Also, `miner` argument can be used to leverage its [`miningstate`](@ref) structure.
    A complete example of the logic behind global support is shown below:

    ```julia
    _gsupport_logic = (itemset, X, threshold, miner) -> begin
        _measure = sum([
            lsupport(itemset, getinstance(X, ith_instance), miner) >= threshold
            for ith_instance in 1:ninstances(X)
        ]) / ninstances(X)

        # at the moment, no `miningstate` fields in miner are leveraged
        return Dict(:measure => _measure)
    end
    ```

See also [`AbstractMiner`](@ref), [`hasminingstate`](@ref), [`gsupport`](@ref),
[`miningstate`](@ref).
"""
macro globalmeasure(measname, measlogic)
    fname = Symbol(measname)

    quote
        # wrap the given `measlogic` to leverage memoization
        Core.@__doc__ function $(esc(fname))(
            subject::ARMSubject,
            X::SupportedLogiset,
            threshold::Threshold,
            miner::AbstractMiner
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
            # do more stuff depending on `miningstate` dispatch (see the documentation).
            # to know more, see `localmeasure` comments.
            globalmemo!(miner, memokey, measure)

            # TODO - enable when an application is found
            # for state in GLOBAL_MINING_STATES
            #     if hasminingstate(miner, state) && haskey(response, state)
            #         miningstate!(miner, state, (subject), response[state])
            #     end
            # end

            return measure
        end

        # export the generated function
        export $(esc(fname))
    end
end

"""
    macro linkmeas(gmeasname, lmeasname)

Link together two [`MeaningfulnessMeasure`](@ref), automatically defining
[`globalof`](@ref)/[`localof`](@ref) and [`isglobalof`](@ref)/[`islocalof`](@ref) traits.

See also [`globalof`](@ref), [`isglobalof`](@ref), [`islocalof`](@ref), [`localof`](@ref),
[`MeaningfulnessMeasure`](@ref).
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



# measures implementation

# core logic of `lsupport`, as a lambda function
_lsupport_logic = (itemset, X, ith_instance, miner) -> begin
    wmask = WorldMask([
        # for each world, compute on which worlds the model checking algorithm returns true
        check(formula(itemset), X, ith_instance, w)

        # NOTE: the `worldfilter` wrapped within `miner` is levereaged, if given
        for w in allworlds(miner; ith_instance=ith_instance)
    ])

    # return the result, and eventually the information needed to support miningstate
    return Dict(
        :measure => count(wmask) / length(wmask),
        :instance_item_toworlds => wmask,
    )
end

# core logic of `gsupport`, as a lambda function
_gsupport_logic = (itemset, X, threshold, miner) -> begin
    _measure = sum([
        # for each instance, compute how many times the local support overpass the threshold
        lsupport(itemset, getinstance(X, ith_instance), miner) >= threshold

        # NOTE: an instance filter could be provided by the user to avoid iterating
        # every instance, depending on the needings.
        for ith_instance in 1:ninstances(X)
    ]) / ninstances(X)

    return Dict(:measure => _measure)
end


# core logic of `lsupport`
_dimensionalwise_lsupport_logic = (itemset, X, ith_instance, miner) -> begin
    # this method assumes that the mining is taking place on geometric type worlds,
    # such as Intervals or Interval2Ds, but not OneWorld!
    # also, it is assumed that `isdimensionally_coherent_itemset` policy is being applied.

    # we need to establish on which worlds the itemset can be evaluated;
    # e.g.1, [min(V1)>0.5, max(V2)<0.2] can be evaluated on any world.
    # e.g.2, [dist(V1,motif1)<4.3, <D>dist(V2,motif2)<3.0] can be evaluated only in
    # worlds w such that size(w) == size(motif1), (first item is a propositional anchor).

    # because of isdimensionally_coherent_itemset, we know the itemset is well-formed;
    # we just need to find the size of the structure wrapped within any anchor item.
    _features = feature.(itemset)
    _anchor_feature_idx = findfirst(
        # it must be dimensionally constraind
        _item -> _item |> feature |> typeof <: VariableDistance &&
        # it must be an anchor (propositional, without modalities like in SyntaxTree case)
        _item |> formula |> typeof <: Atom,
        itemset
    )

    # if no feature introduces a dimensional constraint, then just fallback to lsupport
    if isnothing(_anchor_feature_idx)
        return _lsupport_logic(itemset, X, ith_instance, miner)
    end

    _repr = _features[_anchor_feature_idx]
    _repr_size = _repr |> refsize

    # TODO: implement this for various GeometricalWorld types in SoleLogics
    # see https://github.com/aclai-lab/SoleLogics.jl/issues/68
    function _worldsize(w::Interval{T}) where T
        return (w.y - w.x,)
    end

    _fairworlds = Ref(0) # keeps track of the number of worlds in which itemset can be true
    wmask = WorldMask([
        _worldsize(w) == _repr_size ?
            (_fairworlds[] += 1; check(formula(itemset), X, ith_instance, w)) : 0

        for w in allworlds(miner; ith_instance=ith_instance)
    ])

    # return the result, and eventually the information needed to support miningstate
    return Dict(
        :measure => count(wmask) / _fairworlds[],
        :instance_item_toworlds => wmask,
    )
end

# core logic of `gsupport`
_dimensionalwise_gsupport_logic = (itemset, X, threshold, miner) -> begin
    _measure = sum([
        # for each instance, compute how many times the local support overpass the threshold
        lsupport(itemset, getinstance(X, ith_instance), miner) >= threshold

        # NOTE: an instance filter could be provided by the user to avoid iterating
        # every instance, depending on the needings.
        for ith_instance in 1:ninstances(X)
    ]) / ninstances(X)

    return Dict(:measure => _measure)
end



_lconfidence_logic = (rule, X, ith_instance, miner) -> begin
    _instance = getinstance(X, ith_instance)
    num = lsupport(convert(Itemset, rule), _instance, miner)
    den = lsupport(antecedent(rule), _instance, miner)

    return Dict(:measure => num/den)
end

_gconfidence_logic = (rule, X, threshold, miner) -> begin
    _antecedent = antecedent(rule)
    _consequent = consequent(rule)
    _union = union(_antecedent, _consequent)

    num = gsupport(_union, X, threshold, miner)
    den = gsupport(_antecedent, X, threshold, miner)

    @assert den >= num "ERROR: conf between $(_union) [$(num)] and $(_antecedent) [$(den)]"

    return Dict(:measure => num/den)
end

_dimensionalwise_lconfidence_logic = (rule, X, ith_instance, miner) -> begin
    # this is just a placeholder definition to guarantee no problems with @linkmeas
    # later; TODO: remove this (also, local confidence does not seem to be "useful")
    return _lconfidence_logic(rule, X, ith_instance, miner)
end

_dimensionalwise_gconfidence_logic = (rule, X, threshold, miner) -> begin
    _antecedent = antecedent(rule)
    _consequent = consequent(rule)
    _union = union(_antecedent, _consequent)

    num = gsupport(_union, X, threshold, miner)
    den = gsupport(_antecedent, X, threshold, miner)

    @assert den >= num "ERROR: conf between $(_union) [$(num)] and $(_antecedent) [$(den)]"

    return Dict(:measure => num/den)
end



_llift_logic = (rule, X, ith_instance, miner) -> begin
    num = lconfidence(rule, X, ith_instance, miner)
    den = lsupport(consequent(rule), getinstance(X, ith_instance), miner)

    return Dict(:measure => num/den)
end

_glift_logic = (rule, X, threshold, miner) -> begin
    num = gconfidence(rule, X, threshold, miner)
    den = gsupport(consequent(rule), X, threshold, miner)

    # TODO - think about this claim:
    # when the rule's consequent is anchored, this definition is ok;
    # when it is not, then lift should be computed as:
    # P(X U Y) / (P(X) * P(bar(Y)UX)) or something similar.

    return Dict(:measure => num/den)
end

_dimensionalwise_glift_logic = (rule, X, threshold, miner) -> begin
    # given rule ::= X => Y, wa want to compute
    # P(XUY) / (P(X) * P(inv(Y))) = confidence(X => Y) / P(inv(Y))

    num = gconfidence(rule, X, threshold, miner)

    _consequent = consequent(rule)

    # if Y is a standard, propositional literal (i.e., it is not a temporal one),
    # then this definition is the same as standard lift and we can go on.
    if isa(_consequent, SoleLogics.SyntaxBranch)
        # let us say we have a consequent c that is: <Relation>FeatName[Var] < Threshold;
        # we can see the formula as a tree, whose root is <Relation>.
        # here, we first separate the relation from the body (its children),
        # then we find the converse of the relation (synonym for inverse) and we reassembly
        # the initial literal.
        _tok, _child = SoleLogics.token(_consequent), SoleLogics.children(_consequent)
        invrelation = _tok |> SoleLogics.relation |> SoleLogics.converse
        _consequent = invrelation(_child)
    end

    den = gsupport(_consequent, X, threshold, miner)

    return Dict(:measure => num/den)
end


_lconviction_logic = (rule, X, ith_instance, miner) -> begin
    _instance = getinstance(X, ith_instance)

    num = 1 - lsupport(consequent(rule), X, _instance, miner)
    den = 1 - lconfidence(rule, X, _instance, miner)

    return Dict(:measure => num/den)
end

_gconviction_logic = (rule, X, threshold, miner) -> begin
    num = 1 - gsupport(consequent(rule), X, threshold, miner)
    den = 1 - gconfidence(rule, X, threshold, miner)

    return Dict(:measure => num/den)
end



_lleverage_logic = (rule, X, ith_instance, miner) -> begin
    _instance = getinstance(X, ith_instance)

    _ans = lsupport(convert(Itemset, rule), X, _instance, miner) - \
        lsupport(antecedent(rule), X, _instance, miner) * \
        lsupport(consequent(rule), X, _instance, miner)

    return Dict(:measure => _ans)
end

_gleverage_logic = (rule, X, threshold, miner) -> begin
    _ans = gsupport(convert(Itemset, rule), X, threshold, miner) -
        gsupport(antecedent(rule), X, threshold, miner) *
        gsupport(consequent(rule), X, threshold, miner)

    return Dict(:measure => _ans)
end



_lchisquared_logic = (rule, X, ith_instance, miner) -> begin
    # TODO - this might be broken

    N = ninstances(X)
    _instance = getinstance(X, ith_instance)

    a1 = antecedent(rule)
    a2 = NEGATION(a1 |> formula) |> Itemset

    c1 = consequent(rule)
    c2 = NEGATION(b1 |> formula) |> Itemset

    _ans = N * sum((R) -> lleverage(ARule(first(R),last(R)), X, _instance, miner)^2 /
        (lsupport(first(R), X, _instance, miner) * lsupport(last(R), X, _instance, miner)),
        IterTools.product([a1, a2], [c1, c2])
    )

    return Dict(:measure => _ans)
end

_gchisquared_logic = (rule, X, threshold, miner) -> begin
    # TODO - this might be broken

    N = ninstances(X)

    a1 = antecedent(rule)
    a2 = NEGATION(a1 |> formula) |> Itemset

    c1 = consequent(rule)
    c2 = NEGATION(c1 |> formula) |> Itemset

    _ans = N * sum((R) -> gleverage(ARule(first(R),last(R)), X, threshold, miner)^2 /
        (gsupport(first(R), X, threshold, miner) * gsupport(last(R), X, threshold, miner)),
        IterTools.product([a1, a2], [c1, c2]) |> collect |> vec
    )

    return Dict(:measure => _ans)
end

# measures definition

"""
    function lsupport(
        itemset::Itemset,
        instance::LogicalInstance;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the local support for the given `itemset` in the given `instance`.

Local support is the ratio between the number of worlds in a [`LogicalInstance`](@ref) where
and [`Itemset`](@ref) is true and the total number of worlds in the same instance.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`Miner`](@ref), [`LogicalInstance`](@ref), [`Itemset`](@ref), [`Threshold`](@ref).
"""
@localmeasure __lsupport _lsupport_logic

"""
    function gsupport(
        itemset::Itemset,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
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
@globalmeasure __gsupport _gsupport_logic


"""
    function lsupport(
        itemset::Itemset,
        instance::LogicalInstance;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the local support for the given `itemset` in the given `instance`.

Local support is the ratio between the number of worlds in a [`LogicalInstance`](@ref) where
and [`Itemset`](@ref) is true and the total number of worlds where the [`Itemset`](@ref)
can be [`check`](@ref)ed.

See also `SoleLogics.check`, [`Miner`](@ref), [`gsupport`](@ref), [`LogicalInstance`](@ref),
[`Itemset`](@ref), [`Threshold`](@ref).
"""
@localmeasure lsupport _dimensionalwise_lsupport_logic

"""
    function gsupport(
        itemset::Itemset,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the global support for the given `itemset` on a logiset `X`, considering `threshold`
as the threshold for the local support called internally.

Global support is the ratio between the number of [`LogicalInstance`](@ref)s in a
[`SupportedLogiset`](@ref) for which the local support, [`lsupport`](@ref), is greater than
a [`Threshold`](@ref), and the total number of instances in the same logiset.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`Miner`](@ref), [`lsupport`](@ref), [`LogicalInstance`](@ref),
[`Itemset`](@ref), [`SupportedLogiset`](@ref), [`Threshold`](@ref).
"""
@globalmeasure gsupport _dimensionalwise_gsupport_logic


"""
    function lconfidence(
        rule::ARule,
        ith_instance::LogicalInstance;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the local confidence for the given `rule`.

Local confidence is the ratio between [`lsupport`](@ref) of an [`ARule`](@ref) on a
[`LogicalInstance`](@ref) and the [`lsupport`](@ref) of the [`antecedent`](@ref) of the
same rule.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref),
[`LogicalInstance`](@ref), [`lsupport`](@ref), [`Threshold`](@ref).
"""
@localmeasure lconfidence _dimensionalwise_lconfidence_logic

"""
    function gconfidence(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the global confidence for the given `rule` on a logiset `X`, considering
`threshold` as the threshold for the global support called internally.

Global confidence is the ratio between [`gsupport`](@ref) of an [`ARule`](@ref) on
a [`SupportedLogiset`](@ref) and the [`gsupport`](@ref) of the only [`antecedent`](@ref) of
the same rule.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`antecedent`](@ref), [`ARule`](@ref), [`AbstractMiner`](@ref), [`gsupport`](@ref),
[`SupportedLogiset`](@ref).
"""
@globalmeasure gconfidence _dimensionalwise_gconfidence_logic


"""
    function llift(
        rule::ARule,
        ith_instance::LogicalInstance;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the local lift for the given `rule`.

Local lift measures how far from independence are `rule`'s [`antecedent`](@ref) and
[`consequent`](@ref) on a modal logic instance.

Given an [`ARule`](@ref) `X ⇒ Y`, if local lift value is around 1, then this means that
`P(X ⋃ Y) = P(X)P(Y)`, and hence, the two [`Itemset`](@ref)s `X` and `Y` are independant.
If value is greater than (lower than) 1, then this means that `X` and `Y` are dependant
and positively (negatively) correlated [`Itemset`](@ref)s.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref), [`glift`](@ref),
[`LogicalInstance`](@ref), [`llift`](@ref), [`Threshold`](@ref).
"""
@localmeasure llift _llift_logic

"""
    function glift(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

See also [`llift`](@ref).
"""
@globalmeasure glift _glift_logic

# TODO - remove this as gives the same result as classic lift
@globalmeasure dimensional_glift _dimensionalwise_glift_logic



"""
    function lconviction(
        rule::ARule,
        ith_instance::LogicalInstance;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the local conviction for the given `rule`.

Conviction attempts to measure the degree of implication of a rule.
It's value ranges from 0 to +∞.
Unlike lift, conviction is sensitive to rule direction; like lift, values far from 1
indicate interesting rules.

If a miner is provided, then its internal state is updated and used to leverage memoization.

See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref),
[`LogicalInstance`](@ref), [`llift`](@ref), [`Threshold`](@ref).
"""
@localmeasure lconviction _lconviction_logic

"""
    function gconviction(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

See also [`lconviction`](@ref).
"""
@globalmeasure gconviction _gconviction_logic



"""
    function lleverage(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

Compute the local leverage for the given `rule`.

Measures how much more counting is obtained from the co-occurrence of the
[`antecedent`](@ref) and [`consequent`](@ref) from the expected (from independence).

This value ranges between [-0.25,0.25].

See also [`AbstractMiner`](@ref), [`antecedent`](@ref), [`ARule`](@ref),
[`consequent`](@ref), [`LogicalInstance`](@ref), [`Threshold`](@ref).
"""
@localmeasure lleverage _lleverage_logic

"""
    function gleverage(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

See also [`lleverage`](@ref).
"""
@globalmeasure gleverage _gleverage_logic



"""
    function lchisquared(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

𝛸²-test for a `rule`, in the local setting (within a modal instance).

This test assists in deciding about the independence of these items which suggests that the
measure is not feasible for ranking purposes.

[`AbstractMiner`](@ref), [`Threshold`](@ref).
"""
@localmeasure lchisquared _lchisquared_logic

"""
    function gchisquared(
        rule::ARule,
        X::SupportedLogiset,
        threshold::Threshold;
        miner::Union{Nothing,AbstractMiner}=nothing
    )::Float64

See also [`lchisquared`](@ref).
"""
@globalmeasure gchisquared _gchisquared_logic



# all the meaningfulness measures defined in this file are linked here,
# meaning that a global measure is associated to its corresponding local one.

@linkmeas gsupport lsupport

@linkmeas gconfidence lconfidence

@linkmeas glift llift

@linkmeas gconviction lconviction

@linkmeas gleverage lleverage

@linkmeas gchisquared lchisquared
