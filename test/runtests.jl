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


# see Table 301(I) etc. in butcher2016numerical
t1 = rootedtree([1])
@test order(t1) == 1
@test σ(t1) == 1
@test γ(t1) == 1
@test α(t1) == 1
@test β(t1) == α(t1)*γ(t1)

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

t3 = rootedtree([1, 2, 2])
@test order(t3) == 3
@test σ(t3) == 2
@test γ(t3) == 3
@test α(t3) == 1
@test β(t3) == α(t3)*γ(t3)
@test t3 == t2 ∘ t1

t4 = rootedtree([1, 2, 3])
@test order(t4) == 3
@test σ(t4) == 1
@test γ(t4) == 6
@test α(t4) == 1
@test β(t4) == α(t4)*γ(t4)
@test t4 == t1 ∘ t2

t5 = rootedtree([1, 2, 2, 2])
@test order(t5) == 4
@test σ(t5) == 6
@test γ(t5) == 4
@test α(t5) == 1
@test β(t5) == α(t5)*γ(t5)
@test t5 == t3 ∘ t1

t6 = rootedtree([1, 2, 2, 3])
@inferred RootedTrees.subtrees(t6)
@test order(t6) == 4
@test σ(t6) == 1
@test γ(t6) == 8
@test α(t6) == 3
@test β(t6) == α(t6)*γ(t6)
@test t6 == t2 ∘ t2 == t4 ∘ t1

t7 = rootedtree([1, 2, 3, 3])
@test order(t7) == 4
@test σ(t7) == 2
@test γ(t7) == 12
@test β(t7) == α(t7)*γ(t7)
@test t7 == t1 ∘ t3

t8 = rootedtree([1, 2, 3, 4])
@test order(t8) == 4
@test σ(t8) == 1
@test γ(t8) == 24
@test α(t8) == 1
@test t8 == t1 ∘ t4

t9 = rootedtree([1, 2, 2, 2, 2])
@test order(t9) == 5
@test σ(t9) == 24
@test γ(t9) == 5
@test α(t9) == 1
@test β(t9) == α(t9)*γ(t9)
@test t9 == t5 ∘ t1

t10 = rootedtree([1, 2, 2, 2, 3])
@test order(t10) == 5
@test σ(t10) == 2
@test γ(t10) == 10
@test α(t10) == 6
@test β(t10) == α(t10)*γ(t10)
@test t10 == t3 ∘ t2 == t6 ∘ t1

t11 = rootedtree([1, 2, 2, 3, 3])
@test order(t11) == 5
@test σ(t11) == 2
@test γ(t11) == 15
@test α(t11) == 4
@test t11 == t2 ∘ t3 == t7 ∘ t1

t12 = rootedtree([1, 2, 2, 3, 4])
@test order(t12) == 5
@test σ(t12) == 1
@test γ(t12) == 30
@test α(t12) == 4
@test β(t12) == α(t12)*γ(t12)
@test t12 == t2 ∘ t4 == t8 ∘ t1

t13 = rootedtree([1, 2, 3, 2, 3])
@test order(t13) == 5
@test σ(t13) == 2
@test γ(t13) == 20
@test α(t13) == 3
@test β(t13) == α(t13)*γ(t13)
@test t13 == t4 ∘ t2

t14 = rootedtree([1, 2, 3, 3, 3])
@test order(t14) == 5
@test σ(t14) == 6
@test γ(t14) == 20
@test α(t14) == 1
@test β(t14) == α(t14)*γ(t14)
@test t14 == t1 ∘ t5

t15 = rootedtree([1, 2, 3, 3, 4])
@test order(t15) == 5
@test σ(t15) == 1
@test γ(t15) == 40
@test α(t15) == 3
@test β(t15) == α(t15)*γ(t15)
@test t15 == t1 ∘ t6

t16 = rootedtree([1, 2, 3, 4, 4])
@test order(t16) == 5
@test σ(t16) == 2
@test γ(t16) == 60
@test α(t16) == 1
@test β(t16) == α(t16)*γ(t16)
@test t16 == t1 ∘ t7

t17 = rootedtree([1, 2, 3, 4, 5])
@test order(t17) == 5
@test σ(t17) == 1
@test γ(t17) == 120
@test α(t17) == 1
@test β(t17) == α(t17)*γ(t17)
@test t17 == t1 ∘ t8


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
