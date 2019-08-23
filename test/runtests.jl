using Test
using StaticArrays
using RootedTrees

trees_array = (rootedtree([1,2,3]),
               rootedtree([1,2,3]),
               rootedtree([1,2,2]),
               rootedtree([1,2,3,3]))

for (t1,t2,t3,t4) in (trees_array,)
  @test t1 == t1
  @test t1 == t2
  @test !(t1 == t3)
  @test !(t1 == t4)

  @test t3 < t2    && t2 > t3
  @test !(t2 < t3) && !(t3 > t2)
  @test t1 < t4    && t4 > t1
  @test !(t4 < t1) && !(t1 > t4)
  @test t1 <= t2   && t2 >= t1
  @test t2 <= t2   && t2 >= t2

  println(devnull, t1)
  println(devnull, t2)
  println(devnull, t3)
  println(devnull, t4)
end


t = rootedtree([1])
@test order(t) == 1
@test σ(t) == 1
@test γ(t) == 1
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2])
@test order(t) == 2
@test σ(t) == 1
@test γ(t) == 2
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 2])
@test order(t) == 3
@test σ(t) == 2
@test γ(t) == 3
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3])
@test order(t) == 3
@test σ(t) == 1
@test γ(t) == 6
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 2, 2])
@test order(t) == 4
@test σ(t) == 6
@test γ(t) == 4
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 2, 3])
@inferred RootedTrees.subtrees(t)
@test order(t) == 4
@test σ(t) == 1
@test γ(t) == 8
@test α(t) == 3
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 3])
@test order(t) == 4
@test σ(t) == 2
@test γ(t) == 12
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 4])
@test order(t) == 4
@test σ(t) == 1
@test γ(t) == 24
@test α(t) == 1

t = rootedtree([1, 2, 2, 2, 2])
@test order(t) == 5
@test σ(t) == 24
@test γ(t) == 5
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 2, 2, 3])
@test order(t) == 5
@test σ(t) == 2
@test γ(t) == 10
@test α(t) == 6
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 2, 3, 3])
@test order(t) == 5
@test σ(t) == 2
@test γ(t) == 15
@test α(t) == 4

t = rootedtree([1, 2, 2, 3, 4])
@test order(t) == 5
@test σ(t) == 1
@test γ(t) == 30
@test α(t) == 4
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 2, 3])
@test order(t) == 5
@test σ(t) == 2
@test γ(t) == 20
@test α(t) == 3
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 3, 3])
@test order(t) == 5
@test σ(t) == 6
@test γ(t) == 20
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 3, 4])
@test order(t) == 5
@test σ(t) == 1
@test γ(t) == 40
@test α(t) == 3
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 4, 4])
@test order(t) == 5
@test σ(t) == 2
@test γ(t) == 60
@test α(t) == 1
@test β(t) == α(t)*γ(t)

t = rootedtree([1, 2, 3, 4, 5])
@test order(t) == 5
@test σ(t) == 1
@test γ(t) == 120
@test α(t) == 1
@test β(t) == α(t)*γ(t)

# see butcher2008numerical, Table 302(I)
number_of_rooted_trees = [1, 1, 2, 4, 9, 20, 48, 115, 286, 719]
for order in 1:10
  num = 0
  for t in RootedTreeIterator(order)
    num += 1
  end
  @test num == number_of_rooted_trees[order] == count_trees(order)
end

# Runge-Kutta method SSPRK33 of order 3
A = [0 0 0; 1 0 0; 1/4 1/4 0]
b = [1/6, 1/6, 2/3]
c = A * fill(1, length(b))
for order in 1:3
  for t in RootedTreeIterator(order)
    @test residual_order_condition(t, A, b, c) ≈ 0 atol=eps()
  end
end
let order=4
  res = 0.
  for t in RootedTreeIterator(order)
    res += abs(residual_order_condition(t, A, b, c))
  end
  @test res > 10*eps()
end

A = @SArray [0 0 0; 1 0 0; 1/4 1/4 0]
b = @SArray [1/6, 1/6, 2/3]
c = A * SVector(1, 1, 1)
for order in 1:3
  for t in RootedTreeIterator(order)
    @test residual_order_condition(t, A, b, c) ≈ 0 atol=eps()
  end
end
let order=4
  res = 0.
  for t in RootedTreeIterator(order)
    res += abs(residual_order_condition(t, A, b, c))
  end
  @test res > 10*eps()
end
