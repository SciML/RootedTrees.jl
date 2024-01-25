# Basics, printing, and visualization

As described in the [introduction](@ref introduction), [`RootedTree`](@ref)s
are represented using level sequences, i.e., `AbstractVector`s containing
the distances of the nodes from the root. For example,

```@example basics
using RootedTrees
for t in RootedTreeIterator(4)
    println(t)
end
```


## Visualization of trees

Depending on your background, you may be more familiar with the classical
notation used in the books of Butcher or Hairer & Wanner. You can get these
representation via [`butcher_representation`](@ref).

```@example basics
for t in RootedTreeIterator(4)
    println(butcher_representation(t))
end
```

Remember that you can change the printing style globally via
[`RootedTrees.set_printing_style`](@ref).

When working with LaTeX, it can be convenient to use the LaTeX package
[forest](https://ctan.org/pkg/forest) to draw trees. You can find more
information about this in the docstring of [`RootedTrees.latexify`](@ref).
For example,

```@example basics
for t in RootedTreeIterator(4)
    println(RootedTrees.latexify(t))
end
```

This results in the following LaTeX output:

![latex-trees](https://user-images.githubusercontent.com/12693098/196148917-6e3cf000-5bc3-4798-8a82-d6e939bb6a8f.png)

To get a human-readable output, you can use
[`RootedTrees.set_latexify_style`](@ref). This can be particularly helpful when
working in Jupyter notebooks, e.g., by passing the output of `latexify` to
`IPython.display.Latex`.

```@example basics
RootedTrees.set_latexify_style("butcher")

for t in RootedTreeIterator(4)
    println(RootedTrees.latexify(t))
end

RootedTrees.set_latexify_style("forest")

for t in RootedTreeIterator(4)
    println(RootedTrees.latexify(t))
end
```

If you want to visualize individual trees, you can also use our plot recipes
for [Plots.jl](https://github.com/JuliaPlots/Plots.jl).

```@example basics
using Plots
t = rootedtree([1, 2, 3, 3, 2])
plot(t)
savefig("basics_tree.png"); nothing # hide
```

![](basics_tree.png)

To get the elementary differential, corresponding to a `RootedTree`, as a [`LaTeXString`](https://github.com/JuliaStrings/LaTeXStrings.jl), you can use [`elementary_differential_latexstring`](@ref).

```@example basics
for t in RootedTreeIterator(4)
    println(elementary_differential_latexstring(t))
end
```
In LaTeX this results in the following output:

![latex-elementary_differentials](https://user-images.githubusercontent.com/125130707/282897199-4967fe07-a370-4d64-b671-84f578a52391.png)

Similarly, to get the elementary weight, corresponding to a `RootedTree`, as a [`LaTeXString`](https://github.com/JuliaStrings/LaTeXStrings.jl), you can use [`elementary_weight_latexstring`](@ref).

```@example basics
for t in RootedTreeIterator(4)
    println(elementary_weight_latexstring(t))
end
```

![latex elemenary weights](https://private-user-images.githubusercontent.com/125130707/298310491-8a035faf-fd1a-4fc0-92be-c3387eb53177.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MDYxNjY1ODAsIm5iZiI6MTcwNjE2NjI4MCwicGF0aCI6Ii8xMjUxMzA3MDcvMjk4MzEwNDkxLThhMDM1ZmFmLWZkMWEtNGZjMC05MmJlLWMzMzg3ZWI1MzE3Ny5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjQwMTI1JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI0MDEyNVQwNzA0NDBaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1kYzQyYjM0MWY0MDU5YWZlYzBmODA4MjFiZGIxN2E3YjhkYTdmZDNkYTU5NmI5OTEwNWFiZjg0OGZjNDg1MzZhJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZhY3Rvcl9pZD0wJmtleV9pZD0wJnJlcG9faWQ9MCJ9.GB-PigOlQqenzgruzWg19qslzM6RXeX4xWwCNreOvNY)


## Number of trees

The number of rooted trees grows exponentially. Please consider this when
iterating over some set of rooted trees. The implementations in
[RootedTrees.jl](https://github.com/SciML/RootedTrees.jl)
are reasonably efficient, but an exponential growth will always win in the end.

The function [`count_trees`](@ref) iterates over rooted trees explicitly. Thus,
it provides a lower bound on the computational complexity of operations on all
trees. For example,

```@repl
using RootedTrees
@time count_trees(10)
@time count_trees(20)
```

A nice way to create and print tables of properties of trees is by using
the Julia package [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl).

```@repl
using RootedTrees, PrettyTables
orders = 1:10
pretty_table(hcat(orders, count_trees.(orders)), header=["Order", "# Trees"])
```

To get the corresponding number of Runge-Kutta (RK) order conditions, we must
sum up the number of trees, i.e.,

```@repl
using RootedTrees, PrettyTables
orders = 1:10
pretty_table(hcat(orders, cumsum(count_trees.(orders))), header=["Order", "# RK Order Conditions"])
```

We can also visualize the exponential growth.

```@example basics
using Plots
orders = 1:15
scatter(orders, count_trees.(orders), yscale=:log10,
        xguide="Order", yguide="Number of Trees")
savefig("basics_count_trees.png"); nothing # hide
```

![](basics_count_trees.png)


## Colored trees

A lot of the same functionality is also available for colored trees.
Note that the additional choice of different colors increases the number of
trees significantly. For example, the number of trees of order 3 increases from

```@example basics
for t in RootedTreeIterator(3)
    println(t)
end
```

to

```@example basics
for t in BicoloredRootedTreeIterator(3)
    println(t)
end
```

[`RootedTrees.latexify`](@ref) also supports bicolored rooted trees:

```@example basics
for t in BicoloredRootedTreeIterator(3)
    println(RootedTrees.latexify(t))
end
```

The style can be adapted as well via [`RootedTrees.set_latexify_style`](@ref).

```@example basics
RootedTrees.set_latexify_style("butcher")

for t in BicoloredRootedTreeIterator(3)
    println(RootedTrees.latexify(t))
end

RootedTrees.set_latexify_style("forest")

for t in BicoloredRootedTreeIterator(3)
    println(RootedTrees.latexify(t))
end
```

Plotting is of course also implemented for colored rooted trees.

```@example basics
using Plots
t = rootedtree([1, 2, 3, 3, 2, 2], Bool[0, 0, 1, 0, 1, 0])
plot(t)
savefig("basics_bicolored_tree.png"); nothing # hide
```

![](basics_bicolored_tree.png)

The general implementation supports more than two colors, e.g.,

```@example basics
using Plots
t = rootedtree([1, 2, 3, 3, 2], [1, 2, 3, 4, 5])
plot(t)
savefig("basics_colored_tree.png"); nothing # hide
```

![](basics_colored_tree.png)

However, the support for multiple colors is limited at the moment, e.g.,
concerning efficient iterators.
