module RootedTrees

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) RootedTrees


using LinearAlgebra: dot

using Latexify: Latexify
using RecipesBase: RecipesBase
using Requires: @require


export RootedTree, rootedtree, rootedtree!, RootedTreeIterator,
       ColoredRootedTree, BicoloredRootedTree, BicoloredRootedTreeIterator

export butcher_representation

export α, β, γ, density, σ, symmetry, order, root_color

export residual_order_condition, elementary_weight, derivative_weight

export count_trees

export partition_forest, PartitionForestIterator,
       partition_skeleton,
       all_partitions, PartitionIterator

export all_splittings, SplittingIterator

export RungeKuttaMethod, AdditiveRungeKuttaMethod


abstract type AbstractRootedTree end


"""
    RootedTree(level_sequence, is_canonical::Bool=false)

Represents a rooted tree using its level sequence.

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
struct RootedTree{T<:Integer, V<:AbstractVector{T}} <: AbstractRootedTree
  level_sequence::V
  iscanonical::Bool

  function RootedTree(level_sequence::V, iscanonical::Bool=false) where {T<:Integer, V<:AbstractVector{T}}
    new{T, V}(level_sequence, iscanonical)
  end
end

"""
    rootedtree(level_sequence)

Construct a canonical [`RootedTree`](@ref) object from a `level_sequence`, i.e.,
a vector of integers representing the levels of each node of the tree.

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
rootedtree(level_sequence::AbstractVector) = canonical_representation(RootedTree(level_sequence))

"""
    rootedtree!(level_sequence)

Construct a canonical `RootedTree` object from a `level_sequence` which may be
modified in this process. See also [`rootedtree`](@ref).

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
rootedtree!(level_sequence::AbstractVector) = canonical_representation!(RootedTree(level_sequence))

iscanonical(t::RootedTree) = t.iscanonical
#TODO: Validate rooted tree in constructor?

Base.copy(t::RootedTree) = RootedTree(copy(t.level_sequence), t.iscanonical)
Base.similar(t::RootedTree) = RootedTree(similar(t.level_sequence), true)
Base.isempty(t::RootedTree) = isempty(t.level_sequence)
Base.empty(t::RootedTree) = RootedTree(empty(t.level_sequence), iscanonical(t))

@inline function Base.copy!(t_dst::RootedTree, t_src::RootedTree)
  copy!(t_dst.level_sequence, t_src.level_sequence)
  return t_dst
end

"""
    unsafe_deleteat!(t::AbstractRootedTree, i)

Delete the node `i` from the rooted tree `t`. This is an unsafe operation
since the rooted tree will not necessarily be in canonical representation
afterwards, even if the corresponding flag of `t` is set. Use with caution!

!!! warning "Internal interface"
    This function is considered to be an internal implementation detail and
    will not necessarily be stable.
"""
@inline function unsafe_deleteat!(t::RootedTree, i)
  deleteat!(t.level_sequence, i)
  return t
end

"""
    unsafe_resize!(t::AbstractRootedTree, n::Integer)

Resize the rooted tree `t` to `n` nodes. This is an unsafe operation
since the rooted tree will not necessarily be in canonical representation
afterwards, even if the corresponding flag of `t` is set. Use with caution!

!!! warn "Internal interface"
    This function is considered to be an internal implementation detail and
    will not necessarily be stable.
"""
@inline function unsafe_resize!(t::RootedTree, n::Integer)
  resize!(t.level_sequence, n)
  return t
end

"""
    unsafe_copyto!(t_dst::AbstractRootedTree, dst_offset,
                   t_src::AbstractRootedTree, src_offset, N)

Copy `N` nodes from `t_src` starting at offset `src_offset` to `t_dst`
starting at offset `dst_offset`. The types of the rooted trees must match.
For example, you cannot copy a [`ColoredRootedTree`](@ref) to a
[`RootedTree`](@ref).

This is an unsafe operation since the rooted tree `t_dst` will not necessarily
be in canonical representation afterwards, even if the corresponding flag
of `t_dst` is set. Use with caution!

!!! warning "Internal interface"
    This function is considered to be an internal implementation detail and
    will not necessarily be stable.
"""
@inline function unsafe_copyto!(t_dst::RootedTree, dst_offset,
                                t_src::RootedTree, src_offset, N)
  copyto!(t_dst.level_sequence, dst_offset, t_src.level_sequence, src_offset, N)
  return t_dst
end


#  #function RootedTree(sequence::Vector{T}, valid::Bool)
#  function RootedTree(sequence::Array{T,1})
#    length(sequence) < 1 && throw(ArgumentError("Rooted trees must have a root, in particular at least one element!"))#
#
#    ## If there is only one element, the sequence must be valid.
#    #if !valid && length(sequence) > 1
#    #  # Test, whether there is exactly one root element at the beginning of sequence, if necessary.
#    #  root = sequence[1]
#    #  for level in sequence[2:end]
#    #    level <= root && throw(ArgumentError("Rooted trees must have exactly one element at root level at the beginning."))
#    #  end
#    #end
#    # If there is only one element, the sequence must be valid.
#    if length(sequence) > 1
#      # Test, whether there is exactly one root element at the beginning of sequence, if necessary.
#      root = sequence[1]
#      for level in sequence[2:end]
#        level <= root && throw(ArgumentError("Rooted trees must have exactly one element at root level at the beginning."))
#      end
#    end
#
#    new(sequence)
#  end
#RootedTree{T<:Integer}(sequence::Vector{T}) = RootedTree{T}(sequence, false)


function Base.show(io::IO, t::RootedTree{T}) where {T}
  print(io, "RootedTree{", T, "}: ")
  show(io, t.level_sequence)
end


# comparison

"""
    isless(t1::RootedTree, t2::RootedTree)

Compares two rooted trees using a lexicographical comparison of their level
sequences while considering equivalence classes given by different root indices.
"""
function Base.isless(t1::RootedTree, t2::RootedTree)
  if isempty(t1.level_sequence)
    if isempty(t2.level_sequence)
      # empty trees are equal
      return false
    else
      # the empty tree `isless` than any other tree
      return true
    end
  elseif isempty(t2.level_sequence)
    # the empty tree `isless` than any other tree
    return false
  end

  root1_minus_root2 = first(t1.level_sequence) - first(t2.level_sequence)
  for (e1, e2) in zip(t1.level_sequence, t2.level_sequence)
    v1 = e1
    v2 = e2 + root1_minus_root2
    v1 == v2 || return isless(v1, v2)
  end
  return isless(length(t1.level_sequence), length(t2.level_sequence))
end

"""
    ==(t1::RootedTree, t2::RootedTree)

Compares two rooted trees based on their level sequences while considering
equivalence classes given by different root indices.

# Examples

```jldoctest
julia> t1 = rootedtree([1, 2, 3]);

julia> t2 = rootedtree([2, 3, 4]);

julia> t3 = rootedtree([1, 2, 2]);

julia> t1 == t2
true

julia> t1 == t3
false
```
"""
function Base.:(==)(t1::RootedTree, t2::RootedTree)
  length(t1.level_sequence) == length(t2.level_sequence) || return false

  if isempty(t1.level_sequence)
    # empty trees are equal
    return true
  end

  root1_minus_root2 = first(t1.level_sequence) - first(t2.level_sequence)
  for (e1, e2) in zip(t1.level_sequence, t2.level_sequence)
    e1 == e2 + root1_minus_root2 || return false
  end

  return true
end


# Factor out equivalence classes given by different roots
function Base.hash(t::RootedTree, h::UInt)
  # Use a fast path if possible
  if UInt == UInt64 && length(t.level_sequence) <= 16
    return simple_hash(t, h)
  end

  isempty(t.level_sequence) && return h
  root = first(t.level_sequence)
  for l in t.level_sequence
    h = hash(l - root, h)
  end
  return h
end

# Map the level sequence to an unsigned integer by concatenating the bit
# representations of level sequence differences. If the level sequence increases
# from one vertex to the next, it can increase at most by unity. Since we want
# to use simple bits representations, we measure the decrease compared to the
# maximal possible increase.
# The maximal drop in the level sequence is
#   maximal_drop = length(t.level_sequence) - 3
# We need at most
#   number_of_bits = trunc(Int, log2(maximal_drop)) + 1
# bits to represent this. Thus, 64 bit allow us to compute unique hashes for
# level sequence up to length 16 in the following simple way; 64 bit result
# in `number_of_bits = 4` for `maximal_drop = 16 - 3 = 13`.
# For 32 bits, we could use a maximal length of 10 with `number_of_bits = 3`.
# However, most user systems should use 64 bit by default, so we only implement
# this option for simplicity.
@inline function simple_hash(t::RootedTree, h_base::UInt64)
  isempty(t.level_sequence) && return h_base
  h = zero(h_base)
  l_prev = first(t.level_sequence)
  for l in t.level_sequence
    h = (h << 4) | (l_prev + 1 - l)
    l_prev = l
  end
  return hash(h, h_base)
end


# generation and canonical representation
"""
    canonical_representation(t::AbstractRootedTree)

Returns a new tree using the canonical representation of the rooted tree `t`,
i.e., the one with lexicographically biggest level sequence.

See also [`canonical_representation!`](@ref).
"""
function canonical_representation(t::AbstractRootedTree)
  canonical_representation!(copy(t))
end

# A very simple implementation of `canonical_representation!` could read as
# follows.
#   function canonical_representation!(t::RootedTree)
#     subtr = subtrees(t)
#     for i in eachindex(subtr)
#       canonical_representation!(subtr[i])
#     end
#     sort!(subtr, rev=true)
#
#     i = 2
#     for τ in subtr
#       t.level_sequence[i:i+order(τ)-1] = τ.level_sequence
#       i += order(τ)
#     end
#
#     RootedTree(t.level_sequence, true)
#   end
# However, this would create a lot of intermediate allocations, which make it
# rather slow. Since most trees in use are relatively small, we can use a
# non-allocating sorting algorithm instead - although bubble sort is slower in
# general when comparing the complexity with quicksort etc., it will be faster
# here since we can avoid allocations.
"""
    canonical_representation!(t::AbstractRootedTree)

Change the representation of the rooted tree `t` to the canonical one, i.e., the
one with lexicographically biggest level sequence.

See also [`canonical_representation`](@ref).
"""
function canonical_representation!(t::RootedTree, buffer=similar(t.level_sequence))
  # Since we use a recursive implementation, it is useful to exit early for
  # small trees. If there are at most 3 vertices in a valid rooted tree, its
  # level sequence must already be in canonical representation.
  if order(t) <= 3
    return RootedTree(t.level_sequence, true)
  end

  # First, sort all subtrees recursively. Here, we use `view`s to avoid memory
  # allocations.
  # TODO: Assume 1-based indexing in the following
  subtree_root_index = 2
  number_of_subtrees = 0

  while subtree_root_index <= order(t)
    subtree_last_index = _subtree_last_index(subtree_root_index, t.level_sequence)

    # We found a complete subtree
    subtree = RootedTree(view(t.level_sequence, subtree_root_index:subtree_last_index))
    canonical_representation!(subtree, view(buffer, subtree_root_index:subtree_last_index))

    subtree_root_index = subtree_last_index + 1
    number_of_subtrees += 1
  end

  # Next, we need to sort the subtrees of `t` (in lexicographically decreasing
  # order of the level sequences).
  if number_of_subtrees > 1
    # Simple bubble sort that can act in-place, avoiding allocations
    # We keep track of the last index of the last subtree that we need to sort
    # since we know that the last `n` subtrees are already sorted after `n`
    # iterations.
    subtree_last_index_to_sort = order(t)
    swapped = true
    while swapped
      swapped = false

      # Search the first complete subtree
      subtree1_root_index = 2
      subtree1_last_index = 0
      subtree2_last_index = 0
      while subtree1_root_index <= subtree_last_index_to_sort
        subtree1_last_index = _subtree_last_index(subtree1_root_index, t.level_sequence)
        subtree2_last_index = subtree1_last_index

        # Search the next complete subtree
        subtree1_last_index == subtree_last_index_to_sort && break

        subtree2_root_index = subtree1_last_index + 1
        subtree2_last_index = _subtree_last_index(subtree2_root_index, t.level_sequence)

        # Swap the subtrees if they are not sorted correctly
        subtree1 = RootedTree(view(t.level_sequence, subtree1_root_index:subtree1_last_index))
        subtree2 = RootedTree(view(t.level_sequence, subtree2_root_index:subtree2_last_index))
        if isless(subtree1, subtree2)
          copyto!(buffer, 1, t.level_sequence, subtree1_root_index, order(subtree1) + order(subtree2))
          copyto!(t.level_sequence, subtree1_root_index, buffer, order(subtree1) + 1, order(subtree2))
          copyto!(t.level_sequence, subtree1_root_index + order(subtree2), buffer, 1, order(subtree1))
          # `subtree1_root_index` will be updated below using `subtree1_last_index`.
          # Thus, we need to adapt this variable here.
          subtree1_last_index = subtree1_root_index + order(subtree2) - 1
          swapped = true
        end

        # Move on to the next pair of subtrees
        subtree2_last_index == subtree_last_index_to_sort && break
        subtree1_root_index = subtree1_last_index + 1
      end

      # Update the last subtree we need to look at
      subtree_last_index_to_sort = min(subtree1_last_index, subtree2_last_index)
    end
  end

  RootedTree(t.level_sequence, true)
end

@inline function _subtree_last_index(subtree_root_index, level_sequence)
  # The subtree goes up to the next node that has the same (or lower)
  # rank as its root.
  subtree_last_index = subtree_root_index
  subtree_root_level = level_sequence[subtree_root_index]
  while subtree_last_index < length(level_sequence)
    if level_sequence[subtree_last_index + 1] > subtree_root_level
      subtree_last_index += 1
    else
      break
    end
  end
  return subtree_last_index
end

# Allocate global buffer for `canonical_representation!` for each thread
const BUFFER_LENGTH = 64
const CANONICAL_REPRESENTATION_BUFFER = Vector{Vector{Int}}()

function canonical_representation!(t::RootedTree{Int, Vector{Int}})
  if order(t) <= BUFFER_LENGTH
    buffer = CANONICAL_REPRESENTATION_BUFFER[Threads.threadid()]
  else
    buffer = similar(t.level_sequence)
  end
  canonical_representation!(t, buffer)
end


"""
    check_canonical(t::AbstractRootedTree)

Check whether `t` is in canonical representation.

!!! warning "Internal interface"
    This function is considered to be an internal implementation detail and
    will not necessarily be stable.
"""
function check_canonical(t::AbstractRootedTree)
  for subtree in SubtreeIterator(t)
    if !check_canonical(subtree)
      return false
    end
  end

  return issorted(SubtreeIterator(t), rev=true)
end


"""
    normalize_root!(t::AbstractRootedTree, root=one(eltype(t.level_sequence)))

Normalize the level sequence of the rooted tree `t` such that the root is
set to `root`.
"""
function normalize_root!(t::AbstractRootedTree, root=one(eltype(t.level_sequence)))
  t.level_sequence .+= root - first(t.level_sequence)
  t
end



"""
    RootedTreeIterator(order::Integer)

Iterator over all rooted trees of given `order`. The returned trees are views to
an internal tree modified during the iteration. If the returned trees shall be
stored or modified during the iteration, a `copy` has to be made.
"""
struct RootedTreeIterator{T<:Integer}
  order::T
  t::RootedTree{T,Vector{T}}

  function RootedTreeIterator(order::T) where {T<:Integer}
    new{T}(order, RootedTree(Vector{T}(one(T):order), true))
  end
end

Base.IteratorSize(::Type{<:RootedTreeIterator}) = Base.SizeUnknown()
Base.eltype(::Type{RootedTreeIterator{T}}) where T = RootedTree{T,Vector{T}}

@inline function Base.iterate(iter::RootedTreeIterator{T}) where {T}
  iter.t.level_sequence[:] = one(T):iter.order
  (iter.t, iter.order <= 0)
end

@inline function Base.iterate(iter::RootedTreeIterator{T}, state) where {T}
  state && return nothing

  two = iter.t.level_sequence[1] + one(T)
  p = 1
  q = 1
  @inbounds for i in 2:length(iter.t.level_sequence)
    if iter.t.level_sequence[i] > two
      p = i
    end
  end
  p == 1 && return nothing

  level_q = iter.t.level_sequence[p] - one(T)
  @inbounds for i in 1:p
    if iter.t.level_sequence[i] == level_q
      q = i
    end
  end

  @inbounds for i in p:length(iter.t.level_sequence)
    iter.t.level_sequence[i] = iter.t.level_sequence[i - (p-q)]
  end

  (iter.t, false)
end


"""
    count_trees(order)

Counts all rooted trees of `order`.
"""
function count_trees(order)
  order < 0 && throw(ArgumentError("The `order` must be at least zero."))

  num = 0
  for _ in RootedTreeIterator(order)
    num += 1
  end
  num
end


# subtrees
struct SubtreeIterator{Tree<:AbstractRootedTree}
  t::Tree
end

# optional: define some interface methods such as
# Base.IteratorSize(::Type{<:SubtreeIterator}) = Base.SizeUnknown()
# Base.eltype(::Type{SubtreeIterator})

@inline function Base.iterate(subtrees::SubtreeIterator{<:RootedTree})
  subtree_root_index = firstindex(subtrees.t.level_sequence) + 1
  iterate(subtrees, subtree_root_index)
end

@inline function Base.iterate(subtrees::SubtreeIterator{<:RootedTree}, subtree_root_index)
  level_sequence = subtrees.t.level_sequence

  # terminate the iteration if there are no further subtrees
  if subtree_root_index > lastindex(level_sequence)
    return nothing
  end

  # find the next complete subtree
  subtree_last_index = _subtree_last_index(subtree_root_index, level_sequence)
  subtree = RootedTree(
    view(level_sequence, subtree_root_index:subtree_last_index),
    # if t is in canonical representation, its subtrees are, too
    iscanonical(subtrees.t))

  return (subtree, subtree_last_index + 1)
end


"""
    subtrees(t::RootedTree)

Returns a vector of all subtrees of `t`.
"""
function subtrees(t::RootedTree)
  subtr = typeof(t)[]

  if length(t.level_sequence) < 2
    return subtr
  end

  start = 2
  i = 3
  while i <= length(t.level_sequence)
    if t.level_sequence[i] <= t.level_sequence[start]
      push!(subtr, RootedTree(t.level_sequence[start:i-1]))
      start = i
    end
    i += 1
  end
  push!(subtr, RootedTree(t.level_sequence[start:end]))
end



# partitions
"""
    partition_forest(t::RootedTree, edge_set)

Form the partition forest of the rooted tree `t` where edges marked with `false`
in the `edge_set` are removed. The ith value in the Boolean iterable `edge_set`
corresponds to the edge connecting node `i+1` in the level sequence to its parent.

See also [`partition_skeleton`](@ref), [`PartitionIterator`](@ref), and
[`PartitionForestIterator`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function partition_forest(t::RootedTree, edge_set)
  @boundscheck begin
    @assert length(t.level_sequence) == length(edge_set) + 1
  end

  level_sequence = copy(t.level_sequence)
  edge_set_copy = copy(edge_set)
  forest = Vector{RootedTree{eltype(level_sequence), typeof(level_sequence)}}()
  partition_forest!(forest, level_sequence, edge_set_copy)
  return forest
end

# Internal implementation that `push!`es to `forest` and modifies the vectors
# `level_sequence` and `edge_set`.
function partition_forest!(forest, level_sequence, edge_set)
  # Iterate over all edges that shall be removed.
  edge_to_remove = findlast(==(false), edge_set)
  while edge_to_remove !== nothing
    # Remember the convention node = edge + 1
    subtree_root_index = edge_to_remove + 1
    subtree_last_index = _subtree_last_index(subtree_root_index, level_sequence)
    subtree = rootedtree!(level_sequence[subtree_root_index:subtree_last_index])

    # Since we search from the end, there is no additional edge that needs to
    # be removed in the current subtree. Thus, we can `push!` it to the `forest`
    # and remove it from the active `level_sequence` and `edge_set`.
    push!(forest, subtree)
    deleteat!(level_sequence, subtree_root_index:subtree_last_index)
    deleteat!(edge_set, subtree_root_index-1:subtree_last_index-1)

    edge_to_remove = findlast(==(false), edge_set)
  end
  push!(forest, rootedtree(level_sequence))
end


"""
    PartitionForestIterator(t::AbstractRootedTree, edge_set)

Lazy iterator representation of the [`partition_forest`](@ref) of the rooted
tree `t`.
Similar to [`RootedTreeIterator`](@ref), you should `copy` the iterates
if you want to store or modify them during the iteration since they may be
views to internal caches.

See also [`partition_forest`](@ref), [`partition_skeleton`](@ref), and
[`PartitionIterator`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
struct PartitionForestIterator{Tree<:AbstractRootedTree}
  t_iter::Tree # return value from `iterate`
  t_temp::Tree # internal temporary buffer
  edge_set::Vector{Bool}
end

function PartitionForestIterator(t::AbstractRootedTree, edge_set)
  t_iter = copy(t)
  t_temp = copy(t)
  PartitionForestIterator(t_iter, t_temp, copy(edge_set))
end

Base.IteratorSize(::Type{<:PartitionForestIterator}) = Base.HasLength()
Base.length(forest::PartitionForestIterator) = count(==(false), forest.edge_set) + 1
Base.eltype(::Type{PartitionForestIterator{Tree}}) where {Tree} = Tree

@inline function Base.iterate(forest::PartitionForestIterator)
  iterate(forest, lastindex(forest.edge_set))
end

@inline function Base.iterate(forest::PartitionForestIterator, search_start)
  t_iter = forest.t_iter
  t_temp = forest.t_temp
  edge_set = forest.edge_set

  # We use `search_start = typemin(Int)` to indicate that we have already
  # returned the final tree in the previous call.
  if search_start == typemin(Int)
    return nothing
  end

  edge_to_remove = findprev(==(false), edge_set, search_start)

  # There are no further edges to remove and we can return the final tree.
  if edge_to_remove === nothing
    unsafe_resize!(t_iter, order(t_temp))
    copy!(t_iter, t_temp)
    canonical_representation!(t_iter)
    return (t_iter, typemin(Int))
  end

  # On to the next subtree
  # Remember the convention node = edge + 1
  subtree_root_index = edge_to_remove + 1
  subtree_last_index = _subtree_last_index(subtree_root_index, t_temp.level_sequence)
  subtree_length = subtree_last_index - subtree_root_index + 1

  # Since we search from the end, there is no additional edge that needs to
  # be removed in the current subtree. Thus, we can return it as the next
  # iterate of the partition forest
  unsafe_resize!(t_iter, subtree_length)
  unsafe_copyto!(t_iter, 1, t_temp, subtree_root_index, subtree_length)
  canonical_representation!(t_iter)

  # Now, we can remove the next subtree iterate from the active
  # level sequence in `t_temp` and the `edge_set`.
  unsafe_deleteat!(t_temp, subtree_root_index:subtree_last_index)
  deleteat!(edge_set, subtree_root_index-1:subtree_last_index-1)

  return (t_iter, edge_to_remove - 1)
end

# necessary for simple and convenient use since the iterates may be modified
function Base.collect(forest::PartitionForestIterator)
  iterates = Vector{eltype(forest)}()
  sizehint!(iterates, length(forest))
  for t in forest
    push!(iterates, copy(t))
  end
  return iterates
end


"""
    partition_skeleton(t::AbstractRootedTree, edge_set)

Form the partition skeleton of the rooted tree `t`, i.e., the rooted tree
obtained by contracting each tree of the partition forest to a single vertex
and re-establishing the edges removed to obtain the partition forest.

See also [`partition_forest`](@ref) and [`PartitionIterator`](@ref).

# References

Section 2.3 (and Section 6.1 for colored trees) of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function partition_skeleton(t::AbstractRootedTree, edge_set)
  @boundscheck begin
    @assert order(t) == length(edge_set) + 1
  end

  edge_set_copy = copy(edge_set)
  skeleton = copy(t)
  return partition_skeleton!(skeleton, edge_set_copy)
end

# internal in-place version of partition_skeleton modifying the inputs
function partition_skeleton!(skeleton::AbstractRootedTree, edge_set)
  level_sequence = skeleton.level_sequence

  # Iterate over all edges that shall be kept/contracted.
  # We start the iteration at the end since this will result in less memory
  # moves because we have already reduced the size of the vectors when reaching
  # the beginning.
  edge_to_contract = findlast(edge_set)
  while edge_to_contract !== nothing
    # Contract the corresponding edge by removing the subtree root and promoting
    # the rest of the subtree.
    # Remember the convention node = edge + 1
    subtree_root_index = edge_to_contract + 1
    subtree_last_index = subtree_root_index + 1
    while subtree_last_index <= length(level_sequence)
      if level_sequence[subtree_last_index] > level_sequence[subtree_root_index]
        level_sequence[subtree_last_index] -= 1
        subtree_last_index += 1
      else
        break
      end
    end

    # Remove the root node
    unsafe_deleteat!(skeleton, subtree_root_index)
    deleteat!(edge_set, edge_to_contract)

    edge_to_contract = findprev(edge_set, edge_to_contract - 1)
  end

  # The level sequence `level_sequence` will not automatically be a canonical
  # representation.
  canonical_representation!(skeleton)
end


"""
    all_partitions(t::RootedTree)

Create all partition forests and skeletons of a rooted tree `t`. This returns
vectors of the return values of [`partition_forest`](@ref) and
[`partition_skeleton`](@ref) when looping over all possible edge sets.

See also [`PartitionIterator`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function all_partitions(t::RootedTree)
  edge_set = zeros(Bool, order(t) - 1)
  forests   = [partition_forest(t, edge_set)]
  skeletons = [partition_skeleton(t, edge_set)]

  for edge_set_value in 1:(2^length(edge_set) - 1)
    binary_digits!(edge_set, edge_set_value)
    push!(forests,   partition_forest(t, edge_set))
    push!(skeletons, partition_skeleton(t, edge_set))
  end

  return (; forests, skeletons)
end

# A helper function to comute the binary representation of an integer `n` as
# a vector of `Bool`s. This is a more efficient version of
#   binary_digits!(digits, n) = digits!(digits, n, base=2)
function binary_digits!(digits::Vector{Bool}, n::Int)
  bit = 1
  for i in eachindex(digits)
    digits[i] = n & bit > 0
    bit = bit << 1
  end
  digits
end



"""
    PartitionIterator(t::AbstractRootedTree)

Iterator over all partition forests and skeletons of the rooted tree `t`.
This is basically a pure iterator version of [`all_partitions`](@ref).
In particular, the partition forest may only be realized as an iterator.
Similar to [`RootedTreeIterator`](@ref), you should `copy` the iterates
if you want to store or modify them during the iteration since they may be
views to internal caches.

See also [`partition_forest`](@ref), [`partition_skeleton`](@ref),
and [`PartitionForestIterator`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
struct PartitionIterator{TreeInput<:AbstractRootedTree, TreeOutput<:AbstractRootedTree}
  t::TreeInput
  forest::PartitionForestIterator{TreeOutput}
  skeleton::TreeOutput
  edge_set::Vector{Bool}
  edge_set_tmp::Vector{Bool}
end

function PartitionIterator(t::AbstractRootedTree)
  skeleton = similar(t)
  edge_set = Vector{Bool}(undef, order(t) - 1)
  edge_set_tmp = similar(edge_set)

  t_forest = similar(t)
  t_temp_forest = similar(t)
  forest = PartitionForestIterator(t_forest, t_temp_forest, edge_set_tmp)
  PartitionIterator{typeof(t), typeof(skeleton)}(t, forest, skeleton, edge_set, edge_set_tmp)
end

# Allocate global buffer for `PartitionIterator` for each thread
const PARTITION_ITERATOR_BUFFER_FOREST_T = Vector{Vector{Int}}()
const PARTITION_ITERATOR_BUFFER_FOREST_T_COLORS = Vector{Vector{Bool}}()
const PARTITION_ITERATOR_BUFFER_FOREST_LEVEL_SEQUENCE = Vector{Vector{Int}}()
const PARTITION_ITERATOR_BUFFER_FOREST_COLOR_SEQUENCE = Vector{Vector{Bool}}()
const PARTITION_ITERATOR_BUFFER_SKELETON = Vector{Vector{Int}}()
const PARTITION_ITERATOR_BUFFER_SKELETON_COLORS = Vector{Vector{Bool}}()
const PARTITION_ITERATOR_BUFFER_EDGE_SET = Vector{Vector{Bool}}()
const PARTITION_ITERATOR_BUFFER_EDGE_SET_TMP = Vector{Vector{Bool}}()

function PartitionIterator(t::RootedTree{Int, Vector{Int}})
  order_t = order(t)

  if order_t <= BUFFER_LENGTH
    id = Threads.threadid()

    buffer_forest_t = PARTITION_ITERATOR_BUFFER_FOREST_T[id]
    resize!(buffer_forest_t, order_t)
    level_sequence  = PARTITION_ITERATOR_BUFFER_FOREST_LEVEL_SEQUENCE[id]
    resize!(level_sequence, order_t)
    buffer_skeleton = PARTITION_ITERATOR_BUFFER_SKELETON[id]
    resize!(buffer_skeleton, order_t)
    edge_set        = PARTITION_ITERATOR_BUFFER_EDGE_SET[id]
    resize!(edge_set, order_t - 1)
    edge_set_tmp    = PARTITION_ITERATOR_BUFFER_EDGE_SET_TMP[id]
    resize!(edge_set_tmp, order_t - 1)
  else
    buffer_forest_t = Vector{Int}(undef, order_t)
    level_sequence  = similar(buffer_forest_t)
    buffer_skeleton = similar(buffer_forest_t)
    edge_set        = Vector{Bool}(undef, order_t - 1)
    edge_set_tmp    = similar(edge_set)
  end

  skeleton = RootedTree(buffer_skeleton, true)
  t_forest = RootedTree(buffer_forest_t, true)
  t_temp_forest = RootedTree(level_sequence, true)
  forest = PartitionForestIterator(t_forest, t_temp_forest, edge_set_tmp)
  PartitionIterator{typeof(t), RootedTree{Int, Vector{Int}}}(
    t, forest, skeleton, edge_set, edge_set_tmp)
end


Base.IteratorSize(::Type{<:PartitionIterator}) = Base.HasLength()
Base.length(partitions::PartitionIterator) = 2^length(partitions.edge_set)
Base.eltype(::Type{PartitionIterator{TreeInput, TreeOutput}}) where {TreeInput, TreeOutput} = Tuple{PartitionForestIterator{TreeOutput}, TreeOutput}

@inline function Base.iterate(partitions::PartitionIterator)
  edge_set_value = 0
  iterate(partitions, edge_set_value)
end

@inline function Base.iterate(partitions::PartitionIterator, edge_set_value)
  edge_set_value >= length(partitions) && return nothing

  t            = partitions.t
  forest       = partitions.forest
  skeleton     = partitions.skeleton
  edge_set     = partitions.edge_set
  edge_set_tmp = partitions.edge_set_tmp

  binary_digits!(edge_set, edge_set_value)

  # Compute the partition skeleton.
  # The following is a more efficient version of
  #   skeleton = partition_skeleton(t, edge_set)
  # avoiding some allocations.
  resize!(edge_set_tmp, length(edge_set))
  copy!(edge_set_tmp, edge_set)
  unsafe_resize!(skeleton, order(t))
  copy!(skeleton, t)
  partition_skeleton!(skeleton, edge_set_tmp)

  # Compute the partition forest.
  # The following is a more efficient version of
  #   forest = partition_forest(t, edge_set)
  # avoiding some allocations and using a lazy iterator.
  resize!(edge_set_tmp, length(edge_set))
  copy!(edge_set_tmp, edge_set)
  unsafe_resize!(forest.t_temp, order(t))
  copy!(forest.t_temp, t)


  ((forest, skeleton), edge_set_value + 1)
end

# necessary for simple and convenient use since the iterates may be modified
function Base.collect(partitions::PartitionIterator{TreeInput, TreeOutput}) where {TreeInput, TreeOutput}
  iterates = Vector{Tuple{Vector{TreeOutput}, TreeOutput}}()
  sizehint!(iterates, length(partitions))
  for (forest, skeleton) in partitions
    push!(iterates, (collect(forest), copy(skeleton)))
  end
  return iterates
end



# splittings
"""
    all_splittings(t::RootedTree)

Create all splitting forests and subtrees associated to ordered subtrees of a
rooted tree `t`.

Seee also [`SplittingIterator`](@ref).

# References

Section 2.2 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function all_splittings(t::RootedTree)
  node_set = zeros(Bool, order(t))
  ls = t.level_sequence
  T = eltype(ls)
  forests  = Vector{Vector{RootedTree{T, Vector{T}}}}()
  subtrees = Vector{RootedTree{T, Vector{T}}}() # ordered subtrees

  for node_set_value in 0:(2^order(t) - 1)
    binary_digits!(node_set, node_set_value)

    # Check that if a node is removed then all of its descendants are removed
    subtree_root_index = 1
    forest = Vector{RootedTree{T, Vector{T}}}()
    while subtree_root_index <= order(t)
      if node_set[subtree_root_index] == false # This node is removed
        # Find complete subtree
        subtree_last_index = _subtree_last_index(subtree_root_index, ls)

        # Check that subtree is all removed
        if !any(@view node_set[subtree_root_index:subtree_last_index])
          new_tree = rootedtree(@view ls[subtree_root_index:subtree_last_index])
          push!(forest, new_tree)
          subtree_root_index = subtree_last_index + 1
        else
          break
        end
      else
        subtree_root_index += 1
      end
    end

    if subtree_root_index == order(t) + 1
      # This is a valid ordered subtree.
      # The `level_sequence` will not automatically be a canonical representation.
      level_sequence = ls[node_set]
      subtree = rootedtree!(level_sequence)
      push!(subtrees, subtree)
      push!(forests, forest)
    end
  end

  return (; forests, subtrees)
end


"""
    SplittingIterator(t::RootedTree)

Iterator over all splitting forests and subtrees of the rooted tree `t`.
This is basically an iterator version of [`all_splittings`](@ref).

See also [`partition_forest`](@ref) and [`partition_skeleton`](@ref).

# References

Section 2.2 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
struct SplittingIterator{T<:RootedTree}
  t::T
  node_set::Vector{Bool}
  max_node_set_value::Int

  function SplittingIterator(t::T) where {T<:RootedTree}
    node_set = zeros(Bool, order(t))
    new{T}(t, node_set, 2^order(t) - 1)
  end
end

Base.IteratorSize(::Type{<:SplittingIterator}) = Base.SizeUnknown()
Base.eltype(::Type{SplittingIterator{T}}) where {T} = Tuple{Vector{T}, T}

@inline function Base.iterate(splittings::SplittingIterator)
  node_set_value = 0
  iterate(splittings, node_set_value)
end

@inline function Base.iterate(splittings::SplittingIterator, node_set_value)
  node_set_value > splittings.max_node_set_value && return nothing

  node_set = splittings.node_set
  t = splittings.t
  ls = t.level_sequence
  T = eltype(ls)
  forest = Vector{RootedTree{T, Vector{T}}}()

  while node_set_value <= splittings.max_node_set_value
    binary_digits!(node_set, node_set_value)

    # Check that if a node is removed then all of its descendants are removed
    subtree_root_index = 1
    empty!(forest)
    while subtree_root_index <= order(t)
      if node_set[subtree_root_index] == false # This node is removed
        subtree_last_index = _subtree_last_index(subtree_root_index, ls)

        # Check that subtree is all removed
        if !any(@view node_set[subtree_root_index:subtree_last_index])
          # If `iscanonical(t)`, the subtree starting at the root of `t`
          # is also in canonical representation. Thus, we don't need to
          # use the more expensive version
          #   push!(forest, rootedtree!(level_sequence))
          # but can use the cheaper version below.
          level_sequence = ls[subtree_root_index:subtree_last_index]
          push!(forest, RootedTree(level_sequence, iscanonical(t)))
          subtree_root_index = subtree_last_index + 1
        else
          break
        end
      else
        subtree_root_index += 1
      end
    end

    if subtree_root_index == order(t) + 1
      # This is a valid ordered subtree.
      # The `level_sequence` will not automatically be a canonical representation.
      # TODO: splittings;
      #       Decide whether canonical representations should be used. Disabling
      #       them will increase the performance.
      level_sequence = ls[node_set]
      subtree = rootedtree!(level_sequence)
      return ((forest, subtree), node_set_value + 1)
    else
      node_set_value = node_set_value + 1
    end
  end

  return nothing
end



# functions on trees

"""
    order(t::AbstractRootedTree)

The `order` of a rooted tree `t`, i.e., the length of its level sequence.
"""
order(t::AbstractRootedTree) = length(t.level_sequence)


"""
    σ(t::AbstractRootedTree)
    symmetry(t::AbstractRootedTree)

The symmetry `σ` of a rooted tree `t`, i.e., the order of the group of automorphisms
on a particular labelling (of the vertices) of `t`.

Reference: Section 301 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function symmetry(t::AbstractRootedTree)
  if order(t) <= 2
    return 1
  end

  # Rely on the canonical ordering to guarantee that identical subtrees are
  # next to each other.
  if !iscanonical(t)
    return symmetry(canonical_representation(t))
  end

  # Iterate over all subtrees. Since we know that the `order(t)` is at least 3,
  # there must be at least one subtree.
  subtrees = SubtreeIterator(t)

  # Unroll the `for` loop manually to be able to compare the next iterate with
  # the previous one.
  previous_subtree, state = iterate(subtrees)

  result = 1
  num_same_subtrees = 1
  iter = iterate(subtrees, state)
  while iter !== nothing
    subtree, state = iter
    if subtree == previous_subtree
      num_same_subtrees += 1
    else
      result *= factorial(num_same_subtrees) * symmetry(previous_subtree)^num_same_subtrees
      num_same_subtrees = 1
    end

    previous_subtree = subtree
    iter = iterate(subtrees, state)
  end

  result *= factorial(num_same_subtrees) * symmetry(previous_subtree)^num_same_subtrees
  return result
end

const σ = symmetry


"""
    γ(t::AbstractRootedTree)
    density(t::AbstractRootedTree)

The density `γ(t)` of a rooted tree, i.e., the product over all vertices of `t`
of the order of the subtree rooted at that vertex.

Reference: Section 301 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function density(t::AbstractRootedTree)
  isempty(t) && return 1

  result = order(t)
  for subtree in SubtreeIterator(t)
    result *= density(subtree)
  end
  result
end

const γ = density


"""
    α(t::AbstractRootedTree)

The number of monotonic labelings of `t` not equivalent under the symmetry group.

Reference: Section 302 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function α(t::AbstractRootedTree)
  div(factorial(order(t)), σ(t) * γ(t))
end


"""
    β(t::AbstractRootedTree)

The total number of labelings of `t` not equivalent under the symmetry group.

Reference: Section 302 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function β(t::AbstractRootedTree)
  div(factorial(order(t)), σ(t))
end



# additional representation and construction methods
"""
    t1 ∘ t2

The non-associative Butcher product of rooted trees. It is formed
by adding an edge from the root of `t1` to the root of `t2`.

Reference: Section 301 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2016.
"""
function Base.:∘(t1::RootedTree, t2::RootedTree)
  offset = first(t1.level_sequence) - first(t2.level_sequence) + 1
  level_sequence = vcat(t1.level_sequence, t2.level_sequence .+ offset)
  rootedtree(level_sequence)
end


"""
    butcher_representation(t::RootedTree)

Returns the representation of `t::RootedTree` introduced by Butcher as a string.
Thus, the rooted tree consisting whose only vertex is the root itself is
represented as `τ`. The representation of other trees is defined recursively;
if `t₁, t₂, ... tₙ` are the [`subtrees`](@ref) of the rooted tree `t`, it is
represented as `t = [t₁ t₂ ... tₙ]`. If multiple subtrees are the same, their
number of occurences is written as a power.

# Examples

```jldoctest
julia> rootedtree([1, 2, 3, 2]) |> butcher_representation
"[[τ]τ]"

julia> rootedtree([1, 2, 3, 3, 2]) |> butcher_representation
"[[τ²]τ]"
```

# References

Section 300 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function butcher_representation(t::RootedTree, normalize::Bool=true)
  if order(t) == 0
    return "∅"
  elseif order(t) == 1
    return "τ"
  end

  result = ""
  for subtree in SubtreeIterator(t)
    result = result * butcher_representation(subtree, normalize)
  end
  result = "[" * result * "]"

  if normalize
    # normalize the result by grouping repeated occurrences of τ
    # TODO: Decide whether powers should also be used for subtrees,
    #       e.g., "[[τ]²]" instead of "[[τ][τ]]"
    #       for rootedtree([1, 2, 3, 2, 3]).
    #       Currently, powers are only used for τ.
    for n in order(t):-1:2
      n_str = string(n)
      n_str = replace(n_str, "1" => "¹")
      n_str = replace(n_str, "2" => "²")
      n_str = replace(n_str, "3" => "³")
      n_str = replace(n_str, "4" => "⁴")
      n_str = replace(n_str, "5" => "⁵")
      n_str = replace(n_str, "6" => "⁶")
      n_str = replace(n_str, "7" => "⁷")
      n_str = replace(n_str, "8" => "⁸")
      n_str = replace(n_str, "9" => "⁹")
      n_str = replace(n_str, "0" => "⁰")
      result = replace(result, "τ"^n => "τ" * n_str)
    end
  end

  return result
end


include("colored_trees.jl")
include("latexify.jl")
include("plot_recipes.jl")
include("time_integration_methods.jl")


function __init__()
  # canonical_representation!
  Threads.resize_nthreads!(CANONICAL_REPRESENTATION_BUFFER,
                           Vector{Int}(undef, BUFFER_LENGTH))

  # PartitionIterator
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_FOREST_T,
                           Vector{Int}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_FOREST_T_COLORS,
                           Vector{Bool}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_FOREST_LEVEL_SEQUENCE,
                           Vector{Int}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_FOREST_COLOR_SEQUENCE,
                           Vector{Bool}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_SKELETON,
                           Vector{Int}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_SKELETON_COLORS,
                           Vector{Bool}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_EDGE_SET,
                           Vector{Bool}(undef, BUFFER_LENGTH))
  Threads.resize_nthreads!(PARTITION_ITERATOR_BUFFER_EDGE_SET_TMP,
                           Vector{Bool}(undef, BUFFER_LENGTH))

  @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
    using .Plots: Plots
    include("plots.jl")
  end

  return nothing
end


end # module
