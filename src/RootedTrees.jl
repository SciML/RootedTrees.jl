module RootedTrees

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) RootedTrees


using LinearAlgebra: dot


export rootedtree, rootedtree!, RootedTreeIterator

export butcher_representation

export α, β, γ, density, σ, symmetry, order

export residual_order_condition, elementary_weight, derivative_weight

export count_trees

export partition_forest, partition_skeleton, all_partitions, PartitionIterator

export all_splittings, SplittingIterator



"""
    RootedTree

Represents a rooted tree using its level sequence.

Reference:
- Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
mutable struct RootedTree{T<:Integer, V<:AbstractVector{T}}
  level_sequence::V
  iscanonical::Bool
end

function RootedTree(level_sequence::AbstractVector, iscanonical=false)
  T = eltype(level_sequence)
  V = typeof(level_sequence)
  RootedTree{T,V}(level_sequence, iscanonical)
end

"""
    rootedtree(level_sequence)

Construct a canonical `RootedTree` object from a `level_sequence`, i.e.,
a vector of integers representing the levels of each node of the tree.

Reference:
- Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
rootedtree(level_sequence::AbstractVector) = canonical_representation(RootedTree(level_sequence))

"""
    rootedtree!(level_sequence)

Construct a canonical `RootedTree` object from a `level_sequence` which may be
modified in this process. See also `rootedtree`.

Reference:
- Beyer, Terry, and Sandra Mitchell Hedetniemi.
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
    canonical_representation!(t::RootedTree)

Change the representation of the rooted tree `t` to the canonical one, i.e., the
one with lexicographically biggest level sequence.
"""
function canonical_representation!(t::RootedTree)
  subtr = subtrees(t)
  for i in eachindex(subtr)
    canonical_representation!(subtr[i])
  end
  sort!(subtr, rev=true)

  i = 2
  for τ in subtr
    t.level_sequence[i:i+order(τ)-1] = τ.level_sequence
    i += order(τ)
  end
  t.iscanonical = true

  t
end

"""
    canonical_representation(t::RootedTree)

Returns a new tree using the canonical representation of the rooted tree `t`,
i.e., the one with lexicographically biggest level sequence.
"""
function canonical_representation(t::RootedTree)
  canonical_representation!(copy(t))
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

See also [`partition_skeleton`](@ref) and [`PartitionIterator`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function partition_forest(t::RootedTree, _edge_set)
  @boundscheck begin
    @assert length(t.level_sequence) == length(_edge_set) + 1
  end

  edge_set = copy(_edge_set)
  ls = copy(t.level_sequence)
  T = eltype(ls)
  forest = Vector{RootedTree{T, Vector{T}}}()

  while !all(edge_set)
    # Find next removed edge
    subtree_root_index = findfirst(==(false), edge_set) + 1

    # Detach the corresponding subtree and add its partition forest.
    # The subtree goes up to the next node that has the same (or lower)
    # rank as its root.
    subtree_last_index = subtree_root_index
    while subtree_last_index < length(ls)
      if ls[subtree_last_index + 1] > ls[subtree_root_index]
        subtree_last_index += 1
      else
        break
      end
    end

    # Extract the subtree and the edge set on it. Note that the corresponding
    # edge set contains one element less than the subtree itself.
    # There is no need to use a canonical representation of the temporary
    # subtree. Thus, we do not use `rootedtree` but the (unsafe) constructor.
    # Since we `copy` the level sequence in the recursive call, we can also
    # use a `view` to reduce memory allocations.
    subtree = RootedTree(@view ls[subtree_root_index:subtree_last_index])
    subtree_edge_set = @view edge_set[subtree_root_index:subtree_last_index-1]

    # Form the partition forest recursively
    append!(forest, partition_forest(subtree, subtree_edge_set))

    # Remove the subtree from the base tree
    deleteat!(ls, subtree_root_index:subtree_last_index)
    deleteat!(edge_set, subtree_root_index-1:subtree_last_index-1)
  end

  # The level sequence `ls` will not automatically be a canonical representation.
  # TODO: partitions;
  #       Decide whether canonical representations should be used. Disabling
  #       them will increase the performance.
  push!(forest, rootedtree!(ls))
  return forest
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
  Algebraic Structures of B-series
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function partition_skeleton(t::RootedTree, _edge_set)
  @boundscheck begin
    @assert length(t.level_sequence) == length(_edge_set) + 1
  end

  edge_set = copy(_edge_set)
  ls = copy(t.level_sequence)

  while any(edge_set)
    # Find next edge to contract
    subtree_root_index = findfirst(==(true), edge_set) + 1

    # Contract the corresponding edge by removing the subtree root and promoting
    # the rest of the subtree
    subtree_last_index = subtree_root_index + 1
    while subtree_last_index <= length(ls)
      if ls[subtree_last_index] > ls[subtree_root_index]
        ls[subtree_last_index] -= 1
        subtree_last_index += 1
      else
        break
      end
    end
    # Remove the root node
    deleteat!(ls, subtree_root_index)
    deleteat!(edge_set, subtree_root_index-1)
  end

  # The level sequence `ls` will not automatically be a canonical representation.
  # TODO: partitions;
  #       Decide whether canonical representations should be used. Disabling
  #       them will increase the performance.
  return rootedtree!(ls)
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
  Algebraic Structures of B-series
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
function all_partitions(t::RootedTree)
  edge_set = zeros(Bool, order(t) - 1)
  forests   = [partition_forest(t, edge_set)]
  skeletons = [partition_skeleton(t, edge_set)]

  for edge_set_value in 1:(2^length(edge_set) - 1)
    digits!(edge_set, edge_set_value, base=2)
    push!(forests,   partition_forest(t, edge_set))
    push!(skeletons, partition_skeleton(t, edge_set))
  end

  return (; forests, skeletons)
end


"""
    PartitionIterator(t::RootedTree)

Iterator over all partition forests and skeletons of the rooted tree `t`.
This is basically an iterator version of [`all_partitions`](@ref).

See also [`partition_forest`](@ref) and [`partition_skeleton`](@ref).

# References

Section 2.3 of
- Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
  Algebraic Structures of B-series
  Foundations of Computational Mathematics
  [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
"""
struct PartitionIterator{T<:RootedTree}
  t::T
  edge_set::Vector{Bool}

  function PartitionIterator(t::T) where {T<:RootedTree}
    edge_set = zeros(Bool, order(t) - 1)
    new{T}(t, edge_set)
  end
end

Base.IteratorSize(::Type{<:PartitionIterator}) = Base.HasLength()
Base.length(partitions::PartitionIterator) = 2^length(partitions.edge_set)
Base.eltype(::Type{PartitionIterator{T}}) where {T} = Tuple{Vector{T}, T}

function Base.iterate(partitions::PartitionIterator)
  edge_set_value = 0
  iterate(partitions, edge_set_value)
end

function Base.iterate(partitions::PartitionIterator, edge_set_value)
  edge_set_value >= length(partitions) && return nothing

  t = partitions.t
  edge_set = partitions.edge_set

  digits!(edge_set, edge_set_value, base=2)
  forest = partition_forest(t, edge_set)
  skeleton = partition_skeleton(t, edge_set)
  ((forest, skeleton), edge_set_value + 1)
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
  Algebraic Structures of B-series
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
    digits!(node_set, node_set_value, base=2)

    # Check that if a node is removed then all of its descendants are removed
    subtree_root_index = 1
    forest = Vector{RootedTree{T, Vector{T}}}()
    while subtree_root_index <= order(t)
      if node_set[subtree_root_index] == false # This node is removed
        subtree_last_index = subtree_root_index
        while subtree_last_index < length(ls)
          if ls[subtree_last_index + 1] > ls[subtree_root_index]
            subtree_last_index += 1
          else
            break
          end
        end

        # Check that subtree is all removed
        if !any(@view node_set[subtree_root_index:subtree_last_index])
          push!(forest, rootedtree(@view ls[subtree_root_index:subtree_last_index]))
          subtree_root_index = subtree_last_index + 1
        else
          break
        end
      else
        subtree_root_index += 1
      end
    end

    if subtree_root_index == order(t) + 1
      # This is a valid ordered subtree
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
  Algebraic Structures of B-series
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

  while node_set_value <= splittings.max_node_set_value
    digits!(node_set, node_set_value, base=2)

    # Check that if a node is removed then all of its descendants are removed
    subtree_root_index = 1
    forest = Vector{RootedTree{T, Vector{T}}}()
    while subtree_root_index <= order(t)
      if node_set[subtree_root_index] == false # This node is removed
        subtree_last_index = subtree_root_index
        while subtree_last_index < length(ls)
          if ls[subtree_last_index + 1] > ls[subtree_root_index]
            subtree_last_index += 1
          else
            break
          end
        end

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
      # This is a valid ordered subtree
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

The `order` of a rooted tree, i.e., the length of its level sequence.
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

Returns the representation of `t::RootedTree` as introduced by Butcher.

Reference: Section 301 of
- Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function butcher_representation(t::RootedTree)
  if order(t) == 1
    return "τ"
  end

  subtr = Subtrees(t)
  result = ""
  for i in eachindex(subtr)
    result = result * butcher_representation(subtr[i])
  end
  result = "[" * result * "]"

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

  return result
end


end # module
