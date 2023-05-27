module PlotsExt

# We do not check `isdefined(Base, :get_extension)` since Julia v1.9.0
# does not load package extensions when their dependency is loaded from
# the main environment
if VERSION >= v"1.9.1"
    using Plots: Plots
else
    import ..Plots: Plots
end

using RootedTrees: RootedTrees

RootedTrees._distinguishable_colors(n) = Plots.distinguishable_colors(n)

end # module
