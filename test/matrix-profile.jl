using Test

using MatrixProfile
using ModalAssociationRules
using Plots
using Plots.Measures
using Random

using SoleData

X, _ = load_NATOPS();

# right hand y axis
var_id = 5

# right hand in "I have command class"
IHCC_rhand_y_only = Vector{Float32}.(X[1:30, var_id])

# parameters for matrix profile generation
windowlength = 20
nmotifs = 10
_seed = 3498
r = 5   # how similar two windows must be to belong to the same motif
th = 0  # how nearby in time two motifs are allowed to be

_motifs = motifsalphabet(IHCC_rhand_y_only, windowlength, nmotifs; rng=_seed, r=r, th=th)
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
_itemsetmeasures = [(dimensional_gsupport, 0.001, 0.001)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]

# build the logiset we will mine
logiset = scalarlogiset(X[1:30,:], [vd1, vd2, vm1, vm2])

# build the miner, and mine!
apriori_miner = Miner(
    logiset,
    apriori,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=[isdimensionally_coherent_itemset()]
)

@test_nowarn mine!(apriori_miner)
@test freqitems(apriori_miner) |> length == 5

############################################################################################

# now we want to test a more general setting, in which multiple variables are considered
# as well as multiple motif lengths.

# isolate "I have command class"
IHCC = X[1:30, :]

# right hand X variable generations

# remember: motifsalphabet(data, windowlength, #extractions)
_motifs_v5_l10 = motifsalphabet(IHCC[:,4], 10, 10; rng=_seed, r=30, th=0)
__motif__v5_l10_rhand_x_leaning_forward = _motifs_v4_l10[1]
__motif__v4_l10_rhand_x_inverting_direction = _motifs_v4_l10[2]
__motif__v4_l10_rhand_x_protracting = _motifs_v4_l10[3]

__var__v4_l10_rhand_x_leaning_forward = VariableDistance(4,
    __motif__v4_l10_rhand_x_leaning_forward,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_leaning_forward),
    featurename="LeaningForward"
)
__var__v4_l10_rhand_x_inverting_direction = VariableDistance(4,
    __motif__v4_l10_rhand_x_inverting_direction,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_inverting_direction),
    featurename="InvertingDirection"
)
__var__v4_l10_rhand_x_protracting = VariableDistance(4,
    __motif__v4_l10_rhand_x_protracting,
    distance=x -> _mydistance(x, __motif__v4_l10_rhand_x_protracting),
    featurename="Protracting"
)

_motifs_v4_l40 = motifsalphabet(IHCC[:,4], 30, 10; rng=_seed, r=5, th=0, alphabetsize=1)
__motif__v4_l40_rhand_x_protracting_inverting_leaning = _motifs_v4_l40[1]

__var__v4_l40_rhand_x_protracting_inverting_leaning = VariableDistance(4,
    __motif__v4_l40_rhand_x_protracting_inverting_leaning,
    distance=x -> _mydistance(x, __motif__v4_l40_rhand_x_protracting_inverting_leaning),
    featurename="Protracting⋅InvertingDirection⋅Leaning"
)

# right hand Y variable generations
_motifs_v5_l10 = motifsalphabet(IHCC[:,5], 10, 10; rng=_seed, r=5, th=2)
__motif__v5_l10_rhand_y_ascending = _motifs_v5_l10[1]
__motif__v5_l10_rhand_y_descending = _motifs_v5_l10[2]
__motif__v5_l10_rhand_y_inverting_direction = _motifs_v5_l10[3]

__var__v5_l10_rhand_y_ascending = VariableDistance(5,
    __motif__v5_l10_rhand_y_ascending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_ascending),
    featurename="Ascending"
)
__var__v5_l10_rhand_y_descending = VariableDistance(5,
    __motif__v5_l10_rhand_y_descending,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_descending),
    featurename="Descending"
)
__var__v5_l10_rhand_y_inverting_direction = VariableDistance(5,
    __motif__v5_l10_rhand_y_inverting_direction,
    distance=x -> _mydistance(x, __motif__v5_l10_rhand_y_inverting_direction),
    featurename="InvertingDirection"
)
