using Test
using RootedTrees

function generic_iterator_count(iter)
    state = iterate(iter)
    count = 0
    while !isnothing(state)
        value, iterator_state = state
        @test value isa eltype(iter)
        count += 1
        state = iterate(iter, iterator_state)
    end
    return count
end

@testset "public iterator interface" begin
    tree = rootedtree([1, 2, 2])
    iterators = (
        RootedTreeIterator(4),
        BicoloredRootedTreeIterator(3),
        PartitionForestIterator(tree, Bool[false, true]),
        PartitionIterator(tree),
        SplittingIterator(tree),
    )

    for iter in iterators
        expected_length = length(iter)
        @test generic_iterator_count(iter) == expected_length
    end
end
