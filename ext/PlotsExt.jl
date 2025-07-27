module PlotsExt

    using Plots: Plots
else
    import ..Plots: Plots
end

using RootedTrees: RootedTrees

RootedTrees._distinguishable_colors(n) = Plots.distinguishable_colors(n)

end # module
