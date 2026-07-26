using Test
using RootedTrees
using RootedTrees.Latexify: latexify
using LaTeXStrings: @L_str

@testset "validate level sequence in constructor" begin
    @test_nowarn rootedtree([1, 2, 3, 4])
    @test_throws ArgumentError rootedtree([1, 2, 3, 4, 5, 1])
    @test_throws ArgumentError rootedtree([1, 1])
    @test_throws ArgumentError rootedtree([1, 3])
    @test_throws ArgumentError rootedtree([1, 0])
end

@testset "comparisons etc." begin
    trees = (
        rootedtree([1, 2, 3]),
        rootedtree([1, 2, 3]),
        rootedtree([1, 2, 2]),
        rootedtree([1, 2, 3, 3]),
        rootedtree(Int[]),
    )
    trees_shifted = (
        rootedtree([1, 2, 3]),
        rootedtree([2, 3, 4]),
        rootedtree([1, 2, 2]),
        rootedtree([1, 2, 3, 3]),
        rootedtree(Int[]),
    )

    for (t1, t2, t3, t4, t5) in (trees, trees_shifted)
        @test t1 == t1
        @test t1 == t2
        @test !(t1 == t3)
        @test !(t1 == t4)
        @test !(t1 == t5)
        @test !(t2 == t5)
        @test !(t3 == t5)
        @test !(t4 == t5)
        @test t5 == t5

        @test hash(t1) == hash(t1)
        @test hash(t1) == hash(t2)
        @test !(hash(t1) == hash(t3))
        @test !(hash(t1) == hash(t4))
        @test hash(t1) != hash(t5)
        @test hash(t2) != hash(t5)
        @test hash(t3) != hash(t5)
        @test hash(t4) != hash(t5)
        @test hash(t5) == hash(t5)

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

        println(devnull, t1)
        println(devnull, t2)
        println(devnull, t3)
        println(devnull, t4)
    end

    # more tests of the canonical representation
    t = rootedtree([1, 2, 3, 2, 3, 3, 2])
    @test t.level_sequence == [1, 2, 3, 3, 2, 3, 2]
    @test !isempty(t)

    t = rootedtree([1, 2, 3, 2, 3, 4, 2, 3])
    @test t.level_sequence == [1, 2, 3, 4, 2, 3, 2, 3]
    @test !isempty(t)

    t = rootedtree([1, 2, 3, 2, 3, 3, 2, 3])
    @test t.level_sequence == [1, 2, 3, 3, 2, 3, 2, 3]
    @test !isempty(t)

    @test isempty(rootedtree(Int[]))
    @test isempty(empty(t))

    level_sequence = zeros(Int, RootedTrees.BUFFER_LENGTH + 1)
    level_sequence[1] -= 1
    @inferred rootedtree(level_sequence)
end

@testset "hashing" begin
    hashes = [hash(rootedtree(Int[]))]
    for o in 1:12
        for t in RootedTreeIterator(o)
            new_hash = @inferred hash(t)
            @test !(new_hash in hashes)
            push!(hashes, new_hash)
        end
    end
    t = rootedtree([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 2])
    new_hash = @inferred hash(t)
    @test !(new_hash in hashes)
end

@testset "printing" begin
    io = IOBuffer()

    @testset "butcher" begin
        @test_nowarn RootedTrees.set_printing_style("butcher")

        let t = rootedtree([1])
            show(io, t)
            @test String(take!(io)) == "τ"
            @test butcher_representation(t) == "τ"
        end

        let t = rootedtree([1, 2, 2, 2, 3])
            show(io, t)
            @test String(take!(io)) == "[[τ]τ²]"
            @test butcher_representation(t) == "[[τ]τ²]"
        end
    end

    @testset "sequence" begin
        @test_nowarn RootedTrees.set_printing_style("sequence")

        let t = rootedtree([1])
            show(io, t)
            @test String(take!(io)) != "τ"
            @test butcher_representation(t) == "τ"
        end

        let t = rootedtree([1, 2, 2, 2, 3])
            show(io, t)
            @test String(take!(io)) != "[[τ]τ²]"
            @test butcher_representation(t) == "[[τ]τ²]"
        end
    end

    @testset "nonsense" begin
        @test_throws ArgumentError RootedTrees.set_printing_style("nonsense_style")
        @test_throws ArgumentError RootedTrees.set_printing_style("even_more_nonsense")
    end
end

@testset "latexify" begin
    @testset "default style" begin
        let t = rootedtree(Int[])
            latex_string = "\\varnothing"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1])
            latex_string = "\\rootedtree[.]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2])
            latex_string = "\\rootedtree[.[.]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3])
            latex_string = "\\rootedtree[.[.[.]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 2])
            latex_string = "\\rootedtree[.[.][.]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3, 4])
            latex_string = "\\rootedtree[.[.[.[.]]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3, 3])
            latex_string = "\\rootedtree[.[.[.][.]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 2, 2])
            latex_string = "\\rootedtree[.[.][.][.]]"
            @test latexify(t) == latex_string
        end
    end

    @testset "butcher style" begin
        @test_nowarn RootedTrees.set_latexify_style("butcher")

        let t = rootedtree(Int[])
            latex_string = "\\varnothing"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1])
            latex_string = "τ"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2])
            latex_string = "[τ]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3])
            latex_string = "[[τ]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 2])
            latex_string = "[τ²]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3, 4])
            latex_string = "[[[τ]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3, 3])
            latex_string = "[[τ²]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 2, 2])
            latex_string = "[τ³]"
            @test latexify(t) == latex_string
        end
    end

    @testset "forest style" begin
        @test_nowarn RootedTrees.set_latexify_style("forest")

        let t = rootedtree(Int[])
            latex_string = "\\varnothing"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1])
            latex_string = "\\rootedtree[.]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2])
            latex_string = "\\rootedtree[.[.]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3])
            latex_string = "\\rootedtree[.[.[.]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 2])
            latex_string = "\\rootedtree[.[.][.]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3, 4])
            latex_string = "\\rootedtree[.[.[.[.]]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 3, 3])
            latex_string = "\\rootedtree[.[.[.][.]]]"
            @test latexify(t) == latex_string
        end

        let t = rootedtree([1, 2, 2, 2])
            latex_string = "\\rootedtree[.[.][.][.]]"
            @test latexify(t) == latex_string
        end
    end

    @testset "nonsense style" begin
        @test_throws ArgumentError RootedTrees.set_latexify_style("nonsense")
    end
end

@testset "deprecated elementary differential" begin
    t = rootedtree([1, 2])
    @test_deprecated elementary_differential(t) == elementary_differential_latexstring(t)
end

# see Table 301(I) etc. in butcher2016numerical
@testset "functions on trees" begin
    t1 = rootedtree([1])
    @test order(t1) == 1
    @test σ(t1) == 1
    @test γ(t1) == 1
    @test α(t1) == 1
    @test β(t1) == α(t1) * γ(t1)
    @test butcher_representation(t1) == "τ"
    latex_string = "\\rootedtree[.]"
    @test RootedTrees.latexify(t1) == latex_string
    @test latexify(t1) == latex_string
    @test isempty(RootedTrees.subtrees(t1))
    @test butcher_representation(empty(t1)) == "∅"
    @test RootedTrees.latexify(empty(t1)) == "\\varnothing"
    @test elementary_differential_latexstring(t1) == L"$f$"
    @test elementary_weight_latexstring(t1) == L"$\sum_{d}b_{d}$"

    @inferred order(t1)
    @inferred σ(t1)
    @inferred γ(t1)
    @inferred α(t1)
    @inferred β(t1)
    @inferred t1 ∘ t1
    t_result = copy(t1)
    @inferred butcher_product!(t_result, t1, t1)
    @test @allocated(butcher_product!(t_result, t1, t1)) == 0
    @test t_result == t1 ∘ t1

    t2 = rootedtree([1, 2])
    @test order(t2) == 2
    @test σ(t2) == 1
    @test γ(t2) == 2
    @test α(t2) == 1
    @test β(t2) == α(t2) * γ(t2)
    @test t2 == t1 ∘ t1
    @inferred butcher_product!(t_result, t1, t1)
    @test @allocated(butcher_product!(t_result, t1, t1)) == 0
    @test t2 == t_result
    @test butcher_representation(t2) == "[τ]"
    latex_string = "\\rootedtree[.[.]]"
    @test RootedTrees.latexify(t2) == latex_string
    @test latexify(t2) == latex_string
    @test RootedTrees.subtrees(t2) == [rootedtree([2])]
    @test elementary_differential_latexstring(t2) == L"$f^{\prime}f$"
    @test elementary_weight_latexstring(t2) == L"$\sum_{d}b_{d}c_{d}$"

    t3 = rootedtree([1, 2, 2])
    @test order(t3) == 3
    @test σ(t3) == 2
    @test γ(t3) == 3
    @test α(t3) == 1
    @test β(t3) == α(t3) * γ(t3)
    @test t3 == t2 ∘ t1
    @inferred butcher_product!(t_result, t2, t1)
    @test @allocated(butcher_product!(t_result, t2, t1)) == 0
    @test t3 == t_result
    @test butcher_representation(t3) == "[τ²]"
    latex_string = "\\rootedtree[.[.][.]]"
    @test RootedTrees.latexify(t3) == latex_string
    @test latexify(t3) == latex_string
    @test RootedTrees.subtrees(t3) == [rootedtree([2]), rootedtree([2])]
    @test elementary_differential_latexstring(t3) == L"$f^{\prime\prime}(f, f)$"
    @test elementary_weight_latexstring(t3) == L"$\sum_{d}b_{d}c_{d}^{2}$"

    t4 = rootedtree([1, 2, 3])
    @test order(t4) == 3
    @test σ(t4) == 1
    @test γ(t4) == 6
    @test α(t4) == 1
    @test β(t4) == α(t4) * γ(t4)
    @test t4 == t1 ∘ t2
    @inferred butcher_product!(t_result, t1, t2)
    @test @allocated(butcher_product!(t_result, t1, t2)) == 0
    @test t4 == t_result
    @test butcher_representation(t4) == "[[τ]]"
    latex_string = "\\rootedtree[.[.[.]]]"
    @test RootedTrees.latexify(t4) == latex_string
    @test latexify(t4) == latex_string
    @test RootedTrees.subtrees(t4) == [rootedtree([2, 3])]
    @test elementary_differential_latexstring(t4) == L"$f^{\prime}f^{\prime}f$"
    @test elementary_weight_latexstring(t4) == L"$\sum_{d, e}b_{d}a_{d,e}c_{e}$"

    t5 = rootedtree([1, 2, 2, 2])
    @test order(t5) == 4
    @test σ(t5) == 6
    @test γ(t5) == 4
    @test α(t5) == 1
    @test β(t5) == α(t5) * γ(t5)
    @test t5 == t3 ∘ t1
    @inferred butcher_product!(t_result, t3, t1)
    @test @allocated(butcher_product!(t_result, t3, t1)) == 0
    @test t5 == t_result
    @test butcher_representation(t5) == "[τ³]"
    @test RootedTrees.subtrees(t5) ==
        [rootedtree([2]), rootedtree([2]), rootedtree([2])]
    @test elementary_differential_latexstring(t5) ==
        L"$f^{\prime\prime\prime}(f, f, f)$"
    @test elementary_weight_latexstring(t5) == L"$\sum_{d}b_{d}c_{d}^{3}$"

    t6 = rootedtree([1, 2, 2, 3])
    @inferred RootedTrees.subtrees(t6)
    @test order(t6) == 4
    @test σ(t6) == 1
    @test γ(t6) == 8
    @test α(t6) == 3
    @test β(t6) == α(t6) * γ(t6)
    @test t6 == t2 ∘ t2 == t4 ∘ t1
    @inferred butcher_product!(t_result, t2, t2)
    @test @allocated(butcher_product!(t_result, t2, t2)) == 0
    @test t6 == t_result
    @inferred butcher_product!(t_result, t4, t1)
    @test @allocated(butcher_product!(t_result, t4, t1)) == 0
    @test t6 == t_result
    @test butcher_representation(t6) == "[[τ]τ]"
    @test RootedTrees.subtrees(t6) == [rootedtree([2, 3]), rootedtree([2])]
    @test elementary_differential_latexstring(t6) ==
        L"$f^{\prime\prime}(f^{\prime}f, f)$"
    @test elementary_weight_latexstring(t6) ==
        L"$\sum_{d, e}b_{d}a_{d,e}c_{e}c_{d}$"

    t7 = rootedtree([1, 2, 3, 3])
    @test order(t7) == 4
    @test σ(t7) == 2
    @test γ(t7) == 12
    @test β(t7) == α(t7) * γ(t7)
    @test t7 == t1 ∘ t3
    @inferred butcher_product!(t_result, t1, t3)
    @test @allocated(butcher_product!(t_result, t1, t3)) == 0
    @test t7 == t_result
    @test butcher_representation(t7) == "[[τ²]]"
    @test elementary_differential_latexstring(t7) ==
        L"$f^{\prime}f^{\prime\prime}(f, f)$"
    @test elementary_weight_latexstring(t7) == L"$\sum_{d, e}b_{d}a_{d,e}c_{e}^{2}$"

    t8 = rootedtree([1, 2, 3, 4])
    @test order(t8) == 4
    @test σ(t8) == 1
    @test γ(t8) == 24
    @test α(t8) == 1
    @test t8 == t1 ∘ t4
    @inferred butcher_product!(t_result, t1, t4)
    @test @allocated(butcher_product!(t_result, t1, t4)) == 0
    @test t8 == t_result
    @test butcher_representation(t8) == "[[[τ]]]"
    @test elementary_differential_latexstring(t8) ==
        L"$f^{\prime}f^{\prime}f^{\prime}f$"
    @test elementary_weight_latexstring(t8) ==
        L"$\sum_{d, e, f}b_{d}a_{d,e}a_{e,f}c_{f}$"

    t9 = rootedtree([1, 2, 2, 2, 2])
    @test order(t9) == 5
    @test σ(t9) == 24
    @test γ(t9) == 5
    @test α(t9) == 1
    @test β(t9) == α(t9) * γ(t9)
    @test t9 == t5 ∘ t1
    @inferred butcher_product!(t_result, t5, t1)
    @test @allocated(butcher_product!(t_result, t5, t1)) == 0
    @test t9 == t_result
    @test butcher_representation(t9) == "[τ⁴]"
    @test elementary_differential_latexstring(t9) == L"$f^{(4)}(f, f, f, f)$"
    @test elementary_weight_latexstring(t9) == L"$\sum_{d}b_{d}c_{d}^{4}$"

    t10 = rootedtree([1, 2, 2, 2, 3])
    @test order(t10) == 5
    @test σ(t10) == 2
    @test γ(t10) == 10
    @test α(t10) == 6
    @test β(t10) == α(t10) * γ(t10)
    @test t10 == t3 ∘ t2 == t6 ∘ t1
    @inferred butcher_product!(t_result, t3, t2)
    @test @allocated(butcher_product!(t_result, t3, t2)) == 0
    @test t10 == t_result
    @inferred butcher_product!(t_result, t6, t1)
    @test @allocated(butcher_product!(t_result, t6, t1)) == 0
    @test t10 == t_result
    @test butcher_representation(t10) == "[[τ]τ²]"
    @test elementary_differential_latexstring(t10) ==
        L"$f^{\prime\prime\prime}(f^{\prime}f, f, f)$"
    @test elementary_weight_latexstring(t10) ==
        L"$\sum_{d, e}b_{d}a_{d,e}c_{e}c_{d}^{2}$"

    t11 = rootedtree([1, 2, 2, 3, 3])
    @test order(t11) == 5
    @test σ(t11) == 2
    @test γ(t11) == 15
    @test α(t11) == 4
    @test t11 == t2 ∘ t3 == t7 ∘ t1
    @inferred butcher_product!(t_result, t2, t3)
    @test @allocated(butcher_product!(t_result, t2, t3)) == 0
    @test t11 == t_result
    @inferred butcher_product!(t_result, t7, t1)
    @test @allocated(butcher_product!(t_result, t7, t1)) == 0
    @test t11 == t_result
    @test butcher_representation(t11) == "[[τ²]τ]"
    @test elementary_differential_latexstring(t11) ==
        L"$f^{\prime\prime}(f^{\prime\prime}(f, f), f)$"
    @test elementary_weight_latexstring(t11) ==
        L"$\sum_{d, e}b_{d}a_{d,e}c_{e}^{2}c_{d}$"

    t12 = rootedtree([1, 2, 2, 3, 4])
    @test order(t12) == 5
    @test σ(t12) == 1
    @test γ(t12) == 30
    @test α(t12) == 4
    @test β(t12) == α(t12) * γ(t12)
    @test t12 == t2 ∘ t4 == t8 ∘ t1
    @inferred butcher_product!(t_result, t2, t4)
    @test @allocated(butcher_product!(t_result, t2, t4)) == 0
    @test t12 == t_result
    @inferred butcher_product!(t_result, t8, t1)
    @test @allocated(butcher_product!(t_result, t8, t1)) == 0
    @test t12 == t_result
    @test butcher_representation(t12) == "[[[τ]]τ]"
    @test elementary_differential_latexstring(t12) ==
        L"$f^{\prime\prime}(f^{\prime}f^{\prime}f, f)$"
    @test elementary_weight_latexstring(t12) ==
        L"$\sum_{d, e, f}b_{d}a_{d,e}a_{e,f}c_{f}c_{d}$"

    t13 = rootedtree([1, 2, 3, 2, 3])
    @test order(t13) == 5
    @test σ(t13) == 2
    @test γ(t13) == 20
    @test α(t13) == 3
    @test β(t13) == α(t13) * γ(t13)
    @test t13 == t4 ∘ t2
    @inferred butcher_product!(t_result, t4, t2)
    @test @allocated(butcher_product!(t_result, t4, t2)) == 0
    @test t13 == t_result
    @test butcher_representation(t13) == "[[τ][τ]]"
    @test elementary_differential_latexstring(t13) ==
        L"$f^{\prime\prime}(f^{\prime}f, f^{\prime}f)$"
    @test elementary_weight_latexstring(t13) ==
        L"$\sum_{d, e}b_{d}(a_{d,e}c_{e})^{2}$"

    t14 = rootedtree([1, 2, 3, 3, 3])
    @test order(t14) == 5
    @test σ(t14) == 6
    @test γ(t14) == 20
    @test α(t14) == 1
    @test β(t14) == α(t14) * γ(t14)
    @test t14 == t1 ∘ t5
    @inferred butcher_product!(t_result, t1, t5)
    @test @allocated(butcher_product!(t_result, t1, t5)) == 0
    @test t14 == t_result
    @test butcher_representation(t14) == "[[τ³]]"
    @test elementary_differential_latexstring(t14) ==
        L"$f^{\prime}f^{\prime\prime\prime}(f, f, f)$"
    @test elementary_weight_latexstring(t14) ==
        L"$\sum_{d, e}b_{d}a_{d,e}c_{e}^{3}$"

    t15 = rootedtree([1, 2, 3, 3, 4])
    @test order(t15) == 5
    @test σ(t15) == 1
    @test γ(t15) == 40
    @test α(t15) == 3
    @test β(t15) == α(t15) * γ(t15)
    @test t15 == t1 ∘ t6
    @inferred butcher_product!(t_result, t1, t6)
    @test @allocated(butcher_product!(t_result, t1, t6)) == 0
    @test t15 == t_result
    @test butcher_representation(t15) == "[[[τ]τ]]"
    @test elementary_differential_latexstring(t15) ==
        L"$f^{\prime}f^{\prime\prime}(f^{\prime}f, f)$"
    @test elementary_weight_latexstring(t15) ==
        L"$\sum_{d, e, f}b_{d}a_{d,e}a_{e,f}c_{f}c_{e}$"

    t16 = rootedtree([1, 2, 3, 4, 4])
    @test order(t16) == 5
    @test σ(t16) == 2
    @test γ(t16) == 60
    @test α(t16) == 1
    @test β(t16) == α(t16) * γ(t16)
    @test t16 == t1 ∘ t7
    @inferred butcher_product!(t_result, t1, t7)
    @test @allocated(butcher_product!(t_result, t1, t7)) == 0
    @test t16 == t_result
    @test butcher_representation(t16) == "[[[τ²]]]"
    @test elementary_differential_latexstring(t16) ==
        L"$f^{\prime}f^{\prime}f^{\prime\prime}(f, f)$"
    @test elementary_weight_latexstring(t16) ==
        L"$\sum_{d, e, f}b_{d}a_{d,e}a_{e,f}c_{f}^{2}$"

    t17 = rootedtree([1, 2, 3, 4, 5])
    @test order(t17) == 5
    @test σ(t17) == 1
    @test γ(t17) == 120
    @test α(t17) == 1
    @test β(t17) == α(t17) * γ(t17)
    @test t17 == t1 ∘ t8
    @inferred butcher_product!(t_result, t1, t8)
    @test @allocated(butcher_product!(t_result, t1, t8)) == 0
    @test t17 == t_result
    @test butcher_representation(t17) == "[[[[τ]]]]"
    @test elementary_differential_latexstring(t17) ==
        L"$f^{\prime}f^{\prime}f^{\prime}f^{\prime}f$"
    @test elementary_weight_latexstring(t17) ==
        L"$\sum_{d, e, f, g}b_{d}a_{d,e}a_{e,f}a_{f,g}c_{g}$"

    # test elementary_weight_latexstring which needs more than 23 indices

    t18 = rootedtree(collect(1:25))
    @test elementary_weight_latexstring(t18) ==
        L"$\sum_{d1, e1, f1, g1, h1, i1, j1, k1, l1, m1, n1, o1, p1, q1, r1, s1, t1, u1, v1, w1, x1, y1, z1, d2}b_{d1}a_{d1,e1}a_{e1,f1}a_{f1,g1}a_{g1,h1}a_{h1,i1}a_{i1,j1}a_{j1,k1}a_{k1,l1}a_{l1,m1}a_{m1,n1}a_{n1,o1}a_{o1,p1}a_{p1,q1}a_{q1,r1}a_{r1,s1}a_{s1,t1}a_{t1,u1}a_{u1,v1}a_{v1,w1}a_{w1,x1}a_{x1,y1}a_{y1,z1}a_{z1,d2}c_{d2}$"

    t19 = rootedtree([1, 2, 2, 3, 2, 3])
    @test elementary_weight_latexstring(t19) ==
        L"$\sum_{d, e}b_{d}(a_{d,e}c_{e})^{2}c_{d}$"

    # test non-canonical representation
    level_sequence = [1, 2, 3, 2, 3, 4, 2, 3, 2, 3, 4, 5, 6, 2, 3, 4]
    @test σ(rootedtree(level_sequence)) == σ(RootedTrees.RootedTree(level_sequence))
end

# see butcher2008numerical, Table 302(I)
@testset "number of trees" begin
    number_of_rooted_trees = [1, 1, 1, 2, 4, 9, 20, 48, 115, 286, 719]
    for order in 0:10
        num = 0
        for t in RootedTreeIterator(order)
            num += 1
        end
        @test num == number_of_rooted_trees[order + 1] == count_trees(order)
    end
end

# See Section 2.3 and Table 2 of
# - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
#   Algebraic Structures of B-series.
#   Foundations of Computational Mathematics
#   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
@testset "partitions" begin
    let t = rootedtree([1, 2, 3, 4, 3])
        edge_set = [true, true, false, false]
        reference_forest = [
            rootedtree([1, 2, 3]),
            rootedtree([4]),
            rootedtree([3]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 2])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 4, 3])
        edge_set = [false, true, true, false]
        reference_forest = [
            rootedtree([3]),
            rootedtree([2, 3, 4]),
            rootedtree([1]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 3])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 4, 3])
        edge_set = [false, true, false, false]
        reference_forest = [
            rootedtree([4]),
            rootedtree([3]),
            rootedtree([2, 3]),
            rootedtree([1]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 3, 3])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 2, 2, 2])
        edge_set = [false, false, true, true]
        reference_forest = [
            rootedtree([2]),
            rootedtree([2]),
            rootedtree([1, 2, 2]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 2])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 2, 2])
        edge_set = [false, false, false, true]
        reference_forest = [
            rootedtree([3]),
            rootedtree([2]),
            rootedtree([2]),
            rootedtree([1, 2]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 3, 2])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 2, 2])
        edge_set = [true, true, true, true]
        reference_forest = [rootedtree([1, 2, 3, 2, 2])]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 2, 3])
        edge_set = [true, true, false, false]
        reference_forest = [
            rootedtree([3]),
            rootedtree([2]),
            rootedtree([1, 2, 3]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 3])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 2, 3])
        edge_set = [false, true, false, false]
        reference_forest = [
            rootedtree([2, 3]),
            rootedtree([3]),
            rootedtree([2]),
            rootedtree([1]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 2, 3])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    let t = rootedtree([1, 2, 3, 3, 3])
        edge_set = [false, true, true, false]
        reference_forest = [
            rootedtree([3]),
            rootedtree([2, 3, 3]),
            rootedtree([1]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2, 3])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end

    # additional tests not included in the examples of the paper
    let t = rootedtree([1, 2, 3, 2, 3])
        edge_set = [true, false, true, true]
        reference_forest = [
            rootedtree([1, 2, 3, 2]),
            rootedtree([3]),
        ]
        @test sort!(partition_forest(t, edge_set)) == sort!(reference_forest)
        @test sort!(collect(PartitionForestIterator(t, edge_set))) ==
            reference_forest

        reference_skeleton = rootedtree([1, 2])
        @test reference_skeleton == partition_skeleton(t, edge_set)
    end
end

# See Table 3 of
# - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
#   Algebraic Structures of B-series.
#   Foundations of Computational Mathematics
#   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
@testset "all_partitions" begin
    t = rootedtree([1, 2, 3, 3])
    forests, skeletons = all_partitions(t)
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
        [rootedtree([1, 2, 3, 3])],
        [rootedtree([1]), rootedtree([1, 2, 2])],
        [rootedtree([1]), rootedtree([1, 2, 3])],
        [rootedtree([1]), rootedtree([1, 2, 3])],
        [rootedtree([1]), rootedtree([1]), rootedtree([1, 2])],
        [rootedtree([1]), rootedtree([1]), rootedtree([1, 2])],
        [rootedtree([1]), rootedtree([1]), rootedtree([1, 2])],
        [rootedtree([1]), rootedtree([1]), rootedtree([1]), rootedtree([1])],
    ]
    reference_skeletons = [
        rootedtree([1]),
        rootedtree([1, 2]),
        rootedtree([1, 2]),
        rootedtree([1, 2]),
        rootedtree([1, 2, 2]),
        rootedtree([1, 2, 3]),
        rootedtree([1, 2, 3]),
        rootedtree([1, 2, 3, 3]),
    ]
    for forest in reference_forests
        sort!(forest)
    end
    sort!(reference_forests)
    sort!(reference_skeletons)

    @test forests == reference_forests
    @test skeletons == reference_skeletons

    @testset "PartitionIterator" begin
        partitions = collect(PartitionIterator(t))
        iterator_forests = map(first, partitions)
        iterator_skeletons = map(last, partitions)
        for forest in iterator_forests
            sort!(forest)
        end
        sort!(iterator_forests)
        sort!(iterator_skeletons)
        @test iterator_forests == forests
        @test iterator_skeletons == skeletons

        for order in 1:8
            for t in RootedTreeIterator(order)
                forests, skeletons = all_partitions(t)
                @test collect(zip(forests, skeletons)) ==
                    collect(PartitionIterator(t))
            end
        end

        level_sequence = zeros(Int, RootedTrees.BUFFER_LENGTH + 1)
        level_sequence[1] -= 1
        t = rootedtree(level_sequence)
        @inferred PartitionIterator(t)
        t = @inferred rootedtree!(view(level_sequence, :))
        @inferred PartitionIterator(t)
    end
end

# See Section 2.2 and Table 1 of
# - Philippe Chartier, Ernst Hairer, Gilles Vilmart (2010)
#   Algebraic Structures of B-series.
#   Foundations of Computational Mathematics
#   [DOI: 10.1007/s10208-010-9065-1](https://doi.org/10.1007/s10208-010-9065-1)
@testset "splittings" begin
    t = rootedtree([1, 2, 3, 2, 2])
    splittings = all_splittings(t)
    forests_and_subtrees = sort!(
        collect(
            zip(
                splittings.forests,
                splittings.subtrees
            )
        )
    )

    reference_forests_and_subtrees = [
        (empty([rootedtree([1])]), rootedtree([1, 2, 3, 2, 2])),
        ([rootedtree([1])], rootedtree([1, 2, 3, 2])),
        ([rootedtree([1])], rootedtree([1, 2, 3, 2])),
        ([rootedtree([1, 2])], rootedtree([1, 2, 2])),
        ([rootedtree([1])], rootedtree([1, 2, 2, 2])),
        ([rootedtree([1, 2]), rootedtree([1])], rootedtree([1, 2])),
        ([rootedtree([1, 2]), rootedtree([1])], rootedtree([1, 2])),
        ([rootedtree([1]), rootedtree([1])], rootedtree([1, 2, 3])),
        ([rootedtree([1]), rootedtree([1])], rootedtree([1, 2, 2])),
        ([rootedtree([1]), rootedtree([1])], rootedtree([1, 2, 2])),
        ([rootedtree([1]), rootedtree([1]), rootedtree([1])], rootedtree([1, 2])),
        ([rootedtree([1, 2]), rootedtree([1]), rootedtree([1])], rootedtree([1])),
        ([rootedtree([1, 2, 3, 2, 2])], rootedtree(Int[])),
    ]
    sort!(reference_forests_and_subtrees)

    @test forests_and_subtrees == reference_forests_and_subtrees

    # tested with the Python package BSeries
    t = rootedtree([1, 2, 3, 4, 4, 2, 3, 3, 2, 3, 2, 3])
    splittings = all_splittings(t)
    @test length(splittings.forests) == length(splittings.subtrees) == 271

    # consistency of all_splittings and the SplittingIterator
    for order in 1:8
        for i in RootedTreeIterator(order)
            forests, subtrees = all_splittings(t)
            @test collect(zip(forests, subtrees)) == collect(SplittingIterator(t))
        end
    end
end
