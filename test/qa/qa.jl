using Test
using SafeTestsets

@testset "QA" begin
    @safetestset "Aqua" begin
        include("aqua_tests.jl")
    end

    @safetestset "ExplicitImports" begin
        include("explicitimports_tests.jl")
    end

    @safetestset "JET static analysis" begin
        include("jet_tests.jl")
    end
end
