using RootedTrees
include("../src/NPRKTrees.jl")
using .NPRKTrees

### TESTS BELOW ###
# Some tests, to delete later

# 3 stage Lobatto IIIA-IIIB pair produces an embedded NPRK method
# test the Order conditions code:
# 	Method 1 defined below should satisfy all 3rd order conditions
# 	Method 2 satisfies all additive 3rd order conditions but fails the nonlinear order condition
A1 = [[0 5//24 1//6]' [0 1//3 2//3]' [0 -1//24 1//6]']
A2 = [[1//6 1//6 1//6]' [-1//6 1//3 5//6]' [0 0 0]']
bvec = [1//6, 2//3, 1//6]
cvec = [0, 1//2, 1]
s = size(A1)[1]
Atensor = zeros(s, s, s)
bdiagmatrix = zeros(s,s) # method 1
bdensematrix = zeros(s,s) # method 2

for i in 1:s
	bdiagmatrix[i,i] = bvec[i]
	for j in 1:s
		bdensematrix[i,j] = bvec[i]//s + bvec[j]//s - 1//s^2
		for k in 1:s
			Atensor[i,j,k] = A1[i,j]//s + A2[i,k]//s - cvec[i]//s^2
		end
	end
end

tol = 10^-7 # tolerance for difference between lhs and rhs of order conditions |sum[b*a*a*(...)] - 1/density(t)| < tol
for order in 1:4
	for t in NPRKTreeIterator(2,order)
		# print("Order $order $(t.level_sequence) $(t.color_sequence) LHS $(NPRKOrderCondition2Partitions(Atensor, bdensematrix, t)) vs RHS $(1/density(t)), Is Tree Nonlinear: $(isColorBranching(t)) \n\n")
		print("Method 1: Order $order $(t.level_sequence) $(t.color_sequence), residual<tol: $(residualNPRK2(Atensor, bdiagmatrix, t) < tol), Is Tree Nonlinear: $(isColorBranching(t)) \n\n")
	end
end
for order in 1:4
	for t in NPRKTreeIterator(2,order)
		# print("Order $order $(t.level_sequence) $(t.color_sequence) LHS $(NPRKOrderCondition2Partitions(Atensor, bdensematrix, t)) vs RHS $(1/density(t)), Is Tree Nonlinear: $(isColorBranching(t)) \n\n")
		print("Method 2: Order $order $(t.level_sequence) $(t.color_sequence), residual<tol: $(residualNPRK2(Atensor, bdensematrix, t) < tol), Is Tree Nonlinear: $(isColorBranching(t)) \n\n")
	end
end

# Verify isMultiColored and isColorBranching work properly:
for t in NPRKTreeIterator(3,3)
	print(t.level_sequence)
	print(t.color_sequence)
	print(" isMultiColored: $(isMultiColored(t,true)), isColorBranching: $(isColorBranching(t)) \n\n")
end

# Verify the correct number of ARK trees are generated for various number of partitions and orders
for partitions in 1:4
	for order in 1:5
		print("ARK $partitions $order $(length(ARKTreeIterator(partitions,order))) \n\n")
	end
end

# Verify the correct number of NPRK trees are generated for various number of partitions and orders
for partitions in 1:4
	for order in 1:5
		print("NPRK $partitions $order $(length(NPRKTreeIterator(partitions,order))) \n\n")
	end
end

