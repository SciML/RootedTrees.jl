
struct RootedTreeVertexList
  children::Vector{RootedTreeVertexList}
  isempty::Bool
  iscanonical::Bool
end

const RootedTreeVL = RootedTreeVertexList

function RootedTreeVL(t::RootedTree)
  children = Vector{RootedTreeVL}()
  for subtree in SubtreeIterator(t)
    push!(children, RootedTreeVL(subtree))
  end
  RootedTreeVL(children, isempty(t), iscanonical(t))
end

function RootedTree(t::RootedTreeVL, root=1)
  isempty(t) && return RootedTree(Vector{typeof(root)}(), iscanonical(t))

  level_sequence = [root]
  for subtree in t.children
    append!(level_sequence, RootedTree(subtree, root + 1).level_sequence)
  end
  RootedTree(level_sequence, iscanonical(t))
end


iscanonical(t::RootedTreeVL) = t.iscanonical

Base.copy(t::RootedTreeVL) = RootedTreeVL(copy(t.children), t.isempty, t.iscanonical)
Base.isempty(t::RootedTreeVL) = t.isempty
Base.empty(t::RootedTreeVL) = RootedTreeVL(empty(t.children), true, iscanonical(t))


function Base.show(io::IO, t::RootedTreeVL)
  print(io, "RootedTreeVL: ")
  show(io, RootedTree(t).level_sequence)
end


function Base.cmp(t1::RootedTreeVL, t2::RootedTreeVL)
  for (subtree1, subtree2) in zip(t1.children, t2.children)
    result = cmp(subtree1, subtree2)
    result != 0 && return result
  end
  return cmp(length(t1.children), length(t2.children))
end

Base.isless(t1::RootedTreeVL, t2::RootedTreeVL) = cmp(t1, t2) < 0
Base.:(==)(t1::RootedTreeVL, t2::RootedTreeVL) = cmp(t1, t2) == 0

# function Base.isless(t1::RootedTreeVL, t2::RootedTreeVL)
#   if isempty(t1)
#     if isempty(t2)
#       # empty trees are equal
#       return false
#     else
#       # the empty tree `isless` than any other tree
#       return true
#     end
#   elseif isempty(t2)
#     # the empty tree `isless` than any other tree
#     return false
#   end

#   for (subtree1, subtree2) in zip(t1.children, t2.children)
#     subtree1 == subtree2 || return isless(subtree1, subtree2)
#   end
#   return isless(order(t1), order(t2))
# end

# function Base.:(==)(t1::RootedTreeVL, t2::RootedTreeVL)
#   order(t1) == order(t2) || return false

#   if isempty(t1)
#     # empty trees are equal
#     return true
#   end

#   for (subtree1, subtree2) in zip(t1.children, t2.children)
#     subtree1 == subtree2 || return false
#   end

#   return true
# end


# TODO: Base.hash


function canonical_representation(t::RootedTreeVL)
  canonical_representation!(copy(t))
end

function canonical_representation!(t::RootedTreeVL)
  for subtree in t.children
    canonical_representation!(subtree)
  end

  # simple bubble sort
  n = length(t.children)
  swapped = true
  while swapped
    swapped = false
    for i in 2:n
      subtree1 = t.children[i-1]
      subtree2 = t.children[i]
      if subtree1 > subtree2
        t.children[i-1], t.children[i] = subtree2, subtree1
        swapped = true
      end
    end
    n = n - 1
  end

  RootedTreeVL(t.children, isempty(t), true)
end


# functions on trees

function order(t::RootedTreeVL)
  result = isempty(t) ? 0 : 1
  for subtree in t.children
    result += order(subtree)
  end
  result
end



function partition_skeleton(t::RootedTreeVL, edge_set)
  partition_skeleton!(copy(t), copy(edge_set))
end

function partition_skeleton!(t::RootedTreeVL, edge_set)

end
