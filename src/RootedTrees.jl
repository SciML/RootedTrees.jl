module RootedTrees


using LinearAlgebra

import Base: show, isless, ==, iterate, copy


export rootedtree, RootedTreeIterator

export α, β, γ, σ, order, residual_order_condition, elementary_weight, derivative_weight

export count_trees



"""
    RootedTree

Represents a rooted tree using its level sequence.

Reference:
  Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
"""
mutable struct RootedTree{T<:Integer, V<:AbstractVector}
  level_sequence::V
  iscanonical::Bool
end

function RootedTree(level_sequence::AbstractVector, iscanonical=false)
  T = eltype(level_sequence)
  V = typeof(level_sequence)
  RootedTree{T,V}(level_sequence, iscanonical)
end

"""
    rootedtree

Construct a canonical `RootedTree` object from a level sequence.

Reference:
  Beyer, Terry, and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees."
  SIAM Journal on Computing 9.4 (1980): 706-712.
"""
rootedtree(level_sequence::AbstractVector) = canonical_representation(RootedTree(level_sequence))

iscanonical(t::RootedTree) = t.iscanonical
#TODO: Validate rooted tree in constructor?

copy(t::RootedTree) = RootedTree(copy(t.level_sequence), t.iscanonical)


#  #function RootedTree(sequence::Vector{T}, valid::Bool)
#  function RootedTree(sequence::Array{T,1})
#    length(sequence) < 1 && throw(ArgumentError("Rooted trees must have a root, in particular at least one element!"))#
#
#    ## If there is only one element, the sequence must be valid.
#    #if !valid && length(sequence) > 1
#    #  # Test, whether there is exactly one root element at the beginning of sequence, if necessary.
#    #  root = sequence[1]
#    #  for level in sequence[2:end]
#    #    level <= root && throw(ArgumentError("Rooted trees must have exactly one element at root-level at the beginning."))
#    #  end
#    #end
#    # If there is only one element, the sequence must be valid.
#    if length(sequence) > 1
#      # Test, whether there is exactly one root element at the beginning of sequence, if necessary.
#      root = sequence[1]
#      for level in sequence[2:end]
#        level <= root && throw(ArgumentError("Rooted trees must have exactly one element at root-level at the beginning."))
#      end
#    end
#
#    new(sequence)
#  end
#RootedTree{T<:Integer}(sequence::Vector{T}) = RootedTree{T}(sequence, false)


function show(io::IO, t::RootedTree{T}) where {T}
  print(io, "RootedTree{", T, "}: ")
  show(io, t.level_sequence)
end


# comparison

"""
    isless(t1::RootedTree, t2::RootedTree)

Compares two rooted trees using a lexicographical comparison of their level sequences.
"""
function isless(t1::RootedTree, t2::RootedTree)
  isless(t1.level_sequence, t2.level_sequence)
end

function ==(t1::RootedTree, t2::RootedTree)
  t1.level_sequence == t2.level_sequence
end


# generation and canonical representation
"""
    canonical_representation!(t::RootedTree)

Change the representation of the rooted tree `t` to the canonical one, i.e. the
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
    t.level_sequence[i:i+order(τ)-1] = τ.level_sequence[:]
    i += order(τ)
  end
  t.iscanonical = true

  t
end

"""
    canonical_representation(t::RootedTree)

Returns a new tree using the canonical representation of the rooted tree `t`,
i.e. the one with lexicographically biggest level sequence.
"""
function canonical_representation(t::RootedTree)
  canonical_representation!(copy(t))
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


function iterate(iter::RootedTreeIterator{T}) where {T}
  iter.t.level_sequence[:] = one(T):iter.order
  (iter.t, false)
end

function iterate(iter::RootedTreeIterator{T}, state) where {T}
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


# functions on trees

"""
    order(t::RootedTree)

The `order` of a rooted tree, i.e. the length of it's level sequence.
"""
order(t::RootedTree) = length(t.level_sequence)


"""
    σ(t::RootedTree)

The symmetry `σ` of a rooted tree `t`, i.e. the order of the group of automorphisms
on a particular labelling (of the vertices) of `t`.

Reference: Section 301 of
  Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function σ(t::RootedTree)
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
      sym *= factorial(num) * σ(subtr[i-1])^num
      num = 1
    end
  end
  sym *= factorial(num) * σ(subtr[end])^num
end


"""
    γ(t::RootedTree)

The density `γ(t)` of a rooted tree, i.e. the product over all vertices of `t`
of the order of the subtree rooted at that vertex.

Reference: Section 301 of
  Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function γ(t::RootedTree)
  if order(t) == 1
    return 1
  elseif order(t) == 2
    return 2
  end

  subtr = Subtrees(t)
  den = order(t)
  for τ in subtr
    den *= γ(τ)
  end
  den
end


"""
    α(t::RootedTree)

The number of monotonic labellings of `t` not equivalent under the symmetry group.

Reference: Section 302 of
  Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function α(t::RootedTree)
  div(factorial(order(t)), σ(t)*γ(t))
end


"""
    β(t::RootedTree)

The total number of labellings of `t` not equivalent under the symmetry group.

Reference: Section 302 of
  Butcher, John Charles.
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
  Butcher, John Charles.
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
  Butcher, John Charles.
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
  Butcher, John Charles.
  Numerical methods for ordinary differential equations.
  John Wiley & Sons, 2008.
"""
function residual_order_condition(t::RootedTree, A, b, c)
  ew = elementary_weight(t, A, b, c)
  T = typeof(ew)

  (ew - one(T) / γ(t)) / σ(t)
end


end # module
