using RootedTrees, BenchmarkTools

const SUITE = BenchmarkGroup()

# Classical explicit RK4 tableau
A_rk4 = [
    0 0 0 0
    1 // 2 0 0 0
    0 1 // 2 0 0
    0 0 1 0
]
b_rk4 = [1 // 6, 1 // 3, 1 // 3, 1 // 6]
rk4 = RungeKuttaMethod(A_rk4, b_rk4)

# =============================================================================
# Tree enumeration
# =============================================================================

SUITE["enumeration"] = BenchmarkGroup()

SUITE["enumeration"]["iterator_order5"] = @benchmarkable collect(RootedTreeIterator(5))
SUITE["enumeration"]["iterator_order7"] = @benchmarkable collect(RootedTreeIterator(7))
SUITE["enumeration"]["count_trees"] = @benchmarkable count_trees(8)

trees7 = collect(RootedTreeIterator(7))
SUITE["enumeration"]["canonical"] = @benchmarkable RootedTrees.canonical_representation.($trees7)

# =============================================================================
# Order conditions
# =============================================================================

SUITE["order_conditions"] = BenchmarkGroup()

function sum_residuals(order)
    res = 0.0
    for t in RootedTreeIterator(order)
        res += abs(residual_order_condition(t, rk4))
    end
    return res
end

SUITE["order_conditions"]["residuals_order4"] = @benchmarkable sum_residuals(4)
SUITE["order_conditions"]["residuals_order5"] = @benchmarkable sum_residuals(5)

t8 = rootedtree([1, 2, 3, 2, 3, 4, 3, 4])
SUITE["order_conditions"]["elementary_weight"] = @benchmarkable elementary_weight(
    $t8, $rk4
)

# =============================================================================
# Tree operations
# =============================================================================

SUITE["operations"] = BenchmarkGroup()

SUITE["operations"]["subtrees"] = @benchmarkable sum(
    _ -> 1.0, SubtreeIterator($t8)
)
SUITE["operations"]["splittings"] = @benchmarkable sum(
    _ -> 1.0, all_splittings($t8)
)
SUITE["operations"]["order"] = @benchmarkable order.($trees7)
SUITE["operations"]["symmetry"] = @benchmarkable σ.($trees7)
