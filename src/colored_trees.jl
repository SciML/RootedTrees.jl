
"""
    ColoredRootedTree(level_sequence, color_sequence, is_canonical::Bool=false)

Represents a colored rooted tree using its level sequence. The single-colored
version is [`RootedTree`](@ref).

See also [`BicoloredRootedTree`](@ref), [`rootedtree`](@ref).

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
struct ColoredRootedTree{T <: Integer, V <: AbstractVector{T}, C <: AbstractVector} <:
       AbstractRootedTree
    level_sequence::V
    color_sequence::C
    iscanonical::Bool

    function ColoredRootedTree(level_sequence::V, color_sequence::C,
                               iscanonical::Bool = false) where {T <: Integer,
                                                                 V <: AbstractVector{T},
                                                                 C <: AbstractVector}
        new{T, V, C}(level_sequence, color_sequence, iscanonical)
    end
end

"""
    BicoloredRootedTree{T<:Integer}

Representation of bicolored rooted trees.

See also [`ColoredRootedTree`](@ref), [`RootedTree`](@ref), [`rootedtree`](@ref).
"""
const BicoloredRootedTree{T <: Integer, V <: AbstractVector{T}, C <: AbstractVector{Bool}} = ColoredRootedTree{
                                                                                                               T,
                                                                                                               V,
                                                                                                               C
                                                                                                               }

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
function rootedtree!(level_sequence::AbstractVector, color_sequence::AbstractVector)
    canonical_representation!(ColoredRootedTree(level_sequence, color_sequence))
end

iscanonical(t::ColoredRootedTree) = t.iscanonical
#TODO: Validate rooted tree in constructor?

function Base.copy(t::ColoredRootedTree)
    ColoredRootedTree(copy(t.level_sequence), copy(t.color_sequence), t.iscanonical)
end
function Base.similar(t::ColoredRootedTree)
    ColoredRootedTree(similar(t.level_sequence), similar(t.color_sequence), true)
end
Base.isempty(t::ColoredRootedTree) = isempty(t.level_sequence)
function Base.empty(t::ColoredRootedTree)
    ColoredRootedTree(empty(t.level_sequence), empty(t.color_sequence), iscanonical(t))
end

@inline function Base.copy!(t_dst::ColoredRootedTree, t_src::ColoredRootedTree)
    copy!(t_dst.level_sequence, t_src.level_sequence)
    copy!(t_dst.color_sequence, t_src.color_sequence)
    return t_dst
end

"""
    root_color(t::ColoredRootedTree)

Return the color of the root of `t`.
"""
root_color(t::ColoredRootedTree) = first(t.color_sequence)

# Internal interface
@inline function unsafe_deleteat!(t::ColoredRootedTree, i)
    deleteat!(t.level_sequence, i)
    deleteat!(t.color_sequence, i)
    return t
end

# Internal interface
@inline function unsafe_resize!(t::ColoredRootedTree, n::Integer)
    resize!(t.level_sequence, n)
    resize!(t.color_sequence, n)
    return t
end

# Internal interface
@inline function unsafe_copyto!(t_dst::ColoredRootedTree, dst_offset,
                                t_src::ColoredRootedTree, src_offset, N)
    copyto!(t_dst.level_sequence, dst_offset, t_src.level_sequence, src_offset, N)
    copyto!(t_dst.color_sequence, dst_offset, t_src.color_sequence, src_offset, N)
    return t_dst
end

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
    if length(t1.level_sequence) != length(t2.level_sequence)
        return isless(length(t1.level_sequence), length(t2.level_sequence))
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
    for (e1, c1, e2, c2) in zip(t1.level_sequence, t1.color_sequence, t2.level_sequence,
                                t2.color_sequence)
        v1 = e1
        v2 = e2 + root1_minus_root2
        (v1 == v2 && c1 == c2) || return false
    end

    return true
end

# Factor out equivalence classes given by different roots
function Base.hash(t::ColoredRootedTree, h::UInt)
    # Use a fast path if possible
    if UInt == UInt64 && t isa BicoloredRootedTree && order(t) <= 12
        return simple_hash(t, h)
    end

    isempty(t.level_sequence) && return h
    root = first(t.level_sequence)
    for (l, c) in zip(t.level_sequence, t.color_sequence)
        h = hash(l - root, h)
        h = hash(c, h)
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
# The binary color sequence is mapped to an unsigned integer by interpreting
# the Boolean colors as bits of an unsigned integer. Thus, we need one
# additional bit per level to store also the color information. Thus, we
# can use this simple version with 64 bits up to a maximal length of 12
# (maximal_drop = 9; number_of_bits = 4; max_length * (number_of_bits + 1) = 60)
@inline function simple_hash(t::BicoloredRootedTree, h_base::UInt64)
    isempty(t.level_sequence) && return h_base
    h = zero(h_base)
    l_prev = first(t.level_sequence)
    for l in t.level_sequence
        h = (h << 4) | (l_prev + 1 - l)
        l_prev = l
    end
    for c in t.color_sequence
        h = (h << 1) | c
    end
    return hash(h, h_base)
end

# generation and canonical representation
# A very simple implementation of `canonical_representation!` could read as
# follows.
#     function canonical_representation!(t::ColoredRootedTree)
#       subtr = subtrees(t)
#       for i in eachindex(subtr)
#         canonical_representation!(subtr[i])
#       end
#       sort!(subtr, rev=true)

#       i = 2
#       for τ in subtr
#         t.level_sequence[i:i+order(τ)-1] = τ.level_sequence
#         t.color_sequence[i:i+order(τ)-1] = τ.color_sequence
#         i += order(τ)
#       end

#       ColoredRootedTree(t.level_sequence, t.color_sequence, true)
#     end
# However, this would create a lot of intermediate allocations, which make it
# rather slow. Since most trees in use are relatively small, we can use a
# non-allocating sorting algorithm instead - although bubble sort is slower in
# general when comparing the complexity with quicksort etc., it will be faster
# here since we can avoid allocations.
function canonical_representation!(t::ColoredRootedTree,
                                   buffer_level = similar(t.level_sequence),
                                   buffer_color = similar(t.color_sequence))
    # Since we use a recursive implementation, it is useful to exit early for
    # small trees. If there are at most 3 vertices in a valid rooted tree, its
    # level sequence must already be in canonical representation. However, the
    # color sequence of the bushy tree may be wrong. Thus, we can only skip the
    # sorting for colored trees with at most two nodes.
    if order(t) <= 2
        return ColoredRootedTree(t.level_sequence, t.color_sequence, true)
    end

    # First, sort all subtrees recursively. Here, we use `view`s to avoid memory
    # allocations.
    # TODO: Assume 1-based indexing in the following
    subtree_root_index = 2
    number_of_subtrees = 0

    while subtree_root_index <= order(t)
        subtree_last_index = _subtree_last_index(subtree_root_index, t.level_sequence)

        # We found a complete subtree
        idx_subtree = subtree_root_index:subtree_last_index
        subtree = ColoredRootedTree(view(t.level_sequence, idx_subtree),
                                    view(t.color_sequence, idx_subtree))
        canonical_representation!(subtree,
                                  view(buffer_level, idx_subtree),
                                  view(buffer_color, idx_subtree))

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
                subtree1_last_index = _subtree_last_index(subtree1_root_index,
                                                          t.level_sequence)
                subtree2_last_index = subtree1_last_index

                # Search the next complete subtree
                subtree1_last_index == subtree_last_index_to_sort && break

                subtree2_root_index = subtree1_last_index + 1
                subtree2_last_index = _subtree_last_index(subtree2_root_index,
                                                          t.level_sequence)

                # Swap the subtrees if they are not sorted correctly
                subtree1_idx = subtree1_root_index:subtree1_last_index
                subtree1 = ColoredRootedTree(view(t.level_sequence, subtree1_idx),
                                             view(t.color_sequence, subtree1_idx))
                subtree2_idx = subtree2_root_index:subtree2_last_index
                subtree2 = ColoredRootedTree(view(t.level_sequence, subtree2_idx),
                                             view(t.color_sequence, subtree2_idx))
                if isless(subtree1, subtree2)
                    copyto!(buffer_level, 1, t.level_sequence, subtree1_root_index,
                            order(subtree1) + order(subtree2))
                    copyto!(t.level_sequence, subtree1_root_index, buffer_level,
                            order(subtree1) + 1, order(subtree2))
                    copyto!(t.level_sequence, subtree1_root_index + order(subtree2),
                            buffer_level, 1, order(subtree1))

                    copyto!(buffer_color, 1, t.color_sequence, subtree1_root_index,
                            order(subtree1) + order(subtree2))
                    copyto!(t.color_sequence, subtree1_root_index, buffer_color,
                            order(subtree1) + 1, order(subtree2))
                    copyto!(t.color_sequence, subtree1_root_index + order(subtree2),
                            buffer_color, 1, order(subtree1))

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

    ColoredRootedTree(t.level_sequence, t.color_sequence, true)
end

"""
    BicoloredRootedTreeIterator(order::Integer)

Iterator over all bi-colored rooted trees of given `order`. The returned trees
are views to an internal tree modified during the iteration. If the returned
trees shall be stored or modified during the iteration, a `copy` has to be made.
"""
struct BicoloredRootedTreeIterator{T <: Integer}
    number_of_colors::T
    iter::RootedTreeIterator{T}
    t::BicoloredRootedTree{T, Vector{T}, Vector{Bool}}

    function BicoloredRootedTreeIterator(order::T) where {T <: Integer}
        iter = RootedTreeIterator(order)
        number_of_colors = convert(T, 2)^order
        t = ColoredRootedTree(iter.t.level_sequence, zeros(Bool, order), true)
        new{T}(number_of_colors, iter, t)
    end
end

Base.IteratorSize(::Type{<:BicoloredRootedTreeIterator}) = Base.SizeUnknown()
function Base.eltype(::Type{BicoloredRootedTreeIterator{T}}) where {T}
    BicoloredRootedTree{T, Vector{T}, Vector{Bool}}
end

@inline function Base.iterate(iter::BicoloredRootedTreeIterator)
    _, inner_state = iterate(iter.iter)
    color_id = 0
    binary_digits!(iter.t.color_sequence, color_id)
    (iter.t, (inner_state, color_id + 1))
end

@inline function Base.iterate(iter::BicoloredRootedTreeIterator, state)
    inner_state, color_id = state

    # If we can iterate more by changing the color sequence, let's do so.
    while color_id < iter.number_of_colors
        binary_digits!(iter.t.color_sequence, color_id)

        # This simple enumeration of all possible colors can also yield colored
        # trees that are not in canonical representation. For example, the trees
        #   rootedtree([1, 2, 2], Bool[0, 0, 1])
        #   rootedtree([1, 2, 2], Bool[1, 0, 1])
        # are not in canonical representation.
        # TODO: ColoredRootedTrees. Is there a more efficient way to get only
        #       canonical representations?
        if check_canonical(iter.t)
            return (iter.t, (inner_state, color_id + 1))
        else
            color_id = color_id + 1
        end
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

@inline function Base.iterate(subtrees::SubtreeIterator{<:ColoredRootedTree},
                              subtree_root_index)
    level_sequence = subtrees.t.level_sequence
    color_sequence = subtrees.t.color_sequence

    # terminate the iteration if there are no further subtrees
    if subtree_root_index > lastindex(level_sequence)
        return nothing
    end

    # find the next complete subtree
    subtree_last_index = _subtree_last_index(subtree_root_index, level_sequence)
    subtree = ColoredRootedTree(view(level_sequence, subtree_root_index:subtree_last_index),
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
    subtr = ColoredRootedTree{eltype(t.level_sequence),
                              Vector{eltype(t.level_sequence)},
                              Vector{eltype(t.color_sequence)}}[]

    if length(t.level_sequence) < 2
        return subtr
    end

    start = 2
    i = 3
    while i <= length(t.level_sequence)
        if t.level_sequence[i] <= t.level_sequence[start]
            push!(subtr,
                  ColoredRootedTree(t.level_sequence[start:(i - 1)],
                                    t.color_sequence[start:(i - 1)]))
            start = i
        end
        i += 1
    end
    push!(subtr,
          ColoredRootedTree(t.level_sequence[start:end], t.color_sequence[start:end]))
end

# partitions
# We only need to specialize this performance enhancement. The remaining parts
# are implemented generically.
function PartitionIterator(t::ColoredRootedTree{Int, Vector{Int}, Vector{Bool}})
    order_t = order(t)

    if order_t <= BUFFER_LENGTH
        id = Threads.threadid()

        buffer_forest_t = PARTITION_ITERATOR_BUFFER_FOREST_T[id]
        resize!(buffer_forest_t, order_t)
        buffer_forest_t_colors = PARTITION_ITERATOR_BUFFER_FOREST_T_COLORS[id]
        resize!(buffer_forest_t_colors, order_t)
        level_sequence = PARTITION_ITERATOR_BUFFER_FOREST_LEVEL_SEQUENCE[id]
        resize!(level_sequence, order_t)
        color_sequence = PARTITION_ITERATOR_BUFFER_FOREST_COLOR_SEQUENCE[id]
        resize!(color_sequence, order_t)
        buffer_skeleton = PARTITION_ITERATOR_BUFFER_SKELETON[id]
        resize!(buffer_skeleton, order_t)
        buffer_skeleton_colors = PARTITION_ITERATOR_BUFFER_SKELETON_COLORS[id]
        resize!(buffer_skeleton_colors, order_t)
        edge_set = PARTITION_ITERATOR_BUFFER_EDGE_SET[id]
        resize!(edge_set, order_t - 1)
        edge_set_tmp = PARTITION_ITERATOR_BUFFER_EDGE_SET_TMP[id]
        resize!(edge_set_tmp, order_t - 1)
    else
        buffer_forest_t = Vector{Int}(undef, order_t)
        buffer_forest_t_colors = Vector{Bool}(undef, order_t)
        level_sequence = similar(buffer_forest_t)
        color_sequence = similar(buffer_forest_t_colors)
        buffer_skeleton = similar(buffer_forest_t)
        buffer_skeleton_colors = similar(buffer_forest_t_colors)
        edge_set = Vector{Bool}(undef, order_t - 1)
        edge_set_tmp = similar(edge_set)
    end

    skeleton = ColoredRootedTree(buffer_skeleton, buffer_skeleton_colors, true)
    t_forest = ColoredRootedTree(buffer_forest_t, buffer_forest_t_colors, true)
    t_temp_forest = ColoredRootedTree(level_sequence, color_sequence, true)
    forest = PartitionForestIterator(t_forest, t_temp_forest, edge_set_tmp)
    PartitionIterator{typeof(t), ColoredRootedTree{Int, Vector{Int}, Vector{Bool}}}(t,
                                                                                    forest,
                                                                                    skeleton,
                                                                                    edge_set,
                                                                                    edge_set_tmp)
end

# TODO: ColoredRootedTree. splittings
# SplittingIterator

# additional representation and construction methods

function Base.:∘(t1::ColoredRootedTree, t2::ColoredRootedTree)
    offset = first(t1.level_sequence) - first(t2.level_sequence) + 1
    level_sequence = vcat(t1.level_sequence, t2.level_sequence .+ offset)
    color_sequence = vcat(t1.color_sequence, t2.color_sequence)
    rootedtree(level_sequence, color_sequence)
end

function butcher_representation(t::ColoredRootedTree, normalize::Bool = true;
                                colormap = _colormap_butcher_representation(t))
    if order(t) == 0
        return "∅"
    elseif order(t) == 1
        return "τ" * colormap[root_color(t)]
    end

    result = ""
    for subtree in SubtreeIterator(t)
        result = result * butcher_representation(subtree, normalize, colormap = colormap)
    end
    result = "[" * result * "]" * colormap[root_color(t)]

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
