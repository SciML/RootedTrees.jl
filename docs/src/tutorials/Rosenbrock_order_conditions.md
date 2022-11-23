# Rosenbrock methods

Consider an ordinary differential equation (ODE) of the form
```math
u'(t) = f(t, u(t)).
```

A Rosenbrock (or Rosenbrock-Wanner, ROW) method with ``s`` stages is given
by its coefficients
```math
\gamma = (\gamma_{i,j})_{i,j} \in \mathbb{R}^{s \times s}, \quad
A = (a_{i,j})_{i,j} \in \mathbb{R}^{s \times s}, \quad
b = (b_i)_i \in \mathbb{R}^{s}, \quad
c = (c_i)_i \in \mathbb{R}^{s}.
```
Usually, the consistency condition
```math
\forall i\colon \quad c_i = \sum_j a_{i,j}
```
is assumed, which reduces all analysis to autonomous problems.

The step from ``u^{n}`` to ``u^{n+1}`` is given by
```math
\begin{aligned}
  k^i &= \Delta t f\bigl(u^n + \sum_j a_{i,j} k^j \bigr) + \Delta t J \sum_j \gamma_{ij} k_j, \\
  u^{n+1} &= u^n + \sum_i b_{i} k^i.
\end{aligned}
```

In [RootedTrees.jl](https://github.com/SciML/RootedTrees.jl),
ROW methods are represented as
[`RosenbrockMethod`](@ref)s.


## Order conditions

The order conditions of ROW methods can be derived using rooted trees.
In [RootedTrees.jl](https://github.com/SciML/RootedTrees.jl), this
functionality is again implemented in [`residual_order_condition`](@ref).
Thus, a [`RosenbrockMethod`](@ref) is of order ``p`` if the
[`residual_order_condition`](@ref) vanishes for all rooted trees
with [`order`](@ref) up to ``p``.

For example, the method GRK4A of
[Kaps and Rentrop (1979)](https://doi.org/10.1007/BF01396495) can be
written as follows.

```@example GRK4A
using RootedTrees

γ = [0.395 0 0 0;
     -0.767672395484 0.395 0 0;
     -0.851675323742 0.522967289188 0.395 0;
     0.288463109545 0.880214273381e-1 -.337389840627 0.395]
A = [0 0 0 0;
     0.438 0 0 0;
     0.796920457938 0.730795420615e-1 0 0;
     0.796920457938 0.730795420615e-1 0 0]
b = [0.199293275701, 0.482645235674, 0.680614886256e-1, 0.25]
ros = RosenbrockMethod(γ, A, b)
```

To verify that this method is at least fourth-order accurate, we can
check the [`residual_order_condition`](@ref)s up to this order.

```@example GRK4A
using Test

@testset "GRK4A, order 4" begin
  for o in 0:4
    for t in RootedTreeIterator(o)
      val = residual_order_condition(t, ros)
      @test abs(val) < 3000 * eps()
    end
  end
end
nothing # hide
```

To verify that this method does not satisfy the order conditions
for an order of accuracy of five, we can use the following code.

```@example GRK4A

@testset "GRK4A, not order 5" begin
  s = 0.0
  for t in RootedTreeIterator(5)
    s += abs(residual_order_condition(t, ros))
  end
  @test s > 0.06
end
nothing # hide
```
