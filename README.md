# RootedTrees

[![Docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SciML.github.io/RootedTrees.jl/stable)
[![Docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SciML.github.io/RootedTrees.jl/dev)
[![Build Status](https://github.com/SciML/RootedTrees.jl/workflows/CI/badge.svg)](https://github.com/SciML/RootedTrees.jl/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/SciML/RootedTrees.jl/badge.svg?branch=main)](https://coveralls.io/github/SciML/RootedTrees.jl?branch=main)
[![codecov](https://codecov.io/gh/SciML/RootedTrees.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/SciML/RootedTrees.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5534590.svg)](https://doi.org/10.5281/zenodo.5534590)
[![Downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/RootedTrees)](https://pkgs.genieframework.com?packages=RootedTrees)

A collection of functionality around rooted trees to generate order conditions
for Runge-Kutta methods in [Julia](https://julialang.org/).
This package also provides basic functionality for
[BSeries.jl](https://github.com/ranocha/BSeries.jl).


## API Documentation

The API of RootedTrees.jl is documented in the following. Additional information
on each function is available in their docstrings and in the
[online documentation](https://SciML.github.io/RootedTrees.jl/stable).

### Construction

`RootedTree`s are represented using level sequences, i.e., `AbstractVector`s
containing the distances of the nodes from the root, see

- Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)

`RootedTree`s can be constructed from their level sequence using
```julia
julia> t = rootedtree([1, 2, 3, 2])
RootedTree{Int64}: [1, 2, 3, 2]
```
In the notation of [Butcher (Numerical Methods for ODEs, 2016)](https://doi.org/10.1002/9781119121534),
this tree can be written as `[[τ] τ]` or `(τ ∘ τ) ∘ (τ ∘ τ)`, where
`∘` is the non-associative Butcher product of `RootedTree`s, which is also
implemented.

To get the representation of a `RootedTree` introduced by Butcher, use `butcher_representation`:
```julia
julia> t = rootedtree([1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2])
RootedTree{Int64}: [1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2]

julia> butcher_representation(t)
"[[[τ]τ²]τ⁵]"
```

There are also some simple plot recipes for [Plots.jl](https://github.com/JuliaPlots/Plots.jl).
Thus, you can visualize a rooted tree `t` using `plot(t)` when `using Plots`.

Additionally, there is an un-exported function `RootedTrees.latexify` that can
generate LaTeX code for a rooted tree `t` based on the LaTeX package
[forest](https://ctan.org/pkg/forest). The relevant code that needs to be included
in the preamble can be obtained from the docstring of `RootedTrees.latexify`
(type `?` and `RootedTrees.latexify` in the Julia REPL). The same format is
used when you are `using Latexify` and their function `latexify`, see
[Latexify.jl](https://github.com/korsbo/Latexify.jl).

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


## Referencing

If you use
[RootedTrees.jl](https://github.com/SciML/RootedTrees.jl)
for your research, please cite the paper
```bibtex
@online{ketcheson2021computing,
  title={Computing with {B}-series},
  author={Ketcheson, David I and Ranocha, Hendrik},
  year={2021},
  month={11},
  eprint={2111.11680},
  eprinttype={arXiv},
  eprintclass={math.NA}
}
```
In addition, you can also refer to RootedTrees.jl directly as
```bibtex
@misc{ranocha2019rootedtrees,
  title={{RootedTrees.jl}: {A} collection of functionality around rooted trees
         to generate order conditions for {R}unge-{K}utta methods in {J}ulia
         for differential equations and scientific machine learning ({SciM}L)},
  author={Ranocha, Hendrik and contributors},
  year={2019},
  month={05},
  howpublished={\url{https://github.com/SciML/RootedTrees.jl}},
  doi={10.5281/zenodo.5534590}
}
```
