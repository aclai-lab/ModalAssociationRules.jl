# Include this file in every benchmark based on NATOPS

#= Report example (this included also a "leveraging logiset memo" field)
Apriori elapsed time:
mining on fresh logiset -       132.475009557
leveraging logiset memo -       88.724620054

serial FP-Growth benchmark:
mining on fresh logiset -       44.161213964s

Parallel ModalFP-Growth benchmark:
threads number: 2
mining on fresh logiset -       25.559290247s

Parallel ModalFP-Growth benchmark:
threads number: 4
mining on fresh logiset -       15.07108166s

Parallel ModalFP-Growth benchmark:
threads number: 6
mining on fresh logiset -       12.771895161s

Parallel ModalFP-Growth benchmark:
threads number: 8
mining on fresh logiset -       12.134149515s

Parallel ModalFP-Growth benchmark:
threads number: 10
mining on fresh logiset -       12.011446814s

Parallel ModalFP-Growth benchmarking...
Threads number: 12
mining on fresh logiset -       11.765854723s
=#

#=
Apriori elapsed benchmark:
mining on fresh logiset -       141.908994805s

Serial FPGrowth benchmark:
mining on fresh logiset -       44.2044059s

Parallel ModalFP-Growth benchmark:
threads number: 2
mining on fresh logiset -       23.378121s

Parallel ModalFP-Growth benchmark:
threads number: 4
mining on fresh logiset -       13.720315797s

Parallel ModalFP-Growth benchmark:
threads number: 6
mining on fresh logiset -       11.039609688s

Parallel ModalFP-Growth benchmark:
threads number: 8
mining on fresh logiset -       10.741962272s

Parallel ModalFP-Growth benchmark:
threads number: 10
mining on fresh logiset -       10.131204173s

Parallel ModalFP-Growth benchmark:
threads number: 12
mining on fresh logiset -       9.713116011s
=#

using ModalAssociationRules
using SoleData
using StatsBase

# load NATOPS dataset and convert it to a Logiset
X_df, y = load_NATOPS();
X = scalarlogiset(X_df)

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
