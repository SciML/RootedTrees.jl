module RootedTrees

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) RootedTrees


using LinearAlgebra: dot

using RecipesBase: RecipesBase


export rootedtree, rootedtree!, RootedTreeIterator

export butcher_representation

export α, β, γ, density, σ, symmetry, order

export residual_order_condition, elementary_weight, derivative_weight

export count_trees

export partition_forest, PartitionForestIterator,
       partition_skeleton,
       all_partitions, PartitionIterator

export all_splittings, SplittingIterator



"""
    RootedTree(level_sequence, is_canonical::Bool=false)

Represents a rooted tree using its level sequence.

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
struct RootedTree{T<:Integer, V<:AbstractVector{T}}
  level_sequence::V
  iscanonical::Bool

  function RootedTree(level_sequence::V, iscanonical::Bool=false) where {T<:Integer, V<:AbstractVector{T}}
    new{T, V}(level_sequence, iscanonical)
  end
end

"""
    rootedtree(level_sequence)

Construct a canonical `RootedTree` object from a `level_sequence`, i.e.,
a vector of integers representing the levels of each node of the tree.

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
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
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
rootedtree!(level_sequence::AbstractVector) = canonical_representation!(RootedTree(level_sequence))

iscanonical(t::RootedTree) = t.iscanonical
#TODO: Validate rooted tree in constructor?

Base.copy(t::RootedTree) = RootedTree(copy(t.level_sequence), t.iscanonical)


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


RecipesBase.@recipe function plot(t::RootedTree)
  # Compute x and y coordinates recursively
  width = 2.0
  height = 1.0
  x, y = _plot_coordinates(t, 0.0, 0.0, width, height)

  # Series properties
  seriescolor --> :black
  markershape --> :circle
  markersize  --> 6
  linewidth   --> 2

  # Geometric properties
  grid --> false
  ticks --> false
  foreground_color_border --> :white
  legend --> :bottomright

  # We need to filter out `NaN` since these pollute `extrema`
  x_min, x_max = extrema(Iterators.filter(!isnan, x))
  if x_min ≈ x_max
    xlims --> (x_min - width/2, x_max + width/2)
  end
  y_min, y_max = extrema(Iterators.filter(!isnan, y))
  if y_min ≈ y_max
    ylims --> (y_min - height/2, y_max + height/2)
  end

  # Annotations
  label --> "tree " * string(t.level_sequence)

  x, y
end

function _plot_coordinates(t::RootedTree, x_root::T, y_root::T,
                                          width::T,  height::T) where {T}
  # Indicate a new line series by `NaN`
  nan = convert(T, NaN)
  x = [x_root]
  y = [y_root]

  # Compute plot coordinates recursively
  subtr = subtrees(t)

  # Distribute children uniformly in x and at equal y coordinates
  y_child = y_root + height
  num_children = length(subtr)
  distance = width * (num_children - 1) / 2

  x_children = range(x_root - distance, x_root + distance, length=num_children)
  for idx in eachindex(subtr)
    x_child = x_children[idx]
    push!(x, nan, x_root, x_child)
    push!(y, nan, y_root, y_child)
    x_recursive, y_recursive = _plot_coordinates(subtr[idx],
      x_child, y_child, width / 3, height)
    append!(x, x_recursive)
    append!(y, y_recursive)
  end

  return x, y
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

  root1 = first(t1.level_sequence)
  root2 = first(t2.level_sequence)
  for (e1, e2) in zip(t1.level_sequence, t2.level_sequence)
    v1 = e1 - root1
    v2 = e2 - root2
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

  root1 = first(t1.level_sequence)
  root2 = first(t2.level_sequence)
  for (e1, e2) in zip(t1.level_sequence, t2.level_sequence)
    e1 - root1 == e2 - root2 || return false
  end

  return true
end


# Factor out equivalence classes given by different roots
function Base.hash(t::RootedTree, h::UInt)
  isempty(t.level_sequence) && return h
  root = first(t.level_sequence)
  for l in t.level_sequence
    h = hash(l - root, h)
  end
  return h
end


# generation and canonical representation
"""
    canonical_representation(t::RootedTree)

Returns a new tree using the canonical representation of the rooted tree `t`,
i.e., the one with lexicographically biggest level sequence.

See also [`canonical_representation!`](@ref).
"""
function canonical_representation(t::RootedTree)
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
# generalwhen comparing the complexity with quicksort etc., it will be faster
# here since we can avoid allocations.
"""
    canonical_representation!(t::RootedTree)

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
    swapped = true
    while swapped
      swapped = false

      # Search the first complete subtree
      subtree1_root_index = 2
      while subtree1_root_index <= order(t)
        subtree1_last_index = _subtree_last_index(subtree1_root_index, t.level_sequence)

        # Search the next complete subtree
        subtree1_last_index == order(t) && break

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
        subtree2_last_index == order(t) && break
        subtree1_root_index = subtree1_last_index + 1
      end
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
const CANONICAL_REPRESENTATION_BUFFER_LENGTH = 64
const CANONICAL_REPRESENTATION_BUFFER = Vector{Vector{Int}}()

function canonical_representation!(t::RootedTree{Int, Vector{Int}})
  if order(t) <= CANONICAL_REPRESENTATION_BUFFER_LENGTH
    buffer = CANONICAL_REPRESENTATION_BUFFER[Threads.threadid()]
  else
    buffer = similar(t.level_sequence)
  end
  canonical_representation!(t, buffer)
end


function __init__()
  Threads.resize_nthreads!(CANONICAL_REPRESENTATION_BUFFER,
    Vector{Int}(undef, CANONICAL_REPRESENTATION_BUFFER_LENGTH))
end


"""
    normalize_root!(t::RootedTree, root=one(eltype(t.level_sequence)))

Normalize the level sequence of the rooted tree `t` such that the root is
set to `root`.
"""
function normalize_root!(t::RootedTree, root=one(eltype(t.level_sequence)))
  t.level_sequence .+= root - first(t.level_sequence)
  t
end



"""
    RootedTreeIterator{T<:Integer}

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

function Base.iterate(iter::RootedTreeIterator{T}) where {T}
  iter.t.level_sequence[:] = one(T):iter.order
  (iter.t, false)
end

function Base.iterate(iter::RootedTreeIterator{T}, state) where {T}
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
  order < 1 && throw(ArgumentError("The `order` must be at least one."))

  num = 0
  for _ in RootedTreeIterator(order)
    num += 1
  end
  num
end


# subtrees
struct Subtrees{T<:Integer} <: AbstractVector{RootedTree{T}}
  level_sequence::Vector{T}
  indices::Vector{T}
  iscanonical::Bool

  function Subtrees(t::RootedTree{T}) where {T}
    level_sequence = t.level_sequence
    indices = Vector{T}()

    start = 2
    i = 3
    while i <= length(level_sequence)
      if level_sequence[i] <= level_sequence[start]
        push!(indices, start)
        start = i
      end
      i += 1
    end
    push!(indices, start)

    # in order to get the stopping index for the last subtree
    push!(indices, length(level_sequence)+1)

    new{T}(level_sequence, indices, iscanonical(t))
  end
end

Base.size(s::Subtrees) = (length(s.indices)-1, )
Base.getindex(s::Subtrees, i::Int) = RootedTree(view(s.level_sequence, s.indices[i]:s.indices[i+1]-1), s.iscanonical)


"""
    subtrees(t::RootedTree)

Returns a vector of all subtrees of `t`.
"""
function subtrees(t::RootedTree{T}) where {T}
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
# TODO: partitions; add documentation in the README to make them public API
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
    PartitionForestIterator(t::RootedTree, edge_set)

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
struct PartitionForestIterator{T, V, Tree<:RootedTree{T, V}}
  t::Tree
  level_sequence::V
  edge_set::Vector{Bool}
end

function PartitionForestIterator(t::RootedTree, edge_set)
  level_sequence = copy(t.level_sequence)
  t_iterate = RootedTree(copy(level_sequence), true)
  PartitionForestIterator(t_iterate, level_sequence, copy(edge_set))
end

Base.IteratorSize(::Type{<:PartitionForestIterator}) = Base.HasLength()
Base.length(forest::PartitionForestIterator) = count(==(false), forest.edge_set) + 1
Base.eltype(::Type{PartitionForestIterator{T, V, Tree}}) where {T, V, Tree} = Tree

function Base.iterate(forest::PartitionForestIterator)
  iterate(forest, lastindex(forest.edge_set))
end

function Base.iterate(forest::PartitionForestIterator, search_start)
  t = forest.t
  edge_set = forest.edge_set
  level_sequence = forest.level_sequence

  # We use `search_start = typemin(Int)` to indicate that we have already
  # returned the final tree in the previous call.
  if search_start == typemin(Int)
    return nothing
  end

  edge_to_remove = findprev(==(false), edge_set, search_start)

  # There are no further edges to remove and we can return the final tree.
  if edge_to_remove === nothing
    resize!(t.level_sequence, length(level_sequence))
    copy!(t.level_sequence, level_sequence)
    canonical_representation!(t)
    return (t, typemin(Int))
  end

  # On to the next subtree
  # Remember the convention node = edge + 1
  subtree_root_index = edge_to_remove + 1
  subtree_last_index = _subtree_last_index(subtree_root_index, level_sequence)
  subtree_length = subtree_last_index - subtree_root_index + 1

  # Since we search from the end, there is no additional edge that needs to
  # be removed in the current subtree. Thus, we can return it as the next
  # iterate of the partition forest
  resize!(t.level_sequence, subtree_length)
  copyto!(t.level_sequence, 1, level_sequence, subtree_root_index, subtree_length)
  canonical_representation!(t)

  # Now, we can remove the next subtree iterate from the active `level_sequence`
  # and `edge_set`.
  deleteat!(level_sequence, subtree_root_index:subtree_last_index)
  deleteat!(edge_set, subtree_root_index-1:subtree_last_index-1)

  return (t, edge_to_remove - 1)
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


# TODO: partitions; add documentation in the README to make them public API
"""
    partition_skeleton(t::RootedTree, edge_set)

Form the partition skeleton of the rooted tree `t`, i.e., the rooted tree obtained
by contracting each tree of the partition forest to a single vertex and re-establishing
the edges removed to obtain the partition forest.

See also [`partition_forest`](@ref) and [`PartitionIterator`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series.
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function partition_skeleton(t::RootedTree, edge_set)
  @boundscheck begin
    @assert length(t.level_sequence) == length(edge_set) + 1
  end

  edge_set_copy = copy(edge_set)
  skeleton = RootedTree(copy(t.level_sequence), true)
  return partition_skeleton!(skeleton.level_sequence, edge_set_copy)
end

# internal in-place version of partition_skeleton modifying the inputs
function partition_skeleton!(level_sequence, edge_set)
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
    deleteat!(level_sequence, subtree_root_index)
    deleteat!(edge_set, edge_to_contract)

    edge_to_contract = findprev(edge_set, edge_to_contract - 1)
  end

  # The level sequence `level_sequence` will not automatically be a canonical
  # representation.
  return rootedtree!(level_sequence)
end


# TODO: partitions; add documentation in the README to make them public API
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
    PartitionIterator(t::RootedTree)

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
struct PartitionIterator{T, Tree<:RootedTree{T}}
  t::Tree
  forest::PartitionForestIterator{T, Vector{T}, RootedTree{T, Vector{T}}}
  skeleton::RootedTree{T, Vector{T}}
  edge_set::Vector{Bool}
  edge_set_tmp::Vector{Bool}

  function PartitionIterator(t::Tree) where {T, Tree<:RootedTree{T}}
    skeleton = RootedTree(Vector{T}(undef, order(t)), true)
    edge_set = zeros(Bool, order(t) - 1)
    edge_set_tmp = similar(edge_set)

    t_forest = RootedTree(Vector{T}(undef, order(t)), true)
    level_sequence = similar(t_forest.level_sequence)
    forest = PartitionForestIterator(t_forest, level_sequence, edge_set_tmp)
    new{T, Tree}(t, forest, skeleton, edge_set, edge_set_tmp)
  end
end

Base.IteratorSize(::Type{<:PartitionIterator}) = Base.HasLength()
Base.length(partitions::PartitionIterator) = 2^length(partitions.edge_set)
Base.eltype(::Type{PartitionIterator{T, Tree}}) where {T, Tree} = Tuple{Vector{RootedTree{T, Vector{T}}}, RootedTree{T, Vector{T}}}

function Base.iterate(partitions::PartitionIterator)
  edge_set_value = 0
  iterate(partitions, edge_set_value)
end

function Base.iterate(partitions::PartitionIterator, edge_set_value)
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
  resize!(skeleton.level_sequence, order(t))
  copy!(skeleton.level_sequence, t.level_sequence)
  partition_skeleton!(skeleton.level_sequence, edge_set_tmp)

  # Compute the partition forest.
  # The following is a more efficient version of
  #   forest = partition_forest(t, edge_set)
  # avoiding some allocations and using a lazy iterator.
  resize!(edge_set_tmp, length(edge_set))
  copy!(edge_set_tmp, edge_set)
  resize!(forest.level_sequence, order(t))
  copy!(forest.level_sequence, t.level_sequence)


  ((forest, skeleton), edge_set_value + 1)
end

# necessary for simple and convenient use since the iterates may be modified
function Base.collect(partitions::PartitionIterator)
  iterates = Vector{eltype(partitions)}()
  sizehint!(iterates, length(partitions))
  for (forest, skeleton) in partitions
    push!(iterates, (collect(forest), copy(skeleton)))
  end
  return iterates
end



# splittings
# TODO: splittings; add documentation in the README to make them public API
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

function Base.iterate(splittings::SplittingIterator)
  node_set_value = 0
  iterate(splittings, node_set_value)
end

function Base.iterate(splittings::SplittingIterator, node_set_value)
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
    order(t::RootedTree)

The `order` of a rooted tree `t`, i.e., the length of its level sequence.
"""
order(t::RootedTree) = length(t.level_sequence)


"""
    σ(t::RootedTree)
    symmetry(t::RootedTree)

The symmetry `σ` of a rooted tree `t`, i.e., the order of the group of automorphisms
on a particular labelling (of the vertices) of `t`.

Reference: Section 301 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function symmetry(t::RootedTree)
  if order(t) == 1 || order(t) == 2
    return 1
  end

  if !iscanonical(t)
    t = canonical_representation(t)
  end

  subtr = Subtrees(t)
  sym = 1
  num = 1

  @inbounds for i in 2:length(subtr)
    if subtr[i] == subtr[i-1]
      num += 1
    else
      sym *= factorial(num) * symmetry(subtr[i-1])^num
      num = 1
    end
  end
  sym *= factorial(num) * symmetry(subtr[end])^num
end

const σ = symmetry


"""
    γ(t::RootedTree)
    density(t::RootedTree)

The density `γ(t)` of a rooted tree, i.e., the product over all vertices of `t`
of the order of the subtree rooted at that vertex.

Reference: Section 301 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function density(t::RootedTree)
  if order(t) == 1
    return 1
  elseif order(t) == 2
    return 2
  end

  subtr = Subtrees(t)
  den = order(t)
  for τ in subtr
    den *= density(τ)
  end
  den
end

const γ = density


"""
    α(t::RootedTree)

The number of monotonic labelings of `t` not equivalent under the symmetry group.

Reference: Section 302 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function α(t::RootedTree)
  div(factorial(order(t)), σ(t)*γ(t))
end


"""
    β(t::RootedTree)

The total number of labelings of `t` not equivalent under the symmetry group.

Reference: Section 302 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function β(t::RootedTree)
  div(factorial(order(t)), σ(t))
end


"""
    elementary_weight(t::RootedTree, A::AbstractMatrix, b::AbstractVector, c::AbstractVector)

Compute the elementary weight Φ(`t`) of `t` for the Butcher coefficients
`A, b, c` of a Runge-Kutta method.

Reference: Section 312 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function elementary_weight(t::RootedTree, A::AbstractMatrix, b::AbstractVector, c::AbstractVector)
  T = promote_type(promote_type(eltype(A), eltype(b)), eltype(c))
  elementary_weight(t, Matrix{T}(A), Vector{T}(b), Vector{T}(c))
end

function elementary_weight(t::RootedTree, A::AbstractMatrix{T}, b::AbstractVector{T}, c::AbstractVector{T}) where {T}
  dot(b, derivative_weight(t, A, b, c))
end


"""
    derivative_weight(t::RootedTree, A, b, c)

Compute the derivative weight (ΦᵢD)(`t`) of `t` for the Butcher coefficients
`A, b, c` of a Runge-Kutta method.

Reference: Section 312 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function derivative_weight(t::RootedTree, A, b, c)
  if order(t) == 1
    return zero(c) .+ one(eltype(c))
  end

  subtr = Subtrees(t)
  result = A * derivative_weight(subtr[1], A, b, c)
  for i in 2:length(subtr)
    tmp = A * derivative_weight(subtr[i], A, b, c)
    result = result .* tmp
  end
  return result
end


"""
    residual_order_condition(t::RootedTree, A, b, c)

The residual of the order condition
  `(Φ(t) - 1/γ(t)) / σ(t)`
with elementary weight `Φ(t)`, density `γ(t)`, and symmetry `σ(t)` of the
rooted tree `t` for the Runge-Kutta method with Butcher coefficients
`A, b, c`.

Reference: Section 315 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function residual_order_condition(t::RootedTree, A, b, c)
  ew = elementary_weight(t, A, b, c)
  T = typeof(ew)

  (ew - one(T) / γ(t)) / σ(t)
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
    butcher_represetation(t::RootedTree)

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
  if order(t) == 1
    return "τ"
  end

  subtr = Subtrees(t)
  result = ""
  for i in eachindex(subtr)
    result = result * butcher_representation(subtr[i], normalize)
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
      result = replace(result, "τ"^n => "τ"*n_str)
    end
  end

  return result
end


"""
    latexify(t::RootedTree)

Return a LaTeX representation of the rooted tree `t`. This makes use of the
LaTeX package [forest](https://ctan.org/pkg/forest) and assumes that you use
the following LaTeX code in the preamble.

```
% Butcher trees, cf. https://tex.stackexchange.com/questions/283343/butcher-trees-in-tikz
\\usepackage{forest}
\\forestset{
  */.style={
    delay+={append={[]},}
  },
  rooted tree/.style={
    for tree={
      grow'=90,
      parent anchor=center,
      child anchor=center,
      s sep=2.5pt,
      if level=0{
        baseline
      }{},
      delay={
        if content={*}{
          content=,
          append={[]}
        }{}
      }
    },
    before typesetting nodes={
      for tree={
        circle,
        fill,
        minimum width=3pt,
        inner sep=0pt,
        child anchor=center,
      },
    },
    before computing xy={
      for tree={
        l=5pt,
      }
    }
  }
}
\\DeclareDocumentCommand\\rootedtree{o}{\\Forest{rooted tree [#1]}}
```

# Examples

```jldoctest
julia> rootedtree([1, 2, 2]) |> RootedTrees.latexify |> println
\rootedtree[[][]]

julia> rootedtree([1, 2, 3, 3, 2]) |> RootedTrees.latexify |> println
\rootedtree[[[][]][]]
```
"""
function latexify(t::RootedTree)
  list_representation = butcher_representation(t, false)
  "\\rootedtree" * replace(list_representation, "τ" => "[]")
end


end # module
