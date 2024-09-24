# Include this file in every benchmark based on NATOPS

#=
NATOPS downloaded locally - load_NATOPS()
Apriori elapsed time:
mining on fresh logiset -       132.475009557
leveraging logiset memo -       107.724620054

FPGrowth elapsed time:
mining on fresh logiset -       55.956303671
leveraging logiset memo -       24.282045798

Parallel ModalFP-Growth benchmarking...
Threads number: 4
Parallel Modal-FPGrowth elapsed time (in seconds):
mining on fresh logiset -       28.231277738
leveraging logiset memo -       16.351069634

Parallel ModalFP-Growth benchmarking...
Threads number: 8
Parallel Modal-FPGrowth elapsed time (in seconds):
mining on fresh logiset -       34.547207408
leveraging logiset memo -       7.754877006

Parallel ModalFP-Growth benchmarking...
Threads number: 12
Parallel Modal-FPGrowth elapsed time (in seconds):
mining on fresh logiset -       25.306834625
leveraging logiset memo -       8.896269504
=#

using ModalAssociationRules
using SoleData
using StatsBase

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X1 = scalarlogiset(X_df)

# different tested algorithms will use different Logiset's copies
X2 = deepcopy(X1)
X3 = deepcopy(X1)

# make a vector of item, that will be the initial state of the mining machine
manual_p = Atom(ScalarCondition(VariableMin(1), >, -0.5))
manual_q = Atom(ScalarCondition(VariableMin(2), <=, -2.2))
manual_r = Atom(ScalarCondition(VariableMin(3), >, -3.6))

manual_lp = box(IA_L)(manual_p)
manual_lq = diamond(IA_L)(manual_q)
manual_lr = box(IA_L)(manual_r)

manual_items = Vector{Item}([
    manual_p, manual_q, manual_r, manual_lp, manual_lq, manual_lr])

# set meaningfulness measures, for both mining frequent itemsets and establish which
# combinations of them are association rules.
_itemsetmeasures = [(gsupport, 0.1, 0.1)]
_rulemeasures = [(gconfidence, 0.2, 0.2)]
