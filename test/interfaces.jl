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

    # SubtreeIterator deliberately exposes only the two-argument iterate
    # protocol, so consume it without assuming length or eltype.
    @test generic_iterator_count(SubtreeIterator(tree)) == 2
end

function generic_tree_summary(t)
    edge_set = fill(false, order(t) - 1)
    return (
        order(t),
        generic_iterator_count(SubtreeIterator(t)),
        generic_iterator_count(PartitionIterator(t)),
        order(partition_skeleton(t, edge_set)),
        symmetry(t),
        density(t),
        α(t),
        β(t),
    )
end

@testset "generic tree interface" begin
    tree = rootedtree([1, 2, 2])
    @test generic_tree_summary(tree) == (3, 2, 4, 3, 2, 3, 1, 3)

    colored_tree = rootedtree([1, 2, 2], Bool[false, true, true])
    @test generic_tree_summary(colored_tree) == (3, 2, 4, 3, 2, 3, 1, 3)
    @test root_color(colored_tree) === false
end

@testset "exported names are documented" begin
    exported = names(RootedTrees; all = false, imported = false)
    undocumented = filter(exported) do name
        if isdefined(Base.Docs, :hasdoc)
            !Base.Docs.hasdoc(RootedTrees, name)
        else
            ref = Expr(:., :RootedTrees, QuoteNode(name))
            call = Expr(
                :macrocall, GlobalRef(Base.Docs, Symbol("@doc")), LineNumberNode(0), ref
            )
            doc = Core.eval(@__MODULE__, call)
            occursin("No documentation found", sprint(show, MIME"text/plain"(), doc))
        end
    end
    @test isempty(undocumented)
end
