# Introduction

[`RootedTree`](@ref)s are useful to analyze properties of time integration
methods such as Runge-Kutta methods. Some common references introducing them
are
- John Charles Butcher.
  "Numerical methods for ordinary differential equations".
  John Wiley & Sons, 2016.
  [DOI: 10.1002/9780470753767](https://doi.org/10.1002/9780470753767)
- Ernst Hairer, Gerhard Wanner, Syvert P. Nørsett.
  "Solving Ordinary Differential Equations I".
  Springer, 1993.
  [DOI: 10.1007/978-3-540-78862-1](https://doi.org/10.1007/978-3-540-78862-1)
- Ernst Hairer, Gerhard Wanner.
  "Solving Ordinary Differential Equations II".
  Springer, 1996.
  [DOI: 10.1007/978-3-642-05221-7](https://doi.org/10.1007/978-3-642-05221-7)
- Ernst Hairer, Gerhard Wanner, Christian Lubich.
  "Geometric Numerical Integration".
  Springer, 2006.
  [DOI: 10.1007/3-540-30666-8](https://doi.org/10.1007/3-540-30666-8)


## Construction

[`RootedTree`](@ref)s are represented using level sequences, i.e., `AbstractVector`s
containing the distances of the nodes from the root, see

- Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)

[`RootedTree`](@ref)s can be constructed from their level sequence using
```julia
julia> t = rootedtree([1, 2, 3, 2])
RootedTree{Int64}: [1, 2, 3, 2]
```
In the notation of [Butcher (Numerical Methods for ODEs, 2016)](https://doi.org/10.1002/9781119121534),
this tree can be written as `[[τ] τ]` or `(τ ∘ τ) ∘ (τ ∘ τ)`, where
`∘` is the non-associative Butcher product of [`RootedTree`](@ref)s, which is also
implemented.

To get the representation of a [`RootedTree`](@ref) introduced by Butcher, use `butcher_representation`:
```julia
julia> t = rootedtree([1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2])
RootedTree{Int64}: [1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2]

julia> butcher_representation(t)
"[[[τ]τ²]τ⁵]"
```

You can use the function [`RootedTrees.set_printing_style`](@ref) to change the
printing style globally. For example,
```@repl
t = rootedtree([1, 2, 3, 4, 3, 3, 2, 2, 2, 2, 2])
RootedTrees.set_printing_style("butcher")
t
RootedTrees.set_printing_style("sequence")
t
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


## Iteration over [`RootedTree`](@ref)s

A `RootedTreeIterator(order::Integer)` can be used to iterate efficiently
over all [`RootedTree`](@ref)s of a given `order`.

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


## Functions on Trees

The usual functions on [`RootedTree`](@ref)s are implemented, cf.
[Butcher (Numerical Methods for ODEs, 2016)](https://doi.org/10.1002/9781119121534).
- `order(t::RootedTree)`: The order of a [`RootedTree`](@ref), i.e., the length of its level sequence.
- `σ(t::RootedTree)` or `symmetry(t)`: The symmetry `σ` of a rooted tree, i.e., the order of the group of automorphisms on a particular labelling (of the vertices) of `t`.
- `γ(t::RootedTree)` or `density(t)`: The density `γ(t)` of a rooted tree, i.e., the product over all vertices of `t` of the order of the subtree rooted at that vertex.
- `α(t::RootedTree)`: The number of monotonic labelings of `t` not equivalent under the symmetry group.
- `β(t::RootedTree)`: The total number of labelings of `t` not equivalent under the symmetry group.

Additionally, functions on trees connected to Runge-Kutta methods are implemented.
- `elementary_weight(t, A, b, c)`: Compute the elementary weight Φ(`t`) of `t::RootedTree` for the Butcher coefficients `A, b, c` of a Runge-Kutta method.
- `derivative_weight(t, A, b, c)`: Compute the derivative weight (ΦᵢD)(`t`) of `t` for the Butcher coefficients `A, b, c` of a Runge-Kutta method.
- `residual_order_condition(t, A, b, c)`: The residual of the order condition
  `(Φ(t) - 1/γ(t)) / σ(t)` with elementary weight `Φ(t)`, density `γ(t)`, and symmetry `σ(t)` of the rooted tree `t` for the Runge-Kutta method with Butcher coefficients `A, b, c`.

