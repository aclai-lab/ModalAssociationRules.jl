#=
NATOPS downloaded locally - load_NATOPS()
Apriori elapsed time:
mining on fresh logiset -       132.475009557
leveraging logiset memo -       107.724620054

FPGrowth elapsed time (in seconds):
mining on fresh logiset -       55.956303671
leveraging logiset memo -       24.282045798

Parallel Modal-FPGrowth (using 12 threads) elapsed time (in seconds):
mining on fresh logiset -       16.196234487
leveraging logiset memo -       11.613813371
=#
using BenchmarkTools

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

############################################################################################
#### Benchmarking ##########################################################################
############################################################################################

# Apriori runtime with (1) no optimizations and (2) leveraging dataset memoization
apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
apriori_runtime_no_logiset_optimizations = @elapsed mine!(apriori_miner)

apriori_miner = Miner(X1, apriori, manual_items, _itemsetmeasures, _rulemeasures)
apriori_runtime_with_logiset_optimizations = @elapsed mine!(apriori_miner)

println("Apriori elapsed time:")
println("mining on fresh logiset -\t$(apriori_runtime_no_logiset_optimizations)")
println("leveraging logiset memo -\t$(apriori_runtime_with_logiset_optimizations)")

############################################################################################

# FPGrowth runtime with (1) no optimizations and (2) leveraging dataset memoization
fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_runtime_no_logiset_optimizations = @elapsed mine!(fpgrowth_miner)

fpgrowth_miner = Miner(X2, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
fpgrowth_runtime_with_logiset_optimizations = @elapsed mine!(fpgrowth_miner)

println("\nFPGrowth elapsed time (in seconds):")
println("mining on fresh logiset -\t$(fpgrowth_runtime_no_logiset_optimizations)")
println("leveraging logiset memo -\t$(fpgrowth_runtime_with_logiset_optimizations)")

############################################################################################

# _nthreads = Threads.nthreads()
# println("\nParallel ModalFP-Growth benchmarking...")
# println("Threads number: $(_nthreads)")
# if _nthreads == 1
#     printstyled("Skipping benchmarking. Did you forget to set -t flag?", bold=true)
# else
#     # FPGrowth runtime with multi-threading enabled
#     fpgrowth_miner = Miner(X3, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
#     fpgrowth_runtime_parallel = @elapsed mine!(fpgrowth_miner; parallel=true)
#
#     fpgrowth_miner = Miner(X3, fpgrowth, manual_items, _itemsetmeasures, _rulemeasures)
#     fpgrowth_runtime_parallel_logiset_optimizations = @elapsed mine!(
#         fpgrowth_miner; parallel=true)
#
#     println("Parallel Modal-FPGrowth elapsed time (in seconds):")
#     println("mining on fresh logiset -\t$(fpgrowth_runtime_parallel)")
#     println("leveraging logiset memo -\t$(fpgrowth_runtime_parallel_logiset_optimizations)")
# end
