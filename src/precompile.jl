# We cannot use `@precompile_all_calls` from SnoopPrecompile.jl
# directly on code since the internal buffers are not set up during
# precompilation:
# ```
# ERROR: LoadError: BoundsError: attempt to access 0-element Vector{Vector{Int}} at index [1]
# Stacktrace:
# [1] getindex
#   @ ./array.jl:924 [inlined]
# [2] canonical_representation!
# ...
# ```
#
# @precompile_all_calls begin
#     t = rootedtree([1, 2, 3, 2])
#     butcher_representation(t)
#     order(t)
#     for (forest, subtree) in SplittingIterator(t)
#     end
#     for (forest, skeleton) in PartitionIterator(t)
#     end
#
#     A = [0 0 0 0; 1//2 0 0 0; 0 1//2 0 0; 0 0 1 0]
#     b = [1 // 6, 1 // 3, 1 // 3, 1 // 6]
#     rk = RungeKuttaMethod(A, b)
#     for t in RootedTreeIterator(2)
#         residual_order_condition(t, rk)
#     end
#
#     As = [
#         [0 0; 1//2 1//2],
#         [1//2 0; 1//2 0],
#     ]
#     bs = [
#         [1 // 2, 1 // 2],
#         [1 // 2, 1 // 2],
#     ]
#     ark = AdditiveRungeKuttaMethod(As, bs)
#     for t in BicoloredRootedTreeIterator(2)
#         residual_order_condition(t, ark)
#     end
#
#     γ = [0.395 0 0 0;
#          -0.767672395484 0.395 0 0;
#          -0.851675323742 0.522967289188 0.395 0;
#          0.288463109545 0.880214273381e-1 -0.337389840627 0.395]
#     A = [0 0 0 0;
#          0.438 0 0 0;
#          0.796920457938 0.730795420615e-1 0 0;
#          0.796920457938 0.730795420615e-1 0 0]
#     b = [0.199293275701, 0.482645235674, 0.680614886256e-1, 0.25]
#     ros = RosenbrockMethod(γ, A, b)
#     for t in RootedTreeIterator(2)
#         residual_order_condition(t, ros)
#     end
# end
#
# Thus, we use the older tools from SnoopCompile.jl to generate precompile
# statements. This is based on the following code:
# ```julia
# julia> using SnoopCompile, ProfileView; tinf = @snoopi_deep begin
#
#     using RootedTrees
#
#     t = rootedtree([1, 2, 3, 2])
#     butcher_representation(t)
#     order(t)
#     for (forest, subtree) in SplittingIterator(t) end
#     for (forest, skeleton) in PartitionIterator(t) end
#
#     A = [0 0 0 0; 1//2 0 0 0; 0 1//2 0 0; 0 0 1 0]
#     b = [1//6, 1//3, 1//3, 1//6]
#     rk = RungeKuttaMethod(A, b)
#     for t in RootedTreeIterator(2)
#         residual_order_condition(t, rk)
#     end
#
#     As = [
#       [0 0; 1//2 1//2],
#       [1//2 0; 1//2 0]
#     ]
#     bs = [
#       [1//2, 1//2],
#       [1//2, 1//2]
#     ]
#     ark = AdditiveRungeKuttaMethod(As, bs)
#     for t in BicoloredRootedTreeIterator(2)
#         residual_order_condition(t, ark)
#     end
#
#     γ = [0.395 0 0 0;
#          -0.767672395484 0.395 0 0;
#          -0.851675323742 0.522967289188 0.395 0;
#          0.288463109545 0.880214273381e-1 -.337389840627 0.395]
#     A = [0 0 0 0;
#          0.438 0 0 0;
#          0.796920457938 0.730795420615e-1 0 0;
#          0.796920457938 0.730795420615e-1 0 0]
#     b = [0.199293275701, 0.482645235674, 0.680614886256e-1, 0.25]
#     ros = RosenbrockMethod(γ, A, b)
#     for t in RootedTreeIterator(2)
#         residual_order_condition(t, ros)
#     end
#
#     end
# InferenceTimingNode: 1.929538/2.721058 on Core.Compiler.Timings.ROOT() with 52 direct children
#
# julia> ttot, pcs = SnoopCompile.parcel(tinf);
#
# julia> ttot
# 0.791520612
#
# julia> SnoopCompile.write("/tmp/precompiles_RootedTrees", pcs, has_bodyfunction = true)
# Base.Threads: precompiled 0.0049499190000000005 out of 0.0049499190000000005
# Base: precompiled 0.066721417 out of 0.068838787
# RootedTrees: precompiled 0.716612635 out of 0.7169763830000001
# ```
# See https://timholy.github.io/SnoopCompile.jl/dev/snoopi_deep_parcel/

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing

    Base.precompile(Tuple{typeof(residual_order_condition),
                          RootedTree{Int64, Vector{Int64}},
                          RungeKuttaMethod{Rational{Int64}, Matrix{Rational{Int64}},
                                           Vector{Rational{Int64}}}})   # time: 0.18134941
    Base.precompile(Tuple{typeof(residual_order_condition),
                          BicoloredRootedTree{Int64, Vector{Int64}, Vector{Bool}},
                          AdditiveRungeKuttaMethod{Rational{Int64},
                                                   Vector{RungeKuttaMethod{Rational{Int64},
                                                                           Matrix{Rational{Int64}},
                                                                           Vector{Rational{Int64}}}}}})   # time: 0.16824293
    Base.precompile(Tuple{typeof(rootedtree), Vector{Int64}})   # time: 0.087751105
    Base.precompile(Tuple{typeof(residual_order_condition),
                          RootedTree{Int64, Vector{Int64}},
                          RosenbrockMethod{Float64, Matrix{Float64}, Vector{Float64}}})   # time: 0.07817012
    Base.precompile(Tuple{Type{RungeKuttaMethod}, Matrix{Rational{Int64}},
                          Vector{Rational{Int64}}})   # time: 0.075997345
    Base.precompile(Tuple{Type{AdditiveRungeKuttaMethod}, Vector{Matrix{Rational{Int64}}},
                          Vector{Vector{Rational{Int64}}}})   # time: 0.05049169
    Base.precompile(Tuple{typeof(iterate),
                          SplittingIterator{RootedTree{Int64, Vector{Int64}}}})   # time: 0.044273302
    Base.precompile(Tuple{Type{RosenbrockMethod}, Matrix{Float64}, Matrix{Float64},
                          Vector{Float64}})   # time: 0.016924093
    Base.precompile(Tuple{typeof(butcher_representation), RootedTree{Int64, Vector{Int64}}})   # time: 0.014338499
    Base.precompile(Tuple{typeof(iterate), BicoloredRootedTreeIterator{Int64},
                          Tuple{Bool, Int64}})   # time: 0.014068822
    Base.precompile(Tuple{typeof(symmetry),
                          BicoloredRootedTree{Int64, Vector{Int64}, Vector{Bool}}})   # time: 0.008579416
    Base.precompile(Tuple{typeof(symmetry), RootedTree{Int64, Vector{Int64}}})   # time: 0.007220166
    Base.precompile(Tuple{typeof(iterate),
                          PartitionIterator{RootedTree{Int64, Vector{Int64}},
                                            RootedTree{Int64, Vector{Int64}}}})   # time: 0.006673861
    Base.precompile(Tuple{Type{BicoloredRootedTreeIterator}, Int64})   # time: 0.003071257
    Base.precompile(Tuple{Type{PartitionIterator}, RootedTree{Int64, Vector{Int64}}})   # time: 0.002802794
    Base.precompile(Tuple{typeof(iterate), RootedTreeIterator{Int64}, Bool})   # time: 0.002423941
    Base.precompile(Tuple{Type{RootedTreeIterator}, Int64})   # time: 0.002368873
    Base.precompile(Tuple{typeof(iterate), RootedTreeIterator{Int64}})   # time: 0.002200462
    Base.precompile(Tuple{typeof(iterate), BicoloredRootedTreeIterator{Int64}})   # time: 0.001368852
end

_precompile_()
