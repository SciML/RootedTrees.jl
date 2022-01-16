# Runge-Kutta methods

Consider an ordinary differential equation (ODE) of the form
```math
u'(t) = f(t, u(t)).
```

A Runge-Kutta (RK) method with ``s`` stages is given by its
Butcher coefficients
```math
A = (a_{i,j})_{i,j} \in \mathbb{R}^{s \times s}, \quad
b = (b_i)_i \in \mathbb{R}^{s}, \quad
c = (c_i)_i \in \mathbb{R}^{s},
```
which are often written in form of the Butcher tableau
```math
\begin{array}{c|cc}
  c & A \\
  \hline
  & b^T \\
\end{array}
```
Usually, the consistency condition
```math
\forall i\colon \quad c_i = \sum_j a_{i,j}
```
is assumed, which reduces all analysis to autonomous problems.

The step from ``u^{n}`` to ``u^{n+1}`` is given by
```math
\begin{aligned}
  y^i &= u^n + \Delta t \sum_j a_{i,j} f(t^n + c_i \Delta t, y^i), \\
  u^{n+1} &= u^n + \Delta t \sum_i b_{i} f(t^n + c_i \Delta t, y^i),
\end{aligned}
```
where ``y^i`` are the stage values.

In [RootedTrees.jl](https://github.com/SciML/RootedTrees.jl),
RK methods are represented as
[`RungeKuttaMethod`](@ref)s.


## Order conditions

The order conditions of RK methods can be derived using rooted trees.
In [RootedTrees.jl](https://github.com/SciML/RootedTrees.jl), this
functionality is implemented in [`residual_order_condition`](@ref).
Thus, a [`RungeKuttaMethod`](@ref) is of order ``p`` if the
[`residual_order_condition`](@ref) vanishes for all rooted trees
with [`order`](@ref) up to ``p``.

For example, the classical fourth-order RK method can be
written as follows.

```@example RK4
using RootedTrees

A = [0 0 0 0; 1//2 0 0 0; 0 1//2 0 0; 0 0 1 0]
b = [1//6, 1//3, 1//3, 1//6]
rk = RungeKuttaMethod(A, b)
```

To verify that this method is at least fourth-order accurate, we can
check the [`residual_order_condition`](@ref)s up to this order.

```@example RK4
using Test

@testset "RK4, order 4" begin
  for o in 1:4
    for t in RootedTreeIterator(o)
      @test iszero(residual_order_condition(t, rk))
    end
  end
end
nothing # hide
```

To verify that this method does not satisfy any of the order conditions
for an order of accuracy of five, we can use the following code.

```@example RK4
using Test

@testset "RK4, not order 5" begin
  for t in RootedTreeIterator(5)
    @test !iszero(residual_order_condition(t, rk))
  end
end
nothing # hide
```


## Symbolic computation and automatic differentiation

The implementation is fully generic using plain Julia code. In particular,
this enables automatic differentiation (AD) and symbolic computations.

### Symbolic computations

For example, you can determine the order conditions symbolically as follows.
```@example
using RootedTrees, SymPy

s = 3 # number of stages
A = [symbols("a_$(i)$(j)", real=true) for i in 1:s, j in 1:s]
b = [symbols("b_$(i)", real=true) for i in 1:s]
rk = RungeKuttaMethod(A, b)

for o in 1:3
  println("Order ", o)
  for t in RootedTreeIterator(o)
    println("t = ", t)
    println(residual_order_condition(t, rk))
  end
  println()
end

nothing # hide
```

### Automatic differentiation

The order conditions can be differentiated with respect to the Runge-Kutta
coefficients. For example, we can use
[ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) and
[Zygote.jl](https://github.com/FluxML/Zygote.jl)
as follows.

```@example AD-Jacobian
using RootedTrees, ForwardDiff, Zygote

# collect all rooted trees up to order 4
trees = [copy(t) for o in 1:4 for t in RootedTreeIterator(o)]

# classical RK4 method
A = [0 0 0 0; 1//2 0 0 0; 0 1//2 0 0; 0 0 1 0]
b = [1//6, 1//3, 1//3, 1//6]
coeffs = vcat(vec(A), vec(b)) # one vector of all parameters

function all_order_conditions(trees, coeffs)
  # extract Butcher coefficients from the vector of all coefficients
  # for an RK method with four stages
  A = reshape(view(coeffs, 1:16), 4, 4)
  b = view(coeffs, 17:20)
  rk = RungeKuttaMethod(A, b)
  map(t -> residual_order_condition(t, rk), trees)
end

@assert iszero(all_order_conditions(trees, coeffs)) # fourth-order accurate

ForwardDiff.jacobian(coeffs -> all_order_conditions(trees, coeffs), coeffs)
```

```@example AD-Jacobian
Zygote.jacobian(coeffs -> all_order_conditions(trees, coeffs), coeffs)
```

```@example AD-Jacobian
ForwardDiff.jacobian(coeffs -> all_order_conditions(trees, coeffs), coeffs) == first(Zygote.jacobian(coeffs -> all_order_conditions(trees, coeffs), coeffs))
```
