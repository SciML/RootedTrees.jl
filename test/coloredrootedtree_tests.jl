using Test
using RootedTrees
using RootedTrees.Latexify: latexify

            @testset "validate level sequence in constructor" begin
                @test_nowarn rootedtree([1, 2, 3, 4], Bool[0, 0, 0, 0])
                @test_throws DimensionMismatch rootedtree([1, 2, 3, 4, 5, 1], Bool[0, 0])
                @test_throws ArgumentError rootedtree(
                    [1, 2, 3, 4, 5, 1],
                    Bool[0, 0, 0, 0, 0, 0]
                )
                @test_throws ArgumentError rootedtree([1, 1], Bool[0, 0])
                @test_throws ArgumentError rootedtree([1, 3], Bool[0, 0])
                @test_throws ArgumentError rootedtree([1, 0], Bool[0, 0])
            end

            @testset "comparisons etc." begin
                trees = (
                    rootedtree([1, 2, 3], [1, 1, 1]),
                    rootedtree([1, 2, 3], [1, 1, 1]),
                    rootedtree([1, 2, 2], [1, 1, 1]),
                    rootedtree([1, 2, 3, 3], [1, 1, 1, 1]),
                    rootedtree(Int[], Int[]),
                    rootedtree([1, 2, 3], [1, 1, 2]),
                    rootedtree([1, 2, 3], [1, 2, 1]),
                    rootedtree([1, 2, 3], [1, 2, 2]),
                    rootedtree([1, 2, 2], [2, 2, 2]),
                )
                trees_shifted = (
                    rootedtree([1, 2, 3], [1, 1, 1]),
                    rootedtree([2, 3, 4], [1, 1, 1]),
                    rootedtree([1, 2, 2], [1, 1, 1]),
                    rootedtree([1, 2, 3, 3], [1, 1, 1, 1]),
                    rootedtree(Int[], Int[]),
                    rootedtree([1, 2, 3], [1, 1, 2]),
                    rootedtree([0, 1, 2], [1, 2, 1]),
                    rootedtree([2, 3, 4], [1, 2, 2]),
                    rootedtree([1, 2, 2], [2, 2, 2]),
                )

                for (t1, t2, t3, t4, t5, t6, t7, t8, t9) in (trees, trees_shifted)
                    @test t1 == t1
                    @test t1 == t2
                    @test !(t1 == t3)
                    @test !(t1 == t4)
                    @test !(t1 == t5)
                    @test !(t2 == t5)
                    @test !(t3 == t5)
                    @test !(t4 == t5)
                    @test t5 == t5
                    @test !(t1 == t6)
                    @test !(t1 == t7)
                    @test !(t1 == t8)

                    @test hash(t1) == hash(t1)
                    @test hash(t1) == hash(t2)
                    @test !(hash(t1) == hash(t3))
                    @test !(hash(t1) == hash(t4))
                    @test hash(t1) != hash(t5)
                    @test hash(t2) != hash(t5)
                    @test hash(t3) != hash(t5)
                    @test hash(t4) != hash(t5)
                    @test hash(t5) == hash(t5)
                    @test hash(t1) != hash(t6)
                    @test hash(t1) != hash(t7)
                    @test hash(t1) != hash(t8)

                    @test !(t1 < t1)
                    @test !(t1 < t2)
                    @test !(t2 < t1)
                    @test !(t1 > t2)
                    @test !(t2 > t1)
                    @test t3 < t2 && t2 > t3
                    @test !(t2 < t3) && !(t3 > t2)
                    @test t1 < t4 && t4 > t1
                    @test !(t4 < t1) && !(t1 > t4)
                    @test t1 <= t2 && t2 >= t1
                    @test t2 <= t2 && t2 >= t2
                    @test t5 < t1
                    @test t1 > t5
                    @test !(t5 < t5)
                    @test !(t1 < t5)
                    @test t1 < t6
                    @test t1 < t7
                    @test t1 < t8
                    @test t6 < t7
                    @test t6 < t8
                    @test t7 < t8
                    @test !(t1 < t9)
                    @test !(t6 < t9)
                    @test !(t7 < t9)
                    @test !(t8 < t9)

                    println(devnull, t1)
                    println(devnull, t2)
                    println(devnull, t3)
                    println(devnull, t4)
                    println(devnull, t5)
                    println(devnull, t6)
                    println(devnull, t7)
                    println(devnull, t8)
                end

                @test rootedtree([1, 2]) > rootedtree([1])
                @test rootedtree([1, 2], Bool[0, 1]) > rootedtree([1], Bool[1])

                # more tests of the canonical representation
                t = rootedtree([1, 2, 3, 4, 3], Bool[1, 1, 0, 1, 1])
                @test t.level_sequence == [1, 2, 3, 4, 3]

                t = rootedtree([1, 2, 3, 2, 3, 3, 2], Bool[1, 0, 1, 1, 0, 0, 0])
                @test t.level_sequence == [1, 2, 3, 3, 2, 3, 2]
                @test !isempty(t)

                t = rootedtree([1, 2, 3, 2, 3, 4, 2, 3], [1, 0, 1, 1, 0, 0, 0, 1])
                @test t.level_sequence == [1, 2, 3, 4, 2, 3, 2, 3]
                @test !isempty(t)

                t = rootedtree([1, 2, 3, 2, 3, 3, 2, 3], Bool[1, 0, 1, 1, 0, 0, 0, 1])
                @test t.level_sequence == [1, 2, 3, 3, 2, 3, 2, 3]
                @test !isempty(t)

                @test isempty(rootedtree(Int[]))
                @test isempty(empty(t))

                # misc
                @test_throws DimensionMismatch rootedtree([1, 2, 3], [1, 2])
            end

            @testset "hashing" begin
                hashes = [hash(rootedtree(Int[], Bool[]))]
                for o in 1:8
                    for t in BicoloredRootedTreeIterator(o)
                        new_hash = @inferred hash(t)
                        @test !(new_hash in hashes)
                        push!(hashes, new_hash)
                    end
                end
                t = rootedtree(
                    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 2],
                    Bool[0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
                )
                new_hash = @inferred hash(t)
                @test !(new_hash in hashes)
            end

            @testset "functions on trees" begin
                # See Araujo, Murua, and Sanz-Serna (1997), Table 1
                # https://doi.org/10.1137/S0036142995292128
                let t = rootedtree(Int[], Int[])
                    @test order(t) == 0
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 1
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "∅"
                end

                let t = rootedtree([1], [1])
                    @test order(t) == 1
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 1
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "τ₁"

                    @test t ∘ t == rootedtree([1, 2], [1, 1])
                end

                let t = rootedtree([1], [2])
                    @test order(t) == 1
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 1
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "τ₂"
                end

                let t = rootedtree([1], [3])
                    @test order(t) == 1
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 1
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "τ₃"
                end

                let t = rootedtree([1], [typemax(Int)])
                    @test order(t) == 1
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 1
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "τ₀"
                end

                let t = rootedtree([1, 2], [1, 1])
                    @test order(t) == 2
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 2
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "[τ₁]₁"
                end

                let t = rootedtree([1, 2], [1, 2])
                    @test order(t) == 2
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 2
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "[τ₂]₁"
                end

                let t = rootedtree([1, 2], [3, 1])
                    @test order(t) == 2
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 2
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "[τ₁]₃"
                end

                let t = rootedtree([1, 2, 2], [2, 1, 1])
                    @test order(t) == 3
                    @test α(t) == 1
                    @test σ(t) == 2
                    @test γ(t) == 3
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "[τ₁²]₂"
                end

                let t = rootedtree([1, 2, 2], [2, 1, 2])
                    @test order(t) == 3
                    @test α(t) == 2
                    @test σ(t) == 1
                    @test γ(t) == 3
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "[τ₂τ₁]₂"
                end

                let t = rootedtree([1, 2, 3], [3, 2, 1])
                    @test order(t) == 3
                    @test α(t) == 1
                    @test σ(t) == 1
                    @test γ(t) == 6
                    @test_nowarn println(devnull, t)
                    @test butcher_representation(t) == "[[τ₁]₂]₃"
                end
            end

            @testset "Butcher product" begin
                t1_0 = @inferred rootedtree([1], Bool[0])
                t1_1 = @inferred rootedtree([1], Bool[1])
                @inferred t1_0 ∘ t1_0
                t_result = copy(t1_0)
                @inferred butcher_product!(t_result, t1_0, t1_0)
                @test_broken @allocated(butcher_product!(t_result, t1_0, t1_0)) == 0
                @test t_result == t1_0 ∘ t1_0
                @test t_result == rootedtree([1, 2], Bool[0, 0])
                @inferred butcher_product!(t_result, t1_1, t1_0)
                @test_broken @allocated(butcher_product!(t_result, t1_1, t1_0)) == 0
                @test t_result == t1_1 ∘ t1_0
                @test t_result == rootedtree([1, 2], Bool[1, 0])
                @inferred butcher_product!(t_result, t1_0, t1_1)
                @test_broken @allocated(butcher_product!(t_result, t1_0, t1_1)) == 0
                @test t_result == t1_0 ∘ t1_1
                @test t_result == rootedtree([1, 2], Bool[0, 1])
                @inferred butcher_product!(t_result, t1_1, t1_1)
                @test_broken @allocated(butcher_product!(t_result, t1_1, t1_1)) == 0
                @test t_result == t1_1 ∘ t1_1
                @test t_result == rootedtree([1, 2], Bool[1, 1])

                t2_0 = @inferred rootedtree([1, 2], Bool[0, 0])
                @inferred butcher_product!(t_result, t2_0, t1_0)
                @test_broken @allocated(butcher_product!(t_result, t2_0, t1_0)) == 0
                @test t_result == t2_0 ∘ t1_0
                @test t_result == rootedtree([1, 2, 2], Bool[0, 0, 0])
                @inferred butcher_product!(t_result, t2_0, t1_1)
                @test_broken @allocated(butcher_product!(t_result, t2_0, t1_1)) == 0
                @test t_result == t2_0 ∘ t1_1
                @test t_result == rootedtree([1, 2, 2], Bool[0, 0, 1])
            end

            @testset "latexify" begin
                @testset "default style" begin
                    let t = rootedtree(Int[], Bool[])
                        latex_string = "\\varnothing"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1], Bool[0])
                        latex_string = "\\rootedtree[.]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1], Bool[1])
                        latex_string = "\\rootedtree[o]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[0, 0])
                        latex_string = "\\rootedtree[.[.]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[1, 0])
                        latex_string = "\\rootedtree[o[.]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[0, 1])
                        latex_string = "\\rootedtree[.[o]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[1, 1])
                        latex_string = "\\rootedtree[o[o]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree(
                            [1, 2, 3, 4, 4, 3, 4, 3, 3, 2],
                            Bool[0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
                        )
                        latex_string = "\\rootedtree[.[o[.[o][.]][o[.]][o][.]][o]]"
                        @test latexify(t) == latex_string
                    end
                end

                @testset "butcher style" begin
                    @test_nowarn RootedTrees.set_latexify_style("butcher")

                    let t = rootedtree(Int[], Bool[])
                        latex_string = "\\varnothing"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1], Bool[0])
                        latex_string = "τ₀"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1], Bool[1])
                        latex_string = "τ₁"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[0, 0])
                        latex_string = "[τ₀]₀"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[1, 0])
                        latex_string = "[τ₀]₁"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[0, 1])
                        latex_string = "[τ₁]₀"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[1, 1])
                        latex_string = "[τ₁]₁"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree(
                            [1, 2, 3, 4, 4, 3, 4, 3, 3, 2],
                            Bool[0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
                        )
                        latex_string = "[[[τ₁τ₀]₀[τ₀]₁τ₁τ₀]₁τ₁]₀"
                        @test latexify(t) == latex_string
                    end
                end

                @testset "forest style" begin
                    @test_nowarn RootedTrees.set_latexify_style("forest")

                    let t = rootedtree(Int[], Bool[])
                        latex_string = "\\varnothing"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1], Bool[0])
                        latex_string = "\\rootedtree[.]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1], Bool[1])
                        latex_string = "\\rootedtree[o]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[0, 0])
                        latex_string = "\\rootedtree[.[.]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[1, 0])
                        latex_string = "\\rootedtree[o[.]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[0, 1])
                        latex_string = "\\rootedtree[.[o]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree([1, 2], Bool[1, 1])
                        latex_string = "\\rootedtree[o[o]]"
                        @test latexify(t) == latex_string
                    end

                    let t = rootedtree(
                            [1, 2, 3, 4, 4, 3, 4, 3, 3, 2],
                            Bool[0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
                        )
                        latex_string = "\\rootedtree[.[o[.[o][.]][o[.]][o][.]][o]]"
                        @test latexify(t) == latex_string
                    end
                end
            end

            # see butcher2008numerical, Table 302(I)
            @testset "number of trees" begin
                number_of_rooted_trees = [1, 1, 1, 2, 4, 9, 20, 48, 115, 286, 719]
                for order in 0:10
                    num = 0
                    for t in BicoloredRootedTreeIterator(order)
                        num += 1
                    end
                    # number of plain rooted trees times number of possible color sequences
                    # <= since not all possible color sequences are in canonical representation
                    @test num <= number_of_rooted_trees[order + 1] * 2^order
                end
            end

            # https://github.com/SciML/RootedTrees.jl/issues/72
            @testset "BicoloredRootedTreeIterator is canonical" begin
                for o in 1:10
                    for t_iterator in BicoloredRootedTreeIterator(o)
                        t_canonical = RootedTrees.canonical_representation(t_iterator)
                        @test t_iterator == t_canonical
                    end
                end
            end

            # See Sections 2.3 & 6.1 and Table 2 of
            # - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
            #   Algebraic Structures of B-series.
            #   Foundations of Computational Mathematics
            #   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
            @testset "partitions" begin
                # Example in Section 6.1
                let t = rootedtree([1, 2, 3, 3], Bool[0, 1, 0, 0])
                    edge_set = [false, true, false]
                    reference_forest = [
                        rootedtree([3], Bool[0]),
                        rootedtree([2, 3], Bool[1, 0]),
                        rootedtree([1], Bool[0]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 3], Bool[0, 1, 0])
                    @test reference_skeleton == partition_skeleton(t, edge_set)
                end

                # Other examples for single-colored trees
                let t = rootedtree([1, 2, 3, 4, 3], Bool[1, 1, 0, 1, 1])
                    edge_set = [true, true, false, false]
                    reference_forest = [
                        rootedtree([1, 2, 3], Bool[1, 1, 0]),
                        rootedtree([4], Bool[1]),
                        rootedtree([3], Bool[1]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 2])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 4, 3], rand(Bool, 5))
                    edge_set = [false, true, true, false]
                    reference_forest = [
                        rootedtree([3], t.color_sequence[5:5]),
                        rootedtree([2, 3, 4], t.color_sequence[2:4]),
                        rootedtree([1], t.color_sequence[1:1]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 3])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 4, 3], rand(Bool, 5))
                    edge_set = [false, true, false, false]
                    reference_forest = [
                        rootedtree([4], t.color_sequence[4:4]),
                        rootedtree([3], t.color_sequence[5:5]),
                        rootedtree([2, 3], t.color_sequence[2:3]),
                        rootedtree([1], t.color_sequence[1:1]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 3, 3])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 2, 2, 2], rand(Bool, 5))
                    edge_set = [false, false, true, true]
                    reference_forest = [
                        rootedtree([2], t.color_sequence[2:2]),
                        rootedtree([2], t.color_sequence[3:3]),
                        rootedtree([1, 2, 2], t.color_sequence[[1, 4, 5]]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 2])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 2, 2], rand(Bool, 5))
                    edge_set = [false, false, false, true]
                    reference_forest = [
                        rootedtree([3], t.color_sequence[3:3]),
                        rootedtree([2], t.color_sequence[2:2]),
                        rootedtree([2], t.color_sequence[4:4]),
                        rootedtree([1, 2], t.color_sequence[[1, 5]]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 3, 2])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 2, 2], rand(Bool, 5))
                    edge_set = [true, true, true, true]
                    reference_forest = [rootedtree([1, 2, 3, 2, 2], t.color_sequence[:])]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 2, 3], rand(Bool, 5))
                    edge_set = [true, true, false, false]
                    reference_forest = [
                        rootedtree([3], t.color_sequence[5:5]),
                        rootedtree([2], t.color_sequence[4:4]),
                        rootedtree([1, 2, 3], t.color_sequence[1:3]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 3])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 2, 3], rand(Bool, 5))
                    edge_set = [false, true, false, false]
                    reference_forest = [
                        rootedtree([2, 3], t.color_sequence[2:3]),
                        rootedtree([3], t.color_sequence[5:5]),
                        rootedtree([2], t.color_sequence[4:4]),
                        rootedtree([1], t.color_sequence[1:1]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 2, 3])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                let t = rootedtree([1, 2, 3, 3, 3], rand(Bool, 5))
                    edge_set = [false, true, true, false]
                    reference_forest = [
                        rootedtree([3], t.color_sequence[5:5]),
                        rootedtree([2, 3, 3], t.color_sequence[2:4]),
                        rootedtree([1], t.color_sequence[1:1]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2, 3])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end

                # additional tests not included in the examples of the paper
                let t = rootedtree([1, 2, 3, 2, 3], rand(Bool, 5))
                    edge_set = [true, false, true, true]
                    reference_forest = [
                        rootedtree([1, 2, 3, 2], t.color_sequence[[1, 4, 5, 2]]),
                        rootedtree([3], t.color_sequence[3:3]),
                    ]
                    sort!(reference_forest)
                    @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
                        reference_forest

                    reference_skeleton = rootedtree([1, 2])
                    @test reference_skeleton.level_sequence ==
                        partition_skeleton(t, edge_set).level_sequence
                end
            end

            # See Table 3 of
            # - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
            #   Algebraic Structures of B-series.
            #   Foundations of Computational Mathematics
            #   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
            @testset "PartitionIterator" begin
                t = rootedtree([1, 2, 3, 3], Bool[1, 0, 1, 0])
                partitions = collect(PartitionIterator(t))
                forests = map(first, partitions)
                skeletons = map(last, partitions)
                for forest in forests
                    for tree in forest
                        RootedTrees.normalize_root!(tree)
                    end
                    sort!(forest)
                end
                sort!(forests)
                for tree in skeletons
                    RootedTrees.normalize_root!(tree)
                end
                sort!(skeletons)

                reference_forests = [
                    [rootedtree([1, 2, 3, 3], Bool[1, 0, 1, 0])],
                    [rootedtree([1], Bool[1]), rootedtree([1, 2, 2], Bool[0, 1, 0])],
                    [rootedtree([1], Bool[1]), rootedtree([1, 2, 3], Bool[1, 0, 0])],
                    [rootedtree([1], Bool[0]), rootedtree([1, 2, 3], Bool[1, 0, 1])],
                    [
                        rootedtree([1], Bool[1]),
                        rootedtree([1], Bool[1]),
                        rootedtree([1, 2], Bool[0, 0]),
                    ],
                    [
                        rootedtree([1], Bool[0]),
                        rootedtree([1], Bool[1]),
                        rootedtree([1, 2], Bool[1, 0]),
                    ],
                    [
                        rootedtree([1], Bool[0]),
                        rootedtree([1], Bool[1]),
                        rootedtree([1, 2], Bool[0, 1]),
                    ],
                    [
                        rootedtree([1], Bool[0]),
                        rootedtree([1], Bool[0]),
                        rootedtree([1], Bool[1]),
                        rootedtree([1], Bool[1]),
                    ],
                ]
                reference_skeletons = [
                    rootedtree([1], Bool[1]),
                    rootedtree([1, 2], Bool[1, 0]),
                    rootedtree([1, 2], Bool[1, 0]),
                    rootedtree([1, 2], Bool[1, 1]),
                    rootedtree([1, 2, 2], Bool[1, 1, 0]),
                    rootedtree([1, 2, 3], Bool[1, 0, 0]),
                    rootedtree([1, 2, 3], Bool[1, 0, 1]),
                    rootedtree([1, 2, 3, 3], Bool[1, 0, 1, 0]),
                ]
                for forest in reference_forests
                    sort!(forest)
                end
                sort!(reference_forests)
                sort!(reference_skeletons)

                @test forests == reference_forests
                @test skeletons == reference_skeletons

                level_sequence = zeros(Int, RootedTrees.BUFFER_LENGTH + 1)
                level_sequence[1] -= 1
                color_sequence = rand(Bool, length(level_sequence))
                t = rootedtree(level_sequence, color_sequence)
                @inferred PartitionIterator(t)
                t = @inferred rootedtree!(view(level_sequence, :), view(color_sequence, :))
                @inferred PartitionIterator(t)
            end
