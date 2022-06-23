
RecipesBase.@recipe function plot(t::AbstractRootedTree)
    # Compute x and y coordinates recursively
    width = 2.0
    height = 1.0
    x, y = _plot_coordinates(t, 0.0, 0.0, width, height)

    # Series properties
    seriescolor --> :black
    markershape --> :circle
    markersize --> 6
    linewidth --> 2

    # Geometric properties
    grid --> false
    ticks --> false
    foreground_color_border --> :white
    legend --> :bottomright

    # We need to filter out `NaN` since these pollute `extrema`
    if !isempty(t)
        x_min, x_max = extrema(Iterators.filter(!isnan, x))
    else
        x_min = x_max = zero(eltype(x))
    end
    if x_min ≈ x_max
        xlims --> (x_min - width / 2, x_max + width / 2)
    end

    if !isempty(t)
        y_min, y_max = extrema(Iterators.filter(!isnan, y))
    else
        y_min = y_max = zero(eltype(y))
    end
    if y_min ≈ y_max
        ylims --> (y_min - height / 2, y_max + height / 2)
    end

    # Annotations
    label --> "tree " * string(t.level_sequence)

    return x, y
end

function _plot_coordinates(t::AbstractRootedTree,
                           x_root::T, y_root::T,
                           width::T, height::T) where {T}
    # Indicate a new line series by `NaN`
    nan = convert(T, NaN)

    # Initialize vectors of return values
    x = Vector{typeof(x_root)}()
    y = Vector{typeof(y_root)}()

    if isempty(t)
        return x, y
    end

    push!(x, x_root)
    push!(y, y_root)

    # Compute plot coordinates recursively
    subtr = subtrees(t)

    # Distribute children uniformly in x and at equal y coordinates
    y_child = y_root + height
    num_children = length(subtr)
    distance = width * (num_children - 1) / 2

    x_children = range(x_root - distance, x_root + distance; length = num_children)
    for idx in eachindex(subtr)
        x_child = x_children[idx]
        push!(x, nan, x_root, x_child)
        push!(y, nan, y_root, y_child)
        x_recursive, y_recursive = _plot_coordinates(subtr[idx],
                                                     x_child, y_child, width / 3, height)
        append!(x, x_recursive)
        append!(y, y_recursive)
    end

    return x, y
end
