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

If you want to visualize individual trees, you can also use our plot recipes
for [Plots.jl](https://github.com/JuliaPlots/Plots.jl).

```@example basics
using Plots
t = rootedtree([1, 2, 3, 3, 2])
plot(t)
savefig("basics_tree.png"); nothing # hide
```

![](basics_tree.png)


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
