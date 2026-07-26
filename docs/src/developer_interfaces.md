# Developer Interfaces

`RootedTrees.jl` exposes concrete tree types and iterator types for use in
generic Julia code. This page records the supported contracts. It does not make
the package's internal abstract supertypes extension APIs.

## Iterator contract

[`RootedTreeIterator`](@ref), [`BicoloredRootedTreeIterator`](@ref),
[`PartitionForestIterator`](@ref), [`PartitionIterator`](@ref), and
[`SplittingIterator`](@ref) implement Julia's standard iterator interface:

- `iterate(iter)` starts iteration and `iterate(iter, state)` advances it.
- `eltype(iter)` describes each yielded value.
- `length(iter)` returns the exact number of yielded values.

These iterators are intended to be consumed by generic code using those Base
functions. Several implementations reuse mutable buffers to avoid allocations:
`RootedTreeIterator`, `BicoloredRootedTreeIterator`,
`PartitionForestIterator`, `PartitionIterator`, and `SplittingIterator` may
mutate a previously yielded tree, forest, or skeleton when advanced. Copy data
before storing it or passing it to asynchronous work.

## Tree implementation boundary

`AbstractRootedTree` and `AbstractTimeIntegrationMethod` are internal
classification types. They are deliberately not exported and have no stable
third-party-subtyping contract. The algorithms that dispatch on
`AbstractRootedTree` require package-specific state, canonicalization, and
subtree-iteration operations; `AbstractTimeIntegrationMethod` is only a shared
supertype for the package's own coefficient containers. Use the documented
concrete types and public functions instead of extending either abstract type.
