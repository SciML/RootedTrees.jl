module PlotsExt

using Plots: Plots

using RootedTrees: RootedTrees

RootedTrees._distinguishable_colors(n) = Plots.distinguishable_colors(n)

end # module
