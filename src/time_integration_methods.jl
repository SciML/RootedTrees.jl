
"""
    RungeKuttaMethod(A, b, c=vec(sum(A, dims=2)))

Represent a Runge-Kutta method with Butcher coefficients `A`, `b`, and `c`.
If `c` is not provided, the usual "row sum" requirement of consistency with
autonomous problems is applied.
"""
struct RungeKuttaMethod{T, MatT<:AbstractMatrix{T}, VecT<:AbstractVector{T}}
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

function Base.show(io::IO, rk::RungeKuttaMethod{T}) where {T}
  print(io, "RungeKuttaMethod{", T, "}")
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
    AdditiveRungeKuttaMethod(rks)
    AdditiveRungeKuttaMethod(As, bs, cs=map(A -> vec(sum(A, dims=2)), As))

Represent an additive Runge-Kutta method with collections of Butcher
coefficients `As`, `bs`, and `cs`. Alternatively, you can pass a collection of
[`RungeKuttaMethod`](@ref)s to the constructor.
If the `cs` are not provided, the usual "row sum" requirement of consistency
with autonomous problems is applied.

An additive Runge-Kutta method applied to the ODE problem
```math
  u'(t) = \\sum_\nu f^\\nu(u)
```
has the form
```math
\\begin{aligned}
  y^i &= u^n + \\Delta t \\sum_\\nu \\sum_j a^\\nu_{i,j} f^\\nu(y^i), \\
  u^{n+1} &= u^n + \\Delta t \\sum_\\nu \\sum_i b^\\nu_{i} f^\\nu(y^i).
\\end{aligned}
```

# References

- A. L. Araujo, A. Murua, and J. M. Sanz-Serna.
  "Symplectic Methods Based on Decompositions".
  SIAM Journal on Numerical Analysis 34.5 (1997): 1926–1947.
  [DOI: 10.1137/S0036142995292128](https://doi.org/10.1137/S0036142995292128)
"""
struct AdditiveRungeKuttaMethod{T, RKs<:AbstractVector{<:RungeKuttaMethod{T}}}
  rks::RKs
end

function AdditiveRungeKuttaMethod(As, bs, cs=map(A -> vec(sum(A, dims=2)), As))
  rks = map(RungeKuttaMethod, As, bs, cs)
  AdditiveRungeKuttaMethod(rks)
end

function Base.show(io::IO, ark::AdditiveRungeKuttaMethod{T}) where {T}
  print(io, "AdditiveRungeKuttaMethod{", T, "} with methods\n")
  for (idx, rk) in enumerate(ark.rks)
    print(io, idx, ". ")
    show(io, rk)
  end
end

