using Test
using RootedTrees
using Plots: Plots, plot

Plots.unicodeplots()

@testset "RootedTree" begin
    plot(rootedtree(Int[]))

    for order in 1:4
        for t in RootedTreeIterator(order)
            plot(t)
        end
    end
end

@testset "ColoredRootedTree" begin
    let t = rootedtree(Int[], Bool[])
        plot(t)
    end

    let t = rootedtree([1], [1])
        plot(t)
    end

    let t = rootedtree([1], [2])
        plot(t)
    end

    let t = rootedtree([1], [3])
        plot(t)
    end

    let t = rootedtree([1, 2], [1, 1])
        plot(t)
    end

    let t = rootedtree([1, 2], [1, 2])
        plot(t)
    end

    let t = rootedtree([1, 2], [3, 1])
        plot(t)
    end

    let t = rootedtree([1, 2, 2], [2, 1, 1])
        plot(t)
    end

    let t = rootedtree([1, 2, 2], [2, 1, 2])
        plot(t)
    end

    let t = rootedtree([1, 2, 3], [3, 2, 1])
        plot(t)
    end
end
