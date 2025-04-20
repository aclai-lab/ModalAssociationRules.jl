using Serialization

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

variables = []
propositional_atoms = []

for varid in 1:25
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

        variable = VariableDistance(varid,
            motif,
            distance=expdistance,
            featurename=_featurename
        )

        atom = Atom(
            ScalarCondition(variable, <=, __suggest_threshold(variable, X; _percentile=5)))

        push!(variables, variable)
        push!(propositional_atoms, atom)
    end
end

# remember to serialize your variables after the labelling process
# serialize("NATOPS-variables", variables)
# serialize("NATOPS-propositions", propositional_atoms)

# or load them, if you already have them
# deserialize("NATOPS-variables", <myvar>)
