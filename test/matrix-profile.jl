using Test

using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Statistics

using SoleData

X, _ = load_NATOPS();

# right hand y axis
var_id = 5

# right hand in "I have command class"
IHCC = Vector{Float32}.(X[1:30, var_id])

# parameters for matrix profile generation
windowlength = 20
nmotifs = 10
r = 5   # how similar two windows must be to belong to the same motif
th = 0  # how nearby in time two motifs are allowed to be

_motifs = motifsalphabet(IHCC, windowlength, nmotifs; r=r, th=th)
@test length(_motifs) == 3
# plot(_motifs) # uncomment to explore _motifs content

# we isolated the only var_id 5 from the class "I have command",
# thus we now have only one column/var_id;
# for simplicity, let's consider also just one motif.
_mydistance = (x, y) -> size(x) == size(y) ?
    sqrt(sum([(x - y)^2 for (x, y) in zip(x,y)])) :
    maxintfloat()

vd1 = VariableDistance(
    var_id,
    _motifs[1],
    distance=x -> _mydistance(x, _motifs[1]),
    featurename="DescendingYArm"
)

vd2 = VariableDistance(
    var_id,
    _motifs[3],
    distance=x -> _mydistance(x, _motifs[3]),
    featurename="AscendingYArm"
)

# make proposition (we consider this as we entire alphabet, at the moment)
proposition1 = Atom(ScalarCondition(vd1, <, 5.0))
proposition2 = Atom(ScalarCondition(vd2, <, 5.0))

# those atoms will label possibly every world; they are agnostic of their size;
# we introduce those to test whether `isdimensionally_coherent_itemset` filter policy
# is working later.
vm1, vm2 = VariableMin(1), VariableMin(2)
p = Atom(ScalarCondition(vm1, <, 999.0))
q = Atom(ScalarCondition(vm2, <, 999.0))

_items = Vector{Item}([proposition1, proposition2, p, q])

# define meaningfulness measures
_itemsetmeasures = [(gsupport, 0.001, 0.001)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

# build the logiset we will mine
logiset = scalarlogiset(X[1:30,:], [vd1, vd2, vm1, vm2])

# build the miner, and mine!
fpgrowth_miner = Miner(
    logiset,
    fpgrowth,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=[isdimensionally_coherent_itemset()]
)

@test_nowarn mine!(fpgrowth_miner)
# @test freqitems(fpgrowth_miner) |> length == 0
