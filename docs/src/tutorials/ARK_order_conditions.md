# Additive Runge-Kutta methods

Consider an ordinary differential equation (ODE) of the form
```math
u'(t) = \sum_{\nu=1}^N f^\nu(t, u(t)).
```

An additive Runge-Kutta (ARK) method with ``s`` stages is given by its
Butcher coefficients
```math
A^\nu = (a^\nu_{i,j})_{i,j} \in \mathbb{R}^{s \times s}, \quad
b^\nu = (b^\nu_i)_i \in \mathbb{R}^{s}, \quad
c^\nu = (c^\nu_i)_i \in \mathbb{R}^{s}.
```
Usually, the consistency condition
```math
\forall i\colon \quad c^\nu_i = \sum_j a^\nu_{i,j}
```
is assumed, which reduces all analysis to autonomous problems.

The step from ``u^{n}`` to ``u^{n+1}`` is given by
```math
\begin{aligned}
  y^i &= u^n + \Delta t \sum_\nu \sum_j a^\nu_{i,j} f^\nu(t^n + c_j \Delta t, y^j), \\
  u^{n+1} &= u^n + \Delta t \sum_\nu \sum_i b^\nu_{i} f^\nu(t^n + c_i \Delta t, y^i),
\end{aligned}
```
where ``y^i`` are the stage values.

In [RootedTrees.jl](https://github.com/SciML/RootedTrees.jl),
ARK methods are represented as
[`AdditiveRungeKuttaMethod`](@ref)s.


## Order conditions

The order conditions of ARK methods can be derived using colored rooted trees.
In [RootedTrees.jl](https://github.com/SciML/RootedTrees.jl), this
functionality is implemented in [`residual_order_condition`](@ref).
Thus, an [`AdditiveRungeKuttaMethod`](@ref) is of order ``p`` if the
[`residual_order_condition`](@ref) vanishes for all colored rooted trees
with [`order`](@ref) up to ``p`` and ``N`` colors. The most important case
is ``N = 2``, i.e., [`BicoloredRootedTree`](@ref)s as special case of
[`ColoredRootedTree`](@ref)s.

For example, the classical Störmer-Verlet method can be
written as follows, see Table II.2.1 of Hairer, Lubich, Wanner (2002)
[Geometric numerical integration](https://doi.org/10.1007/3-540-30666-8).

```@example Störmer-Verlet
using RootedTrees

As = [
  [0 0; 1//2 1//2],
  [1//2 0; 1//2 0]
]
bs = [
  [1//2, 1//2],
  [1//2, 1//2]
]
ark = AdditiveRungeKuttaMethod(As, bs)
```

To verify that this method is at least second-order accurate, we can
check the [`residual_order_condition`](@ref)s up to this order.

```@example Störmer-Verlet
using Test

@testset "Störmer-Verlet, order 2" begin
  for o in 1:2
    for t in BicoloredRootedTreeIterator(o)
      @test iszero(residual_order_condition(t, ark))
    end
  end
end
nothing # hide
```

To verify that this method does not satisfy any of the order conditions
for an order of accuracy of three, we can use the following code.

```@example Störmer-Verlet
using Test

@testset "Störmer-Verlet, not order 3" begin
  for t in BicoloredRootedTreeIterator(3)
    @test !iszero(residual_order_condition(t, ark))
  end
end
nothing # hide
```
