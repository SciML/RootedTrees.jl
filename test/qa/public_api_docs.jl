using RootedTrees
using Test

@testset "public API documentation" begin
    public_names = filter(!=(:RootedTrees), names(RootedTrees; all = false, imported = false))

    missing_docs = Symbol[]
    for name in public_names
        binding = Docs.Binding(RootedTrees, name)
        Docs.hasdoc(binding) || push!(missing_docs, name)
    end
    @test isempty(missing_docs)

    api_page = read(joinpath(pkgdir(RootedTrees), "docs", "src", "api_reference.md"), String)
    @test occursin("@autodocs", api_page)
    @test occursin("Modules = [RootedTrees]", api_page)
end
