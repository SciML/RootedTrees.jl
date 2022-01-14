
"""
    ColoredRootedTree(level_sequence, color_sequence, is_canonical::Bool=false)

Represents a colored rooted tree using its level sequence. The single-colored
version is [`RootedTree`](@ref).

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
- A. L. Araujo, A. Murua, and J. M. Sanz-Serna.
  "Symplectic Methods Based on Decompositions".
  SIAM Journal on Numerical Analysis 34.5 (1997): 1926–1947.
  [DOI: 10.1137/S0036142995292128](https://doi.org/10.1137/S0036142995292128)
"""
struct ColoredRootedTree{T<:Integer, V<:AbstractVector{T}, C<:AbstractVector} <: AbstractRootedTree
  level_sequence::V
  color_sequence::C
  iscanonical::Bool

  function ColoredRootedTree(level_sequence::V, color_sequence::C, iscanonical::Bool=false) where {T<:Integer, V<:AbstractVector{T}, C<:AbstractVector}
    new{T, V, C}(level_sequence, color_sequence, iscanonical)
  end
end


const BicoloredRootedTree{T<:Integer, V<:AbstractVector{T}, C<:AbstractVector{Bool}} = ColoredRootedTree{T, V, C}


"""
    rootedtree(level_sequence, color_sequence)

Construct a canonical [`ColoredRootedTree`](@ref) object from a `level_sequence`
and a `color_sequence`, i.e., a vector of integers representing the levels of
each node of the tree and a vector of associated colors (e.g., `Bool`s or
`Integers`).

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
function rootedtree(level_sequence::AbstractVector, color_sequence::AbstractVector)
  if axes(level_sequence) != axes(color_sequence)
    throw(DimensionMismatch("The axes of the `level_sequence` ($level_sequence) and the `color_sequence` ($color_sequence) do not match."))
  end

  canonical_representation(ColoredRootedTree(level_sequence, color_sequence))
end

"""
    rootedtree!(level_sequence, color_sequence)

Construct a canonical [`ColoredRootedTree`](@ref) object from a `level_sequence`
and a `color_sequence` which may be modified in this process. See also
[`rootedtree`](@ref).

# References

- Terry Beyer and Sandra Mitchell Hedetniemi.
  "Constant time generation of rooted trees".
  SIAM Journal on Computing 9.4 (1980): 706-712.
  [DOI: 10.1137/0209055](https://doi.org/10.1137/0209055)
"""
rootedtree!(level_sequence::AbstractVector, color_sequence::AbstractVector) = canonical_representation!(ColoredRootedTree(level_sequence, color_sequence))

iscanonical(t::ColoredRootedTree) = t.iscanonical
#TODO: Validate rooted tree in constructor?

Base.copy(t::ColoredRootedTree) = ColoredRootedTree(copy(t.level_sequence), copy(t.color_sequence), t.iscanonical)
Base.isempty(t::ColoredRootedTree) = isempty(t.level_sequence)
Base.empty(t::ColoredRootedTree) = ColoredRootedTree(empty(t.level_sequence), empty(t.color_sequence), iscanonical(t))


function Base.show(io::IO, t::ColoredRootedTree{T}) where {T}
  # print(io, "ColoredRootedTree{", T, "}: [")
  # if !isempty(t)
  #   print(io, first(t.level_sequence), " (", first(t.color_sequence), ")")
  #   for i in Iterators.drop(eachindex(t.level_sequence, t.color_sequence), 1)
  #     print(io, ", ", t.level_sequence[i], " (", t.color_sequence[i], ")")
  #   end
  # end
  # print(io, "]")
  print(io, "ColoredRootedTree{", T, "}: ")
  show(io, (t.level_sequence, t.color_sequence))
end


# comparison

"""
    isless(t1::ColoredRootedTree, t2::ColoredRootedTree)

Compares two colored rooted trees using a lexicographical comparison of their
level (first) and color (second) sequences while considering equivalence classes
given by different root indices.
"""
function Base.isless(t1::ColoredRootedTree, t2::ColoredRootedTree)
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
    (v1 == v2) || return isless(v1, v2)
  end
  return isless(t1.color_sequence, t2.color_sequence)
end

"""
    ==(t1::ColoredRootedTree, t2::ColoredRootedTree)

Compares two rooted trees based on their level (first) and color (second)
sequences while considering equivalence classes given by different root indices.
```
"""
function Base.:(==)(t1::ColoredRootedTree, t2::ColoredRootedTree)
  length(t1.level_sequence) == length(t2.level_sequence) || return false

  if isempty(t1.level_sequence)
    # empty trees are equal
    return true
  end

  root1_minus_root2 = first(t1.level_sequence) - first(t2.level_sequence)
  for (e1, c1, e2, c2) in zip(t1.level_sequence, t1.color_sequence, t2.level_sequence, t2.color_sequence)
    v1 = e1
    v2 = e2 + root1_minus_root2
    (v1 == v2 && c1 == c2) || return false
  end

  return true
end


# Factor out equivalence classes given by different roots
function Base.hash(t::ColoredRootedTree, h::UInt)
  # TODO: ColoredRootedTree. Use a fast path if possible
  isempty(t.level_sequence) && return h
  root = first(t.level_sequence)
  for (l, c) in zip(t.level_sequence, t.color_sequence)
    h = hash(l - root, h)
    h = hash(c, h)
  end
  return h
end


# generation and canonical representation
# TODO: ColoredRootedTree. Performance improvements possible using in-place sort
function canonical_representation!(t::ColoredRootedTree)
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

  ColoredRootedTree(t.level_sequence, t.color_sequence, true)
end



"""
    BicoloredRootedTreeIterator(order::Integer)

Iterator over all bi-colored rooted trees of given `order`. The returned trees
are views to an internal tree modified during the iteration. If the returned
trees shall be stored or modified during the iteration, a `copy` has to be made.
"""
struct BicoloredRootedTreeIterator{T<:Integer}
  number_of_colors::T
  iter::RootedTreeIterator{T}
  t::BicoloredRootedTree{T, Vector{T}, Vector{Bool}}

  function BicoloredRootedTreeIterator(order::T) where {T<:Integer}
    iter = RootedTreeIterator(order)
    number_of_colors = convert(T, 2)^order
    t = ColoredRootedTree(iter.t.level_sequence, zeros(Bool, order), true)
    new{T}(number_of_colors, iter, t)
  end
end

Base.IteratorSize(::Type{<:BicoloredRootedTreeIterator}) = Base.SizeUnknown()
Base.eltype(::Type{BicoloredRootedTreeIterator{T}}) where T = BicoloredRootedTree{T, Vector{T}, Vector{Bool}}

@inline function Base.iterate(iter::BicoloredRootedTreeIterator)
  _, inner_state = iterate(iter.iter)
  color_id = 0
  binary_digits!(iter.t.color_sequence, color_id)
  (iter.t, (inner_state, color_id + 1))
end

@inline function Base.iterate(iter::BicoloredRootedTreeIterator, state)
  inner_state, color_id = state

  # If we can iterate more by changing the color sequence, let's do so.
  if color_id < iter.number_of_colors
    binary_digits!(iter.t.color_sequence, color_id)
    return (iter.t, (inner_state, color_id + 1))
  end

  # Now, we need to iterate to a new baseline (uncolored) tree - if possible
  inner_value_state = iterate(iter.iter, inner_state)
  if inner_value_state === nothing
    return nothing
  end

  _, inner_state = inner_value_state
  color_id = 0
  binary_digits!(iter.t.color_sequence, color_id)
  return (iter.t, (inner_state, color_id + 1))
end



# subtrees
@inline function Base.iterate(subtrees::SubtreeIterator{<:ColoredRootedTree})
  subtree_root_index = firstindex(subtrees.t.level_sequence) + 1
  iterate(subtrees, subtree_root_index)
end

@inline function Base.iterate(subtrees::SubtreeIterator{<:ColoredRootedTree}, subtree_root_index)
  level_sequence = subtrees.t.level_sequence
  color_sequence = subtrees.t.color_sequence

  # terminate the iteration if there are no further subtrees
  if subtree_root_index > lastindex(level_sequence)
    return nothing
  end

  # find the next complete subtree
  subtree_last_index = _subtree_last_index(subtree_root_index, level_sequence)
  subtree = ColoredRootedTree(
    view(level_sequence, subtree_root_index:subtree_last_index),
    view(color_sequence, subtree_root_index:subtree_last_index),
    # if t is in canonical representation, its subtrees are, too
    iscanonical(subtrees.t))

  return (subtree, subtree_last_index + 1)
end


"""
    subtrees(t::ColoredRootedTree)

Returns a vector of all subtrees of `t`.
"""
function subtrees(t::ColoredRootedTree)
  subtr = typeof(t)[]

  if length(t.level_sequence) < 2
    return subtr
  end

  start = 2
  i = 3
  while i <= length(t.level_sequence)
    if t.level_sequence[i] <= t.level_sequence[start]
      push!(subtr, ColoredRootedTree(t.level_sequence[start:i-1], t.color_sequence[start:i-1]))
      start = i
    end
    i += 1
  end
  push!(subtr, ColoredRootedTree(t.level_sequence[start:end], t.color_sequence[start:end]))
end


# additional representation and construction methods

function Base.:∘(t1::ColoredRootedTree, t2::ColoredRootedTree)
  offset = first(t1.level_sequence) - first(t2.level_sequence) + 1
  level_sequence = vcat(t1.level_sequence, t2.level_sequence .+ offset)
  color_sequence = vcat(t1.color_sequence, t2.color_sequence)
  rootedtree(level_sequence, color_sequence)
end


function butcher_representation(t::ColoredRootedTree, normalize::Bool=true;
                                colormap=_colormap_butcher_representation(t))
  if order(t) == 0
    return "∅"
  elseif order(t) == 1
    return "τ" * colormap[first(t.color_sequence)]
  end

  result = ""
  for subtree in SubtreeIterator(t)
    result = result * butcher_representation(subtree, normalize, colormap=colormap)
  end
  result = "[" * result * "]" * colormap[first(t.color_sequence)]

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
      for index in values(colormap)
        str = "τ" * index
        result = replace(result, str^n => str * n_str)
      end
    end
  end

  return result
end

function _colormap_butcher_representation(t::ColoredRootedTree)
  colors = sort!(unique(t.color_sequence))
  if length(colors) > 10
    @error "Not implemented for trees with more than 10 colors"
  end

  indices = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]

  colormap = Dict{eltype(colors), String}()

  if issubset(colors, 0:9) || eltype(colors) == Bool
    for color in colors
      colormap[color] = indices[color + 1]
    end
  else
    for (color, index) in zip(colors, indices)
      colormap[color] = index
    end
  end

  return colormap
end
