using Documenter
import Pkg
using RootedTrees

# Define module-wide setups such that the respective modules are available in doctests
DocMeta.setdocmeta!(RootedTrees,
                    :DocTestSetup, :(using RootedTrees); recursive = true)

# Copy some files from the top level directory to the docs and modify them
# as necessary
open(joinpath(@__DIR__, "src", "license.md"), "w") do io
    # Point to source license file
    println(io,
            """
    ```@meta
    EditURL = "https://github.com/SciML/RootedTrees.jl/blob/main/LICENSE.md"
    ```
    """)
    # Write the modified contents
    println(io, "# License")
    println(io, "")
    for line in eachline(joinpath(dirname(@__DIR__), "LICENSE.md"))
        line = replace(line, "[LICENSE.md](LICENSE.md)" => "[License](@ref)")
        println(io, "> ", line)
    end
end

open(joinpath(@__DIR__, "src", "contributing.md"), "w") do io
    # Point to source license file
    println(io,
            """
    ```@meta
    EditURL = "https://github.com/SciML/RootedTrees.jl/blob/main/CONTRIBUTING.md"
    ```
    """)
    # Write the modified contents
    println(io, "# Contributing")
    println(io, "")
    for line in eachline(joinpath(dirname(@__DIR__), "CONTRIBUTING.md"))
        line = replace(line, "[LICENSE.md](LICENSE.md)" => "[License](@ref)")
        println(io, "> ", line)
    end
end

# Make documentation
makedocs(modules = [RootedTrees],
         sitename = "RootedTrees.jl",
         format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                                  canonical = "https://SciML.github.io/RootedTrees.jl/stable",
                                  ansicolor = true),
         # Explicitly specify documentation structure
         pages = [
             "Home" => "index.md",
             "Introduction" => "introduction.md",
             "Tutorials" => [
                 "tutorials/basics.md",
                 "tutorials/RK_order_conditions.md",
                 "tutorials/ARK_order_conditions.md",
                 "tutorials/Rosenbrock_order_conditions.md",
             ],
             # "Benchmarks" => "benchmarks.md",
             "API reference" => "api_reference.md",
             "Contributing" => "contributing.md",
             "License" => "license.md",
         ],
         # to make the GitHub action fail when doctests fail
         strict = true)

deploydocs(repo = "github.com/SciML/RootedTrees.jl",
           devbranch = "main",
           push_preview = true)
