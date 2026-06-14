using Test
using RootedTrees
using ExplicitImports: check_no_implicit_imports, check_no_stale_explicit_imports

@test isnothing(check_no_implicit_imports(RootedTrees))
@test isnothing(check_no_stale_explicit_imports(RootedTrees))
