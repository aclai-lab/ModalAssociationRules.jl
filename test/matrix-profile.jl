using Test

using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Statistics

using SoleData

X, _ = load_NATOPS();

# right hand y axis
variable = 5 

# right hand in "I have command class"
IHCC = Vector{Float32}.(X[1:30, variable]) 

# the logiset we will mine
logiset = scalarlogiset(X[1:30,:])

# parameters for matrix profile generation 
windowlength = 20 
nmotifs = 10 
r = 5   # how similar two windows must be to belong to the same motif
th = 0  # how nearby in time two motifs are allowed to be

_motifs = motifsalphabet(IHCC, windowlength, nmotifs; r=r, th=th)
@test length(_motifs) == 3
# plot(_motifs)

# we isolated the only variable 5 from the class "I have command",
# thus we now have only one column/variable;
# for simplicity, let's consider also just one motif.
motif1 = _motifs[1]
vd1 = VariableDistance(1, motif1) # 1 because we only have 1 column/variable

# make a proposition
prop1 = Atom(ScalarCondition(vd1, <, 0.2))

_1_items = Vector{Item}([prop1])

_1_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_1_rulemeasures = [(gconfidence, 0.2, 0.2)]

fpgrowth_miner = Miner(logiset, fpgrowth, _1_items, _1_itemsetmeasures, _1_rulemeasures)


# julia> check(prop1, SoleLogics.getinstance(logiset, 1), Interval((1.0, 2.0)) )
