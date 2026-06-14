using Test
using RootedTrees
using StaticArrays

            # Runge-Kutta method SSPRK33 of order 3
            @testset "RungeKuttaMethod, SSPRK33" begin
                A = [0 0 0; 1 0 0; 1 / 4 1 / 4 0]
                b = [1 / 6, 1 / 6, 2 / 3]
                rk = RungeKuttaMethod(A, b)
                show(IOContext(stdout, :compact => false), rk)

                for order in 1:3
                    for t in RootedTreeIterator(order)
                        @test residual_order_condition(t, rk) ≈ 0 atol = eps()
                    end
                end

                let order = 4
                    res = 0.0
                    for t in RootedTreeIterator(order)
                        res += abs(residual_order_condition(t, rk))
                    end
                    @test res > 10 * eps()
                end

                A = @SArray [0 0 0; 1 0 0; 1 / 4 1 / 4 0]
                b = @SArray [1 / 6, 1 / 6, 2 / 3]
                rk = RungeKuttaMethod(A, b)
                show(IOContext(stdout, :compact => true), rk)
                for order in 1:3
                    @test all(RootedTreeIterator(order)) do t
                        abs(residual_order_condition(t, rk)) < eps()
                    end
                end

                let order = 4
                    res = 0.0
                    for t in RootedTreeIterator(order)
                        res += abs(residual_order_condition(t, rk))
                    end
                    @test res > 10 * eps()
                end

                # deprecations
                let order = 4
                    for t in RootedTreeIterator(order)
                        @test elementary_weight(t, rk.A, rk.b, rk.c) ≈ elementary_weight(t, rk)
                        @test derivative_weight(t, RungeKuttaMethod(rk.A, rk.b, rk.c)) ≈
                            derivative_weight(t, rk)
                        @test residual_order_condition(t, RungeKuttaMethod(rk.A, rk.b, rk.c)) ≈
                            residual_order_condition(t, rk)
                    end
                end
            end

            @testset "AdditiveRungeKuttaMethod, IMEX Euler" begin
                ex_euler = RungeKuttaMethod(@SMatrix([0 // 1]), @SVector [1])
                im_euler = RungeKuttaMethod(@SMatrix([1 // 1]), @SVector [1])
                ark = AdditiveRungeKuttaMethod([ex_euler, im_euler])
                show(IOContext(stdout, :compact => true), ark)
                show(IOContext(stdout, :compact => false), ark)

                @test elementary_weight(rootedtree(Int[], Bool[]), ark) ≈ 1

                for order in 1:1
                    for t in BicoloredRootedTreeIterator(order)
                        @test residual_order_condition(t, ark) ≈ 0 atol = eps()
                    end
                end

                let order = 2
                    res = 0.0
                    for t in BicoloredRootedTreeIterator(order)
                        res += abs(residual_order_condition(t, ark))
                    end
                    @test res > 10 * eps()
                end
            end

            @testset "AdditiveRungeKuttaMethod, Störmer-Verlet" begin
                # Hairer, Lubich, Wanner (2002)
                # Geometric numerical integration
                # Table II.2.1
                As = [
                    [0 0; 1 // 2 1 // 2],
                    [1 // 2 0; 1 // 2 0],
                ]
                bs = [
                    [1 // 2, 1 // 2],
                    [1 // 2, 1 // 2],
                ]
                ark = AdditiveRungeKuttaMethod(As, bs)

                for order in 1:2
                    for t in BicoloredRootedTreeIterator(order)
                        @test residual_order_condition(t, ark) ≈ 0 atol = eps()
                    end
                end

                let order = 3
                    res = 0.0
                    for t in BicoloredRootedTreeIterator(order)
                        res += abs(residual_order_condition(t, ark))
                    end
                    @test res > 10 * eps()
                end
            end

            @testset "AdditiveRungeKuttaMethod, Lobatto IIIA-IIIB pair (s = 3)" begin
                # Hairer, Lubich, Wanner (2002)
                # Geometric numerical integration
                # Table II.2.2
                As = [
                    [0 0 0; 5 // 24 1 // 3 -1 // 24; 1 // 6 2 // 3 1 // 6],
                    [1 // 6 -1 // 6 0; 1 // 6 1 // 3 0; 1 // 6 5 // 6 0],
                ]
                bs = [
                    [1 // 6, 2 // 3, 1 // 6],
                    [1 // 6, 2 // 3, 1 // 6],
                ]
                ark = AdditiveRungeKuttaMethod(As, bs)

                for order in 1:4
                    for t in BicoloredRootedTreeIterator(order)
                        @test residual_order_condition(t, ark) ≈ 0 atol = eps()
                    end
                end

                let order = 5
                    res = 0.0
                    for t in BicoloredRootedTreeIterator(order)
                        res += abs(residual_order_condition(t, ark))
                    end
                    @test res > 10 * eps()
                end
            end

            @testset "AdditiveRungeKuttaMethod, Griep3" begin
                # Oswald Knoth and J. Wensch (2014)
                # "Generalized Split-Explicit Runge-Kutta Methods for the
                # Compressible Euler Equations".
                # Monthly Weather Review, 142, 2067-2081
                A_explicit = @SArray [0 0 0; 1 // 2 0 0; -1 2 0]
                b_explicit = @SArray [1 // 6, 2 // 3, 1 // 6]
                rk_explicit = RungeKuttaMethod(A_explicit, b_explicit)
                β = sqrt(3) / 3
                A_implicit = @SArray [0 0 0; -β / 2 (1 + β) / 2 0; (3 + 5β) / 2 -1 - 3β (1 + β) / 2]
                b_implicit = @SArray [1 // 6, 2 // 3, 1 // 6]
                rk_implicit = RungeKuttaMethod(A_implicit, b_implicit)
                ark = AdditiveRungeKuttaMethod([rk_explicit, rk_implicit])

                for order in 1:3
                    for t in BicoloredRootedTreeIterator(order)
                        @test residual_order_condition(t, ark) ≈ 0 atol = eps()
                    end
                end

                let order = 4
                    res = 0.0
                    for t in BicoloredRootedTreeIterator(order)
                        res += abs(residual_order_condition(t, ark))
                    end
                    @test res > 10 * eps()
                end
            end

            @testset "AdditiveRungeKuttaMethod, ARK3(2)4L[2]SA" begin
                # Kennedy, Christopher A., and Mark H. Carpenter.
                # "Additive Runge-Kutta schemes for convection-diffusion-reaction equations."
                # Applied Numerical Mathematics 44, no. 1-2 (2003): 139-181.
                # https://doi.org/10.1016/S0168-9274(02)00138-1
                A_explicit = @SArray [
                    0 0 0 0
                    1767732205903 / 2027836641118 0 0 0
                    5535828885825 / 10492691773637 788022342437 / 10882634858940 0 0
                    6485989280629 / 16251701735622 -4246266847089 / 9704473918619 10755448449292 / 10357097424841 0
                ]
                b_explicit = @SArray [
                    1471266399579 / 7840856788654,
                    -4482444167858 / 7529755066697,
                    11266239266428 / 11593286722821,
                    1767732205903 / 4055673282236,
                ]
                rk_explicit = RungeKuttaMethod(A_explicit, b_explicit)
                A_implicit = @SArray [
                    0 0 0 0
                    1767732205903 / 4055673282236 1767732205903 / 4055673282236 0 0
                    2746238789719 / 10658868560708 -640167445237 / 6845629431997 1767732205903 / 4055673282236 0
                    1471266399579 / 7840856788654 -4482444167858 / 7529755066697 11266239266428 / 11593286722821 1767732205903 / 4055673282236
                ]
                b_implicit = @SArray [
                    1471266399579 / 7840856788654,
                    -4482444167858 / 7529755066697,
                    11266239266428 / 11593286722821,
                    1767732205903 / 4055673282236,
                ]
                rk_implicit = RungeKuttaMethod(A_implicit, b_implicit)
                ark = AdditiveRungeKuttaMethod([rk_explicit, rk_implicit])

                for order in 1:3
                    for t in BicoloredRootedTreeIterator(order)
                        @test residual_order_condition(t, ark) ≈ 0 atol = eps()
                    end
                end

                let order = 4
                    res = 0.0
                    for t in BicoloredRootedTreeIterator(order)
                        res += abs(residual_order_condition(t, ark))
                    end
                    @test res > 10 * eps()
                end
            end

            @testset "AdditiveRungeKuttaMethod, SSPRK33 three times" begin
                # Using the same method multiple times is equivalent to using a plain RK
                # method without any splitting/partitioning/decomposition
                A = @SArray [0 0 0; 1 0 0; 1 / 4 1 / 4 0]
                b = @SArray [1 / 6, 1 / 6, 2 / 3]
                rk = RungeKuttaMethod(A, b)
                ark = AdditiveRungeKuttaMethod([rk, rk, rk])

                let t = rootedtree([1, 2, 2], [1, 2, 3])
                    @test residual_order_condition(t, ark) ≈ 0 atol = eps()
                end

                let t = rootedtree([1, 2, 3, 2], [1, 2, 3, 1])
                    @test abs(residual_order_condition(t, ark)) > 10 * eps()
                end
            end

            @testset "RosenbrockMethod, original Rosenbrock" begin
                γ = [
                    1 - sqrt(2) / 2 0;
                    0 1 - sqrt(2) / 2
                ]
                A = [
                    0 0;
                    (sqrt(2) - 1) / 2 0
                ]
                b = [0, 1]
                ros = @inferred RosenbrockMethod(γ, A, b)

                # second-order accurate
                @test abs(@inferred(residual_order_condition(rootedtree(Int[]), ros))) <
                    10 * eps()
                @test abs(@inferred(residual_order_condition(rootedtree(Int[1]), ros))) <
                    10 * eps()
                @test abs(@inferred(residual_order_condition(rootedtree(Int[1, 2]), ros))) <
                    10 * eps()
                @test abs(@inferred(residual_order_condition(rootedtree(Int[1, 2, 3]), ros))) >
                    0.04
                @test abs(@inferred(residual_order_condition(rootedtree(Int[1, 2, 2]), ros))) >
                    0.14
            end

            @testset "RosenbrockMethod, GRK4A (Kaps and Rentrop, 1979)" begin
                # Kaps, Rentrop (1979)
                # Generalized Runge-Kutta methods of order four with stepsize control
                # for stiff ordinary differential equations
                # https://doi.org/10.1007/BF01396495
                γ = [
                    0.395 0 0 0;
                    -0.767672395484 0.395 0 0;
                    -0.851675323742 0.522967289188 0.395 0;
                    0.288463109545 0.880214273381e-1 -0.337389840627 0.395
                ]
                A = [
                    0 0 0 0;
                    0.438 0 0 0;
                    0.796920457938 0.730795420615e-1 0 0;
                    0.796920457938 0.730795420615e-1 0 0
                ]
                b = [0.199293275701, 0.482645235674, 0.680614886256e-1, 0.25]
                ros = @inferred RosenbrockMethod(γ, A, b)

                @test_nowarn show(ros)
                @test_nowarn show(IOContext(stdout, :compact => true), ros)

                # fourth-order accurate
                for o in 0:4
                    for t in RootedTreeIterator(o)
                        val = @inferred residual_order_condition(t, ros)
                        @test abs(val) < 3000 * eps()
                    end
                end

                # not fifth-order accurate
                s = 0.0
                for t in RootedTreeIterator(5)
                    s += abs(residual_order_condition(t, ros))
                end
                @test s > 0.06
            end
