# this code flattens the modal dataset specified in the config.json;
# essentially, a transaction dataset is created in such a way that can be
# easily processed by SPMF

using BenchmarkTools
using Graphs
using JSON
using Random
using ProgressBars

using ModalAssociationRules

using SoleLogics: World, randframe
using SoleLogics: KripkeStructure, ExplicitCrispUniModalFrame
using SoleLogics: inittruthvalues, BooleanAlgebra, TOP


##### configuration loading ################################################################

BENCHMARK_REPOSITORY = joinpath(@__DIR__, "test", "benchmark")
FLATTEN_REPOSITORY = joinpath(@__DIR__, "test", "benchmark", "flatten-dataset")

CONFIG_FILENAME = "config.json"
configuration = JSON.parsefile(joinpath(BENCHMARK_REPOSITORY, CONFIG_FILENAME))

SEED = configuration["frame_seed"] |> Xoshiro

NINSTANCES = configuration["n_instances"]
NWORLDS = configuration["n_worlds_per_frame"]
NEDGES = configuration["n_edges_per_frame"]

NITEMS = configuration["n_propositional_items"]

MIN_LOCAL_SUPPORTS = configuration["min_local_supports"]
MIN_GLOBAL_SUPPORTS = configuration["min_global_supports"]

EVALS = configuration["num_evals"]
SAMPLES = configuration["num_runs"]
GCTRIAL = configuration["gctrial"]

# alphabet of both propositional and modal literals (considering diamond operator)
propfacts = [i |> Atom for i in 1:NITEMS] # exploited during the creation of modal instances

facts = vcat(propfacts, diamond().(propfacts))
_items = Item.(facts)    # "handles" for the facts above

# create the synthetic modal dataset (by seed)
modaldataset = Vector{KripkeStructure}([
    generate(
        randframe(SEED, NWORLDS, NEDGES),
        propfacts,
        vcat([SoleLogics.TOP for _ in 1:i], [SoleLogics.BOT for _ in i:NINSTANCES]),
        incremental=true;
        random=true,
        rng=SEED
    )
    for i in 1:NINSTANCES
])

for (i, kmodel) in enumerate(modaldataset)
    open(joinpath(FLATTEN_REPOSITORY, "$(i).txt"), "w") do io
        # new transaction
        for world in kmodel.frame.worlds
            # filling the line
            for (j, fact) in enumerate(facts)
                # does not work for modal operators, as they are not explicitly
                # named in the assignment
                # if kmodel.assignment[world][fact] == ⊤

                if check(fact, kmodel, world) == true
                    print(io, "$j ")
                end
            end

            println(io, "")
        end
    end
end
