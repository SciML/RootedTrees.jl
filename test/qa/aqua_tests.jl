using Test
using RootedTrees
using Aqua: Aqua

Aqua.test_all(
    RootedTrees;
    ambiguities = (; exclude = [getindex]),
    # Requires.jl is not loaded on new versions of Julia
    stale_deps = (; ignore = [:Requires])
)
