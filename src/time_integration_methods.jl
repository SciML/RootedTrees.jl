
abstract type AbstractTimeIntegrationMethod end


"""
    RungeKuttaMethod(A, b, c=vec(sum(A, dims=2)))

Represent a Runge-Kutta method with Butcher coefficients `A`, `b`, and `c`.
If `c` is not provided, the usual "row sum" requirement of consistency with
autonomous problems is applied.
"""
struct RungeKuttaMethod{T, MatT<:AbstractMatrix{T}, VecT<:AbstractVector{T}} <: AbstractTimeIntegrationMethod
  A::MatT
  b::VecT
  c::VecT
end

function RungeKuttaMethod(A::AbstractMatrix, b::AbstractVector, c::AbstractVector=vec(sum(A, dims=2)))
  T = promote_type(eltype(A), eltype(b), eltype(c))
  _A = T.(A)
  _b = T.(b)
  _c = T.(c)
  return RungeKuttaMethod(_A, _b, _c)
end

Base.eltype(rk::RungeKuttaMethod{T}) where {T} = T

function Base.show(io::IO, rk::RungeKuttaMethod)
  print(io, "RungeKuttaMethod{", eltype(rk), "}")
  if get(io, :compact, false)
    print(io, "(")
    show(io, rk.A)
    print(io, ", ")
    show(io, rk.b)
    print(io, ", ")
    show(io, rk.c)
    print(io, ")")
  else
    print(io, " with\nA: ")
    show(io, MIME"text/plain"(), rk.A)
    print(io, "\nb: ")
    show(io, MIME"text/plain"(), rk.b)
    print(io, "\nc: ")
    show(io, MIME"text/plain"(), rk.c)
    print(io, "\n")
  end
end


"""
    elementary_weight(t::RootedTree, rk::RungeKuttaMethod)
    elementary_weight(t::RootedTree, A::AbstractMatrix, b::AbstractVector, c::AbstractVector)

Compute the elementary weight Φ(`t`) of the [`RungeKuttaMethod`](@ref) `rk`
with Butcher coefficients `A, b, c` for a rooted tree `t``.

Reference: Section 312 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function elementary_weight(t::RootedTree, rk::RungeKuttaMethod)
  dot(rk.b, derivative_weight(t, rk))
end

# TODO: Deprecate also this method?
function elementary_weight(t::RootedTree, A::AbstractMatrix, b::AbstractVector, c::AbstractVector)
  elementary_weight(t, RungeKuttaMethod(A, b, c))
end


"""
    derivative_weight(t::RootedTree, rk::RungeKuttaMethod)

Compute the derivative weight (ΦᵢD)(`t`) of the [`RungeKuttaMethod`](@ref) `rk`
with Butcher coefficients `A, b, c` for the rooted tree `t`.

Reference: Section 312 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function derivative_weight(t::RootedTree, rk::RungeKuttaMethod)
  A = rk.A
  c = rk.c

  # Initialize `result` with the identity element of pointwise multiplication `.*`
  result = zero(c) .+ one(eltype(c))

  # Iterate over all subtrees and update the `result` using recursion
  for subtree in SubtreeIterator(t)
    tmp = A * derivative_weight(subtree, rk)
    result = result .* tmp
  end

  return result
end

# TODO: Deprecations introduced in v2
@deprecate derivative_weight(t::RootedTree, A, b, c) derivative_weight(t, RungeKuttaMethod(A, b, c))


"""
    residual_order_condition(t::RootedTree, rk::RungeKuttaMethod)

The residual of the order condition
  `(Φ(t) - 1/γ(t)) / σ(t)`
with [`elementary_weight`](@ref) `Φ(t)`, [`density`](@ref) `γ(t)`, and
[`symmetry`](@ref) `σ(t)` of the [`RungeKuttaMethod`](@ref) `rk` with Butcher
coefficients `A, b, c` for the rooted tree `t`.

Reference: Section 315 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function residual_order_condition(t::RootedTree, rk::RungeKuttaMethod)
  ew = elementary_weight(t, rk)
  T = typeof(ew)

  (ew - one(T) / γ(t)) / σ(t)
end

# TODO: Deprecations introduced in v2
@deprecate residual_order_condition(t::RootedTree, A, b, c) residual_order_condition(t, RungeKuttaMethod(A, b, c))



"""
    AdditiveRungeKuttaMethod(rks)
    AdditiveRungeKuttaMethod(As, bs, cs=map(A -> vec(sum(A, dims=2)), As))

Represent an additive Runge-Kutta method with collections of Butcher
coefficients `As`, `bs`, and `cs`. Alternatively, you can pass a collection of
[`RungeKuttaMethod`](@ref)s to the constructor.
If the `cs` are not provided, the usual "row sum" requirement of consistency
with autonomous problems is applied.

An additive Runge-Kutta method applied to the ODE problem
```math
  u'(t) = \\sum_\\nu f^\\nu(t, u(t))
```
has the form
```math
\\begin{aligned}
  y^i &= u^n + \\Delta t \\sum_\\nu \\sum_j a^\\nu_{i,j} f^\\nu(y^i), \\\\
  u^{n+1} &= u^n + \\Delta t \\sum_\\nu \\sum_i b^\\nu_{i} f^\\nu(y^i).
\\end{aligned}
```

In particular, additive Runge-Kutta methods are a superset of partitioned RK
methods, which are applied to partitioned problems of the form
```math
  (u^1)'(t) = f^1(t, u^1, u^2),
  \\quad
  (u^2)'(t) = f^2(t, u^1, u^2).
```

# References

- A. L. Araujo, A. Murua, and J. M. Sanz-Serna.
  "Symplectic Methods Based on Decompositions".
  SIAM Journal on Numerical Analysis 34.5 (1997): 1926-1947.
  [DOI: 10.1137/S0036142995292128](https://doi.org/10.1137/S0036142995292128)
"""
struct AdditiveRungeKuttaMethod{T, RKs<:AbstractVector{<:RungeKuttaMethod{T}}} <: AbstractTimeIntegrationMethod
  rks::RKs
end

function AdditiveRungeKuttaMethod(rks) # if not all RK methods use the same eltype
  T = mapreduce(eltype, promote_type, rks)
  As = map(rk -> T.(rk.A), rks)
  bs = map(rk -> T.(rk.b), rks)
  cs = map(rk -> T.(rk.c), rks)
  AdditiveRungeKuttaMethod(As, bs, cs)
end

function AdditiveRungeKuttaMethod(As, bs, cs=map(A -> vec(sum(A, dims=2)), As))
  rks = map(RungeKuttaMethod, As, bs, cs)
  AdditiveRungeKuttaMethod(rks)
end

Base.eltype(ark::AdditiveRungeKuttaMethod{T}) where {T} = T

function Base.show(io::IO, ark::AdditiveRungeKuttaMethod)
  print(io, "AdditiveRungeKuttaMethod{", eltype(ark), "} with methods\n")
  for (idx, rk) in enumerate(ark.rks)
    print(io, idx, ". ")
    show(io, rk)
  end
end


# Colored trees are used for order conditions of additive Runge-Kutta methods.
# The function `color_to_index` maps a color to a one-based index of ARK
# coefficients.
# This is considered to be an internal interface but stable across minor/patch
# releases.
color_to_index(color::Integer) = Int(color)
color_to_index(color::Bool) = 1 + color


"""
    elementary_weight(t::ColoredRootedTree, ark::AdditiveRungeKuttaMethod)

Compute the elementary weight Φ(`t`) of the [`AdditiveRungeKuttaMethod`](@ref)
`ark` for a colored rooted tree `t``.

# References

- A. L. Araujo, A. Murua, and J. M. Sanz-Serna.
  "Symplectic Methods Based on Decompositions".
  SIAM Journal on Numerical Analysis 34.5 (1997): 1926–1947.
  [DOI: 10.1137/S0036142995292128](https://doi.org/10.1137/S0036142995292128)
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
  Section 312
"""
function elementary_weight(t::ColoredRootedTree, ark::AdditiveRungeKuttaMethod)
  # TODO: Check number of RK methods in `ark`?
  if isempty(t)
    return one(eltype(first(ark.rks).c))
  else
    color = first(t.color_sequence)
    dot(ark.rks[color_to_index(color)].b, derivative_weight(t, ark))
  end
end


"""
    derivative_weight(t::ColoredRootedTree, ark::AdditiveRungeKuttaMethod)

Compute the derivative weight (ΦᵢD)(`t`) of the [`AdditiveRungeKuttaMethod`](@ref)
`ark` for the colored rooted tree `t`.

# References

- A. L. Araujo, A. Murua, and J. M. Sanz-Serna.
  "Symplectic Methods Based on Decompositions".
  SIAM Journal on Numerical Analysis 34.5 (1997): 1926–1947.
  [DOI: 10.1137/S0036142995292128](https://doi.org/10.1137/S0036142995292128)
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
  Section 312
"""
function derivative_weight(t::ColoredRootedTree, ark::AdditiveRungeKuttaMethod)
  # Initialize `result` with the identity element of pointwise multiplication `.*`
  c = first(ark.rks).c
  result = zero(c) .+ one(eltype(c))

  # Iterate over all subtrees and update the `result` using recursion
  for subtree in SubtreeIterator(t)
    A = ark.rks[color_to_index(first(subtree.color_sequence))].A
    tmp = A * derivative_weight(subtree, ark)
    result = result .* tmp
  end

  return result
end


"""
    residual_order_condition(t::ColoredRootedTree, ark::AdditiveRungeKuttaMethod)

The residual of the order condition
  `(Φ(t) - 1/γ(t)) / σ(t)`
with [`elementary_weight`](@ref) `Φ(t)`, [`density`](@ref) `γ(t)`, and
[`symmetry`](@ref) `σ(t)` of the [`AdditiveRungeKuttaMethod`](@ref) `ark`
for the colored rooted tree `t`.

# References

- A. L. Araujo, A. Murua, and J. M. Sanz-Serna.
  "Symplectic Methods Based on Decompositions".
  SIAM Journal on Numerical Analysis 34.5 (1997): 1926–1947.
  [DOI: 10.1137/S0036142995292128](https://doi.org/10.1137/S0036142995292128)
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
  Section 312
"""
function residual_order_condition(t::ColoredRootedTree, ark::AdditiveRungeKuttaMethod)
  ew = elementary_weight(t, ark)
  T = typeof(ew)

  (ew - one(T) / γ(t)) / σ(t)
end

