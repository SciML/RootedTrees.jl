using SciMLTesting, RootedTrees
using Test

# ExplicitImports only sees an extension module once its trigger package is loaded,
# so `using Plots` is what makes `PlotsExt` part of the QA scan.
using Plots

# ExplicitImports silently skips an extension that fails to load, so assert the
# extension modules actually exist rather than trusting a green run_qa.
@testset "Extensions loaded" begin
    @test Base.get_extension(RootedTrees, :PlotsExt) !== nothing
end

run_qa(
    RootedTrees;
    ei_kwargs = (;
        all_qualified_accesses_are_public = (;
            # RootedTrees: `_distinguishable_colors` is RootedTrees' own internal hook,
            # defined precisely so that `PlotsExt` can fill it in. ExplicitImports does
            # not treat an extension as internal to its parent package, so the access
            # has to be ignored here.
            ignore = (:_distinguishable_colors,),
        ),
    ),
)
