using Test
using Pkg
using SafeTestsets

# Get test group from environment
const GROUP = lowercase(get(ENV, "GROUP", "all"))

# Core group runs the functional test suite.
# QA group runs Aqua / ExplicitImports / JET in an isolated environment.
# all group (default for local testing) runs everything.
const RUN_CORE_TESTS = GROUP in ("core", "all")
const RUN_QA_TESTS = GROUP in ("qa", "all")

@testset "RootedTrees" begin
    if RUN_CORE_TESTS
        @safetestset "RootedTree" begin
            include("rootedtree_tests.jl")
        end
        @safetestset "ColoredRootedTree" begin
            include("coloredrootedtree_tests.jl")
        end
        @safetestset "Order conditions" begin
            include("order_conditions_tests.jl")
        end
        @safetestset "plots" begin
            include("plots_tests.jl")
        end
    end
end

if RUN_QA_TESTS
    Pkg.activate(joinpath(@__DIR__, "qa"))
    Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..")))
    Pkg.instantiate()
    include(joinpath(@__DIR__, "qa", "qa.jl"))
end
