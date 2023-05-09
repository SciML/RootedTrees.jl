
RecipesBase.@recipe function plot(t::ColoredRootedTree)
    # Compute x and y coordinates recursively
    width = 2.0
    height = 1.0
    color_idx = unique(t.color_sequence)
    if eltype(t.color_sequence) == Bool
        color_val = [:white, :black]
    else
        color_val = Plots.distinguishable_colors(length(color_idx))
    end
    colormap = Dict{eltype(color_idx), eltype(color_val)}()
    for (idx, val) in zip(color_idx, color_val)
        colormap[idx] = val
    end
    x, y, colors = _plot_coordinates(t, 0.0, 0.0, width, height, colormap)

    # Series properties
    linecolor --> :black
    markercolor --> reshape(colors, 1, :)
    background_color --> "LightGray"
    markershape --> :circle
    markersize --> 6
    linewidth --> 2

    # Geometric properties
    grid --> false
    ticks --> false
    foreground_color_border --> :white
    legend --> :bottomright

    # We need to `flatten` nested arrays
    if !isempty(t)
        x_min, x_max = extrema(Iterators.flatten(x))
    else
        x_min = x_max = zero(eltype(eltype(x)))
    end
    if x_min ≈ x_max
        xlims --> (x_min - width / 2, x_max + width / 2)
    end

    if !isempty(t)
        y_min, y_max = extrema(Iterators.flatten(y))
    else
        y_min = y_max = zero(eltype(eltype(x)))
    end
    if y_min ≈ y_max
        ylims --> (y_min - height / 2, y_max + height / 2)
    end

    # Annotations
    labels = ones(String, 1, length(colors))
    if !isempty(t)
        labels[1] = "tree " * string((t.level_sequence, t.color_sequence))
    end
    label --> labels

    x, y
end

function _plot_coordinates(t::ColoredRootedTree,
                           x_root::T, y_root::T,
                           width::T, height::T,
                           colormap) where {T}
    # Initialize vectors of return values
    x = Vector{Vector{T}}()
    y = Vector{Vector{T}}()
    colors = Vector{Vector{valtype(colormap)}}()

    if isempty(t)
        return x, y, colors
    end

    push!(x, [x_root])
    push!(y, [y_root])
    color_root = colormap[first(t.color_sequence)]
    push!(colors, [color_root])

    # We cannot indicate a new line series by `NaN` since that doesn't work with
    # colors
    # ┌ Warning: Indices Base.OneTo(9) of attribute `seriescolor` does not match data indices 3:9.
    # └ @ Plots ~/.julia/packages/Plots/AJMX6/src/utils.jl:132
    # ┌ Info: Data contains NaNs or missing values, and indices of `seriescolor` vector do not match data indices.
    # │ If you intend elements of `seriescolor` to apply to individual NaN-separated segments in the data,
    # │ pass each segment in a separate vector instead, and use a row vector for `seriescolor`. Legend entries
    # │ may be suppressed by passing an empty label.
    # │ For example,
    # └     plot([1:2,1:3], [[4,5],[3,4,5]], label=["y" ""], seriescolor=[1 2])
    # ┌ Warning: Indices Base.OneTo(9) of attribute `linecolor` does not match data indices 3:9.
    # └ @ Plots ~/.julia/packages/Plots/AJMX6/src/utils.jl:132
    # ┌ Info: Data contains NaNs or missing values, and indices of `linecolor` vector do not match data indices.
    # │ If you intend elements of `linecolor` to apply to individual NaN-separated segments in the data,
    # │ pass each segment in a separate vector instead, and use a row vector for `linecolor`. Legend entries
    # │ may be suppressed by passing an empty label.
    # │ For example,
    # └     plot([1:2,1:3], [[4,5],[3,4,5]], label=["y" ""], linecolor=[1 2])
    # ┌ Warning: Indices Base.OneTo(9) of attribute `fillcolor` does not match data indices 3:9.
    # └ @ Plots ~/.julia/packages/Plots/AJMX6/src/utils.jl:132
    # ┌ Info: Data contains NaNs or missing values, and indices of `fillcolor` vector do not match data indices.
    # │ If you intend elements of `fillcolor` to apply to individual NaN-separated segments in the data,
    # │ pass each segment in a separate vector instead, and use a row vector for `fillcolor`. Legend entries
    # │ may be suppressed by passing an empty label.
    # │ For example,
    # └     plot([1:2,1:3], [[4,5],[3,4,5]], label=["y" ""], fillcolor=[1 2])
    # ┌ Warning: Indices Base.OneTo(9) of attribute `markercolor` does not match data indices 3:9.
    # └ @ Plots ~/.julia/packages/Plots/AJMX6/src/utils.jl:132
    # ┌ Info: Data contains NaNs or missing values, and indices of `markercolor` vector do not match data indices.
    # │ If you intend elements of `markercolor` to apply to individual NaN-separated segments in the data,
    # │ pass each segment in a separate vector instead, and use a row vector for `markercolor`. Legend entries
    # │ may be suppressed by passing an empty label.
    # │ For example,
    # └     plot([1:2,1:3], [[4,5],[3,4,5]], label=["y" ""], markercolor=[1 2])

    # Compute plot coordinates recursively
    subtr = subtrees(t)

    # Distribute children uniformly in x and at equal y coordinates
    y_child = y_root + height
    num_children = length(subtr)
    distance = width * (num_children - 1) / 2

    x_children = range(x_root - distance, x_root + distance, length = num_children)
    for idx in eachindex(subtr)
        x_child = x_children[idx]
        push!(x, [x_root, x_child])
        push!(y, [y_root, y_child])
        push!(colors, [color_root, colormap[first(subtr[idx].color_sequence)]])
        x_recursive, y_recursive, colors_recursive = _plot_coordinates(subtr[idx],
                                                                       x_child, y_child,
                                                                       width / 3, height,
                                                                       colormap)
        append!(x, x_recursive)
        append!(y, y_recursive)
        append!(colors, colors_recursive)
    end

    return x, y, colors
end
