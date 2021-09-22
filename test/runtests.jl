using Test
using StaticArrays
using RootedTrees

using Plots: Plots, plot
Plots.unicodeplots()

@testset "RootedTrees" begin

@testset "comparisons etc." begin
  trees = (rootedtree([1, 2, 3]),
           rootedtree([1, 2, 3]),
           rootedtree([1, 2, 2]),
           rootedtree([1, 2, 3, 3]),
           rootedtree(Int[]))
  trees_shifted = (rootedtree([1, 2, 3]),
                   rootedtree([2, 3, 4]),
                   rootedtree([1, 2, 2]),
                   rootedtree([1, 2, 3, 3]),
                   rootedtree(Int[]))

  for (t1,t2,t3,t4,t5) in (trees, trees_shifted)
    @test t1 == t1
    @test t1 == t2
    @test !(t1 == t3)
    @test !(t1 == t4)
    @test !(t1 == t5)
    @test !(t2 == t5)
    @test !(t3 == t5)
    @test !(t4 == t5)
    @test t5 == t5

    @test hash(t1) == hash(t1)
    @test hash(t1) == hash(t2)
    @test !(hash(t1) == hash(t3))
    @test !(hash(t1) == hash(t4))
    @test hash(t1) != hash(t5)
    @test hash(t2) != hash(t5)
    @test hash(t3) != hash(t5)
    @test hash(t4) != hash(t5)
    @test hash(t5) == hash(t5)

    @test !(t1 < t1)
    @test !(t1 < t2)
    @test !(t2 < t1)
    @test !(t1 > t2)
    @test !(t2 > t1)
    @test t3 < t2    && t2 > t3
    @test !(t2 < t3) && !(t3 > t2)
    @test t1 < t4    && t4 > t1
    @test !(t4 < t1) && !(t1 > t4)
    @test t1 <= t2   && t2 >= t1
    @test t2 <= t2   && t2 >= t2
    @test t5 < t1
    @test t1 > t5
    @test !(t5 < t5)
    @test !(t1 < t5)

    println(devnull, t1)
    println(devnull, t2)
    println(devnull, t3)
    println(devnull, t4)
  end
end


# see Table 301(I) etc. in butcher2016numerical
@testset "functions on trees" begin
  t1 = rootedtree([1])
  @test order(t1) == 1
  @test σ(t1) == 1
  @test γ(t1) == 1
  @test α(t1) == 1
  @test β(t1) == α(t1)*γ(t1)
  @test butcher_representation(t1) == "τ"

  @inferred order(t1)
  @inferred σ(t1)
  @inferred γ(t1)
  @inferred α(t1)
  @inferred β(t1)
  @inferred t1 ∘ t1

  t2 = rootedtree([1, 2])
  @test order(t2) == 2
  @test σ(t2) == 1
  @test γ(t2) == 2
  @test α(t2) == 1
  @test β(t2) == α(t2)*γ(t2)
  @test t2 == t1 ∘ t1
  @test butcher_representation(t2) == "[τ]"

  t3 = rootedtree([1, 2, 2])
  @test order(t3) == 3
  @test σ(t3) == 2
  @test γ(t3) == 3
  @test α(t3) == 1
  @test β(t3) == α(t3)*γ(t3)
  @test t3 == t2 ∘ t1
  @test butcher_representation(t3) == "[τ²]"

  t4 = rootedtree([1, 2, 3])
  @test order(t4) == 3
  @test σ(t4) == 1
  @test γ(t4) == 6
  @test α(t4) == 1
  @test β(t4) == α(t4)*γ(t4)
  @test t4 == t1 ∘ t2
  @test butcher_representation(t4) == "[[τ]]"

  t5 = rootedtree([1, 2, 2, 2])
  @test order(t5) == 4
  @test σ(t5) == 6
  @test γ(t5) == 4
  @test α(t5) == 1
  @test β(t5) == α(t5)*γ(t5)
  @test t5 == t3 ∘ t1
  @test butcher_representation(t5) == "[τ³]"

  t6 = rootedtree([1, 2, 2, 3])
  @inferred RootedTrees.subtrees(t6)
  @test order(t6) == 4
  @test σ(t6) == 1
  @test γ(t6) == 8
  @test α(t6) == 3
  @test β(t6) == α(t6)*γ(t6)
  @test t6 == t2 ∘ t2 == t4 ∘ t1
  @test butcher_representation(t6) == "[[τ]τ]"

  t7 = rootedtree([1, 2, 3, 3])
  @test order(t7) == 4
  @test σ(t7) == 2
  @test γ(t7) == 12
  @test β(t7) == α(t7)*γ(t7)
  @test t7 == t1 ∘ t3
  @test butcher_representation(t7) == "[[τ²]]"

  t8 = rootedtree([1, 2, 3, 4])
  @test order(t8) == 4
  @test σ(t8) == 1
  @test γ(t8) == 24
  @test α(t8) == 1
  @test t8 == t1 ∘ t4
  @test butcher_representation(t8) == "[[[τ]]]"

  t9 = rootedtree([1, 2, 2, 2, 2])
  @test order(t9) == 5
  @test σ(t9) == 24
  @test γ(t9) == 5
  @test α(t9) == 1
  @test β(t9) == α(t9)*γ(t9)
  @test t9 == t5 ∘ t1
  @test butcher_representation(t9) == "[τ⁴]"

  t10 = rootedtree([1, 2, 2, 2, 3])
  @test order(t10) == 5
  @test σ(t10) == 2
  @test γ(t10) == 10
  @test α(t10) == 6
  @test β(t10) == α(t10)*γ(t10)
  @test t10 == t3 ∘ t2 == t6 ∘ t1
  @test butcher_representation(t10) == "[[τ]τ²]"

  t11 = rootedtree([1, 2, 2, 3, 3])
  @test order(t11) == 5
  @test σ(t11) == 2
  @test γ(t11) == 15
  @test α(t11) == 4
  @test t11 == t2 ∘ t3 == t7 ∘ t1
  @test butcher_representation(t11) == "[[τ²]τ]"

  t12 = rootedtree([1, 2, 2, 3, 4])
  @test order(t12) == 5
  @test σ(t12) == 1
  @test γ(t12) == 30
  @test α(t12) == 4
  @test β(t12) == α(t12)*γ(t12)
  @test t12 == t2 ∘ t4 == t8 ∘ t1
  @test butcher_representation(t12) == "[[[τ]]τ]"

  t13 = rootedtree([1, 2, 3, 2, 3])
  @test order(t13) == 5
  @test σ(t13) == 2
  @test γ(t13) == 20
  @test α(t13) == 3
  @test β(t13) == α(t13)*γ(t13)
  @test t13 == t4 ∘ t2
  @test butcher_representation(t13) == "[[τ][τ]]"

  t14 = rootedtree([1, 2, 3, 3, 3])
  @test order(t14) == 5
  @test σ(t14) == 6
  @test γ(t14) == 20
  @test α(t14) == 1
  @test β(t14) == α(t14)*γ(t14)
  @test t14 == t1 ∘ t5
  @test butcher_representation(t14) == "[[τ³]]"

  t15 = rootedtree([1, 2, 3, 3, 4])
  @test order(t15) == 5
  @test σ(t15) == 1
  @test γ(t15) == 40
  @test α(t15) == 3
  @test β(t15) == α(t15)*γ(t15)
  @test t15 == t1 ∘ t6
  @test butcher_representation(t15) == "[[[τ]τ]]"

  t16 = rootedtree([1, 2, 3, 4, 4])
  @test order(t16) == 5
  @test σ(t16) == 2
  @test γ(t16) == 60
  @test α(t16) == 1
  @test β(t16) == α(t16)*γ(t16)
  @test t16 == t1 ∘ t7
  @test butcher_representation(t16) == "[[[τ²]]]"

  t17 = rootedtree([1, 2, 3, 4, 5])
  @test order(t17) == 5
  @test σ(t17) == 1
  @test γ(t17) == 120
  @test α(t17) == 1
  @test β(t17) == α(t17)*γ(t17)
  @test t17 == t1 ∘ t8
  @test butcher_representation(t17) == "[[[[τ]]]]"
end


# see butcher2008numerical, Table 302(I)
@testset "number of trees" begin
  number_of_rooted_trees = [1, 1, 2, 4, 9, 20, 48, 115, 286, 719]
  for order in 1:10
    num = 0
    for t in RootedTreeIterator(order)
      num += 1
    end
    @test num == number_of_rooted_trees[order] == count_trees(order)
  end
end

# Runge-Kutta method SSPRK33 of order 3
@testset "Runge-Kutta order conditions" begin
  A = [0 0 0; 1 0 0; 1/4 1/4 0]
  b = [1/6, 1/6, 2/3]
  c = A * fill(1, length(b))
  for order in 1:3
    for t in RootedTreeIterator(order)
      @test residual_order_condition(t, A, b, c) ≈ 0 atol=eps()
    end
  end
  let order=4
    res = 0.0
    for t in RootedTreeIterator(order)
      res += abs(residual_order_condition(t, A, b, c))
    end
    @test res > 10*eps()
  end

  A = @SArray [0 0 0; 1 0 0; 1/4 1/4 0]
  b = @SArray [1/6, 1/6, 2/3]
  c = A * SVector(1, 1, 1)
  for order in 1:3
    @test all(RootedTreeIterator(order)) do t
      abs(residual_order_condition(t, A, b, c)) < eps()
    end
  end

  let order=4
    res = 0.0
    for t in RootedTreeIterator(order)
      res += abs(residual_order_condition(t, A, b, c))
    end
    @test res > 10*eps()
  end
end

# See Section 2.3 and Table 2 of
# - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
#   Algebraic Structures of B-series
#   Foundations of Computational Mathematics
#   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
@testset "partitions" begin
  let t = rootedtree([1, 2, 3, 4, 3])
    edge_set = [true, true, false, false]
    reference_forest = [rootedtree([1, 2, 3]),
                        rootedtree([4]),
                        rootedtree([3])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 2])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 4, 3])
    edge_set = [false, true, true, false]
    reference_forest = [rootedtree([3]),
                        rootedtree([2, 3, 4]),
                        rootedtree([1])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 3])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 4, 3])
    edge_set = [false, true, false, false]
    reference_forest = [rootedtree([4]),
                        rootedtree([3]),
                        rootedtree([2, 3]),
                        rootedtree([1])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 3, 3])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 2, 2, 2])
    edge_set = [false, false, true, true]
    reference_forest = [rootedtree([2]),
                        rootedtree([2]),
                        rootedtree([1, 2, 2])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 2])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 2, 2])
    edge_set = [false, false, false, true]
    reference_forest = [rootedtree([3]),
                        rootedtree([2]),
                        rootedtree([2]),
                        rootedtree([1, 2])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 3, 2])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 2, 2])
    edge_set = [true, true, true, true]
    reference_forest = [rootedtree([1, 2, 3, 2, 2])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 2, 3])
    edge_set = [true, true, false, false]
    reference_forest = [rootedtree([3]),
                        rootedtree([2]),
                        rootedtree([1, 2, 3])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 3])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 2, 3])
    edge_set = [false, true, false, false]
    reference_forest = [rootedtree([2, 3]),
                        rootedtree([3]),
                        rootedtree([2]),
                        rootedtree([1])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 2, 3])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  let t = rootedtree([1, 2, 3, 3, 3])
    edge_set = [false, true, true, false]
    reference_forest = [rootedtree([3]),
                        rootedtree([2, 3, 3]),
                        rootedtree([1])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2, 3])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end

  # additional tests not included in the examples of the paper
  let t = rootedtree([1, 2, 3, 2, 3])
    edge_set = [true, false, true, true]
    reference_forest = [rootedtree([1, 2, 3, 2]),
                        rootedtree([3])]
    @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
    reference_skeleton = rootedtree([1, 2])
    @test reference_skeleton == partition_skeleton(t, edge_set)
  end
end

# See Table 3 of
# - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
#   Algebraic Structures of B-series
#   Foundations of Computational Mathematics
#   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
@testset "all_partitions" begin
  t = rootedtree([1, 2, 3, 3])
  forests, skeletons = all_partitions(t)
  for forest in forests
    for tree in forest
      RootedTrees.normalize_root!(tree)
    end
    sort!(forest)
  end
  sort!(forests)
  for tree in skeletons
    RootedTrees.normalize_root!(tree)
  end
  sort!(skeletons)

  reference_forests = [
    [rootedtree([1, 2, 3, 3]),],
    [rootedtree([1]), rootedtree([1, 2, 2])],
    [rootedtree([1]), rootedtree([1, 2, 3])],
    [rootedtree([1]), rootedtree([1, 2, 3]),],
    [rootedtree([1]), rootedtree([1]), rootedtree([1, 2])],
    [rootedtree([1]), rootedtree([1]), rootedtree([1, 2])],
    [rootedtree([1]), rootedtree([1]), rootedtree([1, 2])],
    [rootedtree([1]), rootedtree([1]), rootedtree([1]), rootedtree([1])],
  ]
  reference_skeletons = [
    rootedtree([1]),
    rootedtree([1, 2]),
    rootedtree([1, 2]),
    rootedtree([1, 2]),
    rootedtree([1, 2, 2]),
    rootedtree([1, 2, 3]),
    rootedtree([1, 2, 3]),
    rootedtree([1, 2, 3, 3]),
  ]
  for forest in reference_forests
    sort!(forest)
  end
  sort!(reference_forests)
  sort!(reference_skeletons)

  @test forests == reference_forests
  @test skeletons == reference_skeletons

  partitions = collect(PartitionIterator(t))
  iterator_forests = map(first, partitions)
  iterator_skeletons = map(last, partitions)
  for forest in iterator_forests
    sort!(forest)
  end
  sort!(iterator_forests)
  sort!(iterator_skeletons)
  @test iterator_forests == forests
  @test iterator_skeletons == skeletons

  for order in 1:8
    for i in RootedTreeIterator(order)
      forests, skeletons = all_partitions(t)
      @test collect(zip(forests, skeletons)) == collect(PartitionIterator(t))
    end
  end
end


# See Section 2.2 and Table 1 of
# - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
#   Algebraic Structures of B-series
#   Foundations of Computational Mathematics
#   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
@testset "splittings" begin
  t = rootedtree([1, 2, 3, 2, 2])
  splittings = all_splittings(t)
  forests_and_subtrees = sort!(collect(zip(splittings.forests, splittings.subtrees)))

  reference_forests_and_subtrees = sort!([
    (empty([rootedtree([1])]),                               rootedtree([1, 2, 3, 2, 2])),
    ([rootedtree([1])],                                      rootedtree([1, 2, 3, 2])),
    ([rootedtree([1])],                                      rootedtree([1, 2, 3, 2])),
    ([rootedtree([1, 2])],                                   rootedtree([1, 2, 2])),
    ([rootedtree([1])],                                      rootedtree([1, 2, 2, 2])),
    ([rootedtree([1, 2]), rootedtree([1])],                  rootedtree([1, 2])),
    ([rootedtree([1, 2]), rootedtree([1])],                  rootedtree([1, 2])),
    ([rootedtree([1]),    rootedtree([1])],                  rootedtree([1, 2, 3])),
    ([rootedtree([1]),    rootedtree([1])],                  rootedtree([1, 2, 2])),
    ([rootedtree([1]),    rootedtree([1])],                  rootedtree([1, 2, 2])),
    ([rootedtree([1]),    rootedtree([1]), rootedtree([1])], rootedtree([1, 2])),
    ([rootedtree([1, 2]), rootedtree([1]), rootedtree([1])], rootedtree([1])),
    ([rootedtree([1, 2, 3, 2, 2])],                          rootedtree(Int[])),
  ])

  @test forests_and_subtrees == reference_forests_and_subtrees

  # tested with the Python package BSeries
  t = rootedtree([1, 2, 3, 4, 4, 2, 3, 3, 2, 3, 2, 3])
  splittings = all_splittings(t)
  @test length(splittings.forests) == length(splittings.subtrees) == 271

  # consistency of all_splittings and the SplittingIterator
  for order in 1:8
    for i in RootedTreeIterator(order)
      forests, subtrees = all_splittings(t)
      @test collect(zip(forests, subtrees)) == collect(SplittingIterator(t))
    end
  end
end


@testset "plots" begin
  for order in 1:4
    for t in RootedTreeIterator(order)
      plot(t)
    end
  end
end


end # @testset "RootedTrees"
