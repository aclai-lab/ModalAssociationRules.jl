# README
# I replaced all the `SyntaxTree` appearing in @albe's implementation, with 
# the more general type `Formula`, since this package often deals with 
# `LeftmostConjunctiveForm`, which is a subtype of `Formula` 
# (and brother of `SyntaxTree`).
#
# `AbstractKripkeStructure` replaced with `AbstractLogiset`

"""
Shallow structure for forcing a new dispatch of the SoleLogics' model checker.
"""
struct LazyCheckAlgorithm <: SoleLogics.CheckAlgorithm end

# TODO: make this adapter;
# check(::ModalAssociationRules.LazyCheckAlgorithm, ::LeftmostConjunctiveForm{…}, ::SupportedLogiset{…}, ::Int64, ::Interval{…})

function check(
    ::LazyCheckAlgorithm,
    φ::LeftmostConjunctiveForm,
    i::AbstractLogiset,
    w::Union{Nothing,AnyWorld,<:AbstractWorld}=nothing;
    use_memo::Union{Nothing,AbstractDict{<:Formula,<:Vector{<:Int}}}=nothing,
)::Bool end

"""
Optimization of the default model checking procedure provided by SoleLogics.
"""
function check(
    ::LazyCheckAlgorithm,
    φ::LeftmostConjunctiveForm,
    i::AbstractLogiset,
    w::Union{Nothing,AnyWorld,<:AbstractWorld}=nothing;
    use_memo::Union{Nothing,AbstractDict{<:Formula,<:Vector{<:Int}}}=nothing,
)::Bool
    function _hasformula(
        memo_structure::AbstractDict{<:Formula,<:Vector{<:Int}}, φ::Formula
    )
        return haskey(memo_structure, tree(φ))
    end

    function _readformula(
        memo_structure::AbstractDict{<:Formula,<:Vector{<:Int}}, φ::Formula
    )
        return memo_structure[tree(φ)]
    end

    function _initformula!(
        memo_structure::AbstractDict{<:Formula,<:Vector{<:Int}}, φ::Formula, nworlds::Int
    )
        return memo_structure[tree(φ)] = ones(Int, nworlds) .* -1
    end

    function _setformula!(
        memo_structure::AbstractDict{<:Formula,<:Vector{<:Int}}, φ::Formula, w, val
    )
        return memo_structure[tree(φ)][w.name] = val
    end

    function _check(
        φ::LeftmostConjunctiveForm,
        i::AbstractLogiset,
        w::AbstractWorld,
        memo::AbstractDict{<:Formula,<:Vector{<:Int}},
    )
        if φ isa SyntaxLeaf
            _setformula!(memo, φ, w, istop(interpret(φ, i, w)))
        elseif token(φ) isa NamedConnective{:¬}
            φ1 = φ.children[1]
            if !_hasformula(memo, φ1)
                _initformula!(memo, φ1, nworlds(i))
            end
            if _readformula(memo, φ1)[w.name] == -1
                _check(φ1, i, w, memo)
            end
            if _readformula(memo, φ1)[w.name] == 1
                _setformula!(memo, φ, w, 0)
            else
                _setformula!(memo, φ, w, 1)
            end
        elseif token(φ) isa NamedConnective{:∨}
            φ1, φ2 = φ.children
            if !_hasformula(memo, φ1)
                _initformula!(memo, φ1, nworlds(i))
            end
            if _readformula(memo, φ1)[w.name] == -1
                _check(φ1, i, w, memo)
            end
            if _readformula(memo, φ1)[w.name] == 1
                _setformula!(memo, φ, w, 1)
            else
                if !_hasformula(memo, φ2)
                    _initformula!(memo, φ2, nworlds(i))
                end
                if _readformula(memo, φ2)[w.name] == -1
                    _check(φ2, i, w, memo)
                end
                _setformula!(memo, φ, w, _readformula(memo, φ2)[w.name])
            end
        elseif token(φ) isa NamedConnective{:∧}
            φ1, φ2 = φ.children
            if !_hasformula(memo, φ1)
                _initformula!(memo, φ1, nworlds(i))
            end
            if _readformula(memo, φ1)[w.name] == -1
                _check(φ1, i, w, memo)
            end
            if _readformula(memo, φ1)[w.name] == 0
                _setformula!(memo, φ, w, 0)
            else
                if !_hasformula(memo, φ2)
                    _initformula!(memo, φ2, nworlds(i))
                end
                if _readformula(memo, φ2)[w.name] == -1
                    _check(φ2, i, w, memo)
                end
                _setformula!(memo, φ, w, _readformula(memo, φ2)[w.name])
            end
        elseif token(φ) isa NamedConnective{:→}
            φ1, φ2 = φ.children
            if !_hasformula(memo, φ1)
                _initformula!(memo, φ1, nworlds(i))
            end
            if _readformula(memo, φ1)[w.name] == -1
                _check(φ1, i, w, memo)
            end
            if _readformula(memo, φ1)[w.name] == 0
                _setformula!(memo, φ, w, 1)
            else
                if !_hasformula(memo, φ2)
                    _initformula!(memo, φ2, nworlds(i))
                end
                if _readformula(memo, φ2)[w.name] == -1
                    _check(φ2, i, w, memo)
                end
                _setformula!(memo, φ, w, _readformula(memo, φ2)[w.name])
            end
        elseif token(φ) isa NamedConnective{:◊}
            φ1 = φ.children[1]
            if !_hasformula(memo, φ1)
                _initformula!(memo, φ1, nworlds(i))
            end
            for wi in accessibles(i, w)
                if _readformula(memo, φ1)[wi.name] == -1
                    _check(φ1, i, wi, memo)
                end
                if _readformula(memo, φ1)[wi.name] == 1
                    _setformula!(memo, φ, w, 1)
                    break
                end
            end
            if _readformula(memo, φ)[w.name] == -1
                _setformula!(memo, φ, w, 0)
            end
        elseif token(φ) isa NamedConnective{:□}
            φ1 = φ.children[1]
            if !_hasformula(memo, φ1)
                _initformula!(memo, φ1, nworlds(i))
            end
            for wi in accessibles(i, w)
                if _readformula(memo, φ1)[wi.name] == -1
                    _check(φ1, i, wi, memo)
                end
                if _readformula(memo, φ1)[wi.name] == 0
                    _setformula!(memo, φ, w, 0)
                    break
                end
            end
            if _readformula(memo, φ)[w.name] == -1
                _setformula!(memo, φ, w, 1)
            end
        end
    end

    if isnothing(w)
        if !isgrounded(φ)
            error(
                "Please, specify a world in order to check non-grounded " *
                "formula: $(syntaxstring(φ)).",
            )
        end
        if nworlds(i) == 1
            w = first(allworlds(i))
        end
    end

    memo = begin
        if isnothing(use_memo)
            ThreadSafeDict{LeftmostConjunctiveForm,Vector{Int}}()
        else
            use_memo
        end
    end

    if !_hasformula(memo, φ)
        _initformula!(memo, φ, nworlds(i))
    end

    if w isa AnyWorld
        for wi in allworlds(i)
            if _readformula(memo, φ)[wi.name] == -1
                _check(φ, i, w, memo)
            end
            if _readformula(memo, φ)[wi.name] == 1
                return true
            end
        end
        return false
    end

    if _readformula(memo, φ)[w.name] == -1
        _check(φ, i, w, memo)
    end
    if _readformula(memo, φ)[w.name] == 1
        return true
    elseif _readformula(memo, φ)[w.name] == 0
        return false
    end
end
