# RootedTrees.jl

The [Julia](https://julialang.org/) package
[RootedTrees.jl](https://github.com/SciML/RootedTrees.jl)
provides a collection of functionality around rooted trees, including
the generation of order conditions for Runge-Kutta methods.
This package also provides basic functionality for
[BSeries.jl](https://github.com/ranocha/BSeries.jl).


## Installation

[RootedTrees.jl](https://github.com/SciML/RootedTrees.jl)
is a registered Julia package. Thus, you can install it from the Julia REPL via
```julia
julia> using Pkg; Pkg.add("RootedTrees")
```
[RootedTrees.jl](https://github.com/SciML/RootedTrees.jl) works with
Julia version 1.6 and newer.

If you want to update RootedTrees.jl, you can use
```julia
julia> using Pkg; Pkg.update("RootedTrees")
```
As usual, if you want to update RootedTrees.jl and all other
packages in your current project, you can execute
```julia
julia> using Pkg; Pkg.update()
```


## Referencing

If you use
[RootedTrees.jl](https://github.com/SciML/RootedTrees.jl)
for your research, please cite the paper
```bibtex
@article{ketcheson2022computing,
  title={Computing with {B}-series},
  author={Ketcheson, David I and Ranocha, Hendrik},
  journal={ACM Transactions on Mathematical Software},
  year={2022},
  month={12},
  doi={10.1145/3573384},
  eprint={2111.11680},
  eprinttype={arXiv},
  eprintclass={math.NA}
}
```
In addition, you can also refer to RootedTrees.jl directly as
```bibtex
@misc{ranocha2019rootedtrees,
  title={{RootedTrees.jl}: {A} collection of functionality around rooted trees
         to generate order conditions for {R}unge-{K}utta methods in {J}ulia
         for differential equations and scientific machine learning ({SciM}L)},
  author={Ranocha, Hendrik and contributors},
  year={2019},
  month={05},
  howpublished={\url{https://github.com/SciML/RootedTrees.jl}},
  doi={10.5281/zenodo.5534590}
}
```
Please also cite the appropriate references for specific functions you use,
which can be obtained from their docstrings.


## License and contributing

This project is licensed under the MIT license (see [License](@ref)).
Since it is an open-source project, we are very happy to accept contributions
from the community. Please refer to the section [Contributing](@ref) for more
details.
