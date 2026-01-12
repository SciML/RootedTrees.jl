using JET: @test_opt
using RootedTrees

@testset "JET static analysis" begin
    # Test core type-stable functions with JET's optimization analysis.
    # We use `target_modules=(RootedTrees,)` to focus on issues within
    # this package, ignoring any issues from dependencies.
    #
    # Note: Some functions like `symmetry` use recursion which JET cannot
    # fully analyze for optimization, but they are still type-stable
    # as verified by the @inferred tests throughout this file.

    # Core tree construction and properties
    t = rootedtree([1, 2, 3, 2])
    @test_opt target_modules = (RootedTrees,) order(t)
    @test_opt target_modules = (RootedTrees,) γ(t)
    @test_opt target_modules = (RootedTrees,) hash(t)

    # Iterator construction
    @test_opt target_modules = (RootedTrees,) RootedTreeIterator(4)
    iter = RootedTreeIterator(4)
    @test_opt target_modules = (RootedTrees,) iterate(iter)

    # ColoredRootedTree construction
    ct = rootedtree([1, 2, 3], Bool[true, false, true])
    @test_opt target_modules = (RootedTrees,) order(ct)
    @test_opt target_modules = (RootedTrees,) γ(ct)
    @test_opt target_modules = (RootedTrees,) hash(ct)

    # RungeKuttaMethod construction
    A = [0 0; 1 // 2 0]
    b = [0, 1]
    c = [0, 1 // 2]
    @test_opt target_modules = (RootedTrees,) RungeKuttaMethod(A, b, c)

    # RosenbrockMethod construction
    @test_opt target_modules = (RootedTrees,) RosenbrockMethod([1 // 2;;], [0 0; 1 0], [1 // 2, 1 // 2])

    # SubtreeIterator
    @test_opt target_modules = (RootedTrees,) RootedTrees.SubtreeIterator(t)
    subtrees = RootedTrees.SubtreeIterator(t)
    @test_opt target_modules = (RootedTrees,) iterate(subtrees)
end
