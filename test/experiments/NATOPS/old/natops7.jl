using Serialization

X, y = load_NATOPS();
insertcols!(X, 25, "ΔY[Thumb r and Hand tip r]" => X[:,5]-X[:,23])

# I have command
IHCC = reduce(vcat, [X[1:30, :], X[(180+1):(180+30), :]])
# all clear
ACC = reduce(vcat, [X[31:60, :], X[(180+31):(180+60), :]])
# not clear
NCC = reduce(vcat, [X[61:90, :], X[(180+61):(180+90), :]])
# spread wings
SWC = reduce(vcat, [X[91:120, :], X[(180+91):(180+120), :]])
# fold wings
FWC = reduce(vcat, [X[121:150, :], X[(180+121):(180+150), :]])
# lock wings
LWC = reduce(vcat, [X[151:180, :], X[(180+151):(360), :]])

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
    "ΔY[Thumb r and Hand tip r]"
]

############################################################################################
# Utilities
############################################################################################

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
    for varid in vcat(collect(1:12), 25) # all hands (1-6), all elbows (7-12), thumb-up (25)

        _data = reduce(vcat, X[:,varid])
        S = snippets(_data, 4, 10; m=10)
        Slong = snippets(_data, 3, 20; m=20)


        motifs = [
            [_snippet(S,1)],
            [_snippet(S,2)],
            [_snippet(S,3)],
            [_snippet(S,4)],
            [_snippet(Slong,1)],
            [_snippet(Slong,2)],
            [_snippet(Slong,3)]
        ]

        for (i, motif) in enumerate(motifs)
            println("Plotting $(i)-th motif of class $(variablenames[varid])")
            _plot = plot()
            plot!(motif)
            display(_plot)

            _featurename = readline()

            push!(__ids, varid)
            push!(__motifs, motif)
            push!(__featurenames, _featurename)
        end
    end

    serialize("test/experiments/NATOPS/NATOPS-ids", __ids)
    serialize("test/experiments/NATOPS/NATOPS-motifs", __motifs)
    serialize("test/experiments/NATOPS/NATOPS-featurenames", __featurenames)
else
    __ids = deserialize("test/experiments/NATOPS/NATOPS-ids")
    __motifs = deserialize("test/experiments/NATOPS/NATOPS-motifs")
    __featurenames = deserialize("test/experiments/NATOPS/NATOPS-featurenames")
end

__ids = [id for id in __ids]
__motifs = [m for m in __motifs]
__featurenames = [f for f in __featurenames]


variables = [
    VariableDistance(id, m, distance=expdistance, featurename=name)
    for (id, m, name) in zip(__ids, __motifs, __featurenames)
]

propositional_atoms = [
    Atom(ScalarCondition(v, <=, __suggest_threshold(v, X; _percentile=3)))
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
