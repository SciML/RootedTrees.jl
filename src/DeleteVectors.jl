module DeleteVectors

export DeleteVector

# mutable struct DeleteVector{T, Parent <: AbstractVector{T}} <: AbstractVector{T}
#   parent::Parent
#   length::Int
# end

struct DeleteVector{T, Parent <: AbstractVector{T}} <: AbstractVector{T}
  parent::Parent
  length::Base.RefValue{Int}
end


function DeleteVector(parent::AbstractVector)
  DeleteVector(parent, Ref(length(parent)))
end

function DeleteVector{T}(sizehint::Integer = 4) where {T}
  sizehint >= 0 || throw(DomainError(sizehint, "Invalid initial size."))
  DeleteVector(Vector{T}(undef, sizehint), Ref(0))
end

@inline Base.parent(v::DeleteVector) = v.parent
@inline Base.pointer(v::DeleteVector) = pointer(parent(v))
@inline Base.pointer(v::DeleteVector, i::Integer) = pointer(parent(v), i)

@inline Base.size(v::DeleteVector) = (v.length[], )
Base.IndexStyle(::DeleteVector) = IndexLinear()

@inline function Base.getindex(v::DeleteVector, i)
  @boundscheck checkbounds(v, i)
  @inbounds v.parent[i]
end

@inline function Base.setindex!(v::DeleteVector, x, i)
  @boundscheck checkbounds(v, i)
  @inbounds v.parent[i] = x
end


Base.copy(v::DeleteVector) = DeleteVector(copy(parent(v)), Ref(length(v)))
Base.similar(v::DeleteVector) = DeleteVector(similar(parent(v)), Ref(length(v)))

function Base.copyto!(dest::DeleteVector, doffs::Integer,
                      src::DeleteVector,  soffs::Integer, n::Integer)
  copyto!(parent(dest), doffs, parent(src), soffs, n)
end

Base.view(v::DeleteVector, inds::UnitRange) = view(parent(v), inds)


function Base.sizehint!(v::DeleteVector, n)
  if length(parent(v)) < n || n >= length(v)
    resize!(v.parent, n)
  end
  nothing
end

function Base.resize!(v::DeleteVector, n)
  if length(parent(v)) < n
    resize!(v.parent, n)
  end
  v.length[] = n
  v
end

Base.empty!(v::DeleteVector) = (v.length[] = 0; v)


function Base.deleteat!(v::DeleteVector, i::Integer)
  @boundscheck checkbounds(v, i)
  p = parent(v)
  for j in i+1:lastindex(v)
    @inbounds p[j-1] = p[j]
  end
  v.length[] -= 1
  v
end

function Base.deleteat!(v::DeleteVector, inds::UnitRange)
  @boundscheck checkbounds(v, inds)
  p = parent(v)
  i = first(inds)
  offset = length(inds)
  for j in i+1:lastindex(v)
    @inbounds p[j-offset] = p[j]
  end
  v.length[] -= offset
  v
end


Base.findprev(v::DeleteVector, i::Integer) = findprev(parent(v), i)
# TODO: findnext, findlast, findfirst, function arguments

end # module
