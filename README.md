# RootedTrees

[![Build Status](https://github.com/SciML/RootedTrees.jl/workflows/CI/badge.svg)](https://github.com/SciML/RootedTrees.jl/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/SciML/RootedTrees.jl/badge.svg?branch=main)](https://coveralls.io/github/SciML/RootedTrees.jl?branch=main)
[![codecov](https://codecov.io/gh/SciML/RootedTrees.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/SciML/RootedTrees.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](https://opensource.org/licenses/MIT)

A collection of functionality around rooted trees to generate order conditions
for Runge-Kutta methods in [Julia](https://julialang.org/).


## API Documentation

Please note that this project is work in progress. However, we don't expect
many breaking changes in the near future.

### Construction

`RootedTree`s are represented using level sequences, i.e., `AbstractVector`s
containing the distances of the nodes from the root, see

- Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)

`RootedTree`s can be constructed from their level sequence using
```julia
julia> t = rootedtree([1, 2, 3, 2])
RootedTree{Int64}: [1, 2, 3, 2]
```
In the notation of [Butcher (Numerical Methods for ODEs, 2016)](https://doi.org/10.1002/9781119121534),
this tree can be written as `[[τ²] τ]` or `(τ ∘ τ) ∘ (τ ∘ τ)`, where
`∘` is the non-associative Butcher product of `RootedTree`s, which is also
implemented.

To get the representation of a `RootedTree` introduced by Butcher, use `butcher_representation`:
```julia
julia> t = rootedtree([1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2])
RootedTree{Int64}: [1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2]

julia> butcher_representation(t)
"[[[τ]τ²]τ⁵]"
```

There are also some simple plot recipes for
[Plots.jl](https://github.com/JuliaPlots/Plots.jl).
Thus, you can visualize a rooted tree `t` using `plot(t)` when `using Plots`.

### Iteration over `RootedTree`s

A `RootedTreeIterator(order::Integer)` can be used to iterate efficiently
over all `RootedTree`s of a given `order`.

Be careful that the iterator is stateful for efficiency reasons, so you might
need to use `copy` appropriately, e.g.,
```julia
julia> map(identity, RootedTreeIterator(4))
4-element Array{RootedTrees.RootedTree{Int64,Array{Int64,1}},1}:
 RootedTree{Int64}: [1, 2, 2, 2]
 RootedTree{Int64}: [1, 2, 2, 2]
 RootedTree{Int64}: [1, 2, 2, 2]
 RootedTree{Int64}: [1, 2, 2, 2]

julia> map(copy, RootedTreeIterator(4))
4-element Array{RootedTrees.RootedTree{Int64,Array{Int64,1}},1}:
 RootedTree{Int64}: [1, 2, 3, 4]
 RootedTree{Int64}: [1, 2, 3, 3]
 RootedTree{Int64}: [1, 2, 3, 2]
 RootedTree{Int64}: [1, 2, 2, 2]
```

### Functions on Trees

The usual functions on `RootedTree`s are implemented, cf.
[Butcher (Numerical Methods for ODEs, 2016)](https://doi.org/10.1002/9781119121534).
- `order(t::RootedTree)`: The order of a `RootedTree`, i.e., the length of its level sequence.
- `σ(t::RootedTree)` or `symmetry(t)`: The symmetry `σ` of a rooted tree, i.e., the order of the group of automorphisms on a particular labelling (of the vertices) of `t`.
- `γ(t::RootedTree)` or `density(t)`: The density `γ(t)` of a rooted tree, i.e., the product over all vertices of `t` of the order of the subtree rooted at that vertex.
- `α(t::RootedTree)`: The number of monotonic labelings of `t` not equivalent under the symmetry group.
- `β(t::RootedTree)`: The total number of labelings of `t` not equivalent under the symmetry group.

Additionally, functions on trees connected to Runge-Kutta methods are implemented.
- `elementary_weight(t, A, b, c)`: Compute the elementary weight Φ(`t`) of `t::RootedTree` for the Butcher coefficients `A, b, c` of a Runge-Kutta method.
- `derivative_weight(t, A, b, c)`: Compute the derivative weight (ΦᵢD)(`t`) of `t` for the Butcher coefficients `A, b, c` of a Runge-Kutta method.
- `residual_order_condition(t, A, b, c)`: The residual of the order condition
  `(Φ(t) - 1/γ(t)) / σ(t)` with elementary weight `Φ(t)`, density `γ(t)`, and symmetry `σ(t)` of the rooted tree `t` for the Runge-Kutta method with Butcher coefficients `A, b, c`.


## Brief Changelog

- v2.0: Rooted trees are considered up to isomorphisms introduced by shifting
  each coefficient of their level sequence by the same number.
