using Serialization
import Base: isequal

X, y = load_NATOPS();

# I have command
IHCC = X[1:30, :]
# all clear
ACC = X[31:60, :]
# not clear
NCC = X[61:90, :]
# spread wings
SWC = X[91:120, :]
# lock wings
FWC = X[121:150, :]
# lock wings
LWC = X[151:180, :]

variablenames = [
    "X[Hand tip l]",
    "Y[Hand tip l]",
    "Z[Hand tip l]",
    "X[Hand tip r]",
    "Y[Hand tip r]",
    "Z[Hand tip r]",
    "X[Elbow l]",
    "Y[Elbow l]",
    "Z[Elbow l]",
    "X[Elbow r]",
    "Y[Elbow r]",
    "Z[Elbow r]",
    "X[Wrist l]",
    "Y[Wrist l]",
    "Z[Wrist l]",
    "X[Wrist r]",
    "Y[Wrist r]",
    "Z[Wrist r]",
    "X[Thumb l]",
    "Y[Thumb l]",
    "Z[Thumb l]",
    "X[Thumb r]",
    "Y[Thumb r]",
    "Z[Thumb r]",
]

############################################################################################
# Utilities
############################################################################################

# extract a snippet's inner Vector from the definition in MatrixProfiles.jl
_snippet(_snippets, i) = _snippets.snippets[i].seq

# fallback to _suggest_threshold for VariableDistances
function __suggest_threshold(var::VariableDistance, data; kwargs...)
    _refs = references(var)
    _i_variable = i_variable(var)

    _ans = first.(map(
        _ref -> suggest_threshold(_ref, data[:,_i_variable]; kwargs...) , _refs)) |> minimum
    return round(_ans; digits=2)
end

############################################################################################
# Labeling Logic
# we can consider low-level features in an indipendent manner w.r.t. the class
############################################################################################

# unfortunately, these cannot be serialized/deserialized every time due to tricky
# problems with SoleData (a Base.Fix2 dispatch of isequal works with Ptr and should not be
# overloaded with an ad-hoc VariableDistance version, for the moment)
#
# variables = VariableDistance[]
# propositional_atoms = SyntaxTree[]
#
# we need to serialize/deserialize every piece singularly
__ids = []
__motifs = []
__featurenames = []

println("Do you need to manually create your literals? [Y,n]")
_ans = readline()

if _ans == "Y"
    for varid in 1:12
        S = snippets(reduce(vcat, X[:,varid]), 5, 10; m=10)

        motifs = [
            [_snippet(S,1)],
            [_snippet(S,2)],
            [_snippet(S,3)],
            [_snippet(S,4)],
            [_snippet(S,5)]
        ]

        for (i, motif) in enumerate(motifs)
            println("Plotting $(i)-th motif of class $(variablenames[varid])")
            _plot = plot()
            plot!(motif)
            display(_plot)

            _featurename = readline()

            # OLD
            # variable = VariableDistance(varid,
            # motif,
            # distance=expdistance,
            # featurename=_featurename
            # )
            #
            # atom = Atom(
            #     ScalarCondition(variable, <, __suggest_threshold(variable, X; _percentile=10)))

            # push!(variables, variable)
            # push!(propositional_atoms, atom)

            push!(__ids, varid)
            push!(__motifs, motif)
            push!(__featurenames, _featurename)
        end
    end
    # remember to serialize your variables after the labelling process
    # serialize("test/experiments/NATOPS/NATOPS-variables", variables)
    # serialize("test/experiments/NATOPS/NATOPS-propositions2", propositional_atoms)

    serialize("test/experiments/NATOPS/NATOPS-ids", __ids)
    serialize("test/experiments/NATOPS/NATOPS-motifs", __motifs)
    serialize("test/experiments/NATOPS/NATOPS-featurenames", __featurenames)
else
    # OLD
    # or load them, if you already have them
    # variables = deserialize("test/experiments/NATOPS/NATOPS-variables")
    # propositional_atoms = deserialize("test/experiments/NATOPS/NATOPS-propositions")

    __ids = deserialize("test/experiments/NATOPS/NATOPS-ids")
    __motifs = deserialize("test/experiments/NATOPS/NATOPS-motifs")
    __featurenames = deserialize("test/experiments/NATOPS/NATOPS-featurenames")
end

# OLD
# convert to exact types
# variables = [v for v in variables]
# propositional_atoms = [p for p in propositional_atoms]

__ids = [id for id in __ids]
__motifs = [m for m in __motifs]
__featurenames = [f for f in __featurenames]


variables = [
    VariableDistance(id, m, distance=expdistance, featurename=name)
    for (id, m, name) in zip(__ids, __motifs, __featurenames)
]

propositional_atoms = [
    Atom(ScalarCondition(v, <=, __suggest_threshold(v, X; _percentile=10)))
    for v in variables
]

_atoms = reduce(vcat, [
    propositional_atoms,
    diamond(IA_A).(propositional_atoms),
    diamond(IA_B).(propositional_atoms),
    diamond(IA_E).(propositional_atoms),
])

_items = Vector{Item}(_atoms)

_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [
    (gconfidence, 0.1, 0.1),
    (glift, 0.0, 0.0),
    (dimensional_glift, 0.0, 0.0)
]

# WARNING: for some reason, after deserializing anything, isequal is not working properly;
# see SoleData, dimensional-structures/logiset.jl
# around "i_feature = _findfirst(isequal(feature), features(X))"
#
# this is so dangerous...
# function isequal(a::VariableDistance, b::VariableDistance)
#
#     println("Comparing: $(a) vs $(b)")
#
#     i_variable(a) == i_variable(b) && featurename(a) == featurename(b)
# end
# isequal(a::VariableDistance) = Base.Fix2(isequal, a)
