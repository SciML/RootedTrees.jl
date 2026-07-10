using SciMLTesting, RootedTrees, Test
using JET

include("public_api_docs.jl")

run_qa(
    RootedTrees;
    explicit_imports = true,
    aqua_kwargs = (;
        ambiguities = (; exclude = [getindex]),
        # Requires.jl is not loaded on new versions of Julia
        stale_deps = (; ignore = [:Requires]),
    ),
    ei_kwargs = (;
        # Base internals with no public equivalent, accessed qualified:
        # IteratorSize/HasLength/SizeUnknown are the iterator-trait interface,
        # Iterators.filter is the standard lazy filter, and Base.Threads
        # resize_nthreads! is the canonical per-thread buffer helper.
        all_qualified_accesses_are_public = (;
            ignore = (:IteratorSize, :HasLength, :SizeUnknown, :filter, :resize_nthreads!),
        ),
    ),
)
