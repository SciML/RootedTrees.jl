# Developer Interfaces

`RootedTrees.jl` exposes concrete tree types and iterator types for use in
generic Julia code. This page records the supported contracts and the boundary
between those contracts and implementation details.

## Tree contract

The supported tree inputs are [`RootedTree`](@ref),
[`ColoredRootedTree`](@ref), and its [`BicoloredRootedTree`](@ref) alias. Create
them with [`rootedtree`](@ref) or [`rootedtree!`](@ref) so that the level
sequence is validated and canonicalized.

Code consuming a tree generically should use the public functions below:

- [`order`](@ref) returns the number of nodes.
- [`SubtreeIterator`](@ref) traverses the child subtrees without requiring a
  concrete tree type.
- [`symmetry`](@ref), [`density`](@ref), [`α`](@ref), and [`β`](@ref) compute
  standard tree invariants.
- [`root_color`](@ref) reads the root color of a colored tree.
- [`partition_skeleton`](@ref) and [`PartitionIterator`](@ref) expose the
  partition interface for rooted and colored trees.

Consumers must not assume that a tree's `level_sequence` is an ordinary
one-based `Vector`, or that a yielded tree owns its storage. Use
[`rootedtree`](@ref) to make an owned canonical copy when that is required.

`AbstractRootedTree` and `AbstractTimeIntegrationMethod` are internal
classification types. They are deliberately not exported and do not define a
stable third-party subtyping contract. The package's algorithms rely on
canonicalization, copying, and internal tree-buffer operations that are not
part of the public extension surface. External code should use the concrete
types and public functions above rather than subtype either abstract type.

## Iterator contract

[`RootedTreeIterator`](@ref), [`BicoloredRootedTreeIterator`](@ref),
[`PartitionForestIterator`](@ref), [`PartitionIterator`](@ref), and
[`SplittingIterator`](@ref) implement the standard Julia iterator interface:

- `iterate(iter)` starts iteration and `iterate(iter, state)` advances it.
- `eltype(iter)` describes each yielded value.
- `length(iter)` returns the exact number of yielded values.

`PartitionIterator` yields `(forest_iterator, skeleton)` pairs, while
`SplittingIterator` yields `(forest, subtree)` pairs. The other iterators yield
trees. These iterators are intended to be consumed through generic Base
functions such as `iterate`, `length`, `eltype`, `for`, and `collect`.

[`SubtreeIterator`](@ref) is the exception: it is a lazy traversal helper that
guarantees only the two-argument `iterate` protocol. It intentionally does not
provide `length` or `eltype`; consume it with a `for` loop or a manual generic
`iterate` loop.

Several implementations reuse mutable buffers to avoid allocations.
`RootedTreeIterator`, `BicoloredRootedTreeIterator`,
`PartitionForestIterator`, `PartitionIterator`, and `SplittingIterator` may
mutate a previously yielded tree, forest, or skeleton when advanced. Copy data
before storing it or passing it to asynchronous work. `SubtreeIterator` may
also yield views into the input tree.

## Generic usage

The interface tests exercise consumers that only call the public operations
above. A generic consumer should accept a tree or iterator without dispatching
on its concrete representation, for example:

```julia
function count_items(iter)
    state = iterate(iter)
    result = 0
    while state !== nothing
        result += 1
        state = iterate(iter, last(state))
    end
    return result
end
```

Do not call internal functions such as `canonical_representation!`,
`unsafe_resize!`, or `unsafe_copyto!` from downstream code. They are used by the
package's own implementations and may change without a public API guarantee.
