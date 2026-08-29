module NPRKTrees

# Requires RootedTrees.jl package
using RootedTrees

export ARKTreeIterator
export NPRKTreeIterator
export isMultiColored
export GetParentIndex
export isColorBranching
export elementaryWeightNPRK2
export residualNPRK2

# see tests for these functions in the script ../test/nprktrees_test.jl

# Generates all non-isomorphic ARK trees with num_partitions (i.e., node colors) of a given order
# 	returned as a Vector of ColoredRootedTree's
function ARKTreeIterator(num_partitions::Int64, order::Int64)::Vector{<:ColoredRootedTree}
	toReturn = ColoredRootedTree[]

	if num_partitions < 1
		throw(DomainError(num_partitions,"num_partitions argument must be integer >= 1"))
	elseif order < 1
		throw(DomainError(order,"order argument must be integer >= 1"))
	elseif order == 1
		# if order is 1, generate trivial trees with root color 0<=i<=num_partitions-1
		for i in 0:num_partitions-1
			trivialtree = rootedtree([1],[i])
			push!(toReturn,trivialtree)
		end
	else
		# else order > 1
		# Generate all possible color sequences with colorings 0,1,...,num_partitions-1
		# 	of length order
		colors = reverse.(Iterators.product(fill(0:num_partitions-1,order)...))[:]

		# Loop over all uncolored rooted trees and append the above color sequences
		# 	to define colored rooted trees
		# Note that this will generate duplicate trees that are isomorphic
		for tree in RootedTreeIterator(order)
			for c in colors
				colorseq = collect(c)
				push!(toReturn, rootedtree(tree.level_sequence,colorseq))
			end
		end
	end
	# remove isomorphic trees
	toReturn = unique(toReturn,dims=1)
	return toReturn
end;

# Generates all non-isomorphic NPRK trees with num_partitions (i.e., edge colors) of a given order
#   equivalent to all ARK trees with num_partition colors of that order, with root node coloring fixed = 0
# 	returned as a Vector of ColoredRootedTree's
function NPRKTreeIterator(num_partitions::Int64, order::Int64)::Vector{<:ColoredRootedTree}
	toReturn = ColoredRootedTree[]
	
	if num_partitions < 1
		throw(DomainError(num_partitions,"num_partitions argument must be integer >= 1"))
	elseif order < 1
		throw(DomainError(order,"order argument must be integer >= 1"))
	elseif order == 1
		# if order is 1, generate trivial tree with fixed root color 0
		trivialtree = rootedtree([1],[0])
		push!(toReturn,trivialtree)
	else
		# else order > 1:
		# Generate all possible color sequences with colorings 0,1,...,partitions-1
		# 	of length order-1 (minus one because the root coloring is fixed to 0)
		colors = reverse.(Iterators.product(fill(0:num_partitions-1,order-1)...))[:]
	
		# Loop over all uncolored rooted trees and append the above color sequences
		# 	to define colored rooted trees with fixed root color 0
		# Note that this will generate duplicate trees that are isomorphic
		for tree in RootedTreeIterator(order)
			for c in colors
				colorseq = collect(c)
				pushfirst!(colorseq,0) # push 0 to start of color sequence
				push!(toReturn, rootedtree(tree.level_sequence,colorseq))
			end
		end
	end
	# remove isomorphic trees
	toReturn = unique(toReturn,dims=1)

	return toReturn
end;

# Determines whether a ColoredRootedTree is multicolored:
# 	argument root_color_fixed = true for NPRK trees, i.e., checks if edges of the NPRK tree are multicolored
# 	argument root_color_fixed = false for ARK trees, i.e., checks if nodes of the NPRK tree are multicolored
# 		corresponds to additive coupling conditions
function isMultiColored(colored_tree::ColoredRootedTree, root_color_fixed::Bool)::Bool
	if root_color_fixed
		colorseq = copy(colored_tree.color_sequence)
		popfirst!(colorseq)
		return ~allequal(colorseq)
	else
		return ~allequal(colored_tree.color_sequence)
	end
end

# For a given tree's level sequence and a given node in that level sequence specified by position nodeindex in the level sequence
# 	return the index in the level sequence of the parent node
#   note that if nodeindex == 1, i.e., the node specified is the root node, this returns 0 since the root has no parent
function GetParentIndex(levelseq::Vector, nodeindex::Int64)::Int64
	toReturn = 0
	for i in reverse(1:length(levelseq))
		if levelseq[i] == levelseq[nodeindex]-1
			toReturn = i
			break
		end
	end
	return toReturn
end

# Determines whether an NPRK tree is color branching, i.e.,
# 	it contains a node with out-degree at least two such that at least two of its outward (or upward) edges have different colors
#   such color branching trees corresponding to nonlinear NPRK order conditions
# Assumes order of the tree >= 3 (trees of order 1 and 2 cannot be color branching)
function isColorBranching(NPRK_tree::ColoredRootedTree)::Bool
	toReturn = false
	for i in 2:length(NPRK_tree.level_sequence)-1
		for j in i+1:length(NPRK_tree.level_sequence)
			if GetParentIndex(NPRK_tree.level_sequence,i) == GetParentIndex(NPRK_tree.level_sequence,j) && NPRK_tree.color_sequence[i] != NPRK_tree.color_sequence[j]
				toReturn = true
				break
			end
		end
	end
	return toReturn
end

# Computes the elementary weight of an NPRK tree for a given 
#	  NPRK tableau specified by: A cubic 3-tensor and b square matrix
#     corresponds to a 2-partition F(y,y)
function elementaryWeightNPRK2(Atens::Array, bmatrix::Array, NPRK_tree::ColoredRootedTree)::Float64
	toReturn = 0.0
	if length(size(Atens)) != 3 | length(size(bmatrix)) != 2
		throw(ArgumentError("This not a tableau for an NPRK method with 2 partitions"))
	elseif ~allequal(size(Atens)) | ~allequal(size(bmatrix))
		throw(ArgumentError("This tableau is not cubic/square"))	
	elseif length(NPRK_tree.level_sequence) == 1
		toReturn = sum(bmatrix)
	else
		numstages = copy(size(Atens)[1])
		order = length(NPRK_tree.level_sequence)
		singleitervec = collect(1:numstages)
		indexset = Iterators.product(ntuple(i->singleitervec, 2*order)...)

		for ikjk in indexset # represents indices i1, j1, i2, j2, ..., iN, jN where N=order
			prod = 1.0
			for k in reverse(2:order)
				if NPRK_tree.color_sequence[k] == 0
					prod *= Atens[ikjk[2*GetParentIndex(NPRK_tree.level_sequence, k)-1], ikjk[2*k-1], ikjk[2*k]]
				elseif NPRK_tree.color_sequence[k] == 1
					prod *= Atens[ikjk[2*GetParentIndex(NPRK_tree.level_sequence, k)], ikjk[2*k-1], ikjk[2*k]]
				else
					throw(ArgumentError("The edge colors must be 0 or 1"))
				end
			end
			toReturn += bmatrix[ikjk[1],ikjk[2]]*prod
		end
	end
	return toReturn
end

# computes the residual |elementaryweight - 1/density(tree)| for a given tree 
function residualNPRK2(Atens::Array, bmatrix::Array, NPRK_tree::ColoredRootedTree)::Float64
	return abs(elementaryWeightNPRK2(Atens, bmatrix, NPRK_tree)-1/density(NPRK_tree))
end

end
