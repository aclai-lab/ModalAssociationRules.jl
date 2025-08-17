using Test
using Random

using SoleLogics

using SoleData
using SoleData: VariableMin, VariableMax

function run_tests(list)
    println("\n" * ("#"^50))
    for test in list
        println("TEST: $test")
        @time include(test)
    end
end

println("Julia version: ", VERSION)

test_suites = [
    ("General package functionalities", ["general.jl",]),
    ("Iris", ["iris.jl",]),
    ("NATOPS + Miner comparisons", ["natops.jl"]),
    # ("NATOPS + motifs", ["matrix-profile.jl"]),
]

@testset "ModalAssociationRules.jl" begin
    include("commons.jl")
    using .Commons

    for ts in eachindex(test_suites)
        name = test_suites[ts][1]
        list = test_suites[ts][2]
        let
            @testset "$name" begin
                run_tests(list)
            end
        end
    end
end
